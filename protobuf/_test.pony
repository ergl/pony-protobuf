use "ponytest"
use "ponycheck"
use "buffered"

// TODO(borja): Add test for Skip, fill buffer, skip, ensure that size is now zero

primitive _WriterUtils
  fun squash(buffer: Array[ByteSeq] iso^): Array[U8] val^ =>
    recover
      let b = Array[U8](buffer.size())
      for elt in buffer.values() do
        b.append(elt)
      end
      consume b
    end

  fun writer_size(data: ByteSeqIter): USize =>
    var size: USize = 0
    for v in data.values() do
      size = size + v.size()
    end
    size

primitive _VarintEncoder
  fun encode_unsigned(n: U64): Array[U8] val =>
    let w: Writer = Writer
    IntegerEncoder.encode_unsigned(n, w)
    _WriterUtils.squash(w.done())

  fun encode_signed(n: I64): Array[U8] val =>
    let w: Writer = Writer
    IntegerEncoder.encode_signed(n, w)
    _WriterUtils.squash(w.done())

  fun encode_signed_zigzag(n: I64): Array[U8] val =>
    let w: Writer = Writer
    IntegerEncoder.encode_signed_zigzag(n, w)
    _WriterUtils.squash(w.done())

primitive _VarintDecoder
  fun decode_unsigned(data: Array[U8] val): U64 ? =>
    IntegerDecoder.decode_unsigned(Reader .> append(data)) ?

  fun decode_signed(data: Array[U8] val): I64 ? =>
    IntegerDecoder.decode_signed(Reader .> append(data)) ?

  fun decode_signed_zigzag(data: Array[U8] val): I64 ? =>
    IntegerDecoder.decode_signed_zigzag(Reader .> append(data)) ?

primitive _FixedEncoder
  fun encode_f32(v: F32): Array[U8] val =>
    let w: Writer = Writer
    FloatEncoder.encode(v, w)
    _WriterUtils.squash(w.done())

  fun encode_f64(v: F64): Array[U8] val =>
    let w: Writer = Writer
    DoubleEncoder.encode(v, w)
    _WriterUtils.squash(w.done())

primitive _FixedDecoder
  fun decode_f32(data: Array[U8] val): F32 ? =>
    FloatDecoder.decode(Reader .> append(data)) ?

  fun decode_f64(data: Array[U8] val): F64 ? =>
    DoubleDecoder.decode(Reader .> append(data)) ?

primitive _FieldTypeEncoder
  fun encode_field(field: U64, typ: KeyType): Array[U8] val =>
    let w: Writer = Writer
    FieldTypeEncoder.encode_field(field, typ, w)
    _WriterUtils.squash(w.done())

primitive _FieldTypeDecoder
  fun decode_field(data: Array[U8] val): (U64, KeyType) ? =>
    FieldTypeDecoder.decode_field(Reader .> append(data)) ?

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

  fun key_type(): Generator[KeyType] =>
    Generator[KeyType](
      object is GenObj[KeyType]
       fun generate(rnd: Randomness): KeyType =>
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
    test(Property2UnitTest[U64, KeyType](_TestFieldTypeEncodeProperty))

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
      let first = _VarintDecoder.decode_unsigned(buf_1) ?
      t.assert_eq[U64](first, 1)

      let second = _VarintDecoder.decode_unsigned(buf_300) ?
      t.assert_eq[U64](second, 300)

      t.assert_array_eq[U8](buf_1, _VarintEncoder.encode_unsigned(first))
      t.assert_array_eq[U8](buf_300, _VarintEncoder.encode_unsigned(second))
    else
      t.fail("Error")
      t.complete(true)
    end

class iso _TestUnsignedEncodeProperty is Property1[U64]
  fun name(): String => "encode_decode_property/unsigned_varint"
  fun gen(): Generator[U64] => Generators.u64()
  fun property(arg1: U64, ph: PropertyHelper) =>
    try
      let encoded = _VarintEncoder.encode_unsigned(arg1)
      let decoded = _VarintDecoder.decode_unsigned(encoded) ?
      ph.assert_eq[U64](arg1, decoded)
    else
      ph.fail()
    end

class iso _TestSignedEncodeProperty is Property1[I64]
  fun name(): String => "encode_decode_property/signed_varint"
  fun gen(): Generator[I64] => Generators.i64()
  fun property(arg1: I64, ph: PropertyHelper) =>
    try
      let encoded = _VarintEncoder.encode_signed(arg1)
      let decoded = _VarintDecoder.decode_signed(encoded) ?
      ph.assert_eq[I64](arg1, decoded)
    else
      ph.fail()
    end

class iso _TestZigZagSignedEncodeProperty is Property1[I64]
  fun name(): String => "encode_decode_property/zigzag_signed_varint"
  fun gen(): Generator[I64] => Generators.i64()
  fun property(arg1: I64, ph: PropertyHelper) =>
    try
      let encoded = _VarintEncoder.encode_signed_zigzag(arg1)
      let decoded = _VarintDecoder.decode_signed_zigzag(encoded) ?
      ph.assert_eq[I64](arg1, decoded)
    else
      ph.fail()
    end

class iso _TestFixed32EncodeProperty is Property1[F32]
  fun name(): String => "encode_decode_property/fixed_32"
  fun gen(): Generator[F32] => _CustomGenerators.f32()
  fun property(value: F32, ph: PropertyHelper) =>
    try
      let encoded = _FixedEncoder.encode_f32(value)
      let decoded = _FixedDecoder.decode_f32(encoded) ?
      ph.assert_eq[F32](value, decoded)
    else
      ph.fail()
    end

class iso _TestFixed64EncodeProperty is Property1[F64]
  fun name(): String => "encode_decode_property/fixed_64"
  fun gen(): Generator[F64] => _CustomGenerators.f64()
  fun property(value: F64, ph: PropertyHelper) =>
    try
      let encoded = _FixedEncoder.encode_f64(value)
      let decoded = _FixedDecoder.decode_f64(encoded) ?
      ph.assert_eq[F64](value, decoded)
    else
      ph.fail()
    end

class iso _TestDelimitedEncodeProperty is Property1[String]
  fun name(): String => "encode_decode_property/delimited"
  fun gen(): Generator[String] => Generators.byte_string(where gen = Generators.u8())
  fun property(value: String, ph: PropertyHelper) =>
    try
      let w: Writer = Writer
      DelimitedEncoder.encode(value, w)
      let r = Reader
      for v in w.done().values() do
        r.append(v)
      end
      let decoded: String = DelimitedDecoder.decode_string(consume r) ?
      ph.assert_eq[String](value, decoded)
    else
      ph.fail()
    end

class iso _TestFieldTypeEncodeProperty is Property2[U64, KeyType]
  fun name(): String => "encode_decode_property/wire_types"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[KeyType] => _CustomGenerators.key_type()

  fun property2(arg1: U64, arg2: KeyType, ph: PropertyHelper) =>
    try
      let encoded = _FieldTypeEncoder.encode_field(arg1, arg2)
      let decoded = _FieldTypeDecoder.decode_field(encoded) ?
      ph.assert_eq[U64](arg1, decoded._1)
      ph.assert_is[KeyType](arg2, decoded._2)
    else
      ph.fail()
    end

class iso _TestEncodedUnsignedSizeProperty is Property2[U64, U64]
  fun name(): String => "encoded_field_size_property/unsigned_varint"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[U64] => Generators.u64()
  fun property2(field: U64, value: U64, ph: PropertyHelper) =>
    let expected_size = FieldSize.unsigned_size(field, VarintField, value)
    let writer: Writer = Writer
    FieldTypeEncoder.encode_field(field, VarintField, writer)
    IntegerEncoder.encode_unsigned(value, writer)
    let buf = writer.done()
    ph.assert_eq[U32](_WriterUtils.writer_size(consume buf).u32(), expected_size)

class iso _TestEncodedSignedSizeProperty is Property2[U64, I64]
  fun name(): String => "encoded_field_size_property/signed_varint"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[I64] => Generators.i64()
  fun property2(field: U64, value: I64, ph: PropertyHelper) =>
    let expected_size = FieldSize.signed_size(field, VarintField, value)
    let writer: Writer = Writer
    FieldTypeEncoder.encode_field(field, VarintField, writer)
    IntegerEncoder.encode_signed(value, writer)
    let buf = writer.done()
    ph.assert_eq[U32](_WriterUtils.writer_size(consume buf).u32(), expected_size)

class iso _TestEncodedZigZagSignedSizeProperty is Property2[U64, I64]
  fun name(): String => "encoded_field_size_property/zigzag_signed_varint"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[I64] => Generators.i64()
  fun property2(field: U64, value: I64, ph: PropertyHelper) =>
    let expected_size = FieldSize.signed_zigzag_size(field, VarintField, value)
    let writer: Writer = Writer
    FieldTypeEncoder.encode_field(field, VarintField, writer)
    IntegerEncoder.encode_signed_zigzag(value, writer)
    let buf = writer.done()
    ph.assert_eq[U32](_WriterUtils.writer_size(consume buf).u32(), expected_size)

class iso _TestEncodedFixed32SizeProperty is Property2[U64, F32]
  fun name(): String => "encoded_field_size_property/fixed_32"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[F32] => _CustomGenerators.f32()
  fun property2(field: U64, value: F32, ph: PropertyHelper) =>
    let expected_size = FieldSize.fixed32_size(field, Fixed32Field, value)
    let writer: Writer = Writer
    FieldTypeEncoder.encode_field(field, Fixed32Field, writer)
    FloatEncoder.encode(value, writer)
    let buf = writer.done()
    ph.assert_eq[U32](_WriterUtils.writer_size(consume buf).u32(), expected_size)

class iso _TestEncodedFixed64SizeProperty is Property2[U64, F64]
  fun name(): String => "encoded_field_size_property/fixed_64"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[F64] => _CustomGenerators.f64()
  fun property2(field: U64, value: F64, ph: PropertyHelper) =>
    let expected_size = FieldSize.fixed64_size(field, Fixed64Field, value)
    let writer: Writer = Writer
    FieldTypeEncoder.encode_field(field, Fixed64Field, writer)
    DoubleEncoder.encode(value, writer)
    let buf = writer.done()
    ph.assert_eq[U32](_WriterUtils.writer_size(consume buf).u32(), expected_size)

class iso _TestEncodedDelimitedSizeProperty is Property2[U64, String]
  fun name(): String => "encoded_field_size_property/delimited"
  fun gen1(): Generator[U64] => _CustomGenerators.field_n()
  fun gen2(): Generator[String] => Generators.byte_string(where gen = Generators.u8())
  fun property2(field: U64, value: String, ph: PropertyHelper) =>
    let expected_size = FieldSize.delimited_size(field, DelimitedField, value)
    let writer: Writer = Writer
    FieldTypeEncoder.encode_field(field, DelimitedField, writer)
    DelimitedEncoder.encode(value, writer)
    let buf = writer.done()
    ph.assert_eq[U32](_WriterUtils.writer_size(consume buf).u32(), expected_size)

class iso _TestSkipUnsignedVarintProperty is Property1[U64]
  fun name(): String => "skip_property/unsigned_varint"
  fun gen(): Generator[U64] => Generators.u64()
  fun property(arg1: U64, ph: PropertyHelper) =>
    try
      let r: Reader = Reader .> append(_VarintEncoder.encode_unsigned(arg1))
      SkipField(VarintField, r) ?
      ph.assert_eq[USize](r.size(), 0)
    else
      ph.fail()
    end

class iso _TestSkipSignedVarintProperty is Property1[I64]
  fun name(): String => "skip_property/signed_varint"
  fun gen(): Generator[I64] => Generators.i64()
  fun property(arg1: I64, ph: PropertyHelper) =>
    try
      let r: Reader = Reader .> append(_VarintEncoder.encode_signed(arg1))
      SkipField(VarintField, r) ?
      ph.assert_eq[USize](r.size(), 0)
    else
      ph.fail()
    end

class iso _TestSkipZigZagSignedVarintProperty is Property1[I64]
  fun name(): String => "skip_property/zigzag_signed_varint"
  fun gen(): Generator[I64] => Generators.i64()
  fun property(arg1: I64, ph: PropertyHelper) =>
    try
      let r: Reader = Reader .> append(_VarintEncoder.encode_signed_zigzag(arg1))
      SkipField(VarintField, r) ?
      ph.assert_eq[USize](r.size(), 0)
    else
      ph.fail()
    end

class iso _TestSkipFixed32Property is Property1[F32]
  fun name(): String => "skip_property/fixed_32"
  fun gen(): Generator[F32] => _CustomGenerators.f32()
  fun property(arg1: F32, ph: PropertyHelper) =>
    try
      let r: Reader = Reader .> append(_FixedEncoder.encode_f32(arg1))
      SkipField(Fixed32Field, r) ?
      ph.assert_eq[USize](r.size(), 0)
    else
      ph.fail()
    end

class iso _TestSkipFixed64Property is Property1[F64]
  fun name(): String => "skip_property/fixed_64"
  fun gen(): Generator[F64] => _CustomGenerators.f64()
  fun property(arg1: F64, ph: PropertyHelper) =>
    try
      let r: Reader = Reader .> append(_FixedEncoder.encode_f64(arg1))
      SkipField(Fixed64Field, r) ?
      ph.assert_eq[USize](r.size(), 0)
    else
      ph.fail()
    end

class iso _TestSkipDelimitedProperty is Property1[String]
  fun name(): String => "skip_property/delimited"
  fun gen(): Generator[String] => Generators.byte_string(where gen = Generators.u8())
  fun property(arg1: String, ph: PropertyHelper) =>
    try
      let w: Writer = Writer
      DelimitedEncoder.encode(arg1, w)
      let r: Reader = Reader
      for v in w.done().values() do
        r.append(v)
      end
      SkipField(DelimitedField, r) ?
      ph.assert_eq[USize](r.size(), 0)
    else
      ph.fail()
    end
