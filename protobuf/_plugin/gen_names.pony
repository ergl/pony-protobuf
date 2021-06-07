use "files"

primitive GenNames
  fun proto_file(path: String): String =>
    Path.normcase(Path.base(path where with_ext = false))

  fun proto_enum(name: String iso): String =>
    name.replace("_", "")
    consume name

  fun enum_builder(enum_pony_name: String): String =>
    enum_pony_name + "Builder"

  fun message_field(name: String): String =>
    if _is_keyword(name) then
      return name + "_field"
    end
    name

  fun _is_keyword(name: String): Bool =>
    // Taken from https://tutorial.ponylang.io/appendices/keywords.html
    match name
    | "actor" => true
    | "as" => true
    | "be" => true
    | "box" => true
    | "break" => true
    | "class" => true
    | "compile_error" => true
    | "compile_intrinsic" => true
    | "continue" => true
    | "consume" => true
    | "digestof" => true
    | "do" => true
    | "else" => true
    | "elseif" => true
    | "embed" => true
    | "end" => true
    | "error" => true
    | "for" => true
    | "fun" => true
    | "if" => true
    | "ifdef" => true
    | "iftype" => true
    | "in" => true
    | "interface" => true
    | "is" => true
    | "isnt" => true
    | "iso" => true
    | "let" => true
    | "match" => true
    | "new" => true
    | "not" => true
    | "object" => true
    | "primitive" => true
    | "recover" => true
    | "ref" => true
    | "repeat" => true
    | "return" => true
    | "tag" => true
    | "then" => true
    | "this" => true
    | "trait" => true
    | "trn" => true
    | "try" => true
    | "type" => true
    | "until" => true
    | "use" => true
    | "var" => true
    | "val" => true
    | "where" => true
    | "while" => true
    | "with" => true
    else
      false
    end
