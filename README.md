# pony-protobuf

A protocol buffers library and compiler for Pony.

## Status

`pony-protobuf` is an alpha-level package. Expect API breakage. For now, `pony-protobuf` only supports proto2 files. The generated Pony files have a run-time dependency of this package.

### What works

* Message definitions (also messages in messages).
* Scalar types.
* Importing other files (although namespaces are flat, see point below about packages).
* Nested types.
* The `packed` and `default` options for fields (but not for `bytes`, see [#2](https://github.com/ergl/pony-protobuf/issues/2)).
* Skipping over unknown message fields.
* Merging of messages (simply call `parse_from_stream` multiple times).

### What doesn't work (yet)

- [ ] `oneof` fields
- [ ] `map<_,_>` syntax
- [ ] "proto3" syntax
- [ ] Message extensions.
- [ ] Generating descriptor metadata
- [ ] Discards any unknown types when parsing.
- [ ] groups (proto2). Although deprecated, the current library doesn't know how to handle these. In the future it will ignore any groups when marshalling.
- [ ] Default definitions for `byte` fields.
- [ ] The `allow_alias` enum option.
- [ ] JSON serialization.
- [ ] Service definitions.
- [ ] Proper package namespaces. Importing packages is supported, but the generated code assumes that the types will be present in the same Pony package.

## Installation

* Install [corral](https://github.com/ponylang/corral)
* `corral add github.com/ergl/pony-protobuf.git --version 0.1.0`
* `corral fetch` to fetch your dependencies
* `use "protobuf"` to include this package
* `corral run -- ponyc` to compile your application

Nit: the above will include the `protobuf` library in your application. To use the compiler, you will need to build from source (a binary download / homebrew package might be nice).

## Compiler Usage

The compiler is implemented as a `protoc` plugin. If you don't have `protoc` installed, see the [install notes](https://github.com/protocolbuffers/protobuf#protocol-compiler-installation).

If you have downloaded the repo, run `make plugin`. This will generate a `protoc-gen-pony` file in `build/release` that you can use with `protoc`, as such:

```
protoc --pony_out=<out_dir> --plugin=build/release/protoc-gen-pony path/to/proto/file.proto
```

For more `protoc` options, see `protoc --help`. If you have `protoc-gen-pony` in your `PATH`, you can omit the `--plugin` flag.

## Examples

Take a peek at the [examples](https://github.com/ergl/pony-protobuf/tree/main/examples) directory. It contains auto-generated Pony files. In general, the generated code looks like this:

```pony
use "protobuf"

// <snip>

class AddressBook is ProtoMessage
  var person: Array[Person] = Array[Person]

  fun compute_size(): U32 =>
    var size: U32 = 0
    for v in person.values() do
      size = size + FieldSize.inner_message(1, v)
    end
    size

  fun ref parse_from_stream(reader: ProtoReader) ? =>
    while reader.size() > 0 do
      match reader.read_field_tag()?
      | (1, DelimitedField) =>
        let v: Person = Person
        v.parse_from_stream(reader.pop_embed()?)?
        person.push(v)
      | (_, let typ: TagKind) => reader.skip_field(typ)?
      end
    end

  fun write_to_stream(writer: ProtoWriter) =>
    for v in person.values() do
      writer.write_tag(1, DelimitedField)
      // TODO: Don't recompute size here, it's wasteful
      writer.write_varint[U32](v.compute_size())
      v.write_to_stream(writer)
    end

  fun is_initialized(): Bool =>
    for v in person.values() do
      if not v.is_initialized() then
        return false
      end
    end
    true
```

## Mapping of protocol buffer types to Pony

| Protobuf type | Pony type |
| :---: | :---: |
| `bool` | `Bool` |
| `double` | `F32` |
| `float` | `F64` |
| `int32`, `sint32`, `fixed32` | `I32` |
| `int64`, `sint64`, `fixed64` | `I64` |
| `uint32` | `U32` |
| `uint64` | `U64` |
| `string` | `String val` |
| `bytes` | `Array[U8] ref` |
| `enum` | Primitives (see below) |
| `map<_,_>` | Not supported (yet) |
| `oneof` | Not supported (yet) |
| `groups` | Not supported (no plans) |

Repeated fields are represented as `Array[T] ref`, and optional types are represented as `(T | None)`. Required types (proto2) are also represented as `(T | None)`, to discern between uninitialized types and default values. Users are encouraged to call `Message.is_initialized()` to ensure that the message contains all required types.

### Enums

Since Pony lacks the concept of C-style enums, `pony-protobuf` opts to represent them as primitive types, one per enum value. A type alias is also generated to represent the valid values, along with an utility primitive to translate between the numeric representation and the primitive type. Here's an example from `addressbook.pony`:

```proto
enum PhoneType {
    MOBILE = 0;
    HOME = 1;
    WORK = 2;
}
```

```pony
primitive PhoneTypeMOBILE is ProtoEnumValue
  fun as_i32(): I32 => 0
  fun string(): String => "PhoneTypeMOBILE"

primitive PhoneTypeHOME is ProtoEnumValue
  fun as_i32(): I32 => 1
  fun string(): String => "PhoneTypeHOME"

primitive PhoneTypeWORK is ProtoEnumValue
  fun as_i32(): I32 => 2
  fun string(): String => "PhoneTypeWORK"

type PhoneType is (
  PhoneTypeMOBILE
  | PhoneTypeHOME
  | PhoneTypeWORK
)

primitive PhoneTypeBuilder is ProtoEnum
  fun from_i32(value: I32): (PhoneType | None) =>
    match value
    | 0 => PhoneTypeMOBILE
    | 1 => PhoneTypeHOME
    | 2 => PhoneTypeWORK
    else
      None
    end
```

Another option to represent enum types would be to have a single primitive, with one function per enum field, like so:

```pony
primitive PhoneType
  fun field_MOBILE(): I32 => 0
  fun field_HOME(): I32 => 1
  fun field_WORK(): I32 => 2
```

This option is shorter, doesn't pollute the namespace, but doesn't offer any type-checking affordances to the user. That's the reason I opted for the more verbose alternative. In the future, I might change this.

## API Documentation

[API documentation](https://ergl.github.io/pony-protobuf/)

## Performance

Baby steps.
