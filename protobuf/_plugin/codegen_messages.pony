use ".."

primitive CodeGenMessages
  fun apply(
    writer: CodeGenWriter ref,
    template_ctx: GenTemplate,
    scope_map: SymbolScopeMap,
    messages: Array[DescriptorProto],
    prefix: String = "",
    recursion_level: USize = 0)
  =>
    if recursion_level > CodeGen.recursion_limit() then
      // TODO(borja): Inform caller here
      return
    end

    for message in messages.values() do
      try
        let proto_name = message.name as String
        let name = GenNames.proto_enum(prefix + proto_name)

        CodeGenEnums(writer, template_ctx, message.enum_type, name)
        CodeGenMessages(writer, template_ctx, scope_map, message.nested_type,
          name, recursion_level + 1)

        // We did a scope pass first, this shouldn't fail
        // Have box capability since we don't want children to
        // modify the scope.
        let my_scope = scope_map(name) as SymbolScope box
        let field_meta =
          CodeGenFields(writer, template_ctx, my_scope, message.field)
        writer.write_message(name, field_meta, template_ctx)
      end // TODO(borja): What do we do about anonymous messages?
    end
