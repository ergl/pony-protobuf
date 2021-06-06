use ".."

primitive CodeGenEnums
  fun apply(
    writer: CodeGenWriter ref,
    template_ctx: GenTemplate,
    enums: Array[EnumDescriptorProto] box,
    prefix: String = "")
  =>
    let field_acc = Array[(String, I32)]
    for enum in enums.values() do
      try
        let proto_name = enum.name as String
        let name = GenNames.proto_enum(proto_name.clone())
        for field in enum.value.values() do
          let proto_field_name = field.name as String
          let field_name = GenNames.proto_enum(proto_field_name.clone())
          let pony_primitive_name: String = prefix + name + field_name
          field_acc.push((
            pony_primitive_name,
            field.number as I32
          ))
        end
        writer.write_enum(prefix + name, field_acc, template_ctx)
      end
      field_acc.clear()
    end
