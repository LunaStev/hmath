# C ABI

Include `hmath.h` for the stable ABI-1 interface and `hmath_dlpack.h` for
DLPack exchange. The ABI epoch is independent of package release numbers.
The [C integration guide](../guides/c.md) gives a complete compilable client.

## Function index

| API | Purpose |
| --- | --- |
| [hmath_abi_version](#hmath_abi_version) | Query the C ABI epoch. |
| [hmath_library_version](#hmath_library_version) | Query the package version for diagnostics. |
| [hmath_build_info](#hmath_build_info) | Describe the native build configuration. |
| [hmath_backend_version](#hmath_backend_version) | Describe the backend used by native tensor kernels. |
| [hmath_last_error_code](#hmath_last_error_code) | Read this thread’s most recent checked status. |
| [hmath_last_error_message](#hmath_last_error_message) | Read this thread’s most recent checked diagnostic. |
| [hmath_status_string](#hmath_status_string) | Describe a status code without changing the thread diagnostic. |
| [hmath_init](#hmath_init) | Initialize the process-owned Haskell runtime. |
| [hmath_runtime_shutdown](#hmath_runtime_shutdown) | Request final shutdown after all numerical users have finished. |
| [hmath_shutdown](#hmath_shutdown) | Invoke the legacy shutdown wrapper. |
| [hmath_context_create](#hmath_context_create) | Create a cancellation context. |
| [hmath_context_retain](#hmath_context_retain) | Acquire one additional reference to a cancellation context. |
| [hmath_context_release](#hmath_context_release) | Release one owned cancellation-context reference. |
| [hmath_context_cancel](#hmath_context_cancel) | Request cooperative cancellation. |
| [hmath_context_reset](#hmath_context_reset) | Clear cancellation after the context becomes idle. |
| [hmath_tensor_copy](#hmath_tensor_copy) | Copy row-major values into a new tensor. |
| [hmath_tensor_borrow](#hmath_tensor_borrow) | Create an immutable tensor over caller-provided storage. |
| [hmath_vector_copy](#hmath_vector_copy) | Copy values into a rank-one tensor. |
| [hmath_matrix_copy](#hmath_matrix_copy) | Copy row-major values into a rank-two tensor. |
| [hmath_tensor_retain](#hmath_tensor_retain) | Acquire one additional reference to an existing tensor. |
| [hmath_tensor_release](#hmath_tensor_release) | Release one owned tensor reference. |
| [hmath_tensor_rank](#hmath_tensor_rank) | Query the number of dimensions. |
| [hmath_tensor_count](#hmath_tensor_count) | Query the logical element count. |
| [hmath_tensor_metadata](#hmath_tensor_metadata) | Copy dimensions and element strides to caller-owned arrays. |
| [hmath_tensor_copy_to](#hmath_tensor_copy_to) | Copy logical values to independent row-major storage. |
| [hmath_tensor_data](#hmath_tensor_data) | Borrow a read-only pointer to underlying tensor storage. |
| [hmath_tensor_reshape](#hmath_tensor_reshape) | Create a new handle sharing contiguous storage with a new shape. |
| [hmath_buffer_alloc](#hmath_buffer_alloc) | Allocate aligned storage using the HMath allocator. |
| [hmath_buffer_free](#hmath_buffer_free) | Free storage allocated by hmath_buffer_alloc. |
| [hmath_scalar_add](#hmath_scalar_add) | Add two finite real scalars. |
| [hmath_tensor_sum](#hmath_tensor_sum) | Reduce all logical elements to one scalar. |
| [hmath_tensor_dot](#hmath_tensor_dot) | Reduce corresponding products over identically shaped tensors. |
| [hmath_tensor_add](#hmath_tensor_add) | Add identically shaped tensors element by element. |
| [hmath_tensor_matmul](#hmath_tensor_matmul) | Multiply two dense rank-two matrices. |
| [hmath_tensor_map](#hmath_tensor_map) | Apply a synchronous checked callback to each logical element. |
| [hmath_batch_sum](#hmath_batch_sum) | Sum multiple tensors with explicit partial progress. |
| [hmath_add_f64](#hmath_add_f64) | Add scalars using the legacy numerical interface. |
| [hmath_factorial](#hmath_factorial) | Compute a legacy bounded integer factorial. |
| [hmath_mean_f64](#hmath_mean_f64) | Compute a legacy arithmetic mean. |
| [hmath_dot_f64](#hmath_dot_f64) | Compute a legacy dot product of flat arrays. |
| [hmath_dlpack_export](#hmath_dlpack_export) | Export a writable legacy DLPack copy. |
| [hmath_dlpack_import](#hmath_dlpack_import) | Consume a supported legacy DLPack tensor on successful import. |
| [hmath_dlpack_export_versioned](#hmath_dlpack_export_versioned) | Export a retained read-only versioned DLPack view. |
| [hmath_dlpack_import_versioned](#hmath_dlpack_import_versioned) | Consume a supported versioned DLPack tensor on success. |

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
[table](#native-status-codes) lists every code. Kernel failures can
include runtime unavailable, cancellation, contained Haskell exceptions, and
non-finite arithmetic. Constructors clear their output handle to NULL on error;
scalar outputs are written only on success. Never pass a live owned handle as
an output slot without releasing it first.

Metadata, allocation, and ownership operations do not require an initialized
GHC runtime. Numerical kernels require successful `hmath_init()`. A NULL
kernel context disables cancellation. Cancellation is cooperative before/after
bounded Haskell kernels, and between callback elements. It does not forcibly
interrupt a running Haskell kernel.

## Native status codes

| Code | Name | Meaning |
| --- | --- | --- |
| 0 | `HMATH_OK` | Success |
| 1 | `HMATH_INVALID_ARGUMENT` | Invalid argument |
| 2 | `HMATH_SHAPE_ERROR` | Invalid or incompatible dimensions |
| 3 | `HMATH_OVERFLOW` | Arithmetic or size overflow |
| 4 | `HMATH_ALLOCATION_FAILED` | Allocation failed |
| 5 | `HMATH_RUNTIME_ERROR` | Runtime unavailable |
| 6 | `HMATH_HASKELL_EXCEPTION` | Contained Haskell exception |
| 7 | `HMATH_CANCELLED` | Cooperative cancellation |
| 8 | `HMATH_BOUNDS_ERROR` | Buffer or metadata bounds error |
| 9 | `HMATH_BUSY` | Active work prevents shutdown |
| 10 | `HMATH_UNSUPPORTED` | Unsupported operation |

## Version and diagnostics

### `hmath_abi_version`

Query the C ABI epoch.

`uint32_t hmath_abi_version(void)`

#### Parameters

None.

#### Returns

ABI epoch, currently 1. Compare against
`HMATH_ABI_VERSION` before using the interface. No initialization or allocation
is needed. Example: `if (hmath_abi_version() != HMATH_ABI_VERSION) return 1;`.

#### See also

[hmath_library_version](#hmath_library_version), [hmath_init](#hmath_init).

### `hmath_library_version`

Query the package version for diagnostics.

`const char *hmath_library_version(void)`

#### Parameters

None.

#### Returns

a borrowed, immutable, NUL-terminated package
version string. Do not free it. No runtime initialization
is needed. Use for diagnostics rather than ABI negotiation.

#### See also

[hmath_abi_version](#hmath_abi_version), [hmath_build_info](#hmath_build_info).

### `hmath_build_info`

Describe the native build configuration.

`const char *hmath_build_info(void)`

#### Parameters

None.

#### Returns

a borrowed static description of the native
build (C11, threaded GHC runtime, binary64, rank bound). Do not free or parse it
as a stable machine-readable schema. Example: `puts(hmath_build_info());`.

#### See also

[hmath_backend_version](#hmath_backend_version), [hmath_abi_version](#hmath_abi_version).

### `hmath_backend_version`

Describe the backend used by native tensor kernels.

`const char *hmath_backend_version(void)`

#### Parameters

None.

#### Returns

a borrowed static description of the backend
used by the C tensor kernels. This describes those kernels, independently of
Haskell's separately selected BLAS/LAPACK providers. Do not free it.

#### See also

[hmath_build_info](#hmath_build_info).

### `hmath_last_error_code`

Read this thread’s most recent checked status.

`hmath_status hmath_last_error_code(void)`

#### Parameters

None.

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: the current thread's last checked status.
Queries, retain/release, and cancellation do not clear it. Successful checked
calls replace it with `HMATH_OK`. It does not return another thread's failure.

#### See also

[hmath_last_error_message](#hmath_last_error_message), [hmath_status_string](#hmath_status_string).

### `hmath_last_error_message`

Read this thread’s most recent checked diagnostic.

`const char *hmath_last_error_message(void)`

#### Parameters

None.

#### Returns

a borrowed thread-local NUL-terminated error
message, valid until the next checked operation on this thread. Copy it before
another checked call if it must survive. Do not free it.

#### See also

[hmath_last_error_code](#hmath_last_error_code), [hmath_status_string](#hmath_status_string).

### `hmath_status_string`

Describe a status code without changing the thread diagnostic.

`const char *hmath_status_string(hmath_status status)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `status` | `hmath_status` | Status value; unknown values have a generic label. |

#### Returns

its borrowed static generic label;
unknown codes return `"unknown status"`. This does not replace the more specific
thread-local diagnostic. Example: `puts(hmath_status_string(HMATH_SHAPE_ERROR));`.

#### See also

[hmath_last_error_message](#hmath_last_error_message), [hmath_last_error_code](#hmath_last_error_code).

## Runtime

### `hmath_init`

Initialize the process-owned Haskell runtime.

`int hmath_init(void)`

#### Parameters

None.

#### Returns

`HMATH_INIT_OK` (0) on successful or repeated
initialization; `HMATH_INIT_ALREADY_SHUT_DOWN` (1) after final shutdown. HMath
owns its GHC runtime: do not combine it with independently initialized GHC
libraries. Call before numerical kernels: `if (hmath_init() != 0) return 1;`.

#### See also

[hmath_abi_version](#hmath_abi_version), [hmath_runtime_shutdown](#hmath_runtime_shutdown).

### `hmath_runtime_shutdown`

Request final shutdown after all numerical users have finished.

`hmath_status hmath_runtime_shutdown(void)`

#### Parameters

None.

#### Returns

`HMATH_OK` after final shutdown or `HMATH_BUSY`
while a checked/legacy call or callback is active. Join workers, then retry a
busy result. Successful shutdown is irreversible; only the process owner
should invoke it. Release owned resources before shutdown.

#### See also

[hmath_init](#hmath_init), [hmath_shutdown](#hmath_shutdown).

### `hmath_shutdown`

Invoke the legacy shutdown wrapper.

`void hmath_shutdown(void)`

#### Parameters

None.

#### Returns

nothing. Legacy wrapper around final shutdown;
if busy, leaves the runtime running and records the error. Prefer the checked
`hmath_runtime_shutdown()` for new clients; otherwise inspect the last error.

#### See also

[hmath_runtime_shutdown](#hmath_runtime_shutdown), [hmath_init](#hmath_init).

## Cancellation contexts

### `hmath_context_create`

Create a cancellation context.

`hmath_status hmath_context_create(hmath_context **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `out` | `hmath_context **` | Writable non-NULL slot for one owned context; NULL on failure. |

#### Returns

`HMATH_OK` and one owned,
initially uncancelled context.

#### Errors

invalid output pointer or allocation
failure (NULL result). Example: `hmath_context *ctx = NULL;` followed by
`hmath_context_create(&ctx)`; release the context after its users finish.

#### See also

[hmath_context_release](#hmath_context_release), [hmath_context_cancel](#hmath_context_cancel).

### `hmath_context_retain`

Acquire one additional reference to a cancellation context.

`void hmath_context_retain(hmath_context *context)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `context` | `hmath_context *` | Live context, or NULL for a no-op. |

#### Returns

nothing; adds one owned
reference, or does nothing for NULL. Retain before giving a second owner access.
This does not reset cancellation or update the last diagnostic.

#### See also

[hmath_context_release](#hmath_context_release), [hmath_context_create](#hmath_context_create).

### `hmath_context_release`

Release one owned cancellation-context reference.

`void hmath_context_release(hmath_context *context)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `context` | `hmath_context *` | Owned reference, or NULL for a no-op. |

#### Returns

nothing;
destroys it on final release. Every successful create/retain needs one release.
Do not release the final reference while a kernel still uses this context.

#### See also

[hmath_context_retain](#hmath_context_retain), [hmath_context_create](#hmath_context_create).

### `hmath_context_cancel`

Request cooperative cancellation.

`void hmath_context_cancel(hmath_context *context)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `context` | `hmath_context *` | Live context retained throughout cancellation, or NULL. |

#### Returns

nothing. Atomically requests
cancellation of current/future work using this context. NULL is a no-op. It is
safe to request cancellation from another thread; the caller must keep its
reference alive. Does not clear the error message.

#### See also

[hmath_context_reset](#hmath_context_reset), [hmath_context_create](#hmath_context_create).

### `hmath_context_reset`

Clear cancellation after the context becomes idle.

`void hmath_context_reset(hmath_context *context)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `context` | `hmath_context *` | Live context with no active users, or NULL. |

#### Returns

nothing. Clear the cancelled
flag for reuse, **only after no operation is using the context**. NULL is a
no-op. Reset does not restart a shut down runtime.

#### See also

[hmath_context_cancel](#hmath_context_cancel), [hmath_context_create](#hmath_context_create).

## Tensor construction

### `hmath_tensor_copy`

Copy row-major values into a new tensor.

`hmath_status hmath_tensor_copy(const double *data, size_t count, const size_t *shape, size_t rank, hmath_tensor **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `data` | `const double *` | Readable finite double values; NULL only when count is zero. |
| `count` | `size_t` | Number of input doubles; must equal the shape product. |
| `shape` | `const size_t *` | Array of rank dimensions; may be NULL for rank zero. |
| `rank` | `size_t` | Number of dimensions, from zero through HMATH_MAX_RANK. |
| `out` | `hmath_tensor **` | Writable non-NULL handle slot; receives one owned tensor on success. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: one owned contiguous row-major copy. The caller retains ownership
of the input.

#### Errors

invalid pointers/data, shape/count mismatch, exceeded
bounds, or allocation failure. See the complete example below.

#### Notes

`count` readable finite doubles, `rank` dimensions, and a non-NULL
output slot. `count` must equal the shape product; NULL data is allowed only
for zero elements, and NULL shape for rank zero.

#### See also

[hmath_tensor_borrow](#hmath_tensor_borrow), [hmath_vector_copy](#hmath_vector_copy), [hmath_matrix_copy](#hmath_matrix_copy).

### `hmath_tensor_borrow`

Create an immutable tensor over caller-provided storage.

`hmath_status hmath_tensor_borrow(const double *data, size_t storage_count, const size_t *shape, const size_t *strides, size_t rank, hmath_buffer_deleter deleter, void *userdata, hmath_tensor **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `data` | `const double *` | Aligned finite storage; immutable until final storage release. |
| `storage_count` | `size_t` | Readable storage span in doubles, including gaps between strided elements. |
| `shape` | `const size_t *` | Array of rank bounded dimensions. |
| `strides` | `const size_t *` | Array of rank nonnegative strides in elements; NULL selects row-major. |
| `rank` | `size_t` | Number of dimensions, at most HMATH_MAX_RANK. |
| `deleter` | `hmath_buffer_deleter` | Optional final-storage callback; NULL leaves cleanup to the caller. |
| `userdata` | `void *` | Borrowed callback state, alive until the deleter runs. |
| `out` | `hmath_tensor **` | Writable non-NULL handle slot; one owned reference on success. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: one owned zero-copy tensor. On final storage release, invokes the
deleter exactly once on the releasing thread. The callback must not throw or
call shutdown.

#### Errors

invalid/non-finite storage, shape/span/budget violation,
or allocation failure. Failure does not consume input ownership or call the deleter.
Example: borrow a static `const double[3]` with shape `{3}`, NULL strides/deleter.

#### Notes

aligned immutable storage containing `storage_count` readable
doubles; shape and optional element strides (NULL means row-major); optional
`deleter(userdata, data)` and its borrowed userdata; output slot. All reachable
offsets must fit the storage. Keep data and userdata live/immutable until release.

#### See also

[hmath_tensor_copy](#hmath_tensor_copy), [hmath_tensor_release](#hmath_tensor_release), [hmath_tensor_reshape](#hmath_tensor_reshape).

### `hmath_vector_copy`

Copy values into a rank-one tensor.

`hmath_status hmath_vector_copy(const double *data, size_t count, hmath_vector **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `data` | `const double *` | Readable finite doubles; NULL is allowed for zero elements. |
| `count` | `size_t` | Number of values and vector length. |
| `out` | `hmath_vector **` | Writable non-NULL vector handle slot; one owned reference on success. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: a new owned contiguous tensor with shape `(count)`.

#### Errors

the same input, budget, and allocation errors as `hmath_tensor_copy`.
Example: `hmath_vector_copy(values, 3, &vector)`.

#### See also

[hmath_tensor_copy](#hmath_tensor_copy), [hmath_matrix_copy](#hmath_matrix_copy).

### `hmath_matrix_copy`

Copy row-major values into a rank-two tensor.

`hmath_status hmath_matrix_copy(const double *data, size_t count, size_t rows, size_t columns, hmath_matrix **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `data` | `const double *` | Readable finite doubles in row-major order. |
| `count` | `size_t` | Number of values; must equal rows * columns. |
| `rows` | `size_t` | Nonnegative row count within the element budget. |
| `columns` | `size_t` | Nonnegative column count within the element budget. |
| `out` | `hmath_matrix **` | Writable non-NULL matrix handle slot; one owned reference on success. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: a new owned `(rows, columns)` tensor.

#### Errors

construction errors, including `count != rows * columns`.
Example: `hmath_matrix_copy(values, 6, 2, 3, &matrix)`.

#### See also

[hmath_tensor_copy](#hmath_tensor_copy), [hmath_tensor_matmul](#hmath_tensor_matmul).

## Tensor ownership and inspection

### `hmath_tensor_retain`

Acquire one additional reference to an existing tensor.

`void hmath_tensor_retain(hmath_tensor *tensor)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `hmath_tensor *` | Live tensor retained throughout the call, or NULL. |

#### Returns

nothing; adds one owned
reference for a new owner, or does nothing for NULL. It copies no values.
Balance each retain with a release. Does not change the last diagnostic.

#### See also

[hmath_tensor_release](#hmath_tensor_release), [hmath_tensor_data](#hmath_tensor_data).

### `hmath_tensor_release`

Release one owned tensor reference.

`void hmath_tensor_release(hmath_tensor *tensor)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `hmath_tensor *` | One owned reference, or NULL; never release a non-NULL reference twice. |

#### Returns

nothing; final release
frees the handle and, when no storage owners remain, its data/deleter. NULL is
allowed; releasing the same non-NULL reference twice is invalid. Reset your
variable to NULL after release to avoid accidental reuse.

#### See also

[hmath_tensor_retain](#hmath_tensor_retain), [hmath_tensor_borrow](#hmath_tensor_borrow).

### `hmath_tensor_rank`

Query the number of dimensions.

`size_t hmath_tensor_rank(const hmath_tensor *tensor)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `const hmath_tensor *` | Live tensor, or NULL to obtain zero. |

#### Returns

its dimension count; NULL
returns zero. A real rank-zero scalar also returns zero: this is not an error
check. No initialization or ownership transfer occurs.

#### See also

[hmath_tensor_metadata](#hmath_tensor_metadata), [hmath_tensor_count](#hmath_tensor_count).

### `hmath_tensor_count`

Query the logical element count.

`size_t hmath_tensor_count(const hmath_tensor *tensor)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `const hmath_tensor *` | Live tensor, or NULL to obtain zero. |

#### Returns

its logical element count;
NULL returns zero. Scalars count as one; empty tensors count as zero. The count
can differ from the storage span for strided input.

#### See also

[hmath_tensor_rank](#hmath_tensor_rank), [hmath_tensor_copy_to](#hmath_tensor_copy_to).

### `hmath_tensor_metadata`

Copy dimensions and element strides to caller-owned arrays.

`hmath_status hmath_tensor_metadata(const hmath_tensor *tensor, size_t *shape, size_t *strides, size_t capacity)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `const hmath_tensor *` | Live tensor. |
| `shape` | `size_t *` | Writable array of at least rank entries; NULL allowed for rank zero. |
| `strides` | `size_t *` | Writable array of at least rank entries; NULL allowed for rank zero. |
| `capacity` | `size_t` | Capacity of each output array in size_t entries. |

#### Returns

`HMATH_OK` after writing dimensions and element strides.

#### Errors

invalid tensor/arrays or `HMATH_BOUNDS_ERROR` for insufficient capacity.
Example: use `size_t shape[HMATH_MAX_RANK], strides[HMATH_MAX_RANK];`.

#### Notes

live tensor, two caller-owned output arrays, and capacity in
entries (at least rank). Both arrays may be NULL for rank zero.

#### See also

[hmath_tensor_data](#hmath_tensor_data), [hmath_tensor_rank](#hmath_tensor_rank).

### `hmath_tensor_copy_to`

Copy logical values to independent row-major storage.

`hmath_status hmath_tensor_copy_to(const hmath_tensor *tensor, double *out, size_t capacity)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `const hmath_tensor *` | Live source tensor. |
| `out` | `double *` | Aligned destination, non-overlapping with source storage; NULL allowed for empty output. |
| `capacity` | `size_t` | Destination capacity in doubles, at least the logical element count. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: a logical row-major copy in the caller's buffer.

#### Errors

invalid/overlapping buffer or insufficient capacity. No ownership
transfer occurs. Example: copy a six-element tensor into `double out[6]`.

#### Notes

live tensor and aligned destination with at least `count`
entries. The output must not overlap input storage; NULL is allowed for empty
output.

#### See also

[hmath_tensor_data](#hmath_tensor_data), [hmath_tensor_copy](#hmath_tensor_copy).

### `hmath_tensor_data`

Borrow a read-only pointer to underlying tensor storage.

`hmath_status hmath_tensor_data(const hmath_tensor *tensor, const double **data, size_t *storage_count)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `const hmath_tensor *` | Live tensor whose storage must remain retained while the pointer is used. |
| `data` | `const double **` | Writable non-NULL slot for a borrowed storage pointer; do not free the pointer. |
| `storage_count` | `size_t *` | Writable non-NULL slot for the storage span in doubles. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: a **borrowed read-only** storage pointer and underlying storage
size. Use metadata strides for logical indexing; the storage need not be compact.
The pointer is valid only while storage ownership is retained. Do not free it.

#### Errors

NULL tensor or output slots. No allocation or copying occurs.

#### See also

[hmath_tensor_metadata](#hmath_tensor_metadata), [hmath_tensor_retain](#hmath_tensor_retain).

### `hmath_tensor_reshape`

Create a new handle sharing contiguous storage with a new shape.

`hmath_status hmath_tensor_reshape(const hmath_tensor *tensor, const size_t *shape, size_t rank, hmath_tensor **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `const hmath_tensor *` | Live contiguous source tensor. |
| `shape` | `const size_t *` | New dimensions with the same element count; NULL for rank zero. |
| `rank` | `size_t` | New dimension count, at most HMATH_MAX_RANK. |
| `out` | `hmath_tensor **` | Writable non-NULL slot for a new independently owned handle. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: a new owned handle sharing storage with the original.

#### Errors

invalid shape, changed element count, non-contiguous input, or
allocation failure. No `-1` dimension inference. Example: reshape a length-six
vector to shape `{2, 3}`; both handles require independent release.

#### See also

[hmath_tensor_copy](#hmath_tensor_copy), [hmath_tensor_metadata](#hmath_tensor_metadata).

## Raw allocation

### `hmath_buffer_alloc`

Allocate aligned storage using the HMath allocator.

`hmath_status hmath_buffer_alloc(size_t bytes, size_t alignment, void **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `bytes` | `size_t` | Requested bytes, at most HMATH_MAX_ELEMENTS * sizeof(double); zero is valid. |
| `alignment` | `size_t` | Power of two from sizeof(void *) through 4096. |
| `out` | `void **` | Writable non-NULL slot; release the result only with hmath_buffer_free. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: one owned aligned allocation; release **only** with
`hmath_buffer_free`.

#### Errors

invalid alignment, size exceeding
`HMATH_MAX_ELEMENTS * sizeof(double)`, arithmetic overflow, or allocation failure.
Example: `hmath_buffer_alloc(3 * sizeof(double), 64, &buffer)`.

#### Notes

requested byte count, power-of-two alignment in
`[sizeof(void *), 4096]`, and non-NULL output slot. Zero bytes is valid.

#### See also

[hmath_buffer_free](#hmath_buffer_free), [hmath_tensor_borrow](#hmath_tensor_borrow).

### `hmath_buffer_free`

Free storage allocated by hmath_buffer_alloc.

`void hmath_buffer_free(void *buffer)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `buffer` | `void *` | Owned allocation from hmath_buffer_alloc, or NULL. |

#### Returns

nothing; frees that allocation. Never pass a tensor's borrowed data
pointer or an allocation from another allocator. Free each non-NULL allocation once.

#### See also

[hmath_buffer_alloc](#hmath_buffer_alloc).

## Checked numerical kernels

### `hmath_scalar_add`

Add two finite real scalars.

`hmath_status hmath_scalar_add(hmath_context *context, double a, double b, double *out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `context` | `hmath_context *` | Optional cancellation context; NULL disables cancellation. |
| `a` | `double` | First finite double. |
| `b` | `double` | Second finite double. |
| `out` | `double *` | Aligned writable scalar slot; written only on success. |

#### Returns

`HMATH_OK` with their sum in `*out`.

#### Errors

invalid/non-finite input, non-finite result, or common kernel failures.
Example: `hmath_scalar_add(NULL, 2.0, 3.0, &result)` writes `5.0` on success.

#### See also

[hmath_add_f64](#hmath_add_f64), [hmath_last_error_message](#hmath_last_error_message).

### `hmath_tensor_sum`

Reduce all logical elements to one scalar.

`hmath_status hmath_tensor_sum(hmath_context *context, const hmath_tensor *tensor, double *out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `context` | `hmath_context *` | Optional cancellation context; NULL disables cancellation. |
| `tensor` | `const hmath_tensor *` | Live input tensor of any rank. |
| `out` | `double *` | Aligned writable scalar slot; written only on success. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: sum of all logical elements; empty sum is zero.

#### Errors

invalid arguments, non-finite arithmetic, or common kernel failures.
Neither input nor ownership is modified. See the example below.

#### See also

[hmath_tensor_dot](#hmath_tensor_dot), [hmath_batch_sum](#hmath_batch_sum).

### `hmath_tensor_dot`

Reduce corresponding products over identically shaped tensors.

`hmath_status hmath_tensor_dot(hmath_context *context, const hmath_tensor *a, const hmath_tensor *b, double *out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `context` | `hmath_context *` | Optional cancellation context; NULL disables cancellation. |
| `a` | `const hmath_tensor *` | Live first tensor. |
| `b` | `const hmath_tensor *` | Live second tensor with exactly the same shape. |
| `out` | `double *` | Aligned writable scalar slot; written only on success. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: sum of corresponding products across all dimensions, zero for
matching empty tensors.

#### Errors

invalid arguments, unequal shapes,
non-finite arithmetic, or common kernel failures. This is not matrix multiplication.

#### See also

[hmath_tensor_sum](#hmath_tensor_sum), [hmath_tensor_matmul](#hmath_tensor_matmul).

### `hmath_tensor_add`

Add identically shaped tensors element by element.

`hmath_status hmath_tensor_add(hmath_context *context, const hmath_tensor *a, const hmath_tensor *b, hmath_tensor **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `context` | `hmath_context *` | Optional cancellation context; NULL disables cancellation. |
| `a` | `const hmath_tensor *` | Live first tensor. |
| `b` | `const hmath_tensor *` | Live second tensor of identical shape; no broadcasting. |
| `out` | `hmath_tensor **` | Writable non-NULL slot for a new owned tensor. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: a new owned elementwise sum; inputs unchanged. No broadcasting.

#### Errors

invalid arguments, shape mismatch, allocation/arithmetic or common
kernel failures. For `[1, 2]` and `[3, 4]`, the result contains `[4, 6]`.

#### See also

[hmath_tensor_matmul](#hmath_tensor_matmul), [hmath_tensor_copy](#hmath_tensor_copy).

### `hmath_tensor_matmul`

Multiply two dense rank-two matrices.

`hmath_status hmath_tensor_matmul(hmath_context *context, const hmath_tensor *a, const hmath_tensor *b, hmath_tensor **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `context` | `hmath_context *` | Optional cancellation context; NULL disables cancellation. |
| `a` | `const hmath_tensor *` | Live left matrix of shape (m, k). |
| `b` | `const hmath_tensor *` | Live right matrix of shape (k, n). |
| `out` | `hmath_tensor **` | Writable non-NULL slot for a new owned matrix of shape (m, n). |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: a new owned `(m,n)` matrix product. Work must not exceed
16,777,216 scalar multiply-add steps.

#### Errors

invalid arguments, rank/inner-dimension mismatch, work/size bound,
allocation/arithmetic, or common kernel failures. Inputs remain unchanged.

#### See also

[hmath_tensor_dot](#hmath_tensor_dot), [hmath_matrix_copy](#hmath_matrix_copy).

### `hmath_tensor_map`

Apply a synchronous checked callback to each logical element.

`hmath_status hmath_tensor_map(hmath_context *context, const hmath_tensor *tensor, hmath_map_callback callback, void *userdata, hmath_tensor **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `context` | `hmath_context *` | Optional cancellation context; NULL disables cancellation. |
| `tensor` | `const hmath_tensor *` | Live input tensor. |
| `callback` | `hmath_map_callback` | Non-NULL callback: write one finite result and return a status; never throw across C. |
| `userdata` | `void *` | Borrowed callback state, alive until this synchronous call returns. |
| `out` | `hmath_tensor **` | Writable non-NULL slot; receives a new owned tensor only after every callback succeeds. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: a new owned tensor of the original shape only if every callback
succeeds.

#### Errors

callback status, invalid callback/input, cancellation,
non-finite output, allocation, or runtime failure. Partial results are discarded.
Callbacks are synchronous, may reenter checked calls, must not throw across C,
and must not shut down the runtime. Userdata need only outlive this call.

#### Notes

optional context, live input, callback, borrowed userdata, output.
The callback receives `(double value, size_t index, void *userdata, double *result)`
in logical row-major order, writes one finite result, and returns a status.

#### See also

[hmath_context_cancel](#hmath_context_cancel), [hmath_tensor_sum](#hmath_tensor_sum).

### `hmath_batch_sum`

Sum multiple tensors with explicit partial progress.

`hmath_status hmath_batch_sum(hmath_context *context, const hmath_tensor *const *inputs, size_t count, double *out, size_t *completed)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `context` | `hmath_context *` | Optional cancellation context; NULL disables cancellation. |
| `inputs` | `const hmath_tensor *const *` | Array of count live tensor pointers; NULL allowed for zero count. |
| `count` | `size_t` | Number of tensors, at most 4096. |
| `out` | `double *` | Writable array of count scalar slots; completed entries remain valid on failure. |
| `completed` | `size_t *` | Aligned writable non-NULL size_t slot recording completed reductions. |

#### Returns

`HMATH_OK` after all reductions; `*completed == count`.

#### Errors

invalid arrays/bounds or a reduction failure. Unlike atomic tensor
kernels, entries `out[0 .. *completed)` remain valid after failure; later output
slots are untouched. Count zero permits NULL input/output arrays. Initialize
progress storage even for an empty batch: `size_t completed = 0;`.

#### Notes

optional context, arrays of `count` live tensor pointers and
scalar output slots, and aligned non-NULL progress pointer. `count <= 4096`.

#### See also

[hmath_tensor_sum](#hmath_tensor_sum), [hmath_context_cancel](#hmath_context_cancel).

## Legacy numerical interface

Prefer checked functions when available. Legacy numerical calls still require
successful initialization. Invalid lifecycle returns NaN (`-1` for factorial).
All nonempty buffers must contain the declared readable number of doubles;
counts must fit Haskell `Int`.

### `hmath_add_f64`

Add scalars using the legacy numerical interface.

`double hmath_add_f64(double a, double b)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `a` | `double` | First double. |
| `b` | `double` | Second double. |

#### Returns

their legacy scalar sum. Invalid
lifecycle returns NaN. Unlike the checked interface, this retains legacy
floating-point behavior without a status result. Example: `hmath_add_f64(2, 3)`.

#### See also

[hmath_scalar_add](#hmath_scalar_add), [hmath_init](#hmath_init).

### `hmath_factorial`

Compute a legacy bounded integer factorial.

`long long hmath_factorial(int n)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `n` | `int` | Integer from zero through twenty; other inputs return -1. |

#### Returns

`n!`, including `0! == 1`; `-1` outside the range or with invalid
lifecycle. Example: `hmath_factorial(5)` returns 120.

#### See also

[hmath_init](#hmath_init), [hmath_last_error_code](#hmath_last_error_code).

### `hmath_mean_f64`

Compute a legacy arithmetic mean.

`double hmath_mean_f64(const double *values, size_t count)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `values` | `const double *` | Array of count readable doubles; NULL yields NaN. |
| `count` | `size_t` | Number of values, representable as Haskell Int; zero yields NaN. |

#### Returns

arithmetic mean;
empty or NULL input, or invalid lifecycle, returns NaN. Example: `{2,4}` gives 3.
No handle ownership is transferred.

#### See also

[hmath_tensor_sum](#hmath_tensor_sum), [hmath_init](#hmath_init).

### `hmath_dot_f64`

Compute a legacy dot product of flat arrays.

`double hmath_dot_f64(const double *a, const double *b, size_t count)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `a` | `const double *` | First array of count readable doubles. |
| `b` | `const double *` | Second array of count readable doubles. |
| `count` | `size_t` | Common array length, representable as Haskell Int; zero returns zero. |

#### Returns

sum of products; empty input gives zero, nonempty NULL input or
invalid lifecycle gives NaN. Example: `{1,2}` dotted with `{3,4}` gives 11.

#### See also

[hmath_tensor_dot](#hmath_tensor_dot), [hmath_init](#hmath_init).

## DLPack exchange

Include `hmath_dlpack.h` and the producer's official `dlpack/dlpack.h` for the
managed tensor structs. Only CPU device 0, native-endian binary64, one lane,
and rank at most 8 are supported. Negative strides, unsupported devices/dtypes,
and unknown versioned flags are rejected. Imported storage must remain immutable.

### `hmath_dlpack_export`

Export a writable legacy DLPack copy.

`hmath_status hmath_dlpack_export(const hmath_tensor *tensor, struct DLManagedTensor **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `const hmath_tensor *` | Live input tensor. |
| `out` | `struct DLManagedTensor **` | Writable non-NULL slot for a managed tensor; invoke its deleter exactly once. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: an owned legacy DLPack **copy**, because legacy DLPack cannot express
read-only storage. The recipient must invoke its deleter exactly once. The
HMath input can then be released independently.

#### Errors

invalid input/output, size/layout, or allocation failure.

#### See also

[hmath_dlpack_export_versioned](#hmath_dlpack_export_versioned), [hmath_dlpack_import](#hmath_dlpack_import).

### `hmath_dlpack_import`

Consume a supported legacy DLPack tensor on successful import.

`hmath_status hmath_dlpack_import(struct DLManagedTensor *tensor, size_t storage_elements, hmath_tensor **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `struct DLManagedTensor *` | Producer-owned CPU binary64 managed tensor; ownership transfers only on success. |
| `storage_elements` | `size_t` | Guaranteed readable doubles after byte_offset; DLPack does not provide allocation size. |
| `out` | `hmath_tensor **` | Writable non-NULL slot for one owned HMath tensor. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: one owned HMath tensor and consumes managed-tensor ownership **only
on success**; final HMath storage release calls the producer's deleter.

#### Errors

invalid/unsupported metadata, insufficient storage span, non-finite
data, bounds, or allocation failure. On failure the caller still owns the managed tensor.

#### Notes

producer-owned managed tensor, count of readable double elements
**after `byte_offset`**, and output slot. The caller guarantees this count;
DLPack itself carries no allocation size.

#### See also

[hmath_dlpack_import_versioned](#hmath_dlpack_import_versioned), [hmath_tensor_release](#hmath_tensor_release).

### `hmath_dlpack_export_versioned`

Export a retained read-only versioned DLPack view.

`hmath_status hmath_dlpack_export_versioned(const hmath_tensor *tensor, struct DLManagedTensorVersioned **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `const hmath_tensor *` | Live input tensor. |
| `out` | `struct DLManagedTensorVersioned **` | Writable non-NULL slot for a retained managed view; invoke its deleter exactly once. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: an owned versioned zero-copy DLPack view with the read-only flag set.
It retains storage independently of the original HMath handle; invoke the
managed view's deleter exactly once.

#### Errors

invalid arguments or allocation failure.

#### See also

[hmath_dlpack_export](#hmath_dlpack_export), [hmath_dlpack_import_versioned](#hmath_dlpack_import_versioned).

### `hmath_dlpack_import_versioned`

Consume a supported versioned DLPack tensor on success.

`hmath_status hmath_dlpack_import_versioned(struct DLManagedTensorVersioned *tensor, size_t storage_elements, hmath_tensor **out)`

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `tensor` | `struct DLManagedTensorVersioned *` | Producer-owned supported managed tensor; ownership transfers only on success. |
| `storage_elements` | `size_t` | Guaranteed readable doubles after byte_offset. |
| `out` | `hmath_tensor **` | Writable non-NULL slot for one owned HMath tensor. |

#### Returns

Returns `HMATH_OK` on success or a nonzero `hmath_status` on failure.

On success: one owned HMath tensor, consuming producer ownership
only on success.

#### Errors

legacy import validation failures plus unsupported
DLPack version or flags. Do not mutate the imported storage through any alias
while the resulting storage is retained.

#### See also

[hmath_dlpack_import](#hmath_dlpack_import), [hmath_tensor_release](#hmath_tensor_release).

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
