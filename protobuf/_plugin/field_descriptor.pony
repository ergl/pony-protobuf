// This file was autogenerated by pony-protobuf 0.1.0-a48b754 [release]. Do not edit!
// Compiled by protoc 3.17.3

use ".."

primitive FieldDescriptorProtoTypeTYPEDOUBLE is ProtoEnumValue
  fun as_i32(): I32 => 1
  fun string(): String => "FieldDescriptorProtoTypeTYPEDOUBLE"

primitive FieldDescriptorProtoTypeTYPEFLOAT is ProtoEnumValue
  fun as_i32(): I32 => 2
  fun string(): String => "FieldDescriptorProtoTypeTYPEFLOAT"

primitive FieldDescriptorProtoTypeTYPEINT64 is ProtoEnumValue
  fun as_i32(): I32 => 3
  fun string(): String => "FieldDescriptorProtoTypeTYPEINT64"

primitive FieldDescriptorProtoTypeTYPEUINT64 is ProtoEnumValue
  fun as_i32(): I32 => 4
  fun string(): String => "FieldDescriptorProtoTypeTYPEUINT64"

primitive FieldDescriptorProtoTypeTYPEINT32 is ProtoEnumValue
  fun as_i32(): I32 => 5
  fun string(): String => "FieldDescriptorProtoTypeTYPEINT32"

primitive FieldDescriptorProtoTypeTYPEFIXED64 is ProtoEnumValue
  fun as_i32(): I32 => 6
  fun string(): String => "FieldDescriptorProtoTypeTYPEFIXED64"

primitive FieldDescriptorProtoTypeTYPEFIXED32 is ProtoEnumValue
  fun as_i32(): I32 => 7
  fun string(): String => "FieldDescriptorProtoTypeTYPEFIXED32"

primitive FieldDescriptorProtoTypeTYPEBOOL is ProtoEnumValue
  fun as_i32(): I32 => 8
  fun string(): String => "FieldDescriptorProtoTypeTYPEBOOL"

primitive FieldDescriptorProtoTypeTYPESTRING is ProtoEnumValue
  fun as_i32(): I32 => 9
  fun string(): String => "FieldDescriptorProtoTypeTYPESTRING"

primitive FieldDescriptorProtoTypeTYPEGROUP is ProtoEnumValue
  fun as_i32(): I32 => 10
  fun string(): String => "FieldDescriptorProtoTypeTYPEGROUP"

primitive FieldDescriptorProtoTypeTYPEMESSAGE is ProtoEnumValue
  fun as_i32(): I32 => 11
  fun string(): String => "FieldDescriptorProtoTypeTYPEMESSAGE"

primitive FieldDescriptorProtoTypeTYPEBYTES is ProtoEnumValue
  fun as_i32(): I32 => 12
  fun string(): String => "FieldDescriptorProtoTypeTYPEBYTES"

primitive FieldDescriptorProtoTypeTYPEUINT32 is ProtoEnumValue
  fun as_i32(): I32 => 13
  fun string(): String => "FieldDescriptorProtoTypeTYPEUINT32"

primitive FieldDescriptorProtoTypeTYPEENUM is ProtoEnumValue
  fun as_i32(): I32 => 14
  fun string(): String => "FieldDescriptorProtoTypeTYPEENUM"

primitive FieldDescriptorProtoTypeTYPESFIXED32 is ProtoEnumValue
  fun as_i32(): I32 => 15
  fun string(): String => "FieldDescriptorProtoTypeTYPESFIXED32"

primitive FieldDescriptorProtoTypeTYPESFIXED64 is ProtoEnumValue
  fun as_i32(): I32 => 16
  fun string(): String => "FieldDescriptorProtoTypeTYPESFIXED64"

primitive FieldDescriptorProtoTypeTYPESINT32 is ProtoEnumValue
  fun as_i32(): I32 => 17
  fun string(): String => "FieldDescriptorProtoTypeTYPESINT32"

primitive FieldDescriptorProtoTypeTYPESINT64 is ProtoEnumValue
  fun as_i32(): I32 => 18
  fun string(): String => "FieldDescriptorProtoTypeTYPESINT64"

type FieldDescriptorProtoType is (
  FieldDescriptorProtoTypeTYPEDOUBLE
  | FieldDescriptorProtoTypeTYPEFLOAT
  | FieldDescriptorProtoTypeTYPEINT64
  | FieldDescriptorProtoTypeTYPEUINT64
  | FieldDescriptorProtoTypeTYPEINT32
  | FieldDescriptorProtoTypeTYPEFIXED64
  | FieldDescriptorProtoTypeTYPEFIXED32
  | FieldDescriptorProtoTypeTYPEBOOL
  | FieldDescriptorProtoTypeTYPESTRING
  | FieldDescriptorProtoTypeTYPEGROUP
  | FieldDescriptorProtoTypeTYPEMESSAGE
  | FieldDescriptorProtoTypeTYPEBYTES
  | FieldDescriptorProtoTypeTYPEUINT32
  | FieldDescriptorProtoTypeTYPEENUM
  | FieldDescriptorProtoTypeTYPESFIXED32
  | FieldDescriptorProtoTypeTYPESFIXED64
  | FieldDescriptorProtoTypeTYPESINT32
  | FieldDescriptorProtoTypeTYPESINT64
)

primitive FieldDescriptorProtoTypeBuilder is ProtoEnum
  fun from_i32(value: I32): (FieldDescriptorProtoType | None) =>
    match value
    | 1 => FieldDescriptorProtoTypeTYPEDOUBLE
    | 2 => FieldDescriptorProtoTypeTYPEFLOAT
    | 3 => FieldDescriptorProtoTypeTYPEINT64
    | 4 => FieldDescriptorProtoTypeTYPEUINT64
    | 5 => FieldDescriptorProtoTypeTYPEINT32
    | 6 => FieldDescriptorProtoTypeTYPEFIXED64
    | 7 => FieldDescriptorProtoTypeTYPEFIXED32
    | 8 => FieldDescriptorProtoTypeTYPEBOOL
    | 9 => FieldDescriptorProtoTypeTYPESTRING
    | 10 => FieldDescriptorProtoTypeTYPEGROUP
    | 11 => FieldDescriptorProtoTypeTYPEMESSAGE
    | 12 => FieldDescriptorProtoTypeTYPEBYTES
    | 13 => FieldDescriptorProtoTypeTYPEUINT32
    | 14 => FieldDescriptorProtoTypeTYPEENUM
    | 15 => FieldDescriptorProtoTypeTYPESFIXED32
    | 16 => FieldDescriptorProtoTypeTYPESFIXED64
    | 17 => FieldDescriptorProtoTypeTYPESINT32
    | 18 => FieldDescriptorProtoTypeTYPESINT64
    else
      None
    end

primitive FieldDescriptorProtoLabelLABELOPTIONAL is ProtoEnumValue
  fun as_i32(): I32 => 1
  fun string(): String => "FieldDescriptorProtoLabelLABELOPTIONAL"

primitive FieldDescriptorProtoLabelLABELREQUIRED is ProtoEnumValue
  fun as_i32(): I32 => 2
  fun string(): String => "FieldDescriptorProtoLabelLABELREQUIRED"

primitive FieldDescriptorProtoLabelLABELREPEATED is ProtoEnumValue
  fun as_i32(): I32 => 3
  fun string(): String => "FieldDescriptorProtoLabelLABELREPEATED"

type FieldDescriptorProtoLabel is (
  FieldDescriptorProtoLabelLABELOPTIONAL
  | FieldDescriptorProtoLabelLABELREQUIRED
  | FieldDescriptorProtoLabelLABELREPEATED
)

primitive FieldDescriptorProtoLabelBuilder is ProtoEnum
  fun from_i32(value: I32): (FieldDescriptorProtoLabel | None) =>
    match value
    | 1 => FieldDescriptorProtoLabelLABELOPTIONAL
    | 2 => FieldDescriptorProtoLabelLABELREQUIRED
    | 3 => FieldDescriptorProtoLabelLABELREPEATED
    else
      None
    end

class FieldDescriptorProto is ProtoMessage
  var name: (String | None) = None
  var extendee: (String | None) = None
  var number: (I32 | None) = None
  var label: (FieldDescriptorProtoLabel | None) = None
  var type_field: (FieldDescriptorProtoType | None) = None
  var type_name: (String | None) = None
  var default_value: (String | None) = None
  var options: (FieldOptions | None) = None
  var oneof_index: (I32 | None) = None
  var json_name: (String | None) = None
  var proto3_optional: (Bool | None) = None

  fun compute_size(): U32 =>
    var size: U32 = 0
    match name
    | None => None
    | let name': String =>
      size = size + FieldSize.delimited(1, name')
    end
    match extendee
    | None => None
    | let extendee': String =>
      size = size + FieldSize.delimited(2, extendee')
    end
    match number
    | None => None
    | let number': I32 =>
      size = size + FieldSize.varint[I32](3, number')
    end
    match label
    | None => None
    | let label': FieldDescriptorProtoLabel =>
      size = size + FieldSize.enum(4, label')
    end
    match type_field
    | None => None
    | let type_field': FieldDescriptorProtoType =>
      size = size + FieldSize.enum(5, type_field')
    end
    match type_name
    | None => None
    | let type_name': String =>
      size = size + FieldSize.delimited(6, type_name')
    end
    match default_value
    | None => None
    | let default_value': String =>
      size = size + FieldSize.delimited(7, default_value')
    end
    match options
    | None => None
    | let options': this->FieldOptions =>
      size = size + FieldSize.inner_message(8, options')
    end
    match oneof_index
    | None => None
    | let oneof_index': I32 =>
      size = size + FieldSize.varint[I32](9, oneof_index')
    end
    match json_name
    | None => None
    | let json_name': String =>
      size = size + FieldSize.delimited(10, json_name')
    end
    match proto3_optional
    | None => None
    | let proto3_optional': Bool =>
      size = size + FieldSize.varint[Bool](17, proto3_optional')
    end
    size

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, DelimitedField) =>
        name = reader.read_string()?
      | (2, DelimitedField) =>
        extendee = reader.read_string()?
      | (3, VarintField) =>
        number = reader.read_varint_32()?.i32()
      | (4, VarintField) =>
        label = FieldDescriptorProtoLabelBuilder.from_i32(reader.read_varint_32()?.i32())
      | (5, VarintField) =>
        type_field = FieldDescriptorProtoTypeBuilder.from_i32(reader.read_varint_32()?.i32())
      | (6, DelimitedField) =>
        type_name = reader.read_string()?
      | (7, DelimitedField) =>
        default_value = reader.read_string()?
      | (8, DelimitedField) =>
        match options
        | None =>
          options = FieldOptions.>parse_from_stream(reader.pop_embed()?)?
        | let options': FieldOptions =>
          options'.parse_from_stream(reader.pop_embed()?)?
        end
      | (9, VarintField) =>
        oneof_index = reader.read_varint_32()?.i32()
      | (10, DelimitedField) =>
        json_name = reader.read_string()?
      | (17, VarintField) =>
        proto3_optional = reader.read_varint_bool()?
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
    match extendee
    | None => None
    | let extendee': String =>
      writer.write_tag(2, DelimitedField)
      writer.write_bytes(extendee')
    end
    match number
    | None => None
    | let number': I32 =>
      writer.write_tag(3, VarintField)
      writer.write_varint[I32](number')
    end
    match label
    | None => None
    | let label': FieldDescriptorProtoLabel =>
      writer.write_tag(4, VarintField)
      writer.write_enum(label')
    end
    match type_field
    | None => None
    | let type_field': FieldDescriptorProtoType =>
      writer.write_tag(5, VarintField)
      writer.write_enum(type_field')
    end
    match type_name
    | None => None
    | let type_name': String =>
      writer.write_tag(6, DelimitedField)
      writer.write_bytes(type_name')
    end
    match default_value
    | None => None
    | let default_value': String =>
      writer.write_tag(7, DelimitedField)
      writer.write_bytes(default_value')
    end
    match options
    | None => None
    | let options': this->FieldOptions =>
      writer.write_tag(8, DelimitedField)
      // TODO: Don't recompute size here, it's wasteful
      writer.write_varint[U32](options'.compute_size())
      options'.write_to_stream(writer)
    end
    match oneof_index
    | None => None
    | let oneof_index': I32 =>
      writer.write_tag(9, VarintField)
      writer.write_varint[I32](oneof_index')
    end
    match json_name
    | None => None
    | let json_name': String =>
      writer.write_tag(10, DelimitedField)
      writer.write_bytes(json_name')
    end
    match proto3_optional
    | None => None
    | let proto3_optional': Bool =>
      writer.write_tag(17, VarintField)
      writer.write_varint[Bool](proto3_optional')
    end

  fun is_initialized(): Bool =>
    match options
    | None => None
    | let options': this->FieldOptions =>
      if not (options'.is_initialized()) then
        return false
      end
    end
    true

primitive FieldOptionsCTypeSTRING is ProtoEnumValue
  fun as_i32(): I32 => 0
  fun string(): String => "FieldOptionsCTypeSTRING"

primitive FieldOptionsCTypeCORD is ProtoEnumValue
  fun as_i32(): I32 => 1
  fun string(): String => "FieldOptionsCTypeCORD"

primitive FieldOptionsCTypeSTRINGPIECE is ProtoEnumValue
  fun as_i32(): I32 => 2
  fun string(): String => "FieldOptionsCTypeSTRINGPIECE"

type FieldOptionsCType is (
  FieldOptionsCTypeSTRING
  | FieldOptionsCTypeCORD
  | FieldOptionsCTypeSTRINGPIECE
)

primitive FieldOptionsCTypeBuilder is ProtoEnum
  fun from_i32(value: I32): (FieldOptionsCType | None) =>
    match value
    | 0 => FieldOptionsCTypeSTRING
    | 1 => FieldOptionsCTypeCORD
    | 2 => FieldOptionsCTypeSTRINGPIECE
    else
      None
    end

primitive FieldOptionsJSTypeJSNORMAL is ProtoEnumValue
  fun as_i32(): I32 => 0
  fun string(): String => "FieldOptionsJSTypeJSNORMAL"

primitive FieldOptionsJSTypeJSSTRING is ProtoEnumValue
  fun as_i32(): I32 => 1
  fun string(): String => "FieldOptionsJSTypeJSSTRING"

primitive FieldOptionsJSTypeJSNUMBER is ProtoEnumValue
  fun as_i32(): I32 => 2
  fun string(): String => "FieldOptionsJSTypeJSNUMBER"

type FieldOptionsJSType is (
  FieldOptionsJSTypeJSNORMAL
  | FieldOptionsJSTypeJSSTRING
  | FieldOptionsJSTypeJSNUMBER
)

primitive FieldOptionsJSTypeBuilder is ProtoEnum
  fun from_i32(value: I32): (FieldOptionsJSType | None) =>
    match value
    | 0 => FieldOptionsJSTypeJSNORMAL
    | 1 => FieldOptionsJSTypeJSSTRING
    | 2 => FieldOptionsJSTypeJSNUMBER
    else
      None
    end

class FieldOptions is ProtoMessage
  var ctype: (FieldOptionsCType | None) = FieldOptionsCTypeSTRING
  var packed: (Bool | None) = None
  var deprecated: (Bool | None) = false
  var lazy: (Bool | None) = false
  var jstype: (FieldOptionsJSType | None) = FieldOptionsJSTypeJSNORMAL
  var weak: (Bool | None) = false
  var uninterpreted_option: Array[UninterpretedOption] = Array[UninterpretedOption]

  fun compute_size(): U32 =>
    var size: U32 = 0
    match ctype
    | None => None
    | let ctype': FieldOptionsCType =>
      size = size + FieldSize.enum(1, ctype')
    end
    match packed
    | None => None
    | let packed': Bool =>
      size = size + FieldSize.varint[Bool](2, packed')
    end
    match deprecated
    | None => None
    | let deprecated': Bool =>
      size = size + FieldSize.varint[Bool](3, deprecated')
    end
    match lazy
    | None => None
    | let lazy': Bool =>
      size = size + FieldSize.varint[Bool](5, lazy')
    end
    match jstype
    | None => None
    | let jstype': FieldOptionsJSType =>
      size = size + FieldSize.enum(6, jstype')
    end
    match weak
    | None => None
    | let weak': Bool =>
      size = size + FieldSize.varint[Bool](10, weak')
    end
    for v in uninterpreted_option.values() do
      size = size + FieldSize.inner_message(999, v)
    end
    size

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, VarintField) =>
        ctype = FieldOptionsCTypeBuilder.from_i32(reader.read_varint_32()?.i32())
      | (2, VarintField) =>
        packed = reader.read_varint_bool()?
      | (3, VarintField) =>
        deprecated = reader.read_varint_bool()?
      | (5, VarintField) =>
        lazy = reader.read_varint_bool()?
      | (6, VarintField) =>
        jstype = FieldOptionsJSTypeBuilder.from_i32(reader.read_varint_32()?.i32())
      | (10, VarintField) =>
        weak = reader.read_varint_bool()?
      | (999, DelimitedField) =>
        let v: UninterpretedOption = UninterpretedOption
        v.parse_from_stream(reader.pop_embed()?)?
        uninterpreted_option.push(v)
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    match ctype
    | None => None
    | let ctype': FieldOptionsCType =>
      writer.write_tag(1, VarintField)
      writer.write_enum(ctype')
    end
    match packed
    | None => None
    | let packed': Bool =>
      writer.write_tag(2, VarintField)
      writer.write_varint[Bool](packed')
    end
    match deprecated
    | None => None
    | let deprecated': Bool =>
      writer.write_tag(3, VarintField)
      writer.write_varint[Bool](deprecated')
    end
    match lazy
    | None => None
    | let lazy': Bool =>
      writer.write_tag(5, VarintField)
      writer.write_varint[Bool](lazy')
    end
    match jstype
    | None => None
    | let jstype': FieldOptionsJSType =>
      writer.write_tag(6, VarintField)
      writer.write_enum(jstype')
    end
    match weak
    | None => None
    | let weak': Bool =>
      writer.write_tag(10, VarintField)
      writer.write_varint[Bool](weak')
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
