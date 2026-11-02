# Numerical solvers

Python exposes `hmath.calculus`, `hmath.root`, `hmath.ode` and `hmath.pde`. C includes `hmath_numerical.h`. Every named operation invokes the original Haskell function with its original argument order, defaults, budgets, diagnostic fields, finite checks and errors.

Inputs are borrowed, successful outputs own a [structured value](values.md), and failure leaves output pointers untouched. Immutable handles can be shared by concurrent readers retaining their own references. Source `Left MathError` returns status11 with its full structured payload. Cancellation is checked before entry; source evaluation/step limits govern the solver.

Function arguments are kind101 objects constructed with `hmath_linear_callback`. Their input is a tuple of the source's curried arguments flattened into positional order; their output transfers one owned value. Callbacks may reenter checked APIs and must not unwind through C. Python accepts normal callables and re-raises their original exceptions after cleanup. An actual source `Either MathError` callback may return a recoverable mathematical error; pure callbacks propagate it to the outer boundary. Callback function/userdata must remain valid for all objects retaining them. Python propagates these owners automatically.

`Estimate` retains an arbitrary structured payload; its value is never implicitly converted to binary64. Numerical estimates produced by these solvers have their original binary64 payload. `Matrix Double`, sparse operators and exact polynomial inputs interoperate with their existing typed binding owners.

## `calculus.estimate`

`calculus.estimate(value, error, evaluations)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.Estimate`](haskell/HMath-Calculus.md#v:Estimate).

```haskell
a -> Double -> Int -> Estimate a
```

```c
hmath_status hmath_calculus_estimate(hmath_context *context, const hmath_value *value, const hmath_value *error, const hmath_value *evaluations, hmath_value **out);
```

## `calculus.estimate_value`

`calculus.estimate_value(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.estimateValue`](haskell/HMath-Calculus.md#v:estimateValue).

```haskell
Estimate a -> a
```

```c
hmath_status hmath_calculus_estimate_value(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `calculus.estimate_error`

`calculus.estimate_error(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.estimateError`](haskell/HMath-Calculus.md#v:estimateError).

```haskell
Estimate a -> Double
```

```c
hmath_status hmath_calculus_estimate_error(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `calculus.evaluations`

`calculus.evaluations(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.evaluations`](haskell/HMath-Calculus.md#v:evaluations).

```haskell
Estimate a -> Int
```

```c
hmath_status hmath_calculus_evaluations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `calculus.tolerance`

`calculus.tolerance(absolute_tolerance, relative_tolerance, maximum_evaluations)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.Tolerance`](haskell/HMath-Calculus.md#v:Tolerance).

```haskell
Double -> Double -> Int -> Tolerance
```

```c
hmath_status hmath_calculus_tolerance(hmath_context *context, const hmath_value *absolute_tolerance, const hmath_value *relative_tolerance, const hmath_value *maximum_evaluations, hmath_value **out);
```

## `calculus.absolute_tolerance`

`calculus.absolute_tolerance(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.absoluteTolerance`](haskell/HMath-Calculus.md#v:absoluteTolerance).

```haskell
Tolerance -> Double
```

```c
hmath_status hmath_calculus_absolute_tolerance(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `calculus.relative_tolerance`

`calculus.relative_tolerance(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.relativeTolerance`](haskell/HMath-Calculus.md#v:relativeTolerance).

```haskell
Tolerance -> Double
```

```c
hmath_status hmath_calculus_relative_tolerance(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `calculus.maximum_evaluations`

`calculus.maximum_evaluations(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.maximumEvaluations`](haskell/HMath-Calculus.md#v:maximumEvaluations).

```haskell
Tolerance -> Int
```

```c
hmath_status hmath_calculus_maximum_evaluations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `calculus.default_tolerance`

`calculus.default_tolerance()`

Default adaptive tolerance: 1e-10 absolute, 1e-8 relative, 100000 evaluations.

Original: [`HMath.Calculus.defaultTolerance`](haskell/HMath-Calculus.md#v:defaultTolerance).

```haskell
Tolerance
```

```c
hmath_status hmath_calculus_default_tolerance(hmath_context *context, hmath_value **out);
```

## `calculus.forward`

`calculus.forward()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.Forward`](haskell/HMath-Calculus.md#v:Forward).

```haskell
Difference
```

```c
hmath_status hmath_calculus_forward(hmath_context *context, hmath_value **out);
```

## `calculus.backward`

`calculus.backward()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.Backward`](haskell/HMath-Calculus.md#v:Backward).

```haskell
Difference
```

```c
hmath_status hmath_calculus_backward(hmath_context *context, hmath_value **out);
```

## `calculus.central`

`calculus.central()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.Central`](haskell/HMath-Calculus.md#v:Central).

```haskell
Difference
```

```c
hmath_status hmath_calculus_central(hmath_context *context, hmath_value **out);
```

## `calculus.trapezoidal`

`calculus.trapezoidal()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.Trapezoidal`](haskell/HMath-Calculus.md#v:Trapezoidal).

```haskell
Quadrature
```

```c
hmath_status hmath_calculus_trapezoidal(hmath_context *context, hmath_value **out);
```

## `calculus.simpson`

`calculus.simpson()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.Simpson`](haskell/HMath-Calculus.md#v:Simpson).

```haskell
Quadrature
```

```c
hmath_status hmath_calculus_simpson(hmath_context *context, hmath_value **out);
```

## `calculus.three_eighths`

`calculus.three_eighths()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Calculus.ThreeEighths`](haskell/HMath-Calculus.md#v:ThreeEighths).

```haskell
Quadrature
```

```c
hmath_status hmath_calculus_three_eighths(hmath_context *context, hmath_value **out);
```

## `calculus.derivative`

`calculus.derivative(method, h, f, x)`

First derivative with explicit positive finite step; rounded-away steps fail.

Original: [`HMath.Calculus.derivative`](haskell/HMath-Calculus.md#v:derivative).

```haskell
Difference -> Double -> (Double -> Double) -> Double -> Either MathError Double
```

```c
hmath_status hmath_calculus_derivative(hmath_context *context, const hmath_value *method, const hmath_value *h, const hmath_value *f, const hmath_value *x, hmath_value **out);
```

## `calculus.derivative_n`

`calculus.derivative_n(order, h, f, x)`

 Arbitrary nonnegative derivative order by recursively centered differences. Work grows exponentially with the requested order; orders are limited to 12. 

Original: [`HMath.Calculus.derivativeN`](haskell/HMath-Calculus.md#v:derivativeN).

```haskell
Int -> Double -> (Double -> Double) -> Double -> Either MathError Double
```

```c
hmath_status hmath_calculus_derivative_n(hmath_context *context, const hmath_value *order, const hmath_value *h, const hmath_value *f, const hmath_value *x, hmath_value **out);
```

## `calculus.complex_derivative`

`calculus.complex_derivative(h, f, x)`

 Complex-step first derivative. The callback must have a holomorphic extension and be real on the real axis. 

Original: [`HMath.Calculus.complexDerivative`](haskell/HMath-Calculus.md#v:complexDerivative).

```haskell
Double -> (Complex Double -> Complex Double) -> Double -> Either MathError Double
```

```c
hmath_status hmath_calculus_complex_derivative(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, hmath_value **out);
```

## `calculus.richardson`

`calculus.richardson(tol, initial, f, x)`

 Richardson extrapolation of a central first difference. Each row halves the step. Evaluation budget is 2 per row; convergence uses consecutive diagonals. 

Original: [`HMath.Calculus.richardson`](haskell/HMath-Calculus.md#v:richardson).

```haskell
Tolerance -> Double -> (Double -> Double) -> Double -> Either MathError (Estimate Double)
```

```c
hmath_status hmath_calculus_richardson(hmath_context *context, const hmath_value *tol, const hmath_value *initial, const hmath_value *f, const hmath_value *x, hmath_value **out);
```

## `calculus.ridders`

`calculus.ridders(tol, initial, f, x)`

Ridders extrapolation with factor 1.4 and a best-error stopping criterion.

Original: [`HMath.Calculus.ridders`](haskell/HMath-Calculus.md#v:ridders).

```haskell
Tolerance -> Double -> (Double -> Double) -> Double -> Either MathError (Estimate Double)
```

```c
hmath_status hmath_calculus_ridders(hmath_context *context, const hmath_value *tol, const hmath_value *initial, const hmath_value *f, const hmath_value *x, hmath_value **out);
```

## `calculus.limit`

`calculus.limit(side, tol, initial, f, x)`

 One-sided numerical limit, approaching geometrically from the requested side. Central compares the average of both sides; it cannot prove continuity. 

Original: [`HMath.Calculus.limit`](haskell/HMath-Calculus.md#v:limit).

```haskell
Difference -> Tolerance -> Double -> (Double -> Double) -> Double -> Either MathError (Estimate Double)
```

```c
hmath_status hmath_calculus_limit(hmath_context *context, const hmath_value *side, const hmath_value *tol, const hmath_value *initial, const hmath_value *f, const hmath_value *x, hmath_value **out);
```

## `calculus.partial_derivative`

`calculus.partial_derivative(i, h, f, xs)`

Partial derivative at a zero-based coordinate.

Original: [`HMath.Calculus.partialDerivative`](haskell/HMath-Calculus.md#v:partialDerivative).

```haskell
Int -> Double -> ([Double] -> Double) -> [Double] -> Either MathError Double
```

```c
hmath_status hmath_calculus_partial_derivative(hmath_context *context, const hmath_value *i, const hmath_value *h, const hmath_value *f, const hmath_value *xs, hmath_value **out);
```

## `calculus.gradient`

`calculus.gradient(h, f, xs)`

Gradient using one central difference per coordinate.

Original: [`HMath.Calculus.gradient`](haskell/HMath-Calculus.md#v:gradient).

```haskell
Double -> ([Double] -> Double) -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_calculus_gradient(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *xs, hmath_value **out);
```

## `calculus.jacobian`

`calculus.jacobian(h, f, xs)`

Row-major Jacobian; callback output dimensions must remain constant.

Original: [`HMath.Calculus.jacobian`](haskell/HMath-Calculus.md#v:jacobian).

```haskell
Double -> ([Double] -> [Double]) -> [Double] -> Either MathError (Matrix Double)
```

```c
hmath_status hmath_calculus_jacobian(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *xs, hmath_value **out);
```

## `calculus.hessian`

`calculus.hessian(h, f, xs)`

Hessian with centered diagonal and mixed differences.

Original: [`HMath.Calculus.hessian`](haskell/HMath-Calculus.md#v:hessian).

```haskell
Double -> ([Double] -> Double) -> [Double] -> Either MathError (Matrix Double)
```

```c
hmath_status hmath_calculus_hessian(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *xs, hmath_value **out);
```

## `calculus.directional_derivative`

`calculus.directional_derivative(h, f, x, v)`

Directional derivative; the direction is used as supplied, without normalization.

Original: [`HMath.Calculus.directionalDerivative`](haskell/HMath-Calculus.md#v:directionalDerivative).

```haskell
Double -> ([Double] -> Double) -> [Double] -> [Double] -> Either MathError Double
```

```c
hmath_status hmath_calculus_directional_derivative(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, const hmath_value *v, hmath_value **out);
```

## `calculus.jvp`

`calculus.jvp(h, f, x, v)`

Jacobian-vector product by directional central differences.

Original: [`HMath.Calculus.jvp`](haskell/HMath-Calculus.md#v:jvp).

```haskell
Double -> ([Double] -> [Double]) -> [Double] -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_calculus_jvp(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, const hmath_value *v, hmath_value **out);
```

## `calculus.vjp`

`calculus.vjp(h, f, x, v)`

Vector-Jacobian product as the gradient of a scalar contraction.

Original: [`HMath.Calculus.vjp`](haskell/HMath-Calculus.md#v:vjp).

```haskell
Double -> ([Double] -> [Double]) -> [Double] -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_calculus_vjp(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, const hmath_value *v, hmath_value **out);
```

## `calculus.hvp`

`calculus.hvp(h, f, x, v)`

Hessian-vector product with four directional/coordinate samples per component.

Original: [`HMath.Calculus.hvp`](haskell/HMath-Calculus.md#v:hvp).

```haskell
Double -> ([Double] -> Double) -> [Double] -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_calculus_hvp(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, const hmath_value *v, hmath_value **out);
```

## `calculus.divergence`

`calculus.divergence(h, f, x)`

Divergence of a vector field with equal input and output dimensions.

Original: [`HMath.Calculus.divergence`](haskell/HMath-Calculus.md#v:divergence).

```haskell
Double -> ([Double] -> [Double]) -> [Double] -> Either MathError Double
```

```c
hmath_status hmath_calculus_divergence(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, hmath_value **out);
```

## `calculus.curl`

`calculus.curl(h, f, x)`

Curl of a three-dimensional vector field.

Original: [`HMath.Calculus.curl`](haskell/HMath-Calculus.md#v:curl).

```haskell
Double -> ([Double] -> [Double]) -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_calculus_curl(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, hmath_value **out);
```

## `calculus.laplacian`

`calculus.laplacian(h, f, x)`

Laplacian as the sum of centered second coordinate differences.

Original: [`HMath.Calculus.laplacian`](haskell/HMath-Calculus.md#v:laplacian).

```haskell
Double -> ([Double] -> Double) -> [Double] -> Either MathError Double
```

```c
hmath_status hmath_calculus_laplacian(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, hmath_value **out);
```

## `calculus.integrate_composite`

`calculus.integrate_composite(method, n, f, a, b)`

Composite finite-interval integration with exact panel constraints.

Original: [`HMath.Calculus.integrateComposite`](haskell/HMath-Calculus.md#v:integrateComposite).

```haskell
Quadrature -> Int -> (Double -> Double) -> Double -> Double -> Either MathError Double
```

```c
hmath_status hmath_calculus_integrate_composite(hmath_context *context, const hmath_value *method, const hmath_value *n, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `calculus.romberg`

`calculus.romberg(tol, f, a, b)`

Romberg integration using trapezoidal refinement and Richardson diagonals.

Original: [`HMath.Calculus.romberg`](haskell/HMath-Calculus.md#v:romberg).

```haskell
Tolerance -> (Double -> Double) -> Double -> Double -> Either MathError (Estimate Double)
```

```c
hmath_status hmath_calculus_romberg(hmath_context *context, const hmath_value *tol, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `calculus.gauss_legendre`

`calculus.gauss_legendre(n, f, a, b)`

n-point Gauss-Legendre quadrature; nodes are refined by Newton iteration.

Original: [`HMath.Calculus.gaussLegendre`](haskell/HMath-Calculus.md#v:gaussLegendre).

```haskell
Int -> (Double -> Double) -> Double -> Double -> Either MathError Double
```

```c
hmath_status hmath_calculus_gauss_legendre(hmath_context *context, const hmath_value *n, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `calculus.gauss_hermite`

`calculus.gauss_hermite(value, value2)`

 Weighted Gaussian quadrature on the real line for weight exp(-x^2). Uses the symmetric Jacobi recurrence and a checked implicit QL eigensystem. 

Original: [`HMath.Calculus.gaussHermite`](haskell/HMath-Calculus.md#v:gaussHermite).

```haskell
Int -> (Double -> Double) -> Either MathError Double
```

```c
hmath_status hmath_calculus_gauss_hermite(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `calculus.gauss_laguerre`

`calculus.gauss_laguerre(value, value2)`

Weighted Gaussian quadrature on [0,infinity) for weight exp(-x).

Original: [`HMath.Calculus.gaussLaguerre`](haskell/HMath-Calculus.md#v:gaussLaguerre).

```haskell
Int -> (Double -> Double) -> Either MathError Double
```

```c
hmath_status hmath_calculus_gauss_laguerre(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `calculus.gauss_chebyshev`

`calculus.gauss_chebyshev(n, f)`

Weighted first-kind Chebyshev rule on [-1,1], weight 1/sqrt(1-x^2).

Original: [`HMath.Calculus.gaussChebyshev`](haskell/HMath-Calculus.md#v:gaussChebyshev).

```haskell
Int -> (Double -> Double) -> Either MathError Double
```

```c
hmath_status hmath_calculus_gauss_chebyshev(hmath_context *context, const hmath_value *n, const hmath_value *f, hmath_value **out);
```

## `calculus.gauss_kronrod`

`calculus.gauss_kronrod(f, a, b)`

 Embedded 7-point Gauss / 15-point Kronrod estimate. Nodes and weights are the standard Gauss-Kronrod pair used by QUADPACK dqk15 (Netlib). 

Original: [`HMath.Calculus.gaussKronrod`](haskell/HMath-Calculus.md#v:gaussKronrod).

```haskell
(Double -> Double) -> Double -> Double -> Either MathError (Estimate Double)
```

```c
hmath_status hmath_calculus_gauss_kronrod(hmath_context *context, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `calculus.adaptive_integrate`

`calculus.adaptive_integrate(tol, f, a, b)`

 Adaptive Gauss-Kronrod with global summed error and a strict evaluation budget. The interval with the largest estimated error is bisected first. 

Original: [`HMath.Calculus.adaptiveIntegrate`](haskell/HMath-Calculus.md#v:adaptiveIntegrate).

```haskell
Tolerance -> (Double -> Double) -> Double -> Double -> Either MathError (Estimate Double)
```

```c
hmath_status hmath_calculus_adaptive_integrate(hmath_context *context, const hmath_value *tol, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `calculus.clenshaw_curtis`

`calculus.clenshaw_curtis(n, f, a, b)`

 Clenshaw-Curtis quadrature on n cosine-spaced panels using exact moments of the cosine interpolant. n must be positive and at most 4096. 

Original: [`HMath.Calculus.clenshawCurtis`](haskell/HMath-Calculus.md#v:clenshawCurtis).

```haskell
Int -> (Double -> Double) -> Double -> Double -> Either MathError Double
```

```c
hmath_status hmath_calculus_clenshaw_curtis(hmath_context *context, const hmath_value *n, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `calculus.tanh_sinh`

`calculus.tanh_sinh(tol, f, a, b)`

 Tanh-sinh quadrature with geometric step refinement on a finite interval. Rounded-to-endpoint nodes are omitted, supporting integrable endpoint poles. 

Original: [`HMath.Calculus.tanhSinh`](haskell/HMath-Calculus.md#v:tanhSinh).

```haskell
Tolerance -> (Double -> Double) -> Double -> Double -> Either MathError (Estimate Double)
```

```c
hmath_status hmath_calculus_tanh_sinh(hmath_context *context, const hmath_value *tol, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `calculus.integrate_infinite`

`calculus.integrate_infinite(tol, f, a, b)`

 Integrate on finite, half-infinite or doubly-infinite intervals by an open coordinate transform followed by adaptive Gauss-Kronrod. Reversed bounds change the sign. Divergent integrals have no guaranteed detection criterion. 

Original: [`HMath.Calculus.integrateInfinite`](haskell/HMath-Calculus.md#v:integrateInfinite).

```haskell
Tolerance -> (Double -> Double) -> Double -> Double -> Either MathError (Estimate Double)
```

```c
hmath_status hmath_calculus_integrate_infinite(hmath_context *context, const hmath_value *tol, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `calculus.integrate_oscillatory`

`calculus.integrate_oscillatory(sine, omega, tol, f, a, b)`

 Integrate f(x)*cos(omega*x) or f(x)*sin(omega*x), splitting at least once per half-period to avoid accepting an aliased embedded quadrature estimate. 

Original: [`HMath.Calculus.integrateOscillatory`](haskell/HMath-Calculus.md#v:integrateOscillatory).

```haskell
Bool -> Double -> Tolerance -> (Double -> Double) -> Double -> Double -> Either MathError (Estimate Double)
```

```c
hmath_status hmath_calculus_integrate_oscillatory(hmath_context *context, const hmath_value *sine, const hmath_value *omega, const hmath_value *tol, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `calculus.integrate_nd`

`calculus.integrate_nd(panels, budget, f, bounds)`

 Tensor-product midpoint integration over a box. The product of panel counts is checked against the explicit budget before callback evaluation. 

Original: [`HMath.Calculus.integrateND`](haskell/HMath-Calculus.md#v:integrateND).

```haskell
Int -> Int -> ([Double] -> Double) -> [(Double, Double)] -> Either MathError Double
```

```c
hmath_status hmath_calculus_integrate_nd(hmath_context *context, const hmath_value *panels, const hmath_value *budget, const hmath_value *f, const hmath_value *bounds, hmath_value **out);
```

## `calculus.monte_carlo`

`calculus.monte_carlo(seed, n, f, bounds)`

 Reproducible Monte Carlo box integral with an explicit 64-bit seed. Error is one estimated standard error from Welford's sample variance. 

Original: [`HMath.Calculus.monteCarlo`](haskell/HMath-Calculus.md#v:monteCarlo).

```haskell
Integer -> Int -> ([Double] -> Double) -> [(Double, Double)] -> Either MathError (Estimate Double)
```

```c
hmath_status hmath_calculus_monte_carlo(hmath_context *context, const hmath_value *seed, const hmath_value *n, const hmath_value *f, const hmath_value *bounds, hmath_value **out);
```

## `calculus.quasi_monte_carlo`

`calculus.quasi_monte_carlo(n, f, bounds)`

 Deterministic Halton-box quadrature, up to 16 dimensions. No probabilistic error bound is claimed; estimateError is the difference of the two halves. 

Original: [`HMath.Calculus.quasiMonteCarlo`](haskell/HMath-Calculus.md#v:quasiMonteCarlo).

```haskell
Int -> ([Double] -> Double) -> [(Double, Double)] -> Either MathError (Estimate Double)
```

```c
hmath_status hmath_calculus_quasi_monte_carlo(hmath_context *context, const hmath_value *n, const hmath_value *f, const hmath_value *bounds, hmath_value **out);
```

## `calculus.cumulative_integral`

`calculus.cumulative_integral(value)`

Cumulative trapezoidal integrals at strictly increasing sample coordinates.

Original: [`HMath.Calculus.cumulativeIntegral`](haskell/HMath-Calculus.md#v:cumulativeIntegral).

```haskell
[(Double, Double)] -> Either MathError [Double]
```

```c
hmath_status hmath_calculus_cumulative_integral(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `calculus.path_integral`

`calculus.path_integral(tol, curve, tangent, f, a, b)`

Scalar line integral f(r(t))*|r'(t)| along an explicitly parameterized path.

Original: [`HMath.Calculus.pathIntegral`](haskell/HMath-Calculus.md#v:pathIntegral).

```haskell
Tolerance -> (Double -> [Double]) -> (Double -> [Double]) -> ([Double] -> Double) -> Double -> Double -> Either MathError (Estimate Double)
```

```c
hmath_status hmath_calculus_path_integral(hmath_context *context, const hmath_value *tol, const hmath_value *curve, const hmath_value *tangent, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `calculus.line_integral`

`calculus.line_integral(tol, curve, tangent, field, a, b)`

Oriented vector-field line integral along a parameterized path.

Original: [`HMath.Calculus.lineIntegral`](haskell/HMath-Calculus.md#v:lineIntegral).

```haskell
Tolerance -> (Double -> [Double]) -> (Double -> [Double]) -> ([Double] -> [Double]) -> Double -> Double -> Either MathError (Estimate Double)
```

```c
hmath_status hmath_calculus_line_integral(hmath_context *context, const hmath_value *tol, const hmath_value *curve, const hmath_value *tangent, const hmath_value *field, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `calculus.surface_integral`

`calculus.surface_integral(panels, budget, surface, du, dv, f, bounds)`

Scalar surface integral over a rectangular parameter domain in R3.

Original: [`HMath.Calculus.surfaceIntegral`](haskell/HMath-Calculus.md#v:surfaceIntegral).

```haskell
Int -> Int -> ([Double] -> [Double]) -> ([Double] -> [Double]) -> ([Double] -> [Double]) -> ([Double] -> Double) -> [(Double, Double)] -> Either MathError Double
```

```c
hmath_status hmath_calculus_surface_integral(hmath_context *context, const hmath_value *panels, const hmath_value *budget, const hmath_value *surface, const hmath_value *du, const hmath_value *dv, const hmath_value *f, const hmath_value *bounds, hmath_value **out);
```

## `calculus.volume_integral`

`calculus.volume_integral(panels, budget, f, bounds)`

Volume integral over a three-dimensional rectangular box.

Original: [`HMath.Calculus.volumeIntegral`](haskell/HMath-Calculus.md#v:volumeIntegral).

```haskell
Int -> Int -> ([Double] -> Double) -> [(Double, Double)] -> Either MathError Double
```

```c
hmath_status hmath_calculus_volume_integral(hmath_context *context, const hmath_value *panels, const hmath_value *budget, const hmath_value *f, const hmath_value *bounds, hmath_value **out);
```

## `root.root_options`

`root.root_options(root_max_iterations, root_max_evaluations, root_tolerance, root_step_tolerance)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.RootOptions`](haskell/HMath-Root.md#v:RootOptions).

```haskell
Int -> Int -> Double -> Double -> RootOptions
```

```c
hmath_status hmath_root_root_options(hmath_context *context, const hmath_value *root_max_iterations, const hmath_value *root_max_evaluations, const hmath_value *root_tolerance, const hmath_value *root_step_tolerance, hmath_value **out);
```

## `root.root_max_iterations`

`root.root_max_iterations(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.rootMaxIterations`](haskell/HMath-Root.md#v:rootMaxIterations).

```haskell
RootOptions -> Int
```

```c
hmath_status hmath_root_root_max_iterations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.root_max_evaluations`

`root.root_max_evaluations(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.rootMaxEvaluations`](haskell/HMath-Root.md#v:rootMaxEvaluations).

```haskell
RootOptions -> Int
```

```c
hmath_status hmath_root_root_max_evaluations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.root_tolerance`

`root.root_tolerance(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.rootTolerance`](haskell/HMath-Root.md#v:rootTolerance).

```haskell
RootOptions -> Double
```

```c
hmath_status hmath_root_root_tolerance(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.root_step_tolerance`

`root.root_step_tolerance(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.rootStepTolerance`](haskell/HMath-Root.md#v:rootStepTolerance).

```haskell
RootOptions -> Double
```

```c
hmath_status hmath_root_root_step_tolerance(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.default_root_options`

`root.default_root_options()`

 Default root-solving limits: 200 iterations, 4000 evaluations, residual tolerance 1e-10 and step tolerance 1e-12. Solvers validate options and report their own convergence diagnostics. 

Original: [`HMath.Root.defaultRootOptions`](haskell/HMath-Root.md#v:defaultRootOptions).

```haskell
RootOptions
```

```c
hmath_status hmath_root_default_root_options(hmath_context *context, hmath_value **out);
```

## `root.root_result`

`root.root_result(root_value, root_residual, root_error_bound, root_iterations, root_evaluations)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.RootResult`](haskell/HMath-Root.md#v:RootResult).

```haskell
Double -> Double -> Maybe Double -> Int -> Int -> RootResult
```

```c
hmath_status hmath_root_root_result(hmath_context *context, const hmath_value *root_value, const hmath_value *root_residual, const hmath_value *root_error_bound, const hmath_value *root_iterations, const hmath_value *root_evaluations, hmath_value **out);
```

## `root.root_value`

`root.root_value(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.rootValue`](haskell/HMath-Root.md#v:rootValue).

```haskell
RootResult -> Double
```

```c
hmath_status hmath_root_root_value(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.root_residual`

`root.root_residual(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.rootResidual`](haskell/HMath-Root.md#v:rootResidual).

```haskell
RootResult -> Double
```

```c
hmath_status hmath_root_root_residual(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.root_error_bound`

`root.root_error_bound(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.rootErrorBound`](haskell/HMath-Root.md#v:rootErrorBound).

```haskell
RootResult -> Maybe Double
```

```c
hmath_status hmath_root_root_error_bound(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.root_iterations`

`root.root_iterations(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.rootIterations`](haskell/HMath-Root.md#v:rootIterations).

```haskell
RootResult -> Int
```

```c
hmath_status hmath_root_root_iterations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.root_evaluations`

`root.root_evaluations(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.rootEvaluations`](haskell/HMath-Root.md#v:rootEvaluations).

```haskell
RootResult -> Int
```

```c
hmath_status hmath_root_root_evaluations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.bisection`

`root.bisection()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.Bisection`](haskell/HMath-Root.md#v:Bisection).

```haskell
BracketMethod
```

```c
hmath_status hmath_root_bisection(hmath_context *context, hmath_value **out);
```

## `root.regula_falsi`

`root.regula_falsi()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.RegulaFalsi`](haskell/HMath-Root.md#v:RegulaFalsi).

```haskell
BracketMethod
```

```c
hmath_status hmath_root_regula_falsi(hmath_context *context, hmath_value **out);
```

## `root.illinois`

`root.illinois()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.Illinois`](haskell/HMath-Root.md#v:Illinois).

```haskell
BracketMethod
```

```c
hmath_status hmath_root_illinois(hmath_context *context, hmath_value **out);
```

## `root.brent`

`root.brent()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.Brent`](haskell/HMath-Root.md#v:Brent).

```haskell
BracketMethod
```

```c
hmath_status hmath_root_brent(hmath_context *context, hmath_value **out);
```

## `root.ridder`

`root.ridder()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.Ridder`](haskell/HMath-Root.md#v:Ridder).

```haskell
BracketMethod
```

```c
hmath_status hmath_root_ridder(hmath_context *context, hmath_value **out);
```

## `root.newton`

`root.newton()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.Newton`](haskell/HMath-Root.md#v:Newton).

```haskell
DerivativeMethod
```

```c
hmath_status hmath_root_newton(hmath_context *context, hmath_value **out);
```

## `root.halley`

`root.halley()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.Halley`](haskell/HMath-Root.md#v:Halley).

```haskell
DerivativeMethod
```

```c
hmath_status hmath_root_halley(hmath_context *context, hmath_value **out);
```

## `root.householder3`

`root.householder3()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.Householder3`](haskell/HMath-Root.md#v:Householder3).

```haskell
DerivativeMethod
```

```c
hmath_status hmath_root_householder3(hmath_context *context, hmath_value **out);
```

## `root.picard`

`root.picard()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.Picard`](haskell/HMath-Root.md#v:Picard).

```haskell
FixedPointMethod
```

```c
hmath_status hmath_root_picard(hmath_context *context, hmath_value **out);
```

## `root.aitken`

`root.aitken()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.Aitken`](haskell/HMath-Root.md#v:Aitken).

```haskell
FixedPointMethod
```

```c
hmath_status hmath_root_aitken(hmath_context *context, hmath_value **out);
```

## `root.steffensen_fixed`

`root.steffensen_fixed()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.SteffensenFixed`](haskell/HMath-Root.md#v:SteffensenFixed).

```haskell
FixedPointMethod
```

```c
hmath_status hmath_root_steffensen_fixed(hmath_context *context, hmath_value **out);
```

## `root.multivariate_newton`

`root.multivariate_newton()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.MultivariateNewton`](haskell/HMath-Root.md#v:MultivariateNewton).

```haskell
SystemMethod
```

```c
hmath_status hmath_root_multivariate_newton(hmath_context *context, hmath_value **out);
```

## `root.newton_trust_region`

`root.newton_trust_region(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.NewtonTrustRegion`](haskell/HMath-Root.md#v:NewtonTrustRegion).

```haskell
Double -> SystemMethod
```

```c
hmath_status hmath_root_newton_trust_region(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.broyden`

`root.broyden()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.Broyden`](haskell/HMath-Root.md#v:Broyden).

```haskell
SystemMethod
```

```c
hmath_status hmath_root_broyden(hmath_context *context, hmath_value **out);
```

## `root.system_root_result`

`root.system_root_result(system_root, system_residual, system_iterations, system_evaluations)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.SystemRootResult`](haskell/HMath-Root.md#v:SystemRootResult).

```haskell
[Double] -> Double -> Int -> Int -> SystemRootResult
```

```c
hmath_status hmath_root_system_root_result(hmath_context *context, const hmath_value *system_root, const hmath_value *system_residual, const hmath_value *system_iterations, const hmath_value *system_evaluations, hmath_value **out);
```

## `root.system_root`

`root.system_root(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.systemRoot`](haskell/HMath-Root.md#v:systemRoot).

```haskell
SystemRootResult -> [Double]
```

```c
hmath_status hmath_root_system_root(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.system_residual`

`root.system_residual(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.systemResidual`](haskell/HMath-Root.md#v:systemResidual).

```haskell
SystemRootResult -> Double
```

```c
hmath_status hmath_root_system_residual(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.system_iterations`

`root.system_iterations(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.systemIterations`](haskell/HMath-Root.md#v:systemIterations).

```haskell
SystemRootResult -> Int
```

```c
hmath_status hmath_root_system_iterations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.system_evaluations`

`root.system_evaluations(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Root.systemEvaluations`](haskell/HMath-Root.md#v:systemEvaluations).

```haskell
SystemRootResult -> Int
```

```c
hmath_status hmath_root_system_evaluations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `root.bracket`

`root.bracket(f, a, b)`

Validate finite a<b and endpoint roots or opposite signs; construction never assumes a discontinuity is a root.

Original: [`HMath.Root.bracket`](haskell/HMath-Root.md#v:bracket).

```haskell
(Double -> Double) -> Double -> Double -> Either MathError Bracket
```

```c
hmath_status hmath_root_bracket(hmath_context *context, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `root.solve_bracket`

`root.solve_bracket(value, value2, value3, value4)`

 Brackets are re-evaluated with the supplied function, preventing stale or mismatched endpoint caches from certifying a different function's root. 

Original: [`HMath.Root.solveBracket`](haskell/HMath-Root.md#v:solveBracket).

```haskell
BracketMethod -> RootOptions -> (Double -> Double) -> Bracket -> Either MathError RootResult
```

```c
hmath_status hmath_root_solve_bracket(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out);
```

## `root.bracket_scan`

`root.bracket_scan(o, f, a, b, cells)`

Evaluate a uniform finite grid under the evaluation budget and return every endpoint/sign-change bracket.

Original: [`HMath.Root.bracketScan`](haskell/HMath-Root.md#v:bracketScan).

```haskell
RootOptions -> (Double -> Double) -> Double -> Double -> Int -> Either MathError [Bracket]
```

```c
hmath_status hmath_root_bracket_scan(hmath_context *context, const hmath_value *o, const hmath_value *f, const hmath_value *a, const hmath_value *b, const hmath_value *cells, hmath_value **out);
```

## `root.isolate_intervals`

`root.isolate_intervals(o, f, a, b, cells)`

Refine sign-change scan brackets and deduplicate endpoint roots. Even roots require polynomial isolation.

Original: [`HMath.Root.isolateIntervals`](haskell/HMath-Root.md#v:isolateIntervals).

```haskell
RootOptions -> (Double -> Double) -> Double -> Double -> Int -> Either MathError [RootResult]
```

```c
hmath_status hmath_root_isolate_intervals(hmath_context *context, const hmath_value *o, const hmath_value *f, const hmath_value *a, const hmath_value *b, const hmath_value *cells, hmath_value **out);
```

## `root.solve_derivative`

`root.solve_derivative(method, o, f, derivatives, x0)`

 Derivatives [f', f'', f'''] are required through order 1, 2, or 3. Householder3 is the order-four rational Householder update. 

Original: [`HMath.Root.solveDerivative`](haskell/HMath-Root.md#v:solveDerivative).

```haskell
DerivativeMethod -> RootOptions -> (Double -> Double) -> [Double -> Double] -> Double -> Either MathError RootResult
```

```c
hmath_status hmath_root_solve_derivative(hmath_context *context, const hmath_value *method, const hmath_value *o, const hmath_value *f, const hmath_value *derivatives, const hmath_value *x0, hmath_value **out);
```

## `root.secant`

`root.secant(o, f, a, b)`

Unbracketed two-point secant iteration; zero slopes, stagnation, and exhausted budgets fail explicitly.

Original: [`HMath.Root.secant`](haskell/HMath-Root.md#v:secant).

```haskell
RootOptions -> (Double -> Double) -> Double -> Double -> Either MathError RootResult
```

```c
hmath_status hmath_root_secant(hmath_context *context, const hmath_value *o, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `root.steffensen`

`root.steffensen(o, f, x0)`

Derivative-free Steffensen root update using f(x+f(x)); termination checks the original residual.

Original: [`HMath.Root.steffensen`](haskell/HMath-Root.md#v:steffensen).

```haskell
RootOptions -> (Double -> Double) -> Double -> Either MathError RootResult
```

```c
hmath_status hmath_root_steffensen(hmath_context *context, const hmath_value *o, const hmath_value *f, const hmath_value *x0, hmath_value **out);
```

## `root.fixed_point`

`root.fixed_point(method, o, g, x0)`

Picard iteration, non-restarted Aitken sequence acceleration, or restarted Steffensen acceleration.

Original: [`HMath.Root.fixedPoint`](haskell/HMath-Root.md#v:fixedPoint).

```haskell
FixedPointMethod -> RootOptions -> (Double -> Double) -> Double -> Either MathError RootResult
```

```c
hmath_status hmath_root_fixed_point(hmath_context *context, const hmath_value *method, const hmath_value *o, const hmath_value *g, const hmath_value *x0, hmath_value **out);
```

## `root.anderson`

`root.anderson(depth, regularization, o, g, x0)`

 Anderson mixing with depth m and Tikhonov regularization. Residuals are g(x)-x. Solving the constrained residual Gram system is a bounded reference implementation; it does not pretend to use a low-storage QR update. 

Original: [`HMath.Root.anderson`](haskell/HMath-Root.md#v:anderson).

```haskell
Int -> Double -> RootOptions -> ([Double] -> [Double]) -> [Double] -> Either MathError SystemRootResult
```

```c
hmath_status hmath_root_anderson(hmath_context *context, const hmath_value *depth, const hmath_value *regularization, const hmath_value *o, const hmath_value *g, const hmath_value *x0, hmath_value **out);
```

## `root.solve_system`

`root.solve_system(method, o, f, jac, x0)`

Solve a square analytic-Jacobian system using Newton, trust-radius Newton, or rank-one Broyden updates.

Original: [`HMath.Root.solveSystem`](haskell/HMath-Root.md#v:solveSystem).

```haskell
SystemMethod -> RootOptions -> ([Double] -> [Double]) -> ([Double] -> [[Double]]) -> [Double] -> Either MathError SystemRootResult
```

```c
hmath_status hmath_root_solve_system(hmath_context *context, const hmath_value *method, const hmath_value *o, const hmath_value *f, const hmath_value *jac, const hmath_value *x0, hmath_value **out);
```

## `root.polynomial_roots`

`root.polynomial_roots(o, p)`

Reuse the checked Aberth-Ehrlich simultaneous complex solver for an ascending-coefficient polynomial.

Original: [`HMath.Root.polynomialRoots`](haskell/HMath-Root.md#v:polynomialRoots).

```haskell
RootOptions -> P.Polynomial (Complex Double) -> Either MathError [Complex Double]
```

```c
hmath_status hmath_root_polynomial_roots(hmath_context *context, const hmath_value *o, const hmath_value *p, hmath_value **out);
```

## `root.real_polynomial_roots`

`root.real_polynomial_roots(budget, tolerance, p)`

Use exact square-free factorization and Sturm isolation; return rational intervals and integer multiplicities.

Original: [`HMath.Root.realPolynomialRoots`](haskell/HMath-Root.md#v:realPolynomialRoots).

```haskell
Int -> Rational -> P.Polynomial Rational -> Either MathError [(Rational, Rational, Int)]
```

```c
hmath_status hmath_root_real_polynomial_roots(hmath_context *context, const hmath_value *budget, const hmath_value *tolerance, const hmath_value *p, hmath_value **out);
```

## `ode.euler`

`ode.euler()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.Euler`](haskell/HMath-ODE.md#v:Euler).

```haskell
Method
```

```c
hmath_status hmath_ode_euler(hmath_context *context, hmath_value **out);
```

## `ode.heun`

`ode.heun()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.Heun`](haskell/HMath-ODE.md#v:Heun).

```haskell
Method
```

```c
hmath_status hmath_ode_heun(hmath_context *context, hmath_value **out);
```

## `ode.midpoint`

`ode.midpoint()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.Midpoint`](haskell/HMath-ODE.md#v:Midpoint).

```haskell
Method
```

```c
hmath_status hmath_ode_midpoint(hmath_context *context, hmath_value **out);
```

## `ode.rk2`

`ode.rk2()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.RK2`](haskell/HMath-ODE.md#v:RK2).

```haskell
Method
```

```c
hmath_status hmath_ode_rk2(hmath_context *context, hmath_value **out);
```

## `ode.rk4`

`ode.rk4()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.RK4`](haskell/HMath-ODE.md#v:RK4).

```haskell
Method
```

```c
hmath_status hmath_ode_rk4(hmath_context *context, hmath_value **out);
```

## `ode.rk23`

`ode.rk23()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.RK23`](haskell/HMath-ODE.md#v:RK23).

```haskell
Method
```

```c
hmath_status hmath_ode_rk23(hmath_context *context, hmath_value **out);
```

## `ode.rk45`

`ode.rk45()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.RK45`](haskell/HMath-ODE.md#v:RK45).

```haskell
Method
```

```c
hmath_status hmath_ode_rk45(hmath_context *context, hmath_value **out);
```

## `ode.dormand_prince`

`ode.dormand_prince()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.DormandPrince`](haskell/HMath-ODE.md#v:DormandPrince).

```haskell
Method
```

```c
hmath_status hmath_ode_dormand_prince(hmath_context *context, hmath_value **out);
```

## `ode.dop853`

`ode.dop853()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.DOP853`](haskell/HMath-ODE.md#v:DOP853).

```haskell
Method
```

```c
hmath_status hmath_ode_dop853(hmath_context *context, hmath_value **out);
```

## `ode.adams_bashforth`

`ode.adams_bashforth()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.AdamsBashforth`](haskell/HMath-ODE.md#v:AdamsBashforth).

```haskell
Method
```

```c
hmath_status hmath_ode_adams_bashforth(hmath_context *context, hmath_value **out);
```

## `ode.adams_moulton`

`ode.adams_moulton()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.AdamsMoulton`](haskell/HMath-ODE.md#v:AdamsMoulton).

```haskell
Method
```

```c
hmath_status hmath_ode_adams_moulton(hmath_context *context, hmath_value **out);
```

## `ode.predictor_corrector`

`ode.predictor_corrector()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.PredictorCorrector`](haskell/HMath-ODE.md#v:PredictorCorrector).

```haskell
Method
```

```c
hmath_status hmath_ode_predictor_corrector(hmath_context *context, hmath_value **out);
```

## `ode.backward_euler`

`ode.backward_euler()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.BackwardEuler`](haskell/HMath-ODE.md#v:BackwardEuler).

```haskell
Method
```

```c
hmath_status hmath_ode_backward_euler(hmath_context *context, hmath_value **out);
```

## `ode.bdf`

`ode.bdf()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.BDF`](haskell/HMath-ODE.md#v:BDF).

```haskell
Method
```

```c
hmath_status hmath_ode_bdf(hmath_context *context, hmath_value **out);
```

## `ode.radau`

`ode.radau()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.Radau`](haskell/HMath-ODE.md#v:Radau).

```haskell
Method
```

```c
hmath_status hmath_ode_radau(hmath_context *context, hmath_value **out);
```

## `ode.rosenbrock`

`ode.rosenbrock()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.Rosenbrock`](haskell/HMath-ODE.md#v:Rosenbrock).

```haskell
Method
```

```c
hmath_status hmath_ode_rosenbrock(hmath_context *context, hmath_value **out);
```

## `ode.ode_options`

`ode.ode_options(ode_absolute_tolerance, ode_relative_tolerance, initial_step, minimum_step, maximum_step, maximum_steps, newton_iterations)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.ODEOptions`](haskell/HMath-ODE.md#v:ODEOptions).

```haskell
Double -> Double -> Double -> Double -> Double -> Int -> Int -> ODEOptions
```

```c
hmath_status hmath_ode_ode_options(hmath_context *context, const hmath_value *ode_absolute_tolerance, const hmath_value *ode_relative_tolerance, const hmath_value *initial_step, const hmath_value *minimum_step, const hmath_value *maximum_step, const hmath_value *maximum_steps, const hmath_value *newton_iterations, hmath_value **out);
```

## `ode.ode_absolute_tolerance`

`ode.ode_absolute_tolerance(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.odeAbsoluteTolerance`](haskell/HMath-ODE.md#v:odeAbsoluteTolerance).

```haskell
ODEOptions -> Double
```

```c
hmath_status hmath_ode_ode_absolute_tolerance(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `ode.ode_relative_tolerance`

`ode.ode_relative_tolerance(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.odeRelativeTolerance`](haskell/HMath-ODE.md#v:odeRelativeTolerance).

```haskell
ODEOptions -> Double
```

```c
hmath_status hmath_ode_ode_relative_tolerance(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `ode.initial_step`

`ode.initial_step(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.initialStep`](haskell/HMath-ODE.md#v:initialStep).

```haskell
ODEOptions -> Double
```

```c
hmath_status hmath_ode_initial_step(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `ode.minimum_step`

`ode.minimum_step(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.minimumStep`](haskell/HMath-ODE.md#v:minimumStep).

```haskell
ODEOptions -> Double
```

```c
hmath_status hmath_ode_minimum_step(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `ode.maximum_step`

`ode.maximum_step(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.maximumStep`](haskell/HMath-ODE.md#v:maximumStep).

```haskell
ODEOptions -> Double
```

```c
hmath_status hmath_ode_maximum_step(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `ode.maximum_steps`

`ode.maximum_steps(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.maximumSteps`](haskell/HMath-ODE.md#v:maximumSteps).

```haskell
ODEOptions -> Int
```

```c
hmath_status hmath_ode_maximum_steps(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `ode.newton_iterations`

`ode.newton_iterations(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.newtonIterations`](haskell/HMath-ODE.md#v:newtonIterations).

```haskell
ODEOptions -> Int
```

```c
hmath_status hmath_ode_newton_iterations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `ode.default_ode_options`

`ode.default_ode_options()`

Conservative default adaptive settings for Double callbacks.

Original: [`HMath.ODE.defaultODEOptions`](haskell/HMath-ODE.md#v:defaultODEOptions).

```haskell
ODEOptions
```

```c
hmath_status hmath_ode_default_ode_options(hmath_context *context, hmath_value **out);
```

## `ode.trajectory`

`ode.trajectory(trajectory_times, trajectory_states, trajectory_derivatives)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.Trajectory`](haskell/HMath-ODE.md#v:Trajectory).

```haskell
[Double] -> [[Double]] -> [[Double]] -> Trajectory
```

```c
hmath_status hmath_ode_trajectory(hmath_context *context, const hmath_value *trajectory_times, const hmath_value *trajectory_states, const hmath_value *trajectory_derivatives, hmath_value **out);
```

## `ode.trajectory_times`

`ode.trajectory_times(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.trajectoryTimes`](haskell/HMath-ODE.md#v:trajectoryTimes).

```haskell
Trajectory -> [Double]
```

```c
hmath_status hmath_ode_trajectory_times(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `ode.trajectory_states`

`ode.trajectory_states(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.trajectoryStates`](haskell/HMath-ODE.md#v:trajectoryStates).

```haskell
Trajectory -> [[Double]]
```

```c
hmath_status hmath_ode_trajectory_states(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `ode.trajectory_derivatives`

`ode.trajectory_derivatives(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.trajectoryDerivatives`](haskell/HMath-ODE.md#v:trajectoryDerivatives).

```haskell
Trajectory -> [[Double]]
```

```c
hmath_status hmath_ode_trajectory_derivatives(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `ode.solve_ivp`

`ode.solve_ivp(method, options, panels, f, start, end, initial)`

 Integrate on n equal panels. Multistep methods use genuine derivative history; implicit methods use checked finite-difference Newton iterations. 

Original: [`HMath.ODE.solveIVP`](haskell/HMath-ODE.md#v:solveIVP).

```haskell
Method -> ODEOptions -> Int -> ODE -> Double -> Double -> [Double] -> Either MathError Trajectory
```

```c
hmath_status hmath_ode_solve_ivp(hmath_context *context, const hmath_value *method, const hmath_value *options, const hmath_value *panels, const hmath_value *f, const hmath_value *start, const hmath_value *end, const hmath_value *initial, hmath_value **out);
```

## `ode.solve_adaptive`

`ode.solve_adaptive(method, options, f, start, end, initial)`

 Adaptive explicit RK integration. Euler/Heun/Midpoint/RK4 use step-doubling error estimates. RK23/RK45/DormandPrince/DOP853 use their embedded estimates. Multistep and implicit methods require 'solveIVP' to preserve their grid/history. 

Original: [`HMath.ODE.solveAdaptive`](haskell/HMath-ODE.md#v:solveAdaptive).

```haskell
Method -> ODEOptions -> ODE -> Double -> Double -> [Double] -> Either MathError Trajectory
```

```c
hmath_status hmath_ode_solve_adaptive(hmath_context *context, const hmath_value *method, const hmath_value *options, const hmath_value *f, const hmath_value *start, const hmath_value *end, const hmath_value *initial, hmath_value **out);
```

## `ode.interpolate_trajectory`

`ode.interpolate_trajectory(trajectory, t)`

 Cubic Hermite interpolation inside the trajectory's closed time range. Extrapolation, malformed public trajectories and repeated sample times fail. 

Original: [`HMath.ODE.interpolateTrajectory`](haskell/HMath-ODE.md#v:interpolateTrajectory).

```haskell
Trajectory -> Double -> Either MathError [Double]
```

```c
hmath_status hmath_ode_interpolate_trajectory(hmath_context *context, const hmath_value *trajectory, const hmath_value *t, hmath_value **out);
```

## `ode.any_direction`

`ode.any_direction()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.AnyDirection`](haskell/HMath-ODE.md#v:AnyDirection).

```haskell
EventDirection
```

```c
hmath_status hmath_ode_any_direction(hmath_context *context, hmath_value **out);
```

## `ode.rising`

`ode.rising()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.Rising`](haskell/HMath-ODE.md#v:Rising).

```haskell
EventDirection
```

```c
hmath_status hmath_ode_rising(hmath_context *context, hmath_value **out);
```

## `ode.falling`

`ode.falling()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.Falling`](haskell/HMath-ODE.md#v:Falling).

```haskell
EventDirection
```

```c
hmath_status hmath_ode_falling(hmath_context *context, hmath_value **out);
```

## `ode.event`

`ode.event(event_time, event_state)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.Event`](haskell/HMath-ODE.md#v:Event).

```haskell
Double -> [Double] -> Event
```

```c
hmath_status hmath_ode_event(hmath_context *context, const hmath_value *event_time, const hmath_value *event_state, hmath_value **out);
```

## `ode.event_time`

`ode.event_time(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.eventTime`](haskell/HMath-ODE.md#v:eventTime).

```haskell
Event -> Double
```

```c
hmath_status hmath_ode_event_time(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `ode.event_state`

`ode.event_state(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.eventState`](haskell/HMath-ODE.md#v:eventState).

```haskell
Event -> [Double]
```

```c
hmath_status hmath_ode_event_state(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `ode.locate_events`

`ode.locate_events(direction, tolerance, function, trajectory)`

 Locate bracketed sign-changing events by dense-output bisection. Tangential roots and multiple roots inside one sample interval are not guaranteed. 

Original: [`HMath.ODE.locateEvents`](haskell/HMath-ODE.md#v:locateEvents).

```haskell
EventDirection -> Double -> (Double -> [Double] -> Double) -> Trajectory -> Either MathError [Event]
```

```c
hmath_status hmath_ode_locate_events(hmath_context *context, const hmath_value *direction, const hmath_value *tolerance, const hmath_value *function, const hmath_value *trajectory, hmath_value **out);
```

## `ode.solve_boundary`

`ode.solve_boundary(method, options, panels, f, boundary, start, end, guess)`

 Shooting boundary-value solver: all initial-state components are unknown. The boundary callback takes initial/final states and returns n residuals. Returns the trajectory matching a locally converged shooting root; convergence is local and depends on the supplied initial guess. 

Original: [`HMath.ODE.solveBoundary`](haskell/HMath-ODE.md#v:solveBoundary).

```haskell
Method -> ODEOptions -> Int -> ODE -> ([Double] -> [Double] -> [Double]) -> Double -> Double -> [Double] -> Either MathError Trajectory
```

```c
hmath_status hmath_ode_solve_boundary(hmath_context *context, const hmath_value *method, const hmath_value *options, const hmath_value *panels, const hmath_value *f, const hmath_value *boundary, const hmath_value *start, const hmath_value *end, const hmath_value *guess, hmath_value **out);
```

## `ode.solve_dae`

`ode.solve_dae(options, panels, residual, start, end, initial, initial_derivative)`

 Index-one implicit DAE driver F(t,y,y')=0 with backward differences. Initial y and y' must be consistent to the configured tolerance. Each subsequent state is obtained by a full residual Newton solve. 

Original: [`HMath.ODE.solveDAE`](haskell/HMath-ODE.md#v:solveDAE).

```haskell
ODEOptions -> Int -> (Double -> [Double] -> [Double] -> [Double]) -> Double -> Double -> [Double] -> [Double] -> Either MathError Trajectory
```

```c
hmath_status hmath_ode_solve_dae(hmath_context *context, const hmath_value *options, const hmath_value *panels, const hmath_value *residual, const hmath_value *start, const hmath_value *end, const hmath_value *initial, const hmath_value *initial_derivative, hmath_value **out);
```

## `ode.symplectic_euler`

`ode.symplectic_euler()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.SymplecticEuler`](haskell/HMath-ODE.md#v:SymplecticEuler).

```haskell
HamiltonianMethod
```

```c
hmath_status hmath_ode_symplectic_euler(hmath_context *context, hmath_value **out);
```

## `ode.verlet`

`ode.verlet()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.Verlet`](haskell/HMath-ODE.md#v:Verlet).

```haskell
HamiltonianMethod
```

```c
hmath_status hmath_ode_verlet(hmath_context *context, hmath_value **out);
```

## `ode.leapfrog`

`ode.leapfrog()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.ODE.Leapfrog`](haskell/HMath-ODE.md#v:Leapfrog).

```haskell
HamiltonianMethod
```

```c
hmath_status hmath_ode_leapfrog(hmath_context *context, hmath_value **out);
```

## `ode.solve_hamiltonian`

`ode.solve_hamiltonian(method, panels, velocity, force, start, end, q0, p0)`

 Fixed-step symplectic integration; output states concatenate q then p. Verlet is kick-drift-kick; Leapfrog is drift-kick-drift with integer-time output momenta. These equivalent second-order splittings have distinct order. 

Original: [`HMath.ODE.solveHamiltonian`](haskell/HMath-ODE.md#v:solveHamiltonian).

```haskell
HamiltonianMethod -> Int -> ([Double] -> [Double]) -> ([Double] -> [Double]) -> Double -> Double -> [Double] -> [Double] -> Either MathError Trajectory
```

```c
hmath_status hmath_ode_solve_hamiltonian(hmath_context *context, const hmath_value *method, const hmath_value *panels, const hmath_value *velocity, const hmath_value *force, const hmath_value *start, const hmath_value *end, const hmath_value *q0, const hmath_value *p0, hmath_value **out);
```

## `ode.solve_nystrom`

`ode.solve_nystrom(panels, acceleration, start, end, q0, v0)`

 Fourth-order explicit Runge-Kutta-Nystrom method for q''=a(t,q), with acceleration independent of velocity. State output concatenates q and q'. 

Original: [`HMath.ODE.solveNystrom`](haskell/HMath-ODE.md#v:solveNystrom).

```haskell
Int -> (Double -> [Double] -> [Double]) -> Double -> Double -> [Double] -> [Double] -> Either MathError Trajectory
```

```c
hmath_status hmath_ode_solve_nystrom(hmath_context *context, const hmath_value *panels, const hmath_value *acceleration, const hmath_value *start, const hmath_value *end, const hmath_value *q0, const hmath_value *v0, hmath_value **out);
```

## `ode.sensitivities`

`ode.sensitivities(method, options, panels, h, family, parameters, start, end, initial)`

 Terminal-state parameter sensitivities by centered perturbation of the complete IVP solve. Parameters use the same explicit finite-difference step. 

Original: [`HMath.ODE.sensitivities`](haskell/HMath-ODE.md#v:sensitivities).

```haskell
Method -> ODEOptions -> Int -> Double -> ([Double] -> ODE) -> [Double] -> Double -> Double -> [Double] -> Either MathError (Matrix Double)
```

```c
hmath_status hmath_ode_sensitivities(hmath_context *context, const hmath_value *method, const hmath_value *options, const hmath_value *panels, const hmath_value *h, const hmath_value *family, const hmath_value *parameters, const hmath_value *start, const hmath_value *end, const hmath_value *initial, hmath_value **out);
```

## `ode.equilibrium`

`ode.equilibrium(options, field, guess)`

Find an autonomous equilibrium by a locally convergent Newton solve.

Original: [`HMath.ODE.equilibrium`](haskell/HMath-ODE.md#v:equilibrium).

```haskell
ODEOptions -> ([Double] -> [Double]) -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_ode_equilibrium(hmath_context *context, const hmath_value *options, const hmath_value *field, const hmath_value *guess, hmath_value **out);
```

## `ode.phase_trajectories`

`ode.phase_trajectories(value, value2, value3, value4, value5, value6, value7)`

Compute autonomous phase-space trajectories for independently supplied starts.

Original: [`HMath.ODE.phaseTrajectories`](haskell/HMath-ODE.md#v:phaseTrajectories).

```haskell
Method -> ODEOptions -> Int -> ([Double] -> [Double]) -> Double -> Double -> [[Double]] -> Either MathError [Trajectory]
```

```c
hmath_status hmath_ode_phase_trajectories(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, const hmath_value *value6, const hmath_value *value7, hmath_value **out);
```

## `ode.lyapunov_exponents`

`ode.lyapunov_exponents(options, panels, difference_step, f, start, end, initial)`

 Full Lyapunov spectrum by the Benettin tangent-space method: integrate variational equations with RK4, then modified Gram-Schmidt at each sample. Finite-difference Jacobians are used; results are finite-time estimates. 

Original: [`HMath.ODE.lyapunovExponents`](haskell/HMath-ODE.md#v:lyapunovExponents).

```haskell
ODEOptions -> Int -> Double -> ODE -> Double -> Double -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_ode_lyapunov_exponents(hmath_context *context, const hmath_value *options, const hmath_value *panels, const hmath_value *difference_step, const hmath_value *f, const hmath_value *start, const hmath_value *end, const hmath_value *initial, hmath_value **out);
```

## `pde.dirichlet`

`pde.dirichlet(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.PDE.Dirichlet`](haskell/HMath-PDE.md#v:Dirichlet).

```haskell
Double -> Boundary
```

```c
hmath_status hmath_pde_dirichlet(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `pde.neumann`

`pde.neumann(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.PDE.Neumann`](haskell/HMath-PDE.md#v:Neumann).

```haskell
Double -> Boundary
```

```c
hmath_status hmath_pde_neumann(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `pde.robin`

`pde.robin(value, value2, value3)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.PDE.Robin`](haskell/HMath-PDE.md#v:Robin).

```haskell
Double -> Double -> Double -> Boundary
```

```c
hmath_status hmath_pde_robin(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out);
```

## `pde.periodic`

`pde.periodic()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.PDE.Periodic`](haskell/HMath-PDE.md#v:Periodic).

```haskell
Boundary
```

```c
hmath_status hmath_pde_periodic(hmath_context *context, hmath_value **out);
```

## `pde.finite_difference`

`pde.finite_difference()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.PDE.FiniteDifference`](haskell/HMath-PDE.md#v:FiniteDifference).

```haskell
Discretization
```

```c
hmath_status hmath_pde_finite_difference(hmath_context *context, hmath_value **out);
```

## `pde.finite_volume`

`pde.finite_volume()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.PDE.FiniteVolume`](haskell/HMath-PDE.md#v:FiniteVolume).

```haskell
Discretization
```

```c
hmath_status hmath_pde_finite_volume(hmath_context *context, hmath_value **out);
```

## `pde.finite_element`

`pde.finite_element()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.PDE.FiniteElement`](haskell/HMath-PDE.md#v:FiniteElement).

```haskell
Discretization
```

```c
hmath_status hmath_pde_finite_element(hmath_context *context, hmath_value **out);
```

## `pde.pde_result`

`pde.pde_result(pde_values, pde_residual, pde_error_estimate)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.PDE.PDEResult`](haskell/HMath-PDE.md#v:PDEResult).

```haskell
[Double] -> Double -> Double -> PDEResult
```

```c
hmath_status hmath_pde_pde_result(hmath_context *context, const hmath_value *pde_values, const hmath_value *pde_residual, const hmath_value *pde_error_estimate, hmath_value **out);
```

## `pde.pde_values`

`pde.pde_values(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.PDE.pdeValues`](haskell/HMath-PDE.md#v:pdeValues).

```haskell
PDEResult -> [Double]
```

```c
hmath_status hmath_pde_pde_values(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `pde.pde_residual`

`pde.pde_residual(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.PDE.pdeResidual`](haskell/HMath-PDE.md#v:pdeResidual).

```haskell
PDEResult -> Double
```

```c
hmath_status hmath_pde_pde_residual(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `pde.pde_error_estimate`

`pde.pde_error_estimate(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.PDE.pdeErrorEstimate`](haskell/HMath-PDE.md#v:pdeErrorEstimate).

```haskell
PDEResult -> Double
```

```c
hmath_status hmath_pde_pde_error_estimate(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `pde.grid`

`pde.grid(dims, bounds, periodic)`

Construct a grid with >=3 nodes per axis; reject overflowing counts and rounded-away duplicate coordinates.

Original: [`HMath.PDE.grid`](haskell/HMath-PDE.md#v:grid).

```haskell
[Int] -> [(Double, Double)] -> [Bool] -> Either MathError Grid
```

```c
hmath_status hmath_pde_grid(hmath_context *context, const hmath_value *dims, const hmath_value *bounds, const hmath_value *periodic, hmath_value **out);
```

## `pde.grid_shape`

`pde.grid_shape(value)`

Number of nodes along each axis, preserving last-axis-fastest storage order.

Original: [`HMath.PDE.gridShape`](haskell/HMath-PDE.md#v:gridShape).

```haskell
Grid -> [Int]
```

```c
hmath_status hmath_pde_grid_shape(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `pde.grid_spacing`

`pde.grid_spacing(value)`

Positive uniform distance between adjacent nodes on each axis.

Original: [`HMath.PDE.gridSpacing`](haskell/HMath-PDE.md#v:gridSpacing).

```haskell
Grid -> [Double]
```

```c
hmath_status hmath_pde_grid_spacing(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `pde.flatten_index`

`pde.flatten_index(value, value2)`

Checked conversion of zero-based multidimensional node coordinates to a row-major flat index.

Original: [`HMath.PDE.flattenIndex`](haskell/HMath-PDE.md#v:flattenIndex).

```haskell
Grid -> [Int] -> Either MathError Int
```

```c
hmath_status hmath_pde_flatten_index(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `pde.unflatten_index`

`pde.unflatten_index(value, value2)`

Inverse checked row-major index conversion.

Original: [`HMath.PDE.unflattenIndex`](haskell/HMath-PDE.md#v:unflattenIndex).

```haskell
Grid -> Int -> Either MathError [Int]
```

```c
hmath_status hmath_pde_unflatten_index(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `pde.grid_coordinates`

`pde.grid_coordinates(value)`

Physical coordinates in flat storage order; periodic upper endpoints are omitted.

Original: [`HMath.PDE.gridCoordinates`](haskell/HMath-PDE.md#v:gridCoordinates).

```haskell
Grid -> [[Double]]
```

```c
hmath_status hmath_pde_grid_coordinates(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `pde.assemble_pde`

`pde.assemble_pde(value, value2, value3, value4, value5)`

Assemble -kappa*Laplacian (FD) or -div(kappa grad) (FV/FEM) plus constant reaction; coefficient field is positive at every node.

Original: [`HMath.PDE.assemblePDE`](haskell/HMath-PDE.md#v:assemblePDE).

```haskell
Discretization -> Grid -> [(Boundary, Boundary)] -> [Double] -> Double -> Either MathError PDEOperator
```

```c
hmath_status hmath_pde_assemble_pde(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out);
```

## `pde.pde_stiffness`

`pde.pde_stiffness(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.PDE.pdeStiffness`](haskell/HMath-PDE.md#v:pdeStiffness).

```haskell
PDEOperator -> S.Sparse Double
```

```c
hmath_status hmath_pde_pde_stiffness(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `pde.pde_mass`

`pde.pde_mass(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.PDE.pdeMass`](haskell/HMath-PDE.md#v:pdeMass).

```haskell
PDEOperator -> S.Sparse Double
```

```c
hmath_status hmath_pde_pde_mass(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `pde.pde_boundary_load`

`pde.pde_boundary_load(value)`

Read boundary contributions, including prescribed values at essential rows.

Original: [`HMath.PDE.pdeBoundaryLoad`](haskell/HMath-PDE.md#v:pdeBoundaryLoad).

```haskell
PDEOperator -> [Double]
```

```c
hmath_status hmath_pde_pde_boundary_load(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `pde.solve_elliptic`

`pde.solve_elliptic(value, value2)`

 Dense pivoted reference solve and independently recomputed infinity residual. The error estimate is backward residual, not continuum error. 

Original: [`HMath.PDE.solveElliptic`](haskell/HMath-PDE.md#v:solveElliptic).

```haskell
PDEOperator -> [Double] -> Either MathError PDEResult
```

```c
hmath_status hmath_pde_solve_elliptic(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `pde.poisson`

`pde.poisson(method, g, bc, forcing)`

Solve a unit-diffusivity zero-reaction Poisson problem with the selected spatial discretization.

Original: [`HMath.PDE.poisson`](haskell/HMath-PDE.md#v:poisson).

```haskell
Discretization -> Grid -> [(Boundary, Boundary)] -> [Double] -> Either MathError PDEResult
```

```c
hmath_status hmath_pde_poisson(hmath_context *context, const hmath_value *method, const hmath_value *g, const hmath_value *bc, const hmath_value *forcing, hmath_value **out);
```

## `pde.laplace`

`pde.laplace(method, g, bc)`

Solve the corresponding homogeneous-source boundary-value problem.

Original: [`HMath.PDE.laplace`](haskell/HMath-PDE.md#v:laplace).

```haskell
Discretization -> Grid -> [(Boundary, Boundary)] -> Either MathError PDEResult
```

```c
hmath_status hmath_pde_laplace(hmath_context *context, const hmath_value *method, const hmath_value *g, const hmath_value *bc, hmath_value **out);
```

## `pde.helmholtz`

`pde.helmholtz(method, g, bc, k, forcing)`

Solve -Laplacian(u)-k²u=f; resonances/singular systems fail.

Original: [`HMath.PDE.helmholtz`](haskell/HMath-PDE.md#v:helmholtz).

```haskell
Discretization -> Grid -> [(Boundary, Boundary)] -> Double -> [Double] -> Either MathError PDEResult
```

```c
hmath_status hmath_pde_helmholtz(hmath_context *context, const hmath_value *method, const hmath_value *g, const hmath_value *bc, const hmath_value *k, const hmath_value *forcing, hmath_value **out);
```

## `pde.spatial_gradient`

`pde.spatial_gradient(value, value2)`

Second-order central spatial gradients; physical endpoints use second-order one-sided stencils.

Original: [`HMath.PDE.spatialGradient`](haskell/HMath-PDE.md#v:spatialGradient).

```haskell
Grid -> [Double] -> Either MathError [[Double]]
```

```c
hmath_status hmath_pde_spatial_gradient(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `pde.laplacian_stencil`

`pde.laplacian_stencil(g, bc, values)`

Apply the FD Laplacian with ghost normal/Robin boundary data. Essential rows return prescribed-value minus current-value residuals.

Original: [`HMath.PDE.laplacianStencil`](haskell/HMath-PDE.md#v:laplacianStencil).

```haskell
Grid -> [(Boundary, Boundary)] -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_pde_laplacian_stencil(hmath_context *context, const hmath_value *g, const hmath_value *bc, const hmath_value *values, hmath_value **out);
```

## `pde.spectral_derivative`

`pde.spectral_derivative(value, value2, value3, value4)`

Periodic Fourier collocation derivative of order 0..8 along one axis; odd real Nyquist derivatives are zero.

Original: [`HMath.PDE.spectralDerivative`](haskell/HMath-PDE.md#v:spectralDerivative).

```haskell
Grid -> Int -> Int -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_pde_spectral_derivative(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out);
```

## `pde.spectral_laplacian`

`pde.spectral_laplacian(g, values)`

Sum periodic second Fourier derivatives over all spatial axes.

Original: [`HMath.PDE.spectralLaplacian`](haskell/HMath-PDE.md#v:spectralLaplacian).

```haskell
Grid -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_pde_spectral_laplacian(hmath_context *context, const hmath_value *g, const hmath_value *values, hmath_value **out);
```

## `pde.spectral_poisson`

`pde.spectral_poisson(value, value2, value3)`

Solve (-Laplacian+reaction)u=f spectrally; reaction>=0, and zero reaction requires a mean-free source with zero-mean solution gauge.

Original: [`HMath.PDE.spectralPoisson`](haskell/HMath-PDE.md#v:spectralPoisson).

```haskell
Grid -> Double -> [Double] -> Either MathError PDEResult
```

```c
hmath_status hmath_pde_spectral_poisson(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out);
```

## `pde.pseudo_spectral_diffusion`

`pde.pseudo_spectral_diffusion(g, kappas, values)`

 Pseudospectral divergence(kappa*gradient u). Products are evaluated at collocation nodes; no implicit de-aliasing, so caller must resolve coefficients. 

Original: [`HMath.PDE.pseudoSpectralDiffusion`](haskell/HMath-PDE.md#v:pseudoSpectralDiffusion).

```haskell
Grid -> [Double] -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_pde_pseudo_spectral_diffusion(hmath_context *context, const hmath_value *g, const hmath_value *kappas, const hmath_value *values, hmath_value **out);
```

## `pde.method_of_lines`

`pde.method_of_lines(value, value2, value3, value4, value5)`

 Method of lines with a constant assembled operator and checked time-source callback. Essential Dirichlet values remain constant in time; initial state must satisfy them. Consistent FEM mass is inverted on unconstrained rows. 

Original: [`HMath.PDE.methodOfLines`](haskell/HMath-PDE.md#v:methodOfLines).

```haskell
O.Method -> PDEOperator -> (Double -> [Double]) -> [Double] -> [Double] -> Either MathError O.Trajectory
```

```c
hmath_status hmath_pde_method_of_lines(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out);
```

## `pde.heat`

`pde.heat(value, value2, value3, value4, value5)`

 Explicit heat/diffusion uses RK4, with a conservative forward-Euler CFL check (therefore valid for RK4 too). Positive diffusivity and ordered times. 

Original: [`HMath.PDE.heat`](haskell/HMath-PDE.md#v:heat).

```haskell
Grid -> [(Boundary, Boundary)] -> Double -> [Double] -> [Double] -> Either MathError O.Trajectory
```

```c
hmath_status hmath_pde_heat(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out);
```

## `pde.diffusion`

`pde.diffusion(method, g, bc, kappas, times, initial)`

Variable positive nodal diffusivity, chosen spatial method and increasing output times; FEM uses a stricter consistent-mass CFL bound.

Original: [`HMath.PDE.diffusion`](haskell/HMath-PDE.md#v:diffusion).

```haskell
Discretization -> Grid -> [(Boundary, Boundary)] -> [Double] -> [Double] -> [Double] -> Either MathError O.Trajectory
```

```c
hmath_status hmath_pde_diffusion(hmath_context *context, const hmath_value *method, const hmath_value *g, const hmath_value *bc, const hmath_value *kappas, const hmath_value *times, const hmath_value *initial, hmath_value **out);
```

## `pde.wave`

`pde.wave(g, speed, times, initial, velocity)`

 Periodic velocity-Verlet wave equation u_tt=c² Laplacian(u); returns u at requested equally or unequally spaced increasing times. Spectral Laplacian. 

Original: [`HMath.PDE.wave`](haskell/HMath-PDE.md#v:wave).

```haskell
Grid -> Double -> [Double] -> [Double] -> [Double] -> Either MathError [[Double]]
```

```c
hmath_status hmath_pde_wave(hmath_context *context, const hmath_value *g, const hmath_value *speed, const hmath_value *times, const hmath_value *initial, const hmath_value *velocity, hmath_value **out);
```

## `pde.advection`

`pde.advection(value, value2, value3, value4)`

 Conservative first-order upwind periodic advection, central conservative variable-coefficient diffusion. Explicit Euler preserves constants and total mass for periodic data when the combined positivity CFL is satisfied. 

Original: [`HMath.PDE.advection`](haskell/HMath-PDE.md#v:advection).

```haskell
Grid -> [Double] -> [Double] -> [Double] -> Either MathError [[Double]]
```

```c
hmath_status hmath_pde_advection(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out);
```

## `pde.advection_diffusion`

`pde.advection_diffusion(value, value2, value3, value4, value5)`

Periodic upwind advection plus central diffusion using explicit Euler and the combined positivity CFL bound.

Original: [`HMath.PDE.advectionDiffusion`](haskell/HMath-PDE.md#v:advectionDiffusion).

```haskell
Grid -> [Double] -> Double -> [Double] -> [Double] -> Either MathError [[Double]]
```

```c
hmath_status hmath_pde_advection_diffusion(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out);
```

## `pde.stability_limit`

`pde.stability_limit(g, diffusivity, velocity)`

Conservative explicit positivity bound 1/sum(|v|/h+2*kappa/h^2); infinity denotes a zero spatial operator.

Original: [`HMath.PDE.stabilityLimit`](haskell/HMath-PDE.md#v:stabilityLimit).

```haskell
Grid -> Double -> [Double] -> Either MathError Double
```

```c
hmath_status hmath_pde_stability_limit(hmath_context *context, const hmath_value *g, const hmath_value *diffusivity, const hmath_value *velocity, hmath_value **out);
```

## `pde.cfl_number`

`pde.cfl_number(g, diffusivity, velocity, dt)`

Requested nonnegative timestep divided by the conservative combined stability limit.

Original: [`HMath.PDE.cflNumber`](haskell/HMath-PDE.md#v:cflNumber).

```haskell
Grid -> Double -> [Double] -> Double -> Either MathError Double
```

```c
hmath_status hmath_pde_cfl_number(hmath_context *context, const hmath_value *g, const hmath_value *diffusivity, const hmath_value *velocity, const hmath_value *dt, hmath_value **out);
```

## `pde.manufactured_error`

`pde.manufactured_error(g, exact, values)`

Maximum absolute nodal difference from a finite exact-solution callback; this measures continuum error when an exact solution is known.

Original: [`HMath.PDE.manufacturedError`](haskell/HMath-PDE.md#v:manufacturedError).

```haskell
Grid -> ([Double] -> Double) -> [Double] -> Either MathError Double
```

```c
hmath_status hmath_pde_manufactured_error(hmath_context *context, const hmath_value *g, const hmath_value *exact, const hmath_value *values, hmath_value **out);
```

