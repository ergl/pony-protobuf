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
  fun _get_proto_label(field: ValidFieldDescriptorProto): FieldProtoLabel =>
    match field.label
    | FieldDescriptorProtoLabelLABELREQUIRED => Required
    | FieldDescriptorProtoLabelLABELREPEATED =>
      if field.is_packed then
        RepeatedPacked
      else
        Repeated
      end
    else
      Optional
    end

  fun _get_proto_type(field: ValidFieldDescriptorProto): FieldProtoType =>
    match field.type_name
    | (MessageType, _) => MessageType
    | (EnumType, _) => EnumType
    else
      PrimitiveType
    end

  fun apply(
    writer: CodeGenWriter ref,
    template_ctx: GenTemplate,
    scope: SymbolScope box,
    fields: Array[ValidFieldDescriptorProto] val)
    : Result[Array[FieldMeta] val, String]
  =>
    // Mapping of fields to its field number and kind
    let field_meta = recover Array[FieldMeta] end
    let field_numbers = Map[String, (U64, TagKind)]
    for field in fields.values() do
      let name = GenNames.message_field(field.name)
      let field_number = field.number
      let field_type_tuple_result = _find_field_type(field, field.label, scope)
      match field_type_tuple_result
      | (Error, let error_msg: String) =>
        return (Error, error_msg)
      | (Ok, (
          let wire_type: TagKind,
          let needs_zigzag: Bool,
          let pony_type_decl: String,
          let pony_type_inner: String,
          let default: String
        )) =>
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
      end
    end
    (Ok, recover Sort[Array[FieldMeta], FieldMeta](consume field_meta) end)

  fun _find_field_type(
    field: ValidFieldDescriptorProto,
    field_label: FieldDescriptorProtoLabel,
    scope: SymbolScope box)
    : Result[(TagKind, Bool, String, String, String), String]
  =>
    match field.type_field
    | let proto_type: AllowedProtoTypes =>
      (Ok, GenTypes.typeof(proto_type, field_label, field.default_value))
    | None =>
      match field.type_name
      | None =>
        // Can't happen, the type_field and type_name are exclusive
        (
          Error,
          "pony-protobuf internal error: " + field.name +
          " with type unset, but type_name is None"
        )
      | (let kind: (MessageType | EnumType), let type_name: String) =>
        // The type has a name, check scope
        let wire_type = match kind
        | EnumType => VarintField
        | MessageType => DelimitedField
        end

        try
          let pony_type = GenTypes.label_of(scope(type_name)?, field_label)
          let pony_default =
            match field.default_value
            | None if field_label isnt FieldDescriptorProtoLabelLABELREPEATED =>
              "None"
            | None =>
              GenTypes.default_value(scope(type_name)?, field_label)
            | let str: String =>
              GenTypes.default_value(scope(str)?, field_label)
            end
          (
            Ok,
            (
              wire_type,
              false, // This is either message or enum, so no zigzag
              pony_type._1,
              pony_type._2,
              pony_default
            )
          )
        else
          (
            Error,
            "pony-protobuf internal error: " + field.name +
            " has default value, but couldn't find its type on symbol scope"
          )
        end
      end
    end
