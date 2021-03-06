// This file was autogenerated by pony-protobuf 0.1.0-a48b754 [release]. Do not edit!
// Compiled by protoc 3.17.3

use ".."

class EnumDescriptorProtoEnumReservedRange is ProtoMessage
  var start: (I32 | None) = None
  var end_field: (I32 | None) = None

  fun compute_size(): U32 =>
    var size: U32 = 0
    match start
    | None => None
    | let start': I32 =>
      size = size + FieldSize.varint[I32](1, start')
    end
    match end_field
    | None => None
    | let end_field': I32 =>
      size = size + FieldSize.varint[I32](2, end_field')
    end
    size

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, VarintField) =>
        start = reader.read_varint_32()?.i32()
      | (2, VarintField) =>
        end_field = reader.read_varint_32()?.i32()
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    match start
    | None => None
    | let start': I32 =>
      writer.write_tag(1, VarintField)
      writer.write_varint[I32](start')
    end
    match end_field
    | None => None
    | let end_field': I32 =>
      writer.write_tag(2, VarintField)
      writer.write_varint[I32](end_field')
    end

class EnumDescriptorProto is ProtoMessage
  var name: (String | None) = None
  var value: Array[EnumValueDescriptorProto] = Array[EnumValueDescriptorProto]
  var options: (EnumOptions | None) = None
  var reserved_range: Array[EnumDescriptorProtoEnumReservedRange] = Array[EnumDescriptorProtoEnumReservedRange]
  var reserved_name: Array[String] = Array[String]

  fun compute_size(): U32 =>
    var size: U32 = 0
    match name
    | None => None
    | let name': String =>
      size = size + FieldSize.delimited(1, name')
    end
    for v in value.values() do
      size = size + FieldSize.inner_message(2, v)
    end
    match options
    | None => None
    | let options': this->EnumOptions =>
      size = size + FieldSize.inner_message(3, options')
    end
    for v in reserved_range.values() do
      size = size + FieldSize.inner_message(4, v)
    end
    for v in reserved_name.values() do
      size = size + FieldSize.delimited(5, v)
    end
    size

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, DelimitedField) =>
        name = reader.read_string()?
      | (2, DelimitedField) =>
        let v: EnumValueDescriptorProto = EnumValueDescriptorProto
        v.parse_from_stream(reader.pop_embed()?)?
        value.push(v)
      | (3, DelimitedField) =>
        match options
        | None =>
          options = EnumOptions.>parse_from_stream(reader.pop_embed()?)?
        | let options': EnumOptions =>
          options'.parse_from_stream(reader.pop_embed()?)?
        end
      | (4, DelimitedField) =>
        let v: EnumDescriptorProtoEnumReservedRange = EnumDescriptorProtoEnumReservedRange
        v.parse_from_stream(reader.pop_embed()?)?
        reserved_range.push(v)
      | (5, DelimitedField) =>
        reserved_name.push(reader.read_string()?)
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    match name
    | None => None
    | let name': String =>
      writer.write_tag(1, DelimitedField)
      writer.write_bytes(name')
    end
    for v in value.values() do
      writer.write_tag(2, DelimitedField)
      // TODO: Don't recompute size here, it's wasteful
      writer.write_varint[U32](v.compute_size())
      v.write_to_stream(writer)
    end
    match options
    | None => None
    | let options': this->EnumOptions =>
      writer.write_tag(3, DelimitedField)
      // TODO: Don't recompute size here, it's wasteful
      writer.write_varint[U32](options'.compute_size())
      options'.write_to_stream(writer)
    end
    for v in reserved_range.values() do
      writer.write_tag(4, DelimitedField)
      // TODO: Don't recompute size here, it's wasteful
      writer.write_varint[U32](v.compute_size())
      v.write_to_stream(writer)
    end
    for v in reserved_name.values() do
      writer.write_tag(5, DelimitedField)
      writer.write_bytes(v)
    end

  fun is_initialized(): Bool =>
    for v in value.values() do
      if not v.is_initialized() then
        return false
      end
    end
    match options
    | None => None
    | let options': this->EnumOptions =>
      if not (options'.is_initialized()) then
        return false
      end
    end
    for v in reserved_range.values() do
      if not v.is_initialized() then
        return false
      end
    end
    true

class EnumValueDescriptorProto is ProtoMessage
  var name: (String | None) = None
  var number: (I32 | None) = None
  var options: (EnumValueOptions | None) = None

  fun compute_size(): U32 =>
    var size: U32 = 0
    match name
    | None => None
    | let name': String =>
      size = size + FieldSize.delimited(1, name')
    end
    match number
    | None => None
    | let number': I32 =>
      size = size + FieldSize.varint[I32](2, number')
    end
    match options
    | None => None
    | let options': this->EnumValueOptions =>
      size = size + FieldSize.inner_message(3, options')
    end
    size

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, DelimitedField) =>
        name = reader.read_string()?
      | (2, VarintField) =>
        number = reader.read_varint_32()?.i32()
      | (3, DelimitedField) =>
        match options
        | None =>
          options = EnumValueOptions.>parse_from_stream(reader.pop_embed()?)?
        | let options': EnumValueOptions =>
          options'.parse_from_stream(reader.pop_embed()?)?
        end
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    match name
    | None => None
    | let name': String =>
      writer.write_tag(1, DelimitedField)
      writer.write_bytes(name')
    end
    match number
    | None => None
    | let number': I32 =>
      writer.write_tag(2, VarintField)
      writer.write_varint[I32](number')
    end
    match options
    | None => None
    | let options': this->EnumValueOptions =>
      writer.write_tag(3, DelimitedField)
      // TODO: Don't recompute size here, it's wasteful
      writer.write_varint[U32](options'.compute_size())
      options'.write_to_stream(writer)
    end

  fun is_initialized(): Bool =>
    match options
    | None => None
    | let options': this->EnumValueOptions =>
      if not (options'.is_initialized()) then
        return false
      end
    end
    true

class EnumOptions is ProtoMessage
  var allow_alias: (Bool | None) = None
  var deprecated: (Bool | None) = false
  var uninterpreted_option: Array[UninterpretedOption] = Array[UninterpretedOption]

  fun compute_size(): U32 =>
    var size: U32 = 0
    match allow_alias
    | None => None
    | let allow_alias': Bool =>
      size = size + FieldSize.varint[Bool](2, allow_alias')
    end
    match deprecated
    | None => None
    | let deprecated': Bool =>
      size = size + FieldSize.varint[Bool](3, deprecated')
    end
    for v in uninterpreted_option.values() do
      size = size + FieldSize.inner_message(999, v)
    end
    size

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (2, VarintField) =>
        allow_alias = reader.read_varint_bool()?
      | (3, VarintField) =>
        deprecated = reader.read_varint_bool()?
      | (999, DelimitedField) =>
        let v: UninterpretedOption = UninterpretedOption
        v.parse_from_stream(reader.pop_embed()?)?
        uninterpreted_option.push(v)
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    match allow_alias
    | None => None
    | let allow_alias': Bool =>
      writer.write_tag(2, VarintField)
      writer.write_varint[Bool](allow_alias')
    end
    match deprecated
    | None => None
    | let deprecated': Bool =>
      writer.write_tag(3, VarintField)
      writer.write_varint[Bool](deprecated')
    end
    for v in uninterpreted_option.values() do
      writer.write_tag(999, DelimitedField)
      // TODO: Don't recompute size here, it's wasteful
      writer.write_varint[U32](v.compute_size())
      v.write_to_stream(writer)
    end

  fun is_initialized(): Bool =>
    for v in uninterpreted_option.values() do
      if not v.is_initialized() then
        return false
      end
    end
    true

class EnumValueOptions is ProtoMessage
  var deprecated: (Bool | None) = false
  var uninterpreted_option: Array[UninterpretedOption] = Array[UninterpretedOption]

  fun compute_size(): U32 =>
    var size: U32 = 0
    match deprecated
    | None => None
    | let deprecated': Bool =>
      size = size + FieldSize.varint[Bool](1, deprecated')
    end
    for v in uninterpreted_option.values() do
      size = size + FieldSize.inner_message(999, v)
    end
    size

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, VarintField) =>
        deprecated = reader.read_varint_bool()?
      | (999, DelimitedField) =>
        let v: UninterpretedOption = UninterpretedOption
        v.parse_from_stream(reader.pop_embed()?)?
        uninterpreted_option.push(v)
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    match deprecated
    | None => None
    | let deprecated': Bool =>
      writer.write_tag(1, VarintField)
      writer.write_varint[Bool](deprecated')
    end
    for v in uninterpreted_option.values() do
      writer.write_tag(999, DelimitedField)
      // TODO: Don't recompute size here, it's wasteful
      writer.write_varint[U32](v.compute_size())
      v.write_to_stream(writer)
    end

  fun is_initialized(): Bool =>
    for v in uninterpreted_option.values() do
      if not v.is_initialized() then
        return false
      end
    end
    true
