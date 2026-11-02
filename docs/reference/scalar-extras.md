# Complete scalar-domain adapters

These functions call the original Complex, Trigonometry, NumberTheory and Special APIs. C includes `hmath_scalar_extras.h`; Python namespaces extend existing modules without replacing earlier numerical functions. Complex selectors are owned immutable original objects, constructed with `complex.exp()`/`trigonometry.c_sin()` etc. The `complex_function` adapter accepts `dtype="float32"` or `"float64"`; actual typed Complex Float inputs remain Float through the original RealFloat algorithm. Other complex operations/SFResult retain original Double precision. No principal-branch, pole/nonfinite, error-estimate or integer-budget policy is changed.

Values use the [owned structured protocol](values.md): inputs borrowed, outputs owned/untouched on failure, each reference pins the runtime. Exact integers have no fixed precision or floating conversion. Variable-length/nested lists and tuples keep their original order/shape; Maybe uses None. Checked source errors retain complete MathError/status11. Selectors use kinds352/353. SFResult uses a tuple of two Doubles, interoperable with existing SFResult(value,error) named tuples; its raw constructor does not normalize or certify the error field.

## `complex.exp`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_exp(hmath_context *context, hmath_value **out);
```

## `complex.log`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_log(hmath_context *context, hmath_value **out);
```

## `complex.sqrt`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_sqrt(hmath_context *context, hmath_value **out);
```

## `complex.sin`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_sin(hmath_context *context, hmath_value **out);
```

## `complex.cos`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_cos(hmath_context *context, hmath_value **out);
```

## `complex.tan`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_tan(hmath_context *context, hmath_value **out);
```

## `complex.sinh`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_sinh(hmath_context *context, hmath_value **out);
```

## `complex.cosh`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_cosh(hmath_context *context, hmath_value **out);
```

## `complex.tanh`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_tanh(hmath_context *context, hmath_value **out);
```

## `complex.asin`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_asin(hmath_context *context, hmath_value **out);
```

## `complex.acos`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_acos(hmath_context *context, hmath_value **out);
```

## `complex.atan`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_atan(hmath_context *context, hmath_value **out);
```

## `complex.asinh`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_asinh(hmath_context *context, hmath_value **out);
```

## `complex.acosh`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_acosh(hmath_context *context, hmath_value **out);
```

## `complex.atanh`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Elementary
```

```c
hmath_status hmath_complex_atanh(hmath_context *context, hmath_value **out);
```

## `complex.elementary`

Apply an elementary function, rejecting poles and nonfinite results.

```haskell
Elementary -> Complex Double -> Either MathError (Complex Double)
```

```c
hmath_status hmath_complex_elementary(hmath_context *context, const hmath_value *operation, const hmath_value *value, hmath_value **out);
```

## `complex.complex_matrix`

Checked finite complex matrix, at most 256 rows and columns.

```haskell
Int -> Int -> [Complex Double] -> Either MathError (Matrix (Complex Double))
```

```c
hmath_status hmath_complex_complex_matrix(hmath_context *context, const hmath_value *rows, const hmath_value *columns, const hmath_value *values, hmath_value **out);
```

## `complex.multiply_matrices`

Matrix multiplication with finite-result validation.

```haskell
Matrix (Complex Double) -> Matrix (Complex Double) -> Either MathError (Matrix (Complex Double))
```

```c
hmath_status hmath_complex_multiply_matrices(hmath_context *context, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `complex.conjugate_transpose`

Hermitian transpose with finite-input validation.

```haskell
Matrix (Complex Double) -> Either MathError (Matrix (Complex Double))
```

```c
hmath_status hmath_complex_conjugate_transpose(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `complex.complex_fft`

Existing checked mixed-radix/Bluestein forward FFT.

```haskell
[Complex Double] -> Either MathError [Complex Double]
```

```c
hmath_status hmath_complex_complex_fft(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `complex.complex_ifft`

Existing checked inverse FFT, normalized by sample count.

```haskell
[Complex Double] -> Either MathError [Complex Double]
```

```c
hmath_status hmath_complex_complex_ifft(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `trigonometry.c_sin`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_sin(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_cos`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_cos(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_tan`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_tan(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_asin`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_asin(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_acos`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_acos(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_atan`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_atan(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_sinh`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_sinh(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_cosh`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_cosh(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_tanh`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_tanh(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_asinh`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_asinh(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_acosh`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_acosh(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_atanh`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_atanh(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_sec`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_sec(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_csc`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_csc(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_cot`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_cot(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_sech`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_sech(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_csch`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_csch(hmath_context *context, hmath_value **out);
```

## `trigonometry.c_coth`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ComplexFunction
```

```c
hmath_status hmath_trigonometry_c_coth(hmath_context *context, hmath_value **out);
```

## `trigonometry.complex_function`

 Given a ComplexFunction selector then complex input, compute the selected principal-branch Data.Complex function or reciprocal. Reject non-finite components and non-finite results/poles with Left DomainError. 

```haskell
RealFloat a => ComplexFunction -> Complex a -> Either MathError (Complex a)
```

```c
hmath_status hmath_trigonometry_complex_function(hmath_context *context, const hmath_value *operation, const hmath_value *value, hmath_value **out);
```

## `numbertheory.chinese_remainder`

 Generalized CRT for @(residue,positive modulus)@ pairs. Compatible noncoprime moduli are supported. Returns canonical residue and lcm modulus. 

```haskell
[(Integer,Integer)] -> Either MathError (Integer,Integer)
```

```c
hmath_status hmath_numbertheory_chinese_remainder(hmath_context *context, const hmath_value *congruences, hmath_value **out);
```

## `numbertheory.linear_diophantine`

 One solution and a direction: @(x,y,dx,dy)@ represents every solution @(x+k*dx,y+k*dy)@ of @a*x+b*y=c@. The all-zero equation has a two-dimensional solution set and is rejected instead of returning a misleading direction. 

```haskell
Integer -> Integer -> Integer -> Either MathError (Integer,Integer,Integer,Integer)
```

```c
hmath_status hmath_numbertheory_linear_diophantine(hmath_context *context, const hmath_value *a, const hmath_value *b, const hmath_value *c, hmath_value **out);
```

## `numbertheory.perfect_power`

 Find a representation @n = base^exponent@ with exponent greater than one. Zero, one, and minus one use exponent 2, 2, and 3 respectively. 

```haskell
Integer -> Maybe (Integer,Int)
```

```c
hmath_status hmath_numbertheory_perfect_power(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `numbertheory.prime_factorization`

 Exact trial factorization of a positive integer. The budget counts attempted divisors (including repeated factors). One has an empty factorization. 

```haskell
Int -> Integer -> Either MathError [(Integer,Int)]
```

```c
hmath_status hmath_numbertheory_prime_factorization(hmath_context *context, const hmath_value *budget, const hmath_value *value, hmath_value **out);
```

## `numbertheory.partitions`

Integer partitions in descending part order. Zero has one empty partition.

```haskell
Int -> Either MathError [[Int]]
```

```c
hmath_status hmath_numbertheory_partitions(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `special.sf_result`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> Double -> SFResult
```

```c
hmath_status hmath_special_sf_result(hmath_context *context, const hmath_value *value, const hmath_value *error, hmath_value **out);
```

## `special.sf_value`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
SFResult -> Double
```

```c
hmath_status hmath_special_sf_value(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `special.sf_error`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
SFResult -> Double
```

```c
hmath_status hmath_special_sf_error(hmath_context *context, const hmath_value *value, hmath_value **out);
```

