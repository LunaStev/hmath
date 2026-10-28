# C ABI

Include `hmath.h` for the stable ABI-1 interface and `hmath_dlpack.h` for
DLPack exchange. The ABI epoch is independent of package release numbers.
The [C integration guide](../guides/c.md) gives a complete compilable client.

## Types, bounds, and ownership

`hmath_tensor` and `hmath_context` are opaque reference-counted handles.
`hmath_vector` and `hmath_matrix` alias `hmath_tensor`; their constructors select
rank one and two. Every successful constructor/result owns **one reference**.
Retain before handing an additional owner to another thread. Never release your
last reference concurrently with its use. NULL retain/release is harmless;
other pointers must identify live objects and correctly sized buffers.

Elements are finite IEEE binary64 (`double`). `HMATH_MAX_RANK` is 8 and
`HMATH_MAX_ELEMENTS` is 1,048,576. Shapes/strides are `size_t` arrays; strides
count **elements**, not bytes, and must be nonnegative. Rank zero has one
element; zero-sized dimensions are allowed. Shapes, products, reachable storage
spans, and numerical work are bounded. C cannot verify arbitrary addresses or
the actual allocation behind a supplied buffer.

Checked functions return `hmath_status`. `HMATH_OK` (0) is success; otherwise
read `hmath_last_error_message()` immediately on the same thread. The status
[table](python.md#native-status-codes) lists every code. Kernel failures can
include runtime unavailable, cancellation, contained Haskell exceptions, and
non-finite arithmetic. Constructors clear their output handle to NULL on error;
scalar outputs are written only on success. Never pass a live owned handle as
an output slot without releasing it first.

Metadata, allocation, and ownership operations do not require an initialized
GHC runtime. Numerical kernels require successful `hmath_init()`. A NULL
kernel context disables cancellation. Cancellation is cooperative before/after
bounded Haskell kernels, and between callback elements. It does not forcibly
interrupt a running Haskell kernel.

## Version and diagnostics

### `hmath_abi_version`

`uint32_t hmath_abi_version(void)`

**Parameters:** none. **Returns:** ABI epoch, currently 1. Compare against
`HMATH_ABI_VERSION` before using the interface. No initialization or allocation
is needed. Example: `if (hmath_abi_version() != HMATH_ABI_VERSION) return 1;`.

### `hmath_library_version`

`const char *hmath_library_version(void)`

**Parameters:** none. **Returns:** a borrowed, immutable, NUL-terminated package
version string, such as `"1.0.1"`. Do not free it. No runtime initialization
is needed. Use for diagnostics rather than ABI negotiation.

### `hmath_build_info`

`const char *hmath_build_info(void)`

**Parameters:** none. **Returns:** a borrowed static description of the native
build (C11, threaded GHC runtime, binary64, rank bound). Do not free or parse it
as a stable machine-readable schema. Example: `puts(hmath_build_info());`.

### `hmath_backend_version`

`const char *hmath_backend_version(void)`

**Parameters:** none. **Returns:** a borrowed static description of the backend
used by the C tensor kernels. This describes those kernels, independently of
Haskell's separately selected BLAS/LAPACK providers. Do not free it.

### `hmath_last_error_code`

`hmath_status hmath_last_error_code(void)`

**Parameters:** none. **Returns:** the current thread's last checked status.
Queries, retain/release, and cancellation do not clear it. Successful checked
calls replace it with `HMATH_OK`. It does not return another thread's failure.

### `hmath_last_error_message`

`const char *hmath_last_error_message(void)`

**Parameters:** none. **Returns:** a borrowed thread-local NUL-terminated error
message, valid until the next checked operation on this thread. Copy it before
another checked call if it must survive. Do not free it.

### `hmath_status_string`

`const char *hmath_status_string(hmath_status status)`

**Parameters:** a status code. **Returns:** its borrowed static generic label;
unknown codes return `"unknown status"`. This does not replace the more specific
thread-local diagnostic. Example: `puts(hmath_status_string(HMATH_SHAPE_ERROR));`.

## Runtime

### `hmath_init`

`int hmath_init(void)`

**Parameters:** none. **Returns:** `HMATH_INIT_OK` (0) on successful or repeated
initialization; `HMATH_INIT_ALREADY_SHUT_DOWN` (1) after final shutdown. HMath
owns its GHC runtime: do not combine it with independently initialized GHC
libraries. Call before numerical kernels: `if (hmath_init() != 0) return 1;`.

### `hmath_runtime_shutdown`

`hmath_status hmath_runtime_shutdown(void)`

**Parameters:** none. **Returns:** `HMATH_OK` after final shutdown or `HMATH_BUSY`
while a checked/legacy call or callback is active. Join workers, then retry a
busy result. Successful shutdown is irreversible; only the process owner
should invoke it. Release owned resources before shutdown.

### `hmath_shutdown`

`void hmath_shutdown(void)`

**Parameters:** none. **Returns:** nothing. Legacy wrapper around final shutdown;
if busy, leaves the runtime running and records the error. Prefer the checked
`hmath_runtime_shutdown()` for new clients; otherwise inspect the last error.

## Cancellation contexts

### `hmath_context_create`

`hmath_status hmath_context_create(hmath_context **out)`

**Parameters:** non-NULL output slot. **Returns:** `HMATH_OK` and one owned,
initially uncancelled context. **Errors:** invalid output pointer or allocation
failure (NULL result). Example: `hmath_context *ctx = NULL;` followed by
`hmath_context_create(&ctx)`; release the context after its users finish.

### `hmath_context_retain`

`void hmath_context_retain(hmath_context *context)`

**Parameters:** a live context or NULL. **Returns:** nothing; adds one owned
reference, or does nothing for NULL. Retain before giving a second owner access.
This does not reset cancellation or update the last diagnostic.

### `hmath_context_release`

`void hmath_context_release(hmath_context *context)`

**Parameters:** an owned context reference or NULL. **Returns:** nothing;
destroys it on final release. Every successful create/retain needs one release.
Do not release the final reference while a kernel still uses this context.

### `hmath_context_cancel`

`void hmath_context_cancel(hmath_context *context)`

**Parameters:** a live context or NULL. **Returns:** nothing. Atomically requests
cancellation of current/future work using this context. NULL is a no-op. It is
safe to request cancellation from another thread; the caller must keep its
reference alive. Does not clear the error message.

### `hmath_context_reset`

`void hmath_context_reset(hmath_context *context)`

**Parameters:** a live context or NULL. **Returns:** nothing. Clear the cancelled
flag for reuse, **only after no operation is using the context**. NULL is a
no-op. Reset does not restart a shut down runtime.

## Tensor construction

### `hmath_tensor_copy`

`hmath_status hmath_tensor_copy(const double *data, size_t count, const size_t *shape, size_t rank, hmath_tensor **out)`

**Parameters:** `count` readable finite doubles, `rank` dimensions, and a non-NULL
output slot. `count` must equal the shape product; NULL data is allowed only
for zero elements, and NULL shape for rank zero.
**Returns:** one owned contiguous row-major copy. The caller retains ownership
of the input. **Errors:** invalid pointers/data, shape/count mismatch, exceeded
bounds, or allocation failure. See the complete example below.

### `hmath_tensor_borrow`

`hmath_status hmath_tensor_borrow(const double *data, size_t storage_count, const size_t *shape, const size_t *strides, size_t rank, hmath_buffer_deleter deleter, void *userdata, hmath_tensor **out)`

**Parameters:** aligned immutable storage containing `storage_count` readable
doubles; shape and optional element strides (NULL means row-major); optional
`deleter(userdata, data)` and its borrowed userdata; output slot. All reachable
offsets must fit the storage. Keep data and userdata live/immutable until release.
**Returns:** one owned zero-copy tensor. On final storage release, invokes the
deleter exactly once on the releasing thread. The callback must not throw or
call shutdown. **Errors:** invalid/non-finite storage, shape/span/budget violation,
or allocation failure. Failure does not consume input ownership or call the deleter.
Example: borrow a static `const double[3]` with shape `{3}`, NULL strides/deleter.

### `hmath_vector_copy`

`hmath_status hmath_vector_copy(const double *data, size_t count, hmath_vector **out)`

**Parameters:** `count` readable finite doubles and output slot.
**Returns:** a new owned contiguous tensor with shape `(count)`.
**Errors:** the same input, budget, and allocation errors as `hmath_tensor_copy`.
Example: `hmath_vector_copy(values, 3, &vector)`.

### `hmath_matrix_copy`

`hmath_status hmath_matrix_copy(const double *data, size_t count, size_t rows, size_t columns, hmath_matrix **out)`

**Parameters:** flat row-major data, its count, two dimensions, and output slot.
**Returns:** a new owned `(rows, columns)` tensor.
**Errors:** construction errors, including `count != rows * columns`.
Example: `hmath_matrix_copy(values, 6, 2, 3, &matrix)`.

## Tensor ownership and inspection

### `hmath_tensor_retain`

`void hmath_tensor_retain(hmath_tensor *tensor)`

**Parameters:** a live tensor or NULL. **Returns:** nothing; adds one owned
reference for a new owner, or does nothing for NULL. It copies no values.
Balance each retain with a release. Does not change the last diagnostic.

### `hmath_tensor_release`

`void hmath_tensor_release(hmath_tensor *tensor)`

**Parameters:** an owned reference or NULL. **Returns:** nothing; final release
frees the handle and, when no storage owners remain, its data/deleter. NULL is
allowed; releasing the same non-NULL reference twice is invalid. Reset your
variable to NULL after release to avoid accidental reuse.

### `hmath_tensor_rank`

`size_t hmath_tensor_rank(const hmath_tensor *tensor)`

**Parameters:** a live tensor or NULL. **Returns:** its dimension count; NULL
returns zero. A real rank-zero scalar also returns zero: this is not an error
check. No initialization or ownership transfer occurs.

### `hmath_tensor_count`

`size_t hmath_tensor_count(const hmath_tensor *tensor)`

**Parameters:** a live tensor or NULL. **Returns:** its logical element count;
NULL returns zero. Scalars count as one; empty tensors count as zero. The count
can differ from the storage span for strided input.

### `hmath_tensor_metadata`

`hmath_status hmath_tensor_metadata(const hmath_tensor *tensor, size_t *shape, size_t *strides, size_t capacity)`

**Parameters:** live tensor, two caller-owned output arrays, and capacity in
entries (at least rank). Both arrays may be NULL for rank zero.
**Returns:** `HMATH_OK` after writing dimensions and element strides.
**Errors:** invalid tensor/arrays or `HMATH_BOUNDS_ERROR` for insufficient capacity.
Example: use `size_t shape[HMATH_MAX_RANK], strides[HMATH_MAX_RANK];`.

### `hmath_tensor_copy_to`

`hmath_status hmath_tensor_copy_to(const hmath_tensor *tensor, double *out, size_t capacity)`

**Parameters:** live tensor and aligned destination with at least `count`
entries. The output must not overlap input storage; NULL is allowed for empty
output. **Returns:** a logical row-major copy in the caller's buffer.
**Errors:** invalid/overlapping buffer or insufficient capacity. No ownership
transfer occurs. Example: copy a six-element tensor into `double out[6]`.

### `hmath_tensor_data`

`hmath_status hmath_tensor_data(const hmath_tensor *tensor, const double **data, size_t *storage_count)`

**Parameters:** live tensor and two non-NULL output slots.
**Returns:** a **borrowed read-only** storage pointer and underlying storage
size. Use metadata strides for logical indexing; the storage need not be compact.
The pointer is valid only while storage ownership is retained. Do not free it.
**Errors:** NULL tensor or output slots. No allocation or copying occurs.

### `hmath_tensor_reshape`

`hmath_status hmath_tensor_reshape(const hmath_tensor *tensor, const size_t *shape, size_t rank, hmath_tensor **out)`

**Parameters:** live contiguous tensor, new dimensions, and output slot.
**Returns:** a new owned handle sharing storage with the original.
**Errors:** invalid shape, changed element count, non-contiguous input, or
allocation failure. No `-1` dimension inference. Example: reshape a length-six
vector to shape `{2, 3}`; both handles require independent release.

## Raw allocation

### `hmath_buffer_alloc`

`hmath_status hmath_buffer_alloc(size_t bytes, size_t alignment, void **out)`

**Parameters:** requested byte count, power-of-two alignment in
`[sizeof(void *), 4096]`, and non-NULL output slot. Zero bytes is valid.
**Returns:** one owned aligned allocation; release **only** with
`hmath_buffer_free`. **Errors:** invalid alignment, size exceeding
`HMATH_MAX_ELEMENTS * sizeof(double)`, arithmetic overflow, or allocation failure.
Example: `hmath_buffer_alloc(3 * sizeof(double), 64, &buffer)`.

### `hmath_buffer_free`

`void hmath_buffer_free(void *buffer)`

**Parameters:** a pointer returned by `hmath_buffer_alloc`, or NULL.
**Returns:** nothing; frees that allocation. Never pass a tensor's borrowed data
pointer or an allocation from another allocator. Free each non-NULL allocation once.

## Checked numerical kernels

### `hmath_scalar_add`

`hmath_status hmath_scalar_add(hmath_context *context, double a, double b, double *out)`

**Parameters:** optional context, two finite scalars, and aligned output pointer.
**Returns:** `HMATH_OK` with their sum in `*out`.
**Errors:** invalid/non-finite input, non-finite result, or common kernel failures.
Example: `hmath_scalar_add(NULL, 2.0, 3.0, &result)` writes `5.0` on success.

### `hmath_tensor_sum`

`hmath_status hmath_tensor_sum(hmath_context *context, const hmath_tensor *tensor, double *out)`

**Parameters:** optional context, live tensor, aligned scalar output.
**Returns:** sum of all logical elements; empty sum is zero.
**Errors:** invalid arguments, non-finite arithmetic, or common kernel failures.
Neither input nor ownership is modified. See the example below.

### `hmath_tensor_dot`

`hmath_status hmath_tensor_dot(hmath_context *context, const hmath_tensor *a, const hmath_tensor *b, double *out)`

**Parameters:** optional context, two live identically shaped tensors, scalar output.
**Returns:** sum of corresponding products across all dimensions, zero for
matching empty tensors. **Errors:** invalid arguments, unequal shapes,
non-finite arithmetic, or common kernel failures. This is not matrix multiplication.

### `hmath_tensor_add`

`hmath_status hmath_tensor_add(hmath_context *context, const hmath_tensor *a, const hmath_tensor *b, hmath_tensor **out)`

**Parameters:** optional context, identically shaped live tensors, output slot.
**Returns:** a new owned elementwise sum; inputs unchanged. No broadcasting.
**Errors:** invalid arguments, shape mismatch, allocation/arithmetic or common
kernel failures. For `[1, 2]` and `[3, 4]`, the result contains `[4, 6]`.

### `hmath_tensor_matmul`

`hmath_status hmath_tensor_matmul(hmath_context *context, const hmath_tensor *a, const hmath_tensor *b, hmath_tensor **out)`

**Parameters:** optional context, rank-two `(m,k)` and `(k,n)` tensors, output slot.
**Returns:** a new owned `(m,n)` matrix product. Work must not exceed
16,777,216 scalar multiply-add steps.
**Errors:** invalid arguments, rank/inner-dimension mismatch, work/size bound,
allocation/arithmetic, or common kernel failures. Inputs remain unchanged.

### `hmath_tensor_map`

`hmath_status hmath_tensor_map(hmath_context *context, const hmath_tensor *tensor, hmath_map_callback callback, void *userdata, hmath_tensor **out)`

**Parameters:** optional context, live input, callback, borrowed userdata, output.
The callback receives `(double value, size_t index, void *userdata, double *result)`
in logical row-major order, writes one finite result, and returns a status.
**Returns:** a new owned tensor of the original shape only if every callback
succeeds. **Errors:** callback status, invalid callback/input, cancellation,
non-finite output, allocation, or runtime failure. Partial results are discarded.
Callbacks are synchronous, may reenter checked calls, must not throw across C,
and must not shut down the runtime. Userdata need only outlive this call.

### `hmath_batch_sum`

`hmath_status hmath_batch_sum(hmath_context *context, const hmath_tensor *const *inputs, size_t count, double *out, size_t *completed)`

**Parameters:** optional context, arrays of `count` live tensor pointers and
scalar output slots, and aligned non-NULL progress pointer. `count <= 4096`.
**Returns:** `HMATH_OK` after all reductions; `*completed == count`.
**Errors:** invalid arrays/bounds or a reduction failure. Unlike atomic tensor
kernels, entries `out[0 .. *completed)` remain valid after failure; later output
slots are untouched. Count zero permits NULL input/output arrays. Initialize
progress storage even for an empty batch: `size_t completed = 0;`.

## Legacy numerical interface

Prefer checked functions when available. Legacy numerical calls still require
successful initialization. Invalid lifecycle returns NaN (`-1` for factorial).
All nonempty buffers must contain the declared readable number of doubles;
counts must fit Haskell `Int`.

### `hmath_add_f64`

`double hmath_add_f64(double a, double b)`

**Parameters:** two doubles. **Returns:** their legacy scalar sum. Invalid
lifecycle returns NaN. Unlike the checked interface, this retains legacy
floating-point behavior without a status result. Example: `hmath_add_f64(2, 3)`.

### `hmath_factorial`

`long long hmath_factorial(int n)`

**Parameters:** integer `n` in `[0,20]`.
**Returns:** `n!`, including `0! == 1`; `-1` outside the range or with invalid
lifecycle. Example: `hmath_factorial(5)` returns 120.

### `hmath_mean_f64`

`double hmath_mean_f64(const double *values, size_t count)`

**Parameters:** a readable double array and count. **Returns:** arithmetic mean;
empty or NULL input, or invalid lifecycle, returns NaN. Example: `{2,4}` gives 3.
No handle ownership is transferred.

### `hmath_dot_f64`

`double hmath_dot_f64(const double *a, const double *b, size_t count)`

**Parameters:** two readable double arrays of equal declared count.
**Returns:** sum of products; empty input gives zero, nonempty NULL input or
invalid lifecycle gives NaN. Example: `{1,2}` dotted with `{3,4}` gives 11.

## DLPack exchange

Include `hmath_dlpack.h` and the producer's official `dlpack/dlpack.h` for the
managed tensor structs. Only CPU device 0, native-endian binary64, one lane,
and rank at most 8 are supported. Negative strides, unsupported devices/dtypes,
and unknown versioned flags are rejected. Imported storage must remain immutable.

### `hmath_dlpack_export`

`hmath_status hmath_dlpack_export(const hmath_tensor *tensor, struct DLManagedTensor **out)`

**Parameters:** live input and non-NULL managed-tensor output slot.
**Returns:** an owned legacy DLPack **copy**, because legacy DLPack cannot express
read-only storage. The recipient must invoke its deleter exactly once. The
HMath input can then be released independently.
**Errors:** invalid input/output, size/layout, or allocation failure.

### `hmath_dlpack_import`

`hmath_status hmath_dlpack_import(struct DLManagedTensor *tensor, size_t storage_elements, hmath_tensor **out)`

**Parameters:** producer-owned managed tensor, count of readable double elements
**after `byte_offset`**, and output slot. The caller guarantees this count;
DLPack itself carries no allocation size.
**Returns:** one owned HMath tensor and consumes managed-tensor ownership **only
on success**; final HMath storage release calls the producer's deleter.
**Errors:** invalid/unsupported metadata, insufficient storage span, non-finite
data, bounds, or allocation failure. On failure the caller still owns the managed tensor.

### `hmath_dlpack_export_versioned`

`hmath_status hmath_dlpack_export_versioned(const hmath_tensor *tensor, struct DLManagedTensorVersioned **out)`

**Parameters:** live input and output slot.
**Returns:** an owned versioned zero-copy DLPack view with the read-only flag set.
It retains storage independently of the original HMath handle; invoke the
managed view's deleter exactly once. **Errors:** invalid arguments or allocation failure.

### `hmath_dlpack_import_versioned`

`hmath_status hmath_dlpack_import_versioned(struct DLManagedTensorVersioned *tensor, size_t storage_elements, hmath_tensor **out)`

**Parameters:** versioned managed tensor, readable element count after byte offset,
and output slot. **Returns:** one owned HMath tensor, consuming producer ownership
only on success. **Errors:** legacy import validation failures plus unsupported
DLPack version or flags. Do not mutate the imported storage through any alias
while the resulting storage is retained.

## Complete checked example

```c
#include <hmath.h>
#include <stdio.h>

int main(void) {
    hmath_tensor *tensor = NULL;
    const double values[] = {1.0, 2.0, 3.0};
    const size_t shape[] = {3};
    double total = 0.0;
    hmath_status status;
    if (hmath_abi_version() != HMATH_ABI_VERSION || hmath_init() != 0) return 1;
    status = hmath_tensor_copy(values, 3, shape, 1, &tensor);
    if (status == HMATH_OK) status = hmath_tensor_sum(NULL, tensor, &total);
    if (status != HMATH_OK) fprintf(stderr, "%s\n", hmath_last_error_message());
    hmath_tensor_release(tensor);
    if (status != HMATH_OK) return 1;
    printf("%.1f\n", total); /* 6.0 */
    return hmath_runtime_shutdown() == HMATH_OK ? 0 : 1;
}
```

## Backend adapter boundary

`hmath_backend.h` defines the **internal** BLAS/LAPACK provider bridge used by
Haskell. Its `hmath_backend_*` adapter entry points are not part of this stable
public tensor ABI. The supported Haskell provider API is documented under
`HMath.Backend` in the [Haskell reference](haskell.md).
