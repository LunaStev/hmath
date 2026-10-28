/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_H
#define HMATH_H
#include <stddef.h>
#include <stdint.h>
#if defined(_WIN32) && defined(HMATH_BUILD_SHARED)
#define HMATH_API __declspec(dllexport)
#elif defined(_WIN32) && defined(HMATH_USE_SHARED)
#define HMATH_API __declspec(dllimport)
#elif defined(__GNUC__)
#define HMATH_API __attribute__((visibility("default")))
#else
#define HMATH_API
#endif
#ifdef __cplusplus
extern "C" {
#endif

/* Additive ABI epoch, independent of the package release version. */
#define HMATH_ABI_VERSION 1u
#define HMATH_MAX_RANK 8u
#define HMATH_MAX_ELEMENTS 1048576u
typedef enum hmath_status {
    HMATH_OK = 0,
    HMATH_INVALID_ARGUMENT = 1,
    HMATH_SHAPE_ERROR = 2,
    HMATH_OVERFLOW = 3,
    HMATH_ALLOCATION_FAILED = 4,
    HMATH_RUNTIME_ERROR = 5,
    HMATH_HASKELL_EXCEPTION = 6,
    HMATH_CANCELLED = 7,
    HMATH_BOUNDS_ERROR = 8,
    HMATH_BUSY = 9,
    HMATH_UNSUPPORTED = 10
} hmath_status;
typedef struct hmath_context hmath_context;
typedef struct hmath_tensor hmath_tensor;
typedef hmath_tensor hmath_vector;
typedef hmath_tensor hmath_matrix;
/* Finalizers run synchronously on the last releasing thread. Never throw or
 * call shutdown from a callback. userdata is borrowed until final release. */
typedef void (*hmath_buffer_deleter)(void *userdata, const double *data);
typedef hmath_status (*hmath_map_callback)(double value, size_t index, void *userdata,
                                           double *result);

HMATH_API uint32_t hmath_abi_version(void);
HMATH_API const char *hmath_library_version(void);
HMATH_API const char *hmath_build_info(void);
HMATH_API const char *hmath_backend_version(void);
/* The message is valid on this thread until the next checked operation.
 * Query, retain/release and cancellation functions do not clear it. */
HMATH_API hmath_status hmath_last_error_code(void);
HMATH_API const char *hmath_last_error_message(void);
HMATH_API const char *hmath_status_string(hmath_status status);

enum hmath_init_result { HMATH_INIT_OK = 0, HMATH_INIT_ALREADY_SHUT_DOWN = 1 };
/* HMath owns its GHC RTS. Do not combine with independently initialized GHC
 * libraries. Initialization is idempotent; final shutdown is irreversible.
 * Checked and legacy calls reserve the RTS; shutdown returns BUSY while any
 * call is active, including a callback. Retry after joining workers. */
HMATH_API int hmath_init(void);
HMATH_API hmath_status hmath_runtime_shutdown(void);
/* Legacy void form leaves the RTS running on BUSY; inspect last_error_code. */
HMATH_API void hmath_shutdown(void);
HMATH_API hmath_status hmath_context_create(hmath_context **out);
HMATH_API void hmath_context_retain(hmath_context *context);
HMATH_API void hmath_context_release(hmath_context *context);
HMATH_API void hmath_context_cancel(hmath_context *context);
/* Reset only when no operation is using this context. NULL means no context. */
HMATH_API void hmath_context_reset(hmath_context *context);

/* All handles are immutable, safely shareable while each thread owns a
 * reference. Releasing your final reference concurrently with use is invalid.
 * NULL release is allowed. Other non-NULL pointers must be valid live objects;
 * no C interface can validate arbitrary addresses or actual allocation sizes.
 * Elements are finite IEEE binary64. rank 0 is a scalar (one element); zero
 * dimensions are allowed. Products and reachable spans are bounded. Strides
 * are NONNEGATIVE element strides, not bytes. NULL strides means row-major.
 * Copy requires count == product(shape). Borrow checks every reachable offset
 * against storage_count and requires double alignment. Borrowed storage must
 * remain immutable/live until its optional deleter runs, exactly once; on
 * construction failure ownership stays with the caller. out is NULL on error.
 * Metadata/allocation operations do not require an initialized RTS. */
HMATH_API hmath_status hmath_tensor_copy(const double *data, size_t count, const size_t *shape,
                                         size_t rank, hmath_tensor **out);
HMATH_API hmath_status hmath_tensor_borrow(const double *data, size_t storage_count,
                                           const size_t *shape, const size_t *strides, size_t rank,
                                           hmath_buffer_deleter deleter, void *userdata,
                                           hmath_tensor **out);
HMATH_API hmath_status hmath_vector_copy(const double *data, size_t count, hmath_vector **out);
HMATH_API hmath_status hmath_matrix_copy(const double *data, size_t count, size_t rows,
                                         size_t columns, hmath_matrix **out);
HMATH_API void hmath_tensor_retain(hmath_tensor *tensor);
HMATH_API void hmath_tensor_release(hmath_tensor *tensor);
HMATH_API size_t hmath_tensor_rank(const hmath_tensor *tensor);
HMATH_API size_t hmath_tensor_count(const hmath_tensor *tensor);
HMATH_API hmath_status hmath_tensor_metadata(const hmath_tensor *tensor, size_t *shape,
                                             size_t *strides, size_t capacity);
HMATH_API hmath_status hmath_tensor_copy_to(const hmath_tensor *tensor, double *out,
                                            size_t capacity);
/* Zero-copy view includes its strides; pointer is borrowed until tensor
 * release. */
HMATH_API hmath_status hmath_tensor_data(const hmath_tensor *tensor, const double **data,
                                         size_t *storage_count);
/* Reshape requires contiguous storage and preserves storage ownership. */
HMATH_API hmath_status hmath_tensor_reshape(const hmath_tensor *tensor, const size_t *shape,
                                            size_t rank, hmath_tensor **out);
/* Aligned raw allocation: free ONLY with hmath_buffer_free. zero bytes is
 * valid. alignment is a power of two in [sizeof(void*), 4096]. */
HMATH_API hmath_status hmath_buffer_alloc(size_t bytes, size_t alignment, void **out);
HMATH_API void hmath_buffer_free(void *buffer);

/* Numerical kernels execute Haskell and contain synchronous Haskell exceptions.
 * Require running RTS. A NULL context disables cancellation. Results are only
 * written on success. Cancellation is cooperative before/after a kernel; an
 * in-flight Haskell kernel is bounded, but is not interrupted. */
HMATH_API hmath_status hmath_scalar_add(hmath_context *context, double a, double b, double *out);
HMATH_API hmath_status hmath_tensor_sum(hmath_context *context, const hmath_tensor *tensor,
                                        double *out);
HMATH_API hmath_status hmath_tensor_dot(hmath_context *context, const hmath_tensor *a,
                                        const hmath_tensor *b, double *out);
HMATH_API hmath_status hmath_tensor_add(hmath_context *context, const hmath_tensor *a,
                                        const hmath_tensor *b, hmath_tensor **out);
/* Dense rank-2 matrix product; at most 16,777,216 scalar multiply-add steps. */
HMATH_API hmath_status hmath_tensor_matmul(hmath_context *context, const hmath_tensor *a,
                                           const hmath_tensor *b, hmath_tensor **out);
/* Callbacks are synchronous and may reenter checked APIs, but must not throw
 * across C. Cancel is checked between elements. Result is atomic on failure. */
HMATH_API hmath_status hmath_tensor_map(hmath_context *context, const hmath_tensor *tensor,
                                        hmath_map_callback callback, void *userdata,
                                        hmath_tensor **out);
/* Partial progress is explicit: completed outputs are valid, later outputs
 * untouched. count <= 4096; inputs/output arrays must have count entries. */
HMATH_API hmath_status hmath_batch_sum(hmath_context *context, const hmath_tensor *const *inputs,
                                       size_t count, double *out, size_t *completed);

/* Legacy ABI: numerical functions require initialization. Invalid lifecycle
 * returns NaN (-1 for factorial). Existing numerical behavior is preserved:
 * mean empty/NULL -> NaN; dot empty -> 0, nonempty NULL -> NaN; factorial
 * outside [0,20] -> -1. Buffers must have count readable doubles (count <= max
 * Int). */
HMATH_API double hmath_add_f64(double a, double b);
HMATH_API long long hmath_factorial(int n);
HMATH_API double hmath_mean_f64(const double *values, size_t count);
HMATH_API double hmath_dot_f64(const double *a, const double *b, size_t count);
#ifdef __cplusplus
}
#endif
#endif
