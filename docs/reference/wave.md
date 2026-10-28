# Wave API

The Wave 0.2.1 binding targets **64-bit systems** where C `size_t` matches Wave
`u64`. Import `bindings/wave/hmath.wave` beside your source as shown in the
[Wave integration guide](../guides/wave.md). All numerical values are `f64`.

## Shared rules

`Tensor { handle: ptr<u8> }` owns one native reference. Treat owners linearly:
plain struct assignment does **not** retain a second reference. Use
`tensor_clone`, and close every owner, including those created before a later
failure. Keep all input handles live throughout a call.

Status-returning wrappers return `i32`: zero means success. The C
[status table](python.md#native-status-codes) defines the other values. Read
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

**Parameters:** none. Check ABI 1 and initialize the shared runtime.
**Returns:** 0 on success, 10 for unsupported ABI, 5 after irreversible shutdown.
Repeated initialization is allowed. Constructors and `scalar_add` call this
automatically. It does not create a tensor or an ownership obligation.

### `error_message() -> ptr<i8>`

**Parameters:** none. **Returns:** a borrowed, NUL-terminated thread-local
native error string. It remains valid until the next checked C call on this
thread. Copy it before that call if it must survive; never free it.
Wrapper-only validation does not set a fresh message; see the shared rules.

### `scalar_add(a: f64, b: f64, output: ptr<f64>) -> i32`

**Parameters:** two finite scalars and a valid aligned scalar output pointer.
**Returns:** status 0 and their sum in `output` after automatic initialization.
**Errors:** invalid/non-finite input or result, initialization or native runtime
failure. Example: `scalar_add(2.0, 3.0, &value)` writes 5.0 on success.

## Construction and ownership

### `tensor_empty() -> Tensor`

**Parameters:** none. **Returns:** `Tensor { handle: null }`, with no native
reference to release. Use this to initialize every result slot before passing
its address to a constructor, clone, add, or matrix multiplication.

### `tensor_copy(data: ptr<f64>, count: u64, shape: ptr<u64>, rank: u64, output: ptr<Tensor>) -> i32`

**Parameters:** `count` readable finite doubles, `rank` dimensions, and empty
output wrapper. Count must equal the dimension product. Rank zero contains one
value; zero dimensions allow an empty tensor. Data must remain readable during
this synchronous call.
**Returns:** status 0 and a new owned row-major copy; input ownership is unchanged.
**Errors:** occupied/NULL output, invalid storage/dimensions, count mismatch,
size bound, initialization, or allocation failure.

### `vector_copy(data: ptr<f64>, count: u64, output: ptr<Tensor>) -> i32`

**Parameters:** readable values and their count, plus empty output wrapper.
**Returns:** status 0 and a new owned rank-one tensor of length `count`.
**Errors:** the same construction errors as `tensor_copy`.
The values are copied, so the source can be reused once the call returns.

### `matrix_copy(data: ptr<f64>, count: u64, rows: u64, columns: u64, output: ptr<Tensor>) -> i32`

**Parameters:** row-major values, count, two dimensions, empty output wrapper.
**Returns:** status 0 and a new owned rank-two matrix.
**Errors:** construction errors, including `count != rows * columns`.
For `{1,2,3,4}`, dimensions 2 by 2 create rows `[1,2]` and `[3,4]`.

### `tensor_clone(source: Tensor, output: ptr<Tensor>) -> i32`

**Parameters:** a live source and non-NULL empty result wrapper.
**Returns:** 0 and a second owned reference to the same immutable native tensor.
No values are copied. Both owners must be closed independently.
**Errors:** 1 for an empty source, NULL output, or occupied output slot.

### `tensor_close(tensor: ptr<Tensor>)`

**Parameters:** pointer to an owned or empty wrapper; NULL is also allowed.
**Returns:** nothing. Release its native reference and set the handle to NULL.
Repeated close is safe. Do not close the last owner concurrently with use.
Cloned owners remain valid. Call this on all success and error cleanup paths.

## Inspection

### `tensor_count(tensor: Tensor) -> u64`

**Parameters:** live or empty wrapper.
**Returns:** logical element count; empty/closed wrapper returns zero. A
rank-zero scalar counts as one. This is a query, not a status result; a zero
count cannot distinguish an empty tensor from an empty wrapper.

### `tensor_values(tensor: Tensor, output: ptr<f64>, count: u64) -> i32`

**Parameters:** live wrapper and aligned caller-owned output buffer; `count`
is capacity in doubles, at least `tensor_count(tensor)`. It must not overlap
native input storage. A NULL buffer is allowed for zero elements.
**Returns:** 0 after copying flat logical row-major values.
**Errors:** invalid handle/buffer, overlap, or insufficient capacity (8).
It neither consumes the tensor nor transfers storage ownership.

## Calculations

These wrappers use the existing runtime and disable cancellation (NULL C
context). Construct an input or call `initialize()` first. Common native failures
include unavailable runtime, allocation, and non-finite arithmetic.

### `tensor_sum(tensor: Tensor, output: ptr<f64>) -> i32`

**Parameters:** live input and aligned scalar output pointer.
**Returns:** 0 with the sum of every logical element, or zero for an empty tensor.
**Errors:** invalid pointers/handle or common native failures.
The input owner remains unchanged.

### `tensor_dot(a: Tensor, b: Tensor, output: ptr<f64>) -> i32`

**Parameters:** live tensors with identical shapes and scalar output pointer.
**Returns:** 0 with the sum of elementwise products; matching empty tensors give
zero. **Errors:** shape mismatch, invalid pointers/handles, or common native
failures. This is a scalar reduction, not matrix multiplication.

### `tensor_add(a: Tensor, b: Tensor, output: ptr<Tensor>) -> i32`

**Parameters:** live tensors of identical shape and empty result wrapper.
**Returns:** 0 with a new owned elementwise sum. Inputs remain unchanged; there
is no broadcasting. **Errors:** occupied/NULL output, shape mismatch, invalid
handles, or common native failures. Close the result independently of its inputs.

### `tensor_matmul(a: Tensor, b: Tensor, output: ptr<Tensor>) -> i32`

**Parameters:** live rank-two matrices of shapes `(m,k)` and `(k,n)`, and empty
result wrapper. **Returns:** 0 with a new owned `(m,n)` dense product.
**Errors:** invalid/occupied output, rank/inner-dimension mismatch, element/work
bounds (at most 16,777,216 scalar multiply-add steps), or common native failures.
Batched and broadcasted matrix products are not exposed by this wrapper.

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
