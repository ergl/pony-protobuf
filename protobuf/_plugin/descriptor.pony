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

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, DelimitedField) =>
        name = reader.read_string()?
      | (2, DelimitedField) =>
        package = reader.read_string()?
      | (10, VarintField) =>
        let v = reader.read_varint_32()?.i32()
        public_dependency.push(v)
      | (4, DelimitedField) =>
        let v: DescriptorProto = DescriptorProto
        v.parse_from_stream(reader.pop_embed()?)?
        message_type.push(v)
      | (5, DelimitedField) =>
        let v: EnumDescriptorProto = EnumDescriptorProto
        v.parse_from_stream(reader.pop_embed()?)?
        enum_type.push(v)
      | (7, DelimitedField) =>
        let v: FieldDescriptorProto = FieldDescriptorProto
        v.parse_from_stream(reader.pop_embed()?)?
        extension.push(v)
      | (12, DelimitedField) =>
        syntax = reader.read_string()?
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

// No need to use this for now, ProtoMessage has nice defaults
class GeneratedCodeInfo is ProtoMessage
