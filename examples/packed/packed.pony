use "buffered"
use "../../protobuf"

class TestPacked is ProtoMessage
  var values: Array[I32] = Array[I32]
  embed _reader: Reader = Reader

  fun compute_size(): U32 =>
    var size: U32 = 0
    for v in values.values() do
      size = size + FieldSize.packed_signed_size[I32](1, values)
    end
    size

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer)?
      match t
      | (1, VarintField) =>
        let v = IntegerDecoder.decode_signed(buffer)?.i32()
        values.push(v)
      | (1, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer)?
        PackedDecoder.decode_repeated_varint[I32](
          values,
          _reader .> append(buffer.block(size)?)
        )?
      | (_, let typ: KeyType) => SkipField(typ, buffer)?
      end
    end

  fun write_to_stream(buffer: Writer) =>
    if values.size() != 0 then
      var values_size: U32 = 0
      for v in values.values() do
        values_size = values_size + FieldSize.raw_varint_size(v.u64())
      end
      FieldTypeEncoder.encode_field(1, DelimitedField, buffer)
      PackedEncoder.encode_packed_varint[I32](values, values_size, buffer)
    end

class TestUnpacked is ProtoMessage
  var values: Array[I32] = Array[I32]

  fun compute_size(): U32 =>
    var size: U32 = 0
    for v in values.values() do
      size = size + FieldSize.signed_size(1, VarintField, v.i64())
    end
    size

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer)?
      match t
      | (1, VarintField) =>
        let v = IntegerDecoder.decode_signed(buffer)?.i32()
        values.push(v)
      | (_, let typ: KeyType) => SkipField(typ, buffer)?
      end
    end

  fun write_to_stream(buffer: Writer) =>
    for v in values.values() do
      FieldTypeEncoder.encode_field(1, VarintField, buffer)
      IntegerEncoder.encode_signed(v.i64(), buffer)
    end
