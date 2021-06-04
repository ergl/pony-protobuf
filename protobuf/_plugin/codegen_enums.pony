use ".."

primitive CodeGenEnums
  fun apply(
    writer: CodeGenWriter ref,
    template_ctx: GenTemplate,
    scope: SymbolScope,
    enums: Array[EnumDescriptorProto] box,
    prefix: String = "")
  =>
    let field_acc = Array[(String, I32)]
    for enum in enums.values() do
      try
        let proto_name = enum.name as String
        let local_scope = SymbolScope(proto_name, scope)
        let name = GenNames.proto_enum(proto_name.clone())
        for field in enum.value.values() do
          let proto_field_name = field.name as String
          let field_name = GenNames.proto_enum(proto_field_name.clone())
          let pony_primitive_name: String = prefix + name + field_name
          field_acc.push((
            pony_primitive_name,
            field.number as I32
          ))
          local_scope(proto_field_name) = pony_primitive_name
          // This should only be in the local scope
          scope.local_insert(proto_field_name, pony_primitive_name)
        end
        // Add it to the parent scope
        scope(proto_name) = prefix + name
        writer.write_enum(prefix + name, field_acc, template_ctx)
      end
      field_acc.clear()
    end
