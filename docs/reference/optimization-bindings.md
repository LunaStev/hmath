# Optimizer bindings

The C and Python APIs call the original functions in `Optimization.Common`,
`FirstOrder`, `Local`, `Constrained` and `Global`. They preserve method
constructors, callbacks, result diagnostics, default options, evaluation budgets
and explicit stochastic seeds. The low-level optimizer-state ABI below remains
available alongside the structured solver API.

Include `hmath_optimization.h` in C or C++. In Python, use
`from hmath import optimization`. These operations use binary64, matching the
original `Double` functions. There is no implicit FP32 optimizer implementation.

## GradientMethod

The mathematical methods and enumeration order are unchanged:

| Haskell | C | Python `optimization.GradientMethod` |
| --- | --- | --- |
| `GradientDescent` | `HMATH_GRADIENT_DESCENT` | `GRADIENT_DESCENT` |
| `Momentum` | `HMATH_MOMENTUM` | `MOMENTUM` |
| `Nesterov` | `HMATH_NESTEROV` | `NESTEROV` |
| `AdaGrad` | `HMATH_ADAGRAD` | `ADAGRAD` |
| `RMSProp` | `HMATH_RMSPROP` | `RMSPROP` |
| `AdaDelta` | `HMATH_ADADELTA` | `ADADELTA` |
| `Adam` | `HMATH_ADAM` | `ADAM` |
| `AdamW` | `HMATH_ADAMW` | `ADAMW` |
| `AMSGrad` | `HMATH_AMSGRAD` | `AMSGRAD` |
| `AdaMax` | `HMATH_ADAMAX` | `ADAMAX` |
| `Nadam` | `HMATH_NADAM` | `NADAM` |
| `RAdam` | `HMATH_RADAM` | `RADAM` |

## initialize_optimizer / hmath_initialize_optimizer

Original: [initializeOptimizer](haskell/HMath-Optimization-FirstOrder.md#v:initializeOptimizer).

```c
hmath_status hmath_initialize_optimizer(
    hmath_context *context, ptrdiff_t dimension, hmath_optimizer_state **out);
```

`optimization.initialize_optimizer(dimension)` and
`optimization.OptimizerState(dimension)` construct the same state.

| Parameter | Meaning |
| --- | --- |
| `dimension` | Number of parameters, represented as Haskell `Int`. Negative values retain the original `InvalidArgument "negative optimizer dimension"` error. Zero is valid. |
| `context` | C cancellation context, or `NULL`. Checked before entry. |
| `out` | C address receiving one owned state reference on success; untouched on failure. |

The result is an immutable state with zero initial moments/history. A state holds
the Haskell runtime alive. `hmath_runtime_shutdown` returns `HMATH_BUSY` while any
state remains alive.

## optimizer_step / hmath_optimizer_step

Original: [optimizerStep](haskell/HMath-Optimization-FirstOrder.md#v:optimizerStep).

```c
hmath_status hmath_optimizer_step(
    hmath_context *context, hmath_gradient_method method, double rate,
    const hmath_optimizer_state *state,
    const double *parameters, size_t parameter_count,
    const double *gradient, size_t gradient_count,
    double *out_parameters, size_t out_capacity,
    hmath_optimizer_state **out_state);
```

Python: `optimization.optimizer_step(method, rate, state, parameters, gradient)`.

| Parameter | Meaning |
| --- | --- |
| `method` | Original `GradientMethod` constructor; see the table above. |
| `rate` | Positive finite learning rate. No default is introduced. |
| `state` | Live state returned by initialization or a previous step. |
| `parameters` | Current parameters, in parameter order. |
| `gradient` | Gradient components in the same order. The binding does not compute or modify the gradient. |
| `parameter_count`, `gradient_count` | C lengths of the corresponding readable buffers. |
| `context` | C cancellation context, or `NULL`; checked before entry. |
| `out_parameters`, `out_capacity` | C writable result buffer and its capacity in doubles. Capacity must be at least `parameter_count`. |
| `out_state` | C address receiving one owned reference to the new state. |

Python returns `(new_parameters, new_state)`; C writes those same two results.
The original state is unchanged and may be reused to branch a computation.
All output memory must be disjoint from the inputs and other outputs. On failure
both C outputs remain untouched. Inputs are borrowed only for the call; each
thread must retain a state reference while using it. Independent calls can share
an immutable state, but must use separate output buffers.

Original constants remain unchanged: β₁ = 0.9, β₂ = 0.999, ε = 10⁻⁸;
RMSProp/AdaDelta use ρ = 0.9, and AdamW uses weight decay 0.01.
`Nesterov` in this function applies the original corrected momentum direction;
it does not perform the look-ahead objective evaluation of `minimizeGradient`.

Non-finite parameters, gradients, state or results return the original
`NonFiniteResult`. Nonpositive rates or mismatched dimensions return the original
`InvalidArgument "optimizer rate or state shape"`. A Haskell `MathError` is status
11 in C and `HMathError` with `status == 11` in Python; the error message retains
the constructor and payload. Invalid C pointers/enum representations, insufficient
buffer capacity and allocation failures are separate binding errors.

## State ownership

`hmath_optimizer_state_retain(state)` adds a reference;
`hmath_optimizer_state_release(state)` releases one. Both accept `NULL` as a no-op.
Final release frees the Haskell state and its runtime reservation. Never use a
released state or release the last reference concurrently with a call using it.

Python `state.close()` is idempotent. A `with state:` block closes that reference
on exit; the destructor is a fallback. A closed state rejects further steps with
`ValueError`. Each returned state is independently owned.

```python
from hmath import optimization

with optimization.initialize_optimizer(2) as initial:
    parameters, updated = optimization.optimizer_step(
        optimization.GradientMethod.ADAM,
        0.01,
        initial,
        [1.0, -2.0],
        [2.0, -4.0],
    )
    with updated:
        assert len(parameters) == 2
        assert parameters[0] < 1.0
        assert parameters[1] > -2.0
```

See also: [original Haskell optimizer API](haskell/HMath-Optimization-FirstOrder.md),
[C runtime and errors](c.md#runtime), [numeric bindings](numeric-bindings.md).

## Solver records and options

```python
from hmath import optimization as opt

options = opt.OptimizeOptions(
    max_iterations=1000,
    max_evaluations=20000,
    tolerance=1e-8,
    learning_rate=0.01,
)
result = opt.minimize_quasi_newton(
    opt.BFGS,
    options,
    lambda point: sum(x*x for x in point),
    lambda point: [2*x for x in point],
    [1.0, -2.0],
)
print(result.point, result.value, result.converged)
```

`default_optimize_options()` returns the original defaults shown above. Options
are immutable Python records; create another `OptimizeOptions` to change them.
The source validates options inside the relevant operation. Constructor calls
do not invent stricter validation.

| Record | Fields, in constructor order |
| --- | --- |
| `OptimizeOptions` | `max_iterations`: iteration budget; `max_evaluations`: evaluation budget; `tolerance`: stopping tolerance; `learning_rate`: positive update rate |
| `OptimizeResult` | `point`: final parameter vector; `value`: objective; `gradient_norm`: original solver's residual diagnostic; `iterations`: source iteration count; `evaluations`: source evaluation count; `converged`: original stopping flag |
| `LPResult` | `point`: primal variables; `value`: objective; `basis`: retained zero-based basis indices; `iterations`: source pivot count |
| `EarlyStopping` | `best_score`: `None` or best score; `stale_steps`: stale observation count; `stopped`: stop flag |

The `opt_*`, `lp_*`, `best_score`, `stale_steps` and `stopped` functions expose
original record selectors as well. They are equivalent to reading the matching
record field. A result's diagnostic is solver specific: scalar minimization
reports bracket width, projected/proximal methods report a mapping residual,
and global methods report spread or step size. A global convergence flag does
not certify global optimality. Some algorithms return their incumbent with
`converged=False` on exhaustion; others return `NonConvergence`. Those original
choices and evaluation-accounting rules remain unchanged.

## Callbacks and returned functions

| Source/Python type | Python arguments | Successful result |
| --- | --- | --- |
| `Objective` | `point` | scalar `float` |
| `Gradient` | `point` | vector |
| `Hessian` | `point` | rows of a matrix |
| `ResidualFunction` | `point` | residual vector |
| `JacobianFunction` | `point` | Jacobian rows |
| Projection | `point` | projected vector |
| Proximal operator | `rate, point` | vector |
| Iterate monitor | `OptimizeResult` | `bool`; `False` stops the original monitor-based minimizer |

`minimize_scalar` alone passes a scalar to its objective. Python callbacks return
ordinary values or raise [a structured MathError](errors.md#checked-callbacks)
to return the original `Left` branch. Such failures remain recoverable by the
original solver; for example, feasible barrier backtracking retries a rejected
`DomainError`. Unexpected Python exceptions abort the call and are re-raised
after temporary native values are cleaned up.

`mini_batch_gradient(gradients)` returns a callable original gradient;
`weighted_objective(weights, objectives)` returns a callable original objective.
They evaluate lazily when called. Use the returned function as a context manager
or call `.close()`; its callback references remain alive transitively. Empty
batches, wrong gradient lengths and invalid weights retain original errors.
A callback may call other HMath operations reentrantly. It must not request
final runtime shutdown.

All these original solvers operate on `Double`. Supplying Python or C float32
values does not select an FP32 solver. Vectors/matrices are lists of binary64
values at this API, with no added rectangularization, truncation or finite-value
checks. Exact generic `transpose` accepts shared Value elements (including
integers, rationals, strings and structured native values) and preserves the
original ragged-list behavior.

## Methods and solver contracts

Learning schedules are `ConstantRate(rate)`,
`StepDecay(initial_rate, period, decay)`,
`ExponentialDecay(initial_rate, decay)`,
`CosineAnnealing(maximum, minimum, period)` and `Warmup(steps, base)`.
`learning_rate(schedule, step)` calls the original schedule validation and
formula, including nesting. `early_stopping(patience, min_delta, value, state)`
minimizes the observed score and returns the next immutable state.

Scalar methods are `GoldenSection`, `TernarySearch`, `BrentSearch`; the finite
bracket must satisfy `lower < upper`. Quasi-Newton methods are `BFGS`,
`LBFGS(memory)`, `DFP`, `SR1`. Newton methods are `Newton`, `NewtonCG`,
`TrustRegion(radius)`, `Dogleg(radius)`; Hessians are supplied explicitly.
Least-squares losses are `SquaredLoss`, `HuberLoss(scale)`, `CauchyLoss(scale)`,
`SoftL1(scale)`; `least_squares` also takes the original positive damping value.
`nelder_mead` and `powell` need only an objective. `nonlinear_cg` takes an
objective and gradient.

`stochastic_gradient` makes one pass over the explicit gradients in order,
returning `(point, OptimizerState)`; ordering/shuffling remain caller owned.
`projected_gradient` projects each update. `proximal_gradient` and `fista` call
the supplied proximal operator. `coordinate_descent` requires nonempty blocks
that partition the zero-based parameter indices exactly once. No additional
momentum constants or tuning parameters are introduced by the binding.

Constraints are `Equality(objective, gradient)` for `g(x) = 0` and
`LessEqual(objective, gradient)` for `g(x) <= 0`. `feasibility` returns the maximum
absolute equality or positive inequality violation. `constrained_minimize`
accepts `QuadraticPenalty`, `LogBarrier`, `InteriorPoint`,
`AugmentedLagrangian`; barrier methods require strictly feasible inequality-only
initial points. `slsqp` takes explicit Hessians; `cobyla` takes constraint
objectives without derivative callbacks and an initial radius.

`linear_programming` minimizes `cost·x` with `A x <= rhs` and `x >= 0`, including
phase I for negative right-hand sides. `revised_simplex` instead uses its
original equality-form feasible-basis contract: provide a full row-rank matrix
and a valid feasible basis, with indices into its columns.
`quadratic_programming` minimizes `0.5*xᵀ*H*x + costᵀ*x` under `A x <= rhs`;
its budget bounds dense active-set enumeration. These are the original bounded
dense reference algorithms. `pareto_front` returns zero-based indices of
nondominated minimization vectors. `weighted_objective` keeps each supplied
objective and its original weight validation.

Global methods are `SimulatedAnnealing`, `DifferentialEvolution`,
`GeneticAlgorithm`, `ParticleSwarm`, `CMAES`. `global_minimize` requires a
population size of at least four and finite `(lower, upper)` bounds with
`lower < upper`. Its seed is the exact original unsigned 64-bit seed, including
values above 2⁵³. `basin_hopping` additionally takes temperature, hop count and
an in-bounds initial vector; it performs original local Nelder–Mead descents.
No global RNG, system entropy or replacement stochastic implementation is used.

## Structured C and C++ solver API

Include `hmath_optimization.h` (which includes `hmath_optimization_all.h`). Every
named structured wrapper follows the source argument order in the tables below:

```c
hmath_status hmath_optimization_minimize_quasi_newton(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *options,
    const hmath_value *objective,
    const hmath_value *gradient,
    const hmath_value *initial,
    hmath_value **out);
```

Arguments use [shared immutable Values](values.md): scalar `Double`, `Int`
index, exact `Word64` scalar seed, lists/tuples, or opaque original records and
method constructors. Constructor wrappers end in `_create`. Selectors return
copied Values; numerical solvers return an `OptimizeResult` or `LPResult` Value.
Release every owned output with `hmath_value_release`. Inputs are borrowed for
the call; immutable sharing across threads is allowed when each user retains
its own live reference. Final release must not race a call using the same last
reference. Output pointer storage must be disjoint from inputs and remains
untouched on failure.

Create function Values with `hmath_optimization_callback(context, role,
function, userdata, out)`. Roles are 0 objective, 1 gradient/projection,
2 Hessian/Jacobian, 3 proximal operator, 4 monitor. The C callback receives one
borrowed Value: a parameter list, a `(rate, point)` tuple for role 3, or a result
record for role 4. A scalar-minimization objective receives `[x]` in C. Return
one owned Value reference on success (retain a borrowed input before returning
it). On `HMATH_MATH_ERROR`, fill the `hmath_math_error` wire; other failures
abort the operation. Function pointers, userdata and borrowed error buffers
must remain valid until consumed; pointers/userdata used in a derived function
or constraint remain live until its final release. Calls are synchronous and
may reenter HMath; callback/thread safety remains the caller's responsibility.

`hmath_optimization_function_apply` invokes a returned function Value with an
array of argument Values. `hmath_optimization_state_import` and `_state_export`
convert between a structured state Value and the compatible low-level
`hmath_optimizer_state` handle; each conversion returns independent ownership.
All live native Values and optimizer states reserve the Haskell runtime.

## Named function mapping

The following signatures give the exact argument order. Python `None` denotes
a source `Nothing`/unit as appropriate; all source checked errors use the
structured error contract above. For full mathematical formulas and source
validation conditions, follow the defining Haskell module for each group.

### Common

[Original Haskell reference](haskell/HMath-Optimization-Common.md).

| Python callable or constructor | Result | C wrapper |
| --- | --- | --- |
| `OptimizeOptions(max_iterations, max_evaluations, tolerance, learning_rate)` | `OptimizeOptions` | `hmath_optimization_optimize_options_create` |
| `default_optimize_options()` | `OptimizeOptions` | `hmath_optimization_default_optimize_options` |
| `OptimizeResult(point, value, gradient_norm, iterations, evaluations, converged)` | `OptimizeResult` | `hmath_optimization_optimize_result_create` |
| `EarlyStopping(best_score, stale_steps, stopped)` | `EarlyStopping` | `hmath_optimization_early_stopping_create` |
| `ConstantRate(rate)` | `LearningRate` | `hmath_optimization_constant_rate_create` |
| `StepDecay(initial_rate, period, decay)` | `LearningRate` | `hmath_optimization_step_decay_create` |
| `ExponentialDecay(initial_rate, decay)` | `LearningRate` | `hmath_optimization_exponential_decay_create` |
| `CosineAnnealing(maximum, minimum, period)` | `LearningRate` | `hmath_optimization_cosine_annealing_create` |
| `Warmup(steps, base)` | `LearningRate` | `hmath_optimization_warmup_create` |
| `Armijo` | `LineSearch` | `hmath_optimization_armijo_create` |
| `StrongWolfe` | `LineSearch` | `hmath_optimization_strong_wolfe_create` |
| `checked_options(options)` | `None` | `hmath_optimization_checked_options` |
| `checked_point(point)` | `None` | `hmath_optimization_checked_point` |
| `checked_value(objective, point)` | `Double` | `hmath_optimization_checked_value` |
| `checked_gradient(gradient, point)` | `Vector` | `hmath_optimization_checked_gradient` |
| `check_budget(options, evaluations)` | `None` | `hmath_optimization_check_budget` |
| `dot(left, right)` | `original field/helper value` | `hmath_optimization_dot` |
| `add(left, right)` | `original field/helper value` | `hmath_optimization_add` |
| `sub(left, right)` | `original field/helper value` | `hmath_optimization_sub` |
| `outer(left, right)` | `original field/helper value` | `hmath_optimization_outer` |
| `norm(values)` | `Double` | `hmath_optimization_norm` |
| `scale(factor, values)` | `Vector` | `hmath_optimization_scale` |
| `identity(dimension)` | `Matrix` | `hmath_optimization_identity` |
| `mat_vec(matrix, vector)` | `Vector` | `hmath_optimization_mat_vec` |
| `mat_mul(left, right)` | `Matrix` | `hmath_optimization_mat_mul` |
| `transpose(rows)` | `GenericMatrix` | `hmath_optimization_transpose` |
| `solve_dense(matrix, rhs)` | `Vector` | `hmath_optimization_solve_dense` |
| `result(iterations, evaluations, converged, objective, gradient, point)` | `OptimizeResult` | `hmath_optimization_result` |
| `learning_rate(schedule, step)` | `Double` | `hmath_optimization_learning_rate` |
| `early_stopping(patience, min_delta, value, state)` | `EarlyStopping` | `hmath_optimization_early_stopping` |
| `line_search(method, budget, objective, gradient, point, direction, value, point_gradient)` | `original tuple` | `hmath_optimization_line_search` |
| `opt_max_iterations(value)` | `original field/helper value` | `hmath_optimization_opt_max_iterations` |
| `opt_max_evaluations(value)` | `original field/helper value` | `hmath_optimization_opt_max_evaluations` |
| `opt_tolerance(value)` | `original field/helper value` | `hmath_optimization_opt_tolerance` |
| `opt_learning_rate(value)` | `original field/helper value` | `hmath_optimization_opt_learning_rate` |
| `opt_point(value)` | `original field/helper value` | `hmath_optimization_opt_point` |
| `opt_value(value)` | `original field/helper value` | `hmath_optimization_opt_value` |
| `opt_gradient_norm(value)` | `original field/helper value` | `hmath_optimization_opt_gradient_norm` |
| `opt_iterations(value)` | `original field/helper value` | `hmath_optimization_opt_iterations` |
| `opt_evaluations(value)` | `original field/helper value` | `hmath_optimization_opt_evaluations` |
| `opt_converged(value)` | `original field/helper value` | `hmath_optimization_opt_converged` |
| `best_score(value)` | `original field/helper value` | `hmath_optimization_best_score` |
| `stale_steps(value)` | `original field/helper value` | `hmath_optimization_stale_steps` |
| `stopped(value)` | `original field/helper value` | `hmath_optimization_stopped` |

### FirstOrder

[Original Haskell reference](haskell/HMath-Optimization-FirstOrder.md).

| Python callable or constructor | Result | C wrapper |
| --- | --- | --- |
| `GradientMethod.GRADIENT_DESCENT` | `GradientMethod` | `hmath_optimization_gradient_descent_create` |
| `GradientMethod.MOMENTUM` | `GradientMethod` | `hmath_optimization_momentum_create` |
| `GradientMethod.NESTEROV` | `GradientMethod` | `hmath_optimization_nesterov_create` |
| `GradientMethod.ADAGRAD` | `GradientMethod` | `hmath_optimization_ada_grad_create` |
| `GradientMethod.RMSPROP` | `GradientMethod` | `hmath_optimization_rms_prop_create` |
| `GradientMethod.ADADELTA` | `GradientMethod` | `hmath_optimization_ada_delta_create` |
| `GradientMethod.ADAM` | `GradientMethod` | `hmath_optimization_adam_create` |
| `GradientMethod.ADAMW` | `GradientMethod` | `hmath_optimization_adam_w_create` |
| `GradientMethod.AMSGRAD` | `GradientMethod` | `hmath_optimization_ams_grad_create` |
| `GradientMethod.ADAMAX` | `GradientMethod` | `hmath_optimization_ada_max_create` |
| `GradientMethod.NADAM` | `GradientMethod` | `hmath_optimization_nadam_create` |
| `GradientMethod.RADAM` | `GradientMethod` | `hmath_optimization_r_adam_create` |
| `initialize_optimizer(dimension)` | `OptimizerState` | `hmath_optimization_initialize_optimizer` |
| `optimizer_step(method, rate, state, parameters, gradient)` | `original tuple` | `hmath_optimization_optimizer_step` |
| `minimize_gradient(method, options, objective, gradient, initial)` | `OptimizeResult` | `hmath_optimization_minimize_gradient` |
| `minimize_gradient_with_callback(monitor, method, options, objective, gradient, initial)` | `OptimizeResult` | `hmath_optimization_minimize_gradient_with_callback` |
| `stochastic_gradient(method, rate, gradients, initial)` | `original tuple` | `hmath_optimization_stochastic_gradient` |
| `mini_batch_gradient(gradients)` | `owned callable` | `hmath_optimization_mini_batch_gradient` |
| `projected_gradient(options, objective, gradient, project, initial)` | `OptimizeResult` | `hmath_optimization_projected_gradient` |
| `proximal_gradient(options, objective, gradient, prox, initial)` | `OptimizeResult` | `hmath_optimization_proximal_gradient` |
| `fista(options, objective, gradient, prox, initial)` | `OptimizeResult` | `hmath_optimization_fista` |
| `coordinate_descent(blocks, options, objective, gradient, initial)` | `OptimizeResult` | `hmath_optimization_coordinate_descent` |

### Local

[Original Haskell reference](haskell/HMath-Optimization-Local.md).

| Python callable or constructor | Result | C wrapper |
| --- | --- | --- |
| `GoldenSection` | `ScalarMethod` | `hmath_optimization_golden_section_create` |
| `TernarySearch` | `ScalarMethod` | `hmath_optimization_ternary_search_create` |
| `BrentSearch` | `ScalarMethod` | `hmath_optimization_brent_search_create` |
| `minimize_scalar(method, options, objective, lower, upper)` | `OptimizeResult` | `hmath_optimization_minimize_scalar` |
| `BFGS` | `QuasiNewton` | `hmath_optimization_bfgs_create` |
| `DFP` | `QuasiNewton` | `hmath_optimization_dfp_create` |
| `SR1` | `QuasiNewton` | `hmath_optimization_sr1_create` |
| `LBFGS(memory)` | `QuasiNewton` | `hmath_optimization_lbfgs_create` |
| `minimize_quasi_newton(method, options, objective, gradient, initial)` | `OptimizeResult` | `hmath_optimization_minimize_quasi_newton` |
| `Newton` | `NewtonMethod` | `hmath_optimization_newton_create` |
| `NewtonCG` | `NewtonMethod` | `hmath_optimization_newton_cg_create` |
| `TrustRegion(radius)` | `NewtonMethod` | `hmath_optimization_trust_region_create` |
| `Dogleg(radius)` | `NewtonMethod` | `hmath_optimization_dogleg_create` |
| `minimize_newton(method, options, objective, gradient, hessian, initial)` | `OptimizeResult` | `hmath_optimization_minimize_newton` |
| `nonlinear_cg(options, objective, gradient, initial)` | `OptimizeResult` | `hmath_optimization_nonlinear_cg` |
| `SquaredLoss` | `Loss` | `hmath_optimization_squared_loss_create` |
| `HuberLoss(scale)` | `Loss` | `hmath_optimization_huber_loss_create` |
| `CauchyLoss(scale)` | `Loss` | `hmath_optimization_cauchy_loss_create` |
| `SoftL1(scale)` | `Loss` | `hmath_optimization_soft_l1_create` |
| `least_squares(loss, damping, options, residual, jacobian, initial)` | `OptimizeResult` | `hmath_optimization_least_squares` |
| `nelder_mead(options, objective, initial)` | `OptimizeResult` | `hmath_optimization_nelder_mead` |
| `powell(initial_step, options, objective, initial)` | `OptimizeResult` | `hmath_optimization_powell` |

### Constrained

[Original Haskell reference](haskell/HMath-Optimization-Constrained.md).

| Python callable or constructor | Result | C wrapper |
| --- | --- | --- |
| `Equality(objective, gradient)` | `Constraint` | `hmath_optimization_equality_create` |
| `LessEqual(objective, gradient)` | `Constraint` | `hmath_optimization_less_equal_create` |
| `feasibility(constraints, point)` | `Double` | `hmath_optimization_feasibility` |
| `QuadraticPenalty` | `PenaltyMethod` | `hmath_optimization_quadratic_penalty_create` |
| `LogBarrier` | `PenaltyMethod` | `hmath_optimization_log_barrier_create` |
| `InteriorPoint` | `PenaltyMethod` | `hmath_optimization_interior_point_create` |
| `AugmentedLagrangian` | `PenaltyMethod` | `hmath_optimization_augmented_lagrangian_create` |
| `constrained_minimize(method, options, objective, gradient, constraints, initial)` | `OptimizeResult` | `hmath_optimization_constrained_minimize` |
| `LPResult(point, value, basis, iterations)` | `LPResult` | `hmath_optimization_lp_result_create` |
| `linear_programming(budget, tolerance, cost, matrix, rhs)` | `LPResult` | `hmath_optimization_linear_programming` |
| `revised_simplex(budget, tolerance, cost, matrix, rhs, basis)` | `LPResult` | `hmath_optimization_revised_simplex` |
| `quadratic_programming(budget, tolerance, hessian, cost, matrix, rhs)` | `OptimizeResult` | `hmath_optimization_quadratic_programming` |
| `slsqp(options, objective, gradient, hessian, constraints, initial)` | `OptimizeResult` | `hmath_optimization_slsqp` |
| `cobyla(initial_radius, options, objective, constraints, initial)` | `OptimizeResult` | `hmath_optimization_cobyla` |
| `weighted_objective(weights, objectives)` | `owned callable` | `hmath_optimization_weighted_objective` |
| `pareto_front(points)` | `list[int]` | `hmath_optimization_pareto_front` |
| `lp_point(value)` | `original field/helper value` | `hmath_optimization_lp_point` |
| `lp_value(value)` | `original field/helper value` | `hmath_optimization_lp_value` |
| `lp_basis(value)` | `original field/helper value` | `hmath_optimization_lp_basis` |
| `lp_iterations(value)` | `original field/helper value` | `hmath_optimization_lp_iterations` |

### Global

[Original Haskell reference](haskell/HMath-Optimization-Global.md).

| Python callable or constructor | Result | C wrapper |
| --- | --- | --- |
| `SimulatedAnnealing` | `GlobalMethod` | `hmath_optimization_simulated_annealing_create` |
| `DifferentialEvolution` | `GlobalMethod` | `hmath_optimization_differential_evolution_create` |
| `GeneticAlgorithm` | `GlobalMethod` | `hmath_optimization_genetic_algorithm_create` |
| `ParticleSwarm` | `GlobalMethod` | `hmath_optimization_particle_swarm_create` |
| `CMAES` | `GlobalMethod` | `hmath_optimization_cmaes_create` |
| `global_minimize(method, population_size, seed, options, bounds, objective)` | `OptimizeResult` | `hmath_optimization_global_minimize` |
| `basin_hopping(seed, temperature, hops, options, bounds, objective, initial)` | `OptimizeResult` | `hmath_optimization_basin_hopping` |
