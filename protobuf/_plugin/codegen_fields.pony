use ".."
use "collections"
use persistent = "collections/persistent"

type DeclMeta is (OneOfMeta | FieldMeta)

class val OneOfMeta is Comparable[DeclMeta]
  """
  oneofs are defined like OCaml's variant types: a union of tuple types, where
  the first element is a primitive, and the second element is a raw Pony type.
  For a oneof like:

  ```proto
  message SampleMessage {
    oneof test_oneof {
      int32 field_a = 1;
      int32 field_b = 2;
      string name = 3 [default = "foo"];
    }
  }
  ```

  The corresponding Pony type is:

  ```pony
  primitive SampleMessageFieldAField
  primitive SampleMessageFieldBField
  primitive SampleMessageNameField

  class SampleMessage
    var test_oneof: ((SampleMessageFieldAField, I32)
                    | (SampleMessageFieldBField, I32)
                    | (SampleMessageNameField, String)
                    | None)
  ```

  Since oneofs are always optional, we have to add `None` to count for the
  missing case.
  """

  let name: String
  // The fields inside this oneof, along with their Pony "primitive" name
  let fields: Array[(String, FieldMeta)] val

  new val create(
    name': String,
    fields': Array[(String, FieldMeta)] val)
  =>
    name = name'
    fields = fields'

  fun ne(other: DeclMeta): Bool => not eq(other)
  fun eq(other: DeclMeta): Bool =>
    match other
    | let oneof: OneOfMeta => name == oneof.name
    else
      false
    end

  fun lt(other: DeclMeta): Bool =>
    match other
    | let oneof: OneOfMeta => name < oneof.name
    else
      false // Always ordered after regular fields
    end

primitive Repeated
primitive RepeatedPacked
primitive Optional
primitive Required
type FieldProtoLabel is (Repeated | RepeatedPacked | Optional | Required)

primitive PrimitiveType
primitive EnumType
primitive MessageType
type FieldProtoType is (PrimitiveType | EnumType | MessageType)

class val FieldMeta is Comparable[DeclMeta]
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

  fun ne(other: DeclMeta): Bool => not eq(other)
  fun eq(other: DeclMeta): Bool =>
    match other
    | let field: FieldMeta => _number == field._number
    else
      false
    end

  fun lt(other: DeclMeta): Bool =>
    match other
    | let field: FieldMeta => _number < field._number
    else
      false //fields always before oneofs
    end

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
    message_name: String,
    oneof_decls: Array[String] val,
    fields: Array[ValidFieldDescriptorProto] val)
    : Result[Array[DeclMeta] val, String]
  =>
    let oneof_mapping = Map[String, persistent.Vec[FieldMeta]]
    for decl in oneof_decls.values() do
      oneof_mapping(decl) = persistent.Vec[FieldMeta]
    end

    let metas = recover Array[DeclMeta] end
    // Mapping of fields to its field number and kind
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
          let field_meta = FieldMeta(where
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

          match field.oneof_index
          | None => metas.push(field_meta)
          | let idx: I32 =>
            try
              let decl = oneof_decls(idx.usize())?
              let prev = oneof_mapping(decl)? // Can't fail
              oneof_mapping(decl) = prev.push(field_meta)
            else
              return (Error,
                "pony-protobuf: can't find oneof declaration for field " + name)
            end
          end
      end
    end
    for (oneof_name, oneof_fields_vec) in oneof_mapping.pairs() do
      // What a mess, sort this out
      var oneof_fields_array = Array[FieldMeta]
      for oneof_field in oneof_fields_vec.values() do
        oneof_fields_array.push(oneof_field)
      end
      oneof_fields_array = Sort[Array[FieldMeta], FieldMeta](oneof_fields_array)
      let oneof_fields = recover Array[(String, FieldMeta)] end
      for oneof_field in oneof_fields_array.values() do
        oneof_fields.push((
          GenNames.oneof_field(oneof_field.name.clone(), message_name),
          oneof_field
        ))
      end
      metas.push(OneOfMeta(oneof_name, consume oneof_fields))
    end
    (Ok, recover Sort[Array[DeclMeta], DeclMeta](consume metas) end)

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
