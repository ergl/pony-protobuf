use "format"
use "buffered"

actor Main
  new create(env: Env) =>
    try
      let buffer0 = _AddressBookBytes()
      let book0 = create_addressbook(buffer0) ?
      env.out.print("OG book:")
      walk_addressbook(env.out, book0)

      env.out.print("Reparsed book:")
      let buffer1 = bytes_for_book(book0)
      let book1 = create_addressbook(buffer1) ?
      walk_addressbook(env.out, book1)
      env.out.print("Deterministic?: " + array_eq(buffer0, buffer1).string())

      env.out.print("Reparsed book (again):")
      let buffer2 = bytes_for_book(book1)
      let book2 = create_addressbook(buffer2) ?
      walk_addressbook(env.out, book2)
      env.out.print("Deterministic?: " + array_eq(buffer1, buffer2).string())

      env.out.print("\nOG Buffer:\n")
      print_buffer_erl(env.out, buffer0)
      env.out.print("\nReparsed Buffer:\n")
      print_buffer_erl(env.out, buffer1)
      env.out.print("\nReparsed Buffer (again):\n")
      print_buffer_erl(env.out, buffer2)
    else
      env.err.print("Error parsing address book bytes")
    end

  fun create_addressbook(bytes: Array[U8] val): AddressBook ? =>
    let book: AddressBook = AddressBook
    book.parse_from_stream(Reader .> append(bytes)) ?
    book

  fun bytes_for_book(book: AddressBook): Array[U8] val =>
    let w: Writer = Writer
    book.write_to_stream(w)
    squash(w.done())

  fun squash(buffer: Array[ByteSeq] iso^): Array[U8] val^ =>
    recover
      let b = Array[U8](buffer.size())
      for elt in buffer.values() do
        b.append(elt)
      end
      consume b
    end

  fun array_eq(l: Array[U8] val, r: Array[U8] val): Bool =>
    if l.size() != r.size() then return false end
    for (idx, v) in l.pairs() do
      try
        if v != r(idx)? then
          return false
        end
      else
        return false
      end
    end
    true

  fun print_buffer(out: OutStream, buffer: Array[U8] val, per_line: U32 = 10) =>
    let descr = recover String.create(buffer.size()) end
    var line_n: U32 = 0
    var total_idx: USize = 0
    for v in buffer.values() do
      descr.append(Format.int[U8](v where fmt=FormatHex))
      if (line_n == (per_line - 1)) or (total_idx == (buffer.size() - 1)) then
        descr.append("\n")
      else
        descr.append(";")
      end
      line_n = (line_n + 1) % per_line
      total_idx = total_idx + 1
    end
    out.print(consume descr)

  fun print_buffer_erl(out: OutStream, buffer: Array[U8] val) =>
    let descr = recover String.create(buffer.size() + 4).>append("<<") end
    var total_idx: USize = 0
    for v in buffer.values() do
      descr.append("16#" + Format.int[U8](v where fmt=FormatHexBare))
      if not (total_idx == (buffer.size() - 1)) then
        descr.append(",")
      end
      total_idx = total_idx + 1
    end
    descr.append(">>")
    out.print(consume descr)

  fun walk_addressbook(out: OutStream, book: AddressBook) =>
    try
      let people: Array[Person] = book.person
      let descr = recover String .> append("AddressBook{person=[\n") end
      for p in people.values() do
        descr.append("\tPerson{")
        if p.id isnt None then
          descr.append("id=\"" + (p.id as I32).string() + "\"")
        end
        if p.name isnt None then
          descr.append(", name=\"" + (p.name as String) + "\"")
        end
        if p.email isnt None then
          descr.append(", email=\"" + (p.email as String) + "\"")
        end
        let phones: Array[PersonPhoneNumber] = p.phone
        descr.append(", numbers=[")
        var size = phones.size()
        var idx: USize = 0
        for ph in phones.values() do
          if ph.number isnt None then
            descr.append("\"" + (ph.number as String) + "\"")
            if idx < (size - 1) then
              descr.append(", ")
            end
          end
          idx = idx + 1
        end
        descr.append("]}\n")
      end
      descr.append("]}")
      out.print(consume descr)
    end

primitive _AddressBookBytes
  fun apply(): Array[U8] val =>
    """
    These bytes were generated by gpb_compile version 4.12.0 (erlang).

    It contains the following definiton:

    ```erlang
    Phones = [
        #{number => "555-0100"},
        #{number => "555-0101", type => 'MOBILE'},
        #{number => "555-0102", type => 'HOME'},
        #{number => "555-0103", type => 'WORK'}
    ].
    People = [
        #{id => 0, name => ""},
        #{id => -1, name => ""},
        #{id => 1, name => "1", email => "1@example.org", phone => []},
        #{id => 2, name => "2", email => "2@example.org", phone => [hd(Phones)]},
        #{id => 3, name => "3", email => "3@example.org", phone => Phones}
    ].
    AddressBook = #{person => People}.
    ```
    """
    [0x0A;0x04;0x0A;0x00;0x10;0x00;0x0A;0x0D;0x0A;0x00;0x10
     0xFF;0xFF;0xFF;0xFF;0xFF;0xFF;0xFF;0xFF;0xFF;0x01;0x0A
     0x14;0x0A;0x01;0x31;0x10;0x01;0x1A;0x0D;0x31;0x40;0x65
     0x78;0x61;0x6D;0x70;0x6C;0x65;0x2E;0x6F;0x72;0x67;0x0A
     0x20;0x0A;0x01;0x32;0x10;0x02;0x1A;0x0D;0x32;0x40;0x65
     0x78;0x61;0x6D;0x70;0x6C;0x65;0x2E;0x6F;0x72;0x67;0x22
     0x0A;0x0A;0x08;0x35;0x35;0x35;0x2D;0x30;0x31;0x30;0x30
     0x0A;0x4A;0x0A;0x01;0x33;0x10;0x03;0x1A;0x0D;0x33;0x40
     0x65;0x78;0x61;0x6D;0x70;0x6C;0x65;0x2E;0x6F;0x72;0x67
     0x22;0x0A;0x0A;0x08;0x35;0x35;0x35;0x2D;0x30;0x31;0x30
     0x30;0x22;0x0C;0x0A;0x08;0x35;0x35;0x35;0x2D;0x30;0x31
     0x30;0x31;0x10;0x00;0x22;0x0C;0x0A;0x08;0x35;0x35;0x35
     0x2D;0x30;0x31;0x30;0x32;0x10;0x01;0x22;0x0C;0x0A;0x08
     0x35;0x35;0x35;0x2D;0x30;0x31;0x30;0x33;0x10;0x02]
