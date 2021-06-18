use ".."

primitive CodeGenMessages
  fun apply(
    writer: CodeGenWriter ref,
    template_ctx: GenTemplate,
    scope_map: SymbolScopeMap,
    messages: Array[ValidDescriptorProto] box,
    prefix: String = "")
    : (String | None)
  =>
    for message in messages.values() do
      let message_name = GenNames.top_level_name(message.name.clone(), prefix)
      CodeGenEnums(writer, template_ctx, message.nested_enums, message_name)
      let inner_result = CodeGenMessages(writer, template_ctx, scope_map,
        message.nested_messages, message_name)
      match inner_result
      | let error_reason: String => return error_reason
      | None =>
        try
          // We did a scope pass first, this shouldn't fail
          // Have box capability since we don't want children to
          // modify the scope.
          let my_scope = scope_map(message_name) as SymbolScope box
          let field_meta_result = CodeGenFields(writer, template_ctx, my_scope,
            message.fields)
          match field_meta_result
          | (Error, let error_reason: String) =>
            return error_reason
          | (Ok, let field_meta: Array[FieldMeta] val) =>
            writer.write_message(message_name, field_meta, template_ctx)
          end
        else
          return "pony-protobuf internal error: can't find symbol scope for " +
            message_name
        end
      end
    end
