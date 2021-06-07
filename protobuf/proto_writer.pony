use "buffered"

class ProtoWriter
  embed _writer: Writer = Writer

  new ref create() => None

  fun ref write_tag(field: U64, field_tag: TagKind) =>
    _write_raw_varint((field << 3) or _TagUtil.to_num(field_tag))

  fun ref write_enum(n: ProtoEnumValue) =>
    write_varint[I32](n.as_i32())

  fun ref write_varint
    [T: (I32 | I64 | U32 | U64 | Bool)]
    (n: T)
  =>
    iftype T <: Bool then
      _write_raw_varint(
        if (n and true) then U64(1) else U64(0) end
      )
    elseif T <: I32 then
      _write_raw_varint(n.u64())
    elseif T <: U32 then
      _write_raw_varint(n.u64())
    elseif T <: I64 then
      _write_raw_varint(n.u64())
    elseif T <: U64 then
      _write_raw_varint(n)
    end

  fun ref write_varint_zigzag
    [T: (I32 | I64)]
    (n: T)
  =>
    iftype T <: I32 then
      _write_raw_varint(ZigZag.encode_32(n).u64())
    elseif T <: I64 then
      _write_raw_varint(ZigZag.encode_64(n))
    end

  fun ref write_packed_varint
    [T: (I32 | I64 | U32 | U64 | Bool)]
    (from: Array[T] box, from_size: U32)
  =>
    write_varint[U32](from_size)
    for v in from.values() do
      write_varint[T](v)
    end

  fun ref write_packed_varint_zigzag
    [T: (I32 | I64)]
    (from: Array[T] box, from_size: U32)
  =>
    write_varint[U32](from_size)
    for v in from.values() do
      write_varint_zigzag[T](v)
    end

  fun ref write_packed_fixed32
    [T: (U32 | I32 | F32)]
    (from: Array[T] box)
  =>
    write_varint[U32]((from.size() * 4).u32())
    for v in from.values() do
      write_fixed_32[T](v)
    end

  fun ref write_packed_fixed64
    [T: (U64 | I64 | F64)]
    (from: Array[T] box)
  =>
    write_varint[U32]((from.size() * 8).u32())
    for v in from.values() do
      write_fixed_64[T](v)
    end

  fun ref write_packed_enum
    [T: ProtoEnumValue val]
    (from: Array[T] box, from_size: U32)
  =>
    write_varint[U32](from_size)
    for v in from.values() do
      write_varint[I32](v.as_i32())
    end

  fun ref _write_raw_varint(n: U64) =>
    var n' = n
    while n' >= 0x80 do
      _writer.u8((0x80 or n'.u8()))
      n' = n' >> 7
    end
    _writer.u8(n'.u8())

  fun ref write_fixed_32[T: (U32 | I32 | F32)](n: T) =>
    iftype T <: U32 then
      _writer.u32_le(n)
    elseif T <: I32 then
      _writer.i32_le(n)
    elseif T <: F32 then
      _writer.f32_le(n)
    end

  fun ref write_fixed_64[T: (U64 | I64 | F64)](n: T) =>
    iftype T <: U64 then
      _writer.u64_le(n)
    elseif T <: I64 then
      _writer.i64_le(n)
    elseif T <: F64 then
      _writer.f64_le(n)
    end

  fun ref write_bytes(data: (String | Array[U8] box)) =>
    _write_raw_varint(data.size().u64())
    let data_val = match data
    | let string: String => string
    | let array: Array[U8] box =>
      // FIXME(borja): Try to avoid copying here
      let tmp = recover Array[U8].create(array.size()) end
      for elt in array.values() do
        tmp.push(elt)
      end
      consume val tmp
    end
    _writer.write(data_val)

  fun ref done(): Array[ByteSeq] iso^ =>
    _writer.done()

  fun ref done_array(): Array[U8] iso^ =>
    let b = done()
    let s = recover Array[U8](b.size()) end
    for elt in (consume b).values() do
      s.append(elt)
    end
    consume s
