/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_EXECUTION_H
#define HMATH_EXECUTION_H
#include "hmath.h"
#ifdef __cplusplus
extern "C" {
#endif

typedef enum hmath_execution_provider {
    HMATH_EXECUTION_REFERENCE = 0,
    HMATH_EXECUTION_OPENBLAS = 1,
    HMATH_EXECUTION_BLIS = 2,
    HMATH_EXECUTION_MKL = 3,
    HMATH_EXECUTION_ACCELERATE = 4
} hmath_execution_provider;
typedef struct hmath_execution_options {
    hmath_execution_provider provider;
    unsigned integer_bits;    /* BLAS LP64=32 or ILP64=64; 0 means LP64. */
    const char *library_path; /* Optional explicit provider path, borrowed for create. */
    size_t max_elements;      /* Per logical A/B/C view; 0 means no artificial cap. */
    size_t max_multiply_adds; /* m*n*k per call; 0 means no artificial cap. */
} hmath_execution_options;
typedef struct hmath_execution hmath_execution;
/* Row-major, consecutive columns, optional padding between rows. Counts and
 * leading dimensions are in elements, not bytes. No transpose/negative strides.
 * storage_count bounds the reachable span; caller guarantees actual allocation. */
typedef struct hmath_execution_view {
    const void *data;
    size_t storage_count, rows, columns, leading_dimension;
} hmath_execution_view;
typedef struct hmath_execution_output {
    void *data;
    size_t storage_count, rows, columns, leading_dimension;
} hmath_execution_output;
/* NULL options selects the reference path with unlimited resource policies.
 * Provider selection is explicit; unavailable/mismatched providers never silently
 * fall back. No OpenBLAS dependency is needed for the reference path. */
HMATH_API hmath_status hmath_execution_create(const hmath_execution_options *options,
                                              hmath_execution **out);
HMATH_API void hmath_execution_retain(hmath_execution *execution);
HMATH_API void hmath_execution_release(hmath_execution *execution);
/* C := alpha*A*B + beta*C, borrowing all buffers for this synchronous call.
 * A/B may overlap each other, but C must not overlap either input (including
 * padding spans). C must initially contain finite values even when beta=0,
 * matching the existing checked Backend.gemm input policy. Inputs/scalars are
 * finite checked; failures report original NonFiniteVectorEntry numbering over
 * [alpha,beta] ++ logical(A) ++ logical(B) ++ logical(C), and output errors number
 * logical(C). Validation failures leave C untouched. Once execution starts,
 * failure/cancellation may leave C modified; direct-output execution is not
 * transactional. Output padding is preserved. Reference executes original
 * Matrix.multiplyChecked/scaleMatrix/addMatrixChecked at the selected precision;
 * optimized providers may use different floating reduction/FMA order. Existing
 * pure Matrix and tensor APIs are unchanged. Concurrent calls require independent
 * C outputs and live execution/context references. Cancellation is checked before
 * and after a kernel, not inside a BLAS call. Runtime initialization is required. */
HMATH_API hmath_status hmath_execution_gemm_f32(hmath_execution *execution, hmath_context *context,
                                                float alpha, const hmath_execution_view *a,
                                                const hmath_execution_view *b, float beta,
                                                const hmath_execution_output *c);
HMATH_API hmath_status hmath_execution_gemm_f64(hmath_execution *execution, hmath_context *context,
                                                double alpha, const hmath_execution_view *a,
                                                const hmath_execution_view *b, double beta,
                                                const hmath_execution_output *c);
#ifdef __cplusplus
}
#endif
#endif
