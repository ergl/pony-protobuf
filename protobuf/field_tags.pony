primitive VarintField fun string(): String val => "VarintField"
primitive Fixed32Field fun string(): String val => "Fixed32Field"
primitive Fixed64Field fun string(): String val => "Fixed64Field"
primitive DelimitedField fun string(): String val => "DelimitedField"
type TagKind is (VarintField | Fixed32Field | Fixed64Field | DelimitedField)

primitive _TagUtil
  fun to_num(t: TagKind): U64 =>
    match t
    | VarintField => 0
    | Fixed64Field => 1
    | DelimitedField => 2
    | Fixed32Field => 5
    end

  fun from_num(n: U64): TagKind ? =>
    match n
    | 0 => VarintField
    | 1 => Fixed64Field
    | 2 => DelimitedField
    | 5 => Fixed32Field
    else
      error
    end

primitive FieldSize
  fun varint
    [T: (I32 | I64 | U32 | U64 | Bool)]
    (field: U64, n: T)
    : U32
  =>
    let field_size =
      iftype T <: Bool then
        raw_varint(if (n and true) then 1 else 0 end)
      elseif T <: I32 then
        raw_varint(U64.from[I32](n))
      elseif T <: I64 then
        raw_varint(U64.from[I64](n))
      elseif T <: U32 then
        raw_varint(U64.from[U32](n))
      elseif T <: U64 then
        raw_varint(n)
      else
        0 // Can't happen, but Pony doesn't know
      end

    _tag_size(field) + field_size

  fun varint_zigzag
    [T: (I32 | I64)]
    (field: U64, n: T)
    : U32
  =>
    let field_size =
      iftype T <: I32 then
        raw_varint(ZigZag.encode_32(n).u64())
      elseif T <: I64 then
        raw_varint(ZigZag.encode_64(n))
      else
        0 // Can't happen, but Pony doesn't know
      end
    _tag_size(field) + field_size

  fun enum(field: U64, enum_field: ProtoEnumValue): U32 =>
    _tag_size(field) + raw_varint(enum_field.as_i32().u64())

  fun fixed32(field: U64): U32 => _tag_size(field) + 4

  fun fixed64(field: U64): U32 => _tag_size(field) + 8

  fun delimited(field: U64, bytes: (String box | Array[U8] box)): U32 =>
    _tag_size(field) + raw_varint(bytes.size().u64()) + bytes.size().u32()

  fun inner_message(field: U64, n: ProtoMessage box): U32 =>
    let len = n.compute_size()
    _tag_size(field) + raw_varint(len.u64()) + len

  fun packed_varint
    [T: (I32 | I64 | U32 | U64 | Bool)]
    (field: U64, arg: Array[T] box)
    : U32
  =>
    if arg.size() == 0 then
      0
    else
      var data_size: U32 = 0
      for v in arg.values() do
        iftype T <: Bool then
          data_size = data_size + raw_varint(if (v and true) then 1 else 0 end)
        elseif T <: I32 then
          data_size = data_size + raw_varint(v.u64())
        elseif T <: I64 then
          data_size = data_size + raw_varint(v.u64())
        elseif T <: U32 then
          data_size = data_size + raw_varint(v.u64())
        elseif T <: U64 then
          data_size = data_size + raw_varint(v)
        end
      end
      _tag_size(field) + raw_varint(data_size.u64()) + data_size
    end

  fun packed_varint_zigzag
    [T: (I32 | I64)]
    (field: U64, arg: Array[T] box)
    : U32
  =>
    if arg.size() == 0 then
      0
    else
      var data_size: U32 = 0
      for v in arg.values() do
        iftype T <: I32 then
          data_size = data_size + raw_varint(ZigZag.encode_32(v).u64())
        elseif T <: I64 then
          data_size = data_size + raw_varint(ZigZag.encode_64(v))
        end
      end
      _tag_size(field) + raw_varint(data_size.u64()) + data_size
    end

  fun packed_fixed32
    [T: (I32 | U32 | F32)]
    (field: U64, arg: Array[T] box)
    : U32
  =>
    let array_size = arg.size()
    if array_size == 0 then
      0
    else
      let data_size: USize = 4 * array_size
      _tag_size(field) + raw_varint(data_size.u64()) + data_size.u32()
    end

  fun packed_fixed64
    [T: (I64 | U64 | F64)]
    (field: U64, arg: Array[T] box)
    : U32
  =>
    let array_size = arg.size()
    if array_size == 0 then
      0
    else
      let data_size: USize = 8 * array_size
      _tag_size(field) + raw_varint(data_size.u64()) + data_size.u32()
    end

  fun packed_enum
    [T: ProtoEnumValue val]
    (field: U64, arg: Array[T] box)
    : U32
  =>
    if arg.size() == 0 then
      0
    else
      var data_size: U32 = 0
      for v in arg.values() do
        data_size = data_size + raw_varint(v.as_i32().u64())
      end
      _tag_size(field) + raw_varint(data_size.u64()) + data_size
    end

  fun packed_enum_size(field: U64, arg: Array[ProtoEnumValue] box): U32 =>
    if arg.size() == 0 then
      0
    else
      var data_size: U32 = 0
      for v in arg.values() do
        data_size = data_size + raw_varint(v.as_i32().u64())
      end
      _tag_size(field) + raw_varint(data_size.u64()) + data_size
    end

  fun _tag_size(field: U64): U32 => raw_varint((field << 3))

  // From
  // https://github.com/stepancheg/rust-protobuf/blob/bbe35a98e196c4dea67dd23ac93c0a66ca11b903/protobuf/src/rt.rs#L39
  fun raw_varint(v: U64): U32 =>
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
