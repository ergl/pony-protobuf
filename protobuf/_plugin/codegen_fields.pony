use ".."
use "collections"

primitive Repeated
primitive RepeatedPacked
primitive Optional
type FieldProtoLabel is (Repeated | RepeatedPacked | Optional)

primitive PrimitiveType
primitive EnumType
primitive MessageType
type FieldProtoType is (PrimitiveType | EnumType | MessageType)

class val FieldMeta
  let number: String
  let wire_type: TagKind
  let uses_zigzag: Bool
  // The Pony type at the field declaration
  let pony_type_decl: String
  // The Pony type at "read" / "write" time
  let pony_type_usage: String
  let default_assignment: String
  let proto_type: FieldProtoType
  let proto_label: FieldProtoLabel

  new val create(
    number': String,
    wire_type': TagKind,
    uses_zigzag': Bool,
    pony_type_decl': String,
    pony_type_usage': String,
    default_assignment': String,
    proto_type': FieldProtoType,
    proto_label': FieldProtoLabel)
  =>
    number = number'
    wire_type = wire_type'
    uses_zigzag = uses_zigzag'
    pony_type_decl = pony_type_decl'
    pony_type_usage = pony_type_usage'
    default_assignment = default_assignment'
    proto_type = proto_type'
    proto_label = proto_label'

primitive CodeGenFields
  fun _get_proto_label(field: FieldDescriptorProto): FieldProtoLabel =>
    match field.label
    | FieldDescriptorProtoLabelLABELREPEATED =>
      try
        let is_packed = (field.options as FieldOptions).packed as Bool
        if is_packed then
          return RepeatedPacked
        end
      end
      return Repeated
    else
      Optional
    end

  fun _get_proto_type(field: FieldDescriptorProto): FieldProtoType =>
    match field.field_type
    | FieldDescriptorProtoTypeTYPEMESSAGE => MessageType
    | FieldDescriptorProtoTypeTYPEENUM => EnumType
    else
      PrimitiveType
    end

  fun apply(
    writer: CodeGenWriter ref,
    template_ctx: GenTemplate,
    scope: SymbolScope,
    fields: Array[FieldDescriptorProto])
    : Map[String, FieldMeta] val
  =>
    // Mapping of fields to its field number and kind
    let field_meta = recover Map[String, FieldMeta] end
    let field_numbers = Map[String, (U64, TagKind)]
    for field in fields.values() do
      try
        let name = GenNames.message_field(field.name as String)
        let field_number = field.number as I32
        let field_type_tuple = _find_field_type(field,
          field.label as FieldDescriptorProtoLabel, scope)?
        (
          let wire_type,
          let needs_zigzag,
          let pony_type_decl,
          let pony_type_usage,
          let default
        ) = field_type_tuple
        let proto_label = _get_proto_label(field)
        let proto_type = _get_proto_type(field)
        field_meta(name) =
          FieldMeta(where
            number' = field_number.string(),
            wire_type' = wire_type,
            uses_zigzag' = needs_zigzag,
            pony_type_decl' = pony_type_decl,
            pony_type_usage' = pony_type_usage,
            default_assignment' = default,
            proto_type' = proto_type,
            proto_label' = proto_label
          )
      end // TODO(borja): What do we do about anonymous messages?
    end
    consume field_meta

  fun _find_field_type(
    field: FieldDescriptorProto,
    field_label: FieldDescriptorProtoLabel,
    scope: SymbolScope)
    : (TagKind, Bool, String, String, String)
    ?
  =>

    let default_value_str = match field.default_value
    | let default_value': String => default_value'
    | None => "None"
    end

    match field.field_type
    | let field_type: FieldDescriptorProtoType =>
      match GenTypes.typeof(field_type, field_label, default_value_str)
      | (let wire_type: TagKind, let needs_zigzag: Bool) =>
        // We couldn't decipher the type, it's possible that it's a
        // message or enum type.
        let pony_type = GenTypes.label_of(
          scope(field.type_name as String) as String,
          field_label
        )
        (
          wire_type,
          needs_zigzag,
          pony_type._1,
          pony_type._2,
          _find_default(
            scope,
            field.type_name as String,
            default_value_str,
            field_label
          )?
        )

      | (
          let wire_type: TagKind,
          let needs_zigzag: Bool,
          let pony_type_decl: String,
          let pony_type_usage: String,
          let default_value: String
        ) =>
        // Everything went OK
        (
          wire_type,
          needs_zigzag,
          pony_type_decl,
          pony_type_usage,
          default_value
        )
      end
    else
      // Allowed, but type_name better be set.
      // We assume that this is a message type
      let pony_type = GenTypes.label_of(
        scope(field.type_name as String) as String,
        field_label
      )
      (
        DelimitedField,
        false, // This is either message or enum, so no zigzag
        pony_type._1,
        pony_type._2,
        _find_default(
          scope,
          field.type_name as String,
          default_value_str,
          field_label
        )?
      )
    end

  fun _find_default(
    scope: SymbolScope,
    type_name: String,
    default: String,
    label: FieldDescriptorProtoLabel)
    : String
    ?
  =>
    let has_default = default != "None"
    if
      (not has_default) and
      (label isnt FieldDescriptorProtoLabelLABELREPEATED)
    then
      return "None"
    end

    GenTypes.default_value(
      if has_default then
        scope(default) as String
      else
        scope(type_name) as String
      end,
      label
    )
