use "buffered"

primitive FieldTypeEncoder
  fun encode_field(field: U64, typ: KeyType, buffer: Writer) =>
    IntegerEncoder.encode_unsigned(((field << 3) or _typ_num(typ)), buffer)

  fun _typ_num(t: KeyType): U64 =>
    match t
    | VarintField => 0
    | Fixed64Field => 1
    | DelimitedField => 2
    | Fixed32Field => 5
    end

primitive PackedEncoder
  fun encode_packed_varint[T: (I32 | I64 | U32 | U64)](from: Array[T] box, from_size: U32, buffer: Writer) =>
    IntegerEncoder.encode_unsigned(from_size.u64(), buffer)
    iftype T <: I32 then
      for v in from.values() do IntegerEncoder.encode_signed(v.i64(), buffer) end
    elseif T <: I64 then
      for v in from.values() do IntegerEncoder.encode_signed(v.i64(), buffer) end
    else
      for v in from.values() do IntegerEncoder.encode_unsigned(v.u64(), buffer) end
    end

  fun encode_packed_varint_zigzag[T: (I32 | I64)](from: Array[T] box, from_size: U32, buffer: Writer) =>
    IntegerEncoder.encode_unsigned(from_size.u64(), buffer)
    for v in from.values() do IntegerEncoder.encode_signed_zigzag(v.i64(), buffer) end

primitive ZigZagEncoder
  fun apply(n: I64): U64 =>
    ((n << 1) xor (n >> 63)).u64()

primitive BoolEncoder
  fun apply(b: Bool, buffer: Writer) =>
    IntegerEncoder.encode_unsigned(if b then 1 else 0 end, buffer)

primitive IntegerEncoder
  fun encode_unsigned(n: U64, buffer: Writer) =>
    var n' = n
    while n' >= 0x80 do
      buffer.u8((0x80 or n'.u8()))
      n' = n' >> 7
    end
    buffer.u8(n'.u8())

  fun encode_signed(n: I64, buffer: Writer) =>
    encode_unsigned(n.u64(), buffer)

  fun encode_signed_zigzag(n: I64, buffer: Writer) =>
    encode_unsigned(ZigZagEncoder(n), buffer)

primitive FloatEncoder
  fun encode(n: F32, buffer: Writer) => buffer.f32_le(n)

primitive DoubleEncoder
  fun encode(n: F64, buffer: Writer) => buffer.f64_le(n)

primitive DelimitedEncoder
  fun encode(bytes: ByteSeq, buffer: Writer) =>
    let size = bytes.size()
    IntegerEncoder.encode_unsigned(size.u64(), buffer)
    buffer.write(bytes)
