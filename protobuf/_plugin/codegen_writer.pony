use "templates"
use "collections"
use "debug" // TODO(borja): remove

use ".."

class CodeGenWriter
  var _str: String iso

  new ref create(with_capacity: USize = 0) =>
    _str = recover String(with_capacity) end

  fun ref write_header(protoc_version: String, template_ctx: GenTemplate) =>
    let values = TemplateValues
    values("vsn") = PluginVersion()
    values("protoc_version") = protoc_version
    try
      _str.append(
        template_ctx.header.render(values)?
      )
    end

  fun ref write_enum(
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

  fun _fill_fields(
    field_info: Map[String, FieldMeta] box,
    template_ctx: GenTemplate)
    : TemplateValue
  =>
    let fields = Array[TemplateValue]
    for (name, meta) in field_info.pairs() do
      let tpl = Map[String, TemplateValue]
      tpl("name") = TemplateValue(name)
      tpl("pony_type") = TemplateValue(meta.pony_type_decl)
      tpl("default") = TemplateValue(meta.default_assignment)
      fields.push(TemplateValue("", tpl))
    end
    TemplateValue(fields)

  fun _fill_write_clause_packed(
    field_name: String,
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    // If it's packed, underlying type has to be primitive or enum
    match field_meta.proto_type
    | PrimitiveType =>
      match field_meta.wire_type
      | VarintField =>
        let tpl = TemplateValues
        tpl("field") = field_name
        tpl("number") = field_meta.number
        tpl("type") = field_meta.pony_type_usage
        template_ctx.write_packed_varint.render(tpl)?
      else
        // FIXME(borja): Handle more packed values
        error
      end
    | EnumType =>
      // FIXME(borja): Don't know how to handle these yet
      error
    | MessageType =>
      // In theory, protoc should discard these before it sends us
      // the codegen request, so it should be okay to error here
      error
    end

  fun _fill_write_clause_repeated(
    field_name: String,
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("field") = field_name
    tpl("number") = field_meta.number
    match field_meta.proto_type
    | PrimitiveType =>
      tpl("tag_kind") = field_meta.wire_type.string()
      match field_meta.wire_type
      | VarintField =>
        tpl("type") = field_meta.pony_type_usage
        tpl("method") =
          if field_meta.uses_zigzag then
             "write_varint"
          else
              "write_varint_zigzag"
          end
      | Fixed32Field =>
        tpl("type") = field_meta.pony_type_usage
        tpl("method") = "write_fixed_32"
      | Fixed64Field =>
        tpl("type") = field_meta.pony_type_usage
        tpl("method") = "write_fixed_64"
      | DelimitedField =>
        tpl("method") = "write_bytes"
      end
      template_ctx.write_repeated_non_message_type.render(tpl)?
    | EnumType =>
      tpl("tag_kind") = field_meta.wire_type.string()
      tpl("method") = "write_enum"
      template_ctx.write_repeated_non_message_type.render(tpl)?
    | MessageType =>
      template_ctx.write_repeated_inner_message_clause.render(tpl)?
    end

  fun _fill_write_clause_optional(
    field_name: String,
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("field") = field_name
    tpl("type") = field_meta.pony_type_usage
    if
      (field_meta.proto_type is MessageType) or
      (field_meta.proto_label is Repeated) or
      ((field_meta.wire_type is DelimitedField) and
       (field_meta.pony_type_usage == "Array[U8]"))
    then
      tpl("needs_viewpoint") = ""
    end
    let inner_tpl = TemplateValues
    // Use primed variable inside the optional clause
    inner_tpl("field") = field_name + "'"
    inner_tpl("number") = field_meta.number
    inner_tpl("type") = field_meta.pony_type_usage
    let inner_template = match field_meta.proto_type
    | MessageType => template_ctx.write_inner_message
    | EnumType => template_ctx.write_enum
    | PrimitiveType => match field_meta.wire_type
      | Fixed32Field => template_ctx.write_fixed_32
      | Fixed64Field => template_ctx.write_fixed_64
      | DelimitedField => template_ctx.write_bytes
      | VarintField =>
        if field_meta.uses_zigzag then
          template_ctx.write_varint_zigzag
        else
          template_ctx.write_varint
        end
      end
    end

    tpl("body") = inner_template.render(inner_tpl)?
    template_ctx.write_optional_clause.render(tpl)?

  fun _fill_write_clause(
    field_name: String,
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    match field_meta.proto_label
    | RepeatedPacked =>
      _fill_write_clause_packed(field_name, field_meta, template_ctx)?
    | Repeated =>
      _fill_write_clause_repeated(field_name, field_meta, template_ctx)?
    else
      _fill_write_clause_optional(field_name, field_meta, template_ctx)?
    end

  fun _fill_write_clauses(
    field_info: Map[String, FieldMeta] box,
    template_ctx: GenTemplate)
    : TemplateValue
  =>
    let clauses = Array[TemplateValue]
    for (name, meta) in field_info.pairs() do
      try
        clauses.push(
          TemplateValue(_fill_write_clause(name, meta, template_ctx)?)
        )
      else
        Debug.err("failed to fill write clause template for " + name)
      end
    end
    TemplateValue(clauses)

  fun _fill_init_clause(
    field_name: String,
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("name") = field_name
    match field_meta.proto_label
    | Required =>
      match field_meta.proto_type
      | MessageType =>
        tpl("type") = field_meta.pony_type_usage
        template_ctx.initialized_required_message_clause.render(tpl)?
      else
        // Both enums and primitive types go through the same steps
        template_ctx.initialized_primitive_clause.render(tpl)?
      end

    | Optional =>
      match field_meta.proto_type
      | MessageType =>
        // Although the field is optional, the underlying message
        // might need checking
        tpl("type") = field_meta.pony_type_usage
        template_ctx.initialized_message_clause.render(tpl)?
      else
        error
      end

    | Repeated =>
      match field_meta.proto_type
      | MessageType =>
        template_ctx.initialized_repeated_clause.render(tpl)?
      else
        // Rest of repeated types are primitives
        error
      end
    else
      // Can't pack message types
      error
    end

  fun _fill_init_clauses(
    field_info: Map[String, FieldMeta] box,
    template_ctx: GenTemplate)
    : TemplateValue
  =>
    let clauses = Array[TemplateValue]
    for (name, meta) in field_info.pairs() do
      try
        clauses.push(
          TemplateValue(_fill_init_clause(name, meta, template_ctx)?)
        )
      end
    end
    TemplateValue(clauses)

  fun _fill_size_clause_packed(
    field_name: String,
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("name") = field_name
    tpl("number") = field_meta.number
    match field_meta.proto_type
    | EnumType =>
      // FIXME(borja): Don't know how to handle these yet
      error
    | MessageType => error // Can't have packed messages
    | PrimitiveType =>
      match field_meta.wire_type
      | VarintField =>
        tpl("method_type") = field_meta.pony_type_usage
        tpl("method") =
          if field_meta.uses_zigzag then
            "packed_varint_zigzag"
          else
            "packed_varint"
          end
      else
        // FIXME(Borja): Handle more packed values
        error
      end
    end
    template_ctx.size_packed_clause.render(tpl)?

  fun _fill_size_clause_default(
    field_name: String,
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("name") = field_name
    tpl("number") = field_meta.number
    tpl("type") = field_meta.pony_type_usage
    match field_meta.proto_type
    | MessageType =>
      tpl("needs_viewpoint") = ""
      tpl("method") = "inner_message"
      tpl("needs_name_arg") = ""
    | EnumType =>
      tpl("method") = "enum"
      tpl("needs_name_arg") = ""
    | PrimitiveType =>
      match field_meta.wire_type
      | Fixed32Field => tpl("method") = "fixed32"
      | Fixed64Field => tpl("method") = "fixed64"
      | DelimitedField =>
        tpl("method") = "delimited"
        // TODO(borja): This is a hack, find a better way
        if field_meta.pony_type_usage == "Array[U8]" then
          tpl("needs_viewpoint") = ""
        end
        tpl("needs_name_arg") = ""
      | VarintField =>
        tpl("method_type") = field_meta.pony_type_usage
        tpl("method") =
          if field_meta.uses_zigzag then
            "varint_zigzag"
          else
            "varint"
          end
        tpl("needs_name_arg") = ""
      end
    end
    match field_meta.proto_label
    | Repeated =>
      tpl("needs_viewpoint") = ""
      template_ctx.size_repeated_clause.render(tpl)?
    else
      // Not packed, handled elsewhere
      template_ctx.size_optional_clause.render(tpl)?
    end

  fun _fill_size_clause(
    field_name: String,
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    match field_meta.proto_label
    | RepeatedPacked =>
      _fill_size_clause_packed(field_name, field_meta, template_ctx)?
    else
      // We handle the rest the same, only difference is the template
      _fill_size_clause_default(field_name, field_meta, template_ctx)?
    end

  fun _fill_size_clauses(
    field_info: Map[String, FieldMeta] box,
    template_ctx: GenTemplate)
    : TemplateValue
  =>
    let clauses = Array[TemplateValue]
    for (name, meta) in field_info.pairs() do
      try
        clauses.push(
          TemplateValue(_fill_size_clause(name, meta, template_ctx)?)
        )
      end
    end
    TemplateValue(clauses)

  fun _fill_read_clause_packed(
    field_name: String,
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("name") = field_name
    tpl("number") = field_meta.number
    tpl("wire_type") = field_meta.wire_type.string()
    match field_meta.proto_type
    | PrimitiveType =>
      match field_meta.wire_type
      | VarintField =>
        tpl("type") = field_meta.pony_type_usage
        if field_meta.uses_zigzag then
          tpl("needs_zigzag") = ""
        end
        // This is for the default case where data arrives unpacked
        tpl("varint_kind") = GenTypes.varint_kind(field_meta.uses_zigzag,
          field_meta.pony_type_usage)
        let conv_type = GenTypes.convtype(VarintField, field_meta.uses_zigzag,
          field_meta.pony_type_usage)
        match conv_type
        | None => None
        | let conv_type': String =>
          tpl("conv_type") = conv_type'
        end
        template_ctx.read_packed_varint.render(tpl)?
      else
        // FIXME(borja): Handle more packed values
        error
      end
    | EnumType =>
      // FIXME(borja): Don't know how to read packed enums
      error
    | MessageType =>
      // In theory, protoc should discard these before it sends us
      // the codegen request, so it should be okay to error here
      error
    end

  fun _fill_read_clause_repeated(
    field_name: String,
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("name") = field_name
    tpl("number") = field_meta.number
    tpl("wire_type") = field_meta.wire_type.string()
    let template = match field_meta.proto_type
    | MessageType =>
      tpl("type") = field_meta.pony_type_usage
      template_ctx.read_repeated_inner_message
    | EnumType =>
      // TODO
      error
    | PrimitiveType =>
      // TODO
      error
    end
    template.render(tpl)?

  fun _fill_read_clause_optional(
    field_name: String,
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("name") = field_name
    tpl("number") = field_meta.number
    tpl("wire_type") = field_meta.wire_type.string()
    let template = match field_meta.proto_type
    | MessageType =>
      tpl("type") = field_meta.pony_type_usage
      template_ctx.read_inner_message
    | EnumType =>
      tpl("enum_builder") = GenNames.enum_builder(field_meta.pony_type_usage)
      template_ctx.read_enum
    | PrimitiveType =>
      match field_meta.wire_type
      | DelimitedField =>
        if field_meta.pony_type_usage == "Array[U8]" then
          template_ctx.read_bytes
        else
          template_ctx.read_string
        end
      | VarintField =>
        tpl("varint_kind") = GenTypes.varint_kind(field_meta.uses_zigzag,
          field_meta.pony_type_usage)
        let conv_type = GenTypes.convtype(VarintField, field_meta.uses_zigzag,
          field_meta.pony_type_usage)
        match conv_type
        | None => None
        | let conv_type': String =>
          tpl("conv_type") = conv_type'
        end
        template_ctx.read_varint
      else
        tpl("fixed_kind") =
          if
            (field_meta.pony_type_usage == "F32") or
            (field_meta.pony_type_usage == "F64") then
              "float"
          else
              "integer"
          end
        tpl("fixed_size") =
          if field_meta.wire_type is Fixed32Field then "32" else "64" end
        // Do we need a cast between types?
        let conv_type = GenTypes.convtype(field_meta.wire_type, false,
         field_meta.pony_type_usage)
        match conv_type
        | None => None
        | let conv_type': String =>
          tpl("conv_type") = conv_type'
        end
        template_ctx.read_fixed
      end
    end
    template.render(tpl)?

  fun _fill_read_clause(
    field_name: String,
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    match field_meta.proto_label
    | RepeatedPacked =>
      _fill_read_clause_packed(field_name, field_meta, template_ctx)?
    | Repeated =>
      _fill_read_clause_repeated(field_name, field_meta, template_ctx)?
    else
      _fill_read_clause_optional(field_name, field_meta, template_ctx)?
    end

  fun _fill_read_clauses(
    field_info: Map[String, FieldMeta] box,
    template_ctx: GenTemplate)
    : TemplateValue
  =>
    let clauses = Array[TemplateValue]
    for (name, meta) in field_info.pairs() do
      try
        clauses.push(
          TemplateValue(_fill_read_clause(name, meta, template_ctx)?)
        )
      end
    end
    TemplateValue(clauses)

  fun ref write_message(
    message_name: String,
    field_info: Map[String, FieldMeta] box,
    template_ctx: GenTemplate)
  =>
    let message_structure = TemplateValues
    message_structure("name") = message_name
    message_structure("fields") = _fill_fields(field_info, template_ctx)
    message_structure("initializer_clauses") = _fill_init_clauses(field_info,
      template_ctx)
    message_structure("field_size_clauses") = _fill_size_clauses(field_info,
      template_ctx)
    message_structure("read_clauses") = _fill_read_clauses(field_info,
      template_ctx)
    message_structure("write_clauses") = _fill_write_clauses(field_info,
      template_ctx)
    try
      _str.append(
        template_ctx.message_structure.render(message_structure)?
      )
    else
      Debug.err("failed to fill template for " + message_name)
    end

  fun ref done(): String val =>
    let to_ret = _str = recover String end
    consume to_ret
