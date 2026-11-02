# Numeric bindings

These bindings call the original Haskell functions. They do not replace their algorithms or change domain checks. This is an incremental subset, **not full Haskell API coverage**.

Include `hmath_numeric.h` in C/C++; in Python use `from hmath import scalar, basic, trigonometry, statistics, constants`. Floating functions accept keyword-only `dtype="float64"` or `dtype="float32"`; these select Haskell `Double` and `Float`, respectively. Functions whose original signature fixes `Double` accept only `float64`; `float32` is rejected rather than silently promoted. Generic functions may have other Haskell type instances which are not yet bound. Python returns ordinary floats, complex numbers, tuples, lists, arbitrary-precision integers and `fractions.Fraction` values.

Original argument order is preserved. C flattens coordinate pairs and complex values into two real arguments, lists into a pointer and count, and tuple results into separate output pointers. Haskell `Int` uses `ptrdiff_t`; `Integer` uses signed ASCII decimal strings without a fixed precision limit. Rationals use separate exact numerator and denominator strings. Free each returned string with `hmath_numeric_string_free`. Python owns and releases this transport automatically.

Generic Basic, Scalar, Linear and Statistics functions list their supported `dtype` instances below. `integer` uses unbounded Haskell `Integer`; `rational` uses exact `Rational` and Python `fractions.Fraction`. `int8`/`int16`/`int32`/`int64` and unsigned `uint*` select the corresponding bounded Haskell types. `intp`/`uintp` select native-width Haskell `Int`/`Word`. `complex64` and `complex128` select `Complex Float` and `Complex Double`. Only instances permitted by the original constraints are offered. [Typed generic Value adapters](numeric-objects.md) additionally preserve bound Numeric.Dual/Quaternion, original AD.Dual/Expr and supported native Ord labels through their actual dictionaries. These finite instance sets do not claim support for every user-defined Haskell typeclass instance.

Ordinary bounded arithmetic keeps the original wrapping behavior; the dedicated checked and saturating functions keep their original error/clamping behavior. Python rejects values outside the selected bounded input type with `OverflowError`. Use explicit `dtype='integer'`/`'rational'` for exact arithmetic; existing floating defaults remain unchanged. Rational input arrays use alternating decimal numerator/denominator strings; complex arrays use alternating real/imaginary components. Array counts are logical values, not component counts.

A Haskell `Left MathError` becomes `HMATH_MATH_ERROR` (11) in C and `HMathError(status=11)` in Python; the original constructor and payload are retained in the error message. Pure exceptions use status 6. Unchecked functions still allow their original NaN/Inf behavior. No finite-value check is added.

Input buffers live for the call. Output buffers must not overlap inputs or each other, and list outputs must hold the input count (plus one for prefixSum); C output capacity is checked. Outputs remain untouched on failure. Initialize the runtime before numerical calls. Cancellation is checked before the call. Independent calls can run concurrently.

## `basic.factorial`

`basic.factorial(n)`

Original: [`HMath.Basic.factorial`](haskell/HMath-Basic.md#v:factorial). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_basic_factorial(
    hmath_context *context,
    const char *n,
    char **out0);
```

## `basic.fibonacci`

`basic.fibonacci(n)`

Original: [`HMath.Basic.fibonacci`](haskell/HMath-Basic.md#v:fibonacci). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_basic_fibonacci(
    hmath_context *context,
    const char *n,
    char **out0);
```

## `basic.is_prime`

`basic.is_prime(n)`

Original: [`HMath.Basic.isPrime`](haskell/HMath-Basic.md#v:isPrime). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_basic_is_prime(
    hmath_context *context,
    const char *n,
    int *out0);
```

## `basic.clamp`

`basic.clamp(low, high, value, *, dtype='float64')`

Original: [`HMath.Basic.clamp`](haskell/HMath-Basic.md#v:clamp). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`.

```c
hmath_status hmath_basic_clamp_f32(
    hmath_context *context,
    float low,
    float high,
    float value,
    float *out0);
```

```c
hmath_status hmath_basic_clamp_f64(
    hmath_context *context,
    double low,
    double high,
    double value,
    double *out0);
```

```c
hmath_status hmath_basic_clamp_rational(
    hmath_context *context,
    const char *low_numerator,
    const char *low_denominator,
    const char *high_numerator,
    const char *high_denominator,
    const char *value_numerator,
    const char *value_denominator,
    char **out0,
    char **out1);
```

```c
hmath_status hmath_basic_clamp_integer(
    hmath_context *context,
    const char *low,
    const char *high,
    const char *value,
    char **out0);
```

```c
hmath_status hmath_basic_clamp_i8(
    hmath_context *context,
    int8_t low,
    int8_t high,
    int8_t value,
    int8_t *out0);
```

```c
hmath_status hmath_basic_clamp_i16(
    hmath_context *context,
    int16_t low,
    int16_t high,
    int16_t value,
    int16_t *out0);
```

```c
hmath_status hmath_basic_clamp_i32(
    hmath_context *context,
    int32_t low,
    int32_t high,
    int32_t value,
    int32_t *out0);
```

```c
hmath_status hmath_basic_clamp_i64(
    hmath_context *context,
    int64_t low,
    int64_t high,
    int64_t value,
    int64_t *out0);
```

```c
hmath_status hmath_basic_clamp_u8(
    hmath_context *context,
    uint8_t low,
    uint8_t high,
    uint8_t value,
    uint8_t *out0);
```

```c
hmath_status hmath_basic_clamp_u16(
    hmath_context *context,
    uint16_t low,
    uint16_t high,
    uint16_t value,
    uint16_t *out0);
```

```c
hmath_status hmath_basic_clamp_u32(
    hmath_context *context,
    uint32_t low,
    uint32_t high,
    uint32_t value,
    uint32_t *out0);
```

```c
hmath_status hmath_basic_clamp_u64(
    hmath_context *context,
    uint64_t low,
    uint64_t high,
    uint64_t value,
    uint64_t *out0);
```

```c
hmath_status hmath_basic_clamp_int(
    hmath_context *context,
    ptrdiff_t low,
    ptrdiff_t high,
    ptrdiff_t value,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_basic_clamp_word(
    hmath_context *context,
    size_t low,
    size_t high,
    size_t value,
    size_t *out0);
```

## `basic.lerp`

`basic.lerp(a, b, t, *, dtype='float64')`

Original: [`HMath.Basic.lerp`](haskell/HMath-Basic.md#v:lerp). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `complex64`, `complex128`.

```c
hmath_status hmath_basic_lerp_f32(
    hmath_context *context,
    float a,
    float b,
    float t,
    float *out0);
```

```c
hmath_status hmath_basic_lerp_f64(
    hmath_context *context,
    double a,
    double b,
    double t,
    double *out0);
```

```c
hmath_status hmath_basic_lerp_rational(
    hmath_context *context,
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    const char *t_numerator,
    const char *t_denominator,
    char **out0,
    char **out1);
```

```c
hmath_status hmath_basic_lerp_c64(
    hmath_context *context,
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float t_0,
    float t_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_basic_lerp_c128(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double t_0,
    double t_1,
    double *out0,
    double *out1);
```

## `scalar.add`

`scalar.add(a, b, *, dtype='float64')`

Original: [`HMath.Scalar.add`](haskell/HMath-Scalar.md#v:add). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_scalar_add_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0);
```

```c
hmath_status hmath_scalar_add_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0);
```

```c
hmath_status hmath_scalar_add_rational(
    hmath_context *context,
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1);
```

```c
hmath_status hmath_scalar_add_integer(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0);
```

```c
hmath_status hmath_scalar_add_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_add_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_add_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_add_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_add_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_add_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_add_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_add_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_add_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_add_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0);
```

```c
hmath_status hmath_scalar_add_c64(
    hmath_context *context,
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_scalar_add_c128(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
```

## `scalar.subtract_scalar`

`scalar.subtract_scalar(a, b, *, dtype='float64')`

Original: [`HMath.Scalar.subtractScalar`](haskell/HMath-Scalar.md#v:subtractScalar). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_scalar_subtract_scalar_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0);
```

```c
hmath_status hmath_scalar_subtract_scalar_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0);
```

```c
hmath_status hmath_scalar_subtract_scalar_rational(
    hmath_context *context,
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1);
```

```c
hmath_status hmath_scalar_subtract_scalar_integer(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0);
```

```c
hmath_status hmath_scalar_subtract_scalar_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_subtract_scalar_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_subtract_scalar_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_subtract_scalar_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_subtract_scalar_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_subtract_scalar_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_subtract_scalar_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_subtract_scalar_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_subtract_scalar_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_subtract_scalar_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0);
```

```c
hmath_status hmath_scalar_subtract_scalar_c64(
    hmath_context *context,
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_scalar_subtract_scalar_c128(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
```

## `scalar.multiply`

`scalar.multiply(a, b, *, dtype='float64')`

Original: [`HMath.Scalar.multiply`](haskell/HMath-Scalar.md#v:multiply). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_scalar_multiply_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0);
```

```c
hmath_status hmath_scalar_multiply_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0);
```

```c
hmath_status hmath_scalar_multiply_rational(
    hmath_context *context,
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1);
```

```c
hmath_status hmath_scalar_multiply_integer(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0);
```

```c
hmath_status hmath_scalar_multiply_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_multiply_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_multiply_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_multiply_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_multiply_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_multiply_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_multiply_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_multiply_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_multiply_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_multiply_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0);
```

```c
hmath_status hmath_scalar_multiply_c64(
    hmath_context *context,
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_scalar_multiply_c128(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
```

## `scalar.minimum_scalar`

`scalar.minimum_scalar(a, b, *, dtype='float64')`

Original: [`HMath.Scalar.minimumScalar`](haskell/HMath-Scalar.md#v:minimumScalar). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`.

```c
hmath_status hmath_scalar_minimum_scalar_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0);
```

```c
hmath_status hmath_scalar_minimum_scalar_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0);
```

```c
hmath_status hmath_scalar_minimum_scalar_rational(
    hmath_context *context,
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1);
```

```c
hmath_status hmath_scalar_minimum_scalar_integer(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0);
```

```c
hmath_status hmath_scalar_minimum_scalar_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_minimum_scalar_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_minimum_scalar_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_minimum_scalar_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_minimum_scalar_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_minimum_scalar_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_minimum_scalar_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_minimum_scalar_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_minimum_scalar_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_minimum_scalar_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0);
```

## `scalar.maximum_scalar`

`scalar.maximum_scalar(a, b, *, dtype='float64')`

Original: [`HMath.Scalar.maximumScalar`](haskell/HMath-Scalar.md#v:maximumScalar). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`.

```c
hmath_status hmath_scalar_maximum_scalar_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0);
```

```c
hmath_status hmath_scalar_maximum_scalar_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0);
```

```c
hmath_status hmath_scalar_maximum_scalar_rational(
    hmath_context *context,
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1);
```

```c
hmath_status hmath_scalar_maximum_scalar_integer(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0);
```

```c
hmath_status hmath_scalar_maximum_scalar_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_maximum_scalar_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_maximum_scalar_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_maximum_scalar_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_maximum_scalar_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_maximum_scalar_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_maximum_scalar_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_maximum_scalar_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_maximum_scalar_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_maximum_scalar_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0);
```

## `scalar.absolute`

`scalar.absolute(x, *, dtype='float64')`

Original: [`HMath.Scalar.absolute`](haskell/HMath-Scalar.md#v:absolute). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_scalar_absolute_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_absolute_f64(
    hmath_context *context,
    double x,
    double *out0);
```

```c
hmath_status hmath_scalar_absolute_rational(
    hmath_context *context,
    const char *x_numerator,
    const char *x_denominator,
    char **out0,
    char **out1);
```

```c
hmath_status hmath_scalar_absolute_integer(
    hmath_context *context,
    const char *x,
    char **out0);
```

```c
hmath_status hmath_scalar_absolute_i8(
    hmath_context *context,
    int8_t x,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_absolute_i16(
    hmath_context *context,
    int16_t x,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_absolute_i32(
    hmath_context *context,
    int32_t x,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_absolute_i64(
    hmath_context *context,
    int64_t x,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_absolute_u8(
    hmath_context *context,
    uint8_t x,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_absolute_u16(
    hmath_context *context,
    uint16_t x,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_absolute_u32(
    hmath_context *context,
    uint32_t x,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_absolute_u64(
    hmath_context *context,
    uint64_t x,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_absolute_int(
    hmath_context *context,
    ptrdiff_t x,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_absolute_word(
    hmath_context *context,
    size_t x,
    size_t *out0);
```

```c
hmath_status hmath_scalar_absolute_c64(
    hmath_context *context,
    float x_0,
    float x_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_scalar_absolute_c128(
    hmath_context *context,
    double x_0,
    double x_1,
    double *out0,
    double *out1);
```

## `scalar.sign`

`scalar.sign(x, *, dtype='float64')`

Original: [`HMath.Scalar.sign`](haskell/HMath-Scalar.md#v:sign). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_scalar_sign_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_sign_f64(
    hmath_context *context,
    double x,
    double *out0);
```

```c
hmath_status hmath_scalar_sign_rational(
    hmath_context *context,
    const char *x_numerator,
    const char *x_denominator,
    char **out0,
    char **out1);
```

```c
hmath_status hmath_scalar_sign_integer(
    hmath_context *context,
    const char *x,
    char **out0);
```

```c
hmath_status hmath_scalar_sign_i8(
    hmath_context *context,
    int8_t x,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_sign_i16(
    hmath_context *context,
    int16_t x,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_sign_i32(
    hmath_context *context,
    int32_t x,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_sign_i64(
    hmath_context *context,
    int64_t x,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_sign_u8(
    hmath_context *context,
    uint8_t x,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_sign_u16(
    hmath_context *context,
    uint16_t x,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_sign_u32(
    hmath_context *context,
    uint32_t x,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_sign_u64(
    hmath_context *context,
    uint64_t x,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_sign_int(
    hmath_context *context,
    ptrdiff_t x,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_sign_word(
    hmath_context *context,
    size_t x,
    size_t *out0);
```

```c
hmath_status hmath_scalar_sign_c64(
    hmath_context *context,
    float x_0,
    float x_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_scalar_sign_c128(
    hmath_context *context,
    double x_0,
    double x_1,
    double *out0,
    double *out1);
```

## `scalar.divide`

`scalar.divide(a, b, *, dtype='float64')`

Original: [`HMath.Scalar.divide`](haskell/HMath-Scalar.md#v:divide). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_divide_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0);
```

```c
hmath_status hmath_scalar_divide_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0);
```

## `scalar.power`

`scalar.power(a, b, *, dtype='float64')`

Original: [`HMath.Scalar.power`](haskell/HMath-Scalar.md#v:power). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_power_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0);
```

```c
hmath_status hmath_scalar_power_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0);
```

## `scalar.hypot`

`scalar.hypot(a, b, *, dtype='float64')`

Original: [`HMath.Scalar.hypot`](haskell/HMath-Scalar.md#v:hypot). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_hypot_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0);
```

```c
hmath_status hmath_scalar_hypot_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0);
```

## `scalar.clamp_checked`

`scalar.clamp_checked(low, high, value, *, dtype='float64')`

Original: [`HMath.Scalar.clampChecked`](haskell/HMath-Scalar.md#v:clampChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_clamp_checked_f32(
    hmath_context *context,
    float low,
    float high,
    float value,
    float *out0);
```

```c
hmath_status hmath_scalar_clamp_checked_f64(
    hmath_context *context,
    double low,
    double high,
    double value,
    double *out0);
```

## `scalar.lerp_checked`

`scalar.lerp_checked(a, b, t, *, dtype='float64')`

Original: [`HMath.Scalar.lerpChecked`](haskell/HMath-Scalar.md#v:lerpChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_lerp_checked_f32(
    hmath_context *context,
    float a,
    float b,
    float t,
    float *out0);
```

```c
hmath_status hmath_scalar_lerp_checked_f64(
    hmath_context *context,
    double a,
    double b,
    double t,
    double *out0);
```

## `scalar.inverse_lerp`

`scalar.inverse_lerp(a, b, x, *, dtype='float64')`

Original: [`HMath.Scalar.inverseLerp`](haskell/HMath-Scalar.md#v:inverseLerp). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_inverse_lerp_f32(
    hmath_context *context,
    float a,
    float b,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_inverse_lerp_f64(
    hmath_context *context,
    double a,
    double b,
    double x,
    double *out0);
```

## `scalar.smoothstep`

`scalar.smoothstep(a, b, x, *, dtype='float64')`

Original: [`HMath.Scalar.smoothstep`](haskell/HMath-Scalar.md#v:smoothstep). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_smoothstep_f32(
    hmath_context *context,
    float a,
    float b,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_smoothstep_f64(
    hmath_context *context,
    double a,
    double b,
    double x,
    double *out0);
```

## `scalar.smootherstep`

`scalar.smootherstep(a, b, x, *, dtype='float64')`

Original: [`HMath.Scalar.smootherstep`](haskell/HMath-Scalar.md#v:smootherstep). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_smootherstep_f32(
    hmath_context *context,
    float a,
    float b,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_smootherstep_f64(
    hmath_context *context,
    double a,
    double b,
    double x,
    double *out0);
```

## `scalar.remap`

`scalar.remap(a, b, c, d, x, *, dtype='float64')`

Original: [`HMath.Scalar.remap`](haskell/HMath-Scalar.md#v:remap). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_remap_f32(
    hmath_context *context,
    float a,
    float b,
    float c,
    float d,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_remap_f64(
    hmath_context *context,
    double a,
    double b,
    double c,
    double d,
    double x,
    double *out0);
```

## `scalar.step`

`scalar.step(edge, x, *, dtype='float64')`

Original: [`HMath.Scalar.step`](haskell/HMath-Scalar.md#v:step). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_step_f32(
    hmath_context *context,
    float edge,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_step_f64(
    hmath_context *context,
    double edge,
    double x,
    double *out0);
```

## `scalar.sqrt_checked`

`scalar.sqrt_checked(x, *, dtype='float64')`

Original: [`HMath.Scalar.sqrtChecked`](haskell/HMath-Scalar.md#v:sqrtChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_sqrt_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_sqrt_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `scalar.cube_root`

`scalar.cube_root(x, *, dtype='float64')`

Original: [`HMath.Scalar.cubeRoot`](haskell/HMath-Scalar.md#v:cubeRoot). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_cube_root_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_cube_root_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `scalar.reciprocal_sqrt`

`scalar.reciprocal_sqrt(x, *, dtype='float64')`

Original: [`HMath.Scalar.reciprocalSqrt`](haskell/HMath-Scalar.md#v:reciprocalSqrt). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_reciprocal_sqrt_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_reciprocal_sqrt_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `scalar.exp_checked`

`scalar.exp_checked(x, *, dtype='float64')`

Original: [`HMath.Scalar.expChecked`](haskell/HMath-Scalar.md#v:expChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_exp_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_exp_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `scalar.log_checked`

`scalar.log_checked(x, *, dtype='float64')`

Original: [`HMath.Scalar.logChecked`](haskell/HMath-Scalar.md#v:logChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_log_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_log_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `scalar.expm1`

`scalar.expm1(x, *, dtype='float64')`

Original: [`HMath.Scalar.expm1`](haskell/HMath-Scalar.md#v:expm1). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_expm1_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_expm1_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `scalar.log1p`

`scalar.log1p(x, *, dtype='float64')`

Original: [`HMath.Scalar.log1p`](haskell/HMath-Scalar.md#v:log1p). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_log1p_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_log1p_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `scalar.integer_power`

`scalar.integer_power(a, n, *, dtype='float64')`

Original: [`HMath.Scalar.integerPower`](haskell/HMath-Scalar.md#v:integerPower). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_integer_power_f32(
    hmath_context *context,
    float a,
    const char *n,
    float *out0);
```

```c
hmath_status hmath_scalar_integer_power_f64(
    hmath_context *context,
    double a,
    const char *n,
    double *out0);
```

## `scalar.nth_root`

`scalar.nth_root(n, x, *, dtype='float64')`

Original: [`HMath.Scalar.nthRoot`](haskell/HMath-Scalar.md#v:nthRoot). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_nth_root_f32(
    hmath_context *context,
    ptrdiff_t n,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_nth_root_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0);
```

## `scalar.round_digits`

`scalar.round_digits(n, x, *, dtype='float64')`

Original: [`HMath.Scalar.roundDigits`](haskell/HMath-Scalar.md#v:roundDigits). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_round_digits_f32(
    hmath_context *context,
    ptrdiff_t n,
    float x,
    float *out0);
```

```c
hmath_status hmath_scalar_round_digits_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0);
```

## `scalar.absolute_error`

`scalar.absolute_error(actual, expected, *, dtype='float64')`

Original: [`HMath.Scalar.absoluteError`](haskell/HMath-Scalar.md#v:absoluteError). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_absolute_error_f32(
    hmath_context *context,
    float actual,
    float expected,
    float *out0);
```

```c
hmath_status hmath_scalar_absolute_error_f64(
    hmath_context *context,
    double actual,
    double expected,
    double *out0);
```

## `scalar.relative_error`

`scalar.relative_error(actual, expected, *, dtype='float64')`

Original: [`HMath.Scalar.relativeError`](haskell/HMath-Scalar.md#v:relativeError). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_relative_error_f32(
    hmath_context *context,
    float actual,
    float expected,
    float *out0);
```

```c
hmath_status hmath_scalar_relative_error_f64(
    hmath_context *context,
    double actual,
    double expected,
    double *out0);
```

## `scalar.fused_multiply_add`

`scalar.fused_multiply_add(a, b, c, *, dtype='float64')`

Original: [`HMath.Scalar.fusedMultiplyAdd`](haskell/HMath-Scalar.md#v:fusedMultiplyAdd). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_fused_multiply_add_f32(
    hmath_context *context,
    float a,
    float b,
    float c,
    float *out0);
```

```c
hmath_status hmath_scalar_fused_multiply_add_f64(
    hmath_context *context,
    double a,
    double b,
    double c,
    double *out0);
```

## `scalar.checked_float_multiply`

`scalar.checked_float_multiply(a, b, *, dtype='float64')`

Original: [`HMath.Scalar.checkedFloatMultiply`](haskell/HMath-Scalar.md#v:checkedFloatMultiply). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_checked_float_multiply_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0);
```

```c
hmath_status hmath_scalar_checked_float_multiply_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0);
```

## `scalar.floor_checked`

`scalar.floor_checked(x, *, dtype='float64')`

Original: [`HMath.Scalar.floorChecked`](haskell/HMath-Scalar.md#v:floorChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_floor_checked_f32(
    hmath_context *context,
    float x,
    char **out0);
```

```c
hmath_status hmath_scalar_floor_checked_f64(
    hmath_context *context,
    double x,
    char **out0);
```

## `scalar.ceil_checked`

`scalar.ceil_checked(x, *, dtype='float64')`

Original: [`HMath.Scalar.ceilChecked`](haskell/HMath-Scalar.md#v:ceilChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_ceil_checked_f32(
    hmath_context *context,
    float x,
    char **out0);
```

```c
hmath_status hmath_scalar_ceil_checked_f64(
    hmath_context *context,
    double x,
    char **out0);
```

## `scalar.round_checked`

`scalar.round_checked(x, *, dtype='float64')`

Original: [`HMath.Scalar.roundChecked`](haskell/HMath-Scalar.md#v:roundChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_round_checked_f32(
    hmath_context *context,
    float x,
    char **out0);
```

```c
hmath_status hmath_scalar_round_checked_f64(
    hmath_context *context,
    double x,
    char **out0);
```

## `scalar.truncate_checked`

`scalar.truncate_checked(x, *, dtype='float64')`

Original: [`HMath.Scalar.truncateChecked`](haskell/HMath-Scalar.md#v:truncateChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_truncate_checked_f32(
    hmath_context *context,
    float x,
    char **out0);
```

```c
hmath_status hmath_scalar_truncate_checked_f64(
    hmath_context *context,
    double x,
    char **out0);
```

## `scalar.bankers_round`

`scalar.bankers_round(x, *, dtype='float64')`

Original: [`HMath.Scalar.bankersRound`](haskell/HMath-Scalar.md#v:bankersRound). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_bankers_round_f32(
    hmath_context *context,
    float x,
    char **out0);
```

```c
hmath_status hmath_scalar_bankers_round_f64(
    hmath_context *context,
    double x,
    char **out0);
```

## `scalar.integer_fraction`

`scalar.integer_fraction(x, *, dtype='float64')`

Original: [`HMath.Scalar.integerFraction`](haskell/HMath-Scalar.md#v:integerFraction). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_integer_fraction_f32(
    hmath_context *context,
    float x,
    char **out0,
    float *out1);
```

```c
hmath_status hmath_scalar_integer_fraction_f64(
    hmath_context *context,
    double x,
    char **out0,
    double *out1);
```

## `scalar.quotient_remainder`

`scalar.quotient_remainder(a, b)`

Original: [`HMath.Scalar.quotientRemainder`](haskell/HMath-Scalar.md#v:quotientRemainder). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_quotient_remainder(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0,
    char **out1);
```

## `scalar.euclidean_division`

`scalar.euclidean_division(a, b)`

Original: [`HMath.Scalar.euclideanDivision`](haskell/HMath-Scalar.md#v:euclideanDivision). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_euclidean_division(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0,
    char **out1);
```

## `scalar.positive_modulo`

`scalar.positive_modulo(a, modulus, *, dtype='integer')`

Original: [`HMath.Scalar.positiveModulo`](haskell/HMath-Scalar.md#v:positiveModulo). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`.

```c
hmath_status hmath_scalar_positive_modulo_integer(
    hmath_context *context,
    const char *a,
    const char *modulus,
    char **out0);
```

```c
hmath_status hmath_scalar_positive_modulo_i8(
    hmath_context *context,
    int8_t a,
    int8_t modulus,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_positive_modulo_i16(
    hmath_context *context,
    int16_t a,
    int16_t modulus,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_positive_modulo_i32(
    hmath_context *context,
    int32_t a,
    int32_t modulus,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_positive_modulo_i64(
    hmath_context *context,
    int64_t a,
    int64_t modulus,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_positive_modulo_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t modulus,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_positive_modulo_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t modulus,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_positive_modulo_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t modulus,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_positive_modulo_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t modulus,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_positive_modulo_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t modulus,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_positive_modulo_word(
    hmath_context *context,
    size_t a,
    size_t modulus,
    size_t *out0);
```

```c
hmath_status hmath_scalar_positive_modulo(
    hmath_context *context,
    const char *a,
    const char *modulus,
    char **out0);
```

## `scalar.modular_power`

`scalar.modular_power(a, n, modulus)`

Original: [`HMath.Scalar.modularPower`](haskell/HMath-Scalar.md#v:modularPower). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_modular_power(
    hmath_context *context,
    const char *a,
    const char *n,
    const char *modulus,
    char **out0);
```

## `scalar.factorial_checked`

`scalar.factorial_checked(n)`

Original: [`HMath.Scalar.factorialChecked`](haskell/HMath-Scalar.md#v:factorialChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_factorial_checked(
    hmath_context *context,
    const char *n,
    char **out0);
```

## `scalar.double_factorial`

`scalar.double_factorial(n)`

Original: [`HMath.Scalar.doubleFactorial`](haskell/HMath-Scalar.md#v:doubleFactorial). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_double_factorial(
    hmath_context *context,
    const char *n,
    char **out0);
```

## `scalar.fibonacci_checked`

`scalar.fibonacci_checked(n)`

Original: [`HMath.Scalar.fibonacciChecked`](haskell/HMath-Scalar.md#v:fibonacciChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_fibonacci_checked(
    hmath_context *context,
    const char *n,
    char **out0);
```

## `scalar.lucas`

`scalar.lucas(n)`

Original: [`HMath.Scalar.lucas`](haskell/HMath-Scalar.md#v:lucas). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_lucas(
    hmath_context *context,
    const char *n,
    char **out0);
```

## `scalar.catalan`

`scalar.catalan(n)`

Original: [`HMath.Scalar.catalan`](haskell/HMath-Scalar.md#v:catalan). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_catalan(
    hmath_context *context,
    const char *n,
    char **out0);
```

## `scalar.rising_factorial`

`scalar.rising_factorial(x, n)`

Original: [`HMath.Scalar.risingFactorial`](haskell/HMath-Scalar.md#v:risingFactorial). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_rising_factorial(
    hmath_context *context,
    const char *x,
    const char *n,
    char **out0);
```

## `scalar.falling_factorial`

`scalar.falling_factorial(x, n)`

Original: [`HMath.Scalar.fallingFactorial`](haskell/HMath-Scalar.md#v:fallingFactorial). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_falling_factorial(
    hmath_context *context,
    const char *x,
    const char *n,
    char **out0);
```

## `scalar.permutations`

`scalar.permutations(n, k)`

Original: [`HMath.Scalar.permutations`](haskell/HMath-Scalar.md#v:permutations). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_permutations(
    hmath_context *context,
    const char *n,
    const char *k,
    char **out0);
```

## `scalar.combinations`

`scalar.combinations(n, k)`

Original: [`HMath.Scalar.combinations`](haskell/HMath-Scalar.md#v:combinations). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_combinations(
    hmath_context *context,
    const char *n,
    const char *k,
    char **out0);
```

## `scalar.bernoulli`

`scalar.bernoulli(n)`

Original: [`HMath.Scalar.bernoulli`](haskell/HMath-Scalar.md#v:bernoulli). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_bernoulli(
    hmath_context *context,
    ptrdiff_t n,
    char **out0,
    char **out1);
```

## `scalar.harmonic`

`scalar.harmonic(n)`

Original: [`HMath.Scalar.harmonic`](haskell/HMath-Scalar.md#v:harmonic). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_harmonic(
    hmath_context *context,
    const char *n,
    char **out0,
    char **out1);
```

## `scalar.cumulative_sum`

`scalar.cumulative_sum(values, *, dtype='float64')`

Original: [`HMath.Scalar.cumulativeSum`](haskell/HMath-Scalar.md#v:cumulativeSum). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_scalar_cumulative_sum_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0,
    size_t out_capacity);
```

```c
hmath_status hmath_scalar_cumulative_sum_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0,
    size_t out_capacity);
```

```c
hmath_status hmath_scalar_cumulative_sum_rational(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_sum_integer(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_sum_i8(
    hmath_context *context,
    const int8_t *values,
    size_t values_count,
    int8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_sum_i16(
    hmath_context *context,
    const int16_t *values,
    size_t values_count,
    int16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_sum_i32(
    hmath_context *context,
    const int32_t *values,
    size_t values_count,
    int32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_sum_i64(
    hmath_context *context,
    const int64_t *values,
    size_t values_count,
    int64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_sum_u8(
    hmath_context *context,
    const uint8_t *values,
    size_t values_count,
    uint8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_sum_u16(
    hmath_context *context,
    const uint16_t *values,
    size_t values_count,
    uint16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_sum_u32(
    hmath_context *context,
    const uint32_t *values,
    size_t values_count,
    uint32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_sum_u64(
    hmath_context *context,
    const uint64_t *values,
    size_t values_count,
    uint64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_sum_int(
    hmath_context *context,
    const ptrdiff_t *values,
    size_t values_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_sum_word(
    hmath_context *context,
    const size_t *values,
    size_t values_count,
    size_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_sum_c64(
    hmath_context *context,
    float const *values,
    size_t values_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_sum_c128(
    hmath_context *context,
    double const *values,
    size_t values_count,
    double **out_data,
    size_t *out_count);
```

## `scalar.cumulative_product`

`scalar.cumulative_product(values, *, dtype='float64')`

Original: [`HMath.Scalar.cumulativeProduct`](haskell/HMath-Scalar.md#v:cumulativeProduct). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_scalar_cumulative_product_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0,
    size_t out_capacity);
```

```c
hmath_status hmath_scalar_cumulative_product_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0,
    size_t out_capacity);
```

```c
hmath_status hmath_scalar_cumulative_product_rational(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_product_integer(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_product_i8(
    hmath_context *context,
    const int8_t *values,
    size_t values_count,
    int8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_product_i16(
    hmath_context *context,
    const int16_t *values,
    size_t values_count,
    int16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_product_i32(
    hmath_context *context,
    const int32_t *values,
    size_t values_count,
    int32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_product_i64(
    hmath_context *context,
    const int64_t *values,
    size_t values_count,
    int64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_product_u8(
    hmath_context *context,
    const uint8_t *values,
    size_t values_count,
    uint8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_product_u16(
    hmath_context *context,
    const uint16_t *values,
    size_t values_count,
    uint16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_product_u32(
    hmath_context *context,
    const uint32_t *values,
    size_t values_count,
    uint32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_product_u64(
    hmath_context *context,
    const uint64_t *values,
    size_t values_count,
    uint64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_product_int(
    hmath_context *context,
    const ptrdiff_t *values,
    size_t values_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_product_word(
    hmath_context *context,
    const size_t *values,
    size_t values_count,
    size_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_product_c64(
    hmath_context *context,
    float const *values,
    size_t values_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_cumulative_product_c128(
    hmath_context *context,
    double const *values,
    size_t values_count,
    double **out_data,
    size_t *out_count);
```

## `scalar.prefix_sum`

`scalar.prefix_sum(values, *, dtype='float64')`

Original: [`HMath.Scalar.prefixSum`](haskell/HMath-Scalar.md#v:prefixSum). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_scalar_prefix_sum_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0,
    size_t out_capacity);
```

```c
hmath_status hmath_scalar_prefix_sum_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0,
    size_t out_capacity);
```

```c
hmath_status hmath_scalar_prefix_sum_rational(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_prefix_sum_integer(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_prefix_sum_i8(
    hmath_context *context,
    const int8_t *values,
    size_t values_count,
    int8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_prefix_sum_i16(
    hmath_context *context,
    const int16_t *values,
    size_t values_count,
    int16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_prefix_sum_i32(
    hmath_context *context,
    const int32_t *values,
    size_t values_count,
    int32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_prefix_sum_i64(
    hmath_context *context,
    const int64_t *values,
    size_t values_count,
    int64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_prefix_sum_u8(
    hmath_context *context,
    const uint8_t *values,
    size_t values_count,
    uint8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_prefix_sum_u16(
    hmath_context *context,
    const uint16_t *values,
    size_t values_count,
    uint16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_prefix_sum_u32(
    hmath_context *context,
    const uint32_t *values,
    size_t values_count,
    uint32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_prefix_sum_u64(
    hmath_context *context,
    const uint64_t *values,
    size_t values_count,
    uint64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_prefix_sum_int(
    hmath_context *context,
    const ptrdiff_t *values,
    size_t values_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_prefix_sum_word(
    hmath_context *context,
    const size_t *values,
    size_t values_count,
    size_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_prefix_sum_c64(
    hmath_context *context,
    float const *values,
    size_t values_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_scalar_prefix_sum_c128(
    hmath_context *context,
    double const *values,
    size_t values_count,
    double **out_data,
    size_t *out_count);
```

## `trigonometry.sin_checked`

`trigonometry.sin_checked(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.sinChecked`](haskell/HMath-Trigonometry.md#v:sinChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_sin_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_sin_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.cos_checked`

`trigonometry.cos_checked(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.cosChecked`](haskell/HMath-Trigonometry.md#v:cosChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_cos_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_cos_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.tan_checked`

`trigonometry.tan_checked(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.tanChecked`](haskell/HMath-Trigonometry.md#v:tanChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_tan_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_tan_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.asin_checked`

`trigonometry.asin_checked(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.asinChecked`](haskell/HMath-Trigonometry.md#v:asinChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_asin_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_asin_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.acos_checked`

`trigonometry.acos_checked(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.acosChecked`](haskell/HMath-Trigonometry.md#v:acosChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_acos_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_acos_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.atan_checked`

`trigonometry.atan_checked(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.atanChecked`](haskell/HMath-Trigonometry.md#v:atanChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_atan_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_atan_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.sec`

`trigonometry.sec(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.sec`](haskell/HMath-Trigonometry.md#v:sec). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_sec_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_sec_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.csc`

`trigonometry.csc(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.csc`](haskell/HMath-Trigonometry.md#v:csc). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_csc_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_csc_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.cot`

`trigonometry.cot(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.cot`](haskell/HMath-Trigonometry.md#v:cot). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_cot_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_cot_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.asec`

`trigonometry.asec(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.asec`](haskell/HMath-Trigonometry.md#v:asec). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_asec_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_asec_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.acsc`

`trigonometry.acsc(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.acsc`](haskell/HMath-Trigonometry.md#v:acsc). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_acsc_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_acsc_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.acot`

`trigonometry.acot(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.acot`](haskell/HMath-Trigonometry.md#v:acot). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_acot_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_acot_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.sinh_checked`

`trigonometry.sinh_checked(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.sinhChecked`](haskell/HMath-Trigonometry.md#v:sinhChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_sinh_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_sinh_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.cosh_checked`

`trigonometry.cosh_checked(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.coshChecked`](haskell/HMath-Trigonometry.md#v:coshChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_cosh_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_cosh_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.tanh_checked`

`trigonometry.tanh_checked(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.tanhChecked`](haskell/HMath-Trigonometry.md#v:tanhChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_tanh_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_tanh_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.asinh_checked`

`trigonometry.asinh_checked(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.asinhChecked`](haskell/HMath-Trigonometry.md#v:asinhChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_asinh_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_asinh_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.acosh_checked`

`trigonometry.acosh_checked(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.acoshChecked`](haskell/HMath-Trigonometry.md#v:acoshChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_acosh_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_acosh_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.atanh_checked`

`trigonometry.atanh_checked(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.atanhChecked`](haskell/HMath-Trigonometry.md#v:atanhChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_atanh_checked_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_atanh_checked_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.sech`

`trigonometry.sech(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.sech`](haskell/HMath-Trigonometry.md#v:sech). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_sech_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_sech_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.csch`

`trigonometry.csch(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.csch`](haskell/HMath-Trigonometry.md#v:csch). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_csch_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_csch_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.coth`

`trigonometry.coth(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.coth`](haskell/HMath-Trigonometry.md#v:coth). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_coth_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_coth_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.asech`

`trigonometry.asech(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.asech`](haskell/HMath-Trigonometry.md#v:asech). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_asech_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_asech_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.acsch`

`trigonometry.acsch(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.acsch`](haskell/HMath-Trigonometry.md#v:acsch). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_acsch_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_acsch_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.acoth`

`trigonometry.acoth(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.acoth`](haskell/HMath-Trigonometry.md#v:acoth). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_acoth_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_acoth_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.normalize_angle`

`trigonometry.normalize_angle(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.normalizeAngle`](haskell/HMath-Trigonometry.md#v:normalizeAngle). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_normalize_angle_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_normalize_angle_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.normalize_signed_angle`

`trigonometry.normalize_signed_angle(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.normalizeSignedAngle`](haskell/HMath-Trigonometry.md#v:normalizeSignedAngle). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_normalize_signed_angle_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_normalize_signed_angle_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.versine`

`trigonometry.versine(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.versine`](haskell/HMath-Trigonometry.md#v:versine). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_versine_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_versine_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.haversine`

`trigonometry.haversine(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.haversine`](haskell/HMath-Trigonometry.md#v:haversine). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_haversine_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_haversine_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.sinc`

`trigonometry.sinc(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.sinc`](haskell/HMath-Trigonometry.md#v:sinc). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_sinc_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_sinc_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.cosc`

`trigonometry.cosc(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.cosc`](haskell/HMath-Trigonometry.md#v:cosc). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_cosc_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_cosc_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `trigonometry.atan2_checked`

`trigonometry.atan2_checked(y, x, *, dtype='float64')`

Original: [`HMath.Trigonometry.atan2Checked`](haskell/HMath-Trigonometry.md#v:atan2Checked). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_atan2_checked_f32(
    hmath_context *context,
    float y,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_atan2_checked_f64(
    hmath_context *context,
    double y,
    double x,
    double *out0);
```

## `trigonometry.sincos`

`trigonometry.sincos(x, *, dtype='float64')`

Original: [`HMath.Trigonometry.sincos`](haskell/HMath-Trigonometry.md#v:sincos). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_sincos_f32(
    hmath_context *context,
    float x,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_trigonometry_sincos_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1);
```

## `trigonometry.wrap`

`trigonometry.wrap(low, high, x, *, dtype='float64')`

Original: [`HMath.Trigonometry.wrap`](haskell/HMath-Trigonometry.md#v:wrap). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_wrap_f32(
    hmath_context *context,
    float low,
    float high,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_wrap_f64(
    hmath_context *context,
    double low,
    double high,
    double x,
    double *out0);
```

## `trigonometry.angle_difference`

`trigonometry.angle_difference(a, b, *, dtype='float64')`

Original: [`HMath.Trigonometry.angleDifference`](haskell/HMath-Trigonometry.md#v:angleDifference). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_angle_difference_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0);
```

```c
hmath_status hmath_trigonometry_angle_difference_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0);
```

## `trigonometry.great_circle_angle`

`trigonometry.great_circle_angle(a, b, *, dtype='float64')`

Original: [`HMath.Trigonometry.greatCircleAngle`](haskell/HMath-Trigonometry.md#v:greatCircleAngle). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_great_circle_angle_f32(
    hmath_context *context,
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0);
```

```c
hmath_status hmath_trigonometry_great_circle_angle_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0);
```

## `trigonometry.great_circle_distance`

`trigonometry.great_circle_distance(radius, a, b, *, dtype='float64')`

Original: [`HMath.Trigonometry.greatCircleDistance`](haskell/HMath-Trigonometry.md#v:greatCircleDistance). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_great_circle_distance_f32(
    hmath_context *context,
    float radius,
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0);
```

```c
hmath_status hmath_trigonometry_great_circle_distance_f64(
    hmath_context *context,
    double radius,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0);
```

## `trigonometry.spherical_side`

`trigonometry.spherical_side(a, b, included, *, dtype='float64')`

Original: [`HMath.Trigonometry.sphericalSide`](haskell/HMath-Trigonometry.md#v:sphericalSide). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_spherical_side_f32(
    hmath_context *context,
    float a,
    float b,
    float included,
    float *out0);
```

```c
hmath_status hmath_trigonometry_spherical_side_f64(
    hmath_context *context,
    double a,
    double b,
    double included,
    double *out0);
```

## `trigonometry.spherical_angles`

`trigonometry.spherical_angles(a, b, c, *, dtype='float64')`

Original: [`HMath.Trigonometry.sphericalAngles`](haskell/HMath-Trigonometry.md#v:sphericalAngles). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_spherical_angles_f32(
    hmath_context *context,
    float a,
    float b,
    float c,
    float *out0,
    float *out1,
    float *out2);
```

```c
hmath_status hmath_trigonometry_spherical_angles_f64(
    hmath_context *context,
    double a,
    double b,
    double c,
    double *out0,
    double *out1,
    double *out2);
```

## `trigonometry.spherical_excess`

`trigonometry.spherical_excess(a, b, c, *, dtype='float64')`

Original: [`HMath.Trigonometry.sphericalExcess`](haskell/HMath-Trigonometry.md#v:sphericalExcess). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_spherical_excess_f32(
    hmath_context *context,
    float a,
    float b,
    float c,
    float *out0);
```

```c
hmath_status hmath_trigonometry_spherical_excess_f64(
    hmath_context *context,
    double a,
    double b,
    double c,
    double *out0);
```

## `trigonometry.complex_sin`

`trigonometry.complex_sin(z, *, dtype='float64')`

Original: [`HMath.Trigonometry.complexSin`](haskell/HMath-Trigonometry.md#v:complexSin). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_complex_sin_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_trigonometry_complex_sin_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `trigonometry.complex_cos`

`trigonometry.complex_cos(z, *, dtype='float64')`

Original: [`HMath.Trigonometry.complexCos`](haskell/HMath-Trigonometry.md#v:complexCos). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_complex_cos_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_trigonometry_complex_cos_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `trigonometry.complex_tan`

`trigonometry.complex_tan(z, *, dtype='float64')`

Original: [`HMath.Trigonometry.complexTan`](haskell/HMath-Trigonometry.md#v:complexTan). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_complex_tan_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_trigonometry_complex_tan_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `trigonometry.complex_asin`

`trigonometry.complex_asin(z, *, dtype='float64')`

Original: [`HMath.Trigonometry.complexAsin`](haskell/HMath-Trigonometry.md#v:complexAsin). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_complex_asin_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_trigonometry_complex_asin_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `trigonometry.complex_acos`

`trigonometry.complex_acos(z, *, dtype='float64')`

Original: [`HMath.Trigonometry.complexAcos`](haskell/HMath-Trigonometry.md#v:complexAcos). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_complex_acos_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_trigonometry_complex_acos_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `trigonometry.complex_atan`

`trigonometry.complex_atan(z, *, dtype='float64')`

Original: [`HMath.Trigonometry.complexAtan`](haskell/HMath-Trigonometry.md#v:complexAtan). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_complex_atan_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_trigonometry_complex_atan_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `trigonometry.complex_sinh`

`trigonometry.complex_sinh(z, *, dtype='float64')`

Original: [`HMath.Trigonometry.complexSinh`](haskell/HMath-Trigonometry.md#v:complexSinh). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_complex_sinh_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_trigonometry_complex_sinh_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `trigonometry.complex_cosh`

`trigonometry.complex_cosh(z, *, dtype='float64')`

Original: [`HMath.Trigonometry.complexCosh`](haskell/HMath-Trigonometry.md#v:complexCosh). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_complex_cosh_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_trigonometry_complex_cosh_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `trigonometry.complex_tanh`

`trigonometry.complex_tanh(z, *, dtype='float64')`

Original: [`HMath.Trigonometry.complexTanh`](haskell/HMath-Trigonometry.md#v:complexTanh). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_complex_tanh_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_trigonometry_complex_tanh_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `trigonometry.complex_asinh`

`trigonometry.complex_asinh(z, *, dtype='float64')`

Original: [`HMath.Trigonometry.complexAsinh`](haskell/HMath-Trigonometry.md#v:complexAsinh). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_complex_asinh_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_trigonometry_complex_asinh_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `trigonometry.complex_acosh`

`trigonometry.complex_acosh(z, *, dtype='float64')`

Original: [`HMath.Trigonometry.complexAcosh`](haskell/HMath-Trigonometry.md#v:complexAcosh). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_complex_acosh_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_trigonometry_complex_acosh_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `trigonometry.complex_atanh`

`trigonometry.complex_atanh(z, *, dtype='float64')`

Original: [`HMath.Trigonometry.complexAtanh`](haskell/HMath-Trigonometry.md#v:complexAtanh). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_complex_atanh_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_trigonometry_complex_atanh_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `trigonometry.periodic_sawtooth`

`trigonometry.periodic_sawtooth(period, x, *, dtype='float64')`

Original: [`HMath.Trigonometry.periodicSawtooth`](haskell/HMath-Trigonometry.md#v:periodicSawtooth). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_periodic_sawtooth_f32(
    hmath_context *context,
    float period,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_periodic_sawtooth_f64(
    hmath_context *context,
    double period,
    double x,
    double *out0);
```

## `trigonometry.periodic_triangle`

`trigonometry.periodic_triangle(period, x, *, dtype='float64')`

Original: [`HMath.Trigonometry.periodicTriangle`](haskell/HMath-Trigonometry.md#v:periodicTriangle). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_periodic_triangle_f32(
    hmath_context *context,
    float period,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_periodic_triangle_f64(
    hmath_context *context,
    double period,
    double x,
    double *out0);
```

## `trigonometry.periodic_square`

`trigonometry.periodic_square(period, x, *, dtype='float64')`

Original: [`HMath.Trigonometry.periodicSquare`](haskell/HMath-Trigonometry.md#v:periodicSquare). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_trigonometry_periodic_square_f32(
    hmath_context *context,
    float period,
    float x,
    float *out0);
```

```c
hmath_status hmath_trigonometry_periodic_square_f64(
    hmath_context *context,
    double period,
    double x,
    double *out0);
```

## `statistics.mean`

`statistics.mean(values, *, dtype='float64')`

Original: [`HMath.Statistics.mean`](haskell/HMath-Statistics.md#v:mean). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `complex64`, `complex128`.

```c
hmath_status hmath_statistics_mean_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0);
```

```c
hmath_status hmath_statistics_mean_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0);
```

```c
hmath_status hmath_statistics_mean_rational(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char **out0,
    char **out1);
```

```c
hmath_status hmath_statistics_mean_c64(
    hmath_context *context,
    float const *values,
    size_t values_count,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_statistics_mean_c128(
    hmath_context *context,
    double const *values,
    size_t values_count,
    double *out0,
    double *out1);
```

## `statistics.variance`

`statistics.variance(values, *, dtype='float64')`

Original: [`HMath.Statistics.variance`](haskell/HMath-Statistics.md#v:variance). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `complex64`, `complex128`.

```c
hmath_status hmath_statistics_variance_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0);
```

```c
hmath_status hmath_statistics_variance_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0);
```

```c
hmath_status hmath_statistics_variance_rational(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char **out0,
    char **out1);
```

```c
hmath_status hmath_statistics_variance_c64(
    hmath_context *context,
    float const *values,
    size_t values_count,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_statistics_variance_c128(
    hmath_context *context,
    double const *values,
    size_t values_count,
    double *out0,
    double *out1);
```

## `statistics.standard_deviation`

`statistics.standard_deviation(values, *, dtype='float64')`

Original: [`HMath.Statistics.standardDeviation`](haskell/HMath-Statistics.md#v:standardDeviation). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `complex64`, `complex128`.

```c
hmath_status hmath_statistics_standard_deviation_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0);
```

```c
hmath_status hmath_statistics_standard_deviation_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0);
```

```c
hmath_status hmath_statistics_standard_deviation_c64(
    hmath_context *context,
    float const *values,
    size_t values_count,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_statistics_standard_deviation_c128(
    hmath_context *context,
    double const *values,
    size_t values_count,
    double *out0,
    double *out1);
```

## `statistics.median`

`statistics.median(values, *, dtype='float64')`

Original: [`HMath.Statistics.median`](haskell/HMath-Statistics.md#v:median). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`.

```c
hmath_status hmath_statistics_median_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0);
```

```c
hmath_status hmath_statistics_median_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0);
```

```c
hmath_status hmath_statistics_median_rational(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char **out0,
    char **out1);
```

## `constants.pi_constant`

`constants.pi_constant(*, dtype='float64')`

Original: [`HMath.Constants.piConstant`](haskell/HMath-Constants.md#v:piConstant). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_constants_pi_constant_f32(
    hmath_context *context,
    float *out0);
```

```c
hmath_status hmath_constants_pi_constant_f64(
    hmath_context *context,
    double *out0);
```

## `constants.e_constant`

`constants.e_constant(*, dtype='float64')`

Original: [`HMath.Constants.eConstant`](haskell/HMath-Constants.md#v:eConstant). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_constants_e_constant_f32(
    hmath_context *context,
    float *out0);
```

```c
hmath_status hmath_constants_e_constant_f64(
    hmath_context *context,
    double *out0);
```

## `constants.tau`

`constants.tau(*, dtype='float64')`

Original: [`HMath.Constants.tau`](haskell/HMath-Constants.md#v:tau). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_constants_tau_f32(
    hmath_context *context,
    float *out0);
```

```c
hmath_status hmath_constants_tau_f64(
    hmath_context *context,
    double *out0);
```

## `constants.golden_ratio`

`constants.golden_ratio(*, dtype='float64')`

Original: [`HMath.Constants.goldenRatio`](haskell/HMath-Constants.md#v:goldenRatio). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_constants_golden_ratio_f32(
    hmath_context *context,
    float *out0);
```

```c
hmath_status hmath_constants_golden_ratio_f64(
    hmath_context *context,
    double *out0);
```

## `constants.euler_mascheroni`

`constants.euler_mascheroni(*, dtype='float64')`

Original: [`HMath.Constants.eulerMascheroni`](haskell/HMath-Constants.md#v:eulerMascheroni). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_constants_euler_mascheroni_f32(
    hmath_context *context,
    float *out0);
```

```c
hmath_status hmath_constants_euler_mascheroni_f64(
    hmath_context *context,
    double *out0);
```

## `constants.catalan_constant`

`constants.catalan_constant(*, dtype='float64')`

Original: [`HMath.Constants.catalanConstant`](haskell/HMath-Constants.md#v:catalanConstant). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_constants_catalan_constant_f32(
    hmath_context *context,
    float *out0);
```

```c
hmath_status hmath_constants_catalan_constant_f64(
    hmath_context *context,
    double *out0);
```

## `constants.apery_constant`

`constants.apery_constant(*, dtype='float64')`

Original: [`HMath.Constants.aperyConstant`](haskell/HMath-Constants.md#v:aperyConstant). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_constants_apery_constant_f32(
    hmath_context *context,
    float *out0);
```

```c
hmath_status hmath_constants_apery_constant_f64(
    hmath_context *context,
    double *out0);
```

## `constants.sqrt2`

`constants.sqrt2(*, dtype='float64')`

Original: [`HMath.Constants.sqrt2`](haskell/HMath-Constants.md#v:sqrt2). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_constants_sqrt2_f32(
    hmath_context *context,
    float *out0);
```

```c
hmath_status hmath_constants_sqrt2_f64(
    hmath_context *context,
    double *out0);
```

## `constants.sqrt3`

`constants.sqrt3(*, dtype='float64')`

Original: [`HMath.Constants.sqrt3`](haskell/HMath-Constants.md#v:sqrt3). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_constants_sqrt3_f32(
    hmath_context *context,
    float *out0);
```

```c
hmath_status hmath_constants_sqrt3_f64(
    hmath_context *context,
    double *out0);
```

## `constants.ln2`

`constants.ln2(*, dtype='float64')`

Original: [`HMath.Constants.ln2`](haskell/HMath-Constants.md#v:ln2). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_constants_ln2_f32(
    hmath_context *context,
    float *out0);
```

```c
hmath_status hmath_constants_ln2_f64(
    hmath_context *context,
    double *out0);
```

## `constants.ln10`

`constants.ln10(*, dtype='float64')`

Original: [`HMath.Constants.ln10`](haskell/HMath-Constants.md#v:ln10). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_constants_ln10_f32(
    hmath_context *context,
    float *out0);
```

```c
hmath_status hmath_constants_ln10_f64(
    hmath_context *context,
    double *out0);
```

## `constants.infinity`

`constants.infinity(*, dtype='float64')`

Original: [`HMath.Constants.infinity`](haskell/HMath-Constants.md#v:infinity). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_constants_infinity_f32(
    hmath_context *context,
    float *out0);
```

```c
hmath_status hmath_constants_infinity_f64(
    hmath_context *context,
    double *out0);
```

## `constants.nan`

`constants.nan(*, dtype='float64')`

Original: [`HMath.Constants.nan`](haskell/HMath-Constants.md#v:nan). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_constants_nan_f32(
    hmath_context *context,
    float *out0);
```

```c
hmath_status hmath_constants_nan_f64(
    hmath_context *context,
    double *out0);
```

## `scalar.multinomial`

`scalar.multinomial(ks)`

Original: [`HMath.Scalar.multinomial`](haskell/HMath-Scalar.md#v:multinomial). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_scalar_multinomial(
    hmath_context *context,
    const char * const *ks,
    size_t ks_count,
    char **out0);
```

## `numbertheory.gcd_integer`

`numbertheory.gcd_integer(argument1, argument2)`

Original: [`HMath.NumberTheory.gcdInteger`](haskell/HMath-NumberTheory.md#v:gcdInteger). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_gcd_integer(
    hmath_context *context,
    const char *argument1,
    const char *argument2,
    char **out0);
```

## `numbertheory.lcm_integer`

`numbertheory.lcm_integer(argument1, argument2)`

Original: [`HMath.NumberTheory.lcmInteger`](haskell/HMath-NumberTheory.md#v:lcmInteger). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_lcm_integer(
    hmath_context *context,
    const char *argument1,
    const char *argument2,
    char **out0);
```

## `numbertheory.extended_g_c_d`

`numbertheory.extended_g_c_d(a, b)`

Original: [`HMath.NumberTheory.extendedGCD`](haskell/HMath-NumberTheory.md#v:extendedGCD). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_extended_g_c_d(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0,
    char **out1,
    char **out2);
```

## `numbertheory.bezout`

`numbertheory.bezout(a, b)`

Original: [`HMath.NumberTheory.bezout`](haskell/HMath-NumberTheory.md#v:bezout). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_bezout(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0,
    char **out1);
```

## `numbertheory.mod_pow`

`numbertheory.mod_pow(a, e, m)`

Original: [`HMath.NumberTheory.modPow`](haskell/HMath-NumberTheory.md#v:modPow). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_mod_pow(
    hmath_context *context,
    const char *a,
    const char *e,
    const char *m,
    char **out0);
```

## `numbertheory.mod_inverse`

`numbertheory.mod_inverse(a, m)`

Original: [`HMath.NumberTheory.modInverse`](haskell/HMath-NumberTheory.md#v:modInverse). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_mod_inverse(
    hmath_context *context,
    const char *a,
    const char *m,
    char **out0);
```

## `numbertheory.integer_square_root`

`numbertheory.integer_square_root(n)`

Original: [`HMath.NumberTheory.integerSquareRoot`](haskell/HMath-NumberTheory.md#v:integerSquareRoot). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_integer_square_root(
    hmath_context *context,
    const char *n,
    char **out0);
```

## `numbertheory.is_prime_exact`

`numbertheory.is_prime_exact(budget, n)`

Original: [`HMath.NumberTheory.isPrimeExact`](haskell/HMath-NumberTheory.md#v:isPrimeExact). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_is_prime_exact(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    int *out0);
```

## `numbertheory.next_prime`

`numbertheory.next_prime(budget, n)`

Original: [`HMath.NumberTheory.nextPrime`](haskell/HMath-NumberTheory.md#v:nextPrime). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_next_prime(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0);
```

## `numbertheory.miller_rabin`

`numbertheory.miller_rabin(bases, n)`

Original: [`HMath.NumberTheory.millerRabin`](haskell/HMath-NumberTheory.md#v:millerRabin). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_miller_rabin(
    hmath_context *context,
    const char * const *bases,
    size_t bases_count,
    const char *n,
    int *out0);
```

## `numbertheory.baillie_p_s_w`

`numbertheory.baillie_p_s_w(n)`

Original: [`HMath.NumberTheory.bailliePSW`](haskell/HMath-NumberTheory.md#v:bailliePSW). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_baillie_p_s_w(
    hmath_context *context,
    const char *n,
    int *out0);
```

## `numbertheory.sieve_eratosthenes`

`numbertheory.sieve_eratosthenes(bound)`

Original: [`HMath.NumberTheory.sieveEratosthenes`](haskell/HMath-NumberTheory.md#v:sieveEratosthenes). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_sieve_eratosthenes(
    hmath_context *context,
    ptrdiff_t bound,
    char * **out_data,
    size_t *out_count);
```

## `numbertheory.sieve_atkin`

`numbertheory.sieve_atkin(bound)`

Original: [`HMath.NumberTheory.sieveAtkin`](haskell/HMath-NumberTheory.md#v:sieveAtkin). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_sieve_atkin(
    hmath_context *context,
    ptrdiff_t bound,
    char * **out_data,
    size_t *out_count);
```

## `numbertheory.segmented_sieve`

`numbertheory.segmented_sieve(lo, hi)`

Original: [`HMath.NumberTheory.segmentedSieve`](haskell/HMath-NumberTheory.md#v:segmentedSieve). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_segmented_sieve(
    hmath_context *context,
    const char *lo,
    const char *hi,
    char * **out_data,
    size_t *out_count);
```

## `numbertheory.pollard_rho`

`numbertheory.pollard_rho(budget, seed, n)`

Original: [`HMath.NumberTheory.pollardRho`](haskell/HMath-NumberTheory.md#v:pollardRho). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_pollard_rho(
    hmath_context *context,
    ptrdiff_t budget,
    const char *seed,
    const char *n,
    char **out0);
```

## `numbertheory.pollard_p_minus_one`

`numbertheory.pollard_p_minus_one(bound, base, n)`

Original: [`HMath.NumberTheory.pollardPMinusOne`](haskell/HMath-NumberTheory.md#v:pollardPMinusOne). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_pollard_p_minus_one(
    hmath_context *context,
    ptrdiff_t bound,
    const char *base,
    const char *n,
    char **out0);
```

## `numbertheory.fermat_factor`

`numbertheory.fermat_factor(budget, n)`

Original: [`HMath.NumberTheory.fermatFactor`](haskell/HMath-NumberTheory.md#v:fermatFactor). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_fermat_factor(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0);
```

## `numbertheory.divisors`

`numbertheory.divisors(budget, n)`

Original: [`HMath.NumberTheory.divisors`](haskell/HMath-NumberTheory.md#v:divisors). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_divisors(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char * **out_data,
    size_t *out_count);
```

## `numbertheory.divisor_sum`

`numbertheory.divisor_sum(budget, n)`

Original: [`HMath.NumberTheory.divisorSum`](haskell/HMath-NumberTheory.md#v:divisorSum). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_divisor_sum(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0);
```

## `numbertheory.divisor_count`

`numbertheory.divisor_count(budget, n)`

Original: [`HMath.NumberTheory.divisorCount`](haskell/HMath-NumberTheory.md#v:divisorCount). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_divisor_count(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0);
```

## `numbertheory.euler_totient`

`numbertheory.euler_totient(budget, n)`

Original: [`HMath.NumberTheory.eulerTotient`](haskell/HMath-NumberTheory.md#v:eulerTotient). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_euler_totient(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0);
```

## `numbertheory.carmichael`

`numbertheory.carmichael(budget, n)`

Original: [`HMath.NumberTheory.carmichael`](haskell/HMath-NumberTheory.md#v:carmichael). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_carmichael(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0);
```

## `numbertheory.mobius`

`numbertheory.mobius(budget, n)`

Original: [`HMath.NumberTheory.mobius`](haskell/HMath-NumberTheory.md#v:mobius). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_mobius(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0);
```

## `numbertheory.liouville`

`numbertheory.liouville(budget, n)`

Original: [`HMath.NumberTheory.liouville`](haskell/HMath-NumberTheory.md#v:liouville). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_liouville(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0);
```

## `numbertheory.multiplicative_order`

`numbertheory.multiplicative_order(budget, a, m)`

Original: [`HMath.NumberTheory.multiplicativeOrder`](haskell/HMath-NumberTheory.md#v:multiplicativeOrder). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_multiplicative_order(
    hmath_context *context,
    ptrdiff_t budget,
    const char *a,
    const char *m,
    char **out0);
```

## `numbertheory.primitive_root`

`numbertheory.primitive_root(budget, m)`

Original: [`HMath.NumberTheory.primitiveRoot`](haskell/HMath-NumberTheory.md#v:primitiveRoot). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_primitive_root(
    hmath_context *context,
    ptrdiff_t budget,
    const char *m,
    char **out0);
```

## `numbertheory.discrete_log`

`numbertheory.discrete_log(budget, a, b, m)`

Original: [`HMath.NumberTheory.discreteLog`](haskell/HMath-NumberTheory.md#v:discreteLog). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_discrete_log(
    hmath_context *context,
    ptrdiff_t budget,
    const char *a,
    const char *b,
    const char *m,
    char **out0);
```

## `numbertheory.legendre_symbol`

`numbertheory.legendre_symbol(budget, a, p)`

Original: [`HMath.NumberTheory.legendreSymbol`](haskell/HMath-NumberTheory.md#v:legendreSymbol). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_legendre_symbol(
    hmath_context *context,
    ptrdiff_t budget,
    const char *a,
    const char *p,
    char **out0);
```

## `numbertheory.jacobi_symbol`

`numbertheory.jacobi_symbol(a, n)`

Original: [`HMath.NumberTheory.jacobiSymbol`](haskell/HMath-NumberTheory.md#v:jacobiSymbol). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_jacobi_symbol(
    hmath_context *context,
    const char *a,
    const char *n,
    char **out0);
```

## `numbertheory.kronecker_symbol`

`numbertheory.kronecker_symbol(a, n)`

Original: [`HMath.NumberTheory.kroneckerSymbol`](haskell/HMath-NumberTheory.md#v:kroneckerSymbol). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_kronecker_symbol(
    hmath_context *context,
    const char *a,
    const char *n,
    char **out0);
```

## `numbertheory.tonelli_shanks`

`numbertheory.tonelli_shanks(budget, a, p)`

Original: [`HMath.NumberTheory.tonelliShanks`](haskell/HMath-NumberTheory.md#v:tonelliShanks). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_tonelli_shanks(
    hmath_context *context,
    ptrdiff_t budget,
    const char *a,
    const char *p,
    char **out0);
```

## `numbertheory.continued_fraction`

`numbertheory.continued_fraction(r)`

Original: [`HMath.NumberTheory.continuedFraction`](haskell/HMath-NumberTheory.md#v:continuedFraction). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_continued_fraction(
    hmath_context *context,
    const char *r_numerator,
    const char *r_denominator,
    char * **out_data,
    size_t *out_count);
```

## `numbertheory.from_continued_fraction`

`numbertheory.from_continued_fraction(argument1)`

Original: [`HMath.NumberTheory.fromContinuedFraction`](haskell/HMath-NumberTheory.md#v:fromContinuedFraction). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_from_continued_fraction(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    char **out0,
    char **out1);
```

## `numbertheory.convergents`

`numbertheory.convergents(xs)`

Original: [`HMath.NumberTheory.convergents`](haskell/HMath-NumberTheory.md#v:convergents). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_convergents(
    hmath_context *context,
    const char * const *xs,
    size_t xs_count,
    char * **out_data,
    size_t *out_count);
```

## `numbertheory.farey`

`numbertheory.farey(n)`

Original: [`HMath.NumberTheory.farey`](haskell/HMath-NumberTheory.md#v:farey). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_farey(
    hmath_context *context,
    const char *n,
    char * **out_data,
    size_t *out_count);
```

## `numbertheory.pell_fundamental`

`numbertheory.pell_fundamental(budget, d)`

Original: [`HMath.NumberTheory.pellFundamental`](haskell/HMath-NumberTheory.md#v:pellFundamental). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_pell_fundamental(
    hmath_context *context,
    ptrdiff_t budget,
    const char *d,
    char **out0,
    char **out1);
```

## `numbertheory.is_perfect_number`

`numbertheory.is_perfect_number(budget, n)`

Original: [`HMath.NumberTheory.isPerfectNumber`](haskell/HMath-NumberTheory.md#v:isPerfectNumber). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_is_perfect_number(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    int *out0);
```

## `numbertheory.are_amicable`

`numbertheory.are_amicable(budget, a, b)`

Original: [`HMath.NumberTheory.areAmicable`](haskell/HMath-NumberTheory.md#v:areAmicable). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_are_amicable(
    hmath_context *context,
    ptrdiff_t budget,
    const char *a,
    const char *b,
    int *out0);
```

## `numbertheory.partition_count`

`numbertheory.partition_count(n)`

Original: [`HMath.NumberTheory.partitionCount`](haskell/HMath-NumberTheory.md#v:partitionCount). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_partition_count(
    hmath_context *context,
    ptrdiff_t n,
    char **out0);
```

## `numbertheory.fibonacci_fast`

`numbertheory.fibonacci_fast(n)`

Original: [`HMath.NumberTheory.fibonacciFast`](haskell/HMath-NumberTheory.md#v:fibonacciFast). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numbertheory_fibonacci_fast(
    hmath_context *context,
    const char *n,
    char **out0);
```

## `combinatorics.permutations_count`

`combinatorics.permutations_count(n, k)`

Original: [`HMath.Combinatorics.permutationsCount`](haskell/HMath-Combinatorics.md#v:permutationsCount). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_permutations_count(
    hmath_context *context,
    ptrdiff_t n,
    ptrdiff_t k,
    char **out0);
```

## `combinatorics.combinations_count`

`combinatorics.combinations_count(n, k)`

Original: [`HMath.Combinatorics.combinationsCount`](haskell/HMath-Combinatorics.md#v:combinationsCount). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_combinations_count(
    hmath_context *context,
    ptrdiff_t n,
    ptrdiff_t k,
    char **out0);
```

## `combinatorics.multinomial`

`combinatorics.multinomial(argument1)`

Original: [`HMath.Combinatorics.multinomial`](haskell/HMath-Combinatorics.md#v:multinomial). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_multinomial(
    hmath_context *context,
    ptrdiff_t const *argument1,
    size_t argument1_count,
    char **out0);
```

## `combinatorics.rank_permutation`

`combinatorics.rank_permutation(p)`

Original: [`HMath.Combinatorics.rankPermutation`](haskell/HMath-Combinatorics.md#v:rankPermutation). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_rank_permutation(
    hmath_context *context,
    ptrdiff_t const *p,
    size_t p_count,
    char **out0);
```

## `combinatorics.unrank_permutation`

`combinatorics.unrank_permutation(n, r)`

Original: [`HMath.Combinatorics.unrankPermutation`](haskell/HMath-Combinatorics.md#v:unrankPermutation). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_unrank_permutation(
    hmath_context *context,
    ptrdiff_t n,
    const char *r,
    ptrdiff_t **out_data,
    size_t *out_count);
```

## `combinatorics.rank_combination`

`combinatorics.rank_combination(n, xs)`

Original: [`HMath.Combinatorics.rankCombination`](haskell/HMath-Combinatorics.md#v:rankCombination). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_rank_combination(
    hmath_context *context,
    ptrdiff_t n,
    ptrdiff_t const *xs,
    size_t xs_count,
    char **out0);
```

## `combinatorics.unrank_combination`

`combinatorics.unrank_combination(n, k, r)`

Original: [`HMath.Combinatorics.unrankCombination`](haskell/HMath-Combinatorics.md#v:unrankCombination). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_unrank_combination(
    hmath_context *context,
    ptrdiff_t n,
    ptrdiff_t k,
    const char *r,
    ptrdiff_t **out_data,
    size_t *out_count);
```

## `combinatorics.derangement_count`

`combinatorics.derangement_count(n)`

Original: [`HMath.Combinatorics.derangementCount`](haskell/HMath-Combinatorics.md#v:derangementCount). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_derangement_count(
    hmath_context *context,
    ptrdiff_t n,
    char **out0);
```

## `combinatorics.stirling_first`

`combinatorics.stirling_first(argument1, argument2)`

Original: [`HMath.Combinatorics.stirlingFirst`](haskell/HMath-Combinatorics.md#v:stirlingFirst). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_stirling_first(
    hmath_context *context,
    ptrdiff_t argument1,
    ptrdiff_t argument2,
    char **out0);
```

## `combinatorics.stirling_second`

`combinatorics.stirling_second(argument1, argument2)`

Original: [`HMath.Combinatorics.stirlingSecond`](haskell/HMath-Combinatorics.md#v:stirlingSecond). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_stirling_second(
    hmath_context *context,
    ptrdiff_t argument1,
    ptrdiff_t argument2,
    char **out0);
```

## `combinatorics.bell_number`

`combinatorics.bell_number(n)`

Original: [`HMath.Combinatorics.bellNumber`](haskell/HMath-Combinatorics.md#v:bellNumber). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_bell_number(
    hmath_context *context,
    ptrdiff_t n,
    char **out0);
```

## `combinatorics.eulerian_number`

`combinatorics.eulerian_number(argument1, argument2)`

Original: [`HMath.Combinatorics.eulerianNumber`](haskell/HMath-Combinatorics.md#v:eulerianNumber). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_eulerian_number(
    hmath_context *context,
    ptrdiff_t argument1,
    ptrdiff_t argument2,
    char **out0);
```

## `combinatorics.lah_number`

`combinatorics.lah_number(n, k)`

Original: [`HMath.Combinatorics.lahNumber`](haskell/HMath-Combinatorics.md#v:lahNumber). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_lah_number(
    hmath_context *context,
    ptrdiff_t n,
    ptrdiff_t k,
    char **out0);
```

## `combinatorics.catalan_number`

`combinatorics.catalan_number(argument1)`

Original: [`HMath.Combinatorics.catalanNumber`](haskell/HMath-Combinatorics.md#v:catalanNumber). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_catalan_number(
    hmath_context *context,
    ptrdiff_t argument1,
    char **out0);
```

## `combinatorics.fibonacci`

`combinatorics.fibonacci(n)`

Original: [`HMath.Combinatorics.fibonacci`](haskell/HMath-Combinatorics.md#v:fibonacci). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_fibonacci(
    hmath_context *context,
    ptrdiff_t n,
    char **out0);
```

## `combinatorics.lucas`

`combinatorics.lucas(n)`

Original: [`HMath.Combinatorics.lucas`](haskell/HMath-Combinatorics.md#v:lucas). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_lucas(
    hmath_context *context,
    ptrdiff_t n,
    char **out0);
```

## `combinatorics.inclusion_exclusion`

`combinatorics.inclusion_exclusion(n, sizes)`

Original: [`HMath.Combinatorics.inclusionExclusion`](haskell/HMath-Combinatorics.md#v:inclusionExclusion). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_inclusion_exclusion(
    hmath_context *context,
    ptrdiff_t n,
    const char * const *sizes,
    size_t sizes_count,
    char **out0);
```

## `combinatorics.multiset_count`

`combinatorics.multiset_count(argument1, *, dtype='float64')`

Original: [`HMath.Combinatorics.multisetCount`](haskell/HMath-Combinatorics.md#v:multisetCount). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_multiset_count_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    char **out0);
```

```c
hmath_status hmath_combinatorics_multiset_count_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    char **out0);
```

## `combinatorics.linear_recurrence`

`combinatorics.linear_recurrence(n, cs, initial)`

Original: [`HMath.Combinatorics.linearRecurrence`](haskell/HMath-Combinatorics.md#v:linearRecurrence). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_linear_recurrence(
    hmath_context *context,
    ptrdiff_t n,
    const char * const *cs,
    size_t cs_count,
    const char * const *initial,
    size_t initial_count,
    char * **out_data,
    size_t *out_count);
```

## `combinatorics.convolve_series`

`combinatorics.convolve_series(n, a, b)`

Original: [`HMath.Combinatorics.convolveSeries`](haskell/HMath-Combinatorics.md#v:convolveSeries). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_convolve_series(
    hmath_context *context,
    ptrdiff_t n,
    const char * const *a,
    size_t a_count,
    const char * const *b,
    size_t b_count,
    char * **out_data,
    size_t *out_count);
```

## `combinatorics.finite_sum`

`combinatorics.finite_sum(argument1, *, dtype='float64')`

Original: [`HMath.Combinatorics.finiteSum`](haskell/HMath-Combinatorics.md#v:finiteSum). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_combinatorics_finite_sum_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0);
```

```c
hmath_status hmath_combinatorics_finite_sum_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0);
```

## `linear.dot`

`linear.dot(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Linear.dot`](haskell/HMath-Linear.md#v:dot). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_linear_dot_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float *out0);
```

```c
hmath_status hmath_linear_dot_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double *out0);
```

```c
hmath_status hmath_linear_dot_rational(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char **out0,
    char **out1);
```

```c
hmath_status hmath_linear_dot_integer(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char **out0);
```

```c
hmath_status hmath_linear_dot_i8(
    hmath_context *context,
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t *out0);
```

```c
hmath_status hmath_linear_dot_i16(
    hmath_context *context,
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t *out0);
```

```c
hmath_status hmath_linear_dot_i32(
    hmath_context *context,
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t *out0);
```

```c
hmath_status hmath_linear_dot_i64(
    hmath_context *context,
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t *out0);
```

```c
hmath_status hmath_linear_dot_u8(
    hmath_context *context,
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t *out0);
```

```c
hmath_status hmath_linear_dot_u16(
    hmath_context *context,
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t *out0);
```

```c
hmath_status hmath_linear_dot_u32(
    hmath_context *context,
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t *out0);
```

```c
hmath_status hmath_linear_dot_u64(
    hmath_context *context,
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t *out0);
```

```c
hmath_status hmath_linear_dot_int(
    hmath_context *context,
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_linear_dot_word(
    hmath_context *context,
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t *out0);
```

```c
hmath_status hmath_linear_dot_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_linear_dot_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double *out0,
    double *out1);
```

## `linear.dot_checked`

`linear.dot_checked(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Linear.dotChecked`](haskell/HMath-Linear.md#v:dotChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_linear_dot_checked_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float *out0);
```

```c
hmath_status hmath_linear_dot_checked_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double *out0);
```

```c
hmath_status hmath_linear_dot_checked_rational(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char **out0,
    char **out1);
```

```c
hmath_status hmath_linear_dot_checked_integer(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char **out0);
```

```c
hmath_status hmath_linear_dot_checked_i8(
    hmath_context *context,
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t *out0);
```

```c
hmath_status hmath_linear_dot_checked_i16(
    hmath_context *context,
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t *out0);
```

```c
hmath_status hmath_linear_dot_checked_i32(
    hmath_context *context,
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t *out0);
```

```c
hmath_status hmath_linear_dot_checked_i64(
    hmath_context *context,
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t *out0);
```

```c
hmath_status hmath_linear_dot_checked_u8(
    hmath_context *context,
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t *out0);
```

```c
hmath_status hmath_linear_dot_checked_u16(
    hmath_context *context,
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t *out0);
```

```c
hmath_status hmath_linear_dot_checked_u32(
    hmath_context *context,
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t *out0);
```

```c
hmath_status hmath_linear_dot_checked_u64(
    hmath_context *context,
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t *out0);
```

```c
hmath_status hmath_linear_dot_checked_int(
    hmath_context *context,
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_linear_dot_checked_word(
    hmath_context *context,
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t *out0);
```

```c
hmath_status hmath_linear_dot_checked_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_linear_dot_checked_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double *out0,
    double *out1);
```

## `linear.magnitude`

`linear.magnitude(argument1, *, dtype='float64')`

Original: [`HMath.Linear.magnitude`](haskell/HMath-Linear.md#v:magnitude). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `complex64`, `complex128`.

```c
hmath_status hmath_linear_magnitude_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0);
```

```c
hmath_status hmath_linear_magnitude_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0);
```

```c
hmath_status hmath_linear_magnitude_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float *out0,
    float *out1);
```

```c
hmath_status hmath_linear_magnitude_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double *out0,
    double *out1);
```

## `linear.normalize`

`linear.normalize(argument1, *, dtype='float64')`

Original: [`HMath.Linear.normalize`](haskell/HMath-Linear.md#v:normalize). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `complex64`, `complex128`.

```c
hmath_status hmath_linear_normalize_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_normalize_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_normalize_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_normalize_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
```

## `linear.add`

`linear.add(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Linear.add`](haskell/HMath-Linear.md#v:add). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_linear_add_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_rational(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_integer(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_i8(
    hmath_context *context,
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_i16(
    hmath_context *context,
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_i32(
    hmath_context *context,
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_i64(
    hmath_context *context,
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_u8(
    hmath_context *context,
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_u16(
    hmath_context *context,
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_u32(
    hmath_context *context,
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_u64(
    hmath_context *context,
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_int(
    hmath_context *context,
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_word(
    hmath_context *context,
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

## `linear.add_checked`

`linear.add_checked(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Linear.addChecked`](haskell/HMath-Linear.md#v:addChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_linear_add_checked_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_rational(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_integer(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_i8(
    hmath_context *context,
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_i16(
    hmath_context *context,
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_i32(
    hmath_context *context,
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_i64(
    hmath_context *context,
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_u8(
    hmath_context *context,
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_u16(
    hmath_context *context,
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_u32(
    hmath_context *context,
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_u64(
    hmath_context *context,
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_int(
    hmath_context *context,
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_word(
    hmath_context *context,
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_add_checked_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

## `linear.subtract_checked`

`linear.subtract_checked(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Linear.subtractChecked`](haskell/HMath-Linear.md#v:subtractChecked). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_linear_subtract_checked_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_rational(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_integer(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_i8(
    hmath_context *context,
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_i16(
    hmath_context *context,
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_i32(
    hmath_context *context,
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_i64(
    hmath_context *context,
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_u8(
    hmath_context *context,
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_u16(
    hmath_context *context,
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_u32(
    hmath_context *context,
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_u64(
    hmath_context *context,
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_int(
    hmath_context *context,
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_word(
    hmath_context *context,
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_subtract_checked_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

## `linear.scale`

`linear.scale(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Linear.scale`](haskell/HMath-Linear.md#v:scale). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `float32`, `float64`, `rational`, `integer`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`, `complex64`, `complex128`.

```c
hmath_status hmath_linear_scale_f32(
    hmath_context *context,
    float argument1,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_f64(
    hmath_context *context,
    double argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_rational(
    hmath_context *context,
    const char *argument1_numerator,
    const char *argument1_denominator,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_integer(
    hmath_context *context,
    const char *argument1,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_i8(
    hmath_context *context,
    int8_t argument1,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_i16(
    hmath_context *context,
    int16_t argument1,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_i32(
    hmath_context *context,
    int32_t argument1,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_i64(
    hmath_context *context,
    int64_t argument1,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_u8(
    hmath_context *context,
    uint8_t argument1,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_u16(
    hmath_context *context,
    uint16_t argument1,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_u32(
    hmath_context *context,
    uint32_t argument1,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_u64(
    hmath_context *context,
    uint64_t argument1,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_int(
    hmath_context *context,
    ptrdiff_t argument1,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_word(
    hmath_context *context,
    size_t argument1,
    const size_t *argument2,
    size_t argument2_count,
    size_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_c64(
    hmath_context *context,
    float argument1_0,
    float argument1_1,
    float const *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_linear_scale_c128(
    hmath_context *context,
    double argument1_0,
    double argument1_1,
    double const *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

## `special.gamma`

`special.gamma(x, *, dtype='float64')`

Original: [`HMath.Special.gamma`](haskell/HMath-Special.md#v:gamma). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_gamma_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `special.log_gamma`

`special.log_gamma(x, *, dtype='float64')`

Original: [`HMath.Special.logGamma`](haskell/HMath-Special.md#v:logGamma). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_log_gamma_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `special.log_beta`

`special.log_beta(a, b, *, dtype='float64')`

Original: [`HMath.Special.logBeta`](haskell/HMath-Special.md#v:logBeta). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_log_beta_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0);
```

## `special.beta`

`special.beta(a, b, *, dtype='float64')`

Original: [`HMath.Special.beta`](haskell/HMath-Special.md#v:beta). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_beta_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0);
```

## `special.gamma_p`

`special.gamma_p(a, x, *, dtype='float64')`

Original: [`HMath.Special.gammaP`](haskell/HMath-Special.md#v:gammaP). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_gamma_p_f64(
    hmath_context *context,
    double a,
    double x,
    double *out0);
```

## `special.gamma_q`

`special.gamma_q(a, x, *, dtype='float64')`

Original: [`HMath.Special.gammaQ`](haskell/HMath-Special.md#v:gammaQ). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_gamma_q_f64(
    hmath_context *context,
    double a,
    double x,
    double *out0);
```

## `special.incomplete_gamma`

`special.incomplete_gamma(a, x, *, dtype='float64')`

Original: [`HMath.Special.incompleteGamma`](haskell/HMath-Special.md#v:incompleteGamma). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_incomplete_gamma_f64(
    hmath_context *context,
    double a,
    double x,
    double *out0);
```

## `special.beta_i`

`special.beta_i(a, b, x, *, dtype='float64')`

Original: [`HMath.Special.betaI`](haskell/HMath-Special.md#v:betaI). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_beta_i_f64(
    hmath_context *context,
    double a,
    double b,
    double x,
    double *out0);
```

## `special.incomplete_beta`

`special.incomplete_beta(a, b, x, *, dtype='float64')`

Original: [`HMath.Special.incompleteBeta`](haskell/HMath-Special.md#v:incompleteBeta). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_incomplete_beta_f64(
    hmath_context *context,
    double a,
    double b,
    double x,
    double *out0);
```

## `special.digamma`

`special.digamma(x, *, dtype='float64')`

Original: [`HMath.Special.digamma`](haskell/HMath-Special.md#v:digamma). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_digamma_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `special.trigamma`

`special.trigamma(argument1, *, dtype='float64')`

Original: [`HMath.Special.trigamma`](haskell/HMath-Special.md#v:trigamma). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_trigamma_f64(
    hmath_context *context,
    double argument1,
    double *out0);
```

## `special.polygamma`

`special.polygamma(n, x, *, dtype='float64')`

Original: [`HMath.Special.polygamma`](haskell/HMath-Special.md#v:polygamma). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_polygamma_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0);
```

## `special.erf`

`special.erf(x, *, dtype='float64')`

Original: [`HMath.Special.erf`](haskell/HMath-Special.md#v:erf). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_erf_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `special.erfc`

`special.erfc(x, *, dtype='float64')`

Original: [`HMath.Special.erfc`](haskell/HMath-Special.md#v:erfc). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_erfc_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `special.erfcx`

`special.erfcx(x, *, dtype='float64')`

Original: [`HMath.Special.erfcx`](haskell/HMath-Special.md#v:erfcx). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_erfcx_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1);
```

## `special.normal_c_d_f`

`special.normal_c_d_f(x, *, dtype='float64')`

Original: [`HMath.Special.normalCDF`](haskell/HMath-Special.md#v:normalCDF). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_normal_c_d_f_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `special.normal_quantile`

`special.normal_quantile(p, *, dtype='float64')`

Original: [`HMath.Special.normalQuantile`](haskell/HMath-Special.md#v:normalQuantile). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_normal_quantile_f64(
    hmath_context *context,
    double p,
    double *out0);
```

## `special.inverse_erf`

`special.inverse_erf(x, *, dtype='float64')`

Original: [`HMath.Special.inverseErf`](haskell/HMath-Special.md#v:inverseErf). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_inverse_erf_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `special.dawson`

`special.dawson(x, *, dtype='float64')`

Original: [`HMath.Special.dawson`](haskell/HMath-Special.md#v:dawson). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_dawson_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1);
```

## `special.exponential_integral`

`special.exponential_integral(n, x, *, dtype='float64')`

Original: [`HMath.Special.exponentialIntegral`](haskell/HMath-Special.md#v:exponentialIntegral). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_exponential_integral_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1);
```

## `special.logarithmic_integral`

`special.logarithmic_integral(x, *, dtype='float64')`

Original: [`HMath.Special.logarithmicIntegral`](haskell/HMath-Special.md#v:logarithmicIntegral). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_logarithmic_integral_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1);
```

## `special.sine_integral`

`special.sine_integral(x, *, dtype='float64')`

Original: [`HMath.Special.sineIntegral`](haskell/HMath-Special.md#v:sineIntegral). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_sine_integral_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1);
```

## `special.cosine_integral`

`special.cosine_integral(x, *, dtype='float64')`

Original: [`HMath.Special.cosineIntegral`](haskell/HMath-Special.md#v:cosineIntegral). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_cosine_integral_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1);
```

## `special.fresnel`

`special.fresnel(x, *, dtype='float64')`

Original: [`HMath.Special.fresnel`](haskell/HMath-Special.md#v:fresnel). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_fresnel_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1,
    double *out2,
    double *out3);
```

## `special.elliptic_f`

`special.elliptic_f(phi, m, *, dtype='float64')`

Original: [`HMath.Special.ellipticF`](haskell/HMath-Special.md#v:ellipticF). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_elliptic_f_f64(
    hmath_context *context,
    double phi,
    double m,
    double *out0,
    double *out1);
```

## `special.elliptic_e`

`special.elliptic_e(phi, m, *, dtype='float64')`

Original: [`HMath.Special.ellipticE`](haskell/HMath-Special.md#v:ellipticE). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_elliptic_e_f64(
    hmath_context *context,
    double phi,
    double m,
    double *out0,
    double *out1);
```

## `special.elliptic_pi`

`special.elliptic_pi(n, phi, m, *, dtype='float64')`

Original: [`HMath.Special.ellipticPi`](haskell/HMath-Special.md#v:ellipticPi). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_elliptic_pi_f64(
    hmath_context *context,
    double n,
    double phi,
    double m,
    double *out0,
    double *out1);
```

## `special.jacobi_elliptic`

`special.jacobi_elliptic(u, m, *, dtype='float64')`

Original: [`HMath.Special.jacobiElliptic`](haskell/HMath-Special.md#v:jacobiElliptic). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_jacobi_elliptic_f64(
    hmath_context *context,
    double u,
    double m,
    double *out0,
    double *out1,
    double *out2);
```

## `special.bessel_j`

`special.bessel_j(n, x, *, dtype='float64')`

Original: [`HMath.Special.besselJ`](haskell/HMath-Special.md#v:besselJ). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_bessel_j_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0);
```

## `special.bessel_y`

`special.bessel_y(n, x, *, dtype='float64')`

Original: [`HMath.Special.besselY`](haskell/HMath-Special.md#v:besselY). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_bessel_y_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0);
```

## `special.bessel_i`

`special.bessel_i(n, x, *, dtype='float64')`

Original: [`HMath.Special.besselI`](haskell/HMath-Special.md#v:besselI). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_bessel_i_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1);
```

## `special.scaled_bessel_i`

`special.scaled_bessel_i(n, x, *, dtype='float64')`

Original: [`HMath.Special.scaledBesselI`](haskell/HMath-Special.md#v:scaledBesselI). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_scaled_bessel_i_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1);
```

## `special.bessel_k`

`special.bessel_k(n, x, *, dtype='float64')`

Original: [`HMath.Special.besselK`](haskell/HMath-Special.md#v:besselK). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_bessel_k_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1);
```

## `special.scaled_bessel_k`

`special.scaled_bessel_k(n, x, *, dtype='float64')`

Original: [`HMath.Special.scaledBesselK`](haskell/HMath-Special.md#v:scaledBesselK). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_scaled_bessel_k_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1);
```

## `special.spherical_bessel_j`

`special.spherical_bessel_j(n, x, *, dtype='float64')`

Original: [`HMath.Special.sphericalBesselJ`](haskell/HMath-Special.md#v:sphericalBesselJ). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_spherical_bessel_j_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0);
```

## `special.spherical_bessel_y`

`special.spherical_bessel_y(n, x, *, dtype='float64')`

Original: [`HMath.Special.sphericalBesselY`](haskell/HMath-Special.md#v:sphericalBesselY). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_spherical_bessel_y_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0);
```

## `special.airy`

`special.airy(x, *, dtype='float64')`

Original: [`HMath.Special.airy`](haskell/HMath-Special.md#v:airy). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_airy_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1,
    double *out2,
    double *out3,
    double *out4,
    double *out5,
    double *out6,
    double *out7);
```

## `special.struve`

`special.struve(nu, x, *, dtype='float64')`

Original: [`HMath.Special.struve`](haskell/HMath-Special.md#v:struve). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_struve_f64(
    hmath_context *context,
    double nu,
    double x,
    double *out0,
    double *out1);
```

## `special.hypergeometric`

`special.hypergeometric(as_, bs, z, *, dtype='float64')`

Original: [`HMath.Special.hypergeometric`](haskell/HMath-Special.md#v:hypergeometric). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_hypergeometric_f64(
    hmath_context *context,
    const double *as,
    size_t as_count,
    const double *bs,
    size_t bs_count,
    double z,
    double *out0,
    double *out1);
```

## `special.hypergeometric1_f1`

`special.hypergeometric1_f1(a, b, z, *, dtype='float64')`

Original: [`HMath.Special.hypergeometric1F1`](haskell/HMath-Special.md#v:hypergeometric1F1). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_hypergeometric1_f1_f64(
    hmath_context *context,
    double a,
    double b,
    double z,
    double *out0,
    double *out1);
```

## `special.hypergeometric2_f1`

`special.hypergeometric2_f1(a, b, c, z, *, dtype='float64')`

Original: [`HMath.Special.hypergeometric2F1`](haskell/HMath-Special.md#v:hypergeometric2F1). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_hypergeometric2_f1_f64(
    hmath_context *context,
    double a,
    double b,
    double c,
    double z,
    double *out0,
    double *out1);
```

## `special.legendre`

`special.legendre(n, x, *, dtype='float64')`

Original: [`HMath.Special.legendre`](haskell/HMath-Special.md#v:legendre). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_legendre_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0);
```

## `special.associated_legendre`

`special.associated_legendre(l, m, x, *, dtype='float64')`

Original: [`HMath.Special.associatedLegendre`](haskell/HMath-Special.md#v:associatedLegendre). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_associated_legendre_f64(
    hmath_context *context,
    ptrdiff_t l,
    ptrdiff_t m,
    double x,
    double *out0);
```

## `special.hurwitz_zeta`

`special.hurwitz_zeta(s, q, *, dtype='float64')`

Original: [`HMath.Special.hurwitzZeta`](haskell/HMath-Special.md#v:hurwitzZeta). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_hurwitz_zeta_f64(
    hmath_context *context,
    double s,
    double q,
    double *out0,
    double *out1);
```

## `special.riemann_zeta`

`special.riemann_zeta(s, *, dtype='float64')`

Original: [`HMath.Special.riemannZeta`](haskell/HMath-Special.md#v:riemannZeta). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_riemann_zeta_f64(
    hmath_context *context,
    double s,
    double *out0,
    double *out1);
```

## `special.polylogarithm`

`special.polylogarithm(s, z, *, dtype='float64')`

Original: [`HMath.Special.polylogarithm`](haskell/HMath-Special.md#v:polylogarithm). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_polylogarithm_f64(
    hmath_context *context,
    double s,
    double z,
    double *out0,
    double *out1);
```

## `special.dilogarithm`

`special.dilogarithm(x, *, dtype='float64')`

Original: [`HMath.Special.dilogarithm`](haskell/HMath-Special.md#v:dilogarithm). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_dilogarithm_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1);
```

## `special.lambert_w`

`special.lambert_w(branch, x, *, dtype='float64')`

Original: [`HMath.Special.lambertW`](haskell/HMath-Special.md#v:lambertW). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_lambert_w_f64(
    hmath_context *context,
    ptrdiff_t branch,
    double x,
    double *out0,
    double *out1);
```

## `special.debye`

`special.debye(n, x, *, dtype='float64')`

Original: [`HMath.Special.debye`](haskell/HMath-Special.md#v:debye). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_debye_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1);
```

## `special.clausen`

`special.clausen(theta, *, dtype='float64')`

Original: [`HMath.Special.clausen`](haskell/HMath-Special.md#v:clausen). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_clausen_f64(
    hmath_context *context,
    double theta,
    double *out0,
    double *out1);
```

## `special.fermi_dirac`

`special.fermi_dirac(order, eta, *, dtype='float64')`

Original: [`HMath.Special.fermiDirac`](haskell/HMath-Special.md#v:fermiDirac). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_fermi_dirac_f64(
    hmath_context *context,
    double order,
    double eta,
    double *out0,
    double *out1);
```

## `special.bose_einstein`

`special.bose_einstein(order, eta, *, dtype='float64')`

Original: [`HMath.Special.boseEinstein`](haskell/HMath-Special.md#v:boseEinstein). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_bose_einstein_f64(
    hmath_context *context,
    double order,
    double eta,
    double *out0,
    double *out1);
```

## `special.coulomb_wave`

`special.coulomb_wave(l, eta, rho, *, dtype='float64')`

Original: [`HMath.Special.coulombWave`](haskell/HMath-Special.md#v:coulombWave). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_coulomb_wave_f64(
    hmath_context *context,
    ptrdiff_t l,
    double eta,
    double rho,
    double *out0,
    double *out1,
    double *out2,
    double *out3);
```

## `special.gegenbauer`

`special.gegenbauer(n, a, x, *, dtype='float64')`

Original: [`HMath.Special.gegenbauer`](haskell/HMath-Special.md#v:gegenbauer). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_gegenbauer_f64(
    hmath_context *context,
    ptrdiff_t n,
    double a,
    double x,
    double *out0);
```

## `special.parabolic_cylinder`

`special.parabolic_cylinder(nu, x, *, dtype='float64')`

Original: [`HMath.Special.parabolicCylinder`](haskell/HMath-Special.md#v:parabolicCylinder). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_parabolic_cylinder_f64(
    hmath_context *context,
    double nu,
    double x,
    double *out0,
    double *out1);
```

## `special.mathieu`

`special.mathieu(evenMode, n, q, x, *, dtype='float64')`

Original: [`HMath.Special.mathieu`](haskell/HMath-Special.md#v:mathieu). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_mathieu_f64(
    hmath_context *context,
    int evenMode,
    ptrdiff_t n,
    double q,
    double x,
    double *out0,
    double *out1,
    double *out2);
```

## `special.bernoulli_polynomial`

`special.bernoulli_polynomial(n, x, *, dtype='float64')`

Original: [`HMath.Special.bernoulliPolynomial`](haskell/HMath-Special.md#v:bernoulliPolynomial). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_bernoulli_polynomial_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0);
```

## `special.euler_polynomial`

`special.euler_polynomial(n, x, *, dtype='float64')`

Original: [`HMath.Special.eulerPolynomial`](haskell/HMath-Special.md#v:eulerPolynomial). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_euler_polynomial_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0);
```

## `special.wigner3j`

`special.wigner3j(j1, j2, j3, m1, m2, m3, *, dtype='float64')`

Original: [`HMath.Special.wigner3j`](haskell/HMath-Special.md#v:wigner3j). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_wigner3j_f64(
    hmath_context *context,
    ptrdiff_t j1,
    ptrdiff_t j2,
    ptrdiff_t j3,
    ptrdiff_t m1,
    ptrdiff_t m2,
    ptrdiff_t m3,
    double *out0);
```

## `special.wigner6j`

`special.wigner6j(a, b, c, d, e, f, *, dtype='float64')`

Original: [`HMath.Special.wigner6j`](haskell/HMath-Special.md#v:wigner6j). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_wigner6j_f64(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t c,
    ptrdiff_t d,
    ptrdiff_t e,
    ptrdiff_t f,
    double *out0);
```

## `special.wigner9j`

`special.wigner9j(js, *, dtype='float64')`

Original: [`HMath.Special.wigner9j`](haskell/HMath-Special.md#v:wigner9j). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_wigner9j_f64(
    hmath_context *context,
    ptrdiff_t const *js,
    size_t js_count,
    double *out0);
```

## `special.clebsch_gordan`

`special.clebsch_gordan(j1, m1, j2, m2, j, m, *, dtype='float64')`

Original: [`HMath.Special.clebschGordan`](haskell/HMath-Special.md#v:clebschGordan). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_clebsch_gordan_f64(
    hmath_context *context,
    ptrdiff_t j1,
    ptrdiff_t m1,
    ptrdiff_t j2,
    ptrdiff_t m2,
    ptrdiff_t j,
    ptrdiff_t m,
    double *out0);
```

## `complex.to_polar`

`complex.to_polar(z, *, dtype='float64')`

Original: [`HMath.Complex.toPolar`](haskell/HMath-Complex.md#v:toPolar). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_complex_to_polar_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `probability.gamma_poisson_update`

`probability.gamma_poisson_update(shapePrior, ratePrior, xs, *, dtype='float64')`

Original: [`HMath.Probability.gammaPoissonUpdate`](haskell/HMath-Probability.md#v:gammaPoissonUpdate). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_probability_gamma_poisson_update_f64(
    hmath_context *context,
    double shapePrior,
    double ratePrior,
    ptrdiff_t const *xs,
    size_t xs_count,
    double *out0,
    double *out1);
```

## `probability.normal_normal_update`

`probability.normal_normal_update(mu, priorVariance, observationVariance, xs, *, dtype='float64')`

Original: [`HMath.Probability.normalNormalUpdate`](haskell/HMath-Probability.md#v:normalNormalUpdate). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_probability_normal_normal_update_f64(
    hmath_context *context,
    double mu,
    double priorVariance,
    double observationVariance,
    const double *xs,
    size_t xs_count,
    double *out0,
    double *out1);
```

## `probability.conditional_probability`

`probability.conditional_probability(joint, given, *, dtype='float64')`

Original: [`HMath.Probability.conditionalProbability`](haskell/HMath-Probability.md#v:conditionalProbability). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_probability_conditional_probability_f64(
    hmath_context *context,
    double joint,
    double given,
    double *out0);
```

## `probability.bayes`

`probability.bayes(priors, likelihoods, *, dtype='float64')`

Original: [`HMath.Probability.bayes`](haskell/HMath-Probability.md#v:bayes). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_probability_bayes_f64(
    hmath_context *context,
    const double *priors,
    size_t priors_count,
    const double *likelihoods,
    size_t likelihoods_count,
    double **out_data,
    size_t *out_count);
```

## `probability.multinomial_p_m_f`

`probability.multinomial_p_m_f(ps, counts, *, dtype='float64')`

Original: [`HMath.Probability.multinomialPMF`](haskell/HMath-Probability.md#v:multinomialPMF). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_probability_multinomial_p_m_f_f64(
    hmath_context *context,
    const double *ps,
    size_t ps_count,
    ptrdiff_t const *counts,
    size_t counts_count,
    double *out0);
```

## `probability.dirichlet_density`

`probability.dirichlet_density(as_, xs, *, dtype='float64')`

Original: [`HMath.Probability.dirichletDensity`](haskell/HMath-Probability.md#v:dirichletDensity). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_probability_dirichlet_density_f64(
    hmath_context *context,
    const double *as,
    size_t as_count,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `complex.complex`

`complex.complex(real, imaginary, *, dtype='float64')`

Original: [`HMath.Complex.complex`](haskell/HMath-Complex.md#v:complex). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_complex_complex_f64(
    hmath_context *context,
    double real,
    double imaginary,
    double *out0,
    double *out1);
```

## `complex.reciprocal`

`complex.reciprocal(z, *, dtype='float64')`

Original: [`HMath.Complex.reciprocal`](haskell/HMath-Complex.md#v:reciprocal). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_complex_reciprocal_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `complex.add`

`complex.add(a, b, *, dtype='float64')`

Original: [`HMath.Complex.add`](haskell/HMath-Complex.md#v:add). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_complex_add_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
```

## `complex.subtract_complex`

`complex.subtract_complex(a, b, *, dtype='float64')`

Original: [`HMath.Complex.subtractComplex`](haskell/HMath-Complex.md#v:subtractComplex). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_complex_subtract_complex_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
```

## `complex.multiply`

`complex.multiply(a, b, *, dtype='float64')`

Original: [`HMath.Complex.multiply`](haskell/HMath-Complex.md#v:multiply). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_complex_multiply_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
```

## `complex.divide`

`complex.divide(a, b, *, dtype='float64')`

Original: [`HMath.Complex.divide`](haskell/HMath-Complex.md#v:divide). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_complex_divide_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
```

## `complex.power`

`complex.power(a, b, *, dtype='float64')`

Original: [`HMath.Complex.power`](haskell/HMath-Complex.md#v:power). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_complex_power_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
```

## `complex.from_polar`

`complex.from_polar(radius, angle, *, dtype='float64')`

Original: [`HMath.Complex.fromPolar`](haskell/HMath-Complex.md#v:fromPolar). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_complex_from_polar_f64(
    hmath_context *context,
    double radius,
    double angle,
    double *out0,
    double *out1);
```

## `complex.rotate`

`complex.rotate(angle, z, *, dtype='float64')`

Original: [`HMath.Complex.rotate`](haskell/HMath-Complex.md#v:rotate). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_complex_rotate_f64(
    hmath_context *context,
    double angle,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `special.hankel`

`special.hankel(kind, order, x, *, dtype='float64')`

Original: [`HMath.Special.hankel`](haskell/HMath-Special.md#v:hankel). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_hankel_f64(
    hmath_context *context,
    ptrdiff_t kind,
    ptrdiff_t order,
    double x,
    double *out0,
    double *out1);
```

## `special.spherical_harmonic`

`special.spherical_harmonic(degree, order, theta, phi, *, dtype='float64')`

Original: [`HMath.Special.sphericalHarmonic`](haskell/HMath-Special.md#v:sphericalHarmonic). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_spherical_harmonic_f64(
    hmath_context *context,
    ptrdiff_t degree,
    ptrdiff_t order,
    double theta,
    double phi,
    double *out0,
    double *out1);
```

## `special.complex1_f1`

`special.complex1_f1(a, b, z, *, dtype='float64')`

Original: [`HMath.Special.complex1F1`](haskell/HMath-Special.md#v:complex1F1). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_special_complex1_f1_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
```

## `api_algebra.inner_product`

`api_algebra.inner_product(argument1, argument2, *, dtype='float64')`

Original: [`HMath.API.Algebra.innerProduct`](haskell/HMath-API-Algebra.md#v:innerProduct). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_api_algebra_inner_product_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float *out0);
```

```c
hmath_status hmath_api_algebra_inner_product_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double *out0);
```

## `algorithms.lower_bound`

`algorithms.lower_bound(x, xs, *, dtype='float64')`

Original: [`HMath.Algorithms.lowerBound`](haskell/HMath-Algorithms.md#v:lowerBound). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_lower_bound_f32(
    hmath_context *context,
    float x,
    const float *xs,
    size_t xs_count,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_algorithms_lower_bound_f64(
    hmath_context *context,
    double x,
    const double *xs,
    size_t xs_count,
    ptrdiff_t *out0);
```

## `algorithms.upper_bound`

`algorithms.upper_bound(x, xs, *, dtype='float64')`

Original: [`HMath.Algorithms.upperBound`](haskell/HMath-Algorithms.md#v:upperBound). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_upper_bound_f32(
    hmath_context *context,
    float x,
    const float *xs,
    size_t xs_count,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_algorithms_upper_bound_f64(
    hmath_context *context,
    double x,
    const double *xs,
    size_t xs_count,
    ptrdiff_t *out0);
```

## `algorithms.quickselect`

`algorithms.quickselect(k, xs, *, dtype='float64')`

Original: [`HMath.Algorithms.quickselect`](haskell/HMath-Algorithms.md#v:quickselect). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_quickselect_f32(
    hmath_context *context,
    ptrdiff_t k,
    const float *xs,
    size_t xs_count,
    float *out0);
```

```c
hmath_status hmath_algorithms_quickselect_f64(
    hmath_context *context,
    ptrdiff_t k,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `algorithms.introselect`

`algorithms.introselect(k, xs, *, dtype='float64')`

Original: [`HMath.Algorithms.introselect`](haskell/HMath-Algorithms.md#v:introselect). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_introselect_f32(
    hmath_context *context,
    ptrdiff_t k,
    const float *xs,
    size_t xs_count,
    float *out0);
```

```c
hmath_status hmath_algorithms_introselect_f64(
    hmath_context *context,
    ptrdiff_t k,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `algorithms.partial_sort`

`algorithms.partial_sort(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Algorithms.partialSort`](haskell/HMath-Algorithms.md#v:partialSort). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_partial_sort_f32(
    hmath_context *context,
    ptrdiff_t argument1,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_algorithms_partial_sort_f64(
    hmath_context *context,
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

## `algorithms.merge_sort`

`algorithms.merge_sort(argument1, *, dtype='float64')`

Original: [`HMath.Algorithms.mergeSort`](haskell/HMath-Algorithms.md#v:mergeSort). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_merge_sort_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_algorithms_merge_sort_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
```

## `algorithms.quicksort`

`algorithms.quicksort(argument1, *, dtype='float64')`

Original: [`HMath.Algorithms.quicksort`](haskell/HMath-Algorithms.md#v:quicksort). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_quicksort_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_algorithms_quicksort_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
```

## `algorithms.heapsort`

`algorithms.heapsort(argument1, *, dtype='float64')`

Original: [`HMath.Algorithms.heapsort`](haskell/HMath-Algorithms.md#v:heapsort). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_heapsort_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_algorithms_heapsort_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
```

## `algorithms.introsort`

`algorithms.introsort(argument1, *, dtype='float64')`

Original: [`HMath.Algorithms.introsort`](haskell/HMath-Algorithms.md#v:introsort). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_introsort_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_algorithms_introsort_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
```

## `algorithms.counting_sort`

`algorithms.counting_sort(budget, xs)`

Original: [`HMath.Algorithms.countingSort`](haskell/HMath-Algorithms.md#v:countingSort). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_counting_sort(
    hmath_context *context,
    ptrdiff_t budget,
    ptrdiff_t const *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

## `algorithms.radix_sort`

`algorithms.radix_sort(argument1)`

Original: [`HMath.Algorithms.radixSort`](haskell/HMath-Algorithms.md#v:radixSort). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_radix_sort(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    char * **out_data,
    size_t *out_count);
```

## `algorithms.bucket_sort`

`algorithms.bucket_sort(buckets, xs, *, dtype='float64')`

Original: [`HMath.Algorithms.bucketSort`](haskell/HMath-Algorithms.md#v:bucketSort). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_bucket_sort_f64(
    hmath_context *context,
    ptrdiff_t buckets,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `algorithms.argsort`

`algorithms.argsort(argument1, *, dtype='float64')`

Original: [`HMath.Algorithms.argsort`](haskell/HMath-Algorithms.md#v:argsort). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_argsort_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_algorithms_argsort_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

## `algorithms.top_k`

`algorithms.top_k(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Algorithms.topK`](haskell/HMath-Algorithms.md#v:topK). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_top_k_f32(
    hmath_context *context,
    ptrdiff_t argument1,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_algorithms_top_k_f64(
    hmath_context *context,
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

## `algorithms.quantile_select`

`algorithms.quantile_select(q, xs, *, dtype='float64')`

Original: [`HMath.Algorithms.quantileSelect`](haskell/HMath-Algorithms.md#v:quantileSelect). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_quantile_select_f64(
    hmath_context *context,
    double q,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `algorithms.deduplicate`

`algorithms.deduplicate(argument1, *, dtype='float64')`

Original: [`HMath.Algorithms.deduplicate`](haskell/HMath-Algorithms.md#v:deduplicate). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_deduplicate_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_algorithms_deduplicate_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
```

## `algorithms.prefix_sums`

`algorithms.prefix_sums(argument1, *, dtype='float64')`

Original: [`HMath.Algorithms.prefixSums`](haskell/HMath-Algorithms.md#v:prefixSums). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_prefix_sums_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_algorithms_prefix_sums_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
```

## `algorithms.suffix_sums`

`algorithms.suffix_sums(argument1, *, dtype='float64')`

Original: [`HMath.Algorithms.suffixSums`](haskell/HMath-Algorithms.md#v:suffixSums). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_suffix_sums_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_algorithms_suffix_sums_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
```

## `algorithms.difference_array`

`algorithms.difference_array(argument1, *, dtype='float64')`

Original: [`HMath.Algorithms.differenceArray`](haskell/HMath-Algorithms.md#v:differenceArray). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_difference_array_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_algorithms_difference_array_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
```

## `algorithms.apply_differences`

`algorithms.apply_differences(argument1, *, dtype='float64')`

Original: [`HMath.Algorithms.applyDifferences`](haskell/HMath-Algorithms.md#v:applyDifferences). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_apply_differences_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_algorithms_apply_differences_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
```

## `algorithms.binary_lift`

`algorithms.binary_lift(next, steps, start)`

Original: [`HMath.Algorithms.binaryLift`](haskell/HMath-Algorithms.md#v:binaryLift). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_binary_lift(
    hmath_context *context,
    ptrdiff_t const *next,
    size_t next_count,
    const char *steps,
    ptrdiff_t start,
    ptrdiff_t *out0);
```

## `algorithms.polynomial_hash`

`algorithms.polynomial_hash(base, modulus, xs)`

Original: [`HMath.Algorithms.polynomialHash`](haskell/HMath-Algorithms.md#v:polynomialHash). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_polynomial_hash(
    hmath_context *context,
    const char *base,
    const char *modulus,
    const char * const *xs,
    size_t xs_count,
    char **out0);
```

## `algorithms.rolling_hashes`

`algorithms.rolling_hashes(base, modulus, width, xs)`

Original: [`HMath.Algorithms.rollingHashes`](haskell/HMath-Algorithms.md#v:rollingHashes). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_algorithms_rolling_hashes(
    hmath_context *context,
    const char *base,
    const char *modulus,
    ptrdiff_t width,
    const char * const *xs,
    size_t xs_count,
    char * **out_data,
    size_t *out_count);
```

## `datastructure.monotonic_minima`

`datastructure.monotonic_minima(argument1, argument2, *, dtype='float64')`

Original: [`HMath.DataStructure.monotonicMinima`](haskell/HMath-DataStructure.md#v:monotonicMinima). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_datastructure_monotonic_minima_f32(
    hmath_context *context,
    ptrdiff_t argument1,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_datastructure_monotonic_minima_f64(
    hmath_context *context,
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

## `deeplearning_core.log_softmax`

`deeplearning_core.log_softmax(argument1, *, dtype='float64')`

Original: [`HMath.DeepLearning.Core.logSoftmax`](haskell/HMath-DeepLearning-Core.md#v:logSoftmax). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_core_log_softmax_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
```

## `deeplearning_core.softmax`

`deeplearning_core.softmax(xs, *, dtype='float64')`

Original: [`HMath.DeepLearning.Core.softmax`](haskell/HMath-DeepLearning-Core.md#v:softmax). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_core_softmax_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `deeplearning_core.sparsemax`

`deeplearning_core.sparsemax(argument1, *, dtype='float64')`

Original: [`HMath.DeepLearning.Core.sparsemax`](haskell/HMath-DeepLearning-Core.md#v:sparsemax). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_core_sparsemax_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
```

## `deeplearning_core.gated_linear_unit`

`deeplearning_core.gated_linear_unit(values, gate, *, dtype='float64')`

Original: [`HMath.DeepLearning.Core.gatedLinearUnit`](haskell/HMath-DeepLearning-Core.md#v:gatedLinearUnit). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_core_gated_linear_unit_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    const double *gate,
    size_t gate_count,
    double **out_data,
    size_t *out_count);
```

## `deeplearning_core.categorical_cross_entropy_logits`

`deeplearning_core.categorical_cross_entropy_logits(target, logits, *, dtype='float64')`

Original: [`HMath.DeepLearning.Core.categoricalCrossEntropyLogits`](haskell/HMath-DeepLearning-Core.md#v:categoricalCrossEntropyLogits). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_core_categorical_cross_entropy_logits_f64(
    hmath_context *context,
    const double *target,
    size_t target_count,
    const double *logits,
    size_t logits_count,
    double *out0);
```

## `deeplearning_core.regularization`

`deeplearning_core.regularization(l1, l2, weights, *, dtype='float64')`

Original: [`HMath.DeepLearning.Core.regularization`](haskell/HMath-DeepLearning-Core.md#v:regularization). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_core_regularization_f64(
    hmath_context *context,
    double l1,
    double l2,
    const double *weights,
    size_t weights_count,
    double *out0);
```

## `deeplearning_core.contrastive_loss`

`deeplearning_core.contrastive_loss(margin, similar, a, b, *, dtype='float64')`

Original: [`HMath.DeepLearning.Core.contrastiveLoss`](haskell/HMath-DeepLearning-Core.md#v:contrastiveLoss). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_core_contrastive_loss_f64(
    hmath_context *context,
    double margin,
    int similar,
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double *out0);
```

## `deeplearning_core.triplet_loss`

`deeplearning_core.triplet_loss(margin, anchor, positive, negative, *, dtype='float64')`

Original: [`HMath.DeepLearning.Core.tripletLoss`](haskell/HMath-DeepLearning-Core.md#v:tripletLoss). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_core_triplet_loss_f64(
    hmath_context *context,
    double margin,
    const double *anchor,
    size_t anchor_count,
    const double *positive,
    size_t positive_count,
    const double *negative,
    size_t negative_count,
    double *out0);
```

## `deeplearning_core.focal_loss`

`deeplearning_core.focal_loss(alpha, gamma, target, prediction, *, dtype='float64')`

Original: [`HMath.DeepLearning.Core.focalLoss`](haskell/HMath-DeepLearning-Core.md#v:focalLoss). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_core_focal_loss_f64(
    hmath_context *context,
    double alpha,
    double gamma,
    const double *target,
    size_t target_count,
    const double *prediction,
    size_t prediction_count,
    double *out0);
```

## `deeplearning_core.dice_loss`

`deeplearning_core.dice_loss(smooth, target, prediction, *, dtype='float64')`

Original: [`HMath.DeepLearning.Core.diceLoss`](haskell/HMath-DeepLearning-Core.md#v:diceLoss). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_core_dice_loss_f64(
    hmath_context *context,
    double smooth,
    const double *target,
    size_t target_count,
    const double *prediction,
    size_t prediction_count,
    double *out0);
```

## `deeplearning_core.iou_loss`

`deeplearning_core.iou_loss(smooth, target, prediction, *, dtype='float64')`

Original: [`HMath.DeepLearning.Core.iouLoss`](haskell/HMath-DeepLearning-Core.md#v:iouLoss). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_core_iou_loss_f64(
    hmath_context *context,
    double smooth,
    const double *target,
    size_t target_count,
    const double *prediction,
    size_t prediction_count,
    double *out0);
```

## `deeplearning_metrics.perplexity`

`deeplearning_metrics.perplexity(logs, *, dtype='float64')`

Original: [`HMath.DeepLearning.Metrics.perplexity`](haskell/HMath-DeepLearning-Metrics.md#v:perplexity). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_metrics_perplexity_f64(
    hmath_context *context,
    const double *logs,
    size_t logs_count,
    double *out0);
```

## `deeplearning_metrics.margin_ranking_loss`

`deeplearning_metrics.margin_ranking_loss(margin, labels, left, right, *, dtype='float64')`

Original: [`HMath.DeepLearning.Metrics.marginRankingLoss`](haskell/HMath-DeepLearning-Metrics.md#v:marginRankingLoss). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_metrics_margin_ranking_loss_f64(
    hmath_context *context,
    double margin,
    const double *labels,
    size_t labels_count,
    const double *left,
    size_t left_count,
    const double *right,
    size_t right_count,
    double *out0);
```

## `deeplearning_precision.gradient_norm`

`deeplearning_precision.gradient_norm(xs, *, dtype='float64')`

Original: [`HMath.DeepLearning.Precision.gradientNorm`](haskell/HMath-DeepLearning-Precision.md#v:gradientNorm). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_precision_gradient_norm_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `deeplearning_precision.clip_gradients`

`deeplearning_precision.clip_gradients(argument1, argument2, *, dtype='float64')`

Original: [`HMath.DeepLearning.Precision.clipGradients`](haskell/HMath-DeepLearning-Precision.md#v:clipGradients). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_deeplearning_precision_clip_gradients_f64(
    hmath_context *context,
    double argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

## `discrete.set_union`

`discrete.set_union(a, b, *, dtype='float64')`

Original: [`HMath.Discrete.setUnion`](haskell/HMath-Discrete.md#v:setUnion). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_discrete_set_union_f32(
    hmath_context *context,
    const float *a,
    size_t a_count,
    const float *b,
    size_t b_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_discrete_set_union_f64(
    hmath_context *context,
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double **out_data,
    size_t *out_count);
```

## `discrete.set_intersection`

`discrete.set_intersection(a, b, *, dtype='float64')`

Original: [`HMath.Discrete.setIntersection`](haskell/HMath-Discrete.md#v:setIntersection). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_discrete_set_intersection_f32(
    hmath_context *context,
    const float *a,
    size_t a_count,
    const float *b,
    size_t b_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_discrete_set_intersection_f64(
    hmath_context *context,
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double **out_data,
    size_t *out_count);
```

## `discrete.set_difference`

`discrete.set_difference(a, b, *, dtype='float64')`

Original: [`HMath.Discrete.setDifference`](haskell/HMath-Discrete.md#v:setDifference). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_discrete_set_difference_f32(
    hmath_context *context,
    const float *a,
    size_t a_count,
    const float *b,
    size_t b_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_discrete_set_difference_f64(
    hmath_context *context,
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double **out_data,
    size_t *out_count);
```

## `discrete.symmetric_difference`

`discrete.symmetric_difference(a, b, *, dtype='float64')`

Original: [`HMath.Discrete.symmetricDifference`](haskell/HMath-Discrete.md#v:symmetricDifference). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_discrete_symmetric_difference_f32(
    hmath_context *context,
    const float *a,
    size_t a_count,
    const float *b,
    size_t b_count,
    float **out_data,
    size_t *out_count);
```

```c
hmath_status hmath_discrete_symmetric_difference_f64(
    hmath_context *context,
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double **out_data,
    size_t *out_count);
```

## `fourier.frequencies`

`fourier.frequencies(n, spacing, *, dtype='float64')`

Original: [`HMath.Fourier.frequencies`](haskell/HMath-Fourier.md#v:frequencies). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_fourier_frequencies_f64(
    hmath_context *context,
    ptrdiff_t n,
    double spacing,
    double **out_data,
    size_t *out_count);
```

## `fourier.fft_shift`

`fourier.fft_shift(xs, *, dtype='float64')`

Original: [`HMath.Fourier.fftShift`](haskell/HMath-Fourier.md#v:fftShift). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_fourier_fft_shift_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `fourier.ifft_shift`

`fourier.ifft_shift(xs, *, dtype='float64')`

Original: [`HMath.Fourier.ifftShift`](haskell/HMath-Fourier.md#v:ifftShift). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_fourier_ifft_shift_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `fourier.hartley`

`fourier.hartley(xs, *, dtype='float64')`

Original: [`HMath.Fourier.hartley`](haskell/HMath-Fourier.md#v:hartley). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_fourier_hartley_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `fourier.periodogram`

`fourier.periodogram(rate, window, xs, *, dtype='float64')`

Original: [`HMath.Fourier.periodogram`](haskell/HMath-Fourier.md#v:periodogram). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_fourier_periodogram_f64(
    hmath_context *context,
    double rate,
    const double *window,
    size_t window_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `fourier.welch`

`fourier.welch(rate, window, hop, xs, *, dtype='float64')`

Original: [`HMath.Fourier.welch`](haskell/HMath-Fourier.md#v:welch). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_fourier_welch_f64(
    hmath_context *context,
    double rate,
    const double *window,
    size_t window_count,
    ptrdiff_t hop,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `fourier.cepstrum`

`fourier.cepstrum(floorValue, xs, *, dtype='float64')`

Original: [`HMath.Fourier.cepstrum`](haskell/HMath-Fourier.md#v:cepstrum). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_fourier_cepstrum_f64(
    hmath_context *context,
    double floorValue,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `fourier.hilbert`

`fourier.hilbert(xs, *, dtype='float64')`

Original: [`HMath.Fourier.hilbert`](haskell/HMath-Fourier.md#v:hilbert). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_fourier_hilbert_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `geometry_primitives.hamming_distance`

`geometry_primitives.hamming_distance(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Geometry.Primitives.hammingDistance`](haskell/HMath-Geometry-Primitives.md#v:hammingDistance). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_geometry_primitives_hamming_distance_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_geometry_primitives_hamming_distance_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    ptrdiff_t *out0);
```

## `geometry_primitives.jaccard_distance`

`geometry_primitives.jaccard_distance(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Geometry.Primitives.jaccardDistance`](haskell/HMath-Geometry-Primitives.md#v:jaccardDistance). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_geometry_primitives_jaccard_distance_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double *out0);
```

## `graph_core.finite`

`graph_core.finite(x, *, dtype='float64')`

Original: [`HMath.Graph.Core.finite`](haskell/HMath-Graph-Core.md#v:finite). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_graph_core_finite_f64(
    hmath_context *context,
    double x,
    int *out0);
```

## `image_color.srgb_to_linear`

`image_color.srgb_to_linear(x, *, dtype='float64')`

Original: [`HMath.Image.Color.srgbToLinear`](haskell/HMath-Image-Color.md#v:srgbToLinear). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_image_color_srgb_to_linear_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `image_color.linear_to_srgb`

`image_color.linear_to_srgb(x, *, dtype='float64')`

Original: [`HMath.Image.Color.linearToSrgb`](haskell/HMath-Image-Color.md#v:linearToSrgb). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_image_color_linear_to_srgb_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `interpolation.evaluate_chebyshev`

`interpolation.evaluate_chebyshev(cs, a, b, x, *, dtype='float64')`

Original: [`HMath.Interpolation.evaluateChebyshev`](haskell/HMath-Interpolation.md#v:evaluateChebyshev). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_interpolation_evaluate_chebyshev_f64(
    hmath_context *context,
    const double *cs,
    size_t cs_count,
    double a,
    double b,
    double x,
    double *out0);
```

## `numeric.next_after`

`numeric.next_after(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Numeric.nextAfter`](haskell/HMath-Numeric.md#v:nextAfter). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numeric_next_after_f32(
    hmath_context *context,
    float argument1,
    float argument2,
    float *out0);
```

```c
hmath_status hmath_numeric_next_after_f64(
    hmath_context *context,
    double argument1,
    double argument2,
    double *out0);
```

## `numeric.ldexp`

`numeric.ldexp(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Numeric.ldexp`](haskell/HMath-Numeric.md#v:ldexp). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numeric_ldexp_f32(
    hmath_context *context,
    float argument1,
    ptrdiff_t argument2,
    float *out0);
```

```c
hmath_status hmath_numeric_ldexp_f64(
    hmath_context *context,
    double argument1,
    ptrdiff_t argument2,
    double *out0);
```

## `numeric.ulp_distance`

`numeric.ulp_distance(a, b, *, dtype='float64')`

Original: [`HMath.Numeric.ulpDistance`](haskell/HMath-Numeric.md#v:ulpDistance). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numeric_ulp_distance_f64(
    hmath_context *context,
    double a,
    double b,
    char **out0);
```

## `numeric.within_u_l_ps`

`numeric.within_u_l_ps(n, a, b, *, dtype='float64')`

Original: [`HMath.Numeric.withinULPs`](haskell/HMath-Numeric.md#v:withinULPs). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numeric_within_u_l_ps_f64(
    hmath_context *context,
    const char *n,
    double a,
    double b,
    int *out0);
```

## `numeric.kahan_sum`

`numeric.kahan_sum(argument1, *, dtype='float64')`

Original: [`HMath.Numeric.kahanSum`](haskell/HMath-Numeric.md#v:kahanSum). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numeric_kahan_sum_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0);
```

```c
hmath_status hmath_numeric_kahan_sum_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0);
```

## `numeric.neumaier_sum`

`numeric.neumaier_sum(argument1, *, dtype='float64')`

Original: [`HMath.Numeric.neumaierSum`](haskell/HMath-Numeric.md#v:neumaierSum). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numeric_neumaier_sum_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0);
```

```c
hmath_status hmath_numeric_neumaier_sum_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0);
```

## `numeric.pairwise_sum`

`numeric.pairwise_sum(argument1, *, dtype='float64')`

Original: [`HMath.Numeric.pairwiseSum`](haskell/HMath-Numeric.md#v:pairwiseSum). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numeric_pairwise_sum_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0);
```

```c
hmath_status hmath_numeric_pairwise_sum_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0);
```

## `numeric.logsumexp`

`numeric.logsumexp(argument1, *, dtype='float64')`

Original: [`HMath.Numeric.logsumexp`](haskell/HMath-Numeric.md#v:logsumexp). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numeric_logsumexp_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0);
```

```c
hmath_status hmath_numeric_logsumexp_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0);
```

## `numeric.sum_error_bound`

`numeric.sum_error_bound(argument1, *, dtype='float64')`

Original: [`HMath.Numeric.sumErrorBound`](haskell/HMath-Numeric.md#v:sumErrorBound). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_numeric_sum_error_bound_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0);
```

```c
hmath_status hmath_numeric_sum_error_bound_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0);
```

## `optimization_common.dot`

`optimization_common.dot(a, b, *, dtype='float64')`

Original: [`HMath.Optimization.Common.dot`](haskell/HMath-Optimization-Common.md#v:dot). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_optimization_common_dot_f64(
    hmath_context *context,
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double *out0);
```

## `optimization_common.norm`

`optimization_common.norm(xs, *, dtype='float64')`

Original: [`HMath.Optimization.Common.norm`](haskell/HMath-Optimization-Common.md#v:norm). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_optimization_common_norm_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `optimization_common.add`

`optimization_common.add(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Optimization.Common.add`](haskell/HMath-Optimization-Common.md#v:add). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_optimization_common_add_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

## `optimization_common.sub`

`optimization_common.sub(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Optimization.Common.sub`](haskell/HMath-Optimization-Common.md#v:sub). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_optimization_common_sub_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

## `optimization_common.scale`

`optimization_common.scale(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Optimization.Common.scale`](haskell/HMath-Optimization-Common.md#v:scale). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_optimization_common_scale_f64(
    hmath_context *context,
    double argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

## `random.importance`

`random.importance(values, weights, *, dtype='float64')`

Original: [`HMath.Random.importance`](haskell/HMath-Random.md#v:importance). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_random_importance_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    const double *weights,
    size_t weights_count,
    double *out0);
```

## `random.halton`

`random.halton(dimension, index, *, dtype='float64')`

Original: [`HMath.Random.halton`](haskell/HMath-Random.md#v:halton). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_random_halton_f64(
    hmath_context *context,
    ptrdiff_t dimension,
    ptrdiff_t index,
    double **out_data,
    size_t *out_count);
```

## `random.sobol`

`random.sobol(dimension, index, *, dtype='float64')`

Original: [`HMath.Random.sobol`](haskell/HMath-Random.md#v:sobol). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_random_sobol_f64(
    hmath_context *context,
    ptrdiff_t dimension,
    ptrdiff_t index,
    double **out_data,
    size_t *out_count);
```

## `random.faure`

`random.faure(d, ix, *, dtype='float64')`

Original: [`HMath.Random.faure`](haskell/HMath-Random.md#v:faure). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_random_faure_f64(
    hmath_context *context,
    ptrdiff_t d,
    ptrdiff_t ix,
    double **out_data,
    size_t *out_count);
```

## `signal.convolution`

`signal.convolution(xs, ys, *, dtype='float64')`

Original: [`HMath.Signal.convolution`](haskell/HMath-Signal.md#v:convolution). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_convolution_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double **out_data,
    size_t *out_count);
```

## `signal.circular_convolution`

`signal.circular_convolution(x, y, *, dtype='float64')`

Original: [`HMath.Signal.circularConvolution`](haskell/HMath-Signal.md#v:circularConvolution). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_circular_convolution_f64(
    hmath_context *context,
    const double *x,
    size_t x_count,
    const double *y,
    size_t y_count,
    double **out_data,
    size_t *out_count);
```

## `signal.correlation`

`signal.correlation(x, y, *, dtype='float64')`

Original: [`HMath.Signal.correlation`](haskell/HMath-Signal.md#v:correlation). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_correlation_f64(
    hmath_context *context,
    const double *x,
    size_t x_count,
    const double *y,
    size_t y_count,
    double **out_data,
    size_t *out_count);
```

## `signal.autocorrelation`

`signal.autocorrelation(x, *, dtype='float64')`

Original: [`HMath.Signal.autocorrelation`](haskell/HMath-Signal.md#v:autocorrelation). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_autocorrelation_f64(
    hmath_context *context,
    const double *x,
    size_t x_count,
    double **out_data,
    size_t *out_count);
```

## `signal.overlap_add`

`signal.overlap_add(block, kernel, xs, *, dtype='float64')`

Original: [`HMath.Signal.overlapAdd`](haskell/HMath-Signal.md#v:overlapAdd). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_overlap_add_f64(
    hmath_context *context,
    ptrdiff_t block,
    const double *kernel,
    size_t kernel_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.overlap_save`

`signal.overlap_save(fftLength, kernel, xs, *, dtype='float64')`

Original: [`HMath.Signal.overlapSave`](haskell/HMath-Signal.md#v:overlapSave). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_overlap_save_f64(
    hmath_context *context,
    ptrdiff_t fftLength,
    const double *kernel,
    size_t kernel_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.moving_average`

`signal.moving_average(count, xs, *, dtype='float64')`

Original: [`HMath.Signal.movingAverage`](haskell/HMath-Signal.md#v:movingAverage). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_moving_average_f64(
    hmath_context *context,
    ptrdiff_t count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.median_filter`

`signal.median_filter(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Signal.medianFilter`](haskell/HMath-Signal.md#v:medianFilter). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_median_filter_f64(
    hmath_context *context,
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

## `signal.gaussian_filter`

`signal.gaussian_filter(width, sigma, xs, *, dtype='float64')`

Original: [`HMath.Signal.gaussianFilter`](haskell/HMath-Signal.md#v:gaussianFilter). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_gaussian_filter_f64(
    hmath_context *context,
    ptrdiff_t width,
    double sigma,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.savitzky_golay`

`signal.savitzky_golay(width, degree, derivative, spacing, xs, *, dtype='float64')`

Original: [`HMath.Signal.savitzkyGolay`](haskell/HMath-Signal.md#v:savitzkyGolay). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_savitzky_golay_f64(
    hmath_context *context,
    ptrdiff_t width,
    ptrdiff_t degree,
    ptrdiff_t derivative,
    double spacing,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.downsample`

`signal.downsample(factor, offset, xs, *, dtype='float64')`

Original: [`HMath.Signal.downsample`](haskell/HMath-Signal.md#v:downsample). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_downsample_f64(
    hmath_context *context,
    ptrdiff_t factor,
    ptrdiff_t offset,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.upsample`

`signal.upsample(factor, xs, *, dtype='float64')`

Original: [`HMath.Signal.upsample`](haskell/HMath-Signal.md#v:upsample). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_upsample_f64(
    hmath_context *context,
    ptrdiff_t factor,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.resample_polyphase`

`signal.resample_polyphase(up, down, kernel, xs, *, dtype='float64')`

Original: [`HMath.Signal.resamplePolyphase`](haskell/HMath-Signal.md#v:resamplePolyphase). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_resample_polyphase_f64(
    hmath_context *context,
    ptrdiff_t up,
    ptrdiff_t down,
    const double *kernel,
    size_t kernel_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.resample`

`signal.resample(up, down, taps, xs, *, dtype='float64')`

Original: [`HMath.Signal.resample`](haskell/HMath-Signal.md#v:resample). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_resample_f64(
    hmath_context *context,
    ptrdiff_t up,
    ptrdiff_t down,
    ptrdiff_t taps,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.anti_alias`

`signal.anti_alias(factor, taps, xs, *, dtype='float64')`

Original: [`HMath.Signal.antiAlias`](haskell/HMath-Signal.md#v:antiAlias). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_anti_alias_f64(
    hmath_context *context,
    ptrdiff_t factor,
    ptrdiff_t taps,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.zero_crossings`

`signal.zero_crossings(xs, *, dtype='float64')`

Original: [`HMath.Signal.zeroCrossings`](haskell/HMath-Signal.md#v:zeroCrossings). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_zero_crossings_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.envelope`

`signal.envelope(xs, *, dtype='float64')`

Original: [`HMath.Signal.envelope`](haskell/HMath-Signal.md#v:envelope). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_envelope_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.unwrap_phase`

`signal.unwrap_phase(xs, *, dtype='float64')`

Original: [`HMath.Signal.unwrapPhase`](haskell/HMath-Signal.md#v:unwrapPhase). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_unwrap_phase_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.detrend`

`signal.detrend(linear, xs, *, dtype='float64')`

Original: [`HMath.Signal.detrend`](haskell/HMath-Signal.md#v:detrend). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_detrend_f64(
    hmath_context *context,
    int linear,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.normalize`

`signal.normalize(xs, *, dtype='float64')`

Original: [`HMath.Signal.normalize`](haskell/HMath-Signal.md#v:normalize). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_normalize_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `signal.smooth`

`signal.smooth(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Signal.smooth`](haskell/HMath-Signal.md#v:smooth). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_smooth_f64(
    hmath_context *context,
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
```

## `signal.noise_estimate`

`signal.noise_estimate(xs, *, dtype='float64')`

Original: [`HMath.Signal.noiseEstimate`](haskell/HMath-Signal.md#v:noiseEstimate). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_noise_estimate_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `signal.signal_to_noise`

`signal.signal_to_noise(signal, noise, *, dtype='float64')`

Original: [`HMath.Signal.signalToNoise`](haskell/HMath-Signal.md#v:signalToNoise). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_signal_to_noise_f64(
    hmath_context *context,
    const double *signal,
    size_t signal_count,
    const double *noise,
    size_t noise_count,
    double *out0);
```

## `signal.rms`

`signal.rms(xs, *, dtype='float64')`

Original: [`HMath.Signal.rms`](haskell/HMath-Signal.md#v:rms). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_signal_rms_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.arithmetic_mean`

`statistics_advanced.arithmetic_mean(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.arithmeticMean`](haskell/HMath-Statistics-Advanced.md#v:arithmeticMean). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_arithmetic_mean_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.weighted_mean`

`statistics_advanced.weighted_mean(xs, ws, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.weightedMean`](haskell/HMath-Statistics-Advanced.md#v:weightedMean). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_weighted_mean_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    const double *ws,
    size_t ws_count,
    double *out0);
```

## `statistics_advanced.geometric_mean`

`statistics_advanced.geometric_mean(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.geometricMean`](haskell/HMath-Statistics-Advanced.md#v:geometricMean). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_geometric_mean_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.harmonic_mean`

`statistics_advanced.harmonic_mean(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.harmonicMean`](haskell/HMath-Statistics-Advanced.md#v:harmonicMean). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_harmonic_mean_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.rms`

`statistics_advanced.rms(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.rms`](haskell/HMath-Statistics-Advanced.md#v:rms). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_rms_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.trimmed_mean`

`statistics_advanced.trimmed_mean(fraction, xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.trimmedMean`](haskell/HMath-Statistics-Advanced.md#v:trimmedMean). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_trimmed_mean_f64(
    hmath_context *context,
    double fraction,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.winsorized_mean`

`statistics_advanced.winsorized_mean(fraction, xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.winsorizedMean`](haskell/HMath-Statistics-Advanced.md#v:winsorizedMean). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_winsorized_mean_f64(
    hmath_context *context,
    double fraction,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.quantile`

`statistics_advanced.quantile(p, xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.quantile`](haskell/HMath-Statistics-Advanced.md#v:quantile). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_quantile_f64(
    hmath_context *context,
    double p,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.median`

`statistics_advanced.median(argument1, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.median`](haskell/HMath-Statistics-Advanced.md#v:median). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_median_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0);
```

## `statistics_advanced.percentile`

`statistics_advanced.percentile(argument1, argument2, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.percentile`](haskell/HMath-Statistics-Advanced.md#v:percentile). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_percentile_f64(
    hmath_context *context,
    double argument1,
    const double *argument2,
    size_t argument2_count,
    double *out0);
```

## `statistics_advanced.modes`

`statistics_advanced.modes(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.modes`](haskell/HMath-Statistics-Advanced.md#v:modes). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_modes_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `statistics_advanced.interquartile_range`

`statistics_advanced.interquartile_range(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.interquartileRange`](haskell/HMath-Statistics-Advanced.md#v:interquartileRange). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_interquartile_range_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.median_absolute_deviation`

`statistics_advanced.median_absolute_deviation(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.medianAbsoluteDeviation`](haskell/HMath-Statistics-Advanced.md#v:medianAbsoluteDeviation). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_median_absolute_deviation_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.data_range`

`statistics_advanced.data_range(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.dataRange`](haskell/HMath-Statistics-Advanced.md#v:dataRange). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_data_range_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.central_moment`

`statistics_advanced.central_moment(k, xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.centralMoment`](haskell/HMath-Statistics-Advanced.md#v:centralMoment). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_central_moment_f64(
    hmath_context *context,
    ptrdiff_t k,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.population_variance`

`statistics_advanced.population_variance(argument1, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.populationVariance`](haskell/HMath-Statistics-Advanced.md#v:populationVariance). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_population_variance_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0);
```

## `statistics_advanced.sample_variance`

`statistics_advanced.sample_variance(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.sampleVariance`](haskell/HMath-Statistics-Advanced.md#v:sampleVariance). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_sample_variance_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.population_s_d`

`statistics_advanced.population_s_d(argument1, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.populationSD`](haskell/HMath-Statistics-Advanced.md#v:populationSD). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_population_s_d_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0);
```

## `statistics_advanced.sample_s_d`

`statistics_advanced.sample_s_d(argument1, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.sampleSD`](haskell/HMath-Statistics-Advanced.md#v:sampleSD). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_sample_s_d_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0);
```

## `statistics_advanced.coefficient_of_variation`

`statistics_advanced.coefficient_of_variation(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.coefficientOfVariation`](haskell/HMath-Statistics-Advanced.md#v:coefficientOfVariation). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_coefficient_of_variation_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.skewness`

`statistics_advanced.skewness(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.skewness`](haskell/HMath-Statistics-Advanced.md#v:skewness). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_skewness_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.kurtosis`

`statistics_advanced.kurtosis(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.kurtosis`](haskell/HMath-Statistics-Advanced.md#v:kurtosis). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_kurtosis_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.covariance`

`statistics_advanced.covariance(sampleCorrection, xs, ys, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.covariance`](haskell/HMath-Statistics-Advanced.md#v:covariance). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_covariance_f64(
    hmath_context *context,
    int sampleCorrection,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
```

## `statistics_advanced.correlation`

`statistics_advanced.correlation(xs, ys, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.correlation`](haskell/HMath-Statistics-Advanced.md#v:correlation). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_correlation_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
```

## `statistics_advanced.spearman`

`statistics_advanced.spearman(xs, ys, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.spearman`](haskell/HMath-Statistics-Advanced.md#v:spearman). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_spearman_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
```

## `statistics_advanced.kendall`

`statistics_advanced.kendall(xs, ys, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.kendall`](haskell/HMath-Statistics-Advanced.md#v:kendall). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_kendall_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
```

## `statistics_advanced.autocorrelation`

`statistics_advanced.autocorrelation(lag, xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.autocorrelation`](haskell/HMath-Statistics-Advanced.md#v:autocorrelation). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_autocorrelation_f64(
    hmath_context *context,
    ptrdiff_t lag,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.cross_correlation`

`statistics_advanced.cross_correlation(lag, xs, ys, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.crossCorrelation`](haskell/HMath-Statistics-Advanced.md#v:crossCorrelation). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_cross_correlation_f64(
    hmath_context *context,
    ptrdiff_t lag,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
```

## `statistics_advanced.moving_average`

`statistics_advanced.moving_average(window, xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.movingAverage`](haskell/HMath-Statistics-Advanced.md#v:movingAverage). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_moving_average_f64(
    hmath_context *context,
    ptrdiff_t window,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `statistics_advanced.moving_variance`

`statistics_advanced.moving_variance(window, xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.movingVariance`](haskell/HMath-Statistics-Advanced.md#v:movingVariance). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_moving_variance_f64(
    hmath_context *context,
    ptrdiff_t window,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `statistics_advanced.exponential_moving_average`

`statistics_advanced.exponential_moving_average(alpha, xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.exponentialMovingAverage`](haskell/HMath-Statistics-Advanced.md#v:exponentialMovingAverage). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_exponential_moving_average_f64(
    hmath_context *context,
    double alpha,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `statistics_advanced.entropy`

`statistics_advanced.entropy(ps, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.entropy`](haskell/HMath-Statistics-Advanced.md#v:entropy). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_entropy_f64(
    hmath_context *context,
    const double *ps,
    size_t ps_count,
    double *out0);
```

## `statistics_advanced.kl_divergence`

`statistics_advanced.kl_divergence(p, q, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.klDivergence`](haskell/HMath-Statistics-Advanced.md#v:klDivergence). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_kl_divergence_f64(
    hmath_context *context,
    const double *p,
    size_t p_count,
    const double *q,
    size_t q_count,
    double *out0);
```

## `statistics_advanced.js_divergence`

`statistics_advanced.js_divergence(p, q, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.jsDivergence`](haskell/HMath-Statistics-Advanced.md#v:jsDivergence). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_js_divergence_f64(
    hmath_context *context,
    const double *p,
    size_t p_count,
    const double *q,
    size_t q_count,
    double *out0);
```

## `statistics_advanced.z_scores`

`statistics_advanced.z_scores(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.zScores`](haskell/HMath-Statistics-Advanced.md#v:zScores). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_z_scores_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `statistics_advanced.standard_error`

`statistics_advanced.standard_error(xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.standardError`](haskell/HMath-Statistics-Advanced.md#v:standardError). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_standard_error_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `statistics_advanced.confidence_interval`

`statistics_advanced.confidence_interval(level, xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.confidenceInterval`](haskell/HMath-Statistics-Advanced.md#v:confidenceInterval). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_confidence_interval_f64(
    hmath_context *context,
    double level,
    const double *xs,
    size_t xs_count,
    double *out0,
    double *out1);
```

## `statistics_advanced.bonferroni`

`statistics_advanced.bonferroni(ps, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.bonferroni`](haskell/HMath-Statistics-Advanced.md#v:bonferroni). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_bonferroni_f64(
    hmath_context *context,
    const double *ps,
    size_t ps_count,
    double **out_data,
    size_t *out_count);
```

## `statistics_advanced.benjamini_hochberg`

`statistics_advanced.benjamini_hochberg(ps, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.benjaminiHochberg`](haskell/HMath-Statistics-Advanced.md#v:benjaminiHochberg). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_benjamini_hochberg_f64(
    hmath_context *context,
    const double *ps,
    size_t ps_count,
    double **out_data,
    size_t *out_count);
```

## `statistics_advanced.cohens_d`

`statistics_advanced.cohens_d(xs, ys, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.cohensD`](haskell/HMath-Statistics-Advanced.md#v:cohensD). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_cohens_d_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
```

## `statistics_advanced.normal_test_power`

`statistics_advanced.normal_test_power(alpha, standardizedEffect, n, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.normalTestPower`](haskell/HMath-Statistics-Advanced.md#v:normalTestPower). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_normal_test_power_f64(
    hmath_context *context,
    double alpha,
    double standardizedEffect,
    ptrdiff_t n,
    double *out0);
```

## `statistics_advanced.normal_sample_size`

`statistics_advanced.normal_sample_size(alpha, power, effect, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.normalSampleSize`](haskell/HMath-Statistics-Advanced.md#v:normalSampleSize). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_normal_sample_size_f64(
    hmath_context *context,
    double alpha,
    double power,
    double effect,
    ptrdiff_t *out0);
```

## `statistics_advanced.tukey_outliers`

`statistics_advanced.tukey_outliers(multiplier, xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.tukeyOutliers`](haskell/HMath-Statistics-Advanced.md#v:tukeyOutliers). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_tukey_outliers_f64(
    hmath_context *context,
    double multiplier,
    const double *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

## `statistics_advanced.huber_location`

`statistics_advanced.huber_location(tuning, xs, *, dtype='float64')`

Original: [`HMath.Statistics.Advanced.huberLocation`](haskell/HMath-Statistics-Advanced.md#v:huberLocation). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_statistics_advanced_huber_location_f64(
    hmath_context *context,
    double tuning,
    const double *xs,
    size_t xs_count,
    double *out0);
```

## `tensor.shape_size`

`tensor.shape_size(dims)`

Original: [`HMath.Tensor.shapeSize`](haskell/HMath-Tensor.md#v:shapeSize). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_tensor_shape_size(
    hmath_context *context,
    ptrdiff_t const *dims,
    size_t dims_count,
    ptrdiff_t *out0);
```

## `tensor.infer_broadcast`

`tensor.infer_broadcast(as_, bs)`

Original: [`HMath.Tensor.inferBroadcast`](haskell/HMath-Tensor.md#v:inferBroadcast). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_tensor_infer_broadcast(
    hmath_context *context,
    ptrdiff_t const *as,
    size_t as_count,
    ptrdiff_t const *bs,
    size_t bs_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

## `timeseries_core.exponential_average`

`timeseries_core.exponential_average(alpha, xs, *, dtype='float64')`

Original: [`HMath.TimeSeries.Core.exponentialAverage`](haskell/HMath-TimeSeries-Core.md#v:exponentialAverage). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_timeseries_core_exponential_average_f64(
    hmath_context *context,
    double alpha,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `timeseries_core.weighted_average`

`timeseries_core.weighted_average(ws, xs, *, dtype='float64')`

Original: [`HMath.TimeSeries.Core.weightedAverage`](haskell/HMath-TimeSeries-Core.md#v:weightedAverage). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_timeseries_core_weighted_average_f64(
    hmath_context *context,
    const double *ws,
    size_t ws_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `timeseries_core.cumulative_returns`

`timeseries_core.cumulative_returns(xs, *, dtype='float64')`

Original: [`HMath.TimeSeries.Core.cumulativeReturns`](haskell/HMath-TimeSeries-Core.md#v:cumulativeReturns). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_timeseries_core_cumulative_returns_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `timeseries_core.logarithmic_returns`

`timeseries_core.logarithmic_returns(xs, *, dtype='float64')`

Original: [`HMath.TimeSeries.Core.logarithmicReturns`](haskell/HMath-TimeSeries-Core.md#v:logarithmicReturns). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_timeseries_core_logarithmic_returns_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `timeseries_core.difference`

`timeseries_core.difference(order, lag, xs, *, dtype='float64')`

Original: [`HMath.TimeSeries.Core.difference`](haskell/HMath-TimeSeries-Core.md#v:difference). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_timeseries_core_difference_f64(
    hmath_context *context,
    ptrdiff_t order,
    ptrdiff_t lag,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `timeseries_core.autocorrelation`

`timeseries_core.autocorrelation(lags, xs, *, dtype='float64')`

Original: [`HMath.TimeSeries.Core.autocorrelation`](haskell/HMath-TimeSeries-Core.md#v:autocorrelation). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_timeseries_core_autocorrelation_f64(
    hmath_context *context,
    ptrdiff_t lags,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `timeseries_core.cross_correlation`

`timeseries_core.cross_correlation(lag, xs, ys, *, dtype='float64')`

Original: [`HMath.TimeSeries.Core.crossCorrelation`](haskell/HMath-TimeSeries-Core.md#v:crossCorrelation). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_timeseries_core_cross_correlation_f64(
    hmath_context *context,
    ptrdiff_t lag,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
```

## `timeseries_core.partial_autocorrelation`

`timeseries_core.partial_autocorrelation(order, xs, *, dtype='float64')`

Original: [`HMath.TimeSeries.Core.partialAutocorrelation`](haskell/HMath-TimeSeries-Core.md#v:partialAutocorrelation). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_timeseries_core_partial_autocorrelation_f64(
    hmath_context *context,
    ptrdiff_t order,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
```

## `timeseries_diagnostics.change_points`

`timeseries_diagnostics.change_points(penalty, minSegment, xs, *, dtype='float64')`

Original: [`HMath.TimeSeries.Diagnostics.changePoints`](haskell/HMath-TimeSeries-Diagnostics.md#v:changePoints). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_timeseries_diagnostics_change_points_f64(
    hmath_context *context,
    double penalty,
    ptrdiff_t minSegment,
    const double *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

## `timeseries_diagnostics.cusum`

`timeseries_diagnostics.cusum(mean, sd, drift, threshold, xs, *, dtype='float64')`

Original: [`HMath.TimeSeries.Diagnostics.cusum`](haskell/HMath-TimeSeries-Diagnostics.md#v:cusum). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_timeseries_diagnostics_cusum_f64(
    hmath_context *context,
    double mean,
    double sd,
    double drift,
    double threshold,
    const double *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

## `timeseries_diagnostics.anomalies`

`timeseries_diagnostics.anomalies(threshold, xs, *, dtype='float64')`

Original: [`HMath.TimeSeries.Diagnostics.anomalies`](haskell/HMath-TimeSeries-Diagnostics.md#v:anomalies). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_timeseries_diagnostics_anomalies_f64(
    hmath_context *context,
    double threshold,
    const double *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count);
```

## `units.radians_to_degrees`

`units.radians_to_degrees(x, *, dtype='float64')`

Original: [`HMath.Units.radiansToDegrees`](haskell/HMath-Units.md#v:radiansToDegrees). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_units_radians_to_degrees_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_units_radians_to_degrees_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `units.degrees_to_radians`

`units.degrees_to_radians(x, *, dtype='float64')`

Original: [`HMath.Units.degreesToRadians`](haskell/HMath-Units.md#v:degreesToRadians). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_units_degrees_to_radians_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_units_degrees_to_radians_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `units.radians_to_gradians`

`units.radians_to_gradians(x, *, dtype='float64')`

Original: [`HMath.Units.radiansToGradians`](haskell/HMath-Units.md#v:radiansToGradians). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_units_radians_to_gradians_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_units_radians_to_gradians_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `units.gradians_to_radians`

`units.gradians_to_radians(x, *, dtype='float64')`

Original: [`HMath.Units.gradiansToRadians`](haskell/HMath-Units.md#v:gradiansToRadians). The linked contract defines the operation, valid inputs, result and mathematical errors.

```c
hmath_status hmath_units_gradians_to_radians_f32(
    hmath_context *context,
    float x,
    float *out0);
```

```c
hmath_status hmath_units_gradians_to_radians_f64(
    hmath_context *context,
    double x,
    double *out0);
```

## `scalar.saturating_add`

`scalar.saturating_add(a, b, *, dtype='intp')`

Original: [`HMath.Scalar.saturatingAdd`](haskell/HMath-Scalar.md#v:saturatingAdd). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`.

```c
hmath_status hmath_scalar_saturating_add_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_saturating_add_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_saturating_add_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_saturating_add_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_saturating_add_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_saturating_add_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_saturating_add_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_saturating_add_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_saturating_add_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_saturating_add_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0);
```

## `scalar.saturating_subtract`

`scalar.saturating_subtract(a, b, *, dtype='intp')`

Original: [`HMath.Scalar.saturatingSubtract`](haskell/HMath-Scalar.md#v:saturatingSubtract). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`.

```c
hmath_status hmath_scalar_saturating_subtract_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_saturating_subtract_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_saturating_subtract_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_saturating_subtract_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_saturating_subtract_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_saturating_subtract_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_saturating_subtract_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_saturating_subtract_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_saturating_subtract_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_saturating_subtract_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0);
```

## `scalar.saturating_multiply`

`scalar.saturating_multiply(a, b, *, dtype='intp')`

Original: [`HMath.Scalar.saturatingMultiply`](haskell/HMath-Scalar.md#v:saturatingMultiply). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`.

```c
hmath_status hmath_scalar_saturating_multiply_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_saturating_multiply_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_saturating_multiply_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_saturating_multiply_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_saturating_multiply_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_saturating_multiply_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_saturating_multiply_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_saturating_multiply_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_saturating_multiply_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_saturating_multiply_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0);
```

## `scalar.checked_add`

`scalar.checked_add(a, b, *, dtype='intp')`

Original: [`HMath.Scalar.checkedAdd`](haskell/HMath-Scalar.md#v:checkedAdd). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`.

```c
hmath_status hmath_scalar_checked_add_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_checked_add_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_checked_add_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_checked_add_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_checked_add_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_checked_add_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_checked_add_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_checked_add_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_checked_add_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_checked_add_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0);
```

## `scalar.checked_subtract`

`scalar.checked_subtract(a, b, *, dtype='intp')`

Original: [`HMath.Scalar.checkedSubtract`](haskell/HMath-Scalar.md#v:checkedSubtract). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`.

```c
hmath_status hmath_scalar_checked_subtract_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_checked_subtract_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_checked_subtract_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_checked_subtract_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_checked_subtract_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_checked_subtract_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_checked_subtract_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_checked_subtract_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_checked_subtract_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_checked_subtract_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0);
```

## `scalar.checked_multiply`

`scalar.checked_multiply(a, b, *, dtype='intp')`

Original: [`HMath.Scalar.checkedMultiply`](haskell/HMath-Scalar.md#v:checkedMultiply). The linked contract defines the operation, valid inputs, result and mathematical errors.

Supported `dtype`: `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `intp`, `uintp`.

```c
hmath_status hmath_scalar_checked_multiply_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0);
```

```c
hmath_status hmath_scalar_checked_multiply_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0);
```

```c
hmath_status hmath_scalar_checked_multiply_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0);
```

```c
hmath_status hmath_scalar_checked_multiply_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0);
```

```c
hmath_status hmath_scalar_checked_multiply_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
```

```c
hmath_status hmath_scalar_checked_multiply_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
```

```c
hmath_status hmath_scalar_checked_multiply_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
```

```c
hmath_status hmath_scalar_checked_multiply_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
```

```c
hmath_status hmath_scalar_checked_multiply_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
```

```c
hmath_status hmath_scalar_checked_multiply_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0);
```

