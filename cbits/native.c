/* SPDX-License-Identifier: MPL-2.0 */
#include "native_internal.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <malloc.h>
#endif
static _Thread_local hmath_status last_code;
static _Thread_local char last_message[256];
hmath_status hm_error(hmath_status code, const char *message) {
    last_code = code;
    (void)snprintf(last_message, sizeof last_message, "%s", message ? message : "");
    return code;
}
hmath_status hmath_last_error_code(void) { return last_code; }
const char *hmath_last_error_message(void) { return last_message; }
const char *hmath_status_string(hmath_status s) {
    static const char *const names[] = {"ok",
                                        "invalid argument",
                                        "shape mismatch",
                                        "overflow or nonfinite result",
                                        "allocation failed",
                                        "runtime unavailable",
                                        "Haskell exception",
                                        "cancelled",
                                        "bounds error",
                                        "busy",
                                        "unsupported"};
    return (unsigned)s < sizeof names / sizeof names[0] ? names[s] : "unknown status";
}
uint32_t hmath_abi_version(void) { return HMATH_ABI_VERSION; }
const char *hmath_library_version(void) { return "1.0.1"; }
const char *hmath_build_info(void) {
    return "HMath ABI 1; C11; GHC threaded RTS; binary64; max-rank=8";
}
const char *hmath_backend_version(void) {
    return "native tensor kernels: Haskell reference binary64";
}
int hm_cancelled(const hmath_context *context) {
    return context && atomic_load_explicit(&context->cancelled, memory_order_acquire);
}
hmath_status hmath_context_create(hmath_context **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL context output");
    *out = calloc(1, sizeof **out);
    if (!*out)
        return hm_error(HMATH_ALLOCATION_FAILED, "context allocation failed");
    atomic_init(&(*out)->refs, 1);
    atomic_init(&(*out)->cancelled, 0);
    return hm_error(HMATH_OK, "");
}
void hmath_context_retain(hmath_context *c) {
    if (c)
        atomic_fetch_add_explicit(&c->refs, 1, memory_order_relaxed);
}
void hmath_context_release(hmath_context *c) {
    if (c && atomic_fetch_sub_explicit(&c->refs, 1, memory_order_acq_rel) == 1)
        free(c);
}
void hmath_context_cancel(hmath_context *c) {
    if (c)
        atomic_store_explicit(&c->cancelled, 1, memory_order_release);
}
void hmath_context_reset(hmath_context *c) {
    if (c)
        atomic_store_explicit(&c->cancelled, 0, memory_order_release);
}
hmath_status hmath_buffer_alloc(size_t bytes, size_t alignment, void **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL allocation output");
    *out = NULL;
    if (alignment < sizeof(void *) || alignment > 4096 || (alignment & (alignment - 1)))
        return hm_error(HMATH_INVALID_ARGUMENT,
                        "alignment must be a power of two between pointer size and 4096");
    if (bytes > HMATH_MAX_ELEMENTS * sizeof(double) || bytes > SIZE_MAX - alignment)
        return hm_error(HMATH_OVERFLOW, "allocation exceeds buffer budget");
    size_t rounded = bytes ? (bytes + alignment - 1) & ~(alignment - 1) : alignment;
#ifdef _WIN32
    *out = _aligned_malloc(rounded, alignment);
#else
    *out = aligned_alloc(alignment, rounded);
#endif
    return hm_error(*out ? HMATH_OK : HMATH_ALLOCATION_FAILED,
                    *out ? "" : "aligned allocation failed");
}
void hmath_buffer_free(void *buffer) {
#ifdef _WIN32
    _aligned_free(buffer);
#else
    free(buffer);
#endif
}
static void owned_deleter(void *userdata, const double *data) {
    (void)userdata;
    hmath_buffer_free((void *)data);
}
static hmath_status validate_layout(const size_t *shape, const size_t *strides, size_t rank,
                                    size_t *count, size_t *span, size_t *out_strides) {
    if (rank > HMATH_MAX_RANK || (rank && !shape))
        return hm_error(HMATH_SHAPE_ERROR, "rank must be 0..8 and shape present for nonzero rank");
    /* Scan zeros first: an empty tensor is empty regardless of where its
     * zero dimension occurs, even if a nonzero prefix product is huge. */
    size_t n = 1;
    for (size_t i = 0; i < rank; ++i) {
        if (shape[i] == 0)
            n = 0;
    }
    for (size_t i = 0; i < rank; ++i) {
        if (shape[i] > HMATH_MAX_ELEMENTS)
            return hm_error(HMATH_OVERFLOW, "dimension exceeds element budget");
        if (shape[i] && n > HMATH_MAX_ELEMENTS / shape[i])
            return hm_error(HMATH_OVERFLOW, "shape product exceeds element budget");
        n *= shape[i];
    }
    size_t stride = 1;
    for (size_t i = rank; i > 0; --i) {
        out_strides[i - 1] = strides ? strides[i - 1] : stride;
        if (out_strides[i - 1] > HMATH_MAX_ELEMENTS)
            return hm_error(HMATH_OVERFLOW, "stride exceeds storage budget");
        /* Empty shapes still need a representable canonical stride. */
        if (shape[i - 1] && stride > HMATH_MAX_ELEMENTS / shape[i - 1])
            stride = 0;
        else
            stride *= shape[i - 1];
    }
    size_t reachable = n ? 1 : 0;
    if (n)
        for (size_t i = 0; i < rank; ++i) {
            if (out_strides[i] != 0 &&
                shape[i] - 1 > (HMATH_MAX_ELEMENTS - reachable) / out_strides[i])
                return hm_error(HMATH_OVERFLOW, "strided span exceeds element budget");
            reachable += (shape[i] - 1) * out_strides[i];
        }
    *count = n;
    *span = reachable;
    return HMATH_OK;
}
static size_t element_offset(const hmath_tensor *t, size_t linear) {
    size_t result = 0;
    for (size_t i = t->rank; i > 0; --i) {
        result += (linear % t->shape[i - 1]) * t->strides[i - 1];
        linear /= t->shape[i - 1];
    }
    return result;
}
static int is_contiguous(const hmath_tensor *t) {
    if (t->count == 0)
        return 1;
    size_t step = 1;
    for (size_t i = t->rank; i > 0; --i) {
        if (t->shape[i - 1] > 1 && t->strides[i - 1] != step)
            return 0;
        step *= t->shape[i - 1];
    }
    return 1;
}
hmath_status hmath_tensor_borrow(const double *data, size_t storage_count, const size_t *shape,
                                 const size_t *strides, size_t rank, hmath_buffer_deleter deleter,
                                 void *userdata, hmath_tensor **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL tensor output");
    *out = NULL;
    size_t n, span, steps[HMATH_MAX_RANK];
    hmath_status s = validate_layout(shape, strides, rank, &n, &span, steps);
    if (s)
        return s;
    if (storage_count > HMATH_MAX_ELEMENTS || span > storage_count)
        return hm_error(HMATH_BOUNDS_ERROR, "reachable tensor span exceeds backing buffer");
    if ((span && !data) || (data && (uintptr_t)data % _Alignof(double)))
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL or misaligned tensor storage");
    hmath_tensor *t = calloc(1, sizeof *t);
    hmath_storage *storage = calloc(1, sizeof *storage);
    if (!t || !storage) {
        free(t);
        free(storage);
        return hm_error(HMATH_ALLOCATION_FAILED, "tensor allocation failed");
    }
    atomic_init(&t->refs, 1);
    atomic_init(&storage->refs, 1);
    t->rank = rank;
    t->count = n;
    t->storage = storage;
    storage->data = data;
    storage->count = storage_count;
    storage->deleter = deleter;
    storage->userdata = userdata;
    for (size_t i = 0; i < rank; ++i) {
        t->shape[i] = shape[i];
        t->strides[i] = steps[i];
    }
    for (size_t i = 0; i < n; ++i)
        if (!isfinite(data[element_offset(t, i)])) {
            free(storage);
            free(t);
            return hm_error(HMATH_INVALID_ARGUMENT, "tensor values must be finite");
        }
    *out = t;
    return hm_error(HMATH_OK, "");
}
hmath_status hmath_tensor_copy(const double *data, size_t count, const size_t *shape, size_t rank,
                               hmath_tensor **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL tensor output");
    *out = NULL;
    size_t n, span, strides[HMATH_MAX_RANK];
    hmath_status s = validate_layout(shape, NULL, rank, &n, &span, strides);
    if (s)
        return s;
    if (n != count)
        return hm_error(HMATH_SHAPE_ERROR, "count must equal shape product");
    if ((count && !data) || (data && (uintptr_t)data % _Alignof(double)))
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL or misaligned copy input");
    double *copy;
    s = hmath_buffer_alloc(count * sizeof(double), 64, (void **)&copy);
    if (s)
        return s;
    if (count)
        memcpy(copy, data, count * sizeof(double));
    s = hmath_tensor_borrow(copy, count, shape, NULL, rank, owned_deleter, NULL, out);
    if (s)
        hmath_buffer_free(copy);
    return s;
}
hmath_status hmath_vector_copy(const double *data, size_t count, hmath_vector **out) {
    return hmath_tensor_copy(data, count, &count, 1, out);
}
hmath_status hmath_matrix_copy(const double *data, size_t count, size_t rows, size_t columns,
                               hmath_matrix **out) {
    size_t shape[] = {rows, columns};
    return hmath_tensor_copy(data, count, shape, 2, out);
}
void hmath_tensor_retain(hmath_tensor *t) {
    if (t)
        atomic_fetch_add_explicit(&t->refs, 1, memory_order_relaxed);
}
void hmath_tensor_release(hmath_tensor *t) {
    if (t && atomic_fetch_sub_explicit(&t->refs, 1, memory_order_acq_rel) == 1) {
        hmath_storage *s = t->storage;
        if (atomic_fetch_sub_explicit(&s->refs, 1, memory_order_acq_rel) == 1) {
            if (s->deleter)
                s->deleter(s->userdata, s->data);
            free(s);
        }
        free(t);
    }
}
size_t hmath_tensor_rank(const hmath_tensor *t) { return t ? t->rank : 0; }
size_t hmath_tensor_count(const hmath_tensor *t) { return t ? t->count : 0; }
hmath_status hmath_tensor_metadata(const hmath_tensor *t, size_t *shape, size_t *strides,
                                   size_t capacity) {
    if (!t || (t->rank && (!shape || !strides)))
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL metadata argument");
    if (capacity < t->rank)
        return hm_error(HMATH_BOUNDS_ERROR, "metadata capacity smaller than rank");
    for (size_t i = 0; i < t->rank; ++i) {
        shape[i] = t->shape[i];
        strides[i] = t->strides[i];
    }
    return hm_error(HMATH_OK, "");
}
hmath_status hmath_tensor_copy_to(const hmath_tensor *t, double *out, size_t capacity) {
    if (!t || (t->count && (!out || (uintptr_t)out % _Alignof(double))))
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL or misaligned copy output");
    if (capacity < t->count)
        return hm_error(HMATH_BOUNDS_ERROR, "output capacity smaller than tensor");
    /* Output must not overlap input storage. memcpy aliasing and in-place
       strided permutations are intentionally outside this copy contract. */
    if (t->count &&
        (uintptr_t)out < (uintptr_t)t->storage->data + t->storage->count * sizeof(double) &&
        (uintptr_t)t->storage->data < (uintptr_t)out + t->count * sizeof(double))
        return hm_error(HMATH_INVALID_ARGUMENT, "copy output overlaps input storage");
    for (size_t i = 0; i < t->count; ++i)
        out[i] = t->storage->data[element_offset(t, i)];
    return hm_error(HMATH_OK, "");
}
hmath_status hmath_tensor_data(const hmath_tensor *t, const double **data, size_t *storage_count) {
    if (!t || !data || !storage_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL data query argument");
    *data = t->storage->data;
    *storage_count = t->storage->count;
    return hm_error(HMATH_OK, "");
}
hmath_status hmath_tensor_reshape(const hmath_tensor *t, const size_t *shape, size_t rank,
                                  hmath_tensor **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL reshape output");
    *out = NULL;
    if (!t)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL reshape input");
    size_t n, span, strides[HMATH_MAX_RANK];
    hmath_status s = validate_layout(shape, NULL, rank, &n, &span, strides);
    if (s)
        return s;
    if (n != t->count || !is_contiguous(t))
        return hm_error(HMATH_SHAPE_ERROR,
                        "reshape needs equal element count and contiguous storage");
    hmath_tensor *r = calloc(1, sizeof *r);
    if (!r)
        return hm_error(HMATH_ALLOCATION_FAILED, "reshape allocation failed");
    atomic_init(&r->refs, 1);
    r->rank = rank;
    r->count = n;
    r->storage = t->storage;
    atomic_fetch_add_explicit(&r->storage->refs, 1, memory_order_relaxed);
    for (size_t i = 0; i < rank; ++i) {
        r->shape[i] = shape[i];
        r->strides[i] = strides[i];
    }
    *out = r;
    return hm_error(HMATH_OK, "");
}
static hmath_status gather_values(const hmath_tensor *t, double **out) {
    if (!t)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL tensor");
    *out = malloc((t->count ? t->count : 1) * sizeof(double));
    if (!*out)
        return hm_error(HMATH_ALLOCATION_FAILED, "kernel scratch allocation failed");
    for (size_t i = 0; i < t->count; ++i)
        (*out)[i] = t->storage->data[element_offset(t, i)];
    return HMATH_OK;
}
static int same_shape(const hmath_tensor *a, const hmath_tensor *b) {
    if (!a || !b || a->rank != b->rank)
        return 0;
    for (size_t i = 0; i < a->rank; ++i)
        if (a->shape[i] != b->shape[i])
            return 0;
    return 1;
}
/* The runtime reservation covers all Haskell execution. Cancellation is
 * checked again before publishing a result; it never interrupts the RTS. */
static hmath_status finish_kernel(hmath_context *context, int code) {
    hm_leave();
    if (code)
        return hm_error((hmath_status)code, hmath_status_string((hmath_status)code));
    if (hm_cancelled(context))
        return hm_error(HMATH_CANCELLED, "context cancelled before result publication");
    return hm_error(HMATH_OK, "");
}
hmath_status hmath_scalar_add(hmath_context *context, double a, double b, double *out) {
    if (!out || (uintptr_t)out % _Alignof(double) || !isfinite(a) || !isfinite(b))
        return hm_error(HMATH_INVALID_ARGUMENT, "finite scalar inputs and aligned output required");
    hmath_status s = hm_enter(context);
    if (s)
        return s;
    double result;
    int code = hm_haskell_kernel(0, &a, &b, 1, 0, 0, 0, &result);
    s = finish_kernel(context, code);
    if (!s)
        *out = result;
    return s;
}
static hmath_status scalar_kernel(hmath_context *context, int op, const hmath_tensor *a,
                                  const hmath_tensor *b, double *out) {
    if (!a || !out || (uintptr_t)out % _Alignof(double) || (op == 2 && !b))
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL reduction argument or misaligned output");
    if (op == 2 && !same_shape(a, b))
        return hm_error(HMATH_SHAPE_ERROR, "dot requires equal shapes");
    hmath_status s = hm_enter(context);
    if (s)
        return s;
    double *xs = NULL, *ys = NULL, result;
    s = gather_values(a, &xs);
    if (!s && b)
        s = gather_values(b, &ys);
    if (s) {
        free(xs);
        free(ys);
        hm_leave();
        return s;
    }
    int code = hm_haskell_kernel(op, xs, ys, a->count, 0, 0, 0, &result);
    free(xs);
    free(ys);
    s = finish_kernel(context, code);
    if (!s)
        *out = result;
    return s;
}
hmath_status hmath_tensor_sum(hmath_context *c, const hmath_tensor *a, double *out) {
    return scalar_kernel(c, 1, a, NULL, out);
}
hmath_status hmath_tensor_dot(hmath_context *c, const hmath_tensor *a, const hmath_tensor *b,
                              double *out) {
    return scalar_kernel(c, 2, a, b, out);
}
static hmath_status tensor_kernel(hmath_context *context, int op, const hmath_tensor *a,
                                  const hmath_tensor *b, hmath_tensor **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL tensor result");
    *out = NULL;
    if (!a || !b)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL tensor operand");
    size_t shape[HMATH_MAX_RANK], rank = a->rank, n = a->count, rows = 0, inner = 0, columns = 0;
    if (op == 3) {
        if (!same_shape(a, b))
            return hm_error(HMATH_SHAPE_ERROR, "addition requires equal shapes");
        memcpy(shape, a->shape, rank * sizeof(size_t));
    } else {
        if (a->rank != 2 || b->rank != 2 || a->shape[1] != b->shape[0])
            return hm_error(HMATH_SHAPE_ERROR,
                            "matrix product requires compatible rank-2 operands");
        rows = a->shape[0];
        inner = a->shape[1];
        columns = b->shape[1];
        rank = 2;
        shape[0] = rows;
        shape[1] = columns;
        if (columns && rows > HMATH_MAX_ELEMENTS / columns)
            return hm_error(HMATH_OVERFLOW, "matrix output exceeds element budget");
        n = rows * columns;
        if (inner && n > 16777216u / inner)
            return hm_error(HMATH_OVERFLOW, "matrix product exceeds work budget");
    }
    hmath_status s = hm_enter(context);
    if (s)
        return s;
    double *xs = NULL, *ys = NULL, *result = NULL;
    s = gather_values(a, &xs);
    if (!s)
        s = gather_values(b, &ys);
    if (!s) {
        result = malloc((n ? n : 1) * sizeof(double));
        if (!result)
            s = hm_error(HMATH_ALLOCATION_FAILED, "result allocation failed");
    }
    if (s) {
        free(xs);
        free(ys);
        free(result);
        hm_leave();
        return s;
    }
    int code = hm_haskell_kernel(op, xs, ys, a->count, rows, inner, columns, result);
    free(xs);
    free(ys);
    s = finish_kernel(context, code);
    if (!s)
        s = hmath_tensor_copy(result, n, shape, rank, out);
    free(result);
    return s;
}
hmath_status hmath_tensor_add(hmath_context *c, const hmath_tensor *a, const hmath_tensor *b,
                              hmath_tensor **out) {
    return tensor_kernel(c, 3, a, b, out);
}
hmath_status hmath_tensor_matmul(hmath_context *c, const hmath_tensor *a, const hmath_tensor *b,
                                 hmath_tensor **out) {
    return tensor_kernel(c, 4, a, b, out);
}
hmath_status hmath_tensor_map(hmath_context *c, const hmath_tensor *t, hmath_map_callback callback,
                              void *userdata, hmath_tensor **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL map output");
    *out = NULL;
    if (!t || !callback)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL map input or callback");
    hmath_status s = hm_enter(c);
    if (s)
        return s;
    double *result = malloc((t->count ? t->count : 1) * sizeof(double));
    if (!result) {
        hm_leave();
        return hm_error(HMATH_ALLOCATION_FAILED, "map allocation failed");
    }
    for (size_t i = 0; i < t->count; ++i) {
        if (hm_cancelled(c)) {
            s = HMATH_CANCELLED;
            break;
        }
        s = callback(t->storage->data[element_offset(t, i)], i, userdata, &result[i]);
        if (s)
            break;
        if (!isfinite(result[i])) {
            s = HMATH_OVERFLOW;
            break;
        }
    }
    s = finish_kernel(c, s);
    if (!s)
        s = hmath_tensor_copy(result, t->count, t->shape, t->rank, out);
    free(result);
    return s;
}
hmath_status hmath_batch_sum(hmath_context *c, const hmath_tensor *const *inputs, size_t count,
                             double *out, size_t *completed) {
    if (!completed || (uintptr_t)completed % _Alignof(size_t))
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL or misaligned completed output");
    *completed = 0;
    if (count > 4096)
        return hm_error(HMATH_OVERFLOW, "batch exceeds 4096 operations");
    if (count && (!inputs || !out || (uintptr_t)out % _Alignof(double)))
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL batch input or NULL/misaligned output");
    for (size_t i = 0; i < count; ++i) {
        hmath_status s = hmath_tensor_sum(c, inputs[i], &out[i]);
        if (s)
            return s;
        *completed = i + 1;
    }
    return hm_error(HMATH_OK, "");
}
