use ".."

primitive CodeGenScopePass
  fun apply(
    descriptor: FileDescriptorProto,
    scope: SymbolScope,
    prefix: String = ""
  ) =>
    _scope_enums(descriptor.enum_type, scope, prefix)
    _scope_messages(descriptor.message_type, scope, prefix)

  fun _scope_enums(
    enums: Array[EnumDescriptorProto],
    scope: SymbolScope,
    prefix: String)
  =>
    for enum in enums.values() do
      try
        let proto_name = enum.name as String
        let local_scope = SymbolScope(proto_name, scope)
        let name = GenNames.proto_enum(proto_name.clone())
        for field in enum.value.values() do
          let proto_field_name = field.name as String
          let field_name = GenNames.proto_enum(proto_field_name.clone())
          let pony_primitive_name: String = prefix + name + field_name
          local_scope(proto_field_name) = pony_primitive_name
          // This should only be in the local scope
          scope.local_insert(proto_field_name, pony_primitive_name)
        end
        // Add it to the parent scope
        scope(proto_name) = prefix + name
      end
    end

  fun _scope_messages(
    messages: Array[DescriptorProto],
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
        _scope_enums(message.enum_type, local_scope, name)
        _scope_messages(message.nested_type, local_scope, name,
          recursion_level + 1)
      end
    end
