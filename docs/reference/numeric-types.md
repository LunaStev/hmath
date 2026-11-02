# Numeric representations and constants

`hmath.numeric_types` exposes the original `HMath.Numeric` representations and
`HMath.Constants.Constant` records. Numerical operations run in Haskell. Values
retain their precision, scale, software exception flags and constant metadata.
The C declarations are in `hmath_numeric_types.h`; scalar/container transport is
shared with the matrix and polynomial APIs through `hmath_value.h`.

## Python values

```python
from fractions import Fraction
from hmath import numeric_types as n

result = n.big_float(200, n.RoundingMode.NEAREST_EVEN, Fraction(1, 3))
with result, result.rounded_value as value:
    print(n.big_precision(value))       # 200
    print(n.big_rational(value))        # exact stored Rational
    print(result.numerical_exceptions)  # software rounding flags

with n.number(-2, "float32") as point:
    print(n.derivative(lambda x: x**3 + 2*x, point))

with n.speed_of_light() as constant:
    print(n.constant_value(constant))   # Fraction(299792458, 1)
    print(n.constant_unit(constant))
    print(n.constant_source(constant))
```

Factories for structured types return immutable `NumericValue` owners. Close them
explicitly, or use `with`. A returned child owns its data independently of its
parent. Every live owner keeps the Haskell runtime alive. Final runtime shutdown
reports `BUSY` while a native reference is live.

Standard scalar results normally become Python `int`, `float`, `complex` or
`fractions.Fraction`. Pass `boxed=True` to any numerical function to keep its
native coefficient type for another typed operation. `n.number(value, dtype)`
constructs a typed scalar. The `.value` property explicitly decodes a boxed
standard scalar; `.primal`, `.tangent`, `.rounded_value` and `.components` retain
boxed children and their exact types.

Supported scalar dtype names are `float32`, `float64`, `integer`, `rational`,
`complex64`, `complex128`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`,
`uint32`, `uint64`, `intp` and `uintp`. Integer and Rational inputs have no binary
floating conversion. Bounded input constructors reject values outside their
representation. `safe_integral_cast` and `saturating_cast` instead execute the
original Haskell checked/saturating conversion functions.

`NumericValue` arithmetic invokes the original `Num`, `Fractional` or `Floating`
instance. Python integer/rational literals are lifted into that same instance.
Two explicitly boxed operands must have identical Haskell coefficient types;
there is no implicit promotion. Integer exponents use Haskell `(^)` and, for a
negative exponent, `(^^)`. Other exponents use `(**)`. Methods `sin`, `cos`, `exp`,
`log`, `sqrt`, `tan`, `asin`, `acos`, `atan`, `sinh`, `cosh`, `tanh`, `asinh`,
`acosh`, `atanh`, `signum` and `recip` invoke those original instance methods.
Unavailable instances produce `UNSUPPORTED` rather than a replacement algorithm.

## Rounding, representations and records

- `RoundingMode`: `NEAREST_EVEN`, `TOWARD_ZERO`, `TOWARD_POSITIVE`,
  `TOWARD_NEGATIVE`. The host CPU rounding environment is unchanged.
- `NumericException`: `INVALID_OPERATION`, `DIVISION_BY_ZERO`,
  `NUMERIC_OVERFLOW`, `NUMERIC_UNDERFLOW`, `INEXACT`. `Rounded` retains flag order
  and duplicates; the public record constructor applies no extra filtering.
- `IEEEClass`: `NOT_A_NUMBER`, `POSITIVE_INFINITY`, `NEGATIVE_INFINITY`,
  `POSITIVE_ZERO`, `NEGATIVE_ZERO`, `SUBNORMAL`, `NORMAL`.
- `Float16` and `BFloat16`: constructors take the original `Double` input and
  explicit rounding mode. Bit constructors/accessors preserve all 16 input bits,
  including signed zeros, infinities and NaN representations.
- `BigFloat`: precision is retained with the stored exact Rational.
  `big_add`, `big_subtract`, `big_multiply`, `big_divide`, `big_sqrt`, `big_exp`,
  `big_log`, `mixed_add` and `mixed_multiply` use the original implementations and
  precision selection. Inspect `big_precision` and `big_rational` to avoid a
  lossy `big_to_double` conversion.
- `Fixed`: the stored decimal scale and unbounded integer coefficient remain
  available through `fixed_scale` and `fixed_coefficient`. `Decimal` retains its
  original representation; both expose exact Rational getters. The original
  larger-scale and explicit-rounding rules apply to their arithmetic results.
- `Interval`: bounds remain `Double`, with the original outward-rounded
  operations and original division-by-zero interval checks. `interval_contains`
  has the original inclusive membership behavior.
- `NumericLimits`: `numeric_limits` requires an actual `RealFloat` witness,
  currently `Float`/`Double`; `integer_limits` requires a bounded integral
  witness. Dedicated 16-bit limit functions preserve their original `Double`
  metadata fields. `numeric_limits_record` constructs the original record from
  its four value fields and three integer metadata fields. Field accessors do
  not recompute or normalize those values.

## Duals, quaternions and callbacks

`dual(primal_value, tangent_value)` constructs `HMath.Numeric.Dual`, a distinct
source type from the reverse/forward automatic differentiation APIs. Both fields
must have the same coefficient type. Nested Duals preserve that nesting.
`derivative(function, value)` evaluates the original `Numeric.derivative` with a
synchronous Python/C callback over the actual `Numeric.Dual` argument. The
callback must be deterministic. Python exceptions propagate back to the caller;
C callbacks return a status and transfer one owned output reference.

Dual coefficients support the standard scalar types and recursive Duals where
the original instance exists. `Quaternion` can retain standard coefficient
components; its `Num` instance requires `RealFloat` components, so arithmetic is
available for Float/Double components. Norm, inverse, rotation and rigid
transforms enforce their original constraints. A `Dual` of such a Quaternion can
use the original `Num` instance. `DualQuaternion` retains two actual Quaternion
values and provides the original multiplication, inverse and point transform.
No `Ord`, `RealFloat` or `Fractional` instance is invented for Quaternion or Dual.

## Constant metadata

`constant(name, value, uncertainty, approximation, unit, source)` retains all six
original record fields. Values, standard uncertainty and approximation bounds
are exact Rationals, including user-provided signs. Strings preserve every
Haskell `Char`, embedded NUL and surrogate code points without normalization.
`mathematical_constants` and `physical_constants` return the original record
lists in source order. Physical values retain their CODATA/definition provenance
instead of promising an unversioned latest adjustment.

`constant_as(record, dtype)` invokes the original `constantAs` for standard
Fractional types. `constant_as_like(record, prototype)` selects the actual native
Fractional type of a boxed prototype, including a supported nested Numeric.Dual.
These conversions omit metadata by the original contract; retain the record
when reporting uncertainty or provenance.

## C ownership and errors

Every function accepts an optional `hmath_context *` and writes a new owned
`hmath_numeric_value *` through its final output argument. The typedef aliases
the common `hmath_value` owner. Inputs are borrowed for the synchronous call;
hold an owned reference throughout the call and on each participating thread.
Outputs stay untouched on failure. Release each reference with
`hmath_numeric_types_release`; releasing `NULL` is a no-op. Scalar and container
accessors in `hmath_value.h` accept these same handles.

Distinct handles are immutable and can be shared by independent calls. Callbacks
may reenter the checked API. Retain a borrowed callback input before returning
it as the callback's owned result. A callback must not unwind through C. Its
transferred output is consumed on success and failure. Cancellation is checked
before entering a numerical operation, with the same granularity as other
checked native adapters.

Exact integers are signed ASCII decimal strings. Rationals use separate
numerator and nonzero denominator strings. Text is an explicit array of 32-bit
Unicode code points plus its length; each code point must be at most `0x10ffff`.
Flags are explicit integer enum arrays and lengths. Array spans and overflow are
checked before reading input memory. Original `Left MathError` results use
`HMATH_MATH_ERROR`; `hmath_last_math_error` exposes the complete source
constructor, fields and message. Callback errors preserve that same payload.
There is no process-wide floating environment change or silent dtype promotion.

The function-by-function generated table is in
[Numeric type functions](numeric-type-functions.md). The bindings support the
listed concrete standard types and recursive Numeric.Dual/Quaternion witnesses;
arbitrary user-defined Haskell typeclass instances are outside this C ABI.
