use "../../protobuf"

class SubMessage is ProtoMessage
  var a: (I32 | None) = None
  var b: (I32 | None) = None
  
  fun compute_size(): U32 =>
    var size: U32 = 0
    match a
    | None => None
    | let a': I32 =>
      size = size + FieldSize.varint[I32](1, a')
    end
    match b
    | None => None
    | let b': I32 =>
      size = size + FieldSize.varint[I32](2, b')
    end
    size
  
  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, VarintField) =>
        a = reader.read_varint_32()?.i32()
      | (2, VarintField) =>
        b = reader.read_varint_32()?.i32()
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end
  
  fun write_to_stream(writer: ProtoWriter) =>
    match a
    | None => None
    | let a': I32 =>
      writer.write_tag(1, VarintField)
      writer.write_varint[I32](a')
    end
    match b
    | None => None
    | let b': I32 =>
      writer.write_tag(2, VarintField)
      writer.write_varint[I32](b')
    end

primitive SampleMessageFieldAField
primitive SampleMessageFieldBField
primitive SampleMessageNameField
primitive SampleMessageSubMessageField

class SampleMessage is ProtoMessage
  var test_oneof: ((SampleMessageFieldAField, I32)
                  | (SampleMessageFieldBField, I32)
                  | (SampleMessageNameField, String)
                  | (SampleMessageSubMessageField, SubMessage)
                  | None) = (SampleMessageNameField, "foo")
  
  fun compute_size(): U32 =>
    var size: U32 = 0
    match test_oneof
    | None => None
    | (SampleMessageFieldAField, let field_a: I32) =>
      size = size + FieldSize.varint[I32](1, field_a)
    | (SampleMessageFieldBField, let field_b: I32) =>
      size = size + FieldSize.varint[I32](2, field_b)
    | (SampleMessageNameField, let name: String) =>
      size = size + FieldSize.delimited(3, name)
    | (SampleMessageSubMessageField, let sub_message: this->SubMessage) =>
      size = size + FieldSize.inner_message(4, sub_message)
    end
    size
  
  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, VarintField) =>
        test_oneof = (SampleMessageFieldAField, reader.read_varint_32()?.i32())
      | (2, VarintField) =>
        test_oneof = (SampleMessageFieldBField, reader.read_varint_32()?.i32())
      | (3, DelimitedField) =>
        test_oneof = (SampleMessageNameField, reader.read_string()?)
      | (4, DelimitedField) =>
        match test_oneof
        | (SampleMessageSubMessageField, let sub_message: SubMessage) =>
          sub_message.parse_from_stream(reader.pop_embed()?)?
        else
          test_oneof = (SampleMessageSubMessageField, SubMessage.>parse_from_stream(reader.pop_embed()?)?)
        end
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end
  
  fun write_to_stream(writer: ProtoWriter) =>
    match test_oneof
    | None => None
    | (SampleMessageFieldAField, let field_a: I32) =>
      writer.write_tag(1, VarintField)
      writer.write_varint[I32](field_a)
    | (SampleMessageFieldBField, let field_b: I32) =>
      writer.write_tag(2, VarintField)
      writer.write_varint[I32](field_b)
    | (SampleMessageNameField, let name: String) =>
      writer.write_tag(3, DelimitedField)
      writer.write_bytes(name)
    | (SampleMessageSubMessageField, let sub_message: this->SubMessage) =>
      writer.write_tag(4, DelimitedField)
      // TODO: Don't recompute size here, it's wasteful
      writer.write_varint[U32](sub_message.compute_size())
      sub_message.write_to_stream(writer)
    end

  fun is_initialized(): Bool =>
    match test_oneof
    | (SampleMessageSubMessageField, let sub_message: this->SubMessage) =>
      if not (sub_message.is_initialized()) then
        return false
      end
    else
      None
    end
    true
