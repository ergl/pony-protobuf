use "files"

primitive GenNames
  fun proto_file(path: String): String =>
    Path.normcase(Path.base(path where with_ext = false))

  fun proto_enum(name: String iso): String =>
    name.replace("_", "")
    consume name
