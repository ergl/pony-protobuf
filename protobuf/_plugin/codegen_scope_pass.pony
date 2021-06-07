use ".."

primitive CodeGenScopePass
  fun apply(
    descriptor: FileDescriptorProto,
    scope_map: SymbolScopeMap,
    scope: SymbolScope,
    prefix: String = ""
  ) =>
    _scope_enums(descriptor.enum_type, scope, prefix)
    _scope_messages(descriptor.message_type, scope_map, scope, prefix)

  fun _scope_enums(
    enums: Array[EnumDescriptorProto],
    scope: SymbolScope,
    prefix: String)
  =>
    for enum in enums.values() do
      try
        let proto_name = enum.name as String
        let name = GenNames.proto_enum(proto_name.clone())
        // This is an artifial scope, we're not interested in finding it
        // later, but we want the prefixing capabilities when adding to it,
        // such that the changes are propagated upwards as we append
        // the prefixes.
        let local_scope = SymbolScope(proto_name, scope)
        for field in enum.value.values() do
          let proto_field_name = field.name as String
          let field_name = GenNames.proto_enum(proto_field_name.clone())
          let pony_primitive_name: String = prefix + name + field_name
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
          local_scope(proto_field_name) = pony_primitive_name
          scope.local_insert(proto_field_name, pony_primitive_name)
        end
        // Only let the fully-qualified scope name be visible to outer scopes
        scope(proto_name) = prefix + name
      end
    end

  fun _scope_messages(
    messages: Array[DescriptorProto],
    scope_map: SymbolScopeMap,
    outer_scope: SymbolScope,
    prefix: String,
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
        outer_scope(proto_name) = name

        let local_scope = SymbolScope(proto_name, outer_scope)
        scope_map(name) = local_scope
        _scope_enums(message.enum_type, local_scope, name)
        _scope_messages(message.nested_type, scope_map, local_scope, name,
          recursion_level + 1)
      end
    end
