use ".."

primitive BoolFieldType
primitive I32FieldType
primitive U32FieldType
primitive I64FieldType
primitive U64FieldType
primitive I32ZigZagFieldType
primitive I64ZigZagFieldType
primitive F32FieldType
primitive F64FieldType
primitive FixedI32FieldType
primitive FixedI64FieldType
primitive FixedU32FieldType
primitive FixedU64FieldType
primitive StringFieldType
primitive BytesFieldType

// Types that are directly translatable to Pony
type AllowedProtoTypes is (
  BoolFieldType
  | I32FieldType
  | U32FieldType
  | I64FieldType
  | U64FieldType
  | I32ZigZagFieldType
  | I64ZigZagFieldType
  | F32FieldType
  | F64FieldType
  | FixedI32FieldType
  | FixedI64FieldType
  | FixedU32FieldType
  | FixedU64FieldType
  | StringFieldType
  | BytesFieldType
)

primitive GenTypes
  fun _proto_type_to_tag_kind(
    typ: AllowedProtoTypes)
    : (TagKind, Bool)
  =>
    match typ
    | BoolFieldType => (VarintField, false)
    | I32FieldType => (VarintField, false)
    | U32FieldType => (VarintField, false)
    | I64FieldType => (VarintField, false)
    | U64FieldType => (VarintField, false)
    | I32ZigZagFieldType => (VarintField, true)
    | I64ZigZagFieldType => (VarintField, true)
    | F32FieldType => (Fixed32Field, false)
    | F64FieldType => (Fixed64Field, false)
    | FixedI32FieldType => (Fixed32Field, false)
    | FixedI64FieldType => (Fixed64Field, false)
    | FixedU32FieldType => (Fixed32Field, false)
    | FixedU64FieldType => (Fixed64Field, false)
    | StringFieldType => (DelimitedField, false)
    | BytesFieldType => (DelimitedField, false)
    end

  fun _proto_type_to_pony_type(
    typ: AllowedProtoTypes,
    label: FieldDescriptorProtoLabel)
    : (String, String)
  =>
    match typ
    | BoolFieldType => label_of("Bool", label)
    | I32FieldType => label_of("I32", label)
    | U32FieldType => label_of("U32", label)
    | I64FieldType => label_of("I64", label)
    | U64FieldType => label_of("U64", label)
    | I32ZigZagFieldType => label_of("I32", label)
    | I64ZigZagFieldType => label_of("I64", label)
    | F32FieldType => label_of("F32", label)
    | F64FieldType => label_of("F64", label)
    | FixedI32FieldType => label_of("I32", label)
    | FixedI64FieldType => label_of("I64", label)
    | FixedU32FieldType => label_of("U32", label)
    | FixedU64FieldType => label_of("U64", label)
    | StringFieldType => label_of("String", label)
    | BytesFieldType => label_of("Array[U8]", label)
    end

  fun _default_for_type_label(
    pony_type_decl: String,
    default: (String | None),
    typ_info: AllowedProtoTypes,
    label: FieldDescriptorProtoLabel)
    : String
  =>
    match default
    | String if typ_info is BytesFieldType =>
        // Proto default is a string that represents C-escaped values
        // TODO(borja): Figure how to de-escape default bytes
        // Check https://github.com/golang/protobuf/pull/427
        "Array[U8]"

    | let str: String if typ_info is StringFieldType =>
        // Quote default
        "\"" + str + "\""

    | let str: String => str

    | None if label is FieldDescriptorProtoLabelLABELREPEATED => pony_type_decl

    | None => "None"
    end

  fun typeof(
    typ: AllowedProtoTypes,
    label: FieldDescriptorProtoLabel,
    typ_default_value: (String | None))
    : (TagKind, Bool, String, String, String)
  =>
    """
    Returns the wire type, if the type needs zigzag encoding, the translated
    Pony type used for the variable definition, the inner type (if the Pony
    type is an array, the type of the elements), and the default value to
    assign to the field.

    That is, for optional fields,  the type is "( Type | None )", and the
    other type is "Type". For repeated types, the types are "Array[Type]" and
    "Type", respectively.
    """

    (let tag_kind, let uses_zigzag) = _proto_type_to_tag_kind(typ)
    (let pony_type: String, let pony_inner_type) =
      _proto_type_to_pony_type(typ, label)
    (
      tag_kind,
      uses_zigzag,
      pony_type,
      pony_inner_type,
      _default_for_type_label(
        pony_type, typ_default_value, typ, label
      )
    )

  fun varint_kind(
    is_zigzag: Bool,
    pony_type_decl: String)
    : String
  =>
    if pony_type_decl == "U64" then
      "64"
    elseif pony_type_decl == "I64" then
      if is_zigzag then "zigzag_64" else "64" end
    elseif pony_type_decl == "U32" then
      "32"
    elseif pony_type_decl == "I32" then
      if is_zigzag then "zigzag_32" else "32" end
    else
      // Only bool left, since enums are handled somewhere else
      "bool"
    end

  fun convtype(
    wire_type: TagKind,
    is_zigzag: Bool,
    pony_type_decl: String)
    : (String | None)
  =>
    match wire_type
    | VarintField =>
      if pony_type_decl == "U64" then
        None
      elseif pony_type_decl == "I64" then
        if is_zigzag then None else "i64" end
      elseif pony_type_decl == "U32" then
        None
      elseif pony_type_decl == "I32" then
        if is_zigzag then None else "i32" end
      end
    | Fixed32Field =>
      if pony_type_decl == "I32" then
        "i32"
      else
        None
      end
    | Fixed64Field =>
      if pony_type_decl == "I64" then
        "i64"
      else
        None
      end
    else
      // Delimited types don't need a convtype
      None
    end

  fun label_of(
    typ: String,
    label: FieldDescriptorProtoLabel)
    : (String, String)
  =>
    match label
    | FieldDescriptorProtoLabelLABELREPEATED =>
      ("Array[" + typ + "]", typ)
    else
      // We also wrap required fields in None, to be able to distinguish
      // uninitalized messages from optionals
      // 
      // Clients are encouraged to check "is_initialized" before operating
      // on the message class.
      ("(" + typ + " | None)", typ)
    end

  fun default_value(
    return_type: String,
    label: FieldDescriptorProtoLabel)
    : String
  =>
    """
    Get the default value for a protobuf named type (message or enum)
    """
    // No default value set, use whatever is the default for the type
    match label
    | FieldDescriptorProtoLabelLABELREPEATED => "Array[" + return_type + "]"
    else
      // Optional or required, choose None
      return_type
    end
