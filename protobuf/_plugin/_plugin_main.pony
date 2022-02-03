use ".."

use files = "files"

class iso InputReader is InputNotify
  let _main: Main
  let _chunk_size: USize
  var _reader: ProtoReader iso = recover ProtoReader end

  new iso create(main: Main, chunk_size: USize) =>
    _main = main
    _chunk_size = chunk_size

  fun ref apply(data: Array[U8] iso^) =>
    let size = data.size()
    _reader.append(consume data)
    if size < _chunk_size then
      let to_send = _reader = recover ProtoReader end
      _main.start_codegen(consume to_send)
    end

actor Main
  let _repo_url: String = "https://github.com/ergl/pony-protobuf"
  let _program_name: String

  let _env: Env

  new create(env: Env) =>
    _env = env

    _program_name =
      try
        files.Path.base(_env.args(0)?)
      else
        "pony-protobuf"
      end

    if _env.args.size() == 2 then
      try
        let arg = _env.args(1)?
        if (arg == "-v") or (arg == "--version") then
          _env.out.print(_program_name + " " + PluginVersion())
          return
        elseif (arg == "-h") or (arg == "--help") then
          _env.out.print("See " + _repo_url + " for usage information")
          return
        end
      end
    end

    let chunk_size: USize = 1024
    env.input(InputReader(this, chunk_size), chunk_size)

  be start_codegen(reader: ProtoReader iso) =>
    try
      let request = CodeGeneratorRequest
      request.parse_from_stream(consume reader)?
      this.codegen(consume request)
    else
      _env.err.print("pony-protobuf: Error parsing CodeGeneratorRequest bytes")
      _env.exitcode(1)
    end

  be codegen(request: CodeGeneratorRequest iso) =>
    let writer = ProtoWriter
    let response = CodeGen(consume ref request)
    response.write_to_stream(writer)
    _env.out.writev(writer.done())
    // Although the response might have the `error` field set, we should still
    // exit with 0, protoc itself will look at that field, and print it for us
    _env.exitcode(0)
