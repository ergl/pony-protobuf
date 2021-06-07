// This file was autogenerated by pony-protobuf 23bf878 [debug]. Do not edit!
// Compiled by protoc 3.17.2

use "../../protobuf"

primitive TestEnumUNKNOWN is ProtoEnumValue
  fun as_i32(): I32 => 0
  fun string(): String => "TestEnumUNKNOWN"

primitive TestEnumFIRSTFIELD is ProtoEnumValue
  fun as_i32(): I32 => 1
  fun string(): String => "TestEnumFIRSTFIELD"

primitive TestEnumSECONDFIELD is ProtoEnumValue
  fun as_i32(): I32 => 2
  fun string(): String => "TestEnumSECONDFIELD"

type TestEnum is (
  TestEnumUNKNOWN
  | TestEnumFIRSTFIELD
  | TestEnumSECONDFIELD
)

primitive TestEnumBuilder is ProtoEnum
  fun from_i32(value: I32): (TestEnum | None) =>
    match value
    | 0 => TestEnumUNKNOWN
    | 1 => TestEnumFIRSTFIELD
    | 2 => TestEnumSECONDFIELD
    else
      None
    end

class TestPacked is ProtoMessage
  var values: Array[I32] = Array[I32]
  var values_32: Array[I32] = Array[I32]
  var values_64: Array[I64] = Array[I64]
  var values_bool: Array[Bool] = Array[Bool]
  var values_enum: Array[TestEnum] = Array[TestEnum]
  var values_zigzag: Array[I32] = Array[I32]
  
  fun compute_size(): U32 =>
    var size: U32 = 0
    size = size + FieldSize.packed_varint[I32](1, values)
    size = size + FieldSize.packed_fixed32[I32](2, values_32)
    size = size + FieldSize.packed_fixed64[I64](3, values_64)
    size = size + FieldSize.packed_varint[Bool](4, values_bool)
    size = size + FieldSize.packed_enum[TestEnum](5, values_enum)
    size = size + FieldSize.packed_varint_zigzag[I32](6, values_zigzag)
    size
  
  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, DelimitedField) =>
        reader.read_packed_varint[I32](values)?
      | (1, VarintField) =>
        let v = reader.read_varint_32()?.i32()
        values.push(v)
      | (2, DelimitedField) =>
        reader.read_packed_fixed_32[I32](values_32)?
      | (2, Fixed32Field) =>
        let v = reader.read_fixed_32_integer()?.i32()
        values_32.push(v)
      | (3, DelimitedField) =>
        reader.read_packed_fixed_64[I64](values_64)?
      | (3, Fixed64Field) =>
        let v = reader.read_fixed_64_integer()?.i64()
        values_64.push(v)
      | (4, DelimitedField) =>
        reader.read_packed_varint[Bool](values_bool)?
      | (4, VarintField) =>
        let v = reader.read_varint_bool()?
        values_bool.push(v)
      | (5, DelimitedField) =>
        reader.read_packed_enum[TestEnum](values_enum, TestEnumBuilder)?
      | (5, VarintField) =>
        match TestEnumBuilder.from_i32(reader.read_varint_32()?.i32())
        | None => None
        | let v: TestEnum => values_enum.push(v)
        end
      | (6, DelimitedField) =>
        reader.read_packed_varint_zigzag[I32](values_zigzag)?
      | (6, VarintField) =>
        let v = reader.read_varint_zigzag_32()?
        values_zigzag.push(v)
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end
  
  fun write_to_stream(writer: ProtoWriter) =>
    if values.size() != 0 then
      var values_size: U32 = 0
      for v in values.values() do
        values_size = values_size + FieldSize.raw_varint(v.u64())
      end
      writer.write_tag(1, DelimitedField)
      writer.write_packed_varint[I32](values, values_size)
    end
    if values_32.size() != 0 then
      writer.write_tag(2, DelimitedField)
      writer.write_packed_fixed32[I32](values_32)
    end
    if values_64.size() != 0 then
      writer.write_tag(3, DelimitedField)
      writer.write_packed_fixed64[I64](values_64)
    end
    if values_bool.size() != 0 then
      var values_bool_size: U32 = 0
      for v in values_bool.values() do
        values_bool_size = values_bool_size + FieldSize.raw_varint(if v then 1 else 0 end)
      end
      writer.write_tag(4, DelimitedField)
      writer.write_packed_varint[Bool](values_bool, values_bool_size)
    end
    if values_enum.size() != 0 then
      var values_enum_size: U32 = 0
      for v in values_enum.values() do
        values_enum_size = values_enum_size + FieldSize.raw_varint(v.as_i32().u64())
      end
      writer.write_tag(5, DelimitedField)
      writer.write_packed_enum[TestEnum](values_enum, values_enum_size)
    end
    if values_zigzag.size() != 0 then
      var values_zigzag_size: U32 = 0
      for v in values_zigzag.values() do
        values_zigzag_size = values_zigzag_size + FieldSize.raw_varint(ZigZag.encode_64(v.i64()))
      end
      writer.write_tag(6, DelimitedField)
      writer.write_packed_varint_zigzag[I32](values_zigzag, values_zigzag_size)
    end
  

class TestUnpacked is ProtoMessage
  var values: Array[I32] = Array[I32]
  var values_32: Array[I32] = Array[I32]
  var values_64: Array[I64] = Array[I64]
  var values_bool: Array[Bool] = Array[Bool]
  var values_enum: Array[TestEnum] = Array[TestEnum]
  var values_zigzag: Array[I32] = Array[I32]
  
  fun compute_size(): U32 =>
    var size: U32 = 0
    for v in values.values() do
      size = size + FieldSize.varint[I32](1, v)
    end
    for v in values_32.values() do
      size = size + FieldSize.fixed32(2)
    end
    for v in values_64.values() do
      size = size + FieldSize.fixed64(3)
    end
    for v in values_bool.values() do
      size = size + FieldSize.varint[Bool](4, v)
    end
    for v in values_enum.values() do
      size = size + FieldSize.enum(5, v)
    end
    for v in values_zigzag.values() do
      size = size + FieldSize.varint_zigzag[I32](6, v)
    end
    size
  
  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, VarintField) =>
        values.push(reader.read_varint_32()?.i32())
      | (2, Fixed32Field) =>
        values_32.push(reader.read_fixed_32_integer()?.i32())
      | (3, Fixed64Field) =>
        values_64.push(reader.read_fixed_64_integer()?.i64())
      | (4, VarintField) =>
        values_bool.push(reader.read_varint_bool()?)
      | (5, VarintField) =>
        match TestEnumBuilder.from_i32(reader.read_varint_32()?.i32())
        | None => None
        | let v: TestEnum => values_enum.push(v)
        end
      | (6, VarintField) =>
        values_zigzag.push(reader.read_varint_zigzag_32()?)
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end
  
  fun write_to_stream(writer: ProtoWriter) =>
    for v in values.values() do
      writer.write_tag(1, VarintField)
      writer.write_varint[I32](v)
    end
    for v in values_32.values() do
      writer.write_tag(2, Fixed32Field)
      writer.write_fixed_32[I32](v)
    end
    for v in values_64.values() do
      writer.write_tag(3, Fixed64Field)
      writer.write_fixed_64[I64](v)
    end
    for v in values_bool.values() do
      writer.write_tag(4, VarintField)
      writer.write_varint[Bool](v)
    end
    for v in values_enum.values() do
      writer.write_tag(5, VarintField)
      writer.write_enum(v)
    end
    for v in values_zigzag.values() do
      writer.write_tag(6, VarintField)
      writer.write_varint_zigzag[I32](v)
    end
  

