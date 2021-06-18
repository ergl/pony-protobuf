use "debug" // TODO(borja): remove
use "templates"
use "collections"

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
    enum_builder("name") = GenNames.top_level_name(enum_name + "Builder")
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
    metas: Array[DeclMeta] box,
    template_ctx: GenTemplate)
    : TemplateValue
  =>
    let fields = Array[TemplateValue]
    for elt in metas.values() do
      let tpl = Map[String, TemplateValue]
      match elt
      | let field: FieldMeta =>
        tpl("name") = TemplateValue(field.name)
        tpl("pony_type") = TemplateValue(field.pony_type_decl)
        tpl("default") = TemplateValue(field.default_assignment)
        fields.push(TemplateValue("", tpl))

      | let oneof: OneOfMeta =>
        tpl("name") = TemplateValue(oneof.name)
        tpl("default") = TemplateValue("None")
        let type_alias = Array[TemplateValue]
        for (marker, field) in oneof.fields.values() do
          if field.default_assignment != "None" then
            // FIXME(borja): Custom default values in oneofs are LWW
            tpl("default") = TemplateValue(
              "(" + marker + ", " + field.default_assignment + ")"
            )
          end

          // Build the type alias
          let inner_tpl = TemplateValues
          let inner_tpl_props = Map[String, TemplateValue]
          inner_tpl_props("marker") = TemplateValue(marker)
          // Safe to use inner, repeated fields are not allowed inside oneof
          inner_tpl_props("pony_type") = TemplateValue(field.pony_type_inner)
          type_alias.push(TemplateValue("", inner_tpl_props))
        end
        let alias_tpl = TemplateValues
        alias_tpl("type_aliases") = TemplateValue(type_alias)
        try
          tpl("pony_type") = TemplateValue(
            template_ctx.oneof_field_type_alias.render(
              alias_tpl
            )?
          )
          fields.push(TemplateValue("", tpl))
        end
      end
    end
    TemplateValue(fields)

  fun _fill_write_clause_packed(
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("field") = field_meta.name
    tpl("number") = field_meta.number
    tpl("type") = field_meta.pony_type_inner
    // If it's packed, underlying type has to be primitive or enum
    match field_meta.proto_type
    | PrimitiveType =>
      match field_meta.wire_type
      | VarintField =>
        if field_meta.pony_type_inner == "Bool" then
          template_ctx.write_packed_varint_bool.render(tpl)?
        else
          if field_meta.uses_zigzag then
            template_ctx.write_packed_varint_zigzag.render(tpl)?
          else
            template_ctx.write_packed_varint.render(tpl)?
          end
        end
      else
        // We only have packed Fixed32 and Fixed64, since protoc
        // will discard packed strings and bytes
        tpl("fixed_size") =
          if field_meta.wire_type is Fixed32Field then "32" else "64" end
        template_ctx.write_packed_fixed.render(tpl)?
      end
    | EnumType =>
      template_ctx.write_packed_enum.render(tpl)?
    | MessageType =>
      // In theory, protoc should discard these before it sends us
      // the codegen request, so it should be okay to error here
      error
    end

  fun _fill_write_clause_repeated(
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("field") = field_meta.name
    tpl("number") = field_meta.number
    match field_meta.proto_type
    | PrimitiveType =>
      tpl("tag_kind") = field_meta.wire_type.string()
      match field_meta.wire_type
      | VarintField =>
        tpl("type") = field_meta.pony_type_inner
        tpl("method") =
          if field_meta.uses_zigzag then
            "write_varint_zigzag"
          else
            "write_varint"
          end
      | Fixed32Field =>
        tpl("type") = field_meta.pony_type_inner
        tpl("method") = "write_fixed_32"
      | Fixed64Field =>
        tpl("type") = field_meta.pony_type_inner
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
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("field") = field_meta.name
    tpl("type") = field_meta.pony_type_inner
    if
      (field_meta.proto_type is MessageType) or
      (field_meta.proto_label is Repeated) or
      ((field_meta.wire_type is DelimitedField) and
       (field_meta.pony_type_inner == "Array[U8]"))
    then
      tpl("needs_viewpoint") = ""
    end
    let inner_tpl = TemplateValues
    // Use primed variable inside the optional clause
    inner_tpl("field") = field_meta.name + "'"
    inner_tpl("number") = field_meta.number
    inner_tpl("type") = field_meta.pony_type_inner
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
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    match field_meta.proto_label
    | RepeatedPacked =>
      _fill_write_clause_packed(field_meta, template_ctx)?
    | Repeated =>
      _fill_write_clause_repeated(field_meta, template_ctx)?
    else
      _fill_write_clause_optional(field_meta, template_ctx)?
    end

  fun _fill_write_oneof_clause(
    oneof: OneOfMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    // TODO(borja): Same as _fill_write_clause_optional, refactor
    let tpl = TemplateValues
    tpl("name") = oneof.name
    let clauses = Array[TemplateValue]
    for (marker, field_meta) in oneof.fields.values() do
      let inner_tpl = TemplateValues
      let inner_tpl_props = Map[String, TemplateValue]
      inner_tpl_props("marker") = TemplateValue(marker)
      inner_tpl_props("name") = TemplateValue(field_meta.name)
      inner_tpl_props("type") = TemplateValue(field_meta.pony_type_inner)
      if
        (field_meta.proto_type is MessageType) or
        (field_meta.proto_label is Repeated) or
        ((field_meta.wire_type is DelimitedField) and
         (field_meta.pony_type_inner == "Array[U8]"))
      then
        inner_tpl_props("needs_viewpoint") = TemplateValue("")
      end
      let body_tpl = TemplateValues
      body_tpl("field") = field_meta.name
      body_tpl("number") = field_meta.number
      body_tpl("type") = field_meta.pony_type_inner
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

      inner_tpl_props("body") = TemplateValue(inner_template.render(body_tpl)?)
      clauses.push(TemplateValue("", inner_tpl_props))
    end
    tpl("clauses") = TemplateValue(clauses)
    template_ctx.write_oneof_clause.render(tpl)?

  fun _fill_write_clauses(
    metas: Array[DeclMeta] box,
    template_ctx: GenTemplate)
    : TemplateValue
  =>
    let clauses = Array[TemplateValue]
    for elt in metas.values() do
      try
        match elt
        | let field: FieldMeta =>
          clauses.push(
            TemplateValue(_fill_write_clause(field, template_ctx)?)
          )
        | let oneof: OneOfMeta =>
          clauses.push(
            TemplateValue(_fill_write_oneof_clause(oneof, template_ctx)?)
          )
        end
      end
    end
    TemplateValue(clauses)

  fun _fill_init_clause(
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("name") = field_meta.name
    match field_meta.proto_label
    | Required =>
      match field_meta.proto_type
      | MessageType =>
        tpl("type") = field_meta.pony_type_inner
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
        tpl("type") = field_meta.pony_type_inner
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

  fun _fill_init_oneof_clause(
    oneof: OneOfMeta,
    template_ctx: GenTemplate)
    : (String | None)
    ?
  =>
    // Oneof fields can never be required, but one of the
    // options might be a message type with a required type
    // We will only generate a match block if there are
    // message options. If there's any non-message option,
    // generate a catch-all match clause.
    let tpl = TemplateValues
    tpl("name") = oneof.name
    var more_fields = false
    var need_to_generate = false
    let clauses = Array[TemplateValue]
    for (name, meta) in oneof.fields.values() do
      if meta.proto_type is MessageType then
        need_to_generate = true
        let inner_tpl = TemplateValues
        let inner_tpl_props = Map[String, TemplateValue]
        inner_tpl_props("marker") = TemplateValue(name)
        inner_tpl_props("name") = TemplateValue(meta.name)
        inner_tpl_props("type") = TemplateValue(meta.pony_type_inner)
        clauses.push(TemplateValue("", inner_tpl_props))
      else
        more_fields = true
      end
    end
    if need_to_generate then
      if more_fields then
        tpl("more_fields") = ""
      end
      tpl("clauses") = TemplateValue(clauses)
      template_ctx.initialized_oneof_clause.render(tpl)?
    end

  fun _fill_init_clauses(
    metas: Array[DeclMeta] box,
    template_ctx: GenTemplate)
    : TemplateValue
  =>
    let clauses = Array[TemplateValue]
    for elt in metas.values() do
      try
        match elt
        | let field: FieldMeta =>
          clauses.push(
            TemplateValue(_fill_init_clause(field, template_ctx)?)
          )
        | let oneof: OneOfMeta =>
          match _fill_init_oneof_clause(oneof, template_ctx)?
          | let str: String =>
            clauses.push(TemplateValue(str))
          | None =>
            None
          end
        end
      end
    end
    TemplateValue(clauses)

  fun _fill_size_clause_packed(
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("name") = field_meta.name
    tpl("number") = field_meta.number
    match field_meta.proto_type
    | MessageType => error // Can't have packed messages
    | EnumType =>
      tpl("method") = "packed_enum"
      tpl("method_type") = field_meta.pony_type_inner
    | PrimitiveType =>
      match field_meta.wire_type
      | VarintField =>
        tpl("method_type") = field_meta.pony_type_inner
        tpl("method") =
          if field_meta.uses_zigzag then
            "packed_varint_zigzag"
          else
            "packed_varint"
          end
      else
        // We only have packed Fixed32 and Fixed64, since protoc
        // will discard packed strings and bytes
        tpl("method_type") = field_meta.pony_type_inner
        tpl("method") =
          if field_meta.wire_type is Fixed32Field then
            "packed_fixed32"
          else
            "packed_fixed64"
          end
      end
    end
    template_ctx.size_packed_clause.render(tpl)?

  fun _fill_size_clause_default(
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("name") = field_meta.name
    tpl("number") = field_meta.number
    tpl("type") = field_meta.pony_type_inner
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
        if field_meta.pony_type_inner == "Array[U8]" then
          tpl("needs_viewpoint") = ""
        end
        tpl("needs_name_arg") = ""
      | VarintField =>
        tpl("method_type") = field_meta.pony_type_inner
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
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    match field_meta.proto_label
    | RepeatedPacked =>
      _fill_size_clause_packed(field_meta, template_ctx)?
    else
      // We handle the rest the same, only difference is the template
      _fill_size_clause_default(field_meta, template_ctx)?
    end

  fun _fill_size_oneof_clause(
    oneof: OneOfMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    // This is the same as _fill_size_clause_default, find a way
    // to refactor
    let tpl = TemplateValues
    tpl("name") = oneof.name
    let clauses = Array[TemplateValue]
    for (name, field_meta) in oneof.fields.values() do
      let inner_tpl = TemplateValues
      let inner_tpl_props = Map[String, TemplateValue]
      inner_tpl_props("marker") = TemplateValue(name)
      inner_tpl_props("name") = TemplateValue(field_meta.name)
      inner_tpl_props("number") = TemplateValue(field_meta.number)
      inner_tpl_props("type") = TemplateValue(field_meta.pony_type_inner)
      match field_meta.proto_type
      | MessageType =>
        inner_tpl_props("needs_viewpoint") = TemplateValue("")
        inner_tpl_props("method") = TemplateValue("inner_message")
        inner_tpl_props("needs_name_arg") = TemplateValue("")
      | EnumType =>
        inner_tpl_props("method") = TemplateValue("enum")
        inner_tpl_props("needs_name_arg") = TemplateValue("")
      | PrimitiveType =>
        match field_meta.wire_type
        | Fixed32Field => inner_tpl_props("method") = TemplateValue("fixed32")
        | Fixed64Field => inner_tpl_props("method") = TemplateValue("fixed64")
        | DelimitedField =>
          inner_tpl_props("method") = TemplateValue("delimited")
          // TODO(borja): This is a hack, find a better way
          if field_meta.pony_type_inner == "Array[U8]" then
            inner_tpl_props("needs_viewpoint") = TemplateValue("")
          end
          inner_tpl_props("needs_name_arg") = TemplateValue("")
        | VarintField =>
          inner_tpl_props("method_type") =
            TemplateValue(field_meta.pony_type_inner)
          inner_tpl_props("method") =
            if field_meta.uses_zigzag then
              TemplateValue("varint_zigzag")
            else
              TemplateValue("varint")
            end
          inner_tpl_props("needs_name_arg") = TemplateValue("")
        end
      end
      clauses.push(TemplateValue("", inner_tpl_props))
    end
    tpl("clauses") = TemplateValue(clauses)
    template_ctx.size_oneof_clause.render(tpl)?

  fun _fill_size_clauses(
    metas: Array[DeclMeta] box,
    template_ctx: GenTemplate)
    : TemplateValue
  =>
    let clauses = Array[TemplateValue]
    for elt in metas.values() do
      try
        match elt
        | let field: FieldMeta =>
          clauses.push(
            TemplateValue(_fill_size_clause(field, template_ctx)?)
          )
        | let oneof: OneOfMeta =>
          clauses.push(
            TemplateValue(_fill_size_oneof_clause(oneof, template_ctx)?)
          )
        end
      end
    end
    TemplateValue(clauses)

  fun _fill_read_clause_packed(
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("name") = field_meta.name
    tpl("number") = field_meta.number
    tpl("wire_type") = field_meta.wire_type.string()
    match field_meta.proto_type
    | PrimitiveType =>
      match field_meta.wire_type
      | VarintField =>
        tpl("type") = field_meta.pony_type_inner
        if field_meta.uses_zigzag then
          tpl("needs_zigzag") = ""
        end
        // This is for the default case where data arrives unpacked
        tpl("varint_kind") = GenTypes.varint_kind(field_meta.uses_zigzag,
          field_meta.pony_type_inner)
        let conv_type = GenTypes.convtype(VarintField, field_meta.uses_zigzag,
          field_meta.pony_type_inner)
        match conv_type
        | None => None
        | let conv_type': String =>
          tpl("conv_type") = conv_type'
        end
        template_ctx.read_packed_varint.render(tpl)?
      else
        // We only have packed Fixed32 and Fixed64, since protoc
        // will discard packed strings and bytes
        tpl("type") = field_meta.pony_type_inner
        tpl("fixed_kind") =
          if
            (field_meta.pony_type_inner == "F32") or
            (field_meta.pony_type_inner == "F64") then
              "float"
          else
              "integer"
          end
        tpl("fixed_size") =
          if field_meta.wire_type is Fixed32Field then "32" else "64" end
        let conv_type = GenTypes.convtype(field_meta.wire_type, false,
         field_meta.pony_type_inner)
        match conv_type
        | None => None
        | let conv_type': String =>
          tpl("conv_type") = conv_type'
        end
        template_ctx.read_packed_fixed.render(tpl)?
      end
    | EnumType =>
      tpl("type") = field_meta.pony_type_inner
      tpl("enum_builder") = GenNames.enum_builder(field_meta.pony_type_inner)
      template_ctx.read_packed_enum.render(tpl)?
    | MessageType =>
      // In theory, protoc should discard these before it sends us
      // the codegen request, so it should be okay to error here
      error
    end

  fun _fill_read_clause_repeated(
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("name") = field_meta.name
    tpl("number") = field_meta.number
    tpl("wire_type") = field_meta.wire_type.string()
    let template = match field_meta.proto_type
    | PrimitiveType =>
      match field_meta.wire_type
      | DelimitedField =>
        if field_meta.pony_type_inner == "Array[U8]" then
          template_ctx.read_repeated_bytes
        else
          template_ctx.read_repeated_string
        end
      | VarintField =>
        tpl("varint_kind") = GenTypes.varint_kind(field_meta.uses_zigzag,
          field_meta.pony_type_inner)
        let conv_type = GenTypes.convtype(VarintField, field_meta.uses_zigzag,
          field_meta.pony_type_inner)
        match conv_type
        | None => None
        | let conv_type': String =>
          tpl("conv_type") = conv_type'
        end
        template_ctx.read_repeated_varint
      else
        tpl("fixed_kind") =
          if
            (field_meta.pony_type_inner == "F32") or
            (field_meta.pony_type_inner == "F64") then
              "float"
          else
              "integer"
          end
        tpl("fixed_size") =
          if field_meta.wire_type is Fixed32Field then "32" else "64" end
        // Do we need a cast between types?
        let conv_type = GenTypes.convtype(field_meta.wire_type, false,
         field_meta.pony_type_inner)
        match conv_type
        | None => None
        | let conv_type': String =>
          tpl("conv_type") = conv_type'
        end
        template_ctx.read_repeated_fixed
      end
    | EnumType =>
      tpl("type") = field_meta.pony_type_inner
      tpl("enum_builder") = GenNames.enum_builder(field_meta.pony_type_inner)
      template_ctx.read_repeated_enum
    | MessageType =>
      tpl("type") = field_meta.pony_type_inner
      template_ctx.read_repeated_inner_message
    end
    template.render(tpl)?

  fun _fill_read_clause_optional(
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    let tpl = TemplateValues
    tpl("name") = field_meta.name
    tpl("number") = field_meta.number
    tpl("wire_type") = field_meta.wire_type.string()
    let template = match field_meta.proto_type
    | MessageType =>
      tpl("type") = field_meta.pony_type_inner
      template_ctx.read_inner_message
    | EnumType =>
      tpl("enum_builder") = GenNames.enum_builder(field_meta.pony_type_inner)
      template_ctx.read_enum
    | PrimitiveType =>
      match field_meta.wire_type
      | DelimitedField =>
        if field_meta.pony_type_inner == "Array[U8]" then
          template_ctx.read_bytes
        else
          template_ctx.read_string
        end
      | VarintField =>
        tpl("varint_kind") = GenTypes.varint_kind(field_meta.uses_zigzag,
          field_meta.pony_type_inner)
        let conv_type = GenTypes.convtype(VarintField, field_meta.uses_zigzag,
          field_meta.pony_type_inner)
        match conv_type
        | None => None
        | let conv_type': String =>
          tpl("conv_type") = conv_type'
        end
        template_ctx.read_varint
      else
        tpl("fixed_kind") =
          if
            (field_meta.pony_type_inner == "F32") or
            (field_meta.pony_type_inner == "F64") then
              "float"
          else
              "integer"
          end
        tpl("fixed_size") =
          if field_meta.wire_type is Fixed32Field then "32" else "64" end
        // Do we need a cast between types?
        let conv_type = GenTypes.convtype(field_meta.wire_type, false,
         field_meta.pony_type_inner)
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
    field_meta: FieldMeta,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    match field_meta.proto_label
    | RepeatedPacked =>
      _fill_read_clause_packed(field_meta, template_ctx)?
    | Repeated =>
      _fill_read_clause_repeated(field_meta, template_ctx)?
    else
      _fill_read_clause_optional(field_meta, template_ctx)?
    end

  fun _fill_read_oneof_clause(
    field_meta: FieldMeta,
    tpl: TemplateValues,
    template_ctx: GenTemplate)
    : String
    ?
  =>
    // TODO(borja): Same as _fill_read_clause_optional, refactor
    tpl("name") = field_meta.name
    tpl("number") = field_meta.number
    tpl("wire_type") = field_meta.wire_type.string()
    let template = match field_meta.proto_type
    | MessageType =>
      tpl("type") = field_meta.pony_type_inner
      template_ctx.read_inner_message_oneof
    | EnumType =>
      tpl("enum_builder") = GenNames.enum_builder(field_meta.pony_type_inner)
      template_ctx.read_enum
    | PrimitiveType =>
      match field_meta.wire_type
      | DelimitedField =>
        if field_meta.pony_type_inner == "Array[U8]" then
          template_ctx.read_bytes
        else
          template_ctx.read_string
        end
      | VarintField =>
        tpl("varint_kind") = GenTypes.varint_kind(field_meta.uses_zigzag,
          field_meta.pony_type_inner)
        let conv_type = GenTypes.convtype(VarintField, field_meta.uses_zigzag,
          field_meta.pony_type_inner)
        match conv_type
        | None => None
        | let conv_type': String =>
          tpl("conv_type") = conv_type'
        end
        template_ctx.read_varint
      else
        tpl("fixed_kind") =
          if
            (field_meta.pony_type_inner == "F32") or
            (field_meta.pony_type_inner == "F64") then
              "float"
          else
              "integer"
          end
        tpl("fixed_size") =
          if field_meta.wire_type is Fixed32Field then "32" else "64" end
        // Do we need a cast between types?
        let conv_type = GenTypes.convtype(field_meta.wire_type, false,
         field_meta.pony_type_inner)
        match conv_type
        | None => None
        | let conv_type': String =>
          tpl("conv_type") = conv_type'
        end
        template_ctx.read_fixed
      end
    end
    template.render(tpl)?

  fun _fill_read_clauses(
    metas: Array[DeclMeta] box,
    template_ctx: GenTemplate)
    : TemplateValue
  =>
    let clauses = Array[TemplateValue]
    for elt in metas.values() do
      try
        match elt
        | let field: FieldMeta =>
          clauses.push(
            TemplateValue(_fill_read_clause(field, template_ctx)?)
          )
        | let oneof: OneOfMeta =>
          for (marker, field) in oneof.fields.values() do
            let tpl = TemplateValues
            tpl("oneof") = ""
            tpl("field_name") = oneof.name
            tpl("marker") = marker
            clauses.push(
              TemplateValue(_fill_read_oneof_clause(field, tpl, template_ctx)?)
          )
          end
        end
      end
    end
    TemplateValue(clauses)

  fun _fill_oneof_primitives(field_info: Array[DeclMeta] box): TemplateValue =>
    let primitives = Array[TemplateValue]
    for f in field_info.values() do
      match f
      | let meta: OneOfMeta =>
        for (name, _) in meta.fields.values() do
          primitives.push(TemplateValue(name))
        end
      else
        None
      end
    end
    TemplateValue(primitives)

  fun ref write_message(
    message_name: String,
    field_info: Array[DeclMeta] box,
    template_ctx: GenTemplate)
  =>
    let message_structure = TemplateValues
    message_structure("oneof_primitives") = _fill_oneof_primitives(field_info)
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

  // TODO(borja): Track errors, return if anything happened when writing
  fun ref done(): Result[String, String] =>
    let to_ret = _str = recover String end
    (Ok, consume to_ret)
