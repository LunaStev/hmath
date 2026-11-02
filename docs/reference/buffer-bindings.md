# Buffer API

`from hmath import buffer` exposes the actual `HMath.API.Buffer` containers and operations. C includes `hmath_buffer.h`; all objects use the shared [Value ownership contract](values.md). Outputs own one reference and remain untouched on failure. Release every owner with `close()`/`hmath_value_release`.

Boxed elements remain exact generic values. The distinction between original lazy and WHNF-strict constructors is preserved; foreign values themselves are already materialized, so these constructors do not synthesize Haskell bottoms. Unboxed storage is Double, with no added NaN/Inf checks. Every freeze/thaw conversion copies.

## Mutable scopes and storage

`run_st_buffer(boxed, callback)` lends an actual STBuffer to a synchronous callback. Use `thaw_st_buffer(region, boxed)` to select that same ST state region explicitly. Scoped handles cannot execute on another thread or after the callback; immutable frozen values and ordinary callback results remain owned.

`IOBuffer(n, initial, dtype=...)` / `new_io_buffer` allocate original pinned, synchronized IO storage. Standard Float/Double, Complex Float/Double, signed/unsigned bounded and native integers, Bool and Char have original Storable instances. Exact Integer/Rational and Dual do not. Python integer initial values default to native `intp`; use explicit dtype to select width. Boxed constructors accept dtype to preserve that element witness, and `thaw_io_buffer(boxed, dtype=...)` performs the explicit marshal conversion before the original copying thaw. Empty storage requires dtype or a typed prototype.

`with_io_buffer(io, callback)` lends `(BorrowedPointer, count)` while holding the original lock and ForeignPtr. `pointer.read/write`, `.layout` and `.address` are valid only in that callback and thread. Never retain the raw address or reenter locking operations on the same IOBuffer; same-thread reentry returns BUSY. Other threads use the original synchronized operations. Callback errors release the pointer borrow and lock before propagating the original exception. Bool/Char layouts are queried from their actual Storable instance, not assumed to match C bool/char. `.layout` is `(dtype, size, alignment, length)`; Bool uses dtype16 and Char17.

```python
from hmath import buffer

with buffer.Boxed([1, 2, 3]) as source:
    def change(region):
        region.write(1, 8)
        return region.freeze()
    with buffer.run_st_buffer(source, change) as frozen:
        assert frozen.values == [1, 8, 3]

with buffer.IOBuffer(3, 0.0, dtype="float32") as storage:
    storage.with_pointer(lambda pointer, count: pointer.write(count - 1, 2.0))
    assert storage.read(2) == 2.0
```

## `buffer.lazy_boxed`

Finite lists only. The list spine is consumed; elements remain lazy.

```haskell
[a] -> Boxed a
```

```text
lazy_boxed(values, *, dtype=None)
```

```c
hmath_status hmath_buffer_lazy_boxed(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `buffer.strict_boxed`

 Construct a boxed container from a finite list, forcing every element to weak head normal form (not deep normal form). Preserve order; element evaluation exceptions propagate. 

```haskell
[a] -> Boxed a
```

```text
strict_boxed(values, *, dtype=None)
```

```c
hmath_status hmath_buffer_strict_boxed(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `buffer.boxed_values`

 Return boxed elements in zero-based array order as a list. Elements retain the laziness/strictness chosen at construction. 

```haskell
Boxed a -> [a]
```

```text
boxed_values(value)
```

```c
hmath_status hmath_buffer_boxed_values(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `buffer.boxed_length`

Return the number of elements in a boxed container; empty storage has length zero.

```haskell
Boxed a -> Int
```

```text
boxed_length(value)
```

```c
hmath_status hmath_buffer_boxed_length(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `buffer.map_strict`

 Given element transformation then boxed input, return a boxed result with every mapped element forced to WHNF. Preserve length/order; evaluation exceptions propagate. 

```haskell
(a -> b) -> Boxed a -> Boxed b
```

```text
map_strict(function, value)
```

```c
hmath_status hmath_buffer_map_strict(hmath_context *context, const hmath_value *function, const hmath_value *value, hmath_value **out);
```

## `buffer.unboxed_double`

 Copy a finite Double list into an immutable unboxed array in list order. Values are evaluated by unboxing; no finiteness validation is added. 

```haskell
[Double] -> UnboxedDouble
```

```text
unboxed_double(values)
```

```c
hmath_status hmath_buffer_unboxed_double(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `buffer.unboxed_values`

Copy/expand unboxed Doubles into a list in array order, preserving length.

```haskell
UnboxedDouble -> [Double]
```

```text
unboxed_values(value)
```

```c
hmath_status hmath_buffer_unboxed_values(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `buffer.run_st_buffer`

The rank-2 state parameter prevents a mutable region from escaping.

```haskell
Boxed a -> (forall s. STBuffer s a -> ST s b) -> b
```

```text
run_st_buffer(value, callback)
```

```c
hmath_status hmath_buffer_run_st_buffer(hmath_context *context, const hmath_value *value, const hmath_value *callback, hmath_value **out);
```

## `buffer.thaw_st_buffer`

 Copy immutable boxed values into new mutable storage in the current ST region. The input remains unchanged; storage cannot escape the region. 

```haskell
Boxed a -> ST s (STBuffer s a)
```

```text
thaw_st_buffer(region, value)
```

```c
hmath_status hmath_buffer_thaw_st_buffer(hmath_context *context, const hmath_value *region, const hmath_value *value, hmath_value **out);
```

## `buffer.freeze_st_buffer`

 Copy current mutable ST values into an immutable boxed container; later writes do not modify the frozen result. 

```haskell
STBuffer s a -> ST s (Boxed a)
```

```text
freeze_st_buffer(value)
```

```c
hmath_status hmath_buffer_freeze_st_buffer(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `buffer.read_st_buffer`

 Given ST buffer then zero-based index, read the element. Negative/out-of-range indices return Left InvalidArgument within ST, rather than indexing the array. 

```haskell
STBuffer s a -> Int -> ST s (Either MathError a)
```

```text
read_st_buffer(value, index)
```

```c
hmath_status hmath_buffer_read_st_buffer(hmath_context *context, const hmath_value *value, const hmath_value *index, hmath_value **out);
```

## `buffer.write_st_buffer`

 Given ST buffer, zero-based index, then value, update one element and return Right (). Invalid index returns Left InvalidArgument without writing. 

```haskell
STBuffer s a -> Int -> a -> ST s (Either MathError ())
```

```text
write_st_buffer(value, index, element)
```

```c
hmath_status hmath_buffer_write_st_buffer(hmath_context *context, const hmath_value *value, const hmath_value *index, const hmath_value *element, hmath_value **out);
```

## `buffer.new_io_buffer`

 Allocation overflow is checked before allocation. Allocation/OS exceptions remain IO exceptions; MathError describes input and numeric contract failures. 

```haskell
Storable a => Int -> a -> IO (Either MathError (IOBuffer a))
```

```text
new_io_buffer(count, initial, *, dtype=None)
```

```c
hmath_status hmath_buffer_new_io_buffer(hmath_context *context, const hmath_value *count, const hmath_value *initial, hmath_value **out);
```

## `buffer.thaw_io_buffer`

 Copy boxed Storable values into new pinned IO storage. Return Left InvalidArgument for byte-size overflow; allocation/OS/evaluation failures remain IO exceptions. 

```haskell
Storable a => Boxed a -> IO (Either MathError (IOBuffer a))
```

```text
thaw_io_buffer(value, *, dtype=None, prototype=None)
```

```c
hmath_status hmath_buffer_thaw_io_buffer(hmath_context *context, const hmath_value *prototype, const hmath_value *value, hmath_value **out);
```

## `buffer.freeze_io_buffer`

 Lock and copy pinned IO values to a strict immutable boxed container. The result is independent of later buffer writes; allocation/IO exceptions propagate. 

```haskell
Storable a => IOBuffer a -> IO (Boxed a)
```

```text
freeze_io_buffer(value)
```

```c
hmath_status hmath_buffer_freeze_io_buffer(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `buffer.io_buffer_length`

 Return the immutable element count of a pinned IO buffer. This query neither borrows its pointer nor takes ownership. 

```haskell
IOBuffer a -> Int
```

```text
io_buffer_length(value)
```

```c
hmath_status hmath_buffer_io_buffer_length(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `buffer.read_io_buffer`

 Given IO buffer then zero-based index, read under the buffer lock. Invalid index returns Left InvalidArgument; IO exceptions propagate. 

```haskell
Storable a => IOBuffer a -> Int -> IO (Either MathError a)
```

```text
read_io_buffer(value, index)
```

```c
hmath_status hmath_buffer_read_io_buffer(hmath_context *context, const hmath_value *value, const hmath_value *index, hmath_value **out);
```

## `buffer.write_io_buffer`

 Given IO buffer, zero-based index, then value, write under its lock and return Right (). Invalid index returns Left InvalidArgument without modification. 

```haskell
Storable a => IOBuffer a -> Int -> a -> IO (Either MathError ())
```

```text
write_io_buffer(value, index, element)
```

```c
hmath_status hmath_buffer_write_io_buffer(hmath_context *context, const hmath_value *value, const hmath_value *index, const hmath_value *element, hmath_value **out);
```

## `buffer.with_io_buffer`

 Given IO buffer then callback, hold its lock and lend a Ptr plus element count for the callback duration. Do not retain the pointer or reenter locking operations on this same buffer. Callback exceptions propagate while releasing the lock. 

```haskell
Storable a => IOBuffer a -> (Ptr a -> Int -> IO b) -> IO b
```

```text
with_io_buffer(value, callback)
```

```c
hmath_status hmath_buffer_with_io_buffer(hmath_context *context, const hmath_value *value, const hmath_value *callback, hmath_value **out);
```

## `buffer.unboxed_to_boxed`

 Convert unboxed Double storage to a new strict boxed container, preserving order and values. 

```haskell
UnboxedDouble -> Boxed Double
```

```text
unboxed_to_boxed(value)
```

```c
hmath_status hmath_buffer_unboxed_to_boxed(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `buffer.boxed_to_unboxed`

 Convert boxed Double values to a new unboxed array, forcing values during copying. Preserve order and length. 

```haskell
Boxed Double -> UnboxedDouble
```

```text
boxed_to_unboxed(value)
```

```c
hmath_status hmath_buffer_boxed_to_unboxed(hmath_context *context, const hmath_value *value, hmath_value **out);
```

