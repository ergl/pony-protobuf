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
        let enum_name = GenNames.top_level_name(proto_name.clone(), prefix)
        for field in enum.value.values() do
          let proto_field_name = field.name as String
          let enum_field_name = GenNames.top_level_name(
            proto_field_name.clone(),
            enum_name
          )
          field_acc.push((
            enum_field_name,
            field.number as I32
          ))
        end
        writer.write_enum(enum_name, field_acc, template_ctx)
      end
      field_acc.clear()
    end
