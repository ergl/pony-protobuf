use ".."

type CheckResult[T] is Result[T, String]
type CheckResults[T] is Results[T, String]

type _ValidEnums is Array[ValidEnumDescriptorProto] val
type _ValidMessages is Array[ValidDescriptorProto] val
type _Step0 is String
type _Step1 is (String, String)
type _Step2 is (String, String, _ValidEnums)
type _Step3 is (String, String, _ValidEnums, _ValidMessages)

primitive CodeGenCheckPass
  fun _check_name(
    descr: FileDescriptorProto box)
    : CheckResult[String]
  =>
    match descr.name
    | None => (Error, "Supplied descriptor doesn't have a name")
    | let name: String => (Ok, GenNames.proto_file(name))
    end

  fun _check_proto_version(
    name: String, descr: FileDescriptorProto box)
    : CheckResult[String]
  =>
    match descr.syntax
    | "proto3" => (Error, "pony-protobuf only supports proto2 files")
    else
      (Ok, name)
    end

  fun _build_package(
    name: String, descr: FileDescriptorProto box)
    : (String, String)
  =>
    let package = try descr.package as String else "" end
    (name, package)

  fun _check_enums(
    proto_enums: Array[EnumDescriptorProto] box)
    : CheckResult[_ValidEnums]
  =>
    let enums = recover Array[ValidEnumDescriptorProto] end
    for enum in proto_enums.values() do
      try
        let fields = recover Array[(String, I32)] end
        let enum_name = enum.name as String
        for field in enum.value.values() do
          let field_name = field.name as String
          let field_number = field.number as I32
          fields.push((field_name, field_number))
        end
        enums.push(
          ValidEnumDescriptorProto(
            enum_name,
            consume fields
          )
        )
      else
        return (Error, "pony-protobuf found invalid enum")
      end
    end
    (Ok, consume enums)

  fun _check_oneofs(
    oneof_decls: Array[OneofDescriptorProto] box)
    : Array[String] val
    ?
  =>
    let decls = recover Array[String] end
    for decl in oneof_decls.values() do
      decls.push(decl.name as String)
    end
    consume decls

  fun _check_field_type(
    message_name: String,
    field_name: String,
    type_field: (FieldDescriptorProtoType | None),
    type_name: (String | None))
    : CheckResult[(AllowedProtoTypes |
                  (MessageType, String) |
                  (EnumType, String))]
  =>
    
    match type_name
    | let value: String => 
      match type_field
      | None =>
        // If type_field is not set, assume this is a message
        (Ok, (MessageType, consume value))
      | FieldDescriptorProtoTypeTYPEENUM =>
        (Ok, (EnumType, consume value))
      | FieldDescriptorProtoTypeTYPEMESSAGE =>
        (Ok, (MessageType, consume value))
      | FieldDescriptorProtoTypeTYPEGROUP =>
        (
          Error,
          "pony-protobuf: " +
          message_name + "." + field_name +
          ": group fields are not allowed"
        )
      else
        (
          Error,
          "pony-protobuf: invalid field type for "
          message_name + "." + field_name +
          ": only enums and messages are allowed"
        )
      end
    | None =>
      match type_field
      | FieldDescriptorProtoTypeTYPEGROUP =>
        (
          Error,
          "pony-protobuf: " +
          message_name + "." + field_name +
          ": group fields are not allowed"
        )
      | FieldDescriptorProtoTypeTYPEBOOL => (Ok, BoolFieldType)
      | FieldDescriptorProtoTypeTYPEINT32 => (Ok, I32FieldType)
      | FieldDescriptorProtoTypeTYPEUINT32 => (Ok, U32FieldType)
      | FieldDescriptorProtoTypeTYPEINT64 => (Ok, I64FieldType)
      | FieldDescriptorProtoTypeTYPEUINT64 => (Ok, U64FieldType)

      | FieldDescriptorProtoTypeTYPESINT32 => (Ok, I32ZigZagFieldType)
      | FieldDescriptorProtoTypeTYPESINT64 => (Ok, I64ZigZagFieldType)

      | FieldDescriptorProtoTypeTYPEDOUBLE => (Ok, F64FieldType)
      | FieldDescriptorProtoTypeTYPEFLOAT => (Ok, F32FieldType)
      | FieldDescriptorProtoTypeTYPESFIXED32 => (Ok, FixedI32FieldType)
      | FieldDescriptorProtoTypeTYPESFIXED64 => (Ok, FixedI64FieldType)
      | FieldDescriptorProtoTypeTYPEFIXED32 => (Ok, FixedU32FieldType)
      | FieldDescriptorProtoTypeTYPEFIXED64 => (Ok, FixedU64FieldType)

      | FieldDescriptorProtoTypeTYPESTRING => (Ok, StringFieldType)
      | FieldDescriptorProtoTypeTYPEBYTES => (Ok, BytesFieldType)
      | FieldDescriptorProtoTypeTYPEENUM =>
        (
          Error,
          "pony-protobuf: field " + message_name + "." + field_name +
            " is enum, but no type name was provided"
        )
      | FieldDescriptorProtoTypeTYPEMESSAGE =>
        (
          Error, 
          "pony-protobuf: field " + message_name + "." + field_name +
            " is nested message, but no type name was provided"
        )
      else
        (
          Error,
          "pony-protobuf: invalid precondition on " +
          message_name + "." + field_name +
          ": neither type_name or type are set"
        )
      end
    end

  fun _check_fields(
    message_name: String,
    fields: Array[FieldDescriptorProto] box)
    : CheckResult[Array[ValidFieldDescriptorProto] val]
  =>
    let valid_fields = recover Array[ValidFieldDescriptorProto] end
    for field in fields.values() do
      try
        let name = GenNames.message_field(field.name as String)
        let number = field.number as I32
        let label = field.label as FieldDescriptorProtoLabel
        let is_packed =
          try
            (field.options as FieldOptions box).packed as Bool
          else
            false
          end

        let type_result = _check_field_type(
          message_name,
          name,
          field.type_field,
          field.type_name
        )

        match type_result
        | (Error, let msg: String) =>
          return (Error, msg)
        | (Ok, let field_type: AllowedProtoTypes) =>
          valid_fields.push(
            ValidFieldDescriptorProto(
              name,
              number,
              label,
              field_type,
              None,
              field.default_value,
              field.oneof_index,
              is_packed
            )
          )
        | (Ok, (MessageType, let msg_name: String)) =>
          valid_fields.push(
            ValidFieldDescriptorProto(
              name,
              number,
              label,
              None,
              (MessageType, msg_name),
              field.default_value,
              field.oneof_index,
              is_packed
            )
          )
        | (Ok, (EnumType, let msg_name: String)) =>
          valid_fields.push(
            ValidFieldDescriptorProto(
              name,
              number,
              label,
              None,
              (EnumType, msg_name),
              field.default_value,
              field.oneof_index,
              is_packed
            )
          )
        end
      else
        return (Error, "pony-protobuf found invalid field")
      end
    end
    (Ok, consume valid_fields)

  fun _check_messages(
    descr_name: String,
    wanted_file: String,
    proto_messages: Array[DescriptorProto] box,
    recursion_level: USize = 0)
    : CheckResult[_ValidMessages]
  =>

    let limit = CodeGen.recursion_limit()
    if recursion_level > limit then
      return (Error, "Reached message recursion limit: " + limit.string())
    end

    // We don't need to check the entire descriptor if this is
    // a dependency. For example, there's no need to go through
    // the fields, or the oneof declarations.
    let is_dependency = wanted_file != descr_name
    let messages = recover Array[ValidDescriptorProto] end
    for message in proto_messages.values() do
      try
        let name = message.name as String

        let oneof_decls =
          if is_dependency then
            recover val Array[String] end
          else
            _check_oneofs(message.oneof_decl)?
          end

        // Don't care about the internal reasons
        let nested_enums =
          CheckResults[_ValidEnums].force_ok(
            _check_enums(message.enum_type)
          )?

        // We want to keep the recursion error
        let nested_messages_result = _check_messages(descr_name, wanted_file,
          message.nested_type, recursion_level + 1)

        match nested_messages_result
        | (Error, let reason: String) =>
          return (Error, reason)
        | (Ok, let nested_messages: Array[ValidDescriptorProto] val) =>
          let fields_result =
            if is_dependency then
              (Ok, recover val Array[ValidFieldDescriptorProto] end)
            else
              _check_fields(name, message.field)
            end
            match fields_result
            | (Error, let reason: String) =>
              return (Error, reason)
            | (Ok, let fields: Array[ValidFieldDescriptorProto] val) =>
              messages.push(
                ValidDescriptorProto(
                  name,
                  fields,
                  nested_enums,
                  nested_messages,
                  oneof_decls
                )
              )
            end
        end
      else
        return (Error, "pony-protobuf found invalid message")
      end
    end
    (Ok, consume messages)

  fun apply(
    wanted_file: String,
    descriptor: FileDescriptorProto box)
    : CheckResult[ValidFileDescriptorProto]
  =>

    let name_result = _check_name(descriptor)

    let version_result = CheckResults[String].flat_lmap[_Step0](
      name_result,
      {(name)(descriptor) =>
        CodeGenCheckPass._check_proto_version(name, descriptor)}
    )

    let package_result = CheckResults[_Step0].lmap[_Step1](
      version_result,
      {(name)(descriptor) =>
        CodeGenCheckPass._build_package(name, descriptor)}
    )

    let enums_result = CheckResults[_Step1].flat_lmap[_Step2](
      package_result,
      {(prev)(descriptor) =>
        CheckResults[_ValidEnums].lmap[_Step2](
          CodeGenCheckPass._check_enums(descriptor.enum_type),
          {(enums) => (prev._1, prev._2, enums)}
        )
      }
    )

    let messages_result = CheckResults[_Step2].flat_lmap[_Step3](
      enums_result,
      {(prev)(wanted_file, descriptor) =>
        CheckResults[_ValidMessages].lmap[_Step3](
          CodeGenCheckPass._check_messages(prev._1, wanted_file,
            descriptor.message_type),
          {(messages) => (prev._1, prev._2, prev._3, messages)}
        )
      }
    )

    CheckResults[_Step3].lmap[ValidFileDescriptorProto](
      messages_result,
      {(all_fields) =>
        ValidFileDescriptorProto(
          all_fields._1,
          all_fields._2,
          all_fields._3,
          all_fields._4
        )
      }
    )
