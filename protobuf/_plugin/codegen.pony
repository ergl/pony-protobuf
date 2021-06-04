use "debug"

use "templates"
use "collections"

use ".."

primitive CodeGen
  fun recursion_limit(): USize => 100

  fun _build_protoc_version(maybe_version: (Version | None)): String =>
    match maybe_version
    | None => ""
    | let version: Version =>
      let str = recover String.create(6) end
      match version.major
      | None => None
      | let major: I32 => str.>append(major.string()).append(".")
      end
      match version.minor
      | None => None
      | let minor: I32 => str.>append(minor.string()).append(".")
      end
      match version.patch
      | None => None
      | let patch: I32 => str.append(patch.string())
      end
      match version.suffix
      | let suffix: String if suffix.size() > 0 =>
        str.>append(".").append(suffix)
      else
        None
      end
      consume str
    end

  fun apply(request: CodeGeneratorRequest): CodeGeneratorResponse =>
    let protoc_version_str = _build_protoc_version(request.compiler_version)
    let resp: CodeGeneratorResponse = CodeGeneratorResponse

    resp.supported_features = U64(0)
    resp.file =
      Array[CodeGeneratorResponseFile](request.file_to_generate.size())

    try
      let template_ctx = GenTemplate.create()?
      var dependencies = request.proto_file
      for file_name in request.file_to_generate.values() do
        let res = _codegen_proto_file(file_name, dependencies, template_ctx,
          protoc_version_str)
        match res
        | let gen: CodeGeneratorResponseFile =>
          resp.file.push(gen)
        | let error_reason: String =>
          resp.field_error = error_reason
          break
        end
      end
    else
      resp.field_error =
        "pony-protobuf encountered an internal error during template parsing"
    end
    resp

  fun _codegen_proto_file(
    file_path: String,
    proto_descriptors: Array[FileDescriptorProto],
    template_ctx: GenTemplate,
    protoc_version: String)
    : (CodeGeneratorResponseFile | String)
  =>
    let response_file: CodeGeneratorResponseFile = CodeGeneratorResponseFile
    let file_name = GenNames.proto_file(file_path)
    response_file.name = file_name + ".pony"

    // Although we should only generate code for `file_path`, we should
    // go through the dependencies to construct the names for the dependencies,
    // even if we don't generate code for them
    var offset: USize = 0
    let global_scope = SymbolScope
    while proto_descriptors.size() > 0 do
      try
        let descr = proto_descriptors.shift()?
        // TODO(borja): What can we do about anonymous descriptors?
        let descr_name = descr.name as String
        let package = match descr.package
        | let s': String => s'
        | None => ""
        end
        if (file_name == GenNames.proto_file(descr_name)) then
          match descr.syntax
          | "proto3" =>
            return "pony-protobuf only supports proto2 files"
          else
            let local_scope = SymbolScope(package, global_scope)
            response_file.content =
              _codegen_proto_descriptor(protoc_version, template_ctx,
                local_scope, descr)
            // We generated what we want, bail out
            break
          end
        end
      else
        // Can't happen, we ensured there are still elements in the array
        return "pony-protobuf encountered an internal error"
      end
    end

    response_file

  fun _codegen_proto_descriptor(
    protoc_version: String,
    template_ctx: GenTemplate,
    scope: SymbolScope,
    descriptor: FileDescriptorProto)
    : String
  =>
    let ctx = CodeGenFileContext
    ctx.insert_header(protoc_version, template_ctx)
    _codegen_enums(
      ctx,
      template_ctx,
      scope,
      descriptor.enum_type
    )
    _codegen_messages(
      ctx,
      template_ctx,
      scope,
      descriptor.message_type
    )
    ctx.content()

  fun _codegen_enums(
    ctx: CodeGenFileContext ref,
    template_ctx: GenTemplate,
    scope: SymbolScope,
    enums: Array[EnumDescriptorProto] box,
    prefix: String = "")
  =>
    let field_acc = Array[(String, I32)]
    for enum in enums.values() do
      try
        let proto_name = enum.name as String
        let local_scope = SymbolScope(proto_name, scope)
        let name = GenNames.proto_enum(proto_name.clone())
        for field in enum.value.values() do
          let proto_field_name = field.name as String
          let field_name = GenNames.proto_enum(proto_field_name.clone())
          let pony_primitive_name: String = prefix + name + field_name
          field_acc.push((
            pony_primitive_name,
            field.number as I32
          ))
          local_scope(proto_field_name) = pony_primitive_name
          // This should only be in the local scope
          scope.local_insert(proto_field_name, pony_primitive_name)
        end
        // Add it to the parent scope
        scope(proto_name) = prefix + name
        ctx.add_enum(prefix + name, field_acc, template_ctx)
      end
      field_acc.clear()
    end

  fun _codegen_messages(
    ctx: CodeGenFileContext ref,
    template_ctx: GenTemplate,
    outer_scope: SymbolScope,
    messages: Array[DescriptorProto],
    prefix: String = "",
    recursion_level: USize = 0)
  =>
    if recursion_level > CodeGen.recursion_limit() then
      // TODO(borja): Inform caller here
      return
    end

    // TODO(borja): The messages are ordered arbitrarily
    // We have to do one pass for scoping, then another
    // to generate them, otherwise we might miss something.
    for message in messages.values() do
      try
        let proto_name = message.name as String
        let name = GenNames.proto_enum(prefix + proto_name)
        outer_scope(proto_name) = name

        let local_scope = SymbolScope(proto_name, outer_scope)
        _codegen_enums(ctx, template_ctx, local_scope, message.enum_type, name)
        _codegen_messages(ctx, template_ctx, local_scope, message.nested_type, 
          name, recursion_level + 1)
        let field_meta =
          _codegen_message_fields(ctx, template_ctx, local_scope,
            message.field)
        ctx.add_message(name, field_meta, template_ctx)
      end // TODO(borja): What do we do about anonymous messages?
    end

  fun _codegen_message_fields(
    ctx: CodeGenFileContext ref,
    template_ctx: GenTemplate,
    scope: SymbolScope,
    fields: Array[FieldDescriptorProto])
    : Map[String, FieldMeta] val
  =>
    // Mapping of fields to its field number and kind
    let field_meta = recover Map[String, FieldMeta] end
    let field_numbers = Map[String, (U64, TagKind)]
    for field in fields.values() do
      try
        let name = GenNames.message_field(field.name as String)
        let field_number = field.number as I32
        (let field_tag, let field_type, let default) = _find_field_type(field,
          field.label as FieldDescriptorProtoLabel, scope)?
        let is_packed =
          try (field.options as FieldOptions).packed as Bool else false end
        field_meta(name) =
          FieldMeta(where
            number' = field_number,
            tag_kind' = field_tag,
            typ' = field_type,
            default' = default,
            is_packed' = is_packed
          )
      end // TODO(borja): What do we do about anonymous messages?
    end
    consume field_meta

  fun _find_field_type(
    field: FieldDescriptorProto,
    field_label: FieldDescriptorProtoLabel,
    scope: SymbolScope)
    : (TagKind, String, String)
    ?
  =>

    let default_value_str = match field.default_value
    | let default_value': String => default_value'
    | None => "None"
    end

    match field.field_type
    | let field_type: FieldDescriptorProtoType =>
      match GenTypes.typeof(field_type, field_label, default_value_str)
      | let field_tag: TagKind =>
        // We couldn't decipher the type, it's possible that it's a
        // message or enum type.
        (
          field_tag,
          GenTypes.label_of(
            scope(field.type_name as String) as String,
            field_label
          ),
          _find_default(
            scope,
            field.type_name as String,
            default_value_str,
            field_label
          )?
        )

      | (
          let field_tag: TagKind,
          let type_name: String,
          let default_value: String
        ) =>
        // Everything went OK
        (field_tag, type_name, default_value)
      end
    else
      // Allowed, but type_name better be set.
      // We assume that this is a message type
      (
        DelimitedField,
        GenTypes.label_of(
          scope(field.type_name as String) as String,
          field_label
        ),
        _find_default(
          scope,
          field.type_name as String,
          default_value_str,
          field_label
        )?
      )
    end

  fun _find_default(
    scope: SymbolScope,
    type_name: String,
    default: String,
    label: FieldDescriptorProtoLabel)
    : String
    ?
  =>
    let has_default = default != "None"
    if
      (not has_default) and
      (label isnt FieldDescriptorProtoLabelLABELREPEATED)
    then
      return "None"
    end

    GenTypes.default_value(
      if has_default then
        scope(default) as String
      else
        scope(type_name) as String
      end,
      label
    )

class val FieldMeta
  let number: I32
  let tag_kind: TagKind
  let typ: String
  let default: String
  let is_packed: Bool

  new val create(
    number': I32,
    tag_kind': TagKind,
    typ': String,
    default': String,
    is_packed': Bool = false)
  =>
    number = number'
    tag_kind = tag_kind'
    typ = typ'
    default = default'
    is_packed = is_packed'

class CodeGenFileContext
  var _str: String iso

  new ref create(with_capacity: USize = 0) =>
    _str = recover String(with_capacity) end

  fun ref insert_header(protoc_version: String, template_ctx: GenTemplate) =>
    let values = TemplateValues
    values("vsn") = PluginVersion()
    values("protoc_version") = protoc_version
    try
      _str.append(
        template_ctx.header.render(values)?
      )
    end

  fun ref add_enum(
    enum_name: String,
    fields: Array[(String, I32)] box,
    template_ctx: GenTemplate)
  =>
    let enum_alias = TemplateValues
    enum_alias("name") = enum_name

    let enum_builder = TemplateValues
    enum_builder("name") = GenNames.proto_enum(enum_name + "Builder")
    enum_builder("enum_type") = enum_name

    var is_first = true
    let rest_aliases = Array[TemplateValue]
    let match_clauses = Array[TemplateValue]
    for (name, number) in fields.values() do
      let enum_field = TemplateValues
      let match_clause_map = Map[String, TemplateValue]
      enum_field("name") = name
      enum_field("value") = number.string()
      match_clause_map("name") = TemplateValue(name)
      match_clause_map("value") = TemplateValue(number.string())
      match_clauses.push(TemplateValue("", match_clause_map))
      try
        _str.append(
          template_ctx.enum_field.render(enum_field)?
        )
      end

      if is_first then
        enum_alias("first_alias") = name
        is_first = false
      else
        rest_aliases.push(TemplateValue(name))
      end
    end
    enum_alias("rest_alias") = TemplateValue(rest_aliases)
    enum_builder("match_clauses") = TemplateValue(match_clauses)
    try
      _str.append(
        template_ctx.enum_alias.render(enum_alias)?
      )
      _str.append(
        template_ctx.enum_builder.render(enum_builder)?
      )
    end

  fun ref add_message(
    message_name: String,
    field_info: Map[String, FieldMeta] box,
    template_ctx: GenTemplate)
  =>
    let message_structure = TemplateValues
    message_structure("name") = message_name
    let fields = Array[TemplateValue]
    for (name, meta) in field_info.pairs() do
      let tpl = Map[String, TemplateValue]
      tpl("name") = TemplateValue(name)
      tpl("f_type") = TemplateValue(meta.typ)
      tpl("default") = TemplateValue(meta.default)
      fields.push(TemplateValue("", tpl))
    end
    message_structure("fields") = TemplateValue(fields)
    message_structure("initializer_clauses") =
      TemplateValue(Array[TemplateValue])
    message_structure("field_size_clauses") =
      TemplateValue(Array[TemplateValue])
    message_structure("read_clauses") =
      TemplateValue(Array[TemplateValue])
    message_structure("write_clauses") =
      TemplateValue(Array[TemplateValue])
    try
      _str.append(
        template_ctx.message_structure.render(message_structure)?
      )
    else
      Debug.err("failed to fill template for " + message_name)
    end

  fun ref content(): String val =>
    let to_ret = _str = recover String end
    consume to_ret
