use "buffered"
use ".."

class Version is ProtoMessage
  var major: (I32 | None) = None
  var minor: (I32 | None) = None
  var patch: (I32 | None) = None
  var suffix: (String | None) = None

  fun compute_size(): U32 =>
    var size: U32 = 0
    match major
    | None => None
    | let major': I32 =>
      size = size + FieldSize.varint[I32](1, major')
    end
    match minor
    | None => None
    | let minor': I32 =>
      size = size + FieldSize.varint[I32](2, minor')
    end
    match patch
    | None => None
    | let patch': I32 =>
      size = size + FieldSize.varint[I32](3, patch')
    end
    match suffix
    | None => None
    | let suffix': String =>
      size = size + FieldSize.delimited(4, suffix')
    end
    size

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, VarintField) =>
        major = IntegerDecoder.decode_signed(buffer)?.i32()
      | (2, VarintField) =>
        minor = IntegerDecoder.decode_signed(buffer)?.i32()
      | (3, VarintField) =>
        patch = IntegerDecoder.decode_signed(buffer)?.i32()
      | (4, DelimitedField) =>
        suffix = DelimitedDecoder.decode_string(buffer)?
      | (_, let typ: TagKind) => SkipField(typ, buffer) ?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    match major
    | None => None
    | let major': I32 =>
      writer.write_tag(1, VarintField)
      writer.write_varint[I32](major')
    end
    match minor
    | None => None
    | let minor': I32 =>
      writer.write_tag(2, VarintField)
      writer.write_varint[I32](minor')
    end
    match patch
    | None => None
    | let patch': I32 =>
      writer.write_tag(3, VarintField)
      writer.write_varint[I32](patch')
    end
    match suffix
    | None => None
    | let suffix': String =>
      writer.write_tag(4, DelimitedField)
      writer.write_bytes(suffix')
    end

class CodeGeneratorRequest is ProtoMessage
  var file_to_generate: Array[String] = Array[String]
  var parameter: (String | None) = None
  var proto_file: Array[FileDescriptorProto] = Array[FileDescriptorProto]
  var compiler_version: (Version | None) = None
  embed _reader: Reader = Reader

  fun compute_size(): U32 =>
    var size: U32 = 0
    for v in file_to_generate.values() do
      size = size + FieldSize.delimited(1, v)
    end
    match parameter
    | None => None
    | let parameter': String =>
      size = size + FieldSize.delimited(2, parameter')
    end
    for v in proto_file.values() do
      size = size + FieldSize.inner_message(15, v)
    end
    match compiler_version
    | None => None
    | let compiler_version': this->Version =>
      size = size + FieldSize.inner_message(3, compiler_version')
    end
    size

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, DelimitedField) =>
        file_to_generate.push(DelimitedDecoder.decode_string(buffer)?)
      | (2, DelimitedField) =>
        parameter = DelimitedDecoder.decode_string(buffer) ?
      | (15, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: FileDescriptorProto = FileDescriptorProto
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        proto_file.push(v)
      | (3, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: Version = Version
        v.parse_from_stream(_reader .> append(buffer.block(size)?)) ?
        compiler_version = v
      | (_, let typ: TagKind) => SkipField(typ, buffer) ?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    for v in file_to_generate.values() do
      writer.write_tag(1, DelimitedField)
      writer.write_bytes(v)
    end
    match parameter
    | None => None
    | let parameter': String =>
      writer.write_tag(2, DelimitedField)
      writer.write_bytes(parameter')
    end
    for v in proto_file.values() do
      writer.write_tag(15, DelimitedField)
      writer.write_varint[U32](v.compute_size())
      v.write_to_stream(writer)
    end
    match compiler_version
    | None => None
    | let compiler_version': this->Version =>
      writer.write_tag(3, DelimitedField)
      writer.write_varint[U32](compiler_version'.compute_size())
      compiler_version'.write_to_stream(writer)
    end

primitive CodeGeneratorResponseFeatureFEATURENONE is ProtoEnumValue
  fun as_i32(): I32 => 0
primitive CodeGeneratorResponseFeatureFEATUREPROTO3OPTIONAL is ProtoEnumValue
  fun as_i32(): I32 => 1
type CodeGeneratorResponseFeature is (
  CodeGeneratorResponseFeatureFEATURENONE
  | CodeGeneratorResponseFeatureFEATUREPROTO3OPTIONAL
)
primitive CodeGeneratorResponseFeatureBuilder is ProtoEnum
  fun from_i32(value: I32): (CodeGeneratorResponseFeature | None) =>
    match value
    | 0 => CodeGeneratorResponseFeatureFEATURENONE
    | 1 => CodeGeneratorResponseFeatureFEATUREPROTO3OPTIONAL
    else
      None
    end

class CodeGeneratorResponse is ProtoMessage
  var field_error: (String | None) = None
  var supported_features: (U64 | None) = None
  var file: Array[CodeGeneratorResponseFile] = Array[CodeGeneratorResponseFile]
  embed _reader: Reader = Reader

  fun compute_size(): U32 =>
    var size: U32 = 0
    match field_error
    | None => None
    | let field_error': String =>
      size = size + FieldSize.delimited(1, field_error')
    end
    match supported_features
    | None => None
    | let supported_features': U64 =>
      size = size + FieldSize.varint[U64](2, supported_features')
    end
    for v in file.values() do
      size = size + FieldSize.inner_message(15, v)
    end
    size

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, DelimitedField) =>
        field_error = DelimitedDecoder.decode_string(buffer)?
      | (2, VarintField) =>
        supported_features = IntegerDecoder.decode_unsigned(buffer)?
      | (15, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: CodeGeneratorResponseFile = CodeGeneratorResponseFile
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        file.push(v)
      | (_, let typ: TagKind) => SkipField(typ, buffer) ?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    match field_error
    | None => None
    | let field_error': String =>
      writer.write_tag(1, DelimitedField)
      writer.write_bytes(field_error')
    end
    match supported_features
    | None => None
    | let supported_features': U64 =>
      writer.write_tag(2, VarintField)
      writer.write_varint[U64](supported_features')
    end
    for v in file.values() do
      writer.write_tag(15, DelimitedField)
      writer.write_varint[U32](v.compute_size())
      v.write_to_stream(writer)
    end

class CodeGeneratorResponseFile is ProtoMessage
  var name: (String | None) = None
  var insertion_point: (String | None) = None
  var content: (String | None) = None
  var generated_code_info: (GeneratedCodeInfo | None) = None
  embed _reader: Reader = Reader

  fun compute_size(): U32 =>
    var size: U32 = 0
    match name
    | None => None
    | let name': String =>
      size = size + FieldSize.delimited(1, name')
    end
    match insertion_point
    | None => None
    | let insertion_point': String =>
      size = size + FieldSize.delimited(2, insertion_point')
    end
    match content
    | None => None
    | let content': String =>
      size = size + FieldSize.delimited(15, content')
    end
    match generated_code_info
    | None => None
    | let generated_code_info': this->GeneratedCodeInfo =>
      size = size + FieldSize.inner_message(16, generated_code_info')
    end
    size

  fun ref parse_from_stream(buffer: Reader) ? =>
    while buffer.size() > 0 do
      let t = FieldTypeDecoder.decode_field(buffer) ?
      match t
      | (1, DelimitedField) =>
        name = DelimitedDecoder.decode_string(buffer)?
      | (2, DelimitedField) =>
        insertion_point = DelimitedDecoder.decode_string(buffer)?
      | (15, DelimitedField) =>
        content = DelimitedDecoder.decode_string(buffer)?
      | (16, DelimitedField) =>
        _reader.clear()
        let size = DelimitedDecoder.raw_decode_len(buffer) ?
        let v: GeneratedCodeInfo = GeneratedCodeInfo
        v.parse_from_stream(_reader .> append(buffer.block(size)?))?
        generated_code_info = v
      | (_, let typ: TagKind) => SkipField(typ, buffer) ?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    match name
    | None => None
    | let name': String =>
      writer.write_tag(1, DelimitedField)
      writer.write_bytes(name')
    end
    match insertion_point
    | None => None
    | let insertion_point': String =>
      writer.write_tag(2, DelimitedField)
      writer.write_bytes(insertion_point')
    end
    match content
    | None => None
    | let content': String =>
      writer.write_tag(15, DelimitedField)
      writer.write_bytes(content')
    end
    match generated_code_info
    | None => None
    | let generated_code_info': this->GeneratedCodeInfo =>
      writer.write_tag(15, DelimitedField)
      writer.write_varint[U32](generated_code_info'.compute_size())
      generated_code_info'.write_to_stream(writer)
    end
