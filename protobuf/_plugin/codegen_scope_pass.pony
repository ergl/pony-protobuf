use ".."

primitive CodeGenScopePass
  fun apply(
    descriptor: ValidFileDescriptorProto,
    scope_map: SymbolScopeMap,
    scope: SymbolScope,
    prefix: String = ""
  ) =>
    _scope_enums(descriptor.enums, scope, prefix)
    _scope_messages(descriptor.messages, scope_map, scope, prefix)

  fun _scope_enums(
    enums: Array[ValidEnumDescriptorProto] val,
    scope: SymbolScope,
    prefix: String)
  =>
    for enum in enums.values() do
      let enum_name = GenNames.top_level_name(enum.name.clone(), prefix)
      // This is an artifial scope, we're not interested in finding it
      // later, but we want the prefixing capabilities when adding to it,
      // such that the changes are propagated upwards as we append
      // the prefixes.
      let local_scope = SymbolScope(enum.name, scope)
      for (field_name, field_number) in enum.values.values() do
        let enum_field_name = GenNames.top_level_name(
          field_name.clone(),
          enum_name
        )
        // Enums have weird scoping rules. If we have the following:
        //
        // enum Enum {
        //  FOO = 0;
        //  BAR = 1;
        //  BAZ = 2;
        // }
        //
        // Then any sibling type (and its children) of Enum can refer to FOO,
        // instead of Enum.FOO (although that's also visible)
        // This means that enums don't have their own scope, but instead
        // leak their contents outside of the type. To prevent scope
        // pollution to parents of the enum, we insert the raw field
        // name locally to this scope only, but we allow the fully-qualified
        // name to propagate upwards.
        //
        // That is, this line will add "FOO" to the local scope, and will be
        // propagated upwards as "Enum.FOO", and the next one will add
        // "FOO" to the parent scope, but will not allow us to refer to the
        // enum field as "Parent.FOO", since that's not correct.
        local_scope(field_name) = enum_field_name
        scope.local_insert(field_name, enum_field_name)
      end
      // Only let the fully-qualified scope name be visible to outer scopes
      scope(enum.name) = enum_name
    end

  fun _scope_messages(
    messages: Array[ValidDescriptorProto] val,
    scope_map: SymbolScopeMap,
    outer_scope: SymbolScope,
    prefix: String)
  =>
    for message in messages.values() do
      let message_name = GenNames.top_level_name(
        message.name.clone(), prefix
      )
      outer_scope(message.name) = message_name

      let local_scope = SymbolScope(message.name, outer_scope)
      scope_map(message_name) = local_scope
      _scope_enums(message.nested_enums, local_scope, message_name)
      _scope_messages(message.nested_messages, scope_map, local_scope,
        message_name)
    end
