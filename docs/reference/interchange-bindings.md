# Array interchange

Python uses `from hmath import interchange`; C includes `hmath_interchange.h`. These adapters call the original Haskell array, binary/text/NumPy, compression, streaming and mapped-file functions. Source byte/shape/archive budgets, checksums, metadata, byte order, stride/offset semantics and errors remain unchanged.

Each successful C output owns one [structured value](values.md); inputs are borrowed during the call and failure leaves output pointers untouched. `InterchangeError` uses status13 with its original four-way constructor and full message available through `hmath_last_interchange_error`. Python raises `HMathError` with `interchange_error`. Callbacks may supply the original checked Left by raising `InterchangeError`. Unexpected exceptions abort and are re-raised after cleanup.

ByteString results are owned `Bytes` objects. `bytes(result)` copies; `result.view()` borrows a read-only span retaining an independent reference. C uses `hmath_bytes_data` while retaining the owner. No terminator is implied. Binary/raw preserve IEEE bits; text follows the source policy and does not promise NaN payload preservation. `boxed=True` on scalar/list decoders retains native typed values when Python scalar conversion is undesirable.

Element-polymorphic operations select one original fixed-width instance using a scalar/Boolean prototype in C or `dtype=` in Python. Supported types are Bool8, signed/unsigned8/16/32/64, Float32/64 and Complex64/128. Array dtype and requested result type must match as in Haskell. Matrix/Tensor conversions preserve actual element types; they do not route FP32 through FP64. `get_element` returns the original parser program; `run_decoder` executes the original strict decoder, including trailing-byte checks. `put_element` returns the original Put program and `put_bytes` runs it.

Mapped array access is callback-scoped. A retained mapping capability rejects data reads after scope exit through the original closed-state checks; copied Bytes remain valid. File writes retain the source's IO effects and partial-write behavior. `open_handle`/`close_handle` and seek/tell/flush expose real binary Haskell handles for the original chunked APIs. Handles are shared resources; close them explicitly before releasing their owners.

## `big_endian`

`interchange.big_endian()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.BigEndian`](haskell/HMath-Interchange-Array.md#v:BigEndian). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Endian
```

```c
hmath_status hmath_interchange_value_big_endian(hmath_context *context, hmath_value **out);
```

## `bool8`

`interchange.bool8()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.Bool8`](haskell/HMath-Interchange-Array.md#v:Bool8). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType
```

```c
hmath_status hmath_interchange_value_bool8(hmath_context *context, hmath_value **out);
```

## `c128`

`interchange.c128()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.C128`](haskell/HMath-Interchange-Array.md#v:C128). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType
```

```c
hmath_status hmath_interchange_value_c128(hmath_context *context, hmath_value **out);
```

## `c64`

`interchange.c64()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.C64`](haskell/HMath-Interchange-Array.md#v:C64). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType
```

```c
hmath_status hmath_interchange_value_c64(hmath_context *context, hmath_value **out);
```

## `c_order`

`interchange.c_order()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.COrder`](haskell/HMath-Interchange-Array.md#v:COrder). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Order
```

```c
hmath_status hmath_interchange_value_c_order(hmath_context *context, hmath_value **out);
```

## `f32`

`interchange.f32()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.F32`](haskell/HMath-Interchange-Array.md#v:F32). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType
```

```c
hmath_status hmath_interchange_value_f32(hmath_context *context, hmath_value **out);
```

## `f64`

`interchange.f64()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.F64`](haskell/HMath-Interchange-Array.md#v:F64). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType
```

```c
hmath_status hmath_interchange_value_f64(hmath_context *context, hmath_value **out);
```

## `f_order`

`interchange.f_order()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.FOrder`](haskell/HMath-Interchange-Array.md#v:FOrder). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Order
```

```c
hmath_status hmath_interchange_value_f_order(hmath_context *context, hmath_value **out);
```

## `i16`

`interchange.i16()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.I16`](haskell/HMath-Interchange-Array.md#v:I16). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType
```

```c
hmath_status hmath_interchange_value_i16(hmath_context *context, hmath_value **out);
```

## `i32`

`interchange.i32()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.I32`](haskell/HMath-Interchange-Array.md#v:I32). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType
```

```c
hmath_status hmath_interchange_value_i32(hmath_context *context, hmath_value **out);
```

## `i64`

`interchange.i64()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.I64`](haskell/HMath-Interchange-Array.md#v:I64). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType
```

```c
hmath_status hmath_interchange_value_i64(hmath_context *context, hmath_value **out);
```

## `i8`

`interchange.i8()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.I8`](haskell/HMath-Interchange-Array.md#v:I8). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType
```

```c
hmath_status hmath_interchange_value_i8(hmath_context *context, hmath_value **out);
```

## `interchange_io_error`

`interchange.interchange_io_error(message)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.InterchangeIOError`](haskell/HMath-Interchange-Array.md#v:InterchangeIOError). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
String -> InterchangeError
```

```c
hmath_status hmath_interchange_value_interchange_io_error(hmath_context *context, const hmath_value *message, hmath_value **out);
```

## `invalid_data`

`interchange.invalid_data(message)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.InvalidData`](haskell/HMath-Interchange-Array.md#v:InvalidData). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
String -> InterchangeError
```

```c
hmath_status hmath_interchange_value_invalid_data(hmath_context *context, const hmath_value *message, hmath_value **out);
```

## `limit_exceeded`

`interchange.limit_exceeded(message)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.LimitExceeded`](haskell/HMath-Interchange-Array.md#v:LimitExceeded). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
String -> InterchangeError
```

```c
hmath_status hmath_interchange_value_limit_exceeded(hmath_context *context, const hmath_value *message, hmath_value **out);
```

## `limits`

`interchange.limits(max_bytes, max_elements, max_rank, max_metadata, max_archive_entries)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.Limits`](haskell/HMath-Interchange-Array.md#v:Limits). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Int -> Int -> Int -> Int -> Int -> Limits
```

```c
hmath_status hmath_interchange_value_limits(hmath_context *context, const hmath_value *max_bytes, const hmath_value *max_elements, const hmath_value *max_rank, const hmath_value *max_metadata, const hmath_value *max_archive_entries, hmath_value **out);
```

## `little_endian`

`interchange.little_endian()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.LittleEndian`](haskell/HMath-Interchange-Array.md#v:LittleEndian). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Endian
```

```c
hmath_status hmath_interchange_value_little_endian(hmath_context *context, hmath_value **out);
```

## `u16`

`interchange.u16()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.U16`](haskell/HMath-Interchange-Array.md#v:U16). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType
```

```c
hmath_status hmath_interchange_value_u16(hmath_context *context, hmath_value **out);
```

## `u32`

`interchange.u32()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.U32`](haskell/HMath-Interchange-Array.md#v:U32). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType
```

```c
hmath_status hmath_interchange_value_u32(hmath_context *context, hmath_value **out);
```

## `u64`

`interchange.u64()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.U64`](haskell/HMath-Interchange-Array.md#v:U64). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType
```

```c
hmath_status hmath_interchange_value_u64(hmath_context *context, hmath_value **out);
```

## `u8`

`interchange.u8()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.U8`](haskell/HMath-Interchange-Array.md#v:U8). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType
```

```c
hmath_status hmath_interchange_value_u8(hmath_context *context, hmath_value **out);
```

## `unsupported`

`interchange.unsupported(message)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.Unsupported`](haskell/HMath-Interchange-Array.md#v:Unsupported). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
String -> InterchangeError
```

```c
hmath_status hmath_interchange_value_unsupported(hmath_context *context, const hmath_value *message, hmath_value **out);
```

## `array`

`interchange.array(lim, dt, en, sh, st, off, bs)`

 Construct a bounded view. Bool8 bytes reachable through the view must be 0 or 1. Floating payloads preserve IEEE NaNs, signed zero and infinities. 

Original: [`HMath.Interchange.Array.array`](haskell/HMath-Interchange-Array.md#v:array). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> DType -> Endian -> [Int] -> [Int] -> Int -> ByteString -> Either InterchangeError Array
```

```c
hmath_status hmath_interchange_value_array(hmath_context *context, const hmath_value *lim, const hmath_value *dt, const hmath_value *en, const hmath_value *sh, const hmath_value *st, const hmath_value *off, const hmath_value *bs, hmath_value **out);
```

## `array_bytes`

`interchange.array_bytes(value)`

 Return immutable backing bytes, which may include padding or data not reached by the logical strided view. Use toValues or repack for logical contents. 

Original: [`HMath.Interchange.Array.arrayBytes`](haskell/HMath-Interchange-Array.md#v:arrayBytes). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Array -> ByteString
```

```c
hmath_status hmath_interchange_value_array_bytes(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `array_d_type`

`interchange.array_d_type(value)`

 Return the fixed-width wire dtype of an Array; this is independent of Haskell host Int/Double defaults. 

Original: [`HMath.Interchange.Array.arrayDType`](haskell/HMath-Interchange-Array.md#v:arrayDType). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Array -> DType
```

```c
hmath_status hmath_interchange_value_array_d_type(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `array_endian`

`interchange.array_endian(value)`

Return explicit payload byte order; single-byte dtypes are endian-independent.

Original: [`HMath.Interchange.Array.arrayEndian`](haskell/HMath-Interchange-Array.md#v:arrayEndian). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Array -> Endian
```

```c
hmath_status hmath_interchange_value_array_endian(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `array_metadata`

`interchange.array_metadata(value)`

 Return descriptive UTF-8-compatible key/value metadata strings in stored order; metadata is not executable. 

Original: [`HMath.Interchange.Array.arrayMetadata`](haskell/HMath-Interchange-Array.md#v:arrayMetadata). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Array -> [(String, String)]
```

```c
hmath_status hmath_interchange_value_array_metadata(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `array_offset`

`interchange.array_offset(value)`

Return byte offset of logical origin within arrayBytes backing storage.

Original: [`HMath.Interchange.Array.arrayOffset`](haskell/HMath-Interchange-Array.md#v:arrayOffset). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Array -> Int
```

```c
hmath_status hmath_interchange_value_array_offset(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `array_shape`

`interchange.array_shape(value)`

Return logical dimensions in axis order; [] is scalar and zero axes are valid.

Original: [`HMath.Interchange.Array.arrayShape`](haskell/HMath-Interchange-Array.md#v:arrayShape). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Array -> [Int]
```

```c
hmath_status hmath_interchange_value_array_shape(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `array_strides`

`interchange.array_strides(value)`

 Return signed byte strides for each axis. Unlike HMath.Tensor strides, these are bytes, not elements. 

Original: [`HMath.Interchange.Array.arrayStrides`](haskell/HMath-Interchange-Array.md#v:arrayStrides). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Array -> [Int]
```

```c
hmath_status hmath_interchange_value_array_strides(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `contiguous_array`

`interchange.contiguous_array(lim, dt, en, order, sh, bs)`

 Given limits,dtype,endian,physical order,shape,then exact packed bytes, construct a canonical byte-strided array. Require exact byte count; invalid shape/data/limits fail. 

Original: [`HMath.Interchange.Array.contiguousArray`](haskell/HMath-Interchange-Array.md#v:contiguousArray). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> DType -> Endian -> Order -> [Int] -> ByteString -> Either InterchangeError Array
```

```c
hmath_status hmath_interchange_value_contiguous_array(hmath_context *context, const hmath_value *lim, const hmath_value *dt, const hmath_value *en, const hmath_value *order, const hmath_value *sh, const hmath_value *bs, hmath_value **out);
```

## `default_limits`

`interchange.default_limits()`

128 MiB of bytes, 8 million samples, rank 16, 64 KiB metadata, 256 members.

Original: [`HMath.Interchange.Array.defaultLimits`](haskell/HMath-Interchange-Array.md#v:defaultLimits). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits
```

```c
hmath_status hmath_interchange_value_default_limits(hmath_context *context, hmath_value **out);
```

## `dense_strides`

`interchange.dense_strides(c_order, w, sh)`

 Dense strides use Integer arithmetic before conversion. Call only on validated shape/byte sizes; zero axes use zero strides to avoid overflow. 

Original: [`HMath.Interchange.Array.denseStrides`](haskell/HMath-Interchange-Array.md#v:denseStrides). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Order -> Int -> [Int] -> [Int]
```

```c
hmath_status hmath_interchange_value_dense_strides(hmath_context *context, const hmath_value *c_order, const hmath_value *w, const hmath_value *sh, hmath_value **out);
```

## `element_bytes`

`interchange.element_bytes(dt)`

 Return fixed byte width of a DType, including complex pairs (C64=8,C128=16) and Bool8=1. 

Original: [`HMath.Interchange.Array.elementBytes`](haskell/HMath-Interchange-Array.md#v:elementBytes). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType -> Int
```

```c
hmath_status hmath_interchange_value_element_bytes(hmath_context *context, const hmath_value *dt, hmath_value **out);
```

## `element_count`

`interchange.element_count(value)`

Return logical shape product; scalar arrays have one element and empty axes have zero.

Original: [`HMath.Interchange.Array.elementCount`](haskell/HMath-Interchange-Array.md#v:elementCount). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Array -> Int
```

```c
hmath_status hmath_interchange_value_element_count(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `element_type`

`interchange.element_type(*, dtype="float64")`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.elementType`](haskell/HMath-Interchange-Array.md#v:elementType). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Element a => proxy a -> DType
```

```c
hmath_status hmath_interchange_value_element_type(hmath_context *context, const hmath_value *prototype, hmath_value **out);
```

## `from_matrix`

`interchange.from_matrix(value, value2, value3)`

 Given limits,endian,then typed Matrix, encode its row-major values as a rank-two Array. Dtype comes from Element; resource limits can fail. 

Original: [`HMath.Interchange.Array.fromMatrix`](haskell/HMath-Interchange-Array.md#v:fromMatrix). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Element a => Limits -> Endian -> HMath.Matrix.Matrix a -> Either InterchangeError Array
```

```c
hmath_status hmath_interchange_value_from_matrix(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out);
```

## `from_tensor`

`interchange.from_tensor(value, value2, value3)`

 Given limits,endian,then typed Haskell Tensor, encode logical row-major values and preserve shape. The Element instance determines wire dtype; resource bounds can fail. 

Original: [`HMath.Interchange.Array.fromTensor`](haskell/HMath-Interchange-Array.md#v:fromTensor). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Element a => Limits -> Endian -> HMath.Tensor.Tensor a -> Either InterchangeError Array
```

```c
hmath_status hmath_interchange_value_from_tensor(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out);
```

## `from_values`

`interchange.from_values(limits,endian,shape,values, *, dtype="float64")`

 Given limits,endian,shape,then typed Element list, encode to a contiguous array with that Element dtype. Require exact shape/count match and resource bounds; failures return InterchangeError. 

Original: [`HMath.Interchange.Array.fromValues`](haskell/HMath-Interchange-Array.md#v:fromValues). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Element a => Limits -> Endian -> [Int] -> [a] -> Either InterchangeError Array
```

```c
hmath_status hmath_interchange_value_from_values(hmath_context *context, const hmath_value *prototype, const hmath_value *limits, const hmath_value *endian, const hmath_value *shape, const hmath_value *values, hmath_value **out);
```

## `get_element`

`interchange.get_element(endian, *, dtype="float64")`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.getElement`](haskell/HMath-Interchange-Array.md#v:getElement). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Element a => Endian -> Data.Binary.Get.Internal.Get a
```

```c
hmath_status hmath_interchange_value_get_element(hmath_context *context, const hmath_value *prototype, const hmath_value *endian, hmath_value **out);
```

## `max_archive_entries`

`interchange.max_archive_entries(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.maxArchiveEntries`](haskell/HMath-Interchange-Array.md#v:maxArchiveEntries). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Int
```

```c
hmath_status hmath_interchange_value_max_archive_entries(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `max_bytes`

`interchange.max_bytes(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.maxBytes`](haskell/HMath-Interchange-Array.md#v:maxBytes). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Int
```

```c
hmath_status hmath_interchange_value_max_bytes(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `max_elements`

`interchange.max_elements(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.maxElements`](haskell/HMath-Interchange-Array.md#v:maxElements). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Int
```

```c
hmath_status hmath_interchange_value_max_elements(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `max_metadata`

`interchange.max_metadata(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.maxMetadata`](haskell/HMath-Interchange-Array.md#v:maxMetadata). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Int
```

```c
hmath_status hmath_interchange_value_max_metadata(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `max_rank`

`interchange.max_rank(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.maxRank`](haskell/HMath-Interchange-Array.md#v:maxRank). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Int
```

```c
hmath_status hmath_interchange_value_max_rank(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `put_element`

`interchange.put_element(endian,value, *, dtype="float64")`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Array.putElement`](haskell/HMath-Interchange-Array.md#v:putElement). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Element a => Endian -> a -> Data.Binary.Put.Put
```

```c
hmath_status hmath_interchange_value_put_element(hmath_context *context, const hmath_value *prototype, const hmath_value *endian, const hmath_value *value, hmath_value **out);
```

## `raw_decode`

`interchange.raw_decode(value, value2, value3, value4, value5, value6)`

 Given limits,dtype,endian,order,shape,then bytes, construct a packed Array. Caller supplies all metadata; exact byte-count and shape/resource validation is enforced. 

Original: [`HMath.Interchange.Array.rawDecode`](haskell/HMath-Interchange-Array.md#v:rawDecode). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> DType -> Endian -> Order -> [Int] -> ByteString -> Either InterchangeError Array
```

```c
hmath_status hmath_interchange_value_raw_decode(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, const hmath_value *value6, hmath_value **out);
```

## `raw_encode`

`interchange.raw_encode(value, value2, value3, value4)`

 Given limits,destination endian,physical order,then Array, repack its logical payload and return raw bytes without shape/header metadata. Checked resource/layout failures propagate. 

Original: [`HMath.Interchange.Array.rawEncode`](haskell/HMath-Interchange-Array.md#v:rawEncode). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Endian -> Order -> Array -> Either InterchangeError ByteString
```

```c
hmath_status hmath_interchange_value_raw_encode(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out);
```

## `repack`

`interchange.repack(lim, en, order, a)`

 Pack arbitrary views, preserving dtype and exact component bits. Complex byte swapping reverses each real/imaginary component separately. 

Original: [`HMath.Interchange.Array.repack`](haskell/HMath-Interchange-Array.md#v:repack). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Endian -> Order -> Array -> Either InterchangeError Array
```

```c
hmath_status hmath_interchange_value_repack(hmath_context *context, const hmath_value *lim, const hmath_value *en, const hmath_value *order, const hmath_value *a, hmath_value **out);
```

## `to_matrix`

`interchange.to_matrix(array, *, dtype=None)`

 Decode a matching typed rank-two Array to Matrix. Rank/dtype or checked shape conversion failures return InterchangeError. 

Original: [`HMath.Interchange.Array.toMatrix`](haskell/HMath-Interchange-Array.md#v:toMatrix). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Element a => Array -> Either InterchangeError (HMath.Matrix.Matrix a)
```

```c
hmath_status hmath_interchange_value_to_matrix(hmath_context *context, const hmath_value *prototype, const hmath_value *array, hmath_value **out);
```

## `to_tensor`

`interchange.to_tensor(array, *, dtype=None)`

 Decode an Array of matching Element dtype to a contiguous Haskell Tensor, preserving logical shape/order. Dtype or checked tensor-construction failure returns InterchangeError. 

Original: [`HMath.Interchange.Array.toTensor`](haskell/HMath-Interchange-Array.md#v:toTensor). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Element a => Array -> Either InterchangeError (HMath.Tensor.Tensor a)
```

```c
hmath_status hmath_interchange_value_to_tensor(hmath_context *context, const hmath_value *prototype, const hmath_value *array, hmath_value **out);
```

## `to_values`

`interchange.to_values(array, *, dtype=None, boxed=False)`

 Decode logical row-major values as the requested Element type, requiring an exact dtype match. No silent numeric cast occurs; mismatch returns Unsupported/InvalidData. 

Original: [`HMath.Interchange.Array.toValues`](haskell/HMath-Interchange-Array.md#v:toValues). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Element a => Array -> Either InterchangeError [a]
```

```c
hmath_status hmath_interchange_value_to_values(hmath_context *context, const hmath_value *prototype, const hmath_value *array, hmath_value **out);
```

## `validate_shape`

`interchange.validate_shape(lim, sh)`

 Given limits then dimensions, validate rank, nonnegative axes and element product, returning Int element count. Invalid data or exceeded limits return InterchangeError. 

Original: [`HMath.Interchange.Array.validateShape`](haskell/HMath-Interchange-Array.md#v:validateShape). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> [Int] -> Either InterchangeError Int
```

```c
hmath_status hmath_interchange_value_validate_shape(hmath_context *context, const hmath_value *lim, const hmath_value *sh, hmath_value **out);
```

## `with_metadata`

`interchange.with_metadata(value, value2, value3)`

 Metadata is UTF-8 in binary files; keys must be unique and nonempty. The four-byte-per-codepoint bound is intentionally conservative before encoding. 

Original: [`HMath.Interchange.Array.withMetadata`](haskell/HMath-Interchange-Array.md#v:withMetadata). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> [(String, String)] -> Array -> Either InterchangeError Array
```

```c
hmath_status hmath_interchange_value_with_metadata(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out);
```

## `crc32`

`interchange.crc32(value)`

Standard CRC-32, compatible with ZIP and zlib, with a fixed 256-entry table.

Original: [`HMath.Interchange.Binary.crc32`](haskell/HMath-Interchange-Binary.md#v:crc32). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
ByteString -> Word32
```

```c
hmath_status hmath_interchange_value_crc32(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `decode_binary`

`interchange.decode_binary(lim, input)`

 Given limits then bytes, validate HMath v1 magic/header/flags/CRC and exact framing, returning an Array. Truncation, corruption, unsupported metadata or exceeded budgets return InterchangeError. 

Original: [`HMath.Interchange.Binary.decodeBinary`](haskell/HMath-Interchange-Binary.md#v:decodeBinary). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> ByteString -> Either InterchangeError Array
```

```c
hmath_status hmath_interchange_value_decode_binary(hmath_context *context, const hmath_value *lim, const hmath_value *input, hmath_value **out);
```

## `encode_binary`

`interchange.encode_binary(lim, a)`

 Given limits then Array, encode HMath wire-format v1 including shape/strides/offset/metadata/backing storage and CRC-32. Invalid metadata/layout or exceeded aggregate byte budget fails. 

Original: [`HMath.Interchange.Binary.encodeBinary`](haskell/HMath-Interchange-Binary.md#v:encodeBinary). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Array -> Either InterchangeError ByteString
```

```c
hmath_status hmath_interchange_value_encode_binary(hmath_context *context, const hmath_value *lim, const hmath_value *a, hmath_value **out);
```

## `gzip`

`interchange.gzip()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Compression.Gzip`](haskell/HMath-Interchange-Compression.md#v:Gzip). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Compression
```

```c
hmath_status hmath_interchange_value_gzip(hmath_context *context, hmath_value **out);
```

## `raw_deflate`

`interchange.raw_deflate()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Compression.RawDeflate`](haskell/HMath-Interchange-Compression.md#v:RawDeflate). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Compression
```

```c
hmath_status hmath_interchange_value_raw_deflate(hmath_context *context, hmath_value **out);
```

## `zlib`

`interchange.zlib()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.Compression.Zlib`](haskell/HMath-Interchange-Compression.md#v:Zlib). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Compression
```

```c
hmath_status hmath_interchange_value_zlib(hmath_context *context, hmath_value **out);
```

## `compress`

`interchange.compress(lim, wrapper, input)`

 Given limits,RawDeflate/Zlib/Gzip wrapper,then bytes, compress within a bounded output allocation. Return InterchangeError for unavailable provider, invalid limits, byte-budget excess or compression failure in IO. 

Original: [`HMath.Interchange.Compression.compress`](haskell/HMath-Interchange-Compression.md#v:compress). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Compression -> ByteString -> IO (Either InterchangeError ByteString)
```

```c
hmath_status hmath_interchange_value_compress(hmath_context *context, const hmath_value *lim, const hmath_value *wrapper, const hmath_value *input, hmath_value **out);
```

## `compression_available`

`interchange.compression_available()`

 Probe whether the optional native zlib adapter is available, returning IO Bool. False means compressed operations cannot run; no payload is processed. 

Original: [`HMath.Interchange.Compression.compressionAvailable`](haskell/HMath-Interchange-Compression.md#v:compressionAvailable). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
IO Bool
```

```c
hmath_status hmath_interchange_value_compression_available(hmath_context *context, hmath_value **out);
```

## `decompress`

`interchange.decompress(value, value2, value3, value4)`

 The output length may be smaller than the budget. Archives additionally compare it to the declared member size before accepting their payload. 

Original: [`HMath.Interchange.Compression.decompress`](haskell/HMath-Interchange-Compression.md#v:decompress). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Compression -> Int -> ByteString -> IO (Either InterchangeError ByteString)
```

```c
hmath_status hmath_interchange_value_decompress(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out);
```

## `raw_spec`

`interchange.raw_spec(dtype, endian, order, shape)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interchange.IO.RawSpec`](haskell/HMath-Interchange-IO.md#v:RawSpec). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
DType -> Endian -> Order -> [Int] -> RawSpec
```

```c
hmath_status hmath_interchange_value_raw_spec(hmath_context *context, const hmath_value *dtype, const hmath_value *endian, const hmath_value *order, const hmath_value *shape, hmath_value **out);
```

## `mapped_read_bytes`

`interchange.mapped_read_bytes(mapping, offset, count)`

Copy a bounded byte range. Copies may safely survive mapping closure.

Original: [`HMath.Interchange.IO.mappedReadBytes`](haskell/HMath-Interchange-IO.md#v:mappedReadBytes). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
forall {k} (s :: k). MappedArray s -> Int -> Int -> IO (Either InterchangeError ByteString)
```

```c
hmath_status hmath_interchange_value_mapped_read_bytes(hmath_context *context, const hmath_value *mapping, const hmath_value *offset, const hmath_value *count, hmath_value **out);
```

## `mapped_shape`

`interchange.mapped_shape(mapping)`

 Return dimensions of a callback-scoped read-only mapped array. The region token prevents its raw view escaping withMappedArray. 

Original: [`HMath.Interchange.IO.mappedShape`](haskell/HMath-Interchange-IO.md#v:mappedShape). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
forall {k} (s :: k). MappedArray s -> [Int]
```

```c
hmath_status hmath_interchange_value_mapped_shape(hmath_context *context, const hmath_value *mapping, hmath_value **out);
```

## `mapped_value`

`interchange.mapped_value(mapping,indices, *, dtype="float64",boxed=False)`

 Read one typed scalar using checked multidimensional indexing. Physical endian conversion happens through the same Element decoder as normal arrays. 

Original: [`HMath.Interchange.IO.mappedValue`](haskell/HMath-Interchange-IO.md#v:mappedValue). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
forall {k} a (s :: k). Element a => MappedArray s -> [Int] -> IO (Either InterchangeError a)
```

```c
hmath_status hmath_interchange_value_mapped_value(hmath_context *context, const hmath_value *prototype, const hmath_value *mapping, const hmath_value *indices, hmath_value **out);
```

## `read_array_file`

`interchange.read_array_file(lim, decode, path)`

 File reading checks the declared size before allocating, then caps the actual read too, handling concurrent growth. Files are closed before return. 

Original: [`HMath.Interchange.IO.readArrayFile`](haskell/HMath-Interchange-IO.md#v:readArrayFile). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> (ByteString -> Either InterchangeError Array) -> FilePath -> IO (Either InterchangeError Array)
```

```c
hmath_status hmath_interchange_value_read_array_file(hmath_context *context, const hmath_value *lim, const hmath_value *decode, const hmath_value *path, hmath_value **out);
```

## `read_raw_chunks`

`interchange.read_raw_chunks(value, value2, value3, value4, value5)`

 Read physical-order chunks (one-dimensional arrays); the caller retains the original RawSpec for reconstructing dimensions. Memory is O(chunk), excluding any data retained by the callback. False cancels successfully without consuming the rest. Full completion requires EOF, detecting tails. 

Original: [`HMath.Interchange.IO.readRawChunks`](haskell/HMath-Interchange-IO.md#v:readRawChunks). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> RawSpec -> Int -> Handle -> (Array -> IO (Either InterchangeError Bool)) -> IO (Either InterchangeError ())
```

```c
hmath_status hmath_interchange_value_read_raw_chunks(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out);
```

## `with_mapped_array`

`interchange.with_mapped_array(limits, specification, path, callback)`

 Given limits,RawSpec,path,then rank-2 callback, map read-only raw data for that callback's lifetime and unmap on exit. Validate exact file size/spec/budgets; path/IO/format failures return InterchangeError. Do not retain borrowed pointers beyond the callback. 

Original: [`HMath.Interchange.IO.withMappedArray`](haskell/HMath-Interchange-IO.md#v:withMappedArray). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> RawSpec -> FilePath -> (forall (s :: k). MappedArray s -> IO a) -> IO (Either InterchangeError a)
```

```c
hmath_status hmath_interchange_value_with_mapped_array(hmath_context *context, const hmath_value *limits, const hmath_value *specification, const hmath_value *path, const hmath_value *callback, hmath_value **out);
```

## `write_array_file`

`interchange.write_array_file(lim, encode, path, a)`

 Writes to the supplied path after encoding succeeds. Applications needing transactional replacement can write a sibling temporary and rename it. 

Original: [`HMath.Interchange.IO.writeArrayFile`](haskell/HMath-Interchange-IO.md#v:writeArrayFile). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> (Limits -> Array -> Either InterchangeError ByteString) -> FilePath -> Array -> IO (Either InterchangeError ())
```

```c
hmath_status hmath_interchange_value_write_array_file(hmath_context *context, const hmath_value *lim, const hmath_value *encode, const hmath_value *path, const hmath_value *a, hmath_value **out);
```

## `write_raw_chunks`

`interchange.write_raw_chunks(value, value2, value3, value4, value5)`

 Write fixed-size raw chunks. The producer receives a maximum byte count, must return whole elements, and signals EOF with Nothing. Short streams, overlong streams, noncanonical bools and empty nonfinal chunks fail. Errors may leave a partial output; the handle remains owned by the caller. 

Original: [`HMath.Interchange.IO.writeRawChunks`](haskell/HMath-Interchange-IO.md#v:writeRawChunks). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> RawSpec -> Int -> Handle -> (Int -> IO (Either InterchangeError (Maybe ByteString))) -> IO (Either InterchangeError ())
```

```c
hmath_status hmath_interchange_value_write_raw_chunks(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out);
```

## `decode_npy`

`interchange.decode_npy(lim, input)`

 Given limits then NPY bytes, decode supported v1/v2/v3 fixed-width scalar dtype arrays. Reject pickle/object/record/string dtypes, malformed headers, unknown endian/layout, trailing bytes or exceeded budgets. 

Original: [`HMath.Interchange.Numpy.decodeNpy`](haskell/HMath-Interchange-Numpy.md#v:decodeNpy). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> ByteString -> Either InterchangeError Array
```

```c
hmath_status hmath_interchange_value_decode_npy(hmath_context *context, const hmath_value *lim, const hmath_value *input, hmath_value **out);
```

## `decode_npz`

`interchange.decode_npz(lim, input)`

 Checks directory/local consistency, CRC, exact deflate length, duplicate names, overlapping member ranges and aggregate expanded bytes. Data descriptors/encryption/multi-disk/ZIP64 directories are explicitly rejected. 

Original: [`HMath.Interchange.Numpy.decodeNpz`](haskell/HMath-Interchange-Numpy.md#v:decodeNpz). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> ByteString -> IO (Either InterchangeError [(String, Array)])
```

```c
hmath_status hmath_interchange_value_decode_npz(hmath_context *context, const hmath_value *lim, const hmath_value *input, hmath_value **out);
```

## `encode_npy`

`interchange.encode_npy(lim, order, a)`

 Given limits,physical C/F order,then Array, repack and write a NumPy NPY v1 payload with explicit dtype/endian/shape. Oversized header/output or unsupported layout conversion fails. 

Original: [`HMath.Interchange.Numpy.encodeNpy`](haskell/HMath-Interchange-Numpy.md#v:encodeNpy). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Order -> Array -> Either InterchangeError ByteString
```

```c
hmath_status hmath_interchange_value_encode_npy(hmath_context *context, const hmath_value *lim, const hmath_value *order, const hmath_value *a, hmath_value **out);
```

## `encode_npz`

`interchange.encode_npz(lim, compressed, arrays)`

 Deterministic archives, DOS epoch timestamps and no ZIP comments. True selects raw DEFLATE and requires the optional zlib build feature. 

Original: [`HMath.Interchange.Numpy.encodeNpz`](haskell/HMath-Interchange-Numpy.md#v:encodeNpz). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Bool -> [(String, Array)] -> IO (Either InterchangeError ByteString)
```

```c
hmath_status hmath_interchange_value_encode_npz(hmath_context *context, const hmath_value *lim, const hmath_value *compressed, const hmath_value *arrays, hmath_value **out);
```

## `decode_delimited`

`interchange.decode_delimited(lim, separator, dt, bs)`

 Given limits,comma/tab separator,target DType,then CSV/TSV bytes, parse rectangular real numeric cells to a rank-two Array. Complex dtype, malformed rows/tokens or exceeded budgets fail. 

Original: [`HMath.Interchange.Text.decodeDelimited`](haskell/HMath-Interchange-Text.md#v:decodeDelimited). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Char -> DType -> ByteString -> Either InterchangeError Array
```

```c
hmath_status hmath_interchange_value_decode_delimited(hmath_context *context, const hmath_value *lim, const hmath_value *separator, const hmath_value *dt, const hmath_value *bs, hmath_value **out);
```

## `decode_matrix_market`

`interchange.decode_matrix_market(lim, bs)`

 Array and coordinate input, real/integer/complex/pattern fields and general/symmetric/skew-symmetric/Hermitian storage. Coordinate duplicates are added exactly for integers and checked for finite overflow for floats. Dense output is bounded by maxElements even for sparse input. 

Original: [`HMath.Interchange.Text.decodeMatrixMarket`](haskell/HMath-Interchange-Text.md#v:decodeMatrixMarket). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> ByteString -> Either InterchangeError Array
```

```c
hmath_status hmath_interchange_value_decode_matrix_market(hmath_context *context, const hmath_value *lim, const hmath_value *bs, hmath_value **out);
```

## `decode_text`

`interchange.decode_text(lim, bs)`

 Given limits then HMath text bytes, parse dtype/shape/tokens and return a checked Array. Invalid ASCII/header/value counts or exceeded budgets fail. 

Original: [`HMath.Interchange.Text.decodeText`](haskell/HMath-Interchange-Text.md#v:decodeText). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> ByteString -> Either InterchangeError Array
```

```c
hmath_status hmath_interchange_value_decode_text(hmath_context *context, const hmath_value *lim, const hmath_value *bs, hmath_value **out);
```

## `encode_delimited`

`interchange.encode_delimited(lim, separator, a)`

 Given limits,comma or tab separator,then rank-two noncomplex Array, encode CSV/TSV numeric cells. No shape/dtype metadata is embedded; unsupported input/separator or output bounds fail. 

Original: [`HMath.Interchange.Text.encodeDelimited`](haskell/HMath-Interchange-Text.md#v:encodeDelimited). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Char -> Array -> Either InterchangeError ByteString
```

```c
hmath_status hmath_interchange_value_encode_delimited(hmath_context *context, const hmath_value *lim, const hmath_value *separator, const hmath_value *a, hmath_value **out);
```

## `encode_matrix_market`

`interchange.encode_matrix_market(lim, a)`

Dense general Matrix Market; exact Int64, Float64, or Complex128.

Original: [`HMath.Interchange.Text.encodeMatrixMarket`](haskell/HMath-Interchange-Text.md#v:encodeMatrixMarket). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Array -> Either InterchangeError ByteString
```

```c
hmath_status hmath_interchange_value_encode_matrix_market(hmath_context *context, const hmath_value *lim, const hmath_value *a, hmath_value **out);
```

## `encode_text`

`interchange.encode_text(lim, a)`

 Given limits then Array, encode self-describing HMath text with dtype/shape and scalar tokens. Invalid/unsupported values or output exceeding limits returns InterchangeError. 

Original: [`HMath.Interchange.Text.encodeText`](haskell/HMath-Interchange-Text.md#v:encodeText). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Array -> Either InterchangeError ByteString
```

```c
hmath_status hmath_interchange_value_encode_text(hmath_context *context, const hmath_value *lim, const hmath_value *a, hmath_value **out);
```

## `bounded_int`

`interchange.bounded_int(name, upper, x)`

 Given diagnostic name,nonnegative upper bound,then Integer value, convert only if value lies in [0,upper] and fits Int. Otherwise return LimitExceeded with that name. 

Original: [`HMath.Interchange.Array.boundedInt`](haskell/HMath-Interchange-Array.md#v:boundedInt). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
String -> Integer -> Integer -> Either InterchangeError Int
```

```c
hmath_status hmath_interchange_value_bounded_int(hmath_context *context, const hmath_value *name, const hmath_value *upper, const hmath_value *x, hmath_value **out);
```

## `byte_offsets`

`interchange.byte_offsets(a)`

 Return backing byte offsets for each logical element in row-major coordinate order, honoring signed strides and offset. 

Original: [`HMath.Interchange.Array.byteOffsets`](haskell/HMath-Interchange-Array.md#v:byteOffsets). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Array -> [Int]
```

```c
hmath_status hmath_interchange_value_byte_offsets(hmath_context *context, const hmath_value *a, hmath_value **out);
```

## `check_limits`

`interchange.check_limits(lim)`

 Validate nonnegative finite resource caps, rank<=255 and Int-safe byte/element/metadata/archive budgets. Invalid settings return InvalidData. 

Original: [`HMath.Interchange.Array.checkLimits`](haskell/HMath-Interchange-Array.md#v:checkLimits). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Limits -> Either InterchangeError ()
```

```c
hmath_status hmath_interchange_value_check_limits(hmath_context *context, const hmath_value *lim, hmath_value **out);
```

## `guard_i`

`interchange.guard_i(p, e)`

 Given condition then InterchangeError, return Right () when True and Left that error otherwise. This helper performs no IO. 

Original: [`HMath.Interchange.Array.guardI`](haskell/HMath-Interchange-Array.md#v:guardI). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Bool -> InterchangeError -> Either InterchangeError ()
```

```c
hmath_status hmath_interchange_value_guard_i(hmath_context *context, const hmath_value *p, const hmath_value *e, hmath_value **out);
```

## `run_decoder`

`interchange.run_decoder(parser, data, *, boxed=False)`

Strict, exact decoder: trailing bytes are an error rather than ignored.

Original: [`HMath.Interchange.Binary.runDecoder`](haskell/HMath-Interchange-Binary.md#v:runDecoder). Python keeps the source argument order; Element-polymorphic helpers use `dtype=` instead of a type annotation.

```haskell
Get a -> ByteString -> Either InterchangeError a
```

```c
hmath_status hmath_interchange_value_run_decoder(hmath_context *context, const hmath_value *parser, const hmath_value *data, hmath_value **out);
```

## `dtype_code`

`interchange.dtype_code(dtype)`

Return the original DType enumeration code as an integer (Bool8=0 through C128=12).

```c
hmath_status hmath_interchange_value_dtype_code(hmath_context *context, const hmath_value *dtype, hmath_value **out);
```

## `error_fields`

`interchange.error_fields(error)`

Return an InterchangeError's original constructor code and full message; embedded NUL and Unicode are retained.

```c
hmath_status hmath_interchange_value_error_fields(hmath_context *context, const hmath_value *error, hmath_value **out);
```

## `put_bytes`

`interchange.put_bytes(program)`

Execute the original Put program and return owned Bytes. This does not perform file IO.

```c
hmath_status hmath_interchange_value_put_bytes(hmath_context *context, const hmath_value *program, hmath_value **out);
```

## `open_handle`

`interchange.open_handle(path, mode)`

Open a real binary handle. Modes are rb, wb, ab or r+b; wb truncates and ab appends. IO failures raise the original InterchangeIOError. Close the shared resource explicitly before releasing its value owner.

```c
hmath_status hmath_interchange_value_open_handle(hmath_context *context, const hmath_value *path, const hmath_value *mode, hmath_value **out);
```

## `close_handle`

`interchange.close_handle(handle)`

Close the shared Haskell handle. Other retained owners refer to that same closed resource. Python BinaryHandle.close() closes the resource and releases its own value reference.

```c
hmath_status hmath_interchange_value_close_handle(hmath_context *context, const hmath_value *handle, hmath_value **out);
```

## `seek_handle`

`interchange.seek_handle(handle, whence, offset)`

Seek the binary handle with whence 0 (absolute), 1 (relative) or 2 (from end) and an exact integer byte offset. Original handle IO errors become InterchangeIOError.

```c
hmath_status hmath_interchange_value_seek_handle(hmath_context *context, const hmath_value *handle, const hmath_value *whence, const hmath_value *offset, hmath_value **out);
```

## `tell_handle`

`interchange.tell_handle(handle)`

Return the handle's current byte position as an exact integer.

```c
hmath_status hmath_interchange_value_tell_handle(hmath_context *context, const hmath_value *handle, hmath_value **out);
```

## `flush_handle`

`interchange.flush_handle(handle)`

Flush the original Haskell handle. This has the source hFlush contract and does not promise a filesystem durability barrier.

```c
hmath_status hmath_interchange_value_flush_handle(hmath_context *context, const hmath_value *handle, hmath_value **out);
```

## `equal_array`

`interchange.equal_array(left, right)`

Compare the original Array values, including dtype, endian, layout, metadata and backing bytes. This is structural equality, not a converted numerical comparison.

```c
hmath_status hmath_interchange_value_equal_array(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

