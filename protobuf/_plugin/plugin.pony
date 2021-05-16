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
      size = size + FieldSize.signed_size(1, VarintField, major'.i64())
    end
    match minor
    | None => None
    | let minor': I32 =>
      size = size + FieldSize.signed_size(2, VarintField, minor'.i64())
    end
    match patch
    | None => None
    | let patch': I32 =>
      size = size + FieldSize.signed_size(3, VarintField, patch'.i64())
    end
    match suffix
    | None => None
    | let suffix': String =>
      size = size + FieldSize.delimited_size(4, DelimitedField, suffix')
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
      | (_, let typ: KeyType) => SkipField(typ, buffer) ?
      end
    end

  fun write_to_stream(buffer: Writer) =>
    match major
    | None => None
    | let major': I32 =>
      FieldTypeEncoder.encode_field(1, VarintField, buffer)
      IntegerEncoder.encode_signed(major'.i64(), buffer)
    end
    match minor
    | None => None
    | let minor': I32 =>
      FieldTypeEncoder.encode_field(2, VarintField, buffer)
      IntegerEncoder.encode_signed(minor'.i64(), buffer)
    end
    match patch
    | None => None
    | let patch': I32 =>
      FieldTypeEncoder.encode_field(3, VarintField, buffer)
      IntegerEncoder.encode_signed(patch'.i64(), buffer)
    end
    match suffix
    | None => None
    | let suffix': String =>
      FieldTypeEncoder.encode_field(4, DelimitedField, buffer)
      DelimitedEncoder.encode(suffix', buffer)
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
      size = size + FieldSize.delimited_size(1, DelimitedField, v)
    end
    match parameter
    | None => None
    | let parameter': String =>
      size = size + FieldSize.delimited_size(2, DelimitedField, parameter')
    end
    for v in proto_file.values() do
      size = size + FieldSize.embed_size(15, v)
    end
    match compiler_version
    | None => None
    | let compiler_version': this->Version =>
      size = size + FieldSize.embed_size(3, compiler_version')
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
      | (_, let typ: KeyType) => SkipField(typ, buffer) ?
      end
    end

  fun write_to_stream(buffer: Writer) =>
    for v in file_to_generate.values() do
      FieldTypeEncoder.encode_field(1, DelimitedField, buffer)
      DelimitedEncoder.encode(v, buffer)
    end
    match parameter
    | None => None
    | let parameter': String =>
      FieldTypeEncoder.encode_field(2, DelimitedField, buffer)
      DelimitedEncoder.encode(parameter', buffer)
    end
    for v in proto_file.values() do
      FieldTypeEncoder.encode_field(15, DelimitedField, buffer)
      IntegerEncoder.encode_unsigned(v.compute_size().u64(), buffer)
      v.write_to_stream(buffer)
    end
    match compiler_version
    | None => None
    | let compiler_version': this->Version =>
      FieldTypeEncoder.encode_field(3, DelimitedField, buffer)
      IntegerEncoder.encode_unsigned(compiler_version'.compute_size().u64(), buffer)
      compiler_version'.write_to_stream(buffer)
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
      size = size + FieldSize.delimited_size(1, DelimitedField, field_error')
    end
    match supported_features
    | None => None
    | let supported_features': U64 =>
      size = size + FieldSize.unsigned_size(2, VarintField, supported_features')
    end
    for v in file.values() do
      size = size + FieldSize.embed_size(15, v)
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
      | (_, let typ: KeyType) => SkipField(typ, buffer) ?
      end
    end

  fun write_to_stream(buffer: Writer) =>
    match field_error
    | None => None
    | let field_error': String =>
      FieldTypeEncoder.encode_field(1, DelimitedField, buffer)
      DelimitedEncoder.encode(field_error', buffer)
    end
    match supported_features
    | None => None
    | let supported_features': U64 =>
      FieldTypeEncoder.encode_field(2, VarintField, buffer)
      IntegerEncoder.encode_unsigned(supported_features', buffer)
    end
    for v in file.values() do
      FieldTypeEncoder.encode_field(15, DelimitedField, buffer)
      IntegerEncoder.encode_unsigned(v.compute_size().u64(), buffer)
      v.write_to_stream(buffer)
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
      size = size + FieldSize.delimited_size(1, DelimitedField, name')
    end
    match insertion_point
    | None => None
    | let insertion_point': String =>
      size = size + FieldSize.delimited_size(2, DelimitedField, insertion_point')
    end
    match content
    | None => None
    | let content': String =>
      size = size + FieldSize.delimited_size(15, DelimitedField, content')
    end
    match generated_code_info
    | None => None
    | let generated_code_info': this->GeneratedCodeInfo =>
      size = size + FieldSize.embed_size(16, generated_code_info')
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
    match insertion_point
    | None => None
    | let insertion_point': String =>
      FieldTypeEncoder.encode_field(2, DelimitedField, buffer)
      DelimitedEncoder.encode(insertion_point', buffer)
    end
    match content
    | None => None
    | let content': String =>
      FieldTypeEncoder.encode_field(15, DelimitedField, buffer)
      DelimitedEncoder.encode(content', buffer)
    end
    match generated_code_info
    | None => None
    | let generated_code_info': this->GeneratedCodeInfo =>
      FieldTypeEncoder.encode_field(15, DelimitedField, buffer)
      IntegerEncoder.encode_unsigned(generated_code_info'.compute_size().u64(), buffer)
      generated_code_info'.write_to_stream(buffer)
    end
