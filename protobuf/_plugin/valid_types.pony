use ".."

class val ValidEnumDescriptorProto
  let name: String
  let values: Array[(String, I32)] val

  new val create(
    name': String,
    values': Array[(String, I32)] val)
  =>
    name = name'
    values = values'

class val ValidFieldDescriptorProto
  let name: String
  let number: I32
  let label: FieldDescriptorProtoLabel
  // Either an explicit proto type, or the name of the type
  // (will be either message, or enum, since groups are removed)
  let type_field: (AllowedProtoTypes | None)
  let type_name: ((MessageType, String) | (EnumType, String) | None)
  let default_value: (String | None)
  let oneof_index: (I32 | None)
  let is_packed: Bool

  new val create(
    name': String,
    number': I32,
    label': FieldDescriptorProtoLabel,
    type_field': (AllowedProtoTypes | None),
    type_name': ((MessageType, String) | (EnumType, String) | None),
    default_value': (String | None),
    oneof_index': (I32 | None),
    is_packed': Bool)
  =>
    name = name'
    number = number'
    label = label'
    type_field = type_field'
    type_name = type_name'
    default_value = default_value'
    oneof_index = oneof_index'
    is_packed = is_packed'

class val ValidDescriptorProto
  let name: String
  let fields: Array[ValidFieldDescriptorProto] val
  let nested_enums: Array[ValidEnumDescriptorProto] val
  let nested_messages: Array[ValidDescriptorProto] val
  let oneof_decls: Array[String] val

  new val create(
    name': String,
    fields': Array[ValidFieldDescriptorProto] val,
    nested_enums': Array[ValidEnumDescriptorProto] val,
    nested_messages': Array[ValidDescriptorProto] val,
    oneof_decls': Array[String] val)
  =>
    name = name'
    fields = fields'
    nested_enums = nested_enums'
    nested_messages = nested_messages'
    oneof_decls = oneof_decls'

class val ValidFileDescriptorProto
  let name: String
  let package: String
  let enums: Array[ValidEnumDescriptorProto] val
  let messages: Array[ValidDescriptorProto] val

  new val create(
    name': String,
    package': String,
    enums': Array[ValidEnumDescriptorProto] val,
    messages': Array[ValidDescriptorProto] val)
  =>
    name = name'
    package = package'
    enums = enums'
    messages = messages'
