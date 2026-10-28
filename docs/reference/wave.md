# Wave API

The Wave 0.2.1 binding targets **64-bit systems** where C `size_t` matches Wave
`u64`. Import `bindings/wave/hmath.wave` beside your source as shown in the
[Wave integration guide](../guides/wave.md). All numerical values are `f64`.

## Function index

| API | Purpose |
| --- | --- |
| [initialize](#initialize-i32) | Initialize the shared runtime after checking the ABI. |
| [error_message](#error_message-ptri8) | Borrow the current thread’s native error message. |
| [scalar_add](#scalar_adda-f64-b-f64-output-ptrf64-i32) | Add two finite real scalars. |
| [tensor_empty](#tensor_empty-tensor) | Construct an empty wrapper without allocating a native tensor. |
| [tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32) | Copy row-major values into an owned tensor. |
| [vector_copy](#vector_copydata-ptrf64-count-u64-output-ptrtensor-i32) | Copy values into an owned rank-one tensor. |
| [matrix_copy](#matrix_copydata-ptrf64-count-u64-rows-u64-columns-u64-output-ptrtensor-i32) | Copy row-major values into an owned rank-two tensor. |
| [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32) | Acquire a separate owner for the same native tensor. |
| [tensor_close](#tensor_closetensor-ptrtensor) | Release one owned wrapper and clear its handle. |
| [tensor_count](#tensor_counttensor-tensor-u64) | Query the logical element count. |
| [tensor_values](#tensor_valuestensor-tensor-output-ptrf64-count-u64-i32) | Copy logical values into caller-owned storage. |
| [tensor_sum](#tensor_sumtensor-tensor-output-ptrf64-i32) | Sum all logical tensor elements. |
| [tensor_dot](#tensor_dota-tensor-b-tensor-output-ptrf64-i32) | Reduce corresponding products to one scalar. |
| [tensor_add](#tensor_adda-tensor-b-tensor-output-ptrtensor-i32) | Add identically shaped tensors element by element. |
| [tensor_matmul](#tensor_matmula-tensor-b-tensor-output-ptrtensor-i32) | Multiply two dense rank-two matrices. |

## Shared rules

`Tensor { handle: ptr<u8> }` owns one native reference. Treat owners linearly:
plain struct assignment does **not** retain a second reference. Use
`tensor_clone`, and close every owner, including those created before a later
failure. Keep all input handles live throughout a call.

Status-returning wrappers return `i32`: zero means success. The C
[status table](c.md#native-status-codes) defines the other values. Read
`error_message()` immediately after a failed native checked call. Wrapper-only
validation (such as an occupied output slot or ABI mismatch) returns its code
without replacing the native diagnostic, so the message may describe an earlier
call. Do not use that stale message as the reason for wrapper validation failure.

Every tensor output must be a non-NULL pointer to a wrapper initialized with
`tensor_empty()`. Success transfers one owned reference; failure leaves that
empty wrapper unchanged. Scalar outputs are valid only on success. Inputs
must obey the C ABI's rank 8, 1,048,576-element, finite-data, and storage bounds.

## Initialization and diagnostics

### `initialize() -> i32`

Initialize the shared runtime after checking the ABI.

#### Parameters

None.

#### Returns

0 on success, 10 for unsupported ABI, 5 after irreversible shutdown.
Repeated initialization is allowed. Constructors and `scalar_add` call this
automatically. It does not create a tensor or an ownership obligation.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor).

### `error_message() -> ptr<i8>`

Borrow the current thread’s native error message.

#### Parameters

None.

#### Returns

a borrowed, NUL-terminated thread-local
native error string. It remains valid until the next checked C call on this
thread. Copy it before that call if it must survive; never free it.
Wrapper-only validation does not set a fresh message; see the shared rules.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor).

### `scalar_add(a: f64, b: f64, output: ptr<f64>) -> i32`

Add two finite real scalars.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `a` | `f64` | First finite scalar. |
| `b` | `f64` | Second finite scalar. |
| `output` | `ptr<f64>` | Aligned writable scalar slot; valid only on success. |

#### Returns

status 0 and their sum in `output` after automatic initialization.

#### Errors

invalid/non-finite input or result, initialization or native runtime
failure. Example: `scalar_add(2.0, 3.0, &value)` writes 5.0 on success.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor).

## Construction and ownership

### `tensor_empty() -> Tensor`

Construct an empty wrapper without allocating a native tensor.

#### Parameters

None.

#### Returns

`Tensor { handle: null }`, with no native
reference to release. Use this to initialize every result slot before passing
its address to a constructor, clone, add, or matrix multiplication.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor).

### `tensor_copy(data: ptr<f64>, count: u64, shape: ptr<u64>, rank: u64, output: ptr<Tensor>) -> i32`

Copy row-major values into an owned tensor.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `data` | `ptr<f64>` | Readable finite f64 values; NULL only for zero count. |
| `count` | `u64` | Number of values, equal to the shape product. |
| `shape` | `ptr<u64>` | Array of rank dimensions; may be NULL for rank zero. |
| `rank` | `u64` | Dimension count, at most eight. |
| `output` | `ptr<Tensor>` | Non-NULL pointer to a wrapper initialized with tensor_empty(). |

#### Returns

status 0 and a new owned row-major copy; input ownership is unchanged.

#### Errors

occupied/NULL output, invalid storage/dimensions, count mismatch,
size bound, initialization, or allocation failure.

#### Notes

`count` readable finite doubles, `rank` dimensions, and empty
output wrapper. Count must equal the dimension product. Rank zero contains one
value; zero dimensions allow an empty tensor. Data must remain readable during
this synchronous call.

#### See also

[tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor), [error_message](#error_message-ptri8).

### `vector_copy(data: ptr<f64>, count: u64, output: ptr<Tensor>) -> i32`

Copy values into an owned rank-one tensor.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `data` | `ptr<f64>` | Readable finite f64 values; NULL only for zero count. |
| `count` | `u64` | Vector length, at most 1,048,576. |
| `output` | `ptr<Tensor>` | Non-NULL pointer to an empty result wrapper. |

#### Returns

status 0 and a new owned rank-one tensor of length `count`.

#### Errors

the same construction errors as `tensor_copy`.
The values are copied, so the source can be reused once the call returns.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor).

### `matrix_copy(data: ptr<f64>, count: u64, rows: u64, columns: u64, output: ptr<Tensor>) -> i32`

Copy row-major values into an owned rank-two tensor.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `data` | `ptr<f64>` | Readable finite row-major values. |
| `count` | `u64` | Number of values, equal to rows * columns. |
| `rows` | `u64` | Nonnegative bounded row count. |
| `columns` | `u64` | Nonnegative bounded column count. |
| `output` | `ptr<Tensor>` | Non-NULL pointer to an empty result wrapper. |

#### Returns

status 0 and a new owned rank-two matrix.

#### Errors

construction errors, including `count != rows * columns`.
For `{1,2,3,4}`, dimensions 2 by 2 create rows `[1,2]` and `[3,4]`.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor).

### `tensor_clone(source: Tensor, output: ptr<Tensor>) -> i32`

Acquire a separate owner for the same native tensor.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `source` | `Tensor` | Live source wrapper; remains owned by the caller. |
| `output` | `ptr<Tensor>` | Non-NULL pointer to an empty result wrapper. |

#### Returns

0 and a second owned reference to the same immutable native tensor.
No values are copied. Both owners must be closed independently.

#### Errors

1 for an empty source, NULL output, or occupied output slot.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor), [error_message](#error_message-ptri8).

### `tensor_close(tensor: ptr<Tensor>)`

Release one owned wrapper and clear its handle.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `ptr<Tensor>` | Pointer to an owned or empty wrapper; NULL is a no-op. |

#### Returns

nothing. Release its native reference and set the handle to NULL.
Repeated close is safe. Do not close the last owner concurrently with use.
Cloned owners remain valid. Call this on all success and error cleanup paths.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [error_message](#error_message-ptri8).

## Inspection

### `tensor_count(tensor: Tensor) -> u64`

Query the logical element count.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `Tensor` | Live or empty wrapper; an empty wrapper returns zero. |

#### Returns

logical element count; empty/closed wrapper returns zero. A
rank-zero scalar counts as one. This is a query, not a status result; a zero
count cannot distinguish an empty tensor from an empty wrapper.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor).

### `tensor_values(tensor: Tensor, output: ptr<f64>, count: u64) -> i32`

Copy logical values into caller-owned storage.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `Tensor` | Live source wrapper. |
| `output` | `ptr<f64>` | Aligned writable non-overlapping buffer; NULL for zero elements. |
| `count` | `u64` | Output capacity in f64 elements, at least tensor_count(tensor). |

#### Returns

0 after copying flat logical row-major values.

#### Errors

invalid handle/buffer, overlap, or insufficient capacity (8).
It neither consumes the tensor nor transfers storage ownership.

#### Notes

live wrapper and aligned caller-owned output buffer; `count`
is capacity in doubles, at least `tensor_count(tensor)`. It must not overlap
native input storage. A NULL buffer is allowed for zero elements.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor).

## Calculations

These wrappers use the existing runtime and disable cancellation (NULL C
context). Construct an input or call `initialize()` first. Common native failures
include unavailable runtime, allocation, and non-finite arithmetic.

### `tensor_sum(tensor: Tensor, output: ptr<f64>) -> i32`

Sum all logical tensor elements.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `Tensor` | Live input wrapper. |
| `output` | `ptr<f64>` | Aligned writable scalar slot; valid only on success. |

#### Returns

0 with the sum of every logical element, or zero for an empty tensor.

#### Errors

invalid pointers/handle or common native failures.
The input owner remains unchanged.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor).

### `tensor_dot(a: Tensor, b: Tensor, output: ptr<f64>) -> i32`

Reduce corresponding products to one scalar.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `a` | `Tensor` | Live first wrapper. |
| `b` | `Tensor` | Live second wrapper with identical shape. |
| `output` | `ptr<f64>` | Aligned writable scalar slot; valid only on success. |

#### Returns

0 with the sum of elementwise products; matching empty tensors give
zero.

#### Errors

shape mismatch, invalid pointers/handles, or common native
failures. This is a scalar reduction, not matrix multiplication.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor).

### `tensor_add(a: Tensor, b: Tensor, output: ptr<Tensor>) -> i32`

Add identically shaped tensors element by element.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `a` | `Tensor` | Live first wrapper. |
| `b` | `Tensor` | Live second wrapper with identical shape; no broadcasting. |
| `output` | `ptr<Tensor>` | Non-NULL pointer to an empty result wrapper. |

#### Returns

0 with a new owned elementwise sum. Inputs remain unchanged; there
is no broadcasting.

#### Errors

occupied/NULL output, shape mismatch, invalid
handles, or common native failures. Close the result independently of its inputs.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor).

### `tensor_matmul(a: Tensor, b: Tensor, output: ptr<Tensor>) -> i32`

Multiply two dense rank-two matrices.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `a` | `Tensor` | Live left matrix of shape (m, k). |
| `b` | `Tensor` | Live right matrix of shape (k, n). |
| `output` | `ptr<Tensor>` | Non-NULL pointer to an empty wrapper; result shape is (m, n). |

#### Returns

0 with a new owned `(m,n)` dense product.

#### Errors

invalid/occupied output, rank/inner-dimension mismatch, element/work
bounds (at most 16,777,216 scalar multiply-add steps), or common native failures.
Batched and broadcasted matrix products are not exposed by this wrapper.

#### See also

[tensor_copy](#tensor_copydata-ptrf64-count-u64-shape-ptru64-rank-u64-output-ptrtensor-i32), [tensor_clone](#tensor_clonesource-tensor-output-ptrtensor-i32), [tensor_close](#tensor_closetensor-ptrtensor).

## Example with cleanup

Place this file beside the binding, then use the compiler/linker setup in the
[Wave guide](../guides/wave.md).

```wave
import("./hmath")::{Tensor, tensor_empty, vector_copy, tensor_sum, tensor_close};

fun main() -> i32 {
    var samples: array<f64, 3> = [1.0, 2.0, 3.0];
    var tensor: Tensor = tensor_empty();
    var total: f64 = 0.0;
    var status: i32 = vector_copy(&samples[0], 3, &tensor);
    if (status == 0) {
        status = tensor_sum(tensor, &total);
    }
    tensor_close(&tensor);
    if (status != 0 || total != 6.0) {
        return 1;
    }
    return 0;
}
```

The lower-level `extern(c, ...)` declarations support these wrappers. Their
contracts are the corresponding [C ABI functions](c.md). The process owner,
rather than each Wave tensor, controls final runtime shutdown.
