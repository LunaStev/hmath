# Polynomial and power series

These bindings call the original Haskell functions. Coefficients are ascending: `[a0,a1,...]` represents `a0+a1*x+...`. Polynomial construction removes trailing exact zeros; the zero polynomial has `degree is None`. Power series retain their full finite coefficient sequence, including trailing zeros. They use the source truncation rules. No tolerance, budget or arithmetic algorithm is substituted.

Use `from hmath import polynomial as p`. Constructors accept `dtype="float64"` by default; choose `"float32"`, `"integer"`, `"rational"`, `"complex64"` or `"complex128"` explicitly. Bounded integral types are also available for Num operations. Rational results use `fractions.Fraction` and integers have no FP intermediary. Binary operations require matching coefficient types. A missing original typeclass instance returns `HMATH_UNSUPPORTED`; for example, polynomial division requires Fractional, and logarithmic series require ordered Floating coefficients.

```python
from fractions import Fraction
from hmath import polynomial as p
f = p.polynomial([1, 0, -2], dtype="rational")
g = p.differentiate_polynomial(f)
assert p.evaluate_polynomial(g, Fraction(3, 2)) == -6
f.close()
g.close()
```

C functions borrow inputs for the duration of the call and return independently owned `hmath_value` handles. Construct typed scalar/list/tuple values with `hmath_value.h`; release each owned handle once. `prototype` selects the coefficient type, including for empty lists. Outputs remain untouched on failure. Original `Left MathError` values return status 11 and retain constructor/fields/message through `hmath_last_math_error`. Python raises `HMathError` with `.math_error`. Opaque owners support `close()` and context management. All returned data are immutable; concurrent independent calls may share inputs.

## `polynomial`

Construct a polynomial, deleting trailing exact zeros (no floating tolerance).

`polynomial(coefficients, *, dtype="float64")` returns Polynomial. Parameters follow the original source order: `prototype`, `coefficients`.

```c
hmath_status hmath_polynomial_polynomial(hmath_context *context, const hmath_value *prototype, const hmath_value *coefficients, hmath_value **out);
```

## `coefficients`

Ascending coefficients, with no trailing zero; zero gives an empty list.

`coefficients(polynomial)` returns ascending coefficient list. Parameters follow the original source order: `polynomial`.

```c
hmath_status hmath_polynomial_coefficients(hmath_context *context, const hmath_value *polynomial, hmath_value **out);
```

## `polynomial_degree`

Degree of a nonzero polynomial; zero has no degree.

`polynomial_degree(polynomial)` returns integer degree, or None for the zero polynomial. Parameters follow the original source order: `polynomial`.

```c
hmath_status hmath_polynomial_polynomial_degree(hmath_context *context, const hmath_value *polynomial, hmath_value **out);
```

## `evaluate_polynomial`

Horner evaluation, with the constant coefficient first in storage.

`evaluate_polynomial(polynomial, x)` returns coefficient scalar. Parameters follow the original source order: `polynomial`, `x`.

```c
hmath_status hmath_polynomial_evaluate_polynomial(hmath_context *context, const hmath_value *polynomial, const hmath_value *x, hmath_value **out);
```

## `add_polynomial`

Coefficientwise addition with canonical exact-zero normalization.

`add_polynomial(left, right)` returns Polynomial. Parameters follow the original source order: `left`, `right`.

```c
hmath_status hmath_polynomial_add_polynomial(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `subtract_polynomial`

Coefficientwise subtraction.

`subtract_polynomial(left, right)` returns Polynomial. Parameters follow the original source order: `left`, `right`.

```c
hmath_status hmath_polynomial_subtract_polynomial(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `scale_polynomial`

Multiply every coefficient by a scalar.

`scale_polynomial(scalar, polynomial)` returns Polynomial. Parameters follow the original source order: `scalar`, `polynomial`.

```c
hmath_status hmath_polynomial_scale_polynomial(hmath_context *context, const hmath_value *scalar, const hmath_value *polynomial, hmath_value **out);
```

## `multiply_polynomial`

Exact schoolbook convolution, including zero polynomials.

`multiply_polynomial(left, right)` returns Polynomial. Parameters follow the original source order: `left`, `right`.

```c
hmath_status hmath_polynomial_multiply_polynomial(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `compose_polynomial`

Composition `p(q(x))` by polynomial Horner evaluation.

`compose_polynomial(outer, inner)` returns Polynomial. Parameters follow the original source order: `outer`, `inner`.

```c
hmath_status hmath_polynomial_compose_polynomial(hmath_context *context, const hmath_value *outer, const hmath_value *inner, hmath_value **out);
```

## `divide_polynomial`

Long division over a field. Exact coefficient equality controls termination; numerical cancellation is truncated at the eliminated leading coefficient. Zero denominator is rejected.

`divide_polynomial(numerator, denominator)` returns (quotient, remainder). Parameters follow the original source order: `numerator`, `denominator`.

```c
hmath_status hmath_polynomial_divide_polynomial(hmath_context *context, const hmath_value *numerator, const hmath_value *denominator, hmath_value **out);
```

## `monic_polynomial`

Normalize a nonzero polynomial to leading coefficient one; zero remains zero.

`monic_polynomial(polynomial)` returns Polynomial. Parameters follow the original source order: `polynomial`.

```c
hmath_status hmath_polynomial_monic_polynomial(hmath_context *context, const hmath_value *polynomial, hmath_value **out);
```

## `gcd_polynomial`

Monic Euclidean GCD over an exact field; `gcd(0,0)=0`.

`gcd_polynomial(left, right)` returns Polynomial. Parameters follow the original source order: `left`, `right`.

```c
hmath_status hmath_polynomial_gcd_polynomial(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `differentiate_polynomial`

Formal derivative.

`differentiate_polynomial(polynomial)` returns Polynomial. Parameters follow the original source order: `polynomial`.

```c
hmath_status hmath_polynomial_differentiate_polynomial(hmath_context *context, const hmath_value *polynomial, hmath_value **out);
```

## `integrate_polynomial`

Formal integral with the supplied integration constant.

`integrate_polynomial(constant, polynomial)` returns Polynomial. Parameters follow the original source order: `constant`, `polynomial`.

```c
hmath_status hmath_polynomial_integrate_polynomial(hmath_context *context, const hmath_value *constant, const hmath_value *polynomial, hmath_value **out);
```

## `square_free_factors`

Monic square-free factors with positive multiplicities over Rational. The leading coefficient is omitted; constant polynomials have no factors.

`square_free_factors(polynomial)` returns list of (monic factor, multiplicity). Parameters follow the original source order: `polynomial`. This operation requires exact Rational coefficients.

```c
hmath_status hmath_polynomial_square_free_factors(hmath_context *context, const hmath_value *polynomial, hmath_value **out);
```

## `rational_roots`

Rational roots with exact multiplicities using the rational-root theorem. Budget applies to integer factorization of numerator and leading coefficient.

`rational_roots(budget, polynomial)` returns list of (exact Rational root, multiplicity). Parameters follow the original source order: `budget`, `polynomial`. This operation requires exact Rational coefficients.

```c
hmath_status hmath_polynomial_rational_roots(hmath_context *context, const hmath_value *budget, const hmath_value *polynomial, hmath_value **out);
```

## `factor_rational_polynomial`

Complete rational factorization by bounded Kronecker interpolation. Returns the original leading scalar and monic irreducible factors with multiplicity. Every candidate is divided exactly. Exhausting the candidate budget reports failure, never an unsupported claim of irreducibility. Intended for small exact polynomials; coefficient divisor enumeration also uses this budget.

`factor_rational_polynomial(budget, polynomial)` returns (leading scalar, [(monic factor, multiplicity)]). Parameters follow the original source order: `budget`, `polynomial`. This operation requires exact Rational coefficients.

```c
hmath_status hmath_polynomial_factor_rational_polynomial(hmath_context *context, const hmath_value *budget, const hmath_value *polynomial, hmath_value **out);
```

## `sturm_sequence`

Sturm chain over exact rationals, after removing the derivative GCD. Zero polynomial is invalid. Square-free normalization ensures a repeated root cannot make every chain member vanish and destroy one-sided variation counts.

`sturm_sequence(polynomial)` returns list of exact Rational polynomials. Parameters follow the original source order: `polynomial`. This operation requires exact Rational coefficients.

```c
hmath_status hmath_polynomial_sturm_sequence(hmath_context *context, const hmath_value *polynomial, hmath_value **out);
```

## `count_real_roots`

Number of distinct real roots in `(a,b]`. Endpoints that are roots of the polynomial are rejected to make the interval convention unambiguous.

`count_real_roots(polynomial, left, right)` returns integer number of roots. Parameters follow the original source order: `polynomial`, `left`, `right`. This operation requires exact Rational coefficients.

```c
hmath_status hmath_polynomial_count_real_roots(hmath_context *context, const hmath_value *polynomial, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `isolate_real_roots`

Isolate every distinct real root in rational intervals with disjoint interiors and width at most tolerance. Intervals have the root-count convention (a,b]; shared endpoints belong to the interval on their left. Bisection budget bounds visited intervals; all arithmetic is exact.

`isolate_real_roots(depth, width, polynomial)` returns list of exact Rational endpoint pairs. Parameters follow the original source order: `depth`, `width`, `polynomial`. This operation requires exact Rational coefficients.

```c
hmath_status hmath_polynomial_isolate_real_roots(hmath_context *context, const hmath_value *depth, const hmath_value *width, const hmath_value *polynomial, hmath_value **out);
```

## `durand_kerner`

DurandKerner simultaneous complex root iteration. Distinct initial roots are placed on a Cauchy-bound circle; repeated roots may converge slowly.

`durand_kerner(iterations, tolerance, polynomial)` returns list of Complex Double roots. Parameters follow the original source order: `iterations`, `tolerance`, `polynomial`.

```c
hmath_status hmath_polynomial_durand_kerner(hmath_context *context, const hmath_value *iterations, const hmath_value *tolerance, const hmath_value *polynomial, hmath_value **out);
```

## `aberth_ehrlich`

AberthEhrlich simultaneous iteration, combining Newton corrections with mutual-root repulsion. All roots are verified against a scaled residual.

`aberth_ehrlich(iterations, tolerance, polynomial)` returns list of Complex Double roots. Parameters follow the original source order: `iterations`, `tolerance`, `polynomial`.

```c
hmath_status hmath_polynomial_aberth_ehrlich(hmath_context *context, const hmath_value *iterations, const hmath_value *tolerance, const hmath_value *polynomial, hmath_value **out);
```

## `companion_matrix`

Frobenius companion matrix of a nonconstant polynomial, with ones on the subdiagonal and negated monic coefficients in the last column.

`companion_matrix(polynomial)` returns interoperable Matrix with the same coefficient type. Parameters follow the original source order: `polynomial`.

```c
hmath_status hmath_polynomial_companion_matrix(hmath_context *context, const hmath_value *polynomial, hmath_value **out);
```

## `lagrange_interpolation`

Exact Lagrange interpolating polynomial. Duplicate nodes are rejected.

`lagrange_interpolation(points, *, dtype="float64")` returns Polynomial. Parameters follow the original source order: `prototype`, `points`.

```c
hmath_status hmath_polynomial_lagrange_interpolation(hmath_context *context, const hmath_value *prototype, const hmath_value *points, hmath_value **out);
```

## `newton_interpolation`

Newton divided differences, returned in the standard power basis.

`newton_interpolation(points, *, dtype="float64")` returns Polynomial. Parameters follow the original source order: `prototype`, `points`.

```c
hmath_status hmath_polynomial_newton_interpolation(hmath_context *context, const hmath_value *prototype, const hmath_value *points, hmath_value **out);
```

## `chebyshev_polynomial`

Chebyshev T_n, normalized by T_0=1, T_1=x.

`chebyshev_polynomial(degree, *, dtype="float64")` returns Polynomial. Parameters follow the original source order: `prototype`, `degree`.

```c
hmath_status hmath_polynomial_chebyshev_polynomial(hmath_context *context, const hmath_value *prototype, const hmath_value *degree, hmath_value **out);
```

## `legendre_polynomial`

Legendre P_n, normalized by P_n(1)=1.

`legendre_polynomial(degree, *, dtype="float64")` returns Polynomial. Parameters follow the original source order: `prototype`, `degree`.

```c
hmath_status hmath_polynomial_legendre_polynomial(hmath_context *context, const hmath_value *prototype, const hmath_value *degree, hmath_value **out);
```

## `hermite_polynomial`

Physicists' Hermite H_n: H_0=1, H_1=2x.

`hermite_polynomial(degree, *, dtype="float64")` returns Polynomial. Parameters follow the original source order: `prototype`, `degree`.

```c
hmath_status hmath_polynomial_hermite_polynomial(hmath_context *context, const hmath_value *prototype, const hmath_value *degree, hmath_value **out);
```

## `laguerre_polynomial`

Ordinary Laguerre L_n with alpha=0 and L_n(0)=1.

`laguerre_polynomial(degree, *, dtype="float64")` returns Polynomial. Parameters follow the original source order: `prototype`, `degree`.

```c
hmath_status hmath_polynomial_laguerre_polynomial(hmath_context *context, const hmath_value *prototype, const hmath_value *degree, hmath_value **out);
```

## `bernstein_polynomial`

Bernstein basis `binomial(n,k)*x^k*(1-x)^(n-k)` for 0<=k<=n.

`bernstein_polynomial(degree, index, *, dtype="float64")` returns Polynomial. Parameters follow the original source order: `prototype`, `degree`, `index`.

```c
hmath_status hmath_polynomial_bernstein_polynomial(hmath_context *context, const hmath_value *prototype, const hmath_value *degree, const hmath_value *index, hmath_value **out);
```

## `polynomial_regression`

Least-squares power-basis regression using column-pivoted Householder QR. Degree must be nonnegative; undersampling, nonfinite data and rank deficiency are reported by the checked design-matrix solver.

`polynomial_regression(degree, points, *, dtype="float64")` returns Polynomial. Parameters follow the original source order: `prototype`, `degree`, `points`.

```c
hmath_status hmath_polynomial_polynomial_regression(hmath_context *context, const hmath_value *prototype, const hmath_value *degree, const hmath_value *points, hmath_value **out);
```

## `power_series`

Construct a jet with explicit coefficients, including trailing zeros.

`power_series(coefficients, *, dtype="float64")` returns PowerSeries. Parameters follow the original source order: `prototype`, `coefficients`.

```c
hmath_status hmath_polynomial_power_series(hmath_context *context, const hmath_value *prototype, const hmath_value *coefficients, hmath_value **out);
```

## `series_coefficients`

Stored Taylor coefficients; coefficient n multiplies x^n, not x^n/n!.

`series_coefficients(series)` returns coefficient list, including trailing zeros. Parameters follow the original source order: `series`.

```c
hmath_status hmath_polynomial_series_coefficients(hmath_context *context, const hmath_value *series, hmath_value **out);
```

## `add_series`

Add jets to their common truncation order.

`add_series(left, right)` returns PowerSeries. Parameters follow the original source order: `left`, `right`.

```c
hmath_status hmath_polynomial_add_series(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `multiply_series`

Multiply jets by truncated convolution.

`multiply_series(left, right)` returns PowerSeries. Parameters follow the original source order: `left`, `right`.

```c
hmath_status hmath_polynomial_multiply_series(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `reciprocal_series`

Reciprocal jet from coefficient recurrence; constant term must be nonzero.

`reciprocal_series(series)` returns PowerSeries. Parameters follow the original source order: `series`.

```c
hmath_status hmath_polynomial_reciprocal_series(hmath_context *context, const hmath_value *series, hmath_value **out);
```

## `divide_series`

Divide jets to their common order; denominator constant must be nonzero.

`divide_series(numerator, denominator)` returns PowerSeries. Parameters follow the original source order: `numerator`, `denominator`.

```c
hmath_status hmath_polynomial_divide_series(hmath_context *context, const hmath_value *numerator, const hmath_value *denominator, hmath_value **out);
```

## `compose_series`

Formal composition to the inner jet's order. Inner constant must be zero, so unknown higher outer coefficients cannot affect the returned jet.

`compose_series(outer, inner)` returns PowerSeries. Parameters follow the original source order: `outer`, `inner`.

```c
hmath_status hmath_polynomial_compose_series(hmath_context *context, const hmath_value *outer, const hmath_value *inner, hmath_value **out);
```

## `differentiate_series`

Derivative jet has one fewer coefficient.

`differentiate_series(series)` returns PowerSeries. Parameters follow the original source order: `series`.

```c
hmath_status hmath_polynomial_differentiate_series(hmath_context *context, const hmath_value *series, hmath_value **out);
```

## `integrate_series`

Integral jet with supplied constant, one coefficient longer.

`integrate_series(constant, series)` returns PowerSeries. Parameters follow the original source order: `constant`, `series`.

```c
hmath_status hmath_polynomial_integrate_series(hmath_context *context, const hmath_value *constant, const hmath_value *series, hmath_value **out);
```

## `exp_series`

Exponential of a finite jet from b'=a'b; constant uses the coefficient type's exp. The output has the same truncation order.

`exp_series(series)` returns PowerSeries. Parameters follow the original source order: `series`.

```c
hmath_status hmath_polynomial_exp_series(hmath_context *context, const hmath_value *series, hmath_value **out);
```

## `log_series`

Formal log through derivative/division/integration. Requires positive real constant term, with exact truncation matching the input jet.

`log_series(series)` returns PowerSeries. Parameters follow the original source order: `series`.

```c
hmath_status hmath_polynomial_log_series(hmath_context *context, const hmath_value *series, hmath_value **out);
```

## `rational_function`

Normalize by polynomial GCD and reject a zero denominator.

`rational_function(numerator, denominator)` returns RationalFunction. Parameters follow the original source order: `numerator`, `denominator`. This operation requires exact Rational coefficients.

```c
hmath_status hmath_polynomial_rational_function(hmath_context *context, const hmath_value *numerator, const hmath_value *denominator, hmath_value **out);
```

## `rational_numerator`

Reduced numerator.

`rational_numerator(function)` returns Polynomial. Parameters follow the original source order: `function`. This operation requires exact Rational coefficients.

```c
hmath_status hmath_polynomial_rational_numerator(hmath_context *context, const hmath_value *function, hmath_value **out);
```

## `rational_denominator`

Monic reduced denominator.

`rational_denominator(function)` returns Polynomial. Parameters follow the original source order: `function`. This operation requires exact Rational coefficients.

```c
hmath_status hmath_polynomial_rational_denominator(hmath_context *context, const hmath_value *function, hmath_value **out);
```

## `evaluate_rational_function`

Exact evaluation, rejecting poles.

`evaluate_rational_function(function, x)` returns exact Rational scalar. Parameters follow the original source order: `function`, `x`. This operation requires exact Rational coefficients.

```c
hmath_status hmath_polynomial_evaluate_rational_function(hmath_context *context, const hmath_value *function, const hmath_value *x, hmath_value **out);
```

## `add_rational_function`

Exact rational-function addition with cancellation.

`add_rational_function(left, right)` returns RationalFunction. Parameters follow the original source order: `left`, `right`. This operation requires exact Rational coefficients.

```c
hmath_status hmath_polynomial_add_rational_function(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `multiply_rational_function`

Exact rational-function multiplication with cancellation.

`multiply_rational_function(left, right)` returns RationalFunction. Parameters follow the original source order: `left`, `right`. This operation requires exact Rational coefficients.

```c
hmath_status hmath_polynomial_multiply_rational_function(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `partial_fractions`

Exact partial fractions over Q. Each term is `(numerator,monic irreducible denominator,power)` and numerator degree is smaller than denominator degree. Supports repeated and nonlinear factors. Kronecker factorization and linear elimination are bounded by the supplied candidate budget.

`partial_fractions(budget, function)` returns (polynomial part, [(numerator, denominator, power)]). Parameters follow the original source order: `budget`, `function`. This operation requires exact Rational coefficients.

```c
hmath_status hmath_polynomial_partial_fractions(hmath_context *context, const hmath_value *budget, const hmath_value *function, hmath_value **out);
```

## `polynomial_equal`

Original derived Eq comparison; coefficient types must match.

`polynomial_equal(left, right)` returns Boolean. Parameters follow the original source order: `left`, `right`.

```c
hmath_status hmath_polynomial_polynomial_equal(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `series_equal`

Original derived Eq comparison; coefficient types must match.

`series_equal(left, right)` returns Boolean. Parameters follow the original source order: `left`, `right`.

```c
hmath_status hmath_polynomial_series_equal(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `rational_function_equal`

Original derived Eq comparison; coefficient types must match.

`rational_function_equal(left, right)` returns Boolean. Parameters follow the original source order: `left`, `right`.

```c
hmath_status hmath_polynomial_rational_function_equal(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `chebyshev_approximation`

Truncated Chebyshev interpolation at first-kind nodes on [-1,1], returned in power basis. Uses degree+1 evaluations; nonfinite values are rejected.

`chebyshev_approximation(degree, function)` returns a Double Polynomial. The callback is synchronous and sampled only by the original algorithm. It receives one Python float and returns one float. An original MathError raised by the callback is preserved; other Python exceptions are re-raised after native cleanup. No native callback or userdata outlives the call.

```c
hmath_status hmath_polynomial_chebyshev_approximation(hmath_context *context, ptrdiff_t degree, hmath_polynomial_callback callback, void *userdata, hmath_value **out);
```
