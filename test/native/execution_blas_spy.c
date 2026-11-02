/* SPDX-License-Identifier: MPL-2.0 */
/* A deterministic BLAS protocol spy, not a production numerical backend. */
#include <stddef.h>
#include <stdint.h>
#ifdef ILP64
#define INTEGER int64_t
#else
#define INTEGER int32_t
#endif
static unsigned calls32, calls64;
static const void *last_a, *last_b, *last_c;
static int64_t last_ldc;
static float last_alpha32;
const char *openblas_get_config(void) {
#ifdef ILP64
    return "OpenBLAS test USE64BITINT";
#else
    return "OpenBLAS test LP64";
#endif
}
void cblas_daxpy(void) {}
void cblas_ddot(void) {}
void cblas_dnrm2(void) {}
void cblas_dgemv(void) {}
void cblas_zgemm(void) {}
#ifndef NO_SGEMM
void cblas_sgemm(int order, int ta, int tb, INTEGER m, INTEGER n, INTEGER k, float alpha,
                 const float *a, INTEGER lda, const float *b, INTEGER ldb, float beta, float *c,
                 INTEGER ldc) {
    (void)order;
    (void)ta;
    (void)tb;
    ++calls32;
    last_a = a;
    last_b = b;
    last_c = c;
    last_ldc = ldc;
    last_alpha32 = alpha;
    for (INTEGER i = 0; i < m; ++i)
        for (INTEGER j = 0; j < n; ++j) {
            float value = 0;
            for (INTEGER z = 0; z < k; ++z)
                value += a[i * lda + z] * b[z * ldb + j];
            c[i * ldc + j] = alpha * value + beta * c[i * ldc + j];
        }
}
#endif
void cblas_dgemm(int order, int ta, int tb, INTEGER m, INTEGER n, INTEGER k, double alpha,
                 const double *a, INTEGER lda, const double *b, INTEGER ldb, double beta, double *c,
                 INTEGER ldc) {
    (void)order;
    (void)ta;
    (void)tb;
    ++calls64;
    last_a = a;
    last_b = b;
    last_c = c;
    last_ldc = ldc;
    for (INTEGER i = 0; i < m; ++i)
        for (INTEGER j = 0; j < n; ++j) {
            double value = 0;
            for (INTEGER z = 0; z < k; ++z)
                value += a[i * lda + z] * b[z * ldb + j];
            c[i * ldc + j] = alpha * value + beta * c[i * ldc + j];
        }
}
unsigned hm_spy_calls32(void) { return calls32; }
unsigned hm_spy_calls64(void) { return calls64; }
uintptr_t hm_spy_pointer(unsigned which) {
    return (uintptr_t)(which == 0 ? last_a : which == 1 ? last_b : last_c);
}
int64_t hm_spy_ldc(void) { return last_ldc; }
float hm_spy_alpha32(void) { return last_alpha32; }
