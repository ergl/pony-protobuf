use "buffered"

primitive SkipField
  fun apply(typ: TagKind, buffer: Reader) ? =>
    match typ
    | VarintField => _skip_varint(buffer) ?
    | Fixed32Field => buffer.skip(4) ?
    | Fixed64Field => buffer.skip(8) ?
    | DelimitedField => _skip_delimited(buffer) ?
    end

  fun _skip_varint(buffer: Reader) ? =>
    while (buffer.u8()? and 0x80) != 0 do continue end

  fun _skip_delimited(buffer: Reader) ? =>
    let size = DelimitedDecoder.raw_decode_len(buffer) ?
    buffer.skip(size.usize()) ?

primitive FieldTypeDecoder
  fun decode_field(buffer: Reader): (U64, TagKind) ? =>
    let raw = IntegerDecoder.decode_unsigned(buffer) ?
    (raw >> 3, _TagUtil.from_num(raw and 7)?)

primitive PackedDecoder
  fun decode_repeated_varint[T: (I32 | I64 | U32 | U64)](
    into: Array[T],
    buffer: Reader)
    ?
  =>
    into.reserve(into.size() + buffer.size())
    while buffer.size() > 0 do
      iftype T <: I32 then
        into.push(IntegerDecoder.decode_signed(buffer)?.i32())
      elseif T <: I64 then
        into.push(IntegerDecoder.decode_signed(buffer)?)
      elseif T <: U32 then
        into.push(IntegerDecoder.decode_unsigned(buffer)?.u32())
      elseif T <: U64 then
        into.push(IntegerDecoder.decode_unsigned(buffer)?)
      end
    end

  fun decode_repeated_varint_zigzag[T: (I32 | I64)](
    into: Array[T],
    buffer: Reader)
    ?
  =>
    into.reserve(into.size() + buffer.size())
    while buffer.size() > 0 do
      iftype T <: I32 then
        into.push(IntegerDecoder.decode_signed_zigzag(buffer)?.i32())
      elseif T <: I64 then
        into.push(IntegerDecoder.decode_signed_zigzag(buffer)?)
      end
    end

primitive BoolDecoder
  fun apply(buffer: Reader): Bool ? =>
    let v = IntegerDecoder.decode_unsigned(buffer) ?
    v == 1

primitive IntegerDecoder
  fun decode_unsigned(buffer: Reader): U64 ? =>
    var b: U64 = 0
    var acc: U64 = 0
    var shift: U64 = 0
    while true do
      b = buffer.u8()?.u64()
      acc = acc or ((b and 0x7f) << shift)
      shift = shift + 7
      if (((b and 0x80) == 0) or (shift > 63)) then
        break
      end
    end
    acc

  fun decode_signed(buffer: Reader): I64 ? =>
    decode_unsigned(buffer)?.i64()

  fun decode_signed_zigzag(buffer: Reader): I64 ? =>
    ZigZag.decode_64(decode_unsigned(buffer) ?)

primitive FloatDecoder
  fun decode(buffer: Reader): F32 ? => buffer.f32_le() ?

primitive DoubleDecoder
  fun decode(buffer: Reader): F64 ? => buffer.f64_le() ?

primitive DelimitedDecoder
  fun decode_string(buffer: Reader): String iso^ ? =>
    String.from_iso_array(decode_bytes(buffer)?)

  fun decode_bytes(buffer: Reader): Array[U8] iso^ ? =>
    let size = raw_decode_len(buffer) ?
    buffer.block(size) ?

  fun raw_decode_len(buffer: Reader): USize ? =>
    USize.from[U64](IntegerDecoder.decode_unsigned(buffer) ?)
