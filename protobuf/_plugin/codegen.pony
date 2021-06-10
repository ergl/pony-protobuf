use ".."

primitive CodeGen
  fun recursion_limit(): USize => 100

  fun _build_protoc_version(maybe_version: (Version | None)): String =>
    match maybe_version
    | None => ""
    | let version: Version =>
      let str = recover String.create(6) end
      match version.major
      | None => None
      | let major: I32 => str.>append(major.string()).append(".")
      end
      match version.minor
      | None => None
      | let minor: I32 => str.>append(minor.string()).append(".")
      end
      match version.patch
      | None => None
      | let patch: I32 => str.append(patch.string())
      end
      match version.suffix
      | let suffix: String if suffix.size() > 0 =>
        str.>append(".").append(suffix)
      else
        None
      end
      consume str
    end

  fun apply(request: CodeGeneratorRequest): CodeGeneratorResponse =>
    let protoc_version_str = _build_protoc_version(request.compiler_version)
    let resp: CodeGeneratorResponse = CodeGeneratorResponse

    resp.supported_features = U64(0)
    resp.file =
      Array[CodeGeneratorResponseFile](request.file_to_generate.size())

    try
      let template_ctx = GenTemplate.create()?
      var dependencies = request.proto_file
      for file_name in request.file_to_generate.values() do
        let res = _codegen_proto_file(file_name, dependencies, template_ctx,
          protoc_version_str)
        match res
        | let gen: CodeGeneratorResponseFile =>
          resp.file.push(gen)
        | let error_reason: String =>
          resp.error_field = error_reason
          break
        end
      end
    else
      resp.error_field =
        "pony-protobuf encountered an internal error during template parsing"
    end
    resp

  fun _codegen_proto_file(
    file_path: String,
    proto_descriptors: Array[FileDescriptorProto],
    template_ctx: GenTemplate,
    protoc_version: String)
    : (CodeGeneratorResponseFile | String)
  =>
    let response_file: CodeGeneratorResponseFile = CodeGeneratorResponseFile
    let file_name = GenNames.proto_file(file_path)
    response_file.name = file_name + ".pony"

    // Although we should only generate code for `file_path`, we have
    // to inspect the dependencies to resolve any name references.
    var offset: USize = 0
    let global_scope = SymbolScope
    let scope_map = SymbolScopeMap
    scope_map(".") = global_scope
    while proto_descriptors.size() > 0 do
      try
        let raw_descriptor = proto_descriptors.shift()?

        // Perform preliminary soundness checks, prepare everything for
        // future passes
        let check_result = CodeGenCheckPass(file_name, raw_descriptor)
        match check_result
        | (Error, let error_reason: String) => return error_reason
        | (Ok, let valid_descriptor: ValidFileDescriptorProto) =>
          let local_scope = SymbolScope(valid_descriptor.package, global_scope)
          if valid_descriptor.package == "" then
            scope_map(valid_descriptor.name) = local_scope
          else
            scope_map(valid_descriptor.package) = local_scope
          end
          // TODO(borja): Figure out package situation
          // Although protoc gives us fully qualified names (i.e.,
          // .google.protobuf.FileDescriptorProto), we still need
          // to think about how to expose packages to Pony.
          // Do we build folder hierarchies that mimick the proto packages?
          CodeGenScopePass(valid_descriptor, scope_map, local_scope)
          if file_name == valid_descriptor.name then
            // This isn't a dependency, we reached codegen
            let codegen_result = _codegen_proto_descriptor(protoc_version,
              template_ctx, scope_map, valid_descriptor)
            match codegen_result
            | (Error, let reason: String) =>
              return reason
            | (Ok, let contents: String) =>
              response_file.content = contents
            end
          end
        end
      else
        // Can't happen, we ensured there are still elements in the array
        return "pony-protobuf encountered an internal error"
      end
    end

    response_file

  fun _codegen_proto_descriptor(
    protoc_version: String,
    template_ctx: GenTemplate,
    scope_map: SymbolScopeMap,
    descriptor: ValidFileDescriptorProto)
    : Result[String, String]
  =>
    let writer = CodeGenWriter
    writer.write_header(protoc_version, template_ctx)
    CodeGenEnums(
      writer,
      template_ctx,
      descriptor.enums
    )
    let gen_res = CodeGenMessages(
      writer,
      template_ctx,
      scope_map,
      descriptor.messages
    )
    match gen_res
    | let str: String => (Error, str)
    | None => writer.done()
    end
