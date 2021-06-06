use "templates"

class val GenTemplate
  let header: Template

  // Enums
  let enum_field: Template
  let enum_alias: Template
  let enum_builder: Template

  // Message
  let message_structure: Template

  // is_initialized
  let initialized_primitive_clause: Template
  let initialized_message_clause: Template
  let initialized_required_message_clause: Template
  let initialized_repeated_clause: Template

  // write_to_stream
  let write_bytes: Template
  let write_enum: Template
  let write_varint: Template
  let write_varint_zigzag: Template
  let write_fixed_32: Template
  let write_fixed_64: Template
  let write_inner_message: Template
  let write_repeated_non_message_type: Template
  let write_repeated_inner_message_clause: Template
  let write_packed_varint: Template
  let write_optional_clause: Template

  new val create() ? =>
    header = Template.parse(
      """
      // This file was autogenerated by pony-protobuf {{vsn}}. Do not edit!
      // Compiled by protoc {{protoc_version}}

      use "protobuf"

      """
    )?

    enum_field = Template.parse(
      """
      primitive {{name}} is ProtoEnumValue
        fun as_i32(): I32 => {{value}}

      """
    )?

    enum_alias = Template.parse(
      """
      type {{name}} is (
        {{first_alias}}{{ifnotempty rest_alias}}{{for x in rest_alias}}
        | {{x}}{{end}}{{end}}
      )

      """
    )?

    enum_builder = Template.parse(
      """
      primitive {{name}} is ProtoEnum
        fun from_i32(value: I32): ({{enum_type}} | None) =>
          match value{{for x in match_clauses }}
          | {{x.value}} => {{x.name}}{{end}}
          else
            None
          end

      """
    )?

    message_structure = Template.parse(
      """
      class {{name}} is ProtoMessage{{ifnotempty fields}}{{for field in fields}}
        var {{field.name}}: {{field.pony_type}} = {{field.default}}{{end}}{{end}}

        {{ifnotempty initializer_clauses}}
        fun is_initialized(): Bool =>{{for clause in initializer_clauses}}
          {{clause}}{{end}}
          true{{end}}

        {{ifnotempty field_size_clauses}}
        fun compute_size(): U32 =>
          var size: U32 = 0{{for clause in field_size_clauses}}
          {{clause}}{{end}}
          size{{end}}

        {{ifnotempty read_clauses}}
        fun ref parse_from_stream(reader: ProtoReader) ? =>
          while reader.size() > 0
            match reader.read_field_tag()?{{for clause in read_clauses}}
            {{clause}}{{end}}
            | (_, let typ: TagKind) => reader.skip_field(typ)?
            end
          end{{end}}

        {{ifnotempty write_clauses}}
        fun write_to_stream(writer: ProtoWriter) =>{{for clause in write_clauses}}
          {{clause}}{{end}}{{end}}

      """
    )?

    initialized_primitive_clause = Template.parse(
      """
      if {{name}} is None then
            return false
          end"""
    )?

    initialized_message_clause = Template.parse(
      """
      match {{name}}
          | None => None
          | let {{name}}': this->{{type}} =>
            if not ({{name}}'.is_initialized()) then
              return false
            end
          end"""
    )?

    initialized_required_message_clause = Template.parse(
      """
      match {{name}}
          | None => return false
          | let {{name}}': this->{{type}} =>
            if not ({{name}}'.is_initialized()) then
              return falsse
            end
          end"""
    )?

    initialized_repeated_clause = Template.parse(
      """
      for v in {{name}}.values() do
            if not v.is_initialized() then
              return false
            end
          end"""
    )?

    write_optional_clause = Template.parse(
      """
      match {{field}}
          | None => None
          | let {{field}}': {{if is_message}}this->{{end}}{{type}} =>
            {{body}}
          end"""
    )?

    write_bytes = Template.parse(
      """
      writer.write_tag({{number}}, DelimitedField)
            writer.write_bytes({{field}})"""
    )?

    write_enum = Template.parse(
      """
      writer.write_tag({{number}}, VarintField)
            writer.write_enum({{field}})"""
    )?

    write_varint = Template.parse(
      """
      writer.write_tag({{number}}, VarintField)
            writer.write_varint[{{type}}]({{field}})"""
    )?

    write_varint_zigzag = Template.parse(
      """
      writer.write_tag({{number}}, VarintField)
            writer.write_varint_zigzag[{{type}}]({{field}})"""
    )?

    write_fixed_32 = Template.parse(
      """
      writer.write_tag({{number}}, Fixed32Field)
            writer.write_fixed_32[{{type}}]({{field}})"""
    )?

    write_fixed_64 = Template.parse(
      """
      writer.write_tag({{number}}, Fixed32Field)
            writer.write_fixed_64[{{type}}]({{field}})"""
    )?

    write_inner_message = Template.parse(
      """
      writer.write_tag({{number}}, DelimitedField)
            writer.write_varint[U32]({{field}}.compute_size())
            {{field}}.write_to_stream(writer)"""
    )?

    write_repeated_non_message_type = Template.parse(
      """
      for v in {{field}}.values() do
            writer.write_tag({{number}}, {{tag_kind}})
            writer.{{method}}{{if type}}[{{type}}]{{end}}(v)
          end"""
    )?

    // TODO(borja): This is rendered with wonky indentation
    // Perhaps due to it being serialized to string before putting it
    // into another template?
    write_packed_varint = Template.parse(
      """
      if {{field}}.size() != 0 then
            var {{field}}_size: U32 = 0
            for v in {{field}}.values() do
              {{field}}_size = {{field}}_size + FieldSize.raw_varint(v.u64())
            end
            writer.write_tag({{number}}, DelimitedField)
            writer.write_packed_varint[{{type}}]({{field}}, {{field}}_size)
          end"""
    )?

    // TODO(borja): This is rendered with wonky indentation
    // Perhaps due to it being serialized to string before putting it
    // into another template?
    write_repeated_inner_message_clause = Template.parse(
      """
      for v in {{field}}.values() do
            writer.write_tag({{number}}, DelimitedField)
            // TODO: Don't recompute size here, it's wasteful
            writer.write_varint[U32](v.compute_size())
            v.write_to_stream(writer)
          end"""
    )?
