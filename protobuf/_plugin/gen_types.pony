use ".."

primitive GenTypes
  fun _proto_type_to_tag_kind(
    typ: FieldDescriptorProtoType)
    : (TagKind, Bool)
  =>
    match typ
    | FieldDescriptorProtoTypeTYPEDOUBLE => (Fixed64Field, false)
    | FieldDescriptorProtoTypeTYPEFLOAT => (Fixed32Field, false)
    | FieldDescriptorProtoTypeTYPEINT64 => (VarintField, false)
    | FieldDescriptorProtoTypeTYPEUINT64 => (VarintField, false)
    | FieldDescriptorProtoTypeTYPEINT32 => (VarintField, false)
    | FieldDescriptorProtoTypeTYPEFIXED32 => (Fixed32Field, false)
    | FieldDescriptorProtoTypeTYPEFIXED64 => (Fixed64Field, false)
    | FieldDescriptorProtoTypeTYPEBOOL => (VarintField, false)
    | FieldDescriptorProtoTypeTYPESTRING => (DelimitedField, false)
    | FieldDescriptorProtoTypeTYPEMESSAGE => (DelimitedField, false)
    | FieldDescriptorProtoTypeTYPEBYTES => (DelimitedField, false)
    | FieldDescriptorProtoTypeTYPEUINT32 => (VarintField, false)
    | FieldDescriptorProtoTypeTYPEENUM => (VarintField, false)
    | FieldDescriptorProtoTypeTYPESFIXED32 => (Fixed32Field, false)
    | FieldDescriptorProtoTypeTYPESFIXED64 => (Fixed64Field, false)
    | FieldDescriptorProtoTypeTYPESINT32 => (VarintField, true)
    | FieldDescriptorProtoTypeTYPESINT64 => (VarintField, true)
    else
      // Group type?
      (DelimitedField, false)
    end

  fun _proto_type_to_pony_type(
    typ: FieldDescriptorProtoType,
    label: FieldDescriptorProtoLabel)
    : ((String, String) | None)
  =>
    match typ
    | FieldDescriptorProtoTypeTYPEDOUBLE => label_of("F64", label)
    | FieldDescriptorProtoTypeTYPEFLOAT => label_of("F32", label)
    | FieldDescriptorProtoTypeTYPEINT64 => label_of("I64", label)
    | FieldDescriptorProtoTypeTYPEUINT64 => label_of("U64", label)
    | FieldDescriptorProtoTypeTYPEINT32 => label_of("I32", label)
    | FieldDescriptorProtoTypeTYPEFIXED32 => label_of("U32", label)
    | FieldDescriptorProtoTypeTYPEFIXED64 => label_of("U64", label)
    | FieldDescriptorProtoTypeTYPEBOOL => label_of("Bool", label)
    | FieldDescriptorProtoTypeTYPESTRING => label_of("String", label)
    | FieldDescriptorProtoTypeTYPEMESSAGE => None // Caller needs to check scope
    | FieldDescriptorProtoTypeTYPEBYTES => label_of("Array[U8]", label)
    | FieldDescriptorProtoTypeTYPEUINT32 => label_of("U32", label)
    | FieldDescriptorProtoTypeTYPEENUM => None // Caller needs to check scope
    | FieldDescriptorProtoTypeTYPESFIXED32 => label_of("I32", label)
    | FieldDescriptorProtoTypeTYPESFIXED64 => label_of("I64", label)
    | FieldDescriptorProtoTypeTYPESINT32 => label_of("I32", label)
    | FieldDescriptorProtoTypeTYPESINT64 => label_of("I64", label)
    else
      // Group type?
      None
    end

  fun _default_for_type_label(
    pony_type_decl: String,
    default: String,
    typ_info: FieldDescriptorProtoType,
    label: FieldDescriptorProtoLabel)
    : String
  =>
    if default == "None" then
      // Here, we should distinguish between repeated values and optional
      // If it's optional, return "None". If repeated, use
      // pony_type_decl
      match label
      | FieldDescriptorProtoLabelLABELREPEATED => pony_type_decl
      else
        "None"
      end
    else
      match typ_info
      | FieldDescriptorProtoTypeTYPEBYTES =>
        // Proto default is a string that represents C-escaped values
        // TODO(borja): Figure how to de-escape default bytes
        // Check https://github.com/golang/protobuf/pull/427
        "Array[U8]"
      else
        default
      end
    end

  fun typeof(
    typ: FieldDescriptorProtoType,
    label: FieldDescriptorProtoLabel,
    typ_default_value_str: String)
    : ((TagKind, Bool) | (TagKind, Bool, String, String, String))
  =>
    """
    Returns the tag kind if the type needs zigzag encoding. Optionally, it also
    returns the type of the field, and the type of indicated in the proto file.
    That is, for optional fields,  the type is "( Type | None )", and the
    other type is "Type". For repeated types, the types are "Array[Type]" and
    "Type", respectively.

    If only the tag is returned, caller needs to check SymbolScope.
    """

    (let tag_kind, let uses_zigzag) = _proto_type_to_tag_kind(typ)
    match _proto_type_to_pony_type(typ, label)
    | None => (tag_kind, uses_zigzag)
    | (let pony_type: String, let pony_inner_type: String) =>
      (
        tag_kind,
        uses_zigzag,
        pony_type,
        pony_inner_type,
        _default_for_type_label(
          pony_type, typ_default_value_str, typ, label
        )
      )
    end

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
