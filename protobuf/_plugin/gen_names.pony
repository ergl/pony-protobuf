use "files"

primitive GenNames
  fun proto_file(path: String): String =>
    Path.normcase(Path.base(path where with_ext = false))

  fun top_level_name(name: String iso, prefix: String = ""): String =>
    name.replace("_", "")
    let safe_name: String = _upper_range(consume name, 0, 0)
    // We assume the prefix is already correct
    prefix + safe_name

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

  fun _upper_range(
    str: String iso,
    from: USize = 0,
    to: USize = -1)
    : String iso^
  =>
    let to_offset = str.size().min(to)
    if (from == 0) and (to_offset == str.size()) then
      str.upper_in_place()
      return str
    end

    var idx: USize = 0
    let ret_str = recover String.create(str.size()) end
    for rune in (consume str).runes() do
      if (idx >= from) and (idx <= to) then
        if (rune >= 0x61) and (rune <= 0x7A) then
          ret_str.push_utf32(rune - 0x20)
        else
          ret_str.push_utf32(rune)
        end
      else
        ret_str.push_utf32(rune)
      end
      idx = idx + 1
    end
    consume ret_str
