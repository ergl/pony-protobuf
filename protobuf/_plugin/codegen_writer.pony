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
    if field_meta.proto_type is MessageType then
      tpl("is_message") = ""
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
    | Optional =>
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

  fun ref write_message(
    message_name: String,
    field_info: Map[String, FieldMeta] box,
    template_ctx: GenTemplate)
  =>
    let message_structure = TemplateValues
    message_structure("name") = message_name
    message_structure("fields") = _fill_fields(field_info, template_ctx)
    message_structure("initializer_clauses") =
      TemplateValue(Array[TemplateValue])
    message_structure("field_size_clauses") =
      TemplateValue(Array[TemplateValue])
    message_structure("read_clauses") =
      TemplateValue(Array[TemplateValue])
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
