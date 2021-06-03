use "ponytest"
use "ponycheck"
use "buffered"

primitive _TestUtils
  fun byteseq_iter_size(data: ByteSeqIter): USize =>
    var size: USize = 0
    for v in data.values() do
      size = size + v.size()
    end
    size

primitive _CustomGenerators
  fun field_n(): Generator[U64] =>
    // From https://developers.google.com/protocol-buffers/docs/proto#assigning_field_numbers
    // Since key types must fit into 32 bits, and 3 are assigned to the key type, the max
    // number of field is 2^(32-3) - 1
    Generators.u64(where max = 536_870_911)

  fun f32(): Generator[F32] =>
    Generator[F32](
      object is GenObj[F32]
        fun generate(rnd: Randomness): F32 => rnd.f32()
      end
    )

  fun f64(): Generator[F64] =>
    Generator[F64](
      object is GenObj[F64]
        fun generate(rnd: Randomness): F64 => rnd.f64()
      end
    )

  fun key_type(): Generator[TagKind] =>
    Generator[TagKind](
      object is GenObj[TagKind]
       fun generate(rnd: Randomness): TagKind =>
         match rnd.u8() % 4
         | 0 => VarintField
         | 1 => Fixed32Field
         | 2 => Fixed64Field
         else
           DelimitedField
         end
      end
    )

actor Main is TestList
  new make () => None
  new create(env: Env) => PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_SimpleTest)

    // Encode / decode tests
    test(Property1UnitTest[U64](_TestUnsignedEncodeProperty))
    test(Property1UnitTest[I64](_TestSignedEncodeProperty))
    test(Property1UnitTest[I64](_TestZigZagSignedEncodeProperty))
    test(Property1UnitTest[F32](_TestFixed32EncodeProperty))
    test(Property1UnitTest[F64](_TestFixed64EncodeProperty))
    test(Property1UnitTest[String](_TestDelimitedEncodeProperty))
    test(Property2UnitTest[U64, TagKind](_TestFieldTypeEncodeProperty))

    // Field size tests
    test(Property2UnitTest[U64, U64](_TestEncodedUnsignedSizeProperty))
    test(Property2UnitTest[U64, I64](_TestEncodedSignedSizeProperty))
    test(Property2UnitTest[U64, I64](_TestEncodedZigZagSignedSizeProperty))
    test(Property2UnitTest[U64, F32](_TestEncodedFixed32SizeProperty))
    test(Property2UnitTest[U64, F64](_TestEncodedFixed64SizeProperty))
    test(Property2UnitTest[U64, String](_TestEncodedDelimitedSizeProperty))

    // Skip tests
    test(Property1UnitTest[U64](_TestSkipUnsignedVarintProperty))
    test(Property1UnitTest[I64](_TestSkipSignedVarintProperty))
    test(Property1UnitTest[I64](_TestSkipZigZagSignedVarintProperty))
    test(Property1UnitTest[F32](_TestSkipFixed32Property))
    test(Property1UnitTest[F64](_TestSkipFixed64Property))
    test(Property1UnitTest[String](_TestSkipDelimitedProperty))

class iso _SimpleTest is UnitTest
  fun name(): String => "test/simple"
  fun apply(t: TestHelper) =>
    let buf_1 = recover val [as U8: 1] end
    let buf_300 = recover val [as U8: 0b1010_1100; 0b10] end
    try
      let first = ProtoReader.>append(buf_1).read_varint_64()?
      t.assert_eq[U64](first, 1)

      let second = ProtoReader.>append(buf_300).read_varint_64()?
      t.assert_eq[U64](second, 300)

      t.assert_array_eq[U8](
        buf_1,
        ProtoWriter .> write_varint[U64](first).done_array()
      )
      t.assert_array_eq[U8](
        buf_300,
        ProtoWriter .> write_varint[U64](second).done_array()
      )
    else
      t.fail("Error")
      t.complete(true)
    end

class iso _TestUnsignedEncodeProperty is Property1[U64]
  fun name(): String => "encode_decode_property/unsigned_varint"
  fun gen(): Generator[U64] => Generators.u64()
  fun property(arg1: U64, ph: PropertyHelper) =>
    try
      let encoded = ProtoWriter.>write_varint[U64](arg1).done_array()
      let decoded = ProtoReader.>append(consume encoded).read_varint_64()?
      ph.assert_eq[U64](arg1, decoded)
    else
      ph.fail()
    end

class iso _TestSignedEncodeProperty is Property1[I64]
  fun name(): String => "encode_decode_property/signed_varint"
  fun gen(): Generator[I64] => Generators.i64()
  fun property(arg1: I64, ph: PropertyHelper) =>
    try
      let encoded = ProtoWriter.>write_varint[I64](arg1).done_array()
      let decoded = ProtoReader.>append(consume encoded).read_varint_64()?.i64()
      ph.assert_eq[I64](arg1, decoded)
    else
      ph.fail()
    end

class iso _TestZigZagSignedEncodeProperty is Property1[I64]
  fun name(): String => "encode_decode_property/zigzag_signed_varint"
  fun gen(): Generator[I64] => Generators.i64()
  fun property(arg1: I64, ph: PropertyHelper) =>
    try
      let encoded = ProtoWriter.>write_varint_zigzag[I64](arg1).done_array()
      let decoded = ProtoReader.>append(consume encoded).read_varint_zigzag_64()?
      ph.assert_eq[I64](arg1, decoded)
    else
      ph.fail()
    end

class iso _TestFixed32EncodeProperty is Property1[F32]
  fun name(): String => "encode_decode_property/fixed_32"
  fun gen(): Generator[F32] => _CustomGenerators.f32()
  fun property(value: F32, ph: PropertyHelper) =>
    try
      let encoded = ProtoWriter.>write_fixed_32[F32](value).done_array()
      let decoded = ProtoReader.>append(consume encoded).read_fixed_32_float()?
      ph.assert_eq[F32](value, decoded)
    else
      ph.fail()
    end

class iso _TestFixed64EncodeProperty is Property1[F64]
  fun name(): String => "encode_decode_property/fixed_64"
  fun gen(): Generator[F64] => _CustomGenerators.f64()
  fun property(value: F64, ph: PropertyHelper) =>
    try
      let encoded = ProtoWriter.>write_fixed_64[F64](value).done_array()
      let decoded = ProtoReader.>append(consume encoded).read_fixed_64_float()?
      ph.assert_eq[F64](value, decoded)
    else
      ph.fail()
    end

class iso _TestDelimitedEncodeProperty is Property1[String]
  fun name(): String => "encode_decode_property/delimited"
  fun gen(): Generator[String] => Generators.byte_string(where gen = Generators.u8())
  fun property(value: String, ph: PropertyHelper) =>
    try
      let encoded = ProtoWriter.>write_bytes(value).done_array()
      let decoded = ProtoReader.>append(consume encoded).read_string()?
      ph.assert_eq[String](value, consume val decoded)
    else
      ph.fail()
    end

class iso _TestFieldTypeEncodeProperty is Property2[U64, TagKind]
  fun name(): String => "encode_decode_property/wire_types"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[TagKind] => _CustomGenerators.key_type()

  fun property2(arg1: U64, arg2: TagKind, ph: PropertyHelper) =>
    try
      let encoded =
        recover val
          ProtoWriter.>write_tag(arg1, arg2).done_array()
        end
      let decoded = ProtoReader.>append(encoded).read_field_tag()?
      ph.assert_eq[U64](arg1, decoded._1)
      ph.assert_is[TagKind](arg2, decoded._2)
    else
      ph.fail()
    end

class iso _TestEncodedUnsignedSizeProperty is Property2[U64, U64]
  fun name(): String => "encoded_field_size_property/unsigned_varint"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[U64] => Generators.u64()
  fun property2(field: U64, value: U64, ph: PropertyHelper) =>
    let expected_size = FieldSize.varint[U64](field, value)
    let buf_size =
      ProtoWriter
      .> write_tag(field, VarintField)
      .> write_varint[U64](value)
      .done_array()
      .size()
      .u32()
    ph.assert_eq[U32](expected_size, buf_size)

class iso _TestEncodedSignedSizeProperty is Property2[U64, I64]
  fun name(): String => "encoded_field_size_property/signed_varint"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[I64] => Generators.i64()
  fun property2(field: U64, value: I64, ph: PropertyHelper) =>
    let expected_size = FieldSize.varint[I64](field, value)
    let buf_size =
      ProtoWriter
      .> write_tag(field, VarintField)
      .> write_varint[I64](value)
      .done_array()
      .size()
      .u32()
    ph.assert_eq[U32](expected_size, buf_size)

class iso _TestEncodedZigZagSignedSizeProperty is Property2[U64, I64]
  fun name(): String => "encoded_field_size_property/zigzag_signed_varint"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[I64] => Generators.i64()
  fun property2(field: U64, value: I64, ph: PropertyHelper) =>
    let expected_size = FieldSize.varint_zigzag[I64](field, value)
    let buf_size =
      ProtoWriter
      .> write_tag(field, VarintField)
      .> write_varint_zigzag[I64](value)
      .done_array()
      .size()
      .u32()
    ph.assert_eq[U32](expected_size, buf_size)

class iso _TestEncodedFixed32SizeProperty is Property2[U64, F32]
  fun name(): String => "encoded_field_size_property/fixed_32"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[F32] => _CustomGenerators.f32()
  fun property2(field: U64, value: F32, ph: PropertyHelper) =>
    let expected_size = FieldSize.fixed32(field)
    let buf_size =
      ProtoWriter
      .> write_tag(field, Fixed32Field)
      .> write_fixed_32[F32](value)
      .done_array()
      .size()
      .u32()
    ph.assert_eq[U32](expected_size, buf_size)

class iso _TestEncodedFixed64SizeProperty is Property2[U64, F64]
  fun name(): String => "encoded_field_size_property/fixed_64"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[F64] => _CustomGenerators.f64()
  fun property2(field: U64, value: F64, ph: PropertyHelper) =>
    let expected_size = FieldSize.fixed64(field)
    let buf_size =
      ProtoWriter
      .> write_tag(field, Fixed64Field)
      .> write_fixed_64[F64](value)
      .done_array()
      .size()
      .u32()
    ph.assert_eq[U32](expected_size, buf_size)

class iso _TestEncodedDelimitedSizeProperty is Property2[U64, String]
  fun name(): String => "encoded_field_size_property/delimited"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[String] => Generators.byte_string(where gen = Generators.u8())
  fun property2(field: U64, value: String, ph: PropertyHelper) =>
    let expected_size = FieldSize.delimited(field, value)
    let buf_size =
      ProtoWriter
      .> write_tag(field, DelimitedField)
      .> write_bytes(value)
      .done_array()
      .size()
      .u32()
    ph.assert_eq[U32](expected_size, buf_size)

class iso _TestSkipUnsignedVarintProperty is Property1[U64]
  fun name(): String => "skip_property/unsigned_varint"
  fun gen(): Generator[U64] => Generators.u64()
  fun property(arg1: U64, ph: PropertyHelper) =>
    try
      let encoded = ProtoWriter .> write_varint[U64](arg1).done_array()
      let size =
        ProtoReader
        .> append(consume encoded)
        .> skip_field(VarintField)?
        .size()
      ph.assert_eq[USize](0, size)
    else
      ph.fail()
    end

class iso _TestSkipSignedVarintProperty is Property1[I64]
  fun name(): String => "skip_property/signed_varint"
  fun gen(): Generator[I64] => Generators.i64()
  fun property(arg1: I64, ph: PropertyHelper) =>
    try
      let encoded = ProtoWriter .> write_varint[I64](arg1).done_array()
      let size =
        ProtoReader
        .> append(consume encoded)
        .> skip_field(VarintField)?
        .size()
      ph.assert_eq[USize](0, size)
    else
      ph.fail()
    end

class iso _TestSkipZigZagSignedVarintProperty is Property1[I64]
  fun name(): String => "skip_property/zigzag_signed_varint"
  fun gen(): Generator[I64] => Generators.i64()
  fun property(arg1: I64, ph: PropertyHelper) =>
    try
      let encoded = ProtoWriter .> write_varint_zigzag[I64](arg1).done_array()
      let size =
        ProtoReader
        .> append(consume encoded)
        .> skip_field(VarintField)?
        .size()
      ph.assert_eq[USize](0, size)
    else
      ph.fail()
    end

class iso _TestSkipFixed32Property is Property1[F32]
  fun name(): String => "skip_property/fixed_32"
  fun gen(): Generator[F32] => _CustomGenerators.f32()
  fun property(arg1: F32, ph: PropertyHelper) =>
    try
      let encoded = ProtoWriter .> write_fixed_32[F32](arg1).done_array()
      let size =
        ProtoReader
        .> append(consume encoded)
        .> skip_field(Fixed32Field)?
        .size()
      ph.assert_eq[USize](0, size)
    else
      ph.fail()
    end

class iso _TestSkipFixed64Property is Property1[F64]
  fun name(): String => "skip_property/fixed_64"
  fun gen(): Generator[F64] => _CustomGenerators.f64()
  fun property(arg1: F64, ph: PropertyHelper) =>
    try
      let encoded = ProtoWriter .> write_fixed_64[F64](arg1).done_array()
      let size =
        ProtoReader
        .> append(consume encoded)
        .> skip_field(Fixed64Field)?
        .size()
      ph.assert_eq[USize](0, size)
    else
      ph.fail()
    end

class iso _TestSkipDelimitedProperty is Property1[String]
  fun name(): String => "skip_property/delimited"
  fun gen(): Generator[String] => Generators.byte_string(where gen = Generators.u8())
  fun property(arg1: String, ph: PropertyHelper) =>
    try
      let encoded = ProtoWriter .> write_bytes(arg1).done_array()
      let size =
        ProtoReader
        .> append(consume encoded)
        .> skip_field(DelimitedField)?
        .size()
      ph.assert_eq[USize](0, size)
    else
      ph.fail()
    end
