/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_autodiff.h"
#include "native_internal.h"
#include "value_internal.h"
#include <stdlib.h>
#include <string.h>
enum { EXPR, GRAPH, GRADIENT, TENSOR, DUAL };
struct hmath_ad_handle {
    atomic_size_t refs;
    int kind;
    void *stable;
};
extern void hm_ad_free(void *);
extern int hm_ad_make(int, void *const *, size_t, ptrdiff_t, double, const double *, size_t,
                      const ptrdiff_t *, size_t, const ptrdiff_t *, size_t, void **);
extern int hm_ad_metadata(void *, size_t *, size_t *);
extern int hm_ad_data(void *, double *, ptrdiff_t *);
extern int hm_ad_tensor_values(void *, void **);
extern int hm_ad_run(int, void *const *, size_t, const double *, size_t, const double *, size_t,
                     double, double *);
static int is_kind(const hmath_ad_handle *v, int kind) { return v && v->kind == kind; }
static int all_kind(const hmath_ad_handle *const *vs, size_t count, int kind) {
    if (count > (size_t)PTRDIFF_MAX / sizeof(void *) || (count && !vs))
        return 0;
    for (size_t i = 0; i < count; ++i)
        if (!is_kind(vs[i], kind))
            return 0;
    return 1;
}
static hmath_status bad_kind(void) {
    return hm_error(HMATH_INVALID_ARGUMENT, "incorrect AD handle kind");
}
static int span(const void *p, size_t n, size_t item) {
    return n <= (size_t)PTRDIFF_MAX / item && (!n || p);
}
static void **stable_inputs(const hmath_ad_handle *const *inputs, size_t count) {
    void **p = malloc((count ? count : 1) * sizeof *p);
    if (p)
        for (size_t i = 0; i < count; ++i)
            p[i] = inputs[i]->stable;
    return p;
}
void hmath_ad_retain(hmath_ad_handle *v) {
    if (v)
        atomic_fetch_add_explicit(&v->refs, 1, memory_order_relaxed);
}
void hmath_ad_release(hmath_ad_handle *v) {
    if (v && atomic_fetch_sub_explicit(&v->refs, 1, memory_order_acq_rel) == 1) {
        hm_ad_free(v->stable);
        free(v);
        hm_leave();
    }
}
static hmath_status make(hmath_context *context, int kind, int op,
                         const hmath_ad_handle *const *inputs, size_t count, ptrdiff_t index,
                         double scalar, const double *values, size_t value_count,
                         const ptrdiff_t *shape, size_t rank, const ptrdiff_t *axes,
                         size_t axis_count, hmath_ad_handle **out) {
    if (!out || !span(inputs, count, sizeof(void *)) ||
        !span(values, value_count, sizeof(double)) || !span(shape, rank, sizeof(ptrdiff_t)) ||
        !span(axes, axis_count, sizeof(ptrdiff_t)))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid AD array span or output");
    for (size_t i = 0; i < count; ++i)
        if (!inputs[i])
            return bad_kind();
    hmath_ad_handle *value = malloc(sizeof *value);
    void **stable = stable_inputs(inputs, count);
    if (!value || !stable) {
        free(value);
        free(stable);
        return hm_error(HMATH_ALLOCATION_FAILED, "AD handle allocation failed");
    }
    hmath_status status = hm_enter(context);
    if (status) {
        free(value);
        free(stable);
        return status;
    }
    status = (hmath_status)hm_ad_make(op, stable, count, index, scalar, values, value_count, shape,
                                      rank, axes, axis_count, &value->stable);
    free(stable);
    if (status) {
        free(value);
        hm_leave();
        return status;
    }
    value->kind = kind;
    atomic_init(&value->refs, 1);
    *out = value;
    return HMATH_OK;
}
static hmath_status run(hmath_context *context, int operation, const hmath_ad_handle *const *inputs,
                        size_t count, const double *values, size_t n, const double *direction,
                        size_t direction_count, double scalar, double *out, size_t capacity,
                        size_t required) {
    if (!span(inputs, count, sizeof(void *)) || !span(values, n, sizeof(double)) ||
        !span(direction, direction_count, sizeof(double)) || !span(out, required, sizeof(double)))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid AD evaluation span");
    if (capacity < required)
        return hm_error(HMATH_BOUNDS_ERROR, "insufficient AD result capacity");
    void **stable = stable_inputs(inputs, count);
    if (!stable)
        return hm_error(HMATH_ALLOCATION_FAILED, "AD input allocation failed");
    hmath_status status = hm_enter(context);
    if (!status) {
        status = (hmath_status)hm_ad_run(operation, stable, count, values, n, direction,
                                         direction_count, scalar, out);
        hm_leave();
    }
    free(stable);
    return status;
}
hmath_status hmath_ad_variable(hmath_context *context, ptrdiff_t index, hmath_ad_expr **out) {
    return make(context, EXPR, 0, NULL, 0, index, 0, NULL, 0, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_constant(hmath_context *context, double value, hmath_ad_expr **out) {
    return make(context, EXPR, 1, NULL, 0, 0, value, NULL, 0, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_dual_create(hmath_context *context, double primal, double tangent,
                                  hmath_ad_dual **out) {
    double values[] = {primal, tangent};
    return make(context, DUAL, 2, NULL, 0, 0, 0, values, 2, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_unary(hmath_context *context, hmath_ad_unary_operation operation,
                            const hmath_ad_handle *value, hmath_ad_handle **out) {
    if (!value || (value->kind != EXPR && value->kind != DUAL) ||
        (unsigned)operation > HMATH_AD_STOP_GRADIENT ||
        (value->kind == DUAL && operation >= HMATH_AD_DETACH))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid AD unary input");
    const hmath_ad_handle *inputs[] = {value};
    return make(context, value->kind, 3, inputs, 1, operation, 0, NULL, 0, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_binary(hmath_context *context, hmath_ad_binary_operation operation,
                             const hmath_ad_handle *left, const hmath_ad_handle *right,
                             hmath_ad_handle **out) {
    if (!left || !right || left->kind != right->kind ||
        (left->kind != EXPR && left->kind != DUAL) || (unsigned)operation > HMATH_AD_POWER)
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid AD binary input");
    const hmath_ad_handle *inputs[] = {left, right};
    return make(context, left->kind, 4, inputs, 2, operation, 0, NULL, 0, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_compile_graph(hmath_context *context, ptrdiff_t index,
                                    const hmath_ad_expr *expression, hmath_ad_graph **out) {
    if (!is_kind(expression, EXPR))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {expression};
    return make(context, GRAPH, 5, inputs, 1, index, 0, NULL, 0, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_differentiate(hmath_context *context, ptrdiff_t index,
                                    const hmath_ad_expr *expression, hmath_ad_expr **out) {
    if (!is_kind(expression, EXPR))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {expression};
    return make(context, EXPR, 6, inputs, 1, index, 0, NULL, 0, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_zero_gradients(hmath_context *context, ptrdiff_t count,
                                     hmath_ad_gradient_state **out) {
    return make(context, GRADIENT, 7, NULL, 0, count, 0, NULL, 0, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_gradient_state_create(hmath_context *context, const double *values,
                                            size_t count, hmath_ad_gradient_state **out) {
    return make(context, GRADIENT, 20, NULL, 0, 0, 0, values, count, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_accumulate_gradients(hmath_context *context,
                                           const hmath_ad_gradient_state *state,
                                           const double *values, size_t count,
                                           hmath_ad_gradient_state **out) {
    if (!is_kind(state, GRADIENT))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {state};
    return make(context, GRADIENT, 8, inputs, 1, 0, 0, values, count, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_gradient_hook_result(hmath_context *context,
                                           const hmath_ad_gradient_state *state,
                                           const double *values, size_t count,
                                           hmath_ad_gradient_state **out) {
    if (!is_kind(state, GRADIENT))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {state};
    return make(context, GRADIENT, 19, inputs, 1, 0, 0, values, count, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_reset_gradients(hmath_context *context, const hmath_ad_gradient_state *state,
                                      hmath_ad_gradient_state **out) {
    if (!is_kind(state, GRADIENT))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {state};
    return make(context, GRADIENT, 9, inputs, 1, 0, 0, NULL, 0, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_clip_gradient(hmath_context *context, double limit, const double *values,
                                    size_t count, hmath_ad_gradient_state **out) {
    return make(context, GRADIENT, 10, NULL, 0, 0, limit, values, count, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_tensor_create(hmath_context *context, const ptrdiff_t *shape, size_t rank,
                                    const hmath_ad_expr *const *values, size_t count,
                                    hmath_ad_tensor **out) {
    if (!all_kind(values, count, EXPR))
        return bad_kind();
    return make(context, TENSOR, 11, values, count, 0, 0, NULL, 0, shape, rank, NULL, 0, out);
}
hmath_status hmath_ad_broadcast(hmath_context *context, const ptrdiff_t *shape, size_t rank,
                                const hmath_ad_tensor *tensor, hmath_ad_tensor **out) {
    if (!is_kind(tensor, TENSOR))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {tensor};
    return make(context, TENSOR, 12, inputs, 1, 0, 0, NULL, 0, shape, rank, NULL, 0, out);
}
hmath_status hmath_ad_tensor_add(hmath_context *context, const hmath_ad_tensor *left,
                                 const hmath_ad_tensor *right, hmath_ad_tensor **out) {
    if (!is_kind(left, TENSOR) || !is_kind(right, TENSOR))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {left, right};
    return make(context, TENSOR, 13, inputs, 2, 0, 0, NULL, 0, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_tensor_multiply(hmath_context *context, const hmath_ad_tensor *left,
                                      const hmath_ad_tensor *right, hmath_ad_tensor **out) {
    if (!is_kind(left, TENSOR) || !is_kind(right, TENSOR))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {left, right};
    return make(context, TENSOR, 14, inputs, 2, 0, 0, NULL, 0, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_matmul(hmath_context *context, const hmath_ad_tensor *left,
                             const hmath_ad_tensor *right, hmath_ad_tensor **out) {
    if (!is_kind(left, TENSOR) || !is_kind(right, TENSOR))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {left, right};
    return make(context, TENSOR, 15, inputs, 2, 0, 0, NULL, 0, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_contract(hmath_context *context, const ptrdiff_t *left_axes,
                               size_t left_count, const ptrdiff_t *right_axes, size_t right_count,
                               const hmath_ad_tensor *left, const hmath_ad_tensor *right,
                               hmath_ad_tensor **out) {
    if (!is_kind(left, TENSOR) || !is_kind(right, TENSOR))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {left, right};
    return make(context, TENSOR, 16, inputs, 2, 0, 0, NULL, 0, left_axes, left_count, right_axes,
                right_count, out);
}
hmath_status hmath_ad_sum(hmath_context *context, const hmath_ad_tensor *tensor,
                          hmath_ad_expr **out) {
    if (!is_kind(tensor, TENSOR))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {tensor};
    return make(context, EXPR, 17, inputs, 1, 0, 0, NULL, 0, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_evaluate_graph(hmath_context *context, const hmath_ad_graph *expression,
                                     const double *values, size_t n, double *out, size_t capacity) {
    if (!is_kind(expression, GRAPH))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {expression};
    return run(context, 0, inputs, 1, values, n, NULL, 0, 0, out, capacity, 1);
}
hmath_status hmath_ad_value_and_gradient(hmath_context *context, const hmath_ad_expr *expression,
                                         const double *values, size_t n, double *out,
                                         size_t capacity) {
    if (!is_kind(expression, EXPR))
        return bad_kind();
    if (n == SIZE_MAX)
        return hm_error(HMATH_OVERFLOW, "gradient size overflow");
    const hmath_ad_handle *inputs[] = {expression};
    return run(context, 1, inputs, 1, values, n, NULL, 0, 0, out, capacity, n + 1);
}
hmath_status hmath_ad_gradient(hmath_context *context, const hmath_ad_expr *expression,
                               const double *values, size_t n, double *out, size_t capacity) {
    if (!is_kind(expression, EXPR))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {expression};
    return run(context, 2, inputs, 1, values, n, NULL, 0, 0, out, capacity, n);
}
hmath_status hmath_ad_hessian(hmath_context *context, const hmath_ad_expr *expression,
                              const double *values, size_t n, double *out, size_t capacity) {
    if (!is_kind(expression, EXPR))
        return bad_kind();
    if (n && n > SIZE_MAX / n)
        return hm_error(HMATH_OVERFLOW, "Hessian size overflow");
    const hmath_ad_handle *inputs[] = {expression};
    return run(context, 3, inputs, 1, values, n, NULL, 0, 0, out, capacity, n * n);
}
hmath_status hmath_ad_hvp(hmath_context *context, const hmath_ad_expr *expression,
                          const double *values, size_t n, const double *direction,
                          size_t direction_count, double *out, size_t capacity) {
    if (!is_kind(expression, EXPR))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {expression};
    return run(context, 7, inputs, 1, values, n, direction, direction_count, 0, out, capacity, n);
}
hmath_status hmath_ad_gradient_check(hmath_context *context, const hmath_ad_expr *expression,
                                     const double *values, size_t n, double step, double *out,
                                     size_t capacity) {
    if (!is_kind(expression, EXPR))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {expression};
    return run(context, 8, inputs, 1, values, n, NULL, 0, step, out, capacity, 1);
}
hmath_status hmath_ad_complex_gradient(hmath_context *context, const hmath_ad_expr *expression,
                                       const double *values, size_t n, double *out,
                                       size_t capacity) {
    if (!is_kind(expression, EXPR))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {expression};
    return run(context, 9, inputs, 1, values, n, NULL, 0, 0, out, capacity, 2);
}
hmath_status hmath_ad_jacobian(hmath_context *context, const hmath_ad_expr *const *expressions,
                               size_t count, const double *values, size_t n, double *out,
                               size_t capacity) {
    if (!all_kind(expressions, count, EXPR))
        return bad_kind();
    if (n && count > SIZE_MAX / n)
        return hm_error(HMATH_OVERFLOW, "Jacobian size overflow");
    return run(context, 4, expressions, count, values, n, NULL, 0, 0, out, capacity, count * n);
}
hmath_status hmath_ad_jvp(hmath_context *context, const hmath_ad_expr *const *expressions,
                          size_t count, const double *values, size_t n, const double *direction,
                          size_t direction_count, double *out, size_t capacity) {
    if (!all_kind(expressions, count, EXPR))
        return bad_kind();
    return run(context, 5, expressions, count, values, n, direction, direction_count, 0, out,
               capacity, count);
}
hmath_status hmath_ad_vjp(hmath_context *context, const hmath_ad_expr *const *expressions,
                          size_t count, const double *values, size_t n, const double *direction,
                          size_t direction_count, double *out, size_t capacity) {
    if (!all_kind(expressions, count, EXPR))
        return bad_kind();
    return run(context, 6, expressions, count, values, n, direction, direction_count, 0, out,
               capacity, n);
}
hmath_status hmath_ad_forward_jvp_result(hmath_context *context,
                                         const hmath_ad_dual *const *expressions, size_t count,
                                         const double *values, size_t n, const double *direction,
                                         size_t direction_count, double *out, size_t capacity) {
    if (!all_kind(expressions, count, DUAL))
        return bad_kind();
    if (count > SIZE_MAX / 2)
        return hm_error(HMATH_OVERFLOW, "dual result size overflow");
    return run(context, 10, expressions, count, values, n, direction, direction_count, 0, out,
               capacity, count * 2);
}

hmath_status hmath_ad_metadata(const hmath_ad_handle *v, size_t *count, size_t *rank) {
    if (!v || !count || !rank)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL AD metadata argument");
    hmath_status status = hm_enter(NULL);
    if (!status) {
        status = (hmath_status)hm_ad_metadata(v->stable, count, rank);
        hm_leave();
    }
    return status ? status : hm_error(HMATH_OK, "");
}
hmath_status hmath_ad_values_copy(const hmath_ad_handle *v, double *out, size_t capacity) {
    if (!v || (v->kind != GRADIENT && v->kind != DUAL))
        return bad_kind();
    size_t n, rank;
    hmath_status status = hmath_ad_metadata(v, &n, &rank);
    if (status)
        return status ? status : hm_error(HMATH_OK, "");
    if (!span(out, n, sizeof(double)))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid AD value output span");
    if (capacity < n)
        return hm_error(HMATH_BOUNDS_ERROR, "insufficient AD value capacity");
    status = hm_enter(NULL);
    if (!status) {
        status = (hmath_status)hm_ad_data(v->stable, out, NULL);
        hm_leave();
    }
    return status ? status : hm_error(HMATH_OK, "");
}
hmath_status hmath_ad_shape_copy(const hmath_ad_tensor *v, ptrdiff_t *out, size_t capacity) {
    if (!is_kind(v, TENSOR))
        return bad_kind();
    size_t n, rank;
    hmath_status status = hmath_ad_metadata(v, &n, &rank);
    if (status)
        return status ? status : hm_error(HMATH_OK, "");
    if (!span(out, rank, sizeof(ptrdiff_t)))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid AD shape output span");
    if (capacity < rank)
        return hm_error(HMATH_BOUNDS_ERROR, "insufficient AD shape capacity");
    status = hm_enter(NULL);
    if (!status) {
        status = (hmath_status)hm_ad_data(v->stable, NULL, out);
        hm_leave();
    }
    return status ? status : hm_error(HMATH_OK, "");
}
hmath_status hmath_ad_tensor_values(const hmath_ad_tensor *v, hmath_ad_expr **out,
                                    size_t capacity) {
    if (!is_kind(v, TENSOR))
        return bad_kind();
    size_t n, rank;
    hmath_status status = hmath_ad_metadata(v, &n, &rank);
    if (status)
        return status ? status : hm_error(HMATH_OK, "");
    if (!span(out, n, sizeof(void *)))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid AD expression output span");
    if (capacity < n)
        return hm_error(HMATH_BOUNDS_ERROR, "insufficient AD expression capacity");
    hmath_ad_handle **handles = calloc(n ? n : 1, sizeof *handles);
    void **raw = malloc((n ? n : 1) * sizeof *raw);
    if (!handles || !raw) {
        free(handles);
        free(raw);
        return hm_error(HMATH_ALLOCATION_FAILED, "AD expression array allocation failed");
    }
    size_t allocated = 0;
    for (; allocated < n; ++allocated) {
        handles[allocated] = malloc(sizeof *handles[allocated]);
        if (!handles[allocated]) {
            status = hm_error(HMATH_ALLOCATION_FAILED, "AD expression handle allocation failed");
            break;
        }
        status = hm_enter(NULL);
        if (status) {
            free(handles[allocated]);
            break;
        }
    }
    if (!status)
        status = (hmath_status)hm_ad_tensor_values(v->stable, raw);
    if (!status) {
        for (size_t i = 0; i < n; ++i) {
            handles[i]->kind = EXPR;
            handles[i]->stable = raw[i];
            atomic_init(&handles[i]->refs, 1);
            out[i] = handles[i];
        }
    } else
        for (size_t i = 0; i < allocated; ++i) {
            free(handles[i]);
            hm_leave();
        }
    free(raw);
    free(handles);
    return status ? status : hm_error(HMATH_OK, "");
}

hmath_status hmath_ad_differentiable_step(hmath_context *context, double rate,
                                          const hmath_ad_expr *expression,
                                          const hmath_ad_expr *const *points, size_t count,
                                          hmath_ad_tensor **out) {
    if (!is_kind(expression, EXPR) || !all_kind(points, count, EXPR))
        return bad_kind();
    if (count >= (size_t)PTRDIFF_MAX / sizeof(void *))
        return hm_error(HMATH_OVERFLOW, "differentiable step input size overflow");
    const hmath_ad_handle **inputs = malloc((count + 1) * sizeof *inputs);
    if (!inputs)
        return hm_error(HMATH_ALLOCATION_FAILED, "AD step input allocation failed");
    inputs[0] = expression;
    for (size_t i = 0; i < count; ++i)
        inputs[i + 1] = points[i];
    hmath_status status =
        make(context, TENSOR, 18, inputs, count + 1, 0, rate, NULL, 0, NULL, 0, NULL, 0, out);
    free(inputs);
    return status ? status : hm_error(HMATH_OK, "");
}

extern int hm_ad_clone(void *value, void **out);
extern int hm_ad_callbacks(int operation, void *const *values, size_t count,
                           hmath_ad_rule_callback rule, hmath_ad_unary_callback function,
                           hmath_ad_unary_callback derivative, hmath_ad_builder_callback builder,
                           void *userdata, void **out);

static hmath_status make_callback(hmath_context *context, int operation,
                                  hmath_ad_rule_callback rule, hmath_ad_unary_callback function,
                                  hmath_ad_unary_callback derivative,
                                  hmath_ad_builder_callback builder, void *userdata,
                                  const hmath_ad_expr *const *values, size_t count,
                                  hmath_ad_expr **out) {
    if (!out || !all_kind(values, count, EXPR))
        return bad_kind();
    hmath_ad_handle *value = malloc(sizeof *value);
    void **inputs = stable_inputs(values, count);
    if (!value || !inputs) {
        free(value);
        free(inputs);
        return hm_error(HMATH_ALLOCATION_FAILED, "AD callback allocation failed");
    }
    hmath_status status = hm_enter(context);
    if (status) {
        free(value);
        free(inputs);
        return status;
    }
    status = (hmath_status)hm_ad_callbacks(operation, inputs, count, rule, function, derivative,
                                           builder, userdata, &value->stable);
    free(inputs);
    if (status) {
        free(value);
        hm_leave();
        return status;
    }
    value->kind = EXPR;
    atomic_init(&value->refs, 1);
    *out = value;
    return HMATH_OK;
}
hmath_status hmath_ad_custom_operation(hmath_context *context, hmath_ad_rule_callback callback,
                                       void *userdata, const hmath_ad_expr *const *values,
                                       size_t count, hmath_ad_expr **out) {
    if (!callback)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL custom operation callback");
    return make_callback(context, 0, callback, NULL, NULL, NULL, userdata, values, count, out);
}
hmath_status hmath_ad_custom_unary(hmath_context *context, hmath_ad_unary_callback function,
                                   hmath_ad_unary_callback derivative, void *userdata,
                                   const hmath_ad_expr *value, hmath_ad_expr **out) {
    if (!function || !derivative)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL custom unary callback");
    const hmath_ad_expr *inputs[] = {value};
    return make_callback(context, 1, NULL, function, derivative, NULL, userdata, inputs, 1, out);
}
hmath_status hmath_ad_checkpoint(hmath_context *context, hmath_ad_builder_callback callback,
                                 void *userdata, const hmath_ad_expr *const *values, size_t count,
                                 hmath_ad_expr **out) {
    if (!callback)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL checkpoint callback");
    return make_callback(context, 2, NULL, NULL, NULL, callback, userdata, values, count, out);
}

/* Internal helper called safely from Haskell, allowing a checkpoint builder to
 * reenter the public ABI. Input/output stable pointers are independently cloned
 * so a borrowed callback input cannot outlive the Haskell temporary it came from. */
int hm_ad_invoke_builder(hmath_ad_builder_callback callback, void *userdata, void *const *values,
                         size_t count, void **out, const char **error_message) {
    hmath_ad_handle **inputs = calloc(count ? count : 1, sizeof *inputs);
    if (!inputs) {
        *error_message = "checkpoint input allocation failed";
        return HMATH_ALLOCATION_FAILED;
    }
    size_t allocated = 0;
    hmath_status status = HMATH_OK;
    for (; allocated < count; ++allocated) {
        hmath_ad_handle *value = malloc(sizeof *value);
        if (!value) {
            status = HMATH_ALLOCATION_FAILED;
            *error_message = "checkpoint handle allocation failed";
            break;
        }
        status = hm_enter(NULL);
        if (status) {
            free(value);
            *error_message = "checkpoint runtime reservation failed";
            break;
        }
        status = (hmath_status)hm_ad_clone(values[allocated], &value->stable);
        if (status) {
            free(value);
            hm_leave();
            *error_message = "checkpoint input clone failed";
            break;
        }
        value->kind = EXPR;
        atomic_init(&value->refs, 1);
        inputs[allocated] = value;
    }
    hmath_ad_expr *result = NULL;
    if (!status)
        status =
            callback((const hmath_ad_expr *const *)inputs, count, userdata, &result, error_message);
    if (!status) {
        if (!is_kind(result, EXPR)) {
            status = HMATH_INVALID_ARGUMENT;
            *error_message = "checkpoint builder must return an owned Expr";
        } else
            status = (hmath_status)hm_ad_clone(result->stable, out);
    }
    if (result)
        hmath_ad_release(result);
    for (size_t i = 0; i < allocated; ++i)
        hmath_ad_release(inputs[i]);
    free(inputs);
    return status;
}

extern int hm_ad_dual_depth(void *value, size_t *depth);
extern int hm_ad_dual_parts(void *value, void **primal, void **tangent);

hmath_status hmath_ad_dual_nested(hmath_context *context, const hmath_ad_dual *primal,
                                  const hmath_ad_dual *tangent, hmath_ad_dual **out) {
    if (!is_kind(primal, DUAL) || !is_kind(tangent, DUAL))
        return bad_kind();
    const hmath_ad_handle *inputs[] = {primal, tangent};
    return make(context, DUAL, 21, inputs, 2, 0, 0, NULL, 0, NULL, 0, NULL, 0, out);
}
hmath_status hmath_ad_dual_depth(const hmath_ad_dual *value, size_t *out) {
    if (!is_kind(value, DUAL) || !out)
        return bad_kind();
    hmath_status status = hm_enter(NULL);
    if (!status) {
        status = (hmath_status)hm_ad_dual_depth(value->stable, out);
        hm_leave();
    }
    return status;
}
hmath_status hmath_ad_dual_parts(const hmath_ad_dual *value, hmath_ad_dual **out_primal,
                                 hmath_ad_dual **out_tangent) {
    if (!is_kind(value, DUAL) || !out_primal || !out_tangent)
        return bad_kind();
    hmath_ad_handle *primal = malloc(sizeof *primal), *tangent = malloc(sizeof *tangent);
    if (!primal || !tangent) {
        free(primal);
        free(tangent);
        return hm_error(HMATH_ALLOCATION_FAILED, "Dual component allocation failed");
    }
    hmath_status status = hm_enter(NULL);
    if (status) {
        free(primal);
        free(tangent);
        return status;
    }
    status = hm_enter(NULL);
    if (status) {
        free(primal);
        free(tangent);
        hm_leave();
        return status;
    }
    status = (hmath_status)hm_ad_dual_parts(value->stable, &primal->stable, &tangent->stable);
    if (status) {
        free(primal);
        free(tangent);
        hm_leave();
        hm_leave();
        return status;
    }
    primal->kind = tangent->kind = DUAL;
    atomic_init(&primal->refs, 1);
    atomic_init(&tangent->refs, 1);
    *out_primal = primal;
    *out_tangent = tangent;
    return HMATH_OK;
}

extern int hm_ad_dual_f32(float primal, float tangent, void **out);
extern int hm_ad_dual_exact(int kind, const char *pn, const char *pd, const char *tn,
                            const char *td, void **out);
extern int hm_ad_dual_kind(void *value, int *out);
extern int hm_ad_scalar_text(void *value, char **numerator, char **denominator);

static hmath_status begin_dual(hmath_context *context, hmath_ad_handle **value) {
    *value = malloc(sizeof **value);
    if (!*value)
        return hm_error(HMATH_ALLOCATION_FAILED, "Dual handle allocation failed");
    hmath_status status = hm_enter(context);
    if (status) {
        free(*value);
        *value = NULL;
    }
    return status;
}
static hmath_status finish_dual(hmath_status status, hmath_ad_handle *value, hmath_ad_dual **out) {
    if (status) {
        free(value);
        hm_leave();
        return status;
    }
    value->kind = DUAL;
    atomic_init(&value->refs, 1);
    *out = value;
    return hm_error(HMATH_OK, "");
}
hmath_status hmath_ad_dual_create_f32(hmath_context *context, float primal, float tangent,
                                      hmath_ad_dual **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Dual output");
    hmath_ad_handle *value;
    hmath_status status = begin_dual(context, &value);
    if (status)
        return status;
    status = (hmath_status)hm_ad_dual_f32(primal, tangent, &value->stable);
    return finish_dual(status, value, out);
}
static int decimal(const char *text) {
    if (!text)
        return 0;
    if (*text == '-')
        ++text;
    if (!*text)
        return 0;
    for (; *text; ++text)
        if (*text < '0' || *text > '9')
            return 0;
    return 1;
}
static hmath_status exact_dual(hmath_context *context, int kind, const char *pn, const char *pd,
                               const char *tn, const char *td, hmath_ad_dual **out) {
    if (!out || !decimal(pn) || !decimal(tn) || (kind == 3 && (!decimal(pd) || !decimal(td))))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid exact Dual representation");
    hmath_ad_handle *value;
    hmath_status status = begin_dual(context, &value);
    if (status)
        return status;
    status = (hmath_status)hm_ad_dual_exact(kind, pn, pd, tn, td, &value->stable);
    return finish_dual(status, value, out);
}
hmath_status hmath_ad_dual_create_integer(hmath_context *context, const char *primal,
                                          const char *tangent, hmath_ad_dual **out) {
    return exact_dual(context, 2, primal, NULL, tangent, NULL, out);
}
hmath_status hmath_ad_dual_create_rational(hmath_context *context, const char *pn, const char *pd,
                                           const char *tn, const char *td, hmath_ad_dual **out) {
    return exact_dual(context, 3, pn, pd, tn, td, out);
}
hmath_status hmath_ad_dual_kind(const hmath_ad_dual *value, int *out) {
    if (!is_kind(value, DUAL) || !out)
        return bad_kind();
    hmath_status status = hm_enter(NULL);
    if (!status) {
        status = (hmath_status)hm_ad_dual_kind(value->stable, out);
        hm_leave();
    }
    return status;
}
hmath_status hmath_ad_scalar_text(const hmath_ad_dual *value, char **numerator,
                                  char **denominator) {
    if (!is_kind(value, DUAL) || !numerator || !denominator)
        return bad_kind();
    hmath_status status = hm_enter(NULL);
    if (!status) {
        status = (hmath_status)hm_ad_scalar_text(value->stable, numerator, denominator);
        hm_leave();
    }
    return status;
}
void hmath_ad_string_free(char *value) { free(value); }

extern int hm_ad_dual_relation(int operation, void *left, void *right, int *out);
hmath_status hmath_ad_dual_relation(hmath_context *context, int operation,
                                    const hmath_ad_dual *left, const hmath_ad_dual *right,
                                    int *out) {
    if (!is_kind(left, DUAL) || !is_kind(right, DUAL) || !out || (unsigned)operation > 4)
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Dual relation input");
    hmath_status status = hm_enter(context);
    if (!status) {
        status = (hmath_status)hm_ad_dual_relation(operation, left->stable, right->stable, out);
        hm_leave();
    }
    return status;
}

extern int hm_ad_value_import(void *input,void **out);
extern int hm_ad_value_export(void *input,void **out,int *kind);
hmath_status hmath_ad_value_import(hmath_context *context,const hmath_ad_handle *input,hmath_value **out) {
    if(!input || !out || (input->kind!=EXPR && input->kind!=TENSOR && input->kind!=DUAL))
        return hm_error(HMATH_INVALID_ARGUMENT,"AD Value interchange requires Expr, ADTensor or original Dual");
    hmath_value *result;
    hmath_status status=hm_value_begin(context,&result);
    if(status)return status;
    return hm_value_finish(result,hm_ad_value_import(input->stable,&result->stable),out);
}
hmath_status hmath_ad_value_export(hmath_context *context,const hmath_value *input,hmath_ad_handle **out) {
    if(!input || !out)return hm_error(HMATH_INVALID_ARGUMENT,"NULL AD Value interchange argument/output");
    hmath_ad_handle *result=calloc(1,sizeof *result);
    if(!result)return hm_error(HMATH_ALLOCATION_FAILED,"AD Value handle allocation failed");
    hmath_status status=hm_enter(context);
    if(status){free(result);return status;}
    status=(hmath_status)hm_ad_value_export(hm_value_stable(input),&result->stable,&result->kind);
    if(status){free(result);hm_leave();return status;}
    atomic_init(&result->refs,1);
    *out=result;
    return HMATH_OK;
}

extern int hm_ad_custom_checked(int operation,void (*callback)(void),void (*derivative)(void),
                                void *userdata,void *const *inputs,size_t count,void **out);
static hmath_status make_checked_callback(hmath_context *context,int operation,
                                          void (*callback)(void),void (*derivative)(void),
                                          void *userdata,const hmath_ad_expr *const *inputs,
                                          size_t count,hmath_ad_expr **out) {
    if(!out || !callback || (operation==1 && !derivative) || !all_kind(inputs,count,EXPR))
        return hm_error(HMATH_INVALID_ARGUMENT,"invalid checked AD callback input/output");
    hmath_ad_handle *value=malloc(sizeof *value);
    void **stable=stable_inputs(inputs,count);
    if(!value || !stable){free(value);free(stable);return hm_error(HMATH_ALLOCATION_FAILED,"checked AD callback allocation failed");}
    hmath_status status=hm_enter(context);
    if(status){free(value);free(stable);return status;}
    status=(hmath_status)hm_ad_custom_checked(operation,callback,derivative,userdata,stable,count,&value->stable);
    free(stable);
    if(status){free(value);hm_leave();return status;}
    value->kind=EXPR;atomic_init(&value->refs,1);*out=value;
    return HMATH_OK;
}
hmath_status hmath_ad_custom_operation_checked(hmath_context *context,hmath_ad_rule_checked_callback callback,void *userdata,const hmath_ad_expr *const *inputs,size_t count,hmath_ad_expr **out) {
    return make_checked_callback(context,0,(void (*)(void))callback,NULL,userdata,inputs,count,out);
}
hmath_status hmath_ad_custom_unary_checked(hmath_context *context,hmath_ad_unary_checked_callback callback,hmath_ad_unary_checked_callback derivative,void *userdata,const hmath_ad_expr *input,hmath_ad_expr **out) {
    return make_checked_callback(context,1,(void (*)(void))callback,(void (*)(void))derivative,userdata,&input,1,out);
}
hmath_status hmath_ad_checkpoint_checked(hmath_context *context,hmath_ad_builder_checked_callback callback,void *userdata,const hmath_ad_expr *const *inputs,size_t count,hmath_ad_expr **out) {
    return make_checked_callback(context,2,(void (*)(void))callback,NULL,userdata,inputs,count,out);
}
static hmath_status builder_checked_error(hmath_callback_error *error,hmath_status status,const char *message) {
    error->kind=0;error->message=message;error->message_length=strlen(message);return status;
}
int hm_ad_invoke_builder_checked(hmath_ad_builder_checked_callback callback,void *userdata,
                                  void *const *values,size_t count,void **out,hmath_callback_error *error) {
    hmath_ad_handle **inputs=calloc(count?count:1,sizeof *inputs);
    if(!inputs)return builder_checked_error(error,HMATH_ALLOCATION_FAILED,"checkpoint input allocation failed");
    size_t allocated=0;
    hmath_status status=HMATH_OK;
    for(;allocated<count;++allocated){
        hmath_ad_handle *value=malloc(sizeof *value);
        if(!value){status=builder_checked_error(error,HMATH_ALLOCATION_FAILED,"checkpoint handle allocation failed");break;}
        status=hm_enter(NULL);
        if(status){free(value);builder_checked_error(error,status,"checkpoint runtime reservation failed");break;}
        status=(hmath_status)hm_ad_clone(values[allocated],&value->stable);
        if(status){free(value);hm_leave();builder_checked_error(error,status,"checkpoint input clone failed");break;}
        value->kind=EXPR;atomic_init(&value->refs,1);inputs[allocated]=value;
    }
    hmath_ad_expr *result=NULL;
    if(!status)status=callback((const hmath_ad_expr *const *)inputs,count,userdata,&result,error);
    if(!status){
        if(!is_kind(result,EXPR))status=builder_checked_error(error,HMATH_INVALID_ARGUMENT,"checkpoint builder must return an owned Expr");
        else status=(hmath_status)hm_ad_clone(result->stable,out);
    }
    hmath_ad_release(result);
    for(size_t i=0;i<allocated;++i)hmath_ad_release(inputs[i]);
    free(inputs);
    return status;
}
