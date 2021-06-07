use "buffered"

class ProtoReader
  embed _reader: Reader = Reader

  new ref create() => None

  fun size(): USize =>
    _reader.size()

  fun ref pop_embed(): ProtoReader ? =>
    // TODO(borja): Avoid copying here
    // "Reader.block" copies contents into an array,
    // but we could track offsets ourselves and avoid
    // any copies, similar to what rust-protobuf does.
    // Reader needs to copy since it might not have
    // all its contents into contiguous memory, but
    // for our cases, it might be possible to receive
    // everything at once in the constructor?
    block(read_raw_delimited_length()?)?

  fun ref block(slice_size: USize): ProtoReader ? =>
    ProtoReader.>append(_reader.block(slice_size)?)

  fun ref read_field_tag(): (U64, TagKind) ? =>
    let raw = read_varint_64()?
    (raw >> 3, _TagUtil.from_num(raw and 7)?)

  fun ref read_varint_bool(): Bool ? => _raw_varint_32()? == 1
  fun ref read_varint_32(): U32 ? => _raw_varint_32()?
  fun ref read_varint_64(): U64 ? => _raw_varint_64()?

  fun ref read_varint_zigzag_32(): I32 ? => ZigZag.decode_32(_raw_varint_32()?)
  fun ref read_varint_zigzag_64(): I64 ? => ZigZag.decode_64(_raw_varint_64()?)

  fun ref read_fixed_32_integer(): U32 ? => _reader.u32_le()?
  fun ref read_fixed_32_float(): F32 ? => _reader.f32_le()?

  fun ref read_fixed_64_integer(): U64 ? => _reader.u64_le()?
  fun ref read_fixed_64_float(): F64 ? => _reader.f64_le()?

  fun ref read_packed_varint
    [T: (I32 | I64 | U32 | U64 | Bool)]
    (into: Array[T])
    ?
  =>
    let packed_size = read_raw_delimited_length()?
    let target_size = size() - packed_size
    into.reserve(into.size() + packed_size)
    while size() > target_size do
      iftype T <: Bool then
        into.push(if read_varint_32()? == 1 then true else false end)
      elseif T <: I32 then
        into.push(read_varint_32()?.i32())
      elseif T <: U32 then
        into.push(read_varint_32()?)
      elseif T <: I64 then
        into.push(read_varint_64()?.i64())
      elseif T <: U64 then
        into.push(read_varint_64()?)
      end
    end

  fun ref read_packed_varint_zigzag
    [T: (I32 | I64)]
    (into: Array[T])
    ?
  =>
    let packed_size = read_raw_delimited_length()?
    let target_size = size() - packed_size
    into.reserve(into.size() + packed_size)
    while size() > target_size do
      iftype T <: I32 then
        into.push(ZigZag.decode_32(read_varint_32()?))
      elseif T <: I64 then
        into.push(ZigZag.decode_64(read_varint_64()?))
      end
    end

  fun ref read_packed_fixed_32
    [T: (U32 | I32 | F32)]
    (into: Array[T])
    ?
  =>
    let packed_size = read_raw_delimited_length()?
    let target_size = size() - packed_size
    into.reserve(into.size() + packed_size)
    while size() > target_size do
      iftype T <: U32 then
        into.push(read_fixed_32_integer()?)
      elseif T <: I32 then
        into.push(read_fixed_32_integer()?.i32())
      elseif T <: F32 then
        into.push(read_fixed_32_float()?)
      end
    end

  fun ref read_packed_fixed_64
    [T: (U64 | I64 | F64)]
    (into: Array[T])
    ?
  =>
    let packed_size = read_raw_delimited_length()?
    let target_size = size() - packed_size
    into.reserve(into.size() + packed_size)
    while size() > target_size do
      iftype T <: U64 then
        into.push(read_fixed_64_integer()?)
      elseif T <: I64 then
        into.push(read_fixed_64_integer()?.i64())
      elseif T <: F64 then
        into.push(read_fixed_64_float()?)
      end
    end

  fun ref read_packed_enum
    [T: ProtoEnumValue val]
    (into: Array[T], builder: ProtoEnum)
    ?
  =>
    let packed_size = read_raw_delimited_length()?
    let target_size = size() - packed_size
    into.reserve(into.size() + packed_size)
    while size() > target_size do
      try
        match builder.from_i32(read_varint_32()?.i32())
        | None => None
        | let field: T =>
          iftype T <: ProtoEnumValue then
            into.push(field)
          end
        end
      end
    end

  fun ref read_bytes(): Array[U8] iso^ ? =>
    let size' = read_raw_delimited_length()?
    _reader.block(size')?

  fun ref read_string(): String iso^ ? =>
    String.from_iso_array(read_bytes()?)

  fun ref read_raw_delimited_length(): USize ? =>
    USize.from[U64](read_varint_64()?)

  fun ref skip_field(field_tag: TagKind) ? =>
    match field_tag
    | VarintField => _skip_varint() ?
    | Fixed32Field => _reader.skip(4) ?
    | Fixed64Field => _reader.skip(8) ?
    | DelimitedField => _skip_delimited() ?
    end

  fun ref _skip_varint() ? =>
    while (_reader.u8()? and 0x80) != 0 do continue end

  fun ref _skip_delimited() ? =>
    let size' = read_raw_delimited_length()?
    _reader.skip(size'.usize())?

  fun ref skip_raw(to_skip: USize) ? =>
    _reader.skip(to_skip)?

  fun ref append(data: ByteSeq) =>
    _reader.append(data)

  fun ref _raw_varint_32(): U32 ? =>
    // TODO(borja): Optimize varint if we move to a raw array
    _raw_varint_64()?.u32()

  fun ref _raw_varint_64(): U64 ? =>
    var b: U64 = 0
    var acc: U64 = 0
    var shift: U64 = 0
    while true do
      b = _reader.u8()?.u64()
      acc = acc or ((b and 0x7f) << shift)
      shift = shift + 7
      if (((b and 0x80) == 0) or (shift > 63)) then
        break
      end
    end
    acc

  // Doesn't work due to type-checker being too finicky
  // fun ref read_varint[T: (I32 | I64 | U32 | U64 | Bool)](): T ? =>
  //   iftype T <: Bool then
  //     (_raw_varint_32()? == 1)
  //   elseif T <: I32 then
  //     _raw_varint_32()?.i32()
  //   elseif T <: U32 then
  //     _raw_varint_32()?
  //   elseif T <: I64 then
  //     _raw_varint_64()?.i64()
  //   else
  //     _raw_varint_64()?
  //   end
  // fun ref read_varint_zigzag[T: (I32 | I64)](): T ? =>
  //   iftype T <: I32 then
  //     ZigZag.decode_32(read_varint[U32]()?)
  //   else
  //     ZigZag.decode_64(read_varint[U64]()?)
  //   end
  // fun ref read_fixed_32[T: (U32 | I32 | F32)](): T ? =>
  //   iftype T <: U32 then
  //     _reader.u32_le()?
  //   elseif T <: I32 then
  //     _reader.i32_le()?
  //   else
  //     _reader.f32_le()?
  //   end
  // fun ref read_fixed_64[T: (U64 | I64 | F64)](): T ? =>
  //   iftype T <: U64 then
  //     _reader.u64_le()?
  //   elseif T <: I64 then
  //     _reader.i64_le()?
  //   else
  //     _reader.f64_le()?
  //   end
