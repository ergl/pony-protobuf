primitive VarintField fun string(): String val => "VarintField"
primitive Fixed32Field fun string(): String val => "Fixed32Field"
primitive Fixed64Field fun string(): String val => "Fixed64Field"
primitive DelimitedField fun string(): String val => "DelimitedField"
type KeyType is (VarintField | Fixed32Field | Fixed64Field | DelimitedField)

primitive FieldSize
  fun unsigned_size(field: U64, typ: VarintField, n: U64): U32 =>
    _tag_size(field) + raw_varint_size(n)

  fun signed_size(field: U64, typ: VarintField, n: I64): U32 =>
    _tag_size(field) + raw_varint_size(n.u64())

  fun signed_zigzag_size(field: U64, typ: VarintField, n: I64): U32 =>
    _tag_size(field) + raw_varint_size(ZigZagEncoder(n))

  fun fixed32_size(field: U64, typ: Fixed32Field, n: F32): U32 =>
    _tag_size(field) + 4

  fun fixed64_size(field: U64, typ: Fixed64Field, n: F64): U32 =>
    _tag_size(field) + 8

  fun delimited_size(field: U64, typ: DelimitedField, n: ByteSeq): U32 =>
    _tag_size(field) + raw_varint_size(n.size().u64()) + n.size().u32()

  fun embed_size(field: U64, n: ProtoMessage box): U32 =>
    let len = n.compute_size()
    _tag_size(field) + raw_varint_size(len.u64()) + len

  fun packed_unsigned_size(field: U64, arg: Array[U64] box): U32 =>
    if arg.size() == 0 then
      0
    else
      var data_size: U32 = 0
      for v in arg.values() do
        data_size = data_size + raw_varint_size(v)
      end
      _tag_size(field) + raw_varint_size(data_size.u64()) + data_size
    end

  fun packed_signed_size[T: (I32 | I64)](field: U64, arg: Array[T] box): U32 =>
    if arg.size() == 0 then
      0
    else
      var data_size: U32 = 0
      for v in arg.values() do
        data_size = data_size + raw_varint_size(v.u64())
      end
      _tag_size(field) + raw_varint_size(data_size.u64()) + data_size
    end

  fun packed_zigzag_signed_size(field: U64, arg: Array[I64] box): U32 =>
    if arg.size() == 0 then
      0
    else
      var data_size: U32 = 0
      for v in arg.values() do
        data_size = data_size + raw_varint_size(ZigZagEncoder(v))
      end
      _tag_size(field) + raw_varint_size(data_size.u64()) + data_size
    end

  fun packed_enum_size(field: U64, arg: Array[ProtoEnumValue] box): U32 =>
    if arg.size() == 0 then
      0
    else
      var data_size: U32 = 0
      for v in arg.values() do
        data_size = data_size + raw_varint_size(v.as_i32().u64())
      end
      _tag_size(field) + raw_varint_size(data_size.u64()) + data_size
    end

  fun _tag_size(field: U64): U32 => raw_varint_size((field << 3))

  // From
  // https://github.com/stepancheg/rust-protobuf/blob/bbe35a98e196c4dea67dd23ac93c0a66ca11b903/protobuf/src/rt.rs#L39
  fun raw_varint_size(v: U64): U32 =>
    let cnt: U64 = 0xffffffffffffffff
    if (v and (cnt << 7)) == 0 then
      return 1
    end
    if (v and (cnt << 14)) == 0 then
      return 2
    end
    if (v and (cnt << 21)) == 0 then
      return 3
    end
    if (v and (cnt << 28)) == 0 then
      return 4
    end
    if (v and (cnt << 35)) == 0 then
      return 5
    end
    if (v and (cnt << 42)) == 0 then
      return 6
    end
    if (v and (cnt << 49)) == 0 then
      return 7
    end
    if (v and (cnt << 56)) == 0 then
      return 8
    end
    if (v and (cnt << 63)) == 0 then
      return 9
    end
    10
