use "debug"
use "collections"

class SymbolScopeMap
  let _scopes: Map[String, SymbolScope] = _scopes.create()

  new ref create() => None

  fun apply(name: String): (SymbolScope box | None) =>
    try
      _scopes(name)?
    else
      None
    end

  fun ref update(name: String, value: SymbolScope) =>
    _scopes(name) = value

class SymbolScope
  let _level_prefix: String
  let _parent: (SymbolScope | None)
  let _definitions: Map[String, String] = _definitions.create()

  new create(
    scope_prefix': String = "",
    parent': (SymbolScope | None) = None
  ) =>
    _parent = parent'
    _level_prefix = scope_prefix'

  fun apply(name: String): String ? =>
    try
      _definitions(name)?
    else
      (_parent as this->SymbolScope)(name)?
    end

  fun ref update(name: String, value: String) =>
    _definitions(name) = value
    let parent_scoped: String = _level_prefix + "." + name
    match _parent
    | let parent: SymbolScope => parent(parent_scoped) = value
    | None =>
      // We're the top scope, add with level prefix
      _definitions(parent_scoped) = value
    end

  fun ref local_insert(name: String, value: String) =>
    _definitions(name) = value
