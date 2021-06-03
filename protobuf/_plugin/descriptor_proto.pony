use ".."

class OneofDescriptorProto is ProtoMessage
  var name: (String | None) = None

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, DelimitedField) =>
        name = reader.read_string()?
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

class DescriptorProtoExtensionRange is ProtoMessage
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

class DescriptorProtoReservedRange is ProtoMessage
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

class MessageOptions is ProtoMessage
  var map_entry: (Bool | None) = None

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, VarintField) =>
        map_entry = reader.read_varint_bool()?
      | (_, let typ: TagKind) => reader.skip_field(typ)?
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

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, DelimitedField) =>
        name = reader.read_string()?
      | (2, DelimitedField) =>
        let v: FieldDescriptorProto = FieldDescriptorProto
        v.parse_from_stream(reader.pop_embed()?)?
        field.push(v)
      | (6, DelimitedField) =>
        let v: FieldDescriptorProto = FieldDescriptorProto
        v.parse_from_stream(reader.pop_embed()?)?
        extension.push(v)
      | (3, DelimitedField) =>
        let v: DescriptorProto = DescriptorProto
        v.parse_from_stream(reader.pop_embed()?)?
        nested_type.push(v)
      | (4, DelimitedField) =>
        let v: EnumDescriptorProto = EnumDescriptorProto
        v.parse_from_stream(reader.pop_embed()?)?
        enum_type.push(v)
      | (5, DelimitedField) =>
        let v: DescriptorProtoExtensionRange = DescriptorProtoExtensionRange
        v.parse_from_stream(reader.pop_embed()?)?
        extension_range.push(v)
      | (8, DelimitedField) =>
        let v: OneofDescriptorProto = OneofDescriptorProto
        v.parse_from_stream(reader.pop_embed()?)?
        oneof_decl.push(v)
      | (7, DelimitedField) =>
        let v: MessageOptions = MessageOptions
        v.parse_from_stream(reader.pop_embed()?)?
        options = v
      | (9, DelimitedField) =>
        let v: DescriptorProtoReservedRange = DescriptorProtoReservedRange
        v.parse_from_stream(reader.pop_embed()?)?
        reserved_range.push(v)
      | (10, DelimitedField) =>
        reserved_name = reader.read_string()?
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end
