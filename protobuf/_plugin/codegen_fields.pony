use ".."
use "collections"

primitive Repeated
primitive RepeatedPacked
primitive Optional
primitive Required
type FieldProtoLabel is (Repeated | RepeatedPacked | Optional | Required)

primitive PrimitiveType
primitive EnumType
primitive MessageType
type FieldProtoType is (PrimitiveType | EnumType | MessageType)

class val FieldMeta is Comparable[FieldMeta]
  let name: String
  let number: String
  let _number: I32
  let wire_type: TagKind
  let uses_zigzag: Bool
  // The Pony type at the field declaration
  let pony_type_decl: String
  // If the Pony type is an Array, this contains the type of the elements
  let pony_type_inner: String
  let default_assignment: String
  let proto_type: FieldProtoType
  let proto_label: FieldProtoLabel

  new val create(
    name': String,
    number': I32,
    wire_type': TagKind,
    uses_zigzag': Bool,
    pony_type_decl': String,
    pony_type_inner': String,
    default_assignment': String,
    proto_type': FieldProtoType,
    proto_label': FieldProtoLabel)
  =>
    name = name'
    _number = number'
    number = _number.string()
    wire_type = wire_type'
    uses_zigzag = uses_zigzag'
    pony_type_decl = pony_type_decl'
    pony_type_inner = pony_type_inner'
    default_assignment = default_assignment'
    proto_type = proto_type'
    proto_label = proto_label'

  fun eq(other: FieldMeta box): Bool => _number == other._number
  fun ne(other: FieldMeta box): Bool => _number != other._number
  fun lt(other: FieldMeta box): Bool => _number < other._number

primitive CodeGenFields
  fun _get_proto_label(field: FieldDescriptorProto): FieldProtoLabel =>
    match field.label
    | FieldDescriptorProtoLabelLABELREQUIRED => Required
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
    scope: SymbolScope box,
    fields: Array[FieldDescriptorProto])
    : Array[FieldMeta] val
  =>
    // Mapping of fields to its field number and kind
    let field_meta = recover Array[FieldMeta] end
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
          let pony_type_inner,
          let default
        ) = field_type_tuple
        let proto_label = _get_proto_label(field)
        let proto_type = _get_proto_type(field)
        field_meta.push(
          FieldMeta(where
            name' = name,
            number' = field_number,
            wire_type' = wire_type,
            uses_zigzag' = needs_zigzag,
            pony_type_decl' = pony_type_decl,
            pony_type_inner' = pony_type_inner,
            default_assignment' = default,
            proto_type' = proto_type,
            proto_label' = proto_label
          )
        )
      end // TODO(borja): What do we do about anonymous messages?
    end
    recover Sort[Array[FieldMeta], FieldMeta](consume field_meta) end

  fun _find_field_type(
    field: FieldDescriptorProto,
    field_label: FieldDescriptorProtoLabel,
    scope: SymbolScope box)
    : (TagKind, Bool, String, String, String)
    ?
  =>

    match field.field_type
    | let field_type: FieldDescriptorProtoType =>
      match GenTypes.typeof(field_type, field_label, field.default_value)
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
            field.default_value,
            field_label
          )?
        )

      | (
          let wire_type: TagKind,
          let needs_zigzag: Bool,
          let pony_type_decl: String,
          let pony_type_inner: String,
          let default_value: String
        ) =>
        // Everything went OK
        (
          wire_type,
          needs_zigzag,
          pony_type_decl,
          pony_type_inner,
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
          field.default_value,
          field_label
        )?
      )
    end

  fun _find_default(
    scope: SymbolScope box,
    type_name: String,
    default: (String | None),
    label: FieldDescriptorProtoLabel)
    : String
    ?
  =>
    match default
    | None if label isnt FieldDescriptorProtoLabelLABELREPEATED =>
      "None"
    | None =>
      GenTypes.default_value(scope(type_name) as String, label)
    | let str: String =>
      GenTypes.default_value(scope(str) as String, label)
    end
