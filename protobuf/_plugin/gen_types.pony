use ".."

primitive GenTypes
  fun _proto_type_to_tag_kind(typ: FieldDescriptorProtoType): TagKind =>
    match typ
    | FieldDescriptorProtoTypeTYPEDOUBLE => Fixed64Field
    | FieldDescriptorProtoTypeTYPEFLOAT => Fixed32Field
    | FieldDescriptorProtoTypeTYPEINT64 => VarintField
    | FieldDescriptorProtoTypeTYPEUINT64 => VarintField
    | FieldDescriptorProtoTypeTYPEINT32 => VarintField
    | FieldDescriptorProtoTypeTYPEFIXED32 => Fixed32Field
    | FieldDescriptorProtoTypeTYPEFIXED64 => Fixed64Field
    | FieldDescriptorProtoTypeTYPEBOOL => VarintField
    | FieldDescriptorProtoTypeTYPESTRING => DelimitedField
    | FieldDescriptorProtoTypeTYPEMESSAGE => DelimitedField
    | FieldDescriptorProtoTypeTYPEBYTES => DelimitedField
    | FieldDescriptorProtoTypeTYPEUINT32 => VarintField
    | FieldDescriptorProtoTypeTYPEENUM => VarintField
    | FieldDescriptorProtoTypeTYPESFIXED32 => Fixed32Field
    | FieldDescriptorProtoTypeTYPESFIXED64 => Fixed64Field
    | FieldDescriptorProtoTypeTYPESINT32 => VarintField
    | FieldDescriptorProtoTypeTYPESINT64 => VarintField
    else
      // Group type?
      DelimitedField
    end

  fun _proto_type_to_pony_type(
    typ: FieldDescriptorProtoType,
    label: FieldDescriptorProtoLabel)
    : (String | None)
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
    typ_str: String,
    default: String,
    typ_info: FieldDescriptorProtoType)
    : String
  =>
    if default == "None" then
      typ_str
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
    : (TagKind | (TagKind, String, String))
  =>
    """
    Returns the tag kind and optionally, the type name and default
    value of a proto type. If only the tag is returned, caller needs
    to check SymbolScope.
    """

    let tag_kind = _proto_type_to_tag_kind(typ)
    match _proto_type_to_pony_type(typ, label)
    | None => tag_kind
    | let str: String =>
      (
        tag_kind,
        str,
        _default_for_type_label(str, typ_default_value_str, typ)
      )
    end

  fun label_of(typ: String, label: FieldDescriptorProtoLabel): String =>
    match label
    | FieldDescriptorProtoLabelLABELREPEATED => "Array[" + typ + "]"
    else
      // We also wrap required fields in None, to be able to distinguish
      // uninitalized messages from optionals
      // 
      // Clients are encouraged to check "is_initialized" before operating
      // on the message class.
      "(" + typ + " | None)"
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
