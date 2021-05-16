use "buffered"
use ".."

primitive FieldDescriptorProtoTypeTYPEDOUBLE is ProtoEnumValue
  fun as_i32(): I32 => 1

primitive FieldDescriptorProtoTypeTYPEFLOAT is ProtoEnumValue
  fun as_i32(): I32 => 2

primitive FieldDescriptorProtoTypeTYPEINT64 is ProtoEnumValue
  fun as_i32(): I32 => 3

primitive FieldDescriptorProtoTypeTYPEUINT64 is ProtoEnumValue
  fun as_i32(): I32 => 4

primitive FieldDescriptorProtoTypeTYPEINT32 is ProtoEnumValue
  fun as_i32(): I32 => 5

primitive FieldDescriptorProtoTypeTYPEFIXED64 is ProtoEnumValue
  fun as_i32(): I32 => 6

primitive FieldDescriptorProtoTypeTYPEFIXED32 is ProtoEnumValue
  fun as_i32(): I32 => 7

primitive FieldDescriptorProtoTypeTYPEBOOL is ProtoEnumValue
  fun as_i32(): I32 => 8

primitive FieldDescriptorProtoTypeTYPESTRING is ProtoEnumValue
  fun as_i32(): I32 => 9

primitive FieldDescriptorProtoTypeTYPEGROUP is ProtoEnumValue
  fun as_i32(): I32 => 10

primitive FieldDescriptorProtoTypeTYPEMESSAGE is ProtoEnumValue
  fun as_i32(): I32 => 11

primitive FieldDescriptorProtoTypeTYPEBYTES is ProtoEnumValue
  fun as_i32(): I32 => 12

primitive FieldDescriptorProtoTypeTYPEUINT32 is ProtoEnumValue
  fun as_i32(): I32 => 13

primitive FieldDescriptorProtoTypeTYPEENUM is ProtoEnumValue
  fun as_i32(): I32 => 14

primitive FieldDescriptorProtoTypeTYPESIXED32 is ProtoEnumValue
  fun as_i32(): I32 => 15

primitive FieldDescriptorProtoTypeTYPESIXED64 is ProtoEnumValue
  fun as_i32(): I32 => 16

primitive FieldDescriptorProtoTypeTYPESINT32 is ProtoEnumValue
  fun as_i32(): I32 => 17

primitive FieldDescriptorProtoTypeTYPESINT64 is ProtoEnumValue
  fun as_i32(): I32 => 18

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
  | FieldDescriptorProtoTypeTYPESIXED32
  | FieldDescriptorProtoTypeTYPESIXED64
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
    | 15 => FieldDescriptorProtoTypeTYPESIXED32
    | 16 => FieldDescriptorProtoTypeTYPESIXED64
    | 17 => FieldDescriptorProtoTypeTYPESINT32
    | 18 => FieldDescriptorProtoTypeTYPESINT64
    else
      None
    end

primitive FieldDescriptorProtoLabelLABELOPTIONAL is ProtoEnumValue
  fun as_i32(): I32 => 1

primitive FieldDescriptorProtoLabelLABELREQUIRED is ProtoEnumValue
  fun as_i32(): I32 => 2

primitive FieldDescriptorProtoLabelLABELREPEATED is ProtoEnumValue
  fun as_i32(): I32 => 3

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

class FieldOptions is ProtoMessage
  var packed: (Bool | None) = None

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (2, VarintField) =>
        packed = BoolDecoder(buffer)?
      | (_, let typ : KeyType) => SkipField(typ, buffer) ?
      end
    end

class FieldDescriptorProto is ProtoMessage
  var name: (String | None) = None
  var number: (I32 | None) = None
  var label: (FieldDescriptorProtoLabel | None) = None
  var field_type: (FieldDescriptorProtoType | None) = None
  var type_name: (String | None) = None
  var extendee: (String | None) = None
  var default_value: (String | None) = None
  var oneof_index: (I32 | None) = None
  var json_name: (String | None) = None
  var options: (FieldOptions | None) = None
  var proto3_optional: (Bool | None) = None
  embed _reader: Reader = Reader

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, DelimitedField) =>
        name = DelimitedDecoder.decode_string(buffer) ?
      | (3, VarintField) =>
        number = IntegerDecoder.decode_signed(buffer)?.i32()
      | (4, VarintField) =>
        let n = IntegerDecoder.decode_signed(buffer) ?
        label = FieldDescriptorProtoLabelBuilder.from_i32(n.i32())
      | (5, VarintField) =>
        let n = IntegerDecoder.decode_signed(buffer) ?
        field_type = FieldDescriptorProtoTypeBuilder.from_i32(n.i32())
      | (6, DelimitedField) =>
        type_name = DelimitedDecoder.decode_string(buffer) ?
      | (2, DelimitedField) =>
        extendee = DelimitedDecoder.decode_string(buffer) ?
      | (7, DelimitedField) =>
        default_value = DelimitedDecoder.decode_string(buffer) ?
      | (9, VarintField) =>
        oneof_index = IntegerDecoder.decode_signed(buffer)?.i32()
      | (10, DelimitedField) =>
        json_name = DelimitedDecoder.decode_string(buffer) ?
      | (8, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: FieldOptions = FieldOptions
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        options = v
      | (17, VarintField) =>
        proto3_optional = BoolDecoder(buffer)?
      | (_, let typ : KeyType) => SkipField(typ, buffer) ?
      end
    end
