/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_optimization_all.h"
#include "value_internal.h"
#include <stdlib.h>
#include <string.h>
extern int hm_opt_invoke(const char *name, void *const *arguments, size_t count, void **out);
extern int hm_opt_callback(int role, hmath_optimization_callback_fn function, void *userdata,
                           void **out);
extern int hm_opt_clone(void *value, void **out);

static hmath_status invoke(hmath_context *context, const char *name,
                           const hmath_value *const *arguments, size_t count, hmath_value **out) {
    if (!out || (count && !arguments))
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL optimization argument/output");
    if (count > (size_t)PTRDIFF_MAX / sizeof(void *))
        return hm_error(HMATH_OVERFLOW, "optimization argument span overflow");
    for (size_t i = 0; i < count; ++i)
        if (!arguments[i])
            return hm_error(HMATH_INVALID_ARGUMENT, "NULL optimization value");
    void **stable = malloc((count ? count : 1) * sizeof *stable);
    if (!stable)
        return hm_error(HMATH_ALLOCATION_FAILED, "optimization argument allocation failed");
    for (size_t i = 0; i < count; ++i)
        stable[i] = hm_value_stable(arguments[i]);
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status) {
        free(stable);
        return status;
    }
    int code = hm_opt_invoke(name, stable, count, &result->stable);
    free(stable);
    return hm_value_finish(result, code, out);
}
hmath_status hmath_optimization_callback(hmath_context *context, int role,
                                         hmath_optimization_callback_fn function, void *userdata,
                                         hmath_value **out) {
    if (!function || !out || (unsigned)role > 4)
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid optimization callback");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    return hm_value_finish(result, hm_opt_callback(role, function, userdata, &result->stable), out);
}
/* Called safely from Haskell. Callback input is borrowed; callback output
 * transfers an owned reference. The helper clones both independent roots. */
int hm_opt_invoke_callback(hmath_optimization_callback_fn function, void *userdata, void *argument,
                           void **out, hmath_math_error *error) {
    hmath_value *input;
    hmath_status status = hm_value_begin(NULL, &input);
    if (status) {
        error->message = "optimization callback input allocation failed";
        error->message_length = strlen(error->message);
        return status;
    }
    hmath_value *published = NULL;
    status = hm_value_finish(input, hm_opt_clone(argument, &input->stable), &published);
    if (status) {
        error->message = "optimization callback input clone failed";
        error->message_length = strlen(error->message);
        return status;
    }
    hmath_value *result = NULL;
    status = function(published, userdata, &result, error);
    if (!status) {
        if (!result) {
            status = HMATH_INVALID_ARGUMENT;
            error->message = "callback returned a NULL value";
            error->message_length = strlen(error->message);
        } else
            status = (hmath_status)hm_opt_clone(hm_value_stable(result), out);
    }
    hmath_value_release(result);
    hmath_value_release(published);
    return status;
}
hmath_status hmath_optimization_function_apply(hmath_context *context, const hmath_value *function,
                                               const hmath_value *const *arguments, size_t count,
                                               hmath_value **out) {
    if (!function || (count && !arguments) || count >= (size_t)PTRDIFF_MAX / sizeof(void *))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid optimization function arguments");
    const hmath_value **all = malloc((count + 1) * sizeof *all);
    if (!all)
        return hm_error(HMATH_ALLOCATION_FAILED, "function argument allocation failed");
    all[0] = function;
    for (size_t i = 0; i < count; ++i)
        all[i + 1] = arguments[i];
    hmath_status status = invoke(context, "__apply", all, count + 1, out);
    free(all);
    return status;
}
hmath_status hmath_optimization_optimize_options_create(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1,
                                                        const hmath_value *a2,
                                                        const hmath_value *a3, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3};
    return invoke(context, "OptimizeOptions", arguments, 4, out);
}
hmath_status hmath_optimization_default_optimize_options(hmath_context *context,
                                                         hmath_value **out) {
    return invoke(context, "defaultOptimizeOptions", NULL, 0, out);
}
hmath_status hmath_optimization_optimize_result_create(hmath_context *context,
                                                       const hmath_value *a0, const hmath_value *a1,
                                                       const hmath_value *a2, const hmath_value *a3,
                                                       const hmath_value *a4, const hmath_value *a5,
                                                       hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4, a5};
    return invoke(context, "OptimizeResult", arguments, 6, out);
}
hmath_status hmath_optimization_early_stopping_create(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, const hmath_value *a2,
                                                      hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2};
    return invoke(context, "EarlyStopping", arguments, 3, out);
}
hmath_status hmath_optimization_constant_rate_create(hmath_context *context, const hmath_value *a0,
                                                     hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "ConstantRate", arguments, 1, out);
}
hmath_status hmath_optimization_step_decay_create(hmath_context *context, const hmath_value *a0,
                                                  const hmath_value *a1, const hmath_value *a2,
                                                  hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2};
    return invoke(context, "StepDecay", arguments, 3, out);
}
hmath_status hmath_optimization_exponential_decay_create(hmath_context *context,
                                                         const hmath_value *a0,
                                                         const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "ExponentialDecay", arguments, 2, out);
}
hmath_status hmath_optimization_cosine_annealing_create(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1,
                                                        const hmath_value *a2, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2};
    return invoke(context, "CosineAnnealing", arguments, 3, out);
}
hmath_status hmath_optimization_warmup_create(hmath_context *context, const hmath_value *a0,
                                              const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "Warmup", arguments, 2, out);
}
hmath_status hmath_optimization_armijo_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "Armijo", NULL, 0, out);
}
hmath_status hmath_optimization_strong_wolfe_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "StrongWolfe", NULL, 0, out);
}
hmath_status hmath_optimization_checked_options(hmath_context *context, const hmath_value *a0,
                                                hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "checkedOptions", arguments, 1, out);
}
hmath_status hmath_optimization_checked_point(hmath_context *context, const hmath_value *a0,
                                              hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "checkedPoint", arguments, 1, out);
}
hmath_status hmath_optimization_checked_value(hmath_context *context, const hmath_value *a0,
                                              const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "checkedValue", arguments, 2, out);
}
hmath_status hmath_optimization_checked_gradient(hmath_context *context, const hmath_value *a0,
                                                 const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "checkedGradient", arguments, 2, out);
}
hmath_status hmath_optimization_check_budget(hmath_context *context, const hmath_value *a0,
                                             const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "checkBudget", arguments, 2, out);
}
hmath_status hmath_optimization_dot(hmath_context *context, const hmath_value *a0,
                                    const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "dot", arguments, 2, out);
}
hmath_status hmath_optimization_add(hmath_context *context, const hmath_value *a0,
                                    const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "add", arguments, 2, out);
}
hmath_status hmath_optimization_sub(hmath_context *context, const hmath_value *a0,
                                    const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "sub", arguments, 2, out);
}
hmath_status hmath_optimization_outer(hmath_context *context, const hmath_value *a0,
                                      const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "outer", arguments, 2, out);
}
hmath_status hmath_optimization_norm(hmath_context *context, const hmath_value *a0,
                                     hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "norm", arguments, 1, out);
}
hmath_status hmath_optimization_scale(hmath_context *context, const hmath_value *a0,
                                      const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "scale", arguments, 2, out);
}
hmath_status hmath_optimization_identity(hmath_context *context, const hmath_value *a0,
                                         hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "identity", arguments, 1, out);
}
hmath_status hmath_optimization_mat_vec(hmath_context *context, const hmath_value *a0,
                                        const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "matVec", arguments, 2, out);
}
hmath_status hmath_optimization_mat_mul(hmath_context *context, const hmath_value *a0,
                                        const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "matMul", arguments, 2, out);
}
hmath_status hmath_optimization_transpose(hmath_context *context, const hmath_value *a0,
                                          hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "transpose", arguments, 1, out);
}
hmath_status hmath_optimization_solve_dense(hmath_context *context, const hmath_value *a0,
                                            const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "solveDense", arguments, 2, out);
}
hmath_status hmath_optimization_result(hmath_context *context, const hmath_value *a0,
                                       const hmath_value *a1, const hmath_value *a2,
                                       const hmath_value *a3, const hmath_value *a4,
                                       const hmath_value *a5, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4, a5};
    return invoke(context, "result", arguments, 6, out);
}
hmath_status hmath_optimization_learning_rate(hmath_context *context, const hmath_value *a0,
                                              const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "learningRate", arguments, 2, out);
}
hmath_status hmath_optimization_early_stopping(hmath_context *context, const hmath_value *a0,
                                               const hmath_value *a1, const hmath_value *a2,
                                               const hmath_value *a3, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3};
    return invoke(context, "earlyStopping", arguments, 4, out);
}
hmath_status hmath_optimization_line_search(hmath_context *context, const hmath_value *a0,
                                            const hmath_value *a1, const hmath_value *a2,
                                            const hmath_value *a3, const hmath_value *a4,
                                            const hmath_value *a5, const hmath_value *a6,
                                            const hmath_value *a7, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4, a5, a6, a7};
    return invoke(context, "lineSearch", arguments, 8, out);
}
hmath_status hmath_optimization_opt_max_iterations(hmath_context *context, const hmath_value *a0,
                                                   hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "optMaxIterations", arguments, 1, out);
}
hmath_status hmath_optimization_opt_max_evaluations(hmath_context *context, const hmath_value *a0,
                                                    hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "optMaxEvaluations", arguments, 1, out);
}
hmath_status hmath_optimization_opt_tolerance(hmath_context *context, const hmath_value *a0,
                                              hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "optTolerance", arguments, 1, out);
}
hmath_status hmath_optimization_opt_learning_rate(hmath_context *context, const hmath_value *a0,
                                                  hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "optLearningRate", arguments, 1, out);
}
hmath_status hmath_optimization_opt_point(hmath_context *context, const hmath_value *a0,
                                          hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "optPoint", arguments, 1, out);
}
hmath_status hmath_optimization_opt_value(hmath_context *context, const hmath_value *a0,
                                          hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "optValue", arguments, 1, out);
}
hmath_status hmath_optimization_opt_gradient_norm(hmath_context *context, const hmath_value *a0,
                                                  hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "optGradientNorm", arguments, 1, out);
}
hmath_status hmath_optimization_opt_iterations(hmath_context *context, const hmath_value *a0,
                                               hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "optIterations", arguments, 1, out);
}
hmath_status hmath_optimization_opt_evaluations(hmath_context *context, const hmath_value *a0,
                                                hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "optEvaluations", arguments, 1, out);
}
hmath_status hmath_optimization_opt_converged(hmath_context *context, const hmath_value *a0,
                                              hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "optConverged", arguments, 1, out);
}
hmath_status hmath_optimization_best_score(hmath_context *context, const hmath_value *a0,
                                           hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "bestScore", arguments, 1, out);
}
hmath_status hmath_optimization_stale_steps(hmath_context *context, const hmath_value *a0,
                                            hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "staleSteps", arguments, 1, out);
}
hmath_status hmath_optimization_stopped(hmath_context *context, const hmath_value *a0,
                                        hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "stopped", arguments, 1, out);
}
hmath_status hmath_optimization_gradient_descent_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "GradientDescent", NULL, 0, out);
}
hmath_status hmath_optimization_momentum_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "Momentum", NULL, 0, out);
}
hmath_status hmath_optimization_nesterov_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "Nesterov", NULL, 0, out);
}
hmath_status hmath_optimization_ada_grad_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "AdaGrad", NULL, 0, out);
}
hmath_status hmath_optimization_rms_prop_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "RMSProp", NULL, 0, out);
}
hmath_status hmath_optimization_ada_delta_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "AdaDelta", NULL, 0, out);
}
hmath_status hmath_optimization_adam_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "Adam", NULL, 0, out);
}
hmath_status hmath_optimization_adam_w_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "AdamW", NULL, 0, out);
}
hmath_status hmath_optimization_ams_grad_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "AMSGrad", NULL, 0, out);
}
hmath_status hmath_optimization_ada_max_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "AdaMax", NULL, 0, out);
}
hmath_status hmath_optimization_nadam_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "Nadam", NULL, 0, out);
}
hmath_status hmath_optimization_r_adam_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "RAdam", NULL, 0, out);
}
hmath_status hmath_optimization_initialize_optimizer(hmath_context *context, const hmath_value *a0,
                                                     hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "initializeOptimizer", arguments, 1, out);
}
hmath_status hmath_optimization_optimizer_step(hmath_context *context, const hmath_value *a0,
                                               const hmath_value *a1, const hmath_value *a2,
                                               const hmath_value *a3, const hmath_value *a4,
                                               hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4};
    return invoke(context, "optimizerStep", arguments, 5, out);
}
hmath_status hmath_optimization_minimize_gradient(hmath_context *context, const hmath_value *a0,
                                                  const hmath_value *a1, const hmath_value *a2,
                                                  const hmath_value *a3, const hmath_value *a4,
                                                  hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4};
    return invoke(context, "minimizeGradient", arguments, 5, out);
}
hmath_status hmath_optimization_minimize_gradient_with_callback(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, const hmath_value *a5, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4, a5};
    return invoke(context, "minimizeGradientWithCallback", arguments, 6, out);
}
hmath_status hmath_optimization_stochastic_gradient(hmath_context *context, const hmath_value *a0,
                                                    const hmath_value *a1, const hmath_value *a2,
                                                    const hmath_value *a3, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3};
    return invoke(context, "stochasticGradient", arguments, 4, out);
}
hmath_status hmath_optimization_mini_batch_gradient(hmath_context *context, const hmath_value *a0,
                                                    hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "miniBatchGradient", arguments, 1, out);
}
hmath_status hmath_optimization_projected_gradient(hmath_context *context, const hmath_value *a0,
                                                   const hmath_value *a1, const hmath_value *a2,
                                                   const hmath_value *a3, const hmath_value *a4,
                                                   hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4};
    return invoke(context, "projectedGradient", arguments, 5, out);
}
hmath_status hmath_optimization_proximal_gradient(hmath_context *context, const hmath_value *a0,
                                                  const hmath_value *a1, const hmath_value *a2,
                                                  const hmath_value *a3, const hmath_value *a4,
                                                  hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4};
    return invoke(context, "proximalGradient", arguments, 5, out);
}
hmath_status hmath_optimization_fista(hmath_context *context, const hmath_value *a0,
                                      const hmath_value *a1, const hmath_value *a2,
                                      const hmath_value *a3, const hmath_value *a4,
                                      hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4};
    return invoke(context, "fista", arguments, 5, out);
}
hmath_status hmath_optimization_coordinate_descent(hmath_context *context, const hmath_value *a0,
                                                   const hmath_value *a1, const hmath_value *a2,
                                                   const hmath_value *a3, const hmath_value *a4,
                                                   hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4};
    return invoke(context, "coordinateDescent", arguments, 5, out);
}
hmath_status hmath_optimization_golden_section_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "GoldenSection", NULL, 0, out);
}
hmath_status hmath_optimization_ternary_search_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "TernarySearch", NULL, 0, out);
}
hmath_status hmath_optimization_brent_search_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "BrentSearch", NULL, 0, out);
}
hmath_status hmath_optimization_minimize_scalar(hmath_context *context, const hmath_value *a0,
                                                const hmath_value *a1, const hmath_value *a2,
                                                const hmath_value *a3, const hmath_value *a4,
                                                hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4};
    return invoke(context, "minimizeScalar", arguments, 5, out);
}
hmath_status hmath_optimization_bfgs_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "BFGS", NULL, 0, out);
}
hmath_status hmath_optimization_dfp_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "DFP", NULL, 0, out);
}
hmath_status hmath_optimization_sr1_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "SR1", NULL, 0, out);
}
hmath_status hmath_optimization_lbfgs_create(hmath_context *context, const hmath_value *a0,
                                             hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "LBFGS", arguments, 1, out);
}
hmath_status hmath_optimization_minimize_quasi_newton(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, const hmath_value *a2,
                                                      const hmath_value *a3, const hmath_value *a4,
                                                      hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4};
    return invoke(context, "minimizeQuasiNewton", arguments, 5, out);
}
hmath_status hmath_optimization_newton_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "Newton", NULL, 0, out);
}
hmath_status hmath_optimization_newton_cg_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "NewtonCG", NULL, 0, out);
}
hmath_status hmath_optimization_trust_region_create(hmath_context *context, const hmath_value *a0,
                                                    hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "TrustRegion", arguments, 1, out);
}
hmath_status hmath_optimization_dogleg_create(hmath_context *context, const hmath_value *a0,
                                              hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "Dogleg", arguments, 1, out);
}
hmath_status hmath_optimization_minimize_newton(hmath_context *context, const hmath_value *a0,
                                                const hmath_value *a1, const hmath_value *a2,
                                                const hmath_value *a3, const hmath_value *a4,
                                                const hmath_value *a5, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4, a5};
    return invoke(context, "minimizeNewton", arguments, 6, out);
}
hmath_status hmath_optimization_nonlinear_cg(hmath_context *context, const hmath_value *a0,
                                             const hmath_value *a1, const hmath_value *a2,
                                             const hmath_value *a3, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3};
    return invoke(context, "nonlinearCG", arguments, 4, out);
}
hmath_status hmath_optimization_squared_loss_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "SquaredLoss", NULL, 0, out);
}
hmath_status hmath_optimization_huber_loss_create(hmath_context *context, const hmath_value *a0,
                                                  hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "HuberLoss", arguments, 1, out);
}
hmath_status hmath_optimization_cauchy_loss_create(hmath_context *context, const hmath_value *a0,
                                                   hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "CauchyLoss", arguments, 1, out);
}
hmath_status hmath_optimization_soft_l1_create(hmath_context *context, const hmath_value *a0,
                                               hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "SoftL1", arguments, 1, out);
}
hmath_status hmath_optimization_least_squares(hmath_context *context, const hmath_value *a0,
                                              const hmath_value *a1, const hmath_value *a2,
                                              const hmath_value *a3, const hmath_value *a4,
                                              const hmath_value *a5, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4, a5};
    return invoke(context, "leastSquares", arguments, 6, out);
}
hmath_status hmath_optimization_nelder_mead(hmath_context *context, const hmath_value *a0,
                                            const hmath_value *a1, const hmath_value *a2,
                                            hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2};
    return invoke(context, "nelderMead", arguments, 3, out);
}
hmath_status hmath_optimization_powell(hmath_context *context, const hmath_value *a0,
                                       const hmath_value *a1, const hmath_value *a2,
                                       const hmath_value *a3, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3};
    return invoke(context, "powell", arguments, 4, out);
}
hmath_status hmath_optimization_equality_create(hmath_context *context, const hmath_value *a0,
                                                const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "Equality", arguments, 2, out);
}
hmath_status hmath_optimization_less_equal_create(hmath_context *context, const hmath_value *a0,
                                                  const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "LessEqual", arguments, 2, out);
}
hmath_status hmath_optimization_feasibility(hmath_context *context, const hmath_value *a0,
                                            const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "feasibility", arguments, 2, out);
}
hmath_status hmath_optimization_quadratic_penalty_create(hmath_context *context,
                                                         hmath_value **out) {
    return invoke(context, "QuadraticPenalty", NULL, 0, out);
}
hmath_status hmath_optimization_log_barrier_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "LogBarrier", NULL, 0, out);
}
hmath_status hmath_optimization_interior_point_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "InteriorPoint", NULL, 0, out);
}
hmath_status hmath_optimization_augmented_lagrangian_create(hmath_context *context,
                                                            hmath_value **out) {
    return invoke(context, "AugmentedLagrangian", NULL, 0, out);
}
hmath_status hmath_optimization_constrained_minimize(hmath_context *context, const hmath_value *a0,
                                                     const hmath_value *a1, const hmath_value *a2,
                                                     const hmath_value *a3, const hmath_value *a4,
                                                     const hmath_value *a5, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4, a5};
    return invoke(context, "constrainedMinimize", arguments, 6, out);
}
hmath_status hmath_optimization_lp_result_create(hmath_context *context, const hmath_value *a0,
                                                 const hmath_value *a1, const hmath_value *a2,
                                                 const hmath_value *a3, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3};
    return invoke(context, "LPResult", arguments, 4, out);
}
hmath_status hmath_optimization_linear_programming(hmath_context *context, const hmath_value *a0,
                                                   const hmath_value *a1, const hmath_value *a2,
                                                   const hmath_value *a3, const hmath_value *a4,
                                                   hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4};
    return invoke(context, "linearProgramming", arguments, 5, out);
}
hmath_status hmath_optimization_revised_simplex(hmath_context *context, const hmath_value *a0,
                                                const hmath_value *a1, const hmath_value *a2,
                                                const hmath_value *a3, const hmath_value *a4,
                                                const hmath_value *a5, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4, a5};
    return invoke(context, "revisedSimplex", arguments, 6, out);
}
hmath_status hmath_optimization_quadratic_programming(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, const hmath_value *a2,
                                                      const hmath_value *a3, const hmath_value *a4,
                                                      const hmath_value *a5, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4, a5};
    return invoke(context, "quadraticProgramming", arguments, 6, out);
}
hmath_status hmath_optimization_slsqp(hmath_context *context, const hmath_value *a0,
                                      const hmath_value *a1, const hmath_value *a2,
                                      const hmath_value *a3, const hmath_value *a4,
                                      const hmath_value *a5, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4, a5};
    return invoke(context, "slsqp", arguments, 6, out);
}
hmath_status hmath_optimization_cobyla(hmath_context *context, const hmath_value *a0,
                                       const hmath_value *a1, const hmath_value *a2,
                                       const hmath_value *a3, const hmath_value *a4,
                                       hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4};
    return invoke(context, "cobyla", arguments, 5, out);
}
hmath_status hmath_optimization_weighted_objective(hmath_context *context, const hmath_value *a0,
                                                   const hmath_value *a1, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1};
    return invoke(context, "weightedObjective", arguments, 2, out);
}
hmath_status hmath_optimization_pareto_front(hmath_context *context, const hmath_value *a0,
                                             hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "paretoFront", arguments, 1, out);
}
hmath_status hmath_optimization_lp_point(hmath_context *context, const hmath_value *a0,
                                         hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "lpPoint", arguments, 1, out);
}
hmath_status hmath_optimization_lp_value(hmath_context *context, const hmath_value *a0,
                                         hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "lpValue", arguments, 1, out);
}
hmath_status hmath_optimization_lp_basis(hmath_context *context, const hmath_value *a0,
                                         hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "lpBasis", arguments, 1, out);
}
hmath_status hmath_optimization_lp_iterations(hmath_context *context, const hmath_value *a0,
                                              hmath_value **out) {
    const hmath_value *arguments[] = {a0};
    return invoke(context, "lpIterations", arguments, 1, out);
}
hmath_status hmath_optimization_simulated_annealing_create(hmath_context *context,
                                                           hmath_value **out) {
    return invoke(context, "SimulatedAnnealing", NULL, 0, out);
}
hmath_status hmath_optimization_differential_evolution_create(hmath_context *context,
                                                              hmath_value **out) {
    return invoke(context, "DifferentialEvolution", NULL, 0, out);
}
hmath_status hmath_optimization_genetic_algorithm_create(hmath_context *context,
                                                         hmath_value **out) {
    return invoke(context, "GeneticAlgorithm", NULL, 0, out);
}
hmath_status hmath_optimization_particle_swarm_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "ParticleSwarm", NULL, 0, out);
}
hmath_status hmath_optimization_cmaes_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "CMAES", NULL, 0, out);
}
hmath_status hmath_optimization_global_minimize(hmath_context *context, const hmath_value *a0,
                                                const hmath_value *a1, const hmath_value *a2,
                                                const hmath_value *a3, const hmath_value *a4,
                                                const hmath_value *a5, hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4, a5};
    return invoke(context, "globalMinimize", arguments, 6, out);
}
hmath_status hmath_optimization_basin_hopping(hmath_context *context, const hmath_value *a0,
                                              const hmath_value *a1, const hmath_value *a2,
                                              const hmath_value *a3, const hmath_value *a4,
                                              const hmath_value *a5, const hmath_value *a6,
                                              hmath_value **out) {
    const hmath_value *arguments[] = {a0, a1, a2, a3, a4, a5, a6};
    return invoke(context, "basinHopping", arguments, 7, out);
}
