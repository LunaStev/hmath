/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_OPTIMIZATION_H
#define HMATH_OPTIMIZATION_H
#include "hmath.h"
#ifdef __cplusplus
extern "C" {
#endif

typedef enum hmath_gradient_method {
    HMATH_GRADIENT_DESCENT = 0,
    HMATH_MOMENTUM = 1,
    HMATH_NESTEROV = 2,
    HMATH_ADAGRAD = 3,
    HMATH_RMSPROP = 4,
    HMATH_ADADELTA = 5,
    HMATH_ADAM = 6,
    HMATH_ADAMW = 7,
    HMATH_AMSGRAD = 8,
    HMATH_ADAMAX = 9,
    HMATH_NADAM = 10,
    HMATH_RADAM = 11
} hmath_gradient_method;

typedef struct hmath_optimizer_state hmath_optimizer_state;

/* HMath.Optimization.FirstOrder.initializeOptimizer. Negative dimension is
 * passed to Haskell and returns its original InvalidArgument MathError.
 * Each state is immutable and owns one runtime reservation. Final shutdown
 * returns BUSY until all states are released. Outputs are untouched on error. */
HMATH_API hmath_status hmath_initialize_optimizer(hmath_context *context, ptrdiff_t dimension,
                                                  hmath_optimizer_state **out);
HMATH_API void hmath_optimizer_state_retain(hmath_optimizer_state *state);
HMATH_API void hmath_optimizer_state_release(hmath_optimizer_state *state);

/* HMath.Optimization.FirstOrder.optimizerStep, with the same defaults:
 * beta1=.9, beta2=.999, epsilon=1e-8; RMSProp/AdaDelta rho=.9;
 * AdamW weight decay=.01. No new mathematical options or defaults are added.
 * Nesterov is this function's corrected-momentum update, not the look-ahead
 * objective evaluation performed by minimizeGradient.
 * Preserve the original state; return new parameters and a new independent
 * state. Input/state/gradient length mismatches retain the original MathError.
 * Inputs are borrowed during the call. All output regions must be disjoint
 * from inputs and each other. out_capacity >= parameter_count. On failure
 * both outputs are untouched. The caller holds a state reference for the call.
 * Sharing states between threads is safe; output buffers must be independent.
 * Cancellation is checked before entry. Release returned states explicitly. */
HMATH_API hmath_status hmath_optimizer_step(hmath_context *context, hmath_gradient_method method,
                                            double rate, const hmath_optimizer_state *state,
                                            const double *parameters, size_t parameter_count,
                                            const double *gradient, size_t gradient_count,
                                            double *out_parameters, size_t out_capacity,
                                            hmath_optimizer_state **out_state);

#ifdef __cplusplus
}
#endif
#include "hmath_optimization_all.h"
#endif
