/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_optimization.h"
#include "native_internal.h"
#include "value_internal.h"
#include <stdlib.h>

struct hmath_optimizer_state {
    atomic_size_t refs;
    void *stable;
};

extern int hm_optimizer_initialize(ptrdiff_t dimension, void **out);
extern void hm_optimizer_free(void *state);
extern int hm_optimizer_step(int method, double rate, void *state, const double *parameters,
                             size_t parameter_count, const double *gradient, size_t gradient_count,
                             double *out_parameters, void **out_state);

hmath_status hmath_initialize_optimizer(hmath_context *context, ptrdiff_t dimension,
                                        hmath_optimizer_state **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL optimizer output");
    hmath_optimizer_state *state = malloc(sizeof *state);
    if (!state)
        return hm_error(HMATH_ALLOCATION_FAILED, "optimizer handle allocation failed");
    hmath_status status = hm_enter(context);
    if (status) {
        free(state);
        return status;
    }
    status = (hmath_status)hm_optimizer_initialize(dimension, &state->stable);
    if (status) {
        free(state);
        hm_leave();
        return status;
    }
    atomic_init(&state->refs, 1);
    *out = state;
    /* Keep the reservation for this stable pointer's whole lifetime. */
    return HMATH_OK;
}

void hmath_optimizer_state_retain(hmath_optimizer_state *state) {
    if (state)
        atomic_fetch_add_explicit(&state->refs, 1, memory_order_relaxed);
}

void hmath_optimizer_state_release(hmath_optimizer_state *state) {
    if (state && atomic_fetch_sub_explicit(&state->refs, 1, memory_order_acq_rel) == 1) {
        hm_optimizer_free(state->stable);
        free(state);
        hm_leave();
    }
}

hmath_status hmath_optimizer_step(hmath_context *context, hmath_gradient_method method, double rate,
                                  const hmath_optimizer_state *state, const double *parameters,
                                  size_t parameter_count, const double *gradient,
                                  size_t gradient_count, double *out_parameters,
                                  size_t out_capacity, hmath_optimizer_state **out_state) {
    if (!state || !out_state || (parameter_count && (!parameters || !out_parameters)) ||
        (gradient_count && !gradient))
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL optimizer argument");
    if ((unsigned)method > HMATH_RADAM)
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid GradientMethod constructor");
    if (parameter_count > (size_t)PTRDIFF_MAX / sizeof(double) ||
        gradient_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "optimizer byte span exceeds ptrdiff_t");
    if (out_capacity < parameter_count)
        return hm_error(HMATH_BOUNDS_ERROR, "insufficient optimizer output capacity");
    hmath_optimizer_state *next = malloc(sizeof *next);
    if (!next)
        return hm_error(HMATH_ALLOCATION_FAILED, "optimizer handle allocation failed");
    hmath_status status = hm_enter(context);
    if (status) {
        free(next);
        return status;
    }
    status =
        (hmath_status)hm_optimizer_step(method, rate, state->stable, parameters, parameter_count,
                                        gradient, gradient_count, out_parameters, &next->stable);
    if (status) {
        free(next);
        hm_leave();
        return status;
    }
    atomic_init(&next->refs, 1);
    *out_state = next;
    return HMATH_OK;
}

extern int hm_opt_import_state(void *state, void **out);
extern int hm_opt_export_state(void *value, void **out);
hmath_status hmath_optimization_state_import(hmath_context *context,
                                             const hmath_optimizer_state *state,
                                             hmath_value **out) {
    if (!state || !out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL optimizer state import");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    return hm_value_finish(result, hm_opt_import_state(state->stable, &result->stable), out);
}
hmath_status hmath_optimization_state_export(hmath_context *context, const hmath_value *value,
                                             hmath_optimizer_state **out) {
    if (!value || !out || value->kind != 34)
        return hm_error(HMATH_INVALID_ARGUMENT, "expected optimizer state value");
    hmath_optimizer_state *state = malloc(sizeof *state);
    if (!state)
        return hm_error(HMATH_ALLOCATION_FAILED, "optimizer state owner allocation failed");
    hmath_status status = hm_enter(context);
    if (status) {
        free(state);
        return status;
    }
    status = (hmath_status)hm_opt_export_state(hm_value_stable(value), &state->stable);
    if (status) {
        free(state);
        hm_leave();
        return status;
    }
    atomic_init(&state->refs, 1);
    *out = state;
    return HMATH_OK;
}
