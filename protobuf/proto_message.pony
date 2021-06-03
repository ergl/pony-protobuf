use "buffered"

trait ProtoMessage
  fun is_initialized(): Bool => true
  fun compute_size(): U32 => 0
  fun ref parse_from_stream(buffer: Reader) ? => buffer.skip(buffer.size()) ?
  fun write_to_stream(buffer: ProtoWriter) => None

trait val ProtoEnumValue
  fun as_i32(): I32

trait val ProtoEnum
  fun from_i32(value: I32): (ProtoEnumValue | None)
