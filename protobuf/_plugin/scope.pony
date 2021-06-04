use "debug"
use "collections"

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

  fun apply(name: String): (String | None) =>
    // Debug.err("scope query for " + name )
    try
      let res = _definitions(name)?
      // Debug.err("resulting in " + res)
      res
    else
      // If parent is None this will return None
      try (_parent as this->SymbolScope)(name) end
    end

  fun ref update(name: String, value: String) =>
    // Debug.err("scope insert " + name + ": " + value)
    _definitions(name) = value
    let parent_scoped: String = _level_prefix + "." + name
    match _parent
    | let parent: SymbolScope => parent(parent_scoped) = value
    | None =>
      // We're the top scope, add with level prefix
      // Debug.err("scope insert " + parent_scoped + ": " + value)
      _definitions(parent_scoped) = value
    end

  fun ref local_insert(name: String, value: String) =>
    // Debug.err("local scope insert " + name + ": " + value)
    _definitions(name) = value
