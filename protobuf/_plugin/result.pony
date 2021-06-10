primitive Ok
primitive Error
type Result[L, R] is ((Ok, L) | (Error, R))

primitive Results[L, R]
  fun ok(l: L): Result[L, R] => (Ok, consume l)
  fun to_error(r: R): Result[L, R] => (Error, consume r)
  
  fun force_ok(e: Result[L, R]): L^ ? =>
    match e
    | (Ok, let l: L) => consume l
    else
      error
    end
    
  fun force_error(res: Result[L, R]): R^ ? =>
    match res
    | (Error, let r: R) => consume r
    else
      error
    end

  fun lmap[T = L](
    res: Result[L, R],
    op: {(L): T^})
    : Result[T^, R]
  =>
    match res
    | (Ok, let l: L) => (Ok, op.apply(consume l))
    | (Error, let r: R) => (Error, consume r)
    end

  fun rmap[T = R](
    res: Result[L, R],
    op: {(R): T^})
    : Result[L, T^]
  =>
    match res
    | (Ok, let l: L) => (Ok, consume l)
    | (Error, let r: R) => (Error, op.apply(consume r))
    end

  fun flat_lmap[T = L](
    res: Result[L, R],
    op: {(L):  Result[T^, R]})
    : Result[T^, R]
  =>
    match res
    | (Error, let r: R) => (Error, r)
    | (Ok, let l: L) => op.apply(consume l)
    end

  fun flat_rmap[T = R](
    res: Result[L, R],
    op: {(R):  Result[L, T^]})
    : Result[L, T^]
  =>
    match res
    | (Ok, let l: L) => (Ok, l)
    | (Error, let r: R) => op.apply(consume r)
    end

  fun apply(
    res: Result[L, R],
    op_ok: {(L)},
    op_error: {(R)} = {(_) => None})
  =>
    match res
    | (Ok, let l: L) => op_ok(consume l)
    | (Error, let r: R) => op_error(consume r)
    end
