use ".."
use "buffered"

actor Main
  let _env: Env
  let _reader: Reader = Reader
  var _codegen_request: CodeGeneratorRequest = CodeGeneratorRequest

  new create(env: Env) =>
    _env = env
    let chunk_size: USize = 1024
    env.input(
      object iso is InputNotify
        let _main: Main = this
        fun ref apply(data: Array[U8] iso^) =>
          let size = data.size()
          _main.recv(consume data)
          if size < chunk_size then
            _main.recv_done()
          end
      end,
      chunk_size
    )

  be recv(data: Array[U8] iso^) =>
    _reader.append(consume data)

  be recv_done() =>
    try
      _codegen_request.parse_from_stream(_reader)?
      _reader.clear()
      let resp = CodeGen(_codegen_request)
      let writer = ProtoWriter
      resp.write_to_stream(writer)
      _env.out.writev(writer.done())
      _env.exitcode(0)
    else
      _env.err.print("Error parsing code gen request bytes")
      _env.exitcode(1)
    end
