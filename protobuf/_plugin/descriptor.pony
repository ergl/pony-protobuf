use "buffered"
use ".."

class FileDescriptorProto is ProtoMessage
  var name: (String | None) = None
  var package: (String | None) = None
  var dependency: Array[String] = Array[String]
  var public_dependency: Array[I32] = Array[I32]
  var message_type: Array[DescriptorProto] = Array[DescriptorProto]
  var enum_type: Array[EnumDescriptorProto] = Array[EnumDescriptorProto]
  var extension: Array[FieldDescriptorProto] = Array[FieldDescriptorProto]
  var syntax: (String | None) = None
  embed _reader: Reader = Reader

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, DelimitedField) =>
        name = DelimitedDecoder.decode_string(buffer) ?
      | (2, DelimitedField) =>
        package = DelimitedDecoder.decode_string(buffer) ?
      | (10, VarintField) =>
        let v = IntegerDecoder.decode_signed(buffer)?.i32()
        public_dependency.push(v)
      | (4, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: DescriptorProto = DescriptorProto
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        message_type.push(v)
      | (5, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: EnumDescriptorProto = EnumDescriptorProto
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        enum_type.push(v)
      | (7, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: FieldDescriptorProto = FieldDescriptorProto
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        extension.push(v)
      | (12, DelimitedField) =>
        syntax = DelimitedDecoder.decode_string(buffer)?
      | (_, let typ : KeyType) => SkipField(typ, buffer) ?
      end
    end

// No need to use this for now, ProtoMessage has nice defaults
class GeneratedCodeInfo is ProtoMessage
