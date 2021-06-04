use "../../protobuf"

class TestPacked is ProtoMessage
  var values: Array[I32] = Array[I32]

  fun compute_size(): U32 =>
    var size: U32 = 0
    for v in values.values() do
      size = size + FieldSize.packed_varint[I32](1, values)
    end
    size

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, VarintField) =>
        let v = reader.read_varint_32()?.i32()
        values.push(v)
      | (1, DelimitedField) =>
        reader.read_packed_varint[I32](values)?
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

class TestUnpacked is ProtoMessage
  var values: Array[I32] = Array[I32]

  fun compute_size(): U32 =>
    var size: U32 = 0
    for v in values.values() do
      size = size + FieldSize.varint[I32](1, v)
    end
    size

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, VarintField) =>
        let v = reader.read_varint_32()?.i32()
        values.push(v)
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    for v in values.values() do
      writer.write_tag(1, VarintField)
      writer.write_varint[I32](v)
    end