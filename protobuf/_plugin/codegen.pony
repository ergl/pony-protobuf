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
    while proto_descriptors.size() > 0 do
      try
        let descr = proto_descriptors.shift()?
        match descr.name
        | let descr_name: String =>
          // TODO(borja): Parse dependencies
          if (file_name == GenNames.proto_file(descr_name)) then
            match descr.syntax
            | "proto3" =>
              return "pony-protobuf only supports proto2 files"
            else
              response_file.content =
                _codegen_proto_descriptor(protoc_version, template_ctx, descr)
              // We generated what we want, bail out
              break
            end
          end
        else
          // TODO(borja): What can we do about anonymous descriptors?
          None
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
    descriptor: FileDescriptorProto)
    : String
  =>
    let ctx = CodeGenFileContext
    ctx.insert_header(protoc_version, template_ctx)
    _codegen_enums(
      ctx,
      template_ctx,
      descriptor.enum_type
    )
    _codegen_messages(
      ctx,
      template_ctx,
      descriptor.message_type
    )
    ctx.content()

  fun _codegen_enums(
    ctx: CodeGenFileContext ref,
    template_ctx: GenTemplate,
    enums: Array[EnumDescriptorProto] box,
    prefix: String = "")
  =>
    let field_acc = Array[(String, I32)]
    for enum in enums.values() do
      try
        let name = GenNames.proto_enum((enum.name as String).clone())
        for field in enum.value.values() do
          let field_name = GenNames.proto_enum((field.name as String).clone())
          field_acc.push((
            prefix + name + field_name,
            field.number as I32
          ))
        end
        ctx.add_enum(prefix + name, field_acc, template_ctx)
      end
      field_acc.clear()
    end

  fun _codegen_messages(
    ctx: CodeGenFileContext ref,
    template_ctx: GenTemplate,
    messages: Array[DescriptorProto],
    prefix: String = "",
    recursion_level: USize = 0)
  =>
    if recursion_level > CodeGen.recursion_limit() then
      // TODO(borja): Inform caller here
      return
    end

    for message in messages.values() do
      match message.name
      | let name: String =>
        _codegen_enums(ctx, template_ctx, message.enum_type, name)
        _codegen_messages(ctx, template_ctx, message.nested_type, name,
          recursion_level + 1)
      else
        None // TODO(borja): What do we do about anonymous messages?
      end
    end

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
      match_clauses.push(TemplateValue("", (match_clause_map)))
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

  fun ref content(): String val =>
    let to_ret = _str = recover String end
    consume to_ret
