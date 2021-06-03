use "buffered"

trait ProtoMessage
  fun is_initialized(): Bool => true
  fun compute_size(): U32 => 0
  fun write_to_stream(writer: ProtoWriter) => None
  fun ref parse_from_stream(reader: ProtoReader) ? =>
    reader.skip_raw(reader.size())?

trait val ProtoEnumValue
  fun as_i32(): I32

trait val ProtoEnum
  fun from_i32(value: I32): (ProtoEnumValue | None)
