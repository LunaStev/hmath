# Typed generic numeric APIs

These are additional type instances of the same Basic, Scalar, Linear, Statistics and Geometry equality functions, not additional source functions. Existing flat C APIs and Python dtype defaults remain unchanged. C includes `hmath_numeric_objects.h`; each original prefix gains `_value` and an explicit borrowed typed prototype, with owned Value outputs.

Python automatically selects this path when an argument contains a native numeric owner (recursively through lists), including `Numeric.Dual`, `Numeric.Quaternion`, original `Autodiff.Dual` and symbolic `Autodiff.Expr`. Use `dtype=prototype` for empty vectors, or `dtype="value"` for ordinary values using their exact encoded type, such as unbounded integers or ordered strings/Booleans/tuples/lists. All numeric operands must have the same actual Haskell type; no implicit widening or conversion between the two distinct Dual types occurs.

The actual Coefficient dictionaries preserve all existing standard primitive numeric instances, recursively nested Numeric.Dual and Quaternion where permitted. Original AD.Dual dictionaries preserve its primal-only ordering and full-field equality. Symbolic AD.Expr has Num/Fractional/Floating but no Eq/Ord: normalization and median therefore reject it. Numeric.Quaternion has Num only, so fractional/floating statistics reject it; Numeric.Dual has no Ord. Integral/Bounded operations keep their actual bounded instances and reject nonintegral objects. Ord-only clamp/min/max use the shared resolver for supported native public labels, lists, tuples and optional values, calling the actual original Ord dictionary. Geometry hamming/jaccard Value paths retain the shared native Eq dictionaries: exact coefficients, Numeric.Dual/Quaternion, supported original AD.Dual, structural values and supported domain owners. They do not substitute an ordering comparison for equality. Arbitrary user-defined Haskell instances require a compiled bridge; these finite adapters do not claim universal typeclass coverage.

```python
from hmath import scalar, statistics, numeric_types

with numeric_types.dual(2.0, 1.0) as x, numeric_types.dual(3.0, 0.0) as y:
    with scalar.add(x, y) as z:
        assert numeric_types.primal(z) == 5.0
    with statistics.mean([x, y]) as mean:
        assert numeric_types.primal(mean) == 2.5

assert scalar.minimum_scalar("alpha", "beta", dtype="value") == "alpha"
```

## `hmath.basic.clamp`

Additional Value specialization for the [same original function](haskell/HMath-Basic.md#v:clamp).

```c
hmath_status hmath_basic_clamp_value(hmath_context *context, const hmath_value *prototype, const hmath_value *low, const hmath_value *high, const hmath_value *value, hmath_value **out);
```

## `hmath.basic.lerp`

Additional Value specialization for the [same original function](haskell/HMath-Basic.md#v:lerp).

```c
hmath_status hmath_basic_lerp_value(hmath_context *context, const hmath_value *prototype, const hmath_value *a, const hmath_value *b, const hmath_value *t, hmath_value **out);
```

## `hmath.scalar.add`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:add).

```c
hmath_status hmath_scalar_add_value(hmath_context *context, const hmath_value *prototype, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `hmath.scalar.subtract_scalar`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:subtractScalar).

```c
hmath_status hmath_scalar_subtract_scalar_value(hmath_context *context, const hmath_value *prototype, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `hmath.scalar.multiply`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:multiply).

```c
hmath_status hmath_scalar_multiply_value(hmath_context *context, const hmath_value *prototype, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `hmath.scalar.minimum_scalar`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:minimumScalar).

```c
hmath_status hmath_scalar_minimum_scalar_value(hmath_context *context, const hmath_value *prototype, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `hmath.scalar.maximum_scalar`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:maximumScalar).

```c
hmath_status hmath_scalar_maximum_scalar_value(hmath_context *context, const hmath_value *prototype, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `hmath.scalar.absolute`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:absolute).

```c
hmath_status hmath_scalar_absolute_value(hmath_context *context, const hmath_value *prototype, const hmath_value *x, hmath_value **out);
```

## `hmath.scalar.sign`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:sign).

```c
hmath_status hmath_scalar_sign_value(hmath_context *context, const hmath_value *prototype, const hmath_value *x, hmath_value **out);
```

## `hmath.scalar.positive_modulo`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:positiveModulo).

```c
hmath_status hmath_scalar_positive_modulo_value(hmath_context *context, const hmath_value *prototype, const hmath_value *a, const hmath_value *modulus, hmath_value **out);
```

## `hmath.scalar.cumulative_sum`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:cumulativeSum).

```c
hmath_status hmath_scalar_cumulative_sum_value(hmath_context *context, const hmath_value *prototype, const hmath_value *values, hmath_value **out);
```

## `hmath.scalar.cumulative_product`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:cumulativeProduct).

```c
hmath_status hmath_scalar_cumulative_product_value(hmath_context *context, const hmath_value *prototype, const hmath_value *values, hmath_value **out);
```

## `hmath.scalar.prefix_sum`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:prefixSum).

```c
hmath_status hmath_scalar_prefix_sum_value(hmath_context *context, const hmath_value *prototype, const hmath_value *values, hmath_value **out);
```

## `hmath.statistics.mean`

Additional Value specialization for the [same original function](haskell/HMath-Statistics.md#v:mean).

```c
hmath_status hmath_statistics_mean_value(hmath_context *context, const hmath_value *prototype, const hmath_value *values, hmath_value **out);
```

## `hmath.statistics.variance`

Additional Value specialization for the [same original function](haskell/HMath-Statistics.md#v:variance).

```c
hmath_status hmath_statistics_variance_value(hmath_context *context, const hmath_value *prototype, const hmath_value *values, hmath_value **out);
```

## `hmath.statistics.standard_deviation`

Additional Value specialization for the [same original function](haskell/HMath-Statistics.md#v:standardDeviation).

```c
hmath_status hmath_statistics_standard_deviation_value(hmath_context *context, const hmath_value *prototype, const hmath_value *values, hmath_value **out);
```

## `hmath.statistics.median`

Additional Value specialization for the [same original function](haskell/HMath-Statistics.md#v:median).

```c
hmath_status hmath_statistics_median_value(hmath_context *context, const hmath_value *prototype, const hmath_value *values, hmath_value **out);
```

## `hmath.linear.dot`

Additional Value specialization for the [same original function](haskell/HMath-Linear.md#v:dot).

```c
hmath_status hmath_linear_dot_value(hmath_context *context, const hmath_value *prototype, const hmath_value *argument1, const hmath_value *argument2, hmath_value **out);
```

## `hmath.linear.dot_checked`

Additional Value specialization for the [same original function](haskell/HMath-Linear.md#v:dotChecked).

```c
hmath_status hmath_linear_dot_checked_value(hmath_context *context, const hmath_value *prototype, const hmath_value *argument1, const hmath_value *argument2, hmath_value **out);
```

## `hmath.linear.magnitude`

Additional Value specialization for the [same original function](haskell/HMath-Linear.md#v:magnitude).

```c
hmath_status hmath_linear_magnitude_value(hmath_context *context, const hmath_value *prototype, const hmath_value *argument1, hmath_value **out);
```

## `hmath.linear.normalize`

Additional Value specialization for the [same original function](haskell/HMath-Linear.md#v:normalize).

```c
hmath_status hmath_linear_normalize_value(hmath_context *context, const hmath_value *prototype, const hmath_value *argument1, hmath_value **out);
```

## `hmath.linear.add`

Additional Value specialization for the [same original function](haskell/HMath-Linear.md#v:add).

```c
hmath_status hmath_linear_add_value(hmath_context *context, const hmath_value *prototype, const hmath_value *argument1, const hmath_value *argument2, hmath_value **out);
```

## `hmath.linear.add_checked`

Additional Value specialization for the [same original function](haskell/HMath-Linear.md#v:addChecked).

```c
hmath_status hmath_linear_add_checked_value(hmath_context *context, const hmath_value *prototype, const hmath_value *argument1, const hmath_value *argument2, hmath_value **out);
```

## `hmath.linear.subtract_checked`

Additional Value specialization for the [same original function](haskell/HMath-Linear.md#v:subtractChecked).

```c
hmath_status hmath_linear_subtract_checked_value(hmath_context *context, const hmath_value *prototype, const hmath_value *argument1, const hmath_value *argument2, hmath_value **out);
```

## `hmath.linear.scale`

Additional Value specialization for the [same original function](haskell/HMath-Linear.md#v:scale).

```c
hmath_status hmath_linear_scale_value(hmath_context *context, const hmath_value *prototype, const hmath_value *argument1, const hmath_value *argument2, hmath_value **out);
```

## `hmath.scalar.saturating_add`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:saturatingAdd).

```c
hmath_status hmath_scalar_saturating_add_value(hmath_context *context, const hmath_value *prototype, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `hmath.scalar.saturating_subtract`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:saturatingSubtract).

```c
hmath_status hmath_scalar_saturating_subtract_value(hmath_context *context, const hmath_value *prototype, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `hmath.scalar.saturating_multiply`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:saturatingMultiply).

```c
hmath_status hmath_scalar_saturating_multiply_value(hmath_context *context, const hmath_value *prototype, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `hmath.scalar.checked_add`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:checkedAdd).

```c
hmath_status hmath_scalar_checked_add_value(hmath_context *context, const hmath_value *prototype, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `hmath.scalar.checked_subtract`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:checkedSubtract).

```c
hmath_status hmath_scalar_checked_subtract_value(hmath_context *context, const hmath_value *prototype, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `hmath.scalar.checked_multiply`

Additional Value specialization for the [same original function](haskell/HMath-Scalar.md#v:checkedMultiply).

```c
hmath_status hmath_scalar_checked_multiply_value(hmath_context *context, const hmath_value *prototype, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `hmath.geometry_primitives.hamming_distance`

Additional Value specialization for the [same original function](haskell/HMath-Geometry-Primitives.md#v:hammingDistance).

```c
hmath_status hmath_geometry_primitives_hamming_distance_value(hmath_context *context, const hmath_value *prototype, const hmath_value *argument1, const hmath_value *argument2, hmath_value **out);
```

## `hmath.geometry_primitives.jaccard_distance`

Additional Value specialization for the [same original function](haskell/HMath-Geometry-Primitives.md#v:jaccardDistance).

```c
hmath_status hmath_geometry_primitives_jaccard_distance_value(hmath_context *context, const hmath_value *prototype, const hmath_value *argument1, const hmath_value *argument2, hmath_value **out);
```

