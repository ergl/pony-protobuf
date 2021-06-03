primitive ZigZag
  fun encode_32(n: I32): U32 =>
    ((n << 1) xor (n >> 31)).u32()

  fun encode_64(n: I64): U64 =>
    ((n << 1) xor (n >> 63)).u64()

  fun decode_32(n: U32): I32 =>
    ((n >> 1) xor (n and 1).neg()).i32()

  fun decode_64(n: U64): I64 =>
    ((n >> 1) xor (n and 1).neg()).i64()
