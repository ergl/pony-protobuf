use "../../protobuf"

primitive PersonPhoneTypeMOBILE is ProtoEnumValue
  fun as_i32(): I32 => 0
primitive PersonPhoneTypeHOME is ProtoEnumValue
  fun as_i32(): I32 => 1
primitive PersonPhoneTypeWORK is ProtoEnumValue
  fun as_i32(): I32 => 2
type PersonPhoneType is (
  PersonPhoneTypeMOBILE
  | PersonPhoneTypeHOME
  | PersonPhoneTypeWORK
)
primitive PersonPhoneTypeBuilder is ProtoEnum
  fun from_i32(value: I32): (PersonPhoneType | None) =>
    match value
    | 0 => PersonPhoneTypeMOBILE
    | 1 => PersonPhoneTypeHOME
    | 2 => PersonPhoneTypeWORK
    else
      None
    end

class PersonPhoneNumber is ProtoMessage
  var number: (String | None) = None
  var field_type: (PersonPhoneType | None) = PersonPhoneTypeHOME

  fun is_initialized(): Bool =>
    if number is None then
      return false
    end
    true

  fun compute_size(): U32 =>
    var size: U32 = 0
    match number
    | None => None
    | let number': String =>
      size = size + FieldSize.delimited(1, number')
    end
    match field_type
    | None => None
    | let field_type': PersonPhoneType =>
      size = size + FieldSize.enum(2, field_type')
    end
    size

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag() ?
      | (1, DelimitedField) =>
        number = reader.read_string()?
      | (2, VarintField) =>
        field_type =
          PersonPhoneTypeBuilder.from_i32(reader.read_varint_32()?.i32())
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    match number
    | None => None
    | let number': String =>
      writer.write_tag(1, DelimitedField)
      writer.write_bytes(number')
    end
    match field_type
    | None => None
    | let field_type': PersonPhoneType =>
      writer.write_tag(2, VarintField)
      writer.write_enum(field_type')
    end

class Person is ProtoMessage
  var name: (String | None) = None
  var id: (I32 | None) = None
  var email: (String | None) = None
  var phone: Array[PersonPhoneNumber] = Array[PersonPhoneNumber]

  fun is_initialized(): Bool =>
    if name is None then
      return false
    end
    if id is None then
      return false
    end
    for v in phone.values() do
      if not v.is_initialized() then
        return false
      end
    end
    true

  fun compute_size(): U32 =>
    var size: U32 = 0
    match name
    | None => None
    | let name': String =>
      size = size + FieldSize.delimited(1, name')
    end
    match id
    | None => None
    | let id': I32 =>
      size = size + FieldSize.varint[I32](2, id')
    end
    match email
    | None => None
    | let email': String =>
      size = size + FieldSize.delimited(3, email')
    end
    for v in phone.values() do
      size = size + FieldSize.inner_message(4, v)
    end
    size

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, DelimitedField) =>
        name = reader.read_string()?
      | (2, VarintField) =>
        id = reader.read_varint_32()?.i32()
      | (3, DelimitedField) =>
        email = reader.read_string()?
      | (4, DelimitedField) =>
        let v: PersonPhoneNumber = PersonPhoneNumber
        v.parse_from_stream(reader.pop_embed()?)?
        phone.push(v)
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    match name
    | None => None
    | let name': String =>
      writer.write_tag(1, DelimitedField)
      writer.write_bytes(name')
    end
    match id
    | None => None
    | let id': I32 =>
      writer.write_tag(2, VarintField)
      writer.write_varint[I32](id')
    end
    match email
    | None => None
    | let email': String =>
      writer.write_tag(3, DelimitedField)
      writer.write_bytes(email')
    end
    for v in phone.values() do
      writer.write_tag(4, DelimitedField)
      // TODO(borja): Call a "cached_size" or something, avoid recomputing
      writer.write_varint[U32](v.compute_size())
      v.write_to_stream(writer)
    end

class AddressBook is ProtoMessage
  var person: Array[Person] = Array[Person]

  fun is_initialized(): Bool =>
    for v in person.values() do
      if not v.is_initialized() then
        return false
      end
    end
    true

  fun compute_size(): U32 =>
    var size: U32 = 0
    for v in person.values() do
      size = size + FieldSize.inner_message(1, v)
    end
    size

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag() ?
      | (1, DelimitedField) =>
        let v: Person = Person
        v.parse_from_stream(reader.pop_embed()?)?
        person.push(v)
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    for v in person.values() do
      writer.write_tag(1, DelimitedField)
      writer.write_varint[U32](v.compute_size())
      v.write_to_stream(writer)
    end