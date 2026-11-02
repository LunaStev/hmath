# Exact units and quantities

Unit conversion and quantity arithmetic call the original `HMath.Units` implementation. Values are exact `fractions.Fraction` objects, including affine offsets; exponents are arbitrary integers. Nine dimensions distinguish seven SI base dimensions, data, and plane angle. Invalid conversions preserve original `MathError` constructors and messages.

```python
from fractions import Fraction
from hmath import units as u

with u.kilometre() as km, u.metre() as metre:
    assert u.convert(km, metre, Fraction(3, 2)) == 1500
with u.celsius() as c, u.fahrenheit() as f:
    assert u.convert(c, f, 100) == 212
```

Catalog names are zero-argument functions returning independently owned immutable Unit/Dimension handles. Use `close()` or a context manager; releasing an input cannot invalidate a returned quantity or derived unit. Constants are not initialized at import time. `Dimension`, `Unit`, `Quantity`, and `SIPrefix` constructors follow their original source constructors; named functions provide equivalent access. Their equality uses original derived Haskell `Eq`.

Absolute temperatures and differences retain their original hidden distinction: absolute plus absolute fails, absolute minus absolute yields a difference, difference minus absolute fails, and multiplying/dividing an absolute temperature fails. `temperature_difference` ignores the unit's affine offset. `in_unit` subtracts an affine offset only for absolute quantities. Zero divisor, incompatible dimensions, invalid scale, affine unit products/prefixes, and prefix resource limits retain original errors. The SI prefix catalog includes exactly the source ordering and spellings.

Python integer inputs to Rational fields are converted exactly, and `Fraction` values never pass through FP64. A Python float is converted to the exact fraction representing that already-rounded float; use `Fraction("0.1")` when decimal 0.1 is intended. Prefix exponents must fit Haskell `Int`; unit powers and dimension exponents use unbounded `Integer`. The existing four angle-conversion numeric functions retain their Float/Double interfaces.

Include `hmath_units.h` plus `hmath_value.h` in C. Unit/quantity scalar inputs use Rational Values, dimensional/power exponents use Integer Values, and prefix exponents use Index or an exact Int-range integral Value. Text uses length-delimited codepoints, preserving Unicode, embedded NUL and Haskell Char surrogates. Every result is owned and must be released once. Errors leave `out` untouched. Inputs are immutable and borrowed for the call only; independent calls may share them.

## `dimension`

Exponents in order length, mass, time, current, temperature, amount, luminous intensity, data, plane angle. Require exactly nine exponents.

`dimension(exponents)` returns `Dimension` or raises the original checked error. Parameters: `exponents`: `[Integer]`

```c
hmath_status hmath_units_value_dimension(hmath_context *context, const hmath_value *exponents, hmath_value **out);
```

## `dimension_exponents`

Return nine exact integer exponents ordered as length, mass, time, current, temperature, amount, luminous intensity, data, plane angle.

`dimension_exponents(dimension)` returns `[Integer]`. Parameters: `dimension`: `Dimension`

```c
hmath_status hmath_units_value_dimension_exponents(hmath_context *context, const hmath_value *dimension, hmath_value **out);
```

## `dimensionless`

Dimension witness with all nine exponents zero; all unspecified exponents are zero. Use to construct or compare dimension-safe units/quantities.

`dimensionless()` returns `Dimension`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_dimensionless(hmath_context *context, hmath_value **out);
```

## `length_dimension`

Dimension witness with length exponent one; all unspecified exponents are zero. Use to construct or compare dimension-safe units/quantities.

`length_dimension()` returns `Dimension`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_length_dimension(hmath_context *context, hmath_value **out);
```

## `mass_dimension`

Dimension witness with mass exponent one; all unspecified exponents are zero. Use to construct or compare dimension-safe units/quantities.

`mass_dimension()` returns `Dimension`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_mass_dimension(hmath_context *context, hmath_value **out);
```

## `time_dimension`

Dimension witness with time exponent one; all unspecified exponents are zero. Use to construct or compare dimension-safe units/quantities.

`time_dimension()` returns `Dimension`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_time_dimension(hmath_context *context, hmath_value **out);
```

## `temperature_dimension`

Dimension witness with temperature exponent one; all unspecified exponents are zero. Use to construct or compare dimension-safe units/quantities.

`temperature_dimension()` returns `Dimension`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_temperature_dimension(hmath_context *context, hmath_value **out);
```

## `angle_dimension`

Dimension witness with plane-angle tag exponent one; all unspecified exponents are zero. Use to construct or compare dimension-safe units/quantities.

`angle_dimension()` returns `Dimension`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_angle_dimension(hmath_context *context, hmath_value **out);
```

## `data_dimension`

Dimension witness with data tag exponent one; all unspecified exponents are zero. Use to construct or compare dimension-safe units/quantities.

`data_dimension()` returns `Dimension`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_data_dimension(hmath_context *context, hmath_value **out);
```

## `unit`

SI = value * scale + offset. Only temperature units may have an offset.

`unit(name, dimension, scale, offset)` returns `Unit` or raises the original checked error. Parameters: `name`: `String`, `dimension`: `Dimension`, `scale`: `Rational`, `offset`: `Rational`

```c
hmath_status hmath_units_value_unit(hmath_context *context, const hmath_value *name, const hmath_value *dimension, const hmath_value *scale, const hmath_value *offset, hmath_value **out);
```

## `unit_name`

Return the display name/symbol of a Unit, for example "m". No conversion is performed.

`unit_name(unit)` returns `String`. Parameters: `unit`: `Unit`

```c
hmath_status hmath_units_value_unit_name(hmath_context *context, const hmath_value *unit, hmath_value **out);
```

## `unit_dimension`

Return the dimensional-exponent witness of a Unit. Compatible conversions require equal dimensions.

`unit_dimension(unit)` returns `Dimension`. Parameters: `unit`: `Unit`

```c
hmath_status hmath_units_value_unit_dimension(hmath_context *context, const hmath_value *unit, hmath_value **out);
```

## `unit_scale`

Return exact Rational scale in the conversion SI = value*scale + offset. All public Unit constructors require a positive scale.

`unit_scale(unit)` returns `Rational`. Parameters: `unit`: `Unit`

```c
hmath_status hmath_units_value_unit_scale(hmath_context *context, const hmath_value *unit, hmath_value **out);
```

## `unit_offset`

Return exact Rational affine offset in SI = value*scale + offset. Only temperature units may have a nonzero offset.

`unit_offset(unit)` returns `Rational`. Parameters: `unit`: `Unit`

```c
hmath_status hmath_units_value_unit_offset(hmath_context *context, const hmath_value *unit, hmath_value **out);
```

## `unit_product`

Multiply two zero-offset units: add dimension exponents and multiply Rational scales. Any affine offset returns Left DomainError. This constructs a Unit, not a Quantity.

`unit_product(left, right)` returns `Unit` or raises the original checked error. Parameters: `left`: `Unit`, `right`: `Unit`

```c
hmath_status hmath_units_value_unit_product(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `unit_quotient`

Divide two zero-offset units: subtract dimension exponents and divide their positive scales. Affine units fail with DomainError.

`unit_quotient(numerator, denominator)` returns `Unit` or raises the original checked error. Parameters: `numerator`: `Unit`, `denominator`: `Unit`

```c
hmath_status hmath_units_value_unit_quotient(hmath_context *context, const hmath_value *numerator, const hmath_value *denominator, hmath_value **out);
```

## `unit_power`

Given zero-offset Unit then Integer exponent, multiply its exponents and raise its positive scale to that power. Negative powers are valid; affine units fail.

`unit_power(unit, exponent)` returns `Unit` or raises the original checked error. Parameters: `unit`: `Unit`, `exponent`: `Integer`

```c
hmath_status hmath_units_value_unit_power(hmath_context *context, const hmath_value *unit, const hmath_value *exponent, hmath_value **out);
```

## `quantity`

Given Unit then Rational value, construct an exact SI-valued Quantity using its scale and offset. A temperature unit constructs an absolute temperature; use temperatureDifference for differences.

`quantity(unit, value)` returns `Quantity`. Parameters: `unit`: `Unit`, `value`: `Rational`

```c
hmath_status hmath_units_value_quantity(hmath_context *context, const hmath_value *unit, const hmath_value *value, hmath_value **out);
```

## `temperature_difference`

Given Unit then Rational value, construct an exact SI-valued Quantity using its scale and offset. A temperature unit constructs an absolute temperature; use

`temperature_difference(unit, value)` returns `Quantity` or raises the original checked error. Parameters: `unit`: `Unit`, `value`: `Rational`

```c
hmath_status hmath_units_value_temperature_difference(hmath_context *context, const hmath_value *unit, const hmath_value *value, hmath_value **out);
```

## `quantity_dimension`

Return a Quantity's dimensional-exponent witness, without changing its SI value or absolute-temperature tag.

`quantity_dimension(quantity)` returns `Dimension`. Parameters: `quantity`: `Quantity`

```c
hmath_status hmath_units_value_quantity_dimension(hmath_context *context, const hmath_value *quantity, hmath_value **out);
```

## `si_value`

Return exact Rational SI value of a Quantity. For absolute temperature this is an absolute kelvin value; preserve quantityDimension when interpreting the number.

`si_value(quantity)` returns `Rational`. Parameters: `quantity`: `Quantity`

```c
hmath_status hmath_units_value_si_value(hmath_context *context, const hmath_value *quantity, hmath_value **out);
```

## `in_unit`

Given destination Unit then Quantity, convert its SI value to that unit. Reject incompatible dimensions. Apply affine offsets only for absolute temperatures, not differences.

`in_unit(unit, quantity)` returns `Rational` or raises the original checked error. Parameters: `unit`: `Unit`, `quantity`: `Quantity`

```c
hmath_status hmath_units_value_in_unit(hmath_context *context, const hmath_value *unit, const hmath_value *quantity, hmath_value **out);
```

## `convert`

Given source Unit, destination Unit, then Rational value, convert exactly through SI. Incompatible dimensions fail. Example: convert kilometre metre 2 == Right 2000.

`convert(source, destination, value)` returns `Rational` or raises the original checked error. Parameters: `source`: `Unit`, `destination`: `Unit`, `value`: `Rational`

```c
hmath_status hmath_units_value_convert(hmath_context *context, const hmath_value *source, const hmath_value *destination, const hmath_value *value, hmath_value **out);
```

## `add_quantity`

Original public HMath.Units constructor or field.

`add_quantity(left, right)` returns `Quantity` or raises the original checked error. Parameters: `left`: `Quantity`, `right`: `Quantity`

```c
hmath_status hmath_units_value_add_quantity(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `subtract_quantity`

Original public HMath.Units constructor or field.

`subtract_quantity(left, right)` returns `Quantity` or raises the original checked error. Parameters: `left`: `Quantity`, `right`: `Quantity`

```c
hmath_status hmath_units_value_subtract_quantity(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `multiply_quantity`

Original public HMath.Units constructor or field.

`multiply_quantity(left, right)` returns `Quantity` or raises the original checked error. Parameters: `left`: `Quantity`, `right`: `Quantity`

```c
hmath_status hmath_units_value_multiply_quantity(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out);
```

## `divide_quantity`

Original public HMath.Units constructor or field.

`divide_quantity(numerator, denominator)` returns `Quantity` or raises the original checked error. Parameters: `numerator`: `Quantity`, `denominator`: `Quantity`

```c
hmath_status hmath_units_value_divide_quantity(hmath_context *context, const hmath_value *numerator, const hmath_value *denominator, hmath_value **out);
```

## `si_prefix`

Original public HMath.Units constructor or field.

`si_prefix(name, symbol, exponent)` returns `SIPrefix`. Parameters: `name`: `String`, `symbol`: `String`, `exponent`: `Int`

```c
hmath_status hmath_units_value_si_prefix(hmath_context *context, const hmath_value *name, const hmath_value *symbol, const hmath_value *exponent, hmath_value **out);
```

## `si_prefixes`

BIPM prefixes through the 2022 quetta/ronna and ronto/quecto additions. Source: https://www.bipm.org/en/measurement-units/si-prefixes

`si_prefixes()` returns `[SIPrefix]`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_si_prefixes(hmath_context *context, hmath_value **out);
```

## `prefixed`

Given SIPrefix then zero-offset Unit, multiply its scale by 10^prefixExponent and prepend its symbol. Reject affine units or absolute exponent above 10000.

`prefixed(prefix, unit)` returns `Unit` or raises the original checked error. Parameters: `prefix`: `SIPrefix`, `unit`: `Unit`

```c
hmath_status hmath_units_value_prefixed(hmath_context *context, const hmath_value *prefix, const hmath_value *unit, hmath_value **out);
```

## `metre`

The metre Unit: 1 metre. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`metre()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_metre(hmath_context *context, hmath_value **out);
```

## `kilometre`

The kilometre Unit: 1000 metres. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`kilometre()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_kilometre(hmath_context *context, hmath_value **out);
```

## `centimetre`

The centimetre Unit: 0.01 metre. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`centimetre()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_centimetre(hmath_context *context, hmath_value **out);
```

## `millimetre`

The millimetre Unit: 0.001 metre. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`millimetre()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_millimetre(hmath_context *context, hmath_value **out);
```

## `inch`

The inch Unit: 0.0254 metre. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`inch()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_inch(hmath_context *context, hmath_value **out);
```

## `foot`

The foot Unit: 0.3048 metre. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`foot()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_foot(hmath_context *context, hmath_value **out);
```

## `yard`

The yard Unit: 0.9144 metre. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`yard()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_yard(hmath_context *context, hmath_value **out);
```

## `mile`

The mile Unit: 1609.344 metres. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`mile()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_mile(hmath_context *context, hmath_value **out);
```

## `nautical_mile`

The nauticalMile Unit: 1852 metres. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`nautical_mile()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_nautical_mile(hmath_context *context, hmath_value **out);
```

## `square_metre`

The squareMetre Unit: 1 square metre. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`square_metre()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_square_metre(hmath_context *context, hmath_value **out);
```

## `hectare`

The hectare Unit: 10000 square metres. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`hectare()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_hectare(hmath_context *context, hmath_value **out);
```

## `cubic_metre`

The cubicMetre Unit: 1 cubic metre. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`cubic_metre()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_cubic_metre(hmath_context *context, hmath_value **out);
```

## `litre`

The litre Unit: 0.001 cubic metre. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`litre()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_litre(hmath_context *context, hmath_value **out);
```

## `millilitre`

The millilitre Unit: 0.000001 cubic metre. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`millilitre()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_millilitre(hmath_context *context, hmath_value **out);
```

## `kilogram`

The kilogram Unit: 1 kilogram. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`kilogram()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_kilogram(hmath_context *context, hmath_value **out);
```

## `gram`

The gram Unit: 0.001 kilogram. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`gram()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_gram(hmath_context *context, hmath_value **out);
```

## `tonne`

The tonne Unit: 1000 kilograms. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`tonne()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_tonne(hmath_context *context, hmath_value **out);
```

## `pound`

The pound Unit: 0.45359237 kilogram. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`pound()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_pound(hmath_context *context, hmath_value **out);
```

## `second`

The second Unit: 1 second. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`second()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_second(hmath_context *context, hmath_value **out);
```

## `minute`

The minute Unit: 60 seconds. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`minute()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_minute(hmath_context *context, hmath_value **out);
```

## `hour`

The hour Unit: 3600 seconds. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`hour()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_hour(hmath_context *context, hmath_value **out);
```

## `day`

The day Unit: 86400 seconds. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`day()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_day(hmath_context *context, hmath_value **out);
```

## `metres_per_second`

The metresPerSecond Unit: 1 metre per second. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`metres_per_second()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_metres_per_second(hmath_context *context, hmath_value **out);
```

## `kilometres_per_hour`

The kilometresPerHour Unit: 1000/3600 metres per second. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`kilometres_per_hour()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_kilometres_per_hour(hmath_context *context, hmath_value **out);
```

## `miles_per_hour`

The milesPerHour Unit: 1609.344/3600 metres per second. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`miles_per_hour()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_miles_per_hour(hmath_context *context, hmath_value **out);
```

## `metres_per_second_squared`

The metresPerSecondSquared Unit: 1 metre per second squared. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`metres_per_second_squared()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_metres_per_second_squared(hmath_context *context, hmath_value **out);
```

## `newton`

The newton Unit: 1 kg*m/s^2. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`newton()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_newton(hmath_context *context, hmath_value **out);
```

## `joule`

The joule Unit: 1 newton metre. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`joule()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_joule(hmath_context *context, hmath_value **out);
```

## `watt`

The watt Unit: 1 joule per second. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`watt()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_watt(hmath_context *context, hmath_value **out);
```

## `pascal`

The pascal Unit: 1 newton per square metre. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`pascal()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_pascal(hmath_context *context, hmath_value **out);
```

## `bar`

The bar Unit: 100000 pascals. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`bar()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_bar(hmath_context *context, hmath_value **out);
```

## `atmosphere`

The atmosphere Unit: 101325 pascals. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`atmosphere()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_atmosphere(hmath_context *context, hmath_value **out);
```

## `kelvin`

The kelvin Unit: absolute temperature with SI=value. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`kelvin()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_kelvin(hmath_context *context, hmath_value **out);
```

## `celsius`

The celsius Unit: absolute temperature with SI=value+273.15 kelvin. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`celsius()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_celsius(hmath_context *context, hmath_value **out);
```

## `fahrenheit`

The fahrenheit Unit: absolute temperature with SI=(value-32)*5/9+273.15 kelvin. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`fahrenheit()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_fahrenheit(hmath_context *context, hmath_value **out);
```

## `hertz`

The hertz Unit: 1 inverse second. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`hertz()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_hertz(hmath_context *context, hmath_value **out);
```

## `bit`

The bit Unit: 1 data bit. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`bit()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_bit(hmath_context *context, hmath_value **out);
```

## `byte`

The byte Unit: 8 data bits. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`byte()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_byte(hmath_context *context, hmath_value **out);
```

## `kibibyte`

The kibibyte Unit: 8192 data bits (1024 bytes). Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`kibibyte()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_kibibyte(hmath_context *context, hmath_value **out);
```

## `mebibyte`

The mebibyte Unit: 8388608 data bits (1024^2 bytes). Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`mebibyte()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_mebibyte(hmath_context *context, hmath_value **out);
```

## `gigabyte`

The gigabyte Unit: 8000000000 data bits (10^9 bytes). Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`gigabyte()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_gigabyte(hmath_context *context, hmath_value **out);
```

## `radian`

The radian Unit: 1 radian. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`radian()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_radian(hmath_context *context, hmath_value **out);
```

## `degree`

The degree Unit: pi/180 radian, using the stored 50-place Rational pi approximation. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`degree()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_degree(hmath_context *context, hmath_value **out);
```

## `gradian`

The gradian Unit: pi/200 radian, using the stored Rational pi approximation. Non-temperature definitions use an exact Rational scale and zero affine offset. Use quantity or convert to construct/convert values; temperature differences use temperatureDifference.

`gradian()` returns `Unit`. Parameters: none; returns a new owned reference to the source catalog value.

```c
hmath_status hmath_units_value_gradian(hmath_context *context, hmath_value **out);
```

## `prefix_name`

Original public HMath.Units constructor or field.

`prefix_name(prefix)` returns `String`. Parameters: `prefix`: `SIPrefix`

```c
hmath_status hmath_units_value_prefix_name(hmath_context *context, const hmath_value *prefix, hmath_value **out);
```

## `prefix_symbol`

Original public HMath.Units constructor or field.

`prefix_symbol(prefix)` returns `String`. Parameters: `prefix`: `SIPrefix`

```c
hmath_status hmath_units_value_prefix_symbol(hmath_context *context, const hmath_value *prefix, hmath_value **out);
```

## `prefix_exponent`

Original public HMath.Units constructor or field.

`prefix_exponent(prefix)` returns `Int`. Parameters: `prefix`: `SIPrefix`

```c
hmath_status hmath_units_value_prefix_exponent(hmath_context *context, const hmath_value *prefix, hmath_value **out);
```

