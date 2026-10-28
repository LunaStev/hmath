/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_BACKEND_H
#define HMATH_BACKEND_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
/* Internal adapter ABI. Objects own dlopen references; callers retain the object
 * during every call. Buffers are borrowed for that call only, contiguous and
 * checked by the Haskell entry points. No process-global provider selection. */
typedef struct hmath_backend hmath_backend;
hmath_backend *hmath_backend_open(int provider, int bits, const char *path, int *status);
void hmath_backend_close(hmath_backend *backend);
int hmath_backend_threads(hmath_backend *backend, int threads);
int hmath_backend_vector(hmath_backend *, int operation, int64_t n, double alpha, const double *,
                         double *, double *);
int hmath_backend_gemv(hmath_backend *, int transpose, int64_t m, int64_t n, double alpha,
                       const double *, const double *, double beta, double *);
int hmath_backend_gemm(hmath_backend *, int complex_values, int trans_a, int trans_b, int64_t m,
                       int64_t n, int64_t k, const void *alpha, const void *a, int64_t lda,
                       const void *b, int64_t ldb, const void *beta, void *c);
/* Installed LP64 liblapacke SONAME is the default. HMATH_LAPACKE_LIBRARY
 * overrides the path ONLY with HMATH_LAPACKE_INTEGER_BITS=32 or 64; the latter
 * is an explicit ABI declaration. HMATH_BACKEND=pure disables native dispatch.
 * The loader is initialized once. Unknown custom ABIs are never inferred. */
int hmath_lapack_available(void);
#ifdef __cplusplus
}
#endif
#endif
