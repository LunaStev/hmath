/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_OPTIMIZATION_ALL_H
#define HMATH_OPTIMIZATION_ALL_H
#include "hmath_error.h"
#include "hmath_optimization.h"
#include "hmath_value.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Typed immutable values represent original records, methods, ragged lists and
 * callbacks. All solver arithmetic is the original Double implementation.
 * Each output owns one Value reference; release it with hmath_value_release.
 * Inputs are borrowed for each call; concurrent immutable sharing is allowed.
 * Callback/userdata must remain live while any derived function/constraint may
 * invoke them. Returned callback values transfer one owned reference; retain a
 * borrowed input before returning it. status11 fills MathError wire and becomes
 * a genuine Haskell Left, allowing original solver recovery/backtracking.
 * Unexpected failures return another status and abort after native cleanup.
 * Output pointers remain untouched on errors; buffers must not overlap inputs.
 * Original options, budgets, diagnostics and explicit Word64 seeds are retained.
 * Callback roles:0Objective(vector->Double),1Gradient/projection(vector->vector),
 * 2Hessian/Jacobian(vector->ragged matrix),3prox((rate,point)->vector),
 * 4monitor(OptimizeResult->Bool). Scalar minimization Objective input is [x]. */
typedef hmath_status (*hmath_optimization_callback_fn)(const hmath_value *argument, void *userdata,
                                                       hmath_value **out, hmath_math_error *error);
HMATH_API hmath_status hmath_optimization_callback(hmath_context *context, int role,
                                                   hmath_optimization_callback_fn function,
                                                   void *userdata, hmath_value **out);
HMATH_API hmath_status hmath_optimization_function_apply(hmath_context *context,
                                                         const hmath_value *function,
                                                         const hmath_value *const *arguments,
                                                         size_t count, hmath_value **out);
HMATH_API hmath_status hmath_optimization_state_import(hmath_context *context,
                                                       const hmath_optimizer_state *state,
                                                       hmath_value **out);
HMATH_API hmath_status hmath_optimization_state_export(hmath_context *context,
                                                       const hmath_value *value,
                                                       hmath_optimizer_state **out);
/* HMath.Optimization.Common.OptimizeOptions (Int, Int, Double, Double) -> Options. */
HMATH_API hmath_status hmath_optimization_optimize_options_create(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, hmath_value **out);
/* HMath.Optimization.Common.defaultOptimizeOptions () -> Options. */
HMATH_API hmath_status hmath_optimization_default_optimize_options(hmath_context *context,
                                                                   hmath_value **out);
/* HMath.Optimization.Common.OptimizeResult (Vector, Double, Double, Int, Int, Bool) -> Result. */
HMATH_API hmath_status hmath_optimization_optimize_result_create(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, const hmath_value *a5, hmath_value **out);
/* HMath.Optimization.Common.EarlyStopping (MaybeDouble, Int, Bool) -> EarlyStopping. */
HMATH_API hmath_status hmath_optimization_early_stopping_create(hmath_context *context,
                                                                const hmath_value *a0,
                                                                const hmath_value *a1,
                                                                const hmath_value *a2,
                                                                hmath_value **out);
/* HMath.Optimization.Common.ConstantRate (Double) -> LearningRate. */
HMATH_API hmath_status hmath_optimization_constant_rate_create(hmath_context *context,
                                                               const hmath_value *a0,
                                                               hmath_value **out);
/* HMath.Optimization.Common.StepDecay (Double, Int, Double) -> LearningRate. */
HMATH_API hmath_status hmath_optimization_step_decay_create(hmath_context *context,
                                                            const hmath_value *a0,
                                                            const hmath_value *a1,
                                                            const hmath_value *a2,
                                                            hmath_value **out);
/* HMath.Optimization.Common.ExponentialDecay (Double, Double) -> LearningRate. */
HMATH_API hmath_status hmath_optimization_exponential_decay_create(hmath_context *context,
                                                                   const hmath_value *a0,
                                                                   const hmath_value *a1,
                                                                   hmath_value **out);
/* HMath.Optimization.Common.CosineAnnealing (Double, Double, Int) -> LearningRate. */
HMATH_API hmath_status hmath_optimization_cosine_annealing_create(hmath_context *context,
                                                                  const hmath_value *a0,
                                                                  const hmath_value *a1,
                                                                  const hmath_value *a2,
                                                                  hmath_value **out);
/* HMath.Optimization.Common.Warmup (Int, LearningRate) -> LearningRate. */
HMATH_API hmath_status hmath_optimization_warmup_create(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1, hmath_value **out);
/* HMath.Optimization.Common.Armijo () -> LineSearch. */
HMATH_API hmath_status hmath_optimization_armijo_create(hmath_context *context, hmath_value **out);
/* HMath.Optimization.Common.StrongWolfe () -> LineSearch. */
HMATH_API hmath_status hmath_optimization_strong_wolfe_create(hmath_context *context,
                                                              hmath_value **out);
/* HMath.Optimization.Common.checkedOptions (Options) -> Unit. */
HMATH_API hmath_status hmath_optimization_checked_options(hmath_context *context,
                                                          const hmath_value *a0, hmath_value **out);
/* HMath.Optimization.Common.checkedPoint (Vector) -> Unit. */
HMATH_API hmath_status hmath_optimization_checked_point(hmath_context *context,
                                                        const hmath_value *a0, hmath_value **out);
/* HMath.Optimization.Common.checkedValue (Objective, Vector) -> Double. */
HMATH_API hmath_status hmath_optimization_checked_value(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1, hmath_value **out);
/* HMath.Optimization.Common.checkedGradient (Gradient, Vector) -> Vector. */
HMATH_API hmath_status hmath_optimization_checked_gradient(hmath_context *context,
                                                           const hmath_value *a0,
                                                           const hmath_value *a1,
                                                           hmath_value **out);
/* HMath.Optimization.Common.checkBudget (Options, Int) -> Unit. */
HMATH_API hmath_status hmath_optimization_check_budget(hmath_context *context,
                                                       const hmath_value *a0, const hmath_value *a1,
                                                       hmath_value **out);
/* HMath.Optimization.Common.dot (Vector, Vector) -> Value. */
HMATH_API hmath_status hmath_optimization_dot(hmath_context *context, const hmath_value *a0,
                                              const hmath_value *a1, hmath_value **out);
/* HMath.Optimization.Common.add (Vector, Vector) -> Value. */
HMATH_API hmath_status hmath_optimization_add(hmath_context *context, const hmath_value *a0,
                                              const hmath_value *a1, hmath_value **out);
/* HMath.Optimization.Common.sub (Vector, Vector) -> Value. */
HMATH_API hmath_status hmath_optimization_sub(hmath_context *context, const hmath_value *a0,
                                              const hmath_value *a1, hmath_value **out);
/* HMath.Optimization.Common.outer (Vector, Vector) -> Value. */
HMATH_API hmath_status hmath_optimization_outer(hmath_context *context, const hmath_value *a0,
                                                const hmath_value *a1, hmath_value **out);
/* HMath.Optimization.Common.norm (Vector) -> Double. */
HMATH_API hmath_status hmath_optimization_norm(hmath_context *context, const hmath_value *a0,
                                               hmath_value **out);
/* HMath.Optimization.Common.scale (Double, Vector) -> Vector. */
HMATH_API hmath_status hmath_optimization_scale(hmath_context *context, const hmath_value *a0,
                                                const hmath_value *a1, hmath_value **out);
/* HMath.Optimization.Common.identity (Int) -> Matrix. */
HMATH_API hmath_status hmath_optimization_identity(hmath_context *context, const hmath_value *a0,
                                                   hmath_value **out);
/* HMath.Optimization.Common.matVec (Matrix, Vector) -> Vector. */
HMATH_API hmath_status hmath_optimization_mat_vec(hmath_context *context, const hmath_value *a0,
                                                  const hmath_value *a1, hmath_value **out);
/* HMath.Optimization.Common.matMul (Matrix, Matrix) -> Matrix. */
HMATH_API hmath_status hmath_optimization_mat_mul(hmath_context *context, const hmath_value *a0,
                                                  const hmath_value *a1, hmath_value **out);
/* HMath.Optimization.Common.transpose (GenericMatrix) -> GenericMatrix. */
HMATH_API hmath_status hmath_optimization_transpose(hmath_context *context, const hmath_value *a0,
                                                    hmath_value **out);
/* HMath.Optimization.Common.solveDense (Matrix, Vector) -> Vector. */
HMATH_API hmath_status hmath_optimization_solve_dense(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, hmath_value **out);
/* HMath.Optimization.Common.result (Int, Int, Bool, Objective, Gradient, Vector) -> Result. */
HMATH_API hmath_status hmath_optimization_result(hmath_context *context, const hmath_value *a0,
                                                 const hmath_value *a1, const hmath_value *a2,
                                                 const hmath_value *a3, const hmath_value *a4,
                                                 const hmath_value *a5, hmath_value **out);
/* HMath.Optimization.Common.learningRate (LearningRate, Int) -> Double. */
HMATH_API hmath_status hmath_optimization_learning_rate(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1, hmath_value **out);
/* HMath.Optimization.Common.earlyStopping (Int, Double, Double, EarlyStopping) -> EarlyStopping. */
HMATH_API hmath_status hmath_optimization_early_stopping(hmath_context *context,
                                                         const hmath_value *a0,
                                                         const hmath_value *a1,
                                                         const hmath_value *a2,
                                                         const hmath_value *a3, hmath_value **out);
/* HMath.Optimization.Common.lineSearch (LineSearch, Int, Objective, Gradient, Vector, Vector,
 * Double, Vector) -> Tuple. */
HMATH_API hmath_status hmath_optimization_line_search(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, const hmath_value *a2,
                                                      const hmath_value *a3, const hmath_value *a4,
                                                      const hmath_value *a5, const hmath_value *a6,
                                                      const hmath_value *a7, hmath_value **out);
/* HMath.Optimization.Common.optMaxIterations (Options) -> Value. */
HMATH_API hmath_status hmath_optimization_opt_max_iterations(hmath_context *context,
                                                             const hmath_value *a0,
                                                             hmath_value **out);
/* HMath.Optimization.Common.optMaxEvaluations (Options) -> Value. */
HMATH_API hmath_status hmath_optimization_opt_max_evaluations(hmath_context *context,
                                                              const hmath_value *a0,
                                                              hmath_value **out);
/* HMath.Optimization.Common.optTolerance (Options) -> Value. */
HMATH_API hmath_status hmath_optimization_opt_tolerance(hmath_context *context,
                                                        const hmath_value *a0, hmath_value **out);
/* HMath.Optimization.Common.optLearningRate (Options) -> Value. */
HMATH_API hmath_status hmath_optimization_opt_learning_rate(hmath_context *context,
                                                            const hmath_value *a0,
                                                            hmath_value **out);
/* HMath.Optimization.Common.optPoint (Result) -> Value. */
HMATH_API hmath_status hmath_optimization_opt_point(hmath_context *context, const hmath_value *a0,
                                                    hmath_value **out);
/* HMath.Optimization.Common.optValue (Result) -> Value. */
HMATH_API hmath_status hmath_optimization_opt_value(hmath_context *context, const hmath_value *a0,
                                                    hmath_value **out);
/* HMath.Optimization.Common.optGradientNorm (Result) -> Value. */
HMATH_API hmath_status hmath_optimization_opt_gradient_norm(hmath_context *context,
                                                            const hmath_value *a0,
                                                            hmath_value **out);
/* HMath.Optimization.Common.optIterations (Result) -> Value. */
HMATH_API hmath_status hmath_optimization_opt_iterations(hmath_context *context,
                                                         const hmath_value *a0, hmath_value **out);
/* HMath.Optimization.Common.optEvaluations (Result) -> Value. */
HMATH_API hmath_status hmath_optimization_opt_evaluations(hmath_context *context,
                                                          const hmath_value *a0, hmath_value **out);
/* HMath.Optimization.Common.optConverged (Result) -> Value. */
HMATH_API hmath_status hmath_optimization_opt_converged(hmath_context *context,
                                                        const hmath_value *a0, hmath_value **out);
/* HMath.Optimization.Common.bestScore (EarlyStopping) -> Value. */
HMATH_API hmath_status hmath_optimization_best_score(hmath_context *context, const hmath_value *a0,
                                                     hmath_value **out);
/* HMath.Optimization.Common.staleSteps (EarlyStopping) -> Value. */
HMATH_API hmath_status hmath_optimization_stale_steps(hmath_context *context, const hmath_value *a0,
                                                      hmath_value **out);
/* HMath.Optimization.Common.stopped (EarlyStopping) -> Value. */
HMATH_API hmath_status hmath_optimization_stopped(hmath_context *context, const hmath_value *a0,
                                                  hmath_value **out);
/* HMath.Optimization.FirstOrder.GradientDescent () -> GradientMethod. */
HMATH_API hmath_status hmath_optimization_gradient_descent_create(hmath_context *context,
                                                                  hmath_value **out);
/* HMath.Optimization.FirstOrder.Momentum () -> GradientMethod. */
HMATH_API hmath_status hmath_optimization_momentum_create(hmath_context *context,
                                                          hmath_value **out);
/* HMath.Optimization.FirstOrder.Nesterov () -> GradientMethod. */
HMATH_API hmath_status hmath_optimization_nesterov_create(hmath_context *context,
                                                          hmath_value **out);
/* HMath.Optimization.FirstOrder.AdaGrad () -> GradientMethod. */
HMATH_API hmath_status hmath_optimization_ada_grad_create(hmath_context *context,
                                                          hmath_value **out);
/* HMath.Optimization.FirstOrder.RMSProp () -> GradientMethod. */
HMATH_API hmath_status hmath_optimization_rms_prop_create(hmath_context *context,
                                                          hmath_value **out);
/* HMath.Optimization.FirstOrder.AdaDelta () -> GradientMethod. */
HMATH_API hmath_status hmath_optimization_ada_delta_create(hmath_context *context,
                                                           hmath_value **out);
/* HMath.Optimization.FirstOrder.Adam () -> GradientMethod. */
HMATH_API hmath_status hmath_optimization_adam_create(hmath_context *context, hmath_value **out);
/* HMath.Optimization.FirstOrder.AdamW () -> GradientMethod. */
HMATH_API hmath_status hmath_optimization_adam_w_create(hmath_context *context, hmath_value **out);
/* HMath.Optimization.FirstOrder.AMSGrad () -> GradientMethod. */
HMATH_API hmath_status hmath_optimization_ams_grad_create(hmath_context *context,
                                                          hmath_value **out);
/* HMath.Optimization.FirstOrder.AdaMax () -> GradientMethod. */
HMATH_API hmath_status hmath_optimization_ada_max_create(hmath_context *context, hmath_value **out);
/* HMath.Optimization.FirstOrder.Nadam () -> GradientMethod. */
HMATH_API hmath_status hmath_optimization_nadam_create(hmath_context *context, hmath_value **out);
/* HMath.Optimization.FirstOrder.RAdam () -> GradientMethod. */
HMATH_API hmath_status hmath_optimization_r_adam_create(hmath_context *context, hmath_value **out);
/* HMath.Optimization.FirstOrder.initializeOptimizer (Int) -> State. */
HMATH_API hmath_status hmath_optimization_initialize_optimizer(hmath_context *context,
                                                               const hmath_value *a0,
                                                               hmath_value **out);
/* HMath.Optimization.FirstOrder.optimizerStep (GradientMethod, Double, State, Vector, Vector) ->
 * Tuple. */
HMATH_API hmath_status hmath_optimization_optimizer_step(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, hmath_value **out);
/* HMath.Optimization.FirstOrder.minimizeGradient (GradientMethod, Options, Objective, Gradient,
 * Vector) -> Result. */
HMATH_API hmath_status hmath_optimization_minimize_gradient(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, hmath_value **out);
/* HMath.Optimization.FirstOrder.minimizeGradientWithCallback (Monitor, GradientMethod, Options,
 * Objective, Gradient, Vector) -> Result. */
HMATH_API hmath_status hmath_optimization_minimize_gradient_with_callback(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, const hmath_value *a5, hmath_value **out);
/* HMath.Optimization.FirstOrder.stochasticGradient (GradientMethod, Double, Gradients, Vector) ->
 * Tuple. */
HMATH_API hmath_status hmath_optimization_stochastic_gradient(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, hmath_value **out);
/* HMath.Optimization.FirstOrder.miniBatchGradient (Gradients) -> Function. */
HMATH_API hmath_status hmath_optimization_mini_batch_gradient(hmath_context *context,
                                                              const hmath_value *a0,
                                                              hmath_value **out);
/* HMath.Optimization.FirstOrder.projectedGradient (Options, Objective, Gradient, Gradient, Vector)
 * -> Result. */
HMATH_API hmath_status hmath_optimization_projected_gradient(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, hmath_value **out);
/* HMath.Optimization.FirstOrder.proximalGradient (Options, Objective, Gradient, Prox, Vector) ->
 * Result. */
HMATH_API hmath_status hmath_optimization_proximal_gradient(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, hmath_value **out);
/* HMath.Optimization.FirstOrder.fista (Options, Objective, Gradient, Prox, Vector) -> Result. */
HMATH_API hmath_status hmath_optimization_fista(hmath_context *context, const hmath_value *a0,
                                                const hmath_value *a1, const hmath_value *a2,
                                                const hmath_value *a3, const hmath_value *a4,
                                                hmath_value **out);
/* HMath.Optimization.FirstOrder.coordinateDescent (Blocks, Options, Objective, Gradient, Vector) ->
 * Result. */
HMATH_API hmath_status hmath_optimization_coordinate_descent(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, hmath_value **out);
/* HMath.Optimization.Local.GoldenSection () -> ScalarMethod. */
HMATH_API hmath_status hmath_optimization_golden_section_create(hmath_context *context,
                                                                hmath_value **out);
/* HMath.Optimization.Local.TernarySearch () -> ScalarMethod. */
HMATH_API hmath_status hmath_optimization_ternary_search_create(hmath_context *context,
                                                                hmath_value **out);
/* HMath.Optimization.Local.BrentSearch () -> ScalarMethod. */
HMATH_API hmath_status hmath_optimization_brent_search_create(hmath_context *context,
                                                              hmath_value **out);
/* HMath.Optimization.Local.minimizeScalar (ScalarMethod, Options, ScalarObjective, Double, Double)
 * -> Result. */
HMATH_API hmath_status hmath_optimization_minimize_scalar(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, hmath_value **out);
/* HMath.Optimization.Local.BFGS () -> QuasiNewton. */
HMATH_API hmath_status hmath_optimization_bfgs_create(hmath_context *context, hmath_value **out);
/* HMath.Optimization.Local.DFP () -> QuasiNewton. */
HMATH_API hmath_status hmath_optimization_dfp_create(hmath_context *context, hmath_value **out);
/* HMath.Optimization.Local.SR1 () -> QuasiNewton. */
HMATH_API hmath_status hmath_optimization_sr1_create(hmath_context *context, hmath_value **out);
/* HMath.Optimization.Local.LBFGS (Int) -> QuasiNewton. */
HMATH_API hmath_status hmath_optimization_lbfgs_create(hmath_context *context,
                                                       const hmath_value *a0, hmath_value **out);
/* HMath.Optimization.Local.minimizeQuasiNewton (QuasiNewton, Options, Objective, Gradient, Vector)
 * -> Result. */
HMATH_API hmath_status hmath_optimization_minimize_quasi_newton(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, hmath_value **out);
/* HMath.Optimization.Local.Newton () -> NewtonMethod. */
HMATH_API hmath_status hmath_optimization_newton_create(hmath_context *context, hmath_value **out);
/* HMath.Optimization.Local.NewtonCG () -> NewtonMethod. */
HMATH_API hmath_status hmath_optimization_newton_cg_create(hmath_context *context,
                                                           hmath_value **out);
/* HMath.Optimization.Local.TrustRegion (Double) -> NewtonMethod. */
HMATH_API hmath_status hmath_optimization_trust_region_create(hmath_context *context,
                                                              const hmath_value *a0,
                                                              hmath_value **out);
/* HMath.Optimization.Local.Dogleg (Double) -> NewtonMethod. */
HMATH_API hmath_status hmath_optimization_dogleg_create(hmath_context *context,
                                                        const hmath_value *a0, hmath_value **out);
/* HMath.Optimization.Local.minimizeNewton (NewtonMethod, Options, Objective, Gradient, Hessian,
 * Vector) -> Result. */
HMATH_API hmath_status hmath_optimization_minimize_newton(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, const hmath_value *a5, hmath_value **out);
/* HMath.Optimization.Local.nonlinearCG (Options, Objective, Gradient, Vector) -> Result. */
HMATH_API hmath_status hmath_optimization_nonlinear_cg(hmath_context *context,
                                                       const hmath_value *a0, const hmath_value *a1,
                                                       const hmath_value *a2, const hmath_value *a3,
                                                       hmath_value **out);
/* HMath.Optimization.Local.SquaredLoss () -> Loss. */
HMATH_API hmath_status hmath_optimization_squared_loss_create(hmath_context *context,
                                                              hmath_value **out);
/* HMath.Optimization.Local.HuberLoss (Double) -> Loss. */
HMATH_API hmath_status hmath_optimization_huber_loss_create(hmath_context *context,
                                                            const hmath_value *a0,
                                                            hmath_value **out);
/* HMath.Optimization.Local.CauchyLoss (Double) -> Loss. */
HMATH_API hmath_status hmath_optimization_cauchy_loss_create(hmath_context *context,
                                                             const hmath_value *a0,
                                                             hmath_value **out);
/* HMath.Optimization.Local.SoftL1 (Double) -> Loss. */
HMATH_API hmath_status hmath_optimization_soft_l1_create(hmath_context *context,
                                                         const hmath_value *a0, hmath_value **out);
/* HMath.Optimization.Local.leastSquares (Loss, Double, Options, Gradient, Hessian, Vector) ->
 * Result. */
HMATH_API hmath_status hmath_optimization_least_squares(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, const hmath_value *a5, hmath_value **out);
/* HMath.Optimization.Local.nelderMead (Options, Objective, Vector) -> Result. */
HMATH_API hmath_status hmath_optimization_nelder_mead(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, const hmath_value *a2,
                                                      hmath_value **out);
/* HMath.Optimization.Local.powell (Double, Options, Objective, Vector) -> Result. */
HMATH_API hmath_status hmath_optimization_powell(hmath_context *context, const hmath_value *a0,
                                                 const hmath_value *a1, const hmath_value *a2,
                                                 const hmath_value *a3, hmath_value **out);
/* HMath.Optimization.Constrained.Equality (Objective, Gradient) -> Constraint. */
HMATH_API hmath_status hmath_optimization_equality_create(hmath_context *context,
                                                          const hmath_value *a0,
                                                          const hmath_value *a1, hmath_value **out);
/* HMath.Optimization.Constrained.LessEqual (Objective, Gradient) -> Constraint. */
HMATH_API hmath_status hmath_optimization_less_equal_create(hmath_context *context,
                                                            const hmath_value *a0,
                                                            const hmath_value *a1,
                                                            hmath_value **out);
/* HMath.Optimization.Constrained.feasibility (Constraints, Vector) -> Double. */
HMATH_API hmath_status hmath_optimization_feasibility(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, hmath_value **out);
/* HMath.Optimization.Constrained.QuadraticPenalty () -> PenaltyMethod. */
HMATH_API hmath_status hmath_optimization_quadratic_penalty_create(hmath_context *context,
                                                                   hmath_value **out);
/* HMath.Optimization.Constrained.LogBarrier () -> PenaltyMethod. */
HMATH_API hmath_status hmath_optimization_log_barrier_create(hmath_context *context,
                                                             hmath_value **out);
/* HMath.Optimization.Constrained.InteriorPoint () -> PenaltyMethod. */
HMATH_API hmath_status hmath_optimization_interior_point_create(hmath_context *context,
                                                                hmath_value **out);
/* HMath.Optimization.Constrained.AugmentedLagrangian () -> PenaltyMethod. */
HMATH_API hmath_status hmath_optimization_augmented_lagrangian_create(hmath_context *context,
                                                                      hmath_value **out);
/* HMath.Optimization.Constrained.constrainedMinimize (PenaltyMethod, Options, Objective, Gradient,
 * Constraints, Vector) -> Result. */
HMATH_API hmath_status hmath_optimization_constrained_minimize(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, const hmath_value *a5, hmath_value **out);
/* HMath.Optimization.Constrained.LPResult (Vector, Double, Indices, Int) -> LPResult. */
HMATH_API hmath_status hmath_optimization_lp_result_create(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, hmath_value **out);
/* HMath.Optimization.Constrained.linearProgramming (Int, Double, Vector, Matrix, Vector) ->
 * LPResult. */
HMATH_API hmath_status hmath_optimization_linear_programming(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, hmath_value **out);
/* HMath.Optimization.Constrained.revisedSimplex (Int, Double, Vector, Matrix, Vector, Indices) ->
 * LPResult. */
HMATH_API hmath_status hmath_optimization_revised_simplex(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, const hmath_value *a5, hmath_value **out);
/* HMath.Optimization.Constrained.quadraticProgramming (Int, Double, Matrix, Vector, Matrix, Vector)
 * -> Result. */
HMATH_API hmath_status hmath_optimization_quadratic_programming(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, const hmath_value *a5, hmath_value **out);
/* HMath.Optimization.Constrained.slsqp (Options, Objective, Gradient, Hessian, Constraints, Vector)
 * -> Result. */
HMATH_API hmath_status hmath_optimization_slsqp(hmath_context *context, const hmath_value *a0,
                                                const hmath_value *a1, const hmath_value *a2,
                                                const hmath_value *a3, const hmath_value *a4,
                                                const hmath_value *a5, hmath_value **out);
/* HMath.Optimization.Constrained.cobyla (Double, Options, Objective, Objectives, Vector) -> Result.
 */
HMATH_API hmath_status hmath_optimization_cobyla(hmath_context *context, const hmath_value *a0,
                                                 const hmath_value *a1, const hmath_value *a2,
                                                 const hmath_value *a3, const hmath_value *a4,
                                                 hmath_value **out);
/* HMath.Optimization.Constrained.weightedObjective (Vector, Objectives) -> Function. */
HMATH_API hmath_status hmath_optimization_weighted_objective(hmath_context *context,
                                                             const hmath_value *a0,
                                                             const hmath_value *a1,
                                                             hmath_value **out);
/* HMath.Optimization.Constrained.paretoFront (Matrix) -> Indices. */
HMATH_API hmath_status hmath_optimization_pareto_front(hmath_context *context,
                                                       const hmath_value *a0, hmath_value **out);
/* HMath.Optimization.Constrained.lpPoint (LPResult) -> Value. */
HMATH_API hmath_status hmath_optimization_lp_point(hmath_context *context, const hmath_value *a0,
                                                   hmath_value **out);
/* HMath.Optimization.Constrained.lpValue (LPResult) -> Value. */
HMATH_API hmath_status hmath_optimization_lp_value(hmath_context *context, const hmath_value *a0,
                                                   hmath_value **out);
/* HMath.Optimization.Constrained.lpBasis (LPResult) -> Value. */
HMATH_API hmath_status hmath_optimization_lp_basis(hmath_context *context, const hmath_value *a0,
                                                   hmath_value **out);
/* HMath.Optimization.Constrained.lpIterations (LPResult) -> Value. */
HMATH_API hmath_status hmath_optimization_lp_iterations(hmath_context *context,
                                                        const hmath_value *a0, hmath_value **out);
/* HMath.Optimization.Global.SimulatedAnnealing () -> GlobalMethod. */
HMATH_API hmath_status hmath_optimization_simulated_annealing_create(hmath_context *context,
                                                                     hmath_value **out);
/* HMath.Optimization.Global.DifferentialEvolution () -> GlobalMethod. */
HMATH_API hmath_status hmath_optimization_differential_evolution_create(hmath_context *context,
                                                                        hmath_value **out);
/* HMath.Optimization.Global.GeneticAlgorithm () -> GlobalMethod. */
HMATH_API hmath_status hmath_optimization_genetic_algorithm_create(hmath_context *context,
                                                                   hmath_value **out);
/* HMath.Optimization.Global.ParticleSwarm () -> GlobalMethod. */
HMATH_API hmath_status hmath_optimization_particle_swarm_create(hmath_context *context,
                                                                hmath_value **out);
/* HMath.Optimization.Global.CMAES () -> GlobalMethod. */
HMATH_API hmath_status hmath_optimization_cmaes_create(hmath_context *context, hmath_value **out);
/* HMath.Optimization.Global.globalMinimize (GlobalMethod, Int, Word64, Options, Bounds, Objective)
 * -> Result. */
HMATH_API hmath_status hmath_optimization_global_minimize(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, const hmath_value *a5, hmath_value **out);
/* HMath.Optimization.Global.basinHopping (Word64, Double, Int, Options, Bounds, Objective, Vector)
 * -> Result. */
HMATH_API hmath_status hmath_optimization_basin_hopping(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, const hmath_value *a5, const hmath_value *a6,
    hmath_value **out);
#ifdef __cplusplus
}
#endif
#endif
