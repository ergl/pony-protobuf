use "buffered"
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
      size = size + FieldSize.delimited_size(1, DelimitedField, number')
    end
    match field_type
    | None => None
    | let field_type': PersonPhoneType =>
      size = size + FieldSize.signed_size(2, VarintField, field_type'.as_i32().i64())
    end
    size

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, DelimitedField) =>
        number = DelimitedDecoder.decode_string(buffer) ?
      | (2, VarintField) =>
        let n = IntegerDecoder.decode_signed(buffer) ?
        field_type = PersonPhoneTypeBuilder.from_i32(n.i32())
      | (_, let typ: KeyType) => SkipField(typ, buffer) ?
      end
    end

  fun write_to_stream(buffer: Writer) =>
    match number
    | None => None
    | let number': String =>
      FieldTypeEncoder.encode_field(1, DelimitedField, buffer)
      DelimitedEncoder.encode(number', buffer)
    end
    match field_type
    | None => None
    | let field_type': PersonPhoneType =>
      FieldTypeEncoder.encode_field(2, VarintField, buffer)
      IntegerEncoder.encode_signed(field_type'.as_i32().i64(), buffer)
    end

class Person is ProtoMessage
  var name: (String | None) = None
  var id: (I32 | None) = None
  var email: (String | None) = None
  var phone: Array[PersonPhoneNumber] = Array[PersonPhoneNumber]
  embed _reader: Reader = Reader

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
      size = size + FieldSize.delimited_size(1, DelimitedField, name')
    end
    match id
    | None => None
    | let id': I32 =>
      size = size + FieldSize.signed_size(2, VarintField, id'.i64())
    end
    match email
    | None => None
    | let email': String =>
      size = size + FieldSize.delimited_size(3, DelimitedField, email')
    end
    for v in phone.values() do
      size = size + FieldSize.embed_size(4, v)
    end
    size

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, DelimitedField) =>
        name = DelimitedDecoder.decode_string(buffer) ?
      | (2, VarintField) =>
        id = IntegerDecoder.decode_signed(buffer)?.i32()
      | (3, DelimitedField) =>
        email = DelimitedDecoder.decode_string(buffer) ?
      | (4, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: PersonPhoneNumber = PersonPhoneNumber
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        phone.push(v)
      | (_, let typ: KeyType) => SkipField(typ, buffer) ?
      end
    end

  fun write_to_stream(buffer: Writer) =>
    match name
    | None => None
    | let name': String =>
      FieldTypeEncoder.encode_field(1, DelimitedField, buffer)
      DelimitedEncoder.encode(name', buffer)
    end
    match id
    | None => None
    | let id': I32 =>
      FieldTypeEncoder.encode_field(2, VarintField, buffer)
      IntegerEncoder.encode_signed(id'.i64(), buffer)
    end
    match email
    | None => None
    | let email': String =>
      FieldTypeEncoder.encode_field(3, DelimitedField, buffer)
      DelimitedEncoder.encode(email', buffer)
    end
    for v in phone.values() do
      FieldTypeEncoder.encode_field(4, DelimitedField, buffer)
      IntegerEncoder.encode_unsigned(v.compute_size().u64(), buffer)
      v.write_to_stream(buffer)
    end

class AddressBook is ProtoMessage
  var person: Array[Person] = Array[Person]
  embed _reader: Reader = Reader

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
      size = size + FieldSize.embed_size(1, v)
    end
    size

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: Person = Person
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        person.push(v)
      | (_, let typ: KeyType) => SkipField(typ, buffer) ?
      end
    end

  fun write_to_stream(buffer: Writer) =>
    for v in person.values() do
      FieldTypeEncoder.encode_field(1, DelimitedField, buffer)
      IntegerEncoder.encode_unsigned(v.compute_size().u64(), buffer)
      v.write_to_stream(buffer)
    end
