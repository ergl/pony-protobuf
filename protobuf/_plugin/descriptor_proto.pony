use "buffered"
use ".."

class OneofDescriptorProto is ProtoMessage
  var name: (String | None) = None

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, DelimitedField) =>
        name = DelimitedDecoder.decode_string(buffer) ?
      | (_, let typ: TagKind) => SkipField(typ, buffer) ?
      end
    end

class DescriptorProtoExtensionRange is ProtoMessage
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

class DescriptorProtoReservedRange is ProtoMessage
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

class MessageOptions is ProtoMessage
  var map_entry: (Bool | None) = None

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, VarintField) =>
        map_entry = BoolDecoder(buffer) ?
      | (_, let typ: TagKind) => SkipField(typ, buffer) ?
      end
    end

class DescriptorProto is ProtoMessage
  var name: (String | None) = None
  var field: Array[FieldDescriptorProto] = Array[FieldDescriptorProto]
  var extension: Array[FieldDescriptorProto] = Array[FieldDescriptorProto]
  var nested_type: Array[DescriptorProto] = Array[DescriptorProto]
  var enum_type: Array[EnumDescriptorProto] = Array[EnumDescriptorProto]
  var extension_range: Array[DescriptorProtoExtensionRange] = Array[DescriptorProtoExtensionRange]
  var oneof_decl: Array[OneofDescriptorProto] = Array[OneofDescriptorProto]
  var options: (MessageOptions | None) = None
  var reserved_range: Array[DescriptorProtoReservedRange] = Array[DescriptorProtoReservedRange]
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
        let v: FieldDescriptorProto = FieldDescriptorProto
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        field.push(v)
      | (6, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: FieldDescriptorProto = FieldDescriptorProto
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        extension.push(v)
      | (3, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: DescriptorProto = DescriptorProto
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        nested_type.push(v)
      | (4, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: EnumDescriptorProto = EnumDescriptorProto
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        enum_type.push(v)
      | (5, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: DescriptorProtoExtensionRange = DescriptorProtoExtensionRange
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        extension_range.push(v)
      | (8, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: OneofDescriptorProto = OneofDescriptorProto
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        oneof_decl.push(v)
      | (7, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: MessageOptions = MessageOptions
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        options = v
      | (9, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: DescriptorProtoReservedRange = DescriptorProtoReservedRange
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        reserved_range.push(v)
      | (10, DelimitedField) =>
        reserved_name = DelimitedDecoder.decode_string(buffer) ?
      | (_, let typ: TagKind) => SkipField(typ, buffer) ?
      end
    end
