/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_backend.h"
#include "hmath_execution.h"
#include "native_internal.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

struct hmath_execution {
    atomic_size_t refs;
    hmath_backend *backend;
    size_t max_elements, max_multiply_adds;
};
extern int hm_execution_reference_f32(size_t m, size_t n, size_t k, float alpha, const float *a,
                                      size_t lda, const float *b, size_t ldb, float beta, float *c,
                                      size_t ldc);
extern int hm_execution_reference_f64(size_t m, size_t n, size_t k, double alpha, const double *a,
                                      size_t lda, const double *b, size_t ldb, double beta,
                                      double *c, size_t ldc);

hmath_status hmath_execution_create(const hmath_execution_options *options, hmath_execution **out) {
    hmath_execution_options defaults = {HMATH_EXECUTION_REFERENCE, 32, NULL, 0, 0};
    if (!options)
        options = &defaults;
    if (!out || options->provider < HMATH_EXECUTION_REFERENCE ||
        options->provider > HMATH_EXECUTION_ACCELERATE ||
        (options->integer_bits != 0 && options->integer_bits != 32 &&
         options->integer_bits != 64) ||
        (options->provider == HMATH_EXECUTION_REFERENCE && options->library_path &&
         *options->library_path))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid execution options");
    hmath_execution *value = calloc(1, sizeof *value);
    if (!value)
        return hm_error(HMATH_ALLOCATION_FAILED, "execution allocation failed");
    atomic_init(&value->refs, 1);
    value->max_elements = options->max_elements;
    value->max_multiply_adds = options->max_multiply_adds;
    if (options->provider != HMATH_EXECUTION_REFERENCE) {
        int code;
        value->backend = hmath_backend_open(options->provider,
                                            options->integer_bits ? (int)options->integer_bits : 32,
                                            options->library_path, &code);
        if (!value->backend) {
            free(value);
            return hm_error(
                code == 2   ? HMATH_INVALID_ARGUMENT
                : code == 3 ? HMATH_ALLOCATION_FAILED
                            : HMATH_UNSUPPORTED,
                "requested BLAS provider unavailable or incompatible; no fallback selected");
        }
    }
    *out = value;
    return hm_error(HMATH_OK, "");
}
void hmath_execution_retain(hmath_execution *execution) {
    if (execution)
        atomic_fetch_add_explicit(&execution->refs, 1, memory_order_relaxed);
}
void hmath_execution_release(hmath_execution *execution) {
    if (execution && atomic_fetch_sub_explicit(&execution->refs, 1, memory_order_acq_rel) == 1) {
        hmath_backend_close(execution->backend);
        free(execution);
    }
}

typedef struct validated_view {
    hmath_execution_view view;
    size_t count, span;
    uintptr_t begin, end;
} validated_view;
static hmath_status validate_view(const hmath_execution_view *view, size_t bytes, size_t limit,
                                  validated_view *out) {
    if (!view)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL execution view");
    if (view->rows > (size_t)PTRDIFF_MAX || view->columns > (size_t)PTRDIFF_MAX ||
        view->leading_dimension > (size_t)PTRDIFF_MAX)
        return hm_error(HMATH_OVERFLOW, "view dimension exceeds Haskell Int");
    if (view->columns && view->rows > (size_t)PTRDIFF_MAX / bytes / view->columns)
        return hm_error(HMATH_OVERFLOW, "view logical byte count overflows ptrdiff_t");
    size_t count = view->rows * view->columns, span = 0;
    if (limit && count > limit)
        return hm_error(HMATH_OVERFLOW, "configured element limit exceeded");
    if (count) {
        if (view->leading_dimension < view->columns)
            return hm_error(HMATH_INVALID_ARGUMENT,
                            "row-major leading dimension is smaller than columns");
        if (view->rows - 1 >
            ((size_t)PTRDIFF_MAX / bytes - view->columns) / view->leading_dimension)
            return hm_error(HMATH_OVERFLOW, "view reachable byte span overflows ptrdiff_t");
        span = (view->rows - 1) * view->leading_dimension + view->columns;
    }
    if (span > view->storage_count)
        return hm_error(HMATH_BOUNDS_ERROR, "view span exceeds backing storage");
    if ((span && !view->data) || (view->data && (uintptr_t)view->data % bytes))
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL or misaligned execution storage");
    uintptr_t begin = (uintptr_t)view->data;
    if (span && begin > UINTPTR_MAX - span * bytes)
        return hm_error(HMATH_OVERFLOW, "view address span overflows uintptr_t");
    *out = (validated_view){*view, count, span, begin, begin + span * bytes};
    return HMATH_OK;
}
static int overlap(const validated_view *a, const validated_view *b) {
    return a->span && b->span && a->begin < b->end && b->begin < a->end;
}
static hmath_status nonfinite(size_t index) {
    char message[96];
    (void)snprintf(message, sizeof message, "NonFiniteVectorEntry %zu", index);
    return hm_error(HMATH_MATH_ERROR, message);
}
static size_t first_nonfinite(const validated_view *view, int precision) {
    if (!view->count)
        return SIZE_MAX;
    for (size_t row = 0; row < view->view.rows; ++row)
        for (size_t column = 0; column < view->view.columns; ++column) {
            size_t index = row * view->view.leading_dimension + column;
            if (precision == 32 ? !isfinite(((const float *)view->view.data)[index])
                                : !isfinite(((const double *)view->view.data)[index]))
                return row * view->view.columns + column;
        }
    return SIZE_MAX;
}
static hmath_status gemm(hmath_execution *execution, hmath_context *context, int precision,
                         const void *alpha, const hmath_execution_view *a,
                         const hmath_execution_view *b, const void *beta,
                         const hmath_execution_output *output) {
    if (!execution || !a || !b || !output)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL execution argument");
    if (a->columns != b->rows)
        return hm_error(HMATH_SHAPE_ERROR, "GEMM inner dimensions differ");
    if (output->rows != a->rows || output->columns != b->columns)
        return hm_error(HMATH_SHAPE_ERROR, "GEMM output shape differs");
    hmath_execution_view c = {output->data, output->storage_count, output->rows, output->columns,
                              output->leading_dimension};
    validated_view aa, bb, cc;
    size_t bytes = precision == 32 ? sizeof(float) : sizeof(double);
    hmath_status status = validate_view(a, bytes, execution->max_elements, &aa);
    if (!status)
        status = validate_view(b, bytes, execution->max_elements, &bb);
    if (!status)
        status = validate_view(&c, bytes, execution->max_elements, &cc);
    if (status)
        return status;
    if (overlap(&aa, &cc) || overlap(&bb, &cc))
        return hm_error(HMATH_INVALID_ARGUMENT, "GEMM output overlaps an input span");
    if (a->columns && cc.count > SIZE_MAX / a->columns)
        return hm_error(HMATH_OVERFLOW, "GEMM work count overflows size_t");
    size_t work = cc.count * a->columns;
    if (execution->max_multiply_adds && work > execution->max_multiply_adds)
        return hm_error(HMATH_OVERFLOW, "configured multiply-add limit exceeded");
    status = hm_enter(context);
    if (status)
        return status;
    if (precision == 32 ? !isfinite(*(const float *)alpha) : !isfinite(*(const double *)alpha)) {
        status = nonfinite(0);
        goto done;
    }
    if (precision == 32 ? !isfinite(*(const float *)beta) : !isfinite(*(const double *)beta)) {
        status = nonfinite(1);
        goto done;
    }
    size_t offset = first_nonfinite(&aa, precision);
    if (offset != SIZE_MAX) {
        status = nonfinite(2 + offset);
        goto done;
    }
    offset = first_nonfinite(&bb, precision);
    if (offset != SIZE_MAX) {
        status = nonfinite(2 + aa.count + offset);
        goto done;
    }
    offset = first_nonfinite(&cc, precision);
    if (offset != SIZE_MAX) {
        status = nonfinite(2 + aa.count + bb.count + offset);
        goto done;
    }
    int code;
    if (execution->backend && a->rows && b->columns && a->columns) {
        code = hm_backend_real_gemm(
            execution->backend, precision, (int64_t)a->rows, (int64_t)b->columns,
            (int64_t)a->columns, alpha, a->data, (int64_t)a->leading_dimension, b->data,
            (int64_t)b->leading_dimension, beta, output->data, (int64_t)output->leading_dimension);
        if (code) {
            status = hm_error(code == 2 ? HMATH_INVALID_ARGUMENT : HMATH_UNSUPPORTED,
                              "selected provider cannot execute this GEMM dtype/extent");
            goto done;
        }
        offset = first_nonfinite(&cc, precision);
        if (offset != SIZE_MAX) {
            status = nonfinite(offset);
            goto done;
        }
    } else {
        if (precision == 32)
            code = hm_execution_reference_f32(a->rows, b->columns, a->columns,
                                              *(const float *)alpha, a->data, a->leading_dimension,
                                              b->data, b->leading_dimension, *(const float *)beta,
                                              output->data, output->leading_dimension);
        else
            code = hm_execution_reference_f64(a->rows, b->columns, a->columns,
                                              *(const double *)alpha, a->data, a->leading_dimension,
                                              b->data, b->leading_dimension, *(const double *)beta,
                                              output->data, output->leading_dimension);
        if (code) {
            status = (hmath_status)code;
            goto done;
        }
    }
    status =
        hm_cancelled(context)
            ? hm_error(HMATH_CANCELLED, "execution cancelled after kernel; output may be modified")
            : hm_error(HMATH_OK, "");
done:
    hm_leave();
    return status;
}
hmath_status hmath_execution_gemm_f32(hmath_execution *execution, hmath_context *context,
                                      float alpha, const hmath_execution_view *a,
                                      const hmath_execution_view *b, float beta,
                                      const hmath_execution_output *c) {
    return gemm(execution, context, 32, &alpha, a, b, &beta, c);
}
hmath_status hmath_execution_gemm_f64(hmath_execution *execution, hmath_context *context,
                                      double alpha, const hmath_execution_view *a,
                                      const hmath_execution_view *b, double beta,
                                      const hmath_execution_output *c) {
    return gemm(execution, context, 64, &alpha, a, b, &beta, c);
}
