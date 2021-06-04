use "templates"
use "collections"
use "debug" // TODO(borja): remove

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

  fun ref write_message(
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

  fun ref done(): String val =>
    let to_ret = _str = recover String end
    consume to_ret
