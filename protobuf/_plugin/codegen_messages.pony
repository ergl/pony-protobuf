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
        let message_name = GenNames.top_level_name(proto_name.clone(), prefix)

        CodeGenEnums(writer, template_ctx, message.enum_type, message_name)
        CodeGenMessages(writer, template_ctx, scope_map, message.nested_type,
          message_name, recursion_level + 1)

        // We did a scope pass first, this shouldn't fail
        // Have box capability since we don't want children to
        // modify the scope.
        let my_scope = scope_map(message_name) as SymbolScope box
        let field_meta =
          CodeGenFields(writer, template_ctx, my_scope, message.field)
        writer.write_message(message_name, field_meta, template_ctx)
      end // TODO(borja): What do we do about anonymous messages?
    end
