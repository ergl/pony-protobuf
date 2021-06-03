use ".."

class EnumDescriptorProtoEnumReservedRange is ProtoMessage
  var start: (I32 | None) = None
  var field_end: (I32 | None) = None

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, VarintField) =>
        start = reader.read_varint_32()?.i32()
      | (2, VarintField) =>
        field_end = reader.read_varint_32()?.i32()
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

class EnumValueDescriptorProto is ProtoMessage
  var name: (String | None) = None
  var number: (I32 | None) = None

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, DelimitedField) =>
        name = reader.read_string()?
      | (2, VarintField) =>
        number = reader.read_varint_32()?.i32()
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

class EnumDescriptorProto is ProtoMessage
  var name: (String | None) = None
  var value: Array[EnumValueDescriptorProto] = Array[EnumValueDescriptorProto]
  var reserved_range: Array[EnumDescriptorProtoEnumReservedRange] = Array[EnumDescriptorProtoEnumReservedRange]
  var reserved_name: (String | None) = None

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, DelimitedField) =>
        name = reader.read_string()?
      | (2, DelimitedField) =>
        let v: EnumValueDescriptorProto = EnumValueDescriptorProto
        v.parse_from_stream(reader.pop_embed()?)?
        value.push(v)
      | (4, DelimitedField) =>
        let v: EnumDescriptorProtoEnumReservedRange = EnumDescriptorProtoEnumReservedRange
        v.parse_from_stream(reader.pop_embed()?)?
        reserved_range.push(v)
      | (5, DelimitedField) =>
        reserved_name = reader.read_string()?
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end
