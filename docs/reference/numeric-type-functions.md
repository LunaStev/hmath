# Numeric type functions
All entries below call the corresponding original Haskell function or constructor.
The [representation and ownership contract](numeric-types.md) applies to every entry.
Python functions additionally accept `boxed=True` to retain an output scalar dtype.

| Python signature | Original symbol | C function |
| --- | --- | --- |
| `round_rational(mode, value)` | `HMath.Numeric.roundRational` | `hmath_numeric_types_round_rational` |
| `classify(value)` | `HMath.Numeric.classify` | `hmath_numeric_types_classify` |
| `frexp(value)` | `HMath.Numeric.frexp` | `hmath_numeric_types_frexp` |
| `numeric_limits(value)` | `HMath.Numeric.numericLimits` | `hmath_numeric_types_numeric_limits` |
| `integer_limits(value)` | `HMath.Numeric.integerLimits` | `hmath_numeric_types_integer_limits` |
| `float16_limits()` | `HMath.Numeric.float16Limits` | `hmath_numeric_types_float16_limits` |
| `bfloat16_limits()` | `HMath.Numeric.bfloat16Limits` | `hmath_numeric_types_bfloat16_limits` |
| `numeric_limits_record(normal, subnormal, maximum_value, epsilon, digits, low, high)` | `HMath.Numeric.NumericLimits` | `hmath_numeric_types_numeric_limits_record` |
| `minimum_normal(value)` | `HMath.Numeric.minimumNormal` | `hmath_numeric_types_minimum_normal` |
| `minimum_subnormal(value)` | `HMath.Numeric.minimumSubnormal` | `hmath_numeric_types_minimum_subnormal` |
| `maximum_finite(value)` | `HMath.Numeric.maximumFinite` | `hmath_numeric_types_maximum_finite` |
| `machine_epsilon(value)` | `HMath.Numeric.machineEpsilon` | `hmath_numeric_types_machine_epsilon` |
| `significand_digits(value)` | `HMath.Numeric.significandDigits` | `hmath_numeric_types_significand_digits` |
| `minimum_exponent(value)` | `HMath.Numeric.minimumExponent` | `hmath_numeric_types_minimum_exponent` |
| `maximum_exponent(value)` | `HMath.Numeric.maximumExponent` | `hmath_numeric_types_maximum_exponent` |
| `safe_integral_cast(value, dtype)` | `HMath.Numeric.safeIntegralCast` | `hmath_numeric_types_safe_integral_cast` |
| `saturating_cast(value, dtype)` | `HMath.Numeric.saturatingCast` | `hmath_numeric_types_saturating_cast` |
| `real_to_integral(mode, value, dtype)` | `HMath.Numeric.realToIntegral` | `hmath_numeric_types_real_to_integral` |
| `narrow_float(value, dtype)` | `HMath.Numeric.narrowFloat` | `hmath_numeric_types_narrow_float` |
| `float16(mode, value)` | `HMath.Numeric.float16` | `hmath_numeric_types_float16` |
| `bfloat16(mode, value)` | `HMath.Numeric.bfloat16` | `hmath_numeric_types_bfloat16` |
| `float16_from_bits(bits)` | `HMath.Numeric.float16FromBits` | `hmath_numeric_types_float16_from_bits` |
| `bfloat16_from_bits(bits)` | `HMath.Numeric.bfloat16FromBits` | `hmath_numeric_types_bfloat16_from_bits` |
| `float16_bits(value)` | `HMath.Numeric.float16Bits` | `hmath_numeric_types_float16_bits` |
| `bfloat16_bits(value)` | `HMath.Numeric.bfloat16Bits` | `hmath_numeric_types_bfloat16_bits` |
| `from_float16(value)` | `HMath.Numeric.fromFloat16` | `hmath_numeric_types_from_float16` |
| `from_bfloat16(value)` | `HMath.Numeric.fromBFloat16` | `hmath_numeric_types_from_bfloat16` |
| `rounded(value, flags)` | `HMath.Numeric.Rounded` | `hmath_numeric_types_rounded` |
| `rounded_value(value)` | `HMath.Numeric.roundedValue` | `hmath_numeric_types_rounded_value` |
| `numerical_exceptions(value)` | `HMath.Numeric.numericalExceptions` | `hmath_numeric_types_numerical_exceptions` |
| `big_float(precision, mode, value)` | `HMath.Numeric.bigFloat` | `hmath_numeric_types_big_float` |
| `extended(value)` | `HMath.Numeric.extended` | `hmath_numeric_types_extended` |
| `big_precision(value)` | `HMath.Numeric.bigPrecision` | `hmath_numeric_types_big_precision` |
| `big_rational(value)` | `HMath.Numeric.bigRational` | `hmath_numeric_types_big_rational` |
| `big_to_double(value)` | `HMath.Numeric.bigToDouble` | `hmath_numeric_types_big_to_double` |
| `big_add(a, b)` | `HMath.Numeric.bigAdd` | `hmath_numeric_types_big_add` |
| `big_subtract(a, b)` | `HMath.Numeric.bigSubtract` | `hmath_numeric_types_big_subtract` |
| `big_multiply(a, b)` | `HMath.Numeric.bigMultiply` | `hmath_numeric_types_big_multiply` |
| `big_divide(a, b)` | `HMath.Numeric.bigDivide` | `hmath_numeric_types_big_divide` |
| `big_sqrt(value)` | `HMath.Numeric.bigSqrt` | `hmath_numeric_types_big_sqrt` |
| `big_exp(value)` | `HMath.Numeric.bigExp` | `hmath_numeric_types_big_exp` |
| `big_log(value)` | `HMath.Numeric.bigLog` | `hmath_numeric_types_big_log` |
| `mixed_add(a, b)` | `HMath.Numeric.mixedAdd` | `hmath_numeric_types_mixed_add` |
| `mixed_multiply(a, b)` | `HMath.Numeric.mixedMultiply` | `hmath_numeric_types_mixed_multiply` |
| `fixed(scale, mode, value)` | `HMath.Numeric.fixed` | `hmath_numeric_types_fixed` |
| `fixed_rational(value)` | `HMath.Numeric.fixedRational` | `hmath_numeric_types_fixed_rational` |
| `fixed_add(a, b)` | `HMath.Numeric.fixedAdd` | `hmath_numeric_types_fixed_add` |
| `fixed_multiply(mode, a, b)` | `HMath.Numeric.fixedMultiply` | `hmath_numeric_types_fixed_multiply` |
| `fixed_divide(mode, a, b)` | `HMath.Numeric.fixedDivide` | `hmath_numeric_types_fixed_divide` |
| `decimal(scale, mode, value)` | `HMath.Numeric.decimal` | `hmath_numeric_types_decimal` |
| `decimal_rational(value)` | `HMath.Numeric.decimalRational` | `hmath_numeric_types_decimal_rational` |
| `decimal_add(a, b)` | `HMath.Numeric.decimalAdd` | `hmath_numeric_types_decimal_add` |
| `decimal_multiply(mode, a, b)` | `HMath.Numeric.decimalMultiply` | `hmath_numeric_types_decimal_multiply` |
| `decimal_divide(mode, a, b)` | `HMath.Numeric.decimalDivide` | `hmath_numeric_types_decimal_divide` |
| `fixed_scale(value)` | `HMath.Numeric.fixedScale` | `hmath_numeric_types_fixed_scale` |
| `fixed_coefficient(value)` | `HMath.Numeric.fixedCoefficient` | `hmath_numeric_types_fixed_coefficient` |
| `interval(low, high)` | `HMath.Numeric.interval` | `hmath_numeric_types_interval` |
| `interval_bounds(value)` | `HMath.Numeric.intervalBounds` | `hmath_numeric_types_interval_bounds` |
| `interval_contains(value, point)` | `HMath.Numeric.intervalContains` | `hmath_numeric_types_interval_contains` |
| `interval_add(a, b)` | `HMath.Numeric.intervalAdd` | `hmath_numeric_types_interval_add` |
| `interval_subtract(a, b)` | `HMath.Numeric.intervalSubtract` | `hmath_numeric_types_interval_subtract` |
| `interval_multiply(a, b)` | `HMath.Numeric.intervalMultiply` | `hmath_numeric_types_interval_multiply` |
| `interval_divide(a, b)` | `HMath.Numeric.intervalDivide` | `hmath_numeric_types_interval_divide` |
| `dual(primal_value, tangent_value)` | `HMath.Numeric.Dual` | `hmath_numeric_types_dual` |
| `primal(value)` | `HMath.Numeric.primal` | `hmath_numeric_types_primal` |
| `tangent(value)` | `HMath.Numeric.tangent` | `hmath_numeric_types_tangent` |
| `derivative(function, value)` | `HMath.Numeric.derivative` | `hmath_numeric_types_derivative` |
| `quaternion(real, i, j, k)` | `HMath.Numeric.Quaternion` | `hmath_numeric_types_quaternion` |
| `quaternion_conjugate(value)` | `HMath.Numeric.quaternionConjugate` | `hmath_numeric_types_quaternion_conjugate` |
| `quaternion_norm(value)` | `HMath.Numeric.quaternionNorm` | `hmath_numeric_types_quaternion_norm` |
| `quaternion_inverse(value)` | `HMath.Numeric.quaternionInverse` | `hmath_numeric_types_quaternion_inverse` |
| `dual_quaternion(real, dual)` | `HMath.Numeric.DualQuaternion` | `hmath_numeric_types_dual_quaternion` |
| `dual_quaternion_multiply(a, b)` | `HMath.Numeric.dualQuaternionMultiply` | `hmath_numeric_types_dual_quaternion_multiply` |
| `dual_quaternion_inverse(value)` | `HMath.Numeric.dualQuaternionInverse` | `hmath_numeric_types_dual_quaternion_inverse` |
| `rotate_vector(value, x, y, z)` | `HMath.Numeric.rotateVector` | `hmath_numeric_types_rotate_vector` |
| `rigid_transform(value, x, y, z)` | `HMath.Numeric.rigidTransform` | `hmath_numeric_types_rigid_transform` |
| `transform_point(value, x, y, z)` | `HMath.Numeric.transformPoint` | `hmath_numeric_types_transform_point` |
| `constant(name, value, uncertainty, approximation, unit, source)` | `HMath.Constants.Constant` | `hmath_numeric_types_constant` |
| `constant_name(value)` | `HMath.Constants.constantName` | `hmath_numeric_types_constant_name` |
| `constant_value(value)` | `HMath.Constants.constantValue` | `hmath_numeric_types_constant_value` |
| `standard_uncertainty(value)` | `HMath.Constants.standardUncertainty` | `hmath_numeric_types_standard_uncertainty` |
| `approximation_bound(value)` | `HMath.Constants.approximationBound` | `hmath_numeric_types_approximation_bound` |
| `constant_unit(value)` | `HMath.Constants.constantUnit` | `hmath_numeric_types_constant_unit` |
| `constant_source(value)` | `HMath.Constants.constantSource` | `hmath_numeric_types_constant_source` |
| `constant_as(value, dtype)` | `HMath.Constants.constantAs` | `hmath_numeric_types_constant_as` |
| `mathematical_constants()` | `HMath.Constants.mathematicalConstants` | `hmath_numeric_types_mathematical_constants` |
| `physical_constants()` | `HMath.Constants.physicalConstants` | `hmath_numeric_types_physical_constants` |
| `speed_of_light()` | `HMath.Constants.speedOfLight` | `hmath_numeric_types_speed_of_light` |
| `planck_constant()` | `HMath.Constants.planckConstant` | `hmath_numeric_types_planck_constant` |
| `elementary_charge()` | `HMath.Constants.elementaryCharge` | `hmath_numeric_types_elementary_charge` |
| `boltzmann_constant()` | `HMath.Constants.boltzmannConstant` | `hmath_numeric_types_boltzmann_constant` |
| `avogadro_constant()` | `HMath.Constants.avogadroConstant` | `hmath_numeric_types_avogadro_constant` |
| `gravitational_constant()` | `HMath.Constants.gravitationalConstant` | `hmath_numeric_types_gravitational_constant` |
| `electron_mass()` | `HMath.Constants.electronMass` | `hmath_numeric_types_electron_mass` |
| `astronomical_unit()` | `HMath.Constants.astronomicalUnit` | `hmath_numeric_types_astronomical_unit` |

All handle parameters preserve their original type. `mode` is a `RoundingMode`;
`dtype` selects a shared scalar code. Precision, scale, digits and exponent fields
use native Haskell `Int` width. Rational parameters accept `Fraction` in Python
and exact numerator/denominator decimal strings in C. The `constant_as_like`
helper uses a typed prototype instead of a fixed scalar code.
