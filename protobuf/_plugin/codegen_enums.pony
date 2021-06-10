use ".."

primitive CodeGenEnums
  fun apply(
    writer: CodeGenWriter ref,
    template_ctx: GenTemplate,
    enums: Array[ValidEnumDescriptorProto] box,
    prefix: String = "")
  =>
    let field_acc = Array[(String, I32)]
    for enum in enums.values() do
      let enum_name = GenNames.top_level_name(enum.name.clone(), prefix)
      for (field, number) in enum.values.values() do
        field_acc.push((
          GenNames.top_level_name(field.clone(), enum_name),
          number
        ))
      end
      writer.write_enum(
        enum_name,
        field_acc,
        template_ctx
      )
      field_acc.clear()
    end
