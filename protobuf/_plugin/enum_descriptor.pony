use "buffered"
use ".."

class EnumDescriptorProtoEnumReservedRange is ProtoMessage
  var start: (I32 | None) = None
  var field_end: (I32 | None) = None

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, VarintField) =>
        start = IntegerDecoder.decode_signed(buffer)?.i32()
      | (2, VarintField) =>
        field_end = IntegerDecoder.decode_signed(buffer)?.i32()
      | (_, let typ: TagKind) => SkipField(typ, buffer) ?
      end
    end

class EnumValueDescriptorProto is ProtoMessage
  var name: (String | None) = None
  var number: (I32 | None) = None

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, DelimitedField) =>
        name = DelimitedDecoder.decode_string(buffer) ?
      | (2, VarintField) =>
        number = IntegerDecoder.decode_signed(buffer)?.i32()
      | (_, let typ: TagKind) => SkipField(typ, buffer) ?
      end
    end

class EnumDescriptorProto is ProtoMessage
  var name: (String | None) = None
  var value: Array[EnumValueDescriptorProto] = Array[EnumValueDescriptorProto]
  var reserved_range: Array[EnumDescriptorProtoEnumReservedRange] = Array[EnumDescriptorProtoEnumReservedRange]
  var reserved_name: (String | None) = None
  embed _reader: Reader = Reader

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, DelimitedField) =>
        name = DelimitedDecoder.decode_string(buffer) ?
      | (2, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: EnumValueDescriptorProto = EnumValueDescriptorProto
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        value.push(v)
      | (4, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: EnumDescriptorProtoEnumReservedRange = EnumDescriptorProtoEnumReservedRange
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        reserved_range.push(v)
      | (5, DelimitedField) =>
        reserved_name = DelimitedDecoder.decode_string(buffer) ?
      | (_, let typ: TagKind) => SkipField(typ, buffer) ?
      end
    end
