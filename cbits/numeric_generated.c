/* SPDX-License-Identifier: MPL-2.0 */
/* Generated; do not edit. */
#include "hmath_numeric.h"
#include "numeric_internal.h"
#include <stdlib.h>
void hmath_numeric_string_free(char *value) { free(value); }
void hmath_numeric_buffer_free(void *value) { free(value); }
extern int hm_numeric_basic_factorial(
    const char *n,
    char **out0);
hmath_status hmath_basic_factorial(
    hmath_context *context,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_factorial(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_fibonacci(
    const char *n,
    char **out0);
hmath_status hmath_basic_fibonacci(
    hmath_context *context,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_fibonacci(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_is_prime(
    const char *n,
    int *out0);
hmath_status hmath_basic_is_prime(
    hmath_context *context,
    const char *n,
    int *out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_is_prime(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_f32(
    float low,
    float high,
    float value,
    float *out0);
hmath_status hmath_basic_clamp_f32(
    hmath_context *context,
    float low,
    float high,
    float value,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_f32(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_f64(
    double low,
    double high,
    double value,
    double *out0);
hmath_status hmath_basic_clamp_f64(
    hmath_context *context,
    double low,
    double high,
    double value,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_f64(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_rational(
    const char *low_numerator,
    const char *low_denominator,
    const char *high_numerator,
    const char *high_denominator,
    const char *value_numerator,
    const char *value_denominator,
    char **out0,
    char **out1);
hmath_status hmath_basic_clamp_rational(
    hmath_context *context,
    const char *low_numerator,
    const char *low_denominator,
    const char *high_numerator,
    const char *high_denominator,
    const char *value_numerator,
    const char *value_denominator,
    char **out0,
    char **out1) {
    if (!hm_decimal(low_numerator) || !hm_decimal(low_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *low_digit = low_denominator;
    if (*low_digit == '-') ++low_digit;
    while (*low_digit == '0') ++low_digit;
    if (!*low_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!hm_decimal(high_numerator) || !hm_decimal(high_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *high_digit = high_denominator;
    if (*high_digit == '-') ++high_digit;
    while (*high_digit == '0') ++high_digit;
    if (!*high_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!hm_decimal(value_numerator) || !hm_decimal(value_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *value_digit = value_denominator;
    if (*value_digit == '-') ++value_digit;
    while (*value_digit == '0') ++value_digit;
    if (!*value_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_rational(low_numerator, low_denominator, high_numerator, high_denominator, value_numerator, value_denominator, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_integer(
    const char *low,
    const char *high,
    const char *value,
    char **out0);
hmath_status hmath_basic_clamp_integer(
    hmath_context *context,
    const char *low,
    const char *high,
    const char *value,
    char **out0) {
    if (!hm_decimal(low))
        return hm_error(HMATH_INVALID_ARGUMENT, "low: expected signed decimal Integer");
    if (!hm_decimal(high))
        return hm_error(HMATH_INVALID_ARGUMENT, "high: expected signed decimal Integer");
    if (!hm_decimal(value))
        return hm_error(HMATH_INVALID_ARGUMENT, "value: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_integer(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_i8(
    int8_t low,
    int8_t high,
    int8_t value,
    int8_t *out0);
hmath_status hmath_basic_clamp_i8(
    hmath_context *context,
    int8_t low,
    int8_t high,
    int8_t value,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_i8(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_i16(
    int16_t low,
    int16_t high,
    int16_t value,
    int16_t *out0);
hmath_status hmath_basic_clamp_i16(
    hmath_context *context,
    int16_t low,
    int16_t high,
    int16_t value,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_i16(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_i32(
    int32_t low,
    int32_t high,
    int32_t value,
    int32_t *out0);
hmath_status hmath_basic_clamp_i32(
    hmath_context *context,
    int32_t low,
    int32_t high,
    int32_t value,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_i32(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_i64(
    int64_t low,
    int64_t high,
    int64_t value,
    int64_t *out0);
hmath_status hmath_basic_clamp_i64(
    hmath_context *context,
    int64_t low,
    int64_t high,
    int64_t value,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_i64(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_u8(
    uint8_t low,
    uint8_t high,
    uint8_t value,
    uint8_t *out0);
hmath_status hmath_basic_clamp_u8(
    hmath_context *context,
    uint8_t low,
    uint8_t high,
    uint8_t value,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_u8(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_u16(
    uint16_t low,
    uint16_t high,
    uint16_t value,
    uint16_t *out0);
hmath_status hmath_basic_clamp_u16(
    hmath_context *context,
    uint16_t low,
    uint16_t high,
    uint16_t value,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_u16(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_u32(
    uint32_t low,
    uint32_t high,
    uint32_t value,
    uint32_t *out0);
hmath_status hmath_basic_clamp_u32(
    hmath_context *context,
    uint32_t low,
    uint32_t high,
    uint32_t value,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_u32(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_u64(
    uint64_t low,
    uint64_t high,
    uint64_t value,
    uint64_t *out0);
hmath_status hmath_basic_clamp_u64(
    hmath_context *context,
    uint64_t low,
    uint64_t high,
    uint64_t value,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_u64(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_int(
    ptrdiff_t low,
    ptrdiff_t high,
    ptrdiff_t value,
    ptrdiff_t *out0);
hmath_status hmath_basic_clamp_int(
    hmath_context *context,
    ptrdiff_t low,
    ptrdiff_t high,
    ptrdiff_t value,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_int(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_clamp_word(
    size_t low,
    size_t high,
    size_t value,
    size_t *out0);
hmath_status hmath_basic_clamp_word(
    hmath_context *context,
    size_t low,
    size_t high,
    size_t value,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_clamp_word(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_lerp_f32(
    float a,
    float b,
    float t,
    float *out0);
hmath_status hmath_basic_lerp_f32(
    hmath_context *context,
    float a,
    float b,
    float t,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_lerp_f32(a, b, t, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_lerp_f64(
    double a,
    double b,
    double t,
    double *out0);
hmath_status hmath_basic_lerp_f64(
    hmath_context *context,
    double a,
    double b,
    double t,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_lerp_f64(a, b, t, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_lerp_rational(
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    const char *t_numerator,
    const char *t_denominator,
    char **out0,
    char **out1);
hmath_status hmath_basic_lerp_rational(
    hmath_context *context,
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    const char *t_numerator,
    const char *t_denominator,
    char **out0,
    char **out1) {
    if (!hm_decimal(a_numerator) || !hm_decimal(a_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *a_digit = a_denominator;
    if (*a_digit == '-') ++a_digit;
    while (*a_digit == '0') ++a_digit;
    if (!*a_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!hm_decimal(b_numerator) || !hm_decimal(b_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *b_digit = b_denominator;
    if (*b_digit == '-') ++b_digit;
    while (*b_digit == '0') ++b_digit;
    if (!*b_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!hm_decimal(t_numerator) || !hm_decimal(t_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *t_digit = t_denominator;
    if (*t_digit == '-') ++t_digit;
    while (*t_digit == '0') ++t_digit;
    if (!*t_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_lerp_rational(a_numerator, a_denominator, b_numerator, b_denominator, t_numerator, t_denominator, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_lerp_c64(
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float t_0,
    float t_1,
    float *out0,
    float *out1);
hmath_status hmath_basic_lerp_c64(
    hmath_context *context,
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float t_0,
    float t_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_lerp_c64(a_0, a_1, b_0, b_1, t_0, t_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_basic_lerp_c128(
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double t_0,
    double t_1,
    double *out0,
    double *out1);
hmath_status hmath_basic_lerp_c128(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double t_0,
    double t_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_basic_lerp_c128(a_0, a_1, b_0, b_1, t_0, t_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_f32(
    float a,
    float b,
    float *out0);
hmath_status hmath_scalar_add_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_f32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_f64(
    double a,
    double b,
    double *out0);
hmath_status hmath_scalar_add_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_f64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_rational(
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1);
hmath_status hmath_scalar_add_rational(
    hmath_context *context,
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1) {
    if (!hm_decimal(a_numerator) || !hm_decimal(a_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *a_digit = a_denominator;
    if (*a_digit == '-') ++a_digit;
    while (*a_digit == '0') ++a_digit;
    if (!*a_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!hm_decimal(b_numerator) || !hm_decimal(b_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *b_digit = b_denominator;
    if (*b_digit == '-') ++b_digit;
    while (*b_digit == '0') ++b_digit;
    if (!*b_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_rational(a_numerator, a_denominator, b_numerator, b_denominator, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_integer(
    const char *a,
    const char *b,
    char **out0);
hmath_status hmath_scalar_add_integer(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(b))
        return hm_error(HMATH_INVALID_ARGUMENT, "b: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_integer(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_i8(
    int8_t a,
    int8_t b,
    int8_t *out0);
hmath_status hmath_scalar_add_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_i8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_i16(
    int16_t a,
    int16_t b,
    int16_t *out0);
hmath_status hmath_scalar_add_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_i16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_i32(
    int32_t a,
    int32_t b,
    int32_t *out0);
hmath_status hmath_scalar_add_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_i32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_i64(
    int64_t a,
    int64_t b,
    int64_t *out0);
hmath_status hmath_scalar_add_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_i64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_u8(
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
hmath_status hmath_scalar_add_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_u8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_u16(
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
hmath_status hmath_scalar_add_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_u16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_u32(
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
hmath_status hmath_scalar_add_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_u32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_u64(
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
hmath_status hmath_scalar_add_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_u64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_int(
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
hmath_status hmath_scalar_add_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_int(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_word(
    size_t a,
    size_t b,
    size_t *out0);
hmath_status hmath_scalar_add_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_word(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_c64(
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0,
    float *out1);
hmath_status hmath_scalar_add_c64(
    hmath_context *context,
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_c64(a_0, a_1, b_0, b_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_add_c128(
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
hmath_status hmath_scalar_add_c128(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_add_c128(a_0, a_1, b_0, b_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_f32(
    float a,
    float b,
    float *out0);
hmath_status hmath_scalar_subtract_scalar_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_f32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_f64(
    double a,
    double b,
    double *out0);
hmath_status hmath_scalar_subtract_scalar_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_f64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_rational(
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1);
hmath_status hmath_scalar_subtract_scalar_rational(
    hmath_context *context,
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1) {
    if (!hm_decimal(a_numerator) || !hm_decimal(a_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *a_digit = a_denominator;
    if (*a_digit == '-') ++a_digit;
    while (*a_digit == '0') ++a_digit;
    if (!*a_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!hm_decimal(b_numerator) || !hm_decimal(b_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *b_digit = b_denominator;
    if (*b_digit == '-') ++b_digit;
    while (*b_digit == '0') ++b_digit;
    if (!*b_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_rational(a_numerator, a_denominator, b_numerator, b_denominator, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_integer(
    const char *a,
    const char *b,
    char **out0);
hmath_status hmath_scalar_subtract_scalar_integer(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(b))
        return hm_error(HMATH_INVALID_ARGUMENT, "b: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_integer(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_i8(
    int8_t a,
    int8_t b,
    int8_t *out0);
hmath_status hmath_scalar_subtract_scalar_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_i8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_i16(
    int16_t a,
    int16_t b,
    int16_t *out0);
hmath_status hmath_scalar_subtract_scalar_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_i16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_i32(
    int32_t a,
    int32_t b,
    int32_t *out0);
hmath_status hmath_scalar_subtract_scalar_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_i32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_i64(
    int64_t a,
    int64_t b,
    int64_t *out0);
hmath_status hmath_scalar_subtract_scalar_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_i64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_u8(
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
hmath_status hmath_scalar_subtract_scalar_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_u8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_u16(
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
hmath_status hmath_scalar_subtract_scalar_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_u16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_u32(
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
hmath_status hmath_scalar_subtract_scalar_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_u32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_u64(
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
hmath_status hmath_scalar_subtract_scalar_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_u64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_int(
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
hmath_status hmath_scalar_subtract_scalar_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_int(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_word(
    size_t a,
    size_t b,
    size_t *out0);
hmath_status hmath_scalar_subtract_scalar_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_word(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_c64(
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0,
    float *out1);
hmath_status hmath_scalar_subtract_scalar_c64(
    hmath_context *context,
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_c64(a_0, a_1, b_0, b_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_subtract_scalar_c128(
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
hmath_status hmath_scalar_subtract_scalar_c128(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_subtract_scalar_c128(a_0, a_1, b_0, b_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_f32(
    float a,
    float b,
    float *out0);
hmath_status hmath_scalar_multiply_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_f32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_f64(
    double a,
    double b,
    double *out0);
hmath_status hmath_scalar_multiply_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_f64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_rational(
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1);
hmath_status hmath_scalar_multiply_rational(
    hmath_context *context,
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1) {
    if (!hm_decimal(a_numerator) || !hm_decimal(a_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *a_digit = a_denominator;
    if (*a_digit == '-') ++a_digit;
    while (*a_digit == '0') ++a_digit;
    if (!*a_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!hm_decimal(b_numerator) || !hm_decimal(b_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *b_digit = b_denominator;
    if (*b_digit == '-') ++b_digit;
    while (*b_digit == '0') ++b_digit;
    if (!*b_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_rational(a_numerator, a_denominator, b_numerator, b_denominator, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_integer(
    const char *a,
    const char *b,
    char **out0);
hmath_status hmath_scalar_multiply_integer(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(b))
        return hm_error(HMATH_INVALID_ARGUMENT, "b: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_integer(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_i8(
    int8_t a,
    int8_t b,
    int8_t *out0);
hmath_status hmath_scalar_multiply_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_i8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_i16(
    int16_t a,
    int16_t b,
    int16_t *out0);
hmath_status hmath_scalar_multiply_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_i16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_i32(
    int32_t a,
    int32_t b,
    int32_t *out0);
hmath_status hmath_scalar_multiply_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_i32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_i64(
    int64_t a,
    int64_t b,
    int64_t *out0);
hmath_status hmath_scalar_multiply_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_i64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_u8(
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
hmath_status hmath_scalar_multiply_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_u8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_u16(
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
hmath_status hmath_scalar_multiply_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_u16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_u32(
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
hmath_status hmath_scalar_multiply_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_u32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_u64(
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
hmath_status hmath_scalar_multiply_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_u64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_int(
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
hmath_status hmath_scalar_multiply_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_int(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_word(
    size_t a,
    size_t b,
    size_t *out0);
hmath_status hmath_scalar_multiply_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_word(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_c64(
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0,
    float *out1);
hmath_status hmath_scalar_multiply_c64(
    hmath_context *context,
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_c64(a_0, a_1, b_0, b_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multiply_c128(
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
hmath_status hmath_scalar_multiply_c128(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multiply_c128(a_0, a_1, b_0, b_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_f32(
    float a,
    float b,
    float *out0);
hmath_status hmath_scalar_minimum_scalar_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_f32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_f64(
    double a,
    double b,
    double *out0);
hmath_status hmath_scalar_minimum_scalar_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_f64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_rational(
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1);
hmath_status hmath_scalar_minimum_scalar_rational(
    hmath_context *context,
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1) {
    if (!hm_decimal(a_numerator) || !hm_decimal(a_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *a_digit = a_denominator;
    if (*a_digit == '-') ++a_digit;
    while (*a_digit == '0') ++a_digit;
    if (!*a_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!hm_decimal(b_numerator) || !hm_decimal(b_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *b_digit = b_denominator;
    if (*b_digit == '-') ++b_digit;
    while (*b_digit == '0') ++b_digit;
    if (!*b_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_rational(a_numerator, a_denominator, b_numerator, b_denominator, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_integer(
    const char *a,
    const char *b,
    char **out0);
hmath_status hmath_scalar_minimum_scalar_integer(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(b))
        return hm_error(HMATH_INVALID_ARGUMENT, "b: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_integer(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_i8(
    int8_t a,
    int8_t b,
    int8_t *out0);
hmath_status hmath_scalar_minimum_scalar_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_i8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_i16(
    int16_t a,
    int16_t b,
    int16_t *out0);
hmath_status hmath_scalar_minimum_scalar_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_i16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_i32(
    int32_t a,
    int32_t b,
    int32_t *out0);
hmath_status hmath_scalar_minimum_scalar_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_i32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_i64(
    int64_t a,
    int64_t b,
    int64_t *out0);
hmath_status hmath_scalar_minimum_scalar_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_i64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_u8(
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
hmath_status hmath_scalar_minimum_scalar_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_u8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_u16(
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
hmath_status hmath_scalar_minimum_scalar_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_u16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_u32(
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
hmath_status hmath_scalar_minimum_scalar_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_u32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_u64(
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
hmath_status hmath_scalar_minimum_scalar_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_u64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_int(
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
hmath_status hmath_scalar_minimum_scalar_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_int(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_minimum_scalar_word(
    size_t a,
    size_t b,
    size_t *out0);
hmath_status hmath_scalar_minimum_scalar_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_minimum_scalar_word(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_f32(
    float a,
    float b,
    float *out0);
hmath_status hmath_scalar_maximum_scalar_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_f32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_f64(
    double a,
    double b,
    double *out0);
hmath_status hmath_scalar_maximum_scalar_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_f64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_rational(
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1);
hmath_status hmath_scalar_maximum_scalar_rational(
    hmath_context *context,
    const char *a_numerator,
    const char *a_denominator,
    const char *b_numerator,
    const char *b_denominator,
    char **out0,
    char **out1) {
    if (!hm_decimal(a_numerator) || !hm_decimal(a_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *a_digit = a_denominator;
    if (*a_digit == '-') ++a_digit;
    while (*a_digit == '0') ++a_digit;
    if (!*a_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!hm_decimal(b_numerator) || !hm_decimal(b_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *b_digit = b_denominator;
    if (*b_digit == '-') ++b_digit;
    while (*b_digit == '0') ++b_digit;
    if (!*b_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_rational(a_numerator, a_denominator, b_numerator, b_denominator, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_integer(
    const char *a,
    const char *b,
    char **out0);
hmath_status hmath_scalar_maximum_scalar_integer(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(b))
        return hm_error(HMATH_INVALID_ARGUMENT, "b: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_integer(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_i8(
    int8_t a,
    int8_t b,
    int8_t *out0);
hmath_status hmath_scalar_maximum_scalar_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_i8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_i16(
    int16_t a,
    int16_t b,
    int16_t *out0);
hmath_status hmath_scalar_maximum_scalar_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_i16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_i32(
    int32_t a,
    int32_t b,
    int32_t *out0);
hmath_status hmath_scalar_maximum_scalar_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_i32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_i64(
    int64_t a,
    int64_t b,
    int64_t *out0);
hmath_status hmath_scalar_maximum_scalar_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_i64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_u8(
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
hmath_status hmath_scalar_maximum_scalar_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_u8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_u16(
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
hmath_status hmath_scalar_maximum_scalar_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_u16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_u32(
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
hmath_status hmath_scalar_maximum_scalar_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_u32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_u64(
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
hmath_status hmath_scalar_maximum_scalar_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_u64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_int(
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
hmath_status hmath_scalar_maximum_scalar_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_int(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_maximum_scalar_word(
    size_t a,
    size_t b,
    size_t *out0);
hmath_status hmath_scalar_maximum_scalar_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_maximum_scalar_word(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_f32(
    float x,
    float *out0);
hmath_status hmath_scalar_absolute_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_f64(
    double x,
    double *out0);
hmath_status hmath_scalar_absolute_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_rational(
    const char *x_numerator,
    const char *x_denominator,
    char **out0,
    char **out1);
hmath_status hmath_scalar_absolute_rational(
    hmath_context *context,
    const char *x_numerator,
    const char *x_denominator,
    char **out0,
    char **out1) {
    if (!hm_decimal(x_numerator) || !hm_decimal(x_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *x_digit = x_denominator;
    if (*x_digit == '-') ++x_digit;
    while (*x_digit == '0') ++x_digit;
    if (!*x_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_rational(x_numerator, x_denominator, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_integer(
    const char *x,
    char **out0);
hmath_status hmath_scalar_absolute_integer(
    hmath_context *context,
    const char *x,
    char **out0) {
    if (!hm_decimal(x))
        return hm_error(HMATH_INVALID_ARGUMENT, "x: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_integer(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_i8(
    int8_t x,
    int8_t *out0);
hmath_status hmath_scalar_absolute_i8(
    hmath_context *context,
    int8_t x,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_i8(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_i16(
    int16_t x,
    int16_t *out0);
hmath_status hmath_scalar_absolute_i16(
    hmath_context *context,
    int16_t x,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_i16(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_i32(
    int32_t x,
    int32_t *out0);
hmath_status hmath_scalar_absolute_i32(
    hmath_context *context,
    int32_t x,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_i32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_i64(
    int64_t x,
    int64_t *out0);
hmath_status hmath_scalar_absolute_i64(
    hmath_context *context,
    int64_t x,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_i64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_u8(
    uint8_t x,
    uint8_t *out0);
hmath_status hmath_scalar_absolute_u8(
    hmath_context *context,
    uint8_t x,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_u8(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_u16(
    uint16_t x,
    uint16_t *out0);
hmath_status hmath_scalar_absolute_u16(
    hmath_context *context,
    uint16_t x,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_u16(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_u32(
    uint32_t x,
    uint32_t *out0);
hmath_status hmath_scalar_absolute_u32(
    hmath_context *context,
    uint32_t x,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_u32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_u64(
    uint64_t x,
    uint64_t *out0);
hmath_status hmath_scalar_absolute_u64(
    hmath_context *context,
    uint64_t x,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_u64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_int(
    ptrdiff_t x,
    ptrdiff_t *out0);
hmath_status hmath_scalar_absolute_int(
    hmath_context *context,
    ptrdiff_t x,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_int(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_word(
    size_t x,
    size_t *out0);
hmath_status hmath_scalar_absolute_word(
    hmath_context *context,
    size_t x,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_word(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_c64(
    float x_0,
    float x_1,
    float *out0,
    float *out1);
hmath_status hmath_scalar_absolute_c64(
    hmath_context *context,
    float x_0,
    float x_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_c64(x_0, x_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_c128(
    double x_0,
    double x_1,
    double *out0,
    double *out1);
hmath_status hmath_scalar_absolute_c128(
    hmath_context *context,
    double x_0,
    double x_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_c128(x_0, x_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_f32(
    float x,
    float *out0);
hmath_status hmath_scalar_sign_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_f64(
    double x,
    double *out0);
hmath_status hmath_scalar_sign_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_rational(
    const char *x_numerator,
    const char *x_denominator,
    char **out0,
    char **out1);
hmath_status hmath_scalar_sign_rational(
    hmath_context *context,
    const char *x_numerator,
    const char *x_denominator,
    char **out0,
    char **out1) {
    if (!hm_decimal(x_numerator) || !hm_decimal(x_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *x_digit = x_denominator;
    if (*x_digit == '-') ++x_digit;
    while (*x_digit == '0') ++x_digit;
    if (!*x_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_rational(x_numerator, x_denominator, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_integer(
    const char *x,
    char **out0);
hmath_status hmath_scalar_sign_integer(
    hmath_context *context,
    const char *x,
    char **out0) {
    if (!hm_decimal(x))
        return hm_error(HMATH_INVALID_ARGUMENT, "x: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_integer(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_i8(
    int8_t x,
    int8_t *out0);
hmath_status hmath_scalar_sign_i8(
    hmath_context *context,
    int8_t x,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_i8(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_i16(
    int16_t x,
    int16_t *out0);
hmath_status hmath_scalar_sign_i16(
    hmath_context *context,
    int16_t x,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_i16(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_i32(
    int32_t x,
    int32_t *out0);
hmath_status hmath_scalar_sign_i32(
    hmath_context *context,
    int32_t x,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_i32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_i64(
    int64_t x,
    int64_t *out0);
hmath_status hmath_scalar_sign_i64(
    hmath_context *context,
    int64_t x,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_i64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_u8(
    uint8_t x,
    uint8_t *out0);
hmath_status hmath_scalar_sign_u8(
    hmath_context *context,
    uint8_t x,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_u8(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_u16(
    uint16_t x,
    uint16_t *out0);
hmath_status hmath_scalar_sign_u16(
    hmath_context *context,
    uint16_t x,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_u16(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_u32(
    uint32_t x,
    uint32_t *out0);
hmath_status hmath_scalar_sign_u32(
    hmath_context *context,
    uint32_t x,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_u32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_u64(
    uint64_t x,
    uint64_t *out0);
hmath_status hmath_scalar_sign_u64(
    hmath_context *context,
    uint64_t x,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_u64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_int(
    ptrdiff_t x,
    ptrdiff_t *out0);
hmath_status hmath_scalar_sign_int(
    hmath_context *context,
    ptrdiff_t x,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_int(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_word(
    size_t x,
    size_t *out0);
hmath_status hmath_scalar_sign_word(
    hmath_context *context,
    size_t x,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_word(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_c64(
    float x_0,
    float x_1,
    float *out0,
    float *out1);
hmath_status hmath_scalar_sign_c64(
    hmath_context *context,
    float x_0,
    float x_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_c64(x_0, x_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sign_c128(
    double x_0,
    double x_1,
    double *out0,
    double *out1);
hmath_status hmath_scalar_sign_c128(
    hmath_context *context,
    double x_0,
    double x_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sign_c128(x_0, x_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_divide_f32(
    float a,
    float b,
    float *out0);
hmath_status hmath_scalar_divide_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_divide_f32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_divide_f64(
    double a,
    double b,
    double *out0);
hmath_status hmath_scalar_divide_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_divide_f64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_power_f32(
    float a,
    float b,
    float *out0);
hmath_status hmath_scalar_power_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_power_f32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_power_f64(
    double a,
    double b,
    double *out0);
hmath_status hmath_scalar_power_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_power_f64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_hypot_f32(
    float a,
    float b,
    float *out0);
hmath_status hmath_scalar_hypot_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_hypot_f32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_hypot_f64(
    double a,
    double b,
    double *out0);
hmath_status hmath_scalar_hypot_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_hypot_f64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_clamp_checked_f32(
    float low,
    float high,
    float value,
    float *out0);
hmath_status hmath_scalar_clamp_checked_f32(
    hmath_context *context,
    float low,
    float high,
    float value,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_clamp_checked_f32(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_clamp_checked_f64(
    double low,
    double high,
    double value,
    double *out0);
hmath_status hmath_scalar_clamp_checked_f64(
    hmath_context *context,
    double low,
    double high,
    double value,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_clamp_checked_f64(low, high, value, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_lerp_checked_f32(
    float a,
    float b,
    float t,
    float *out0);
hmath_status hmath_scalar_lerp_checked_f32(
    hmath_context *context,
    float a,
    float b,
    float t,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_lerp_checked_f32(a, b, t, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_lerp_checked_f64(
    double a,
    double b,
    double t,
    double *out0);
hmath_status hmath_scalar_lerp_checked_f64(
    hmath_context *context,
    double a,
    double b,
    double t,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_lerp_checked_f64(a, b, t, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_inverse_lerp_f32(
    float a,
    float b,
    float x,
    float *out0);
hmath_status hmath_scalar_inverse_lerp_f32(
    hmath_context *context,
    float a,
    float b,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_inverse_lerp_f32(a, b, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_inverse_lerp_f64(
    double a,
    double b,
    double x,
    double *out0);
hmath_status hmath_scalar_inverse_lerp_f64(
    hmath_context *context,
    double a,
    double b,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_inverse_lerp_f64(a, b, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_smoothstep_f32(
    float a,
    float b,
    float x,
    float *out0);
hmath_status hmath_scalar_smoothstep_f32(
    hmath_context *context,
    float a,
    float b,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_smoothstep_f32(a, b, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_smoothstep_f64(
    double a,
    double b,
    double x,
    double *out0);
hmath_status hmath_scalar_smoothstep_f64(
    hmath_context *context,
    double a,
    double b,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_smoothstep_f64(a, b, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_smootherstep_f32(
    float a,
    float b,
    float x,
    float *out0);
hmath_status hmath_scalar_smootherstep_f32(
    hmath_context *context,
    float a,
    float b,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_smootherstep_f32(a, b, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_smootherstep_f64(
    double a,
    double b,
    double x,
    double *out0);
hmath_status hmath_scalar_smootherstep_f64(
    hmath_context *context,
    double a,
    double b,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_smootherstep_f64(a, b, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_remap_f32(
    float a,
    float b,
    float c,
    float d,
    float x,
    float *out0);
hmath_status hmath_scalar_remap_f32(
    hmath_context *context,
    float a,
    float b,
    float c,
    float d,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_remap_f32(a, b, c, d, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_remap_f64(
    double a,
    double b,
    double c,
    double d,
    double x,
    double *out0);
hmath_status hmath_scalar_remap_f64(
    hmath_context *context,
    double a,
    double b,
    double c,
    double d,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_remap_f64(a, b, c, d, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_step_f32(
    float edge,
    float x,
    float *out0);
hmath_status hmath_scalar_step_f32(
    hmath_context *context,
    float edge,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_step_f32(edge, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_step_f64(
    double edge,
    double x,
    double *out0);
hmath_status hmath_scalar_step_f64(
    hmath_context *context,
    double edge,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_step_f64(edge, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sqrt_checked_f32(
    float x,
    float *out0);
hmath_status hmath_scalar_sqrt_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sqrt_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_sqrt_checked_f64(
    double x,
    double *out0);
hmath_status hmath_scalar_sqrt_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_sqrt_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cube_root_f32(
    float x,
    float *out0);
hmath_status hmath_scalar_cube_root_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cube_root_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cube_root_f64(
    double x,
    double *out0);
hmath_status hmath_scalar_cube_root_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cube_root_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_reciprocal_sqrt_f32(
    float x,
    float *out0);
hmath_status hmath_scalar_reciprocal_sqrt_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_reciprocal_sqrt_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_reciprocal_sqrt_f64(
    double x,
    double *out0);
hmath_status hmath_scalar_reciprocal_sqrt_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_reciprocal_sqrt_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_exp_checked_f32(
    float x,
    float *out0);
hmath_status hmath_scalar_exp_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_exp_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_exp_checked_f64(
    double x,
    double *out0);
hmath_status hmath_scalar_exp_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_exp_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_log_checked_f32(
    float x,
    float *out0);
hmath_status hmath_scalar_log_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_log_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_log_checked_f64(
    double x,
    double *out0);
hmath_status hmath_scalar_log_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_log_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_expm1_f32(
    float x,
    float *out0);
hmath_status hmath_scalar_expm1_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_expm1_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_expm1_f64(
    double x,
    double *out0);
hmath_status hmath_scalar_expm1_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_expm1_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_log1p_f32(
    float x,
    float *out0);
hmath_status hmath_scalar_log1p_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_log1p_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_log1p_f64(
    double x,
    double *out0);
hmath_status hmath_scalar_log1p_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_log1p_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_integer_power_f32(
    float a,
    const char *n,
    float *out0);
hmath_status hmath_scalar_integer_power_f32(
    hmath_context *context,
    float a,
    const char *n,
    float *out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_integer_power_f32(a, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_integer_power_f64(
    double a,
    const char *n,
    double *out0);
hmath_status hmath_scalar_integer_power_f64(
    hmath_context *context,
    double a,
    const char *n,
    double *out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_integer_power_f64(a, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_nth_root_f32(
    ptrdiff_t n,
    float x,
    float *out0);
hmath_status hmath_scalar_nth_root_f32(
    hmath_context *context,
    ptrdiff_t n,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_nth_root_f32(n, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_nth_root_f64(
    ptrdiff_t n,
    double x,
    double *out0);
hmath_status hmath_scalar_nth_root_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_nth_root_f64(n, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_round_digits_f32(
    ptrdiff_t n,
    float x,
    float *out0);
hmath_status hmath_scalar_round_digits_f32(
    hmath_context *context,
    ptrdiff_t n,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_round_digits_f32(n, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_round_digits_f64(
    ptrdiff_t n,
    double x,
    double *out0);
hmath_status hmath_scalar_round_digits_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_round_digits_f64(n, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_error_f32(
    float actual,
    float expected,
    float *out0);
hmath_status hmath_scalar_absolute_error_f32(
    hmath_context *context,
    float actual,
    float expected,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_error_f32(actual, expected, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_absolute_error_f64(
    double actual,
    double expected,
    double *out0);
hmath_status hmath_scalar_absolute_error_f64(
    hmath_context *context,
    double actual,
    double expected,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_absolute_error_f64(actual, expected, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_relative_error_f32(
    float actual,
    float expected,
    float *out0);
hmath_status hmath_scalar_relative_error_f32(
    hmath_context *context,
    float actual,
    float expected,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_relative_error_f32(actual, expected, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_relative_error_f64(
    double actual,
    double expected,
    double *out0);
hmath_status hmath_scalar_relative_error_f64(
    hmath_context *context,
    double actual,
    double expected,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_relative_error_f64(actual, expected, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_fused_multiply_add_f32(
    float a,
    float b,
    float c,
    float *out0);
hmath_status hmath_scalar_fused_multiply_add_f32(
    hmath_context *context,
    float a,
    float b,
    float c,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_fused_multiply_add_f32(a, b, c, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_fused_multiply_add_f64(
    double a,
    double b,
    double c,
    double *out0);
hmath_status hmath_scalar_fused_multiply_add_f64(
    hmath_context *context,
    double a,
    double b,
    double c,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_fused_multiply_add_f64(a, b, c, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_float_multiply_f32(
    float a,
    float b,
    float *out0);
hmath_status hmath_scalar_checked_float_multiply_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_float_multiply_f32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_float_multiply_f64(
    double a,
    double b,
    double *out0);
hmath_status hmath_scalar_checked_float_multiply_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_float_multiply_f64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_floor_checked_f32(
    float x,
    char **out0);
hmath_status hmath_scalar_floor_checked_f32(
    hmath_context *context,
    float x,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_floor_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_floor_checked_f64(
    double x,
    char **out0);
hmath_status hmath_scalar_floor_checked_f64(
    hmath_context *context,
    double x,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_floor_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_ceil_checked_f32(
    float x,
    char **out0);
hmath_status hmath_scalar_ceil_checked_f32(
    hmath_context *context,
    float x,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_ceil_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_ceil_checked_f64(
    double x,
    char **out0);
hmath_status hmath_scalar_ceil_checked_f64(
    hmath_context *context,
    double x,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_ceil_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_round_checked_f32(
    float x,
    char **out0);
hmath_status hmath_scalar_round_checked_f32(
    hmath_context *context,
    float x,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_round_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_round_checked_f64(
    double x,
    char **out0);
hmath_status hmath_scalar_round_checked_f64(
    hmath_context *context,
    double x,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_round_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_truncate_checked_f32(
    float x,
    char **out0);
hmath_status hmath_scalar_truncate_checked_f32(
    hmath_context *context,
    float x,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_truncate_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_truncate_checked_f64(
    double x,
    char **out0);
hmath_status hmath_scalar_truncate_checked_f64(
    hmath_context *context,
    double x,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_truncate_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_bankers_round_f32(
    float x,
    char **out0);
hmath_status hmath_scalar_bankers_round_f32(
    hmath_context *context,
    float x,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_bankers_round_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_bankers_round_f64(
    double x,
    char **out0);
hmath_status hmath_scalar_bankers_round_f64(
    hmath_context *context,
    double x,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_bankers_round_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_integer_fraction_f32(
    float x,
    char **out0,
    float *out1);
hmath_status hmath_scalar_integer_fraction_f32(
    hmath_context *context,
    float x,
    char **out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_integer_fraction_f32(x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_integer_fraction_f64(
    double x,
    char **out0,
    double *out1);
hmath_status hmath_scalar_integer_fraction_f64(
    hmath_context *context,
    double x,
    char **out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_integer_fraction_f64(x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_quotient_remainder(
    const char *a,
    const char *b,
    char **out0,
    char **out1);
hmath_status hmath_scalar_quotient_remainder(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0,
    char **out1) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(b))
        return hm_error(HMATH_INVALID_ARGUMENT, "b: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_quotient_remainder(a, b, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_euclidean_division(
    const char *a,
    const char *b,
    char **out0,
    char **out1);
hmath_status hmath_scalar_euclidean_division(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0,
    char **out1) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(b))
        return hm_error(HMATH_INVALID_ARGUMENT, "b: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_euclidean_division(a, b, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_positive_modulo_integer(
    const char *a,
    const char *modulus,
    char **out0);
hmath_status hmath_scalar_positive_modulo_integer(
    hmath_context *context,
    const char *a,
    const char *modulus,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(modulus))
        return hm_error(HMATH_INVALID_ARGUMENT, "modulus: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_positive_modulo_integer(a, modulus, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_positive_modulo_i8(
    int8_t a,
    int8_t modulus,
    int8_t *out0);
hmath_status hmath_scalar_positive_modulo_i8(
    hmath_context *context,
    int8_t a,
    int8_t modulus,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_positive_modulo_i8(a, modulus, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_positive_modulo_i16(
    int16_t a,
    int16_t modulus,
    int16_t *out0);
hmath_status hmath_scalar_positive_modulo_i16(
    hmath_context *context,
    int16_t a,
    int16_t modulus,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_positive_modulo_i16(a, modulus, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_positive_modulo_i32(
    int32_t a,
    int32_t modulus,
    int32_t *out0);
hmath_status hmath_scalar_positive_modulo_i32(
    hmath_context *context,
    int32_t a,
    int32_t modulus,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_positive_modulo_i32(a, modulus, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_positive_modulo_i64(
    int64_t a,
    int64_t modulus,
    int64_t *out0);
hmath_status hmath_scalar_positive_modulo_i64(
    hmath_context *context,
    int64_t a,
    int64_t modulus,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_positive_modulo_i64(a, modulus, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_positive_modulo_u8(
    uint8_t a,
    uint8_t modulus,
    uint8_t *out0);
hmath_status hmath_scalar_positive_modulo_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t modulus,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_positive_modulo_u8(a, modulus, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_positive_modulo_u16(
    uint16_t a,
    uint16_t modulus,
    uint16_t *out0);
hmath_status hmath_scalar_positive_modulo_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t modulus,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_positive_modulo_u16(a, modulus, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_positive_modulo_u32(
    uint32_t a,
    uint32_t modulus,
    uint32_t *out0);
hmath_status hmath_scalar_positive_modulo_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t modulus,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_positive_modulo_u32(a, modulus, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_positive_modulo_u64(
    uint64_t a,
    uint64_t modulus,
    uint64_t *out0);
hmath_status hmath_scalar_positive_modulo_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t modulus,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_positive_modulo_u64(a, modulus, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_positive_modulo_int(
    ptrdiff_t a,
    ptrdiff_t modulus,
    ptrdiff_t *out0);
hmath_status hmath_scalar_positive_modulo_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t modulus,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_positive_modulo_int(a, modulus, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_positive_modulo_word(
    size_t a,
    size_t modulus,
    size_t *out0);
hmath_status hmath_scalar_positive_modulo_word(
    hmath_context *context,
    size_t a,
    size_t modulus,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_positive_modulo_word(a, modulus, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_positive_modulo(
    const char *a,
    const char *modulus,
    char **out0);
hmath_status hmath_scalar_positive_modulo(
    hmath_context *context,
    const char *a,
    const char *modulus,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(modulus))
        return hm_error(HMATH_INVALID_ARGUMENT, "modulus: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_positive_modulo(a, modulus, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_modular_power(
    const char *a,
    const char *n,
    const char *modulus,
    char **out0);
hmath_status hmath_scalar_modular_power(
    hmath_context *context,
    const char *a,
    const char *n,
    const char *modulus,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!hm_decimal(modulus))
        return hm_error(HMATH_INVALID_ARGUMENT, "modulus: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_modular_power(a, n, modulus, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_factorial_checked(
    const char *n,
    char **out0);
hmath_status hmath_scalar_factorial_checked(
    hmath_context *context,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_factorial_checked(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_double_factorial(
    const char *n,
    char **out0);
hmath_status hmath_scalar_double_factorial(
    hmath_context *context,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_double_factorial(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_fibonacci_checked(
    const char *n,
    char **out0);
hmath_status hmath_scalar_fibonacci_checked(
    hmath_context *context,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_fibonacci_checked(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_lucas(
    const char *n,
    char **out0);
hmath_status hmath_scalar_lucas(
    hmath_context *context,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_lucas(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_catalan(
    const char *n,
    char **out0);
hmath_status hmath_scalar_catalan(
    hmath_context *context,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_catalan(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_rising_factorial(
    const char *x,
    const char *n,
    char **out0);
hmath_status hmath_scalar_rising_factorial(
    hmath_context *context,
    const char *x,
    const char *n,
    char **out0) {
    if (!hm_decimal(x))
        return hm_error(HMATH_INVALID_ARGUMENT, "x: expected signed decimal Integer");
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_rising_factorial(x, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_falling_factorial(
    const char *x,
    const char *n,
    char **out0);
hmath_status hmath_scalar_falling_factorial(
    hmath_context *context,
    const char *x,
    const char *n,
    char **out0) {
    if (!hm_decimal(x))
        return hm_error(HMATH_INVALID_ARGUMENT, "x: expected signed decimal Integer");
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_falling_factorial(x, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_permutations(
    const char *n,
    const char *k,
    char **out0);
hmath_status hmath_scalar_permutations(
    hmath_context *context,
    const char *n,
    const char *k,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!hm_decimal(k))
        return hm_error(HMATH_INVALID_ARGUMENT, "k: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_permutations(n, k, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_combinations(
    const char *n,
    const char *k,
    char **out0);
hmath_status hmath_scalar_combinations(
    hmath_context *context,
    const char *n,
    const char *k,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!hm_decimal(k))
        return hm_error(HMATH_INVALID_ARGUMENT, "k: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_combinations(n, k, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_bernoulli(
    ptrdiff_t n,
    char **out0,
    char **out1);
hmath_status hmath_scalar_bernoulli(
    hmath_context *context,
    ptrdiff_t n,
    char **out0,
    char **out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_bernoulli(n, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_harmonic(
    const char *n,
    char **out0,
    char **out1);
hmath_status hmath_scalar_harmonic(
    hmath_context *context,
    const char *n,
    char **out0,
    char **out1) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_harmonic(n, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_f32(
    const float *values,
    size_t values_count,
    float *out0,
    size_t out_capacity);
hmath_status hmath_scalar_cumulative_sum_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0,
    size_t out_capacity) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (values_count + 0 > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "output byte span exceeds ptrdiff_t");
    if (out_capacity < values_count + 0)
        return hm_error(HMATH_BOUNDS_ERROR, "insufficient output capacity");
    if ((values_count + 0) && !out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_f32(values, values_count, out0, out_capacity);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_f64(
    const double *values,
    size_t values_count,
    double *out0,
    size_t out_capacity);
hmath_status hmath_scalar_cumulative_sum_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0,
    size_t out_capacity) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (values_count + 0 > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "output byte span exceeds ptrdiff_t");
    if (out_capacity < values_count + 0)
        return hm_error(HMATH_BOUNDS_ERROR, "insufficient output capacity");
    if ((values_count + 0) && !out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_f64(values, values_count, out0, out_capacity);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_rational(
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_rational(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * values_count; ++i) {
        if (!hm_decimal(values[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = values[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_rational(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_integer(
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_integer(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (values_count && !values))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < values_count; ++i) if (!hm_decimal(values[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_integer(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_i8(
    const int8_t *values,
    size_t values_count,
    int8_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_i8(
    hmath_context *context,
    const int8_t *values,
    size_t values_count,
    int8_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_i8(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_i16(
    const int16_t *values,
    size_t values_count,
    int16_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_i16(
    hmath_context *context,
    const int16_t *values,
    size_t values_count,
    int16_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_i16(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_i32(
    const int32_t *values,
    size_t values_count,
    int32_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_i32(
    hmath_context *context,
    const int32_t *values,
    size_t values_count,
    int32_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_i32(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_i64(
    const int64_t *values,
    size_t values_count,
    int64_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_i64(
    hmath_context *context,
    const int64_t *values,
    size_t values_count,
    int64_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_i64(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_u8(
    const uint8_t *values,
    size_t values_count,
    uint8_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_u8(
    hmath_context *context,
    const uint8_t *values,
    size_t values_count,
    uint8_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_u8(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_u16(
    const uint16_t *values,
    size_t values_count,
    uint16_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_u16(
    hmath_context *context,
    const uint16_t *values,
    size_t values_count,
    uint16_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_u16(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_u32(
    const uint32_t *values,
    size_t values_count,
    uint32_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_u32(
    hmath_context *context,
    const uint32_t *values,
    size_t values_count,
    uint32_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_u32(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_u64(
    const uint64_t *values,
    size_t values_count,
    uint64_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_u64(
    hmath_context *context,
    const uint64_t *values,
    size_t values_count,
    uint64_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_u64(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_int(
    const ptrdiff_t *values,
    size_t values_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_int(
    hmath_context *context,
    const ptrdiff_t *values,
    size_t values_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_int(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_word(
    const size_t *values,
    size_t values_count,
    size_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_word(
    hmath_context *context,
    const size_t *values,
    size_t values_count,
    size_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_word(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_c64(
    float const *values,
    size_t values_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_c64(
    hmath_context *context,
    float const *values,
    size_t values_count,
    float **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_c64(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_sum_c128(
    double const *values,
    size_t values_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_sum_c128(
    hmath_context *context,
    double const *values,
    size_t values_count,
    double **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_sum_c128(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_f32(
    const float *values,
    size_t values_count,
    float *out0,
    size_t out_capacity);
hmath_status hmath_scalar_cumulative_product_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0,
    size_t out_capacity) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (values_count + 0 > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "output byte span exceeds ptrdiff_t");
    if (out_capacity < values_count + 0)
        return hm_error(HMATH_BOUNDS_ERROR, "insufficient output capacity");
    if ((values_count + 0) && !out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_f32(values, values_count, out0, out_capacity);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_f64(
    const double *values,
    size_t values_count,
    double *out0,
    size_t out_capacity);
hmath_status hmath_scalar_cumulative_product_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0,
    size_t out_capacity) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (values_count + 0 > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "output byte span exceeds ptrdiff_t");
    if (out_capacity < values_count + 0)
        return hm_error(HMATH_BOUNDS_ERROR, "insufficient output capacity");
    if ((values_count + 0) && !out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_f64(values, values_count, out0, out_capacity);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_rational(
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_rational(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * values_count; ++i) {
        if (!hm_decimal(values[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = values[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_rational(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_integer(
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_integer(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (values_count && !values))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < values_count; ++i) if (!hm_decimal(values[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_integer(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_i8(
    const int8_t *values,
    size_t values_count,
    int8_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_i8(
    hmath_context *context,
    const int8_t *values,
    size_t values_count,
    int8_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_i8(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_i16(
    const int16_t *values,
    size_t values_count,
    int16_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_i16(
    hmath_context *context,
    const int16_t *values,
    size_t values_count,
    int16_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_i16(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_i32(
    const int32_t *values,
    size_t values_count,
    int32_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_i32(
    hmath_context *context,
    const int32_t *values,
    size_t values_count,
    int32_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_i32(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_i64(
    const int64_t *values,
    size_t values_count,
    int64_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_i64(
    hmath_context *context,
    const int64_t *values,
    size_t values_count,
    int64_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_i64(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_u8(
    const uint8_t *values,
    size_t values_count,
    uint8_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_u8(
    hmath_context *context,
    const uint8_t *values,
    size_t values_count,
    uint8_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_u8(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_u16(
    const uint16_t *values,
    size_t values_count,
    uint16_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_u16(
    hmath_context *context,
    const uint16_t *values,
    size_t values_count,
    uint16_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_u16(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_u32(
    const uint32_t *values,
    size_t values_count,
    uint32_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_u32(
    hmath_context *context,
    const uint32_t *values,
    size_t values_count,
    uint32_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_u32(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_u64(
    const uint64_t *values,
    size_t values_count,
    uint64_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_u64(
    hmath_context *context,
    const uint64_t *values,
    size_t values_count,
    uint64_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_u64(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_int(
    const ptrdiff_t *values,
    size_t values_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_int(
    hmath_context *context,
    const ptrdiff_t *values,
    size_t values_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_int(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_word(
    const size_t *values,
    size_t values_count,
    size_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_word(
    hmath_context *context,
    const size_t *values,
    size_t values_count,
    size_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_word(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_c64(
    float const *values,
    size_t values_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_c64(
    hmath_context *context,
    float const *values,
    size_t values_count,
    float **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_c64(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_cumulative_product_c128(
    double const *values,
    size_t values_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_scalar_cumulative_product_c128(
    hmath_context *context,
    double const *values,
    size_t values_count,
    double **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_cumulative_product_c128(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_f32(
    const float *values,
    size_t values_count,
    float *out0,
    size_t out_capacity);
hmath_status hmath_scalar_prefix_sum_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0,
    size_t out_capacity) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (values_count + 1 > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "output byte span exceeds ptrdiff_t");
    if (out_capacity < values_count + 1)
        return hm_error(HMATH_BOUNDS_ERROR, "insufficient output capacity");
    if ((values_count + 1) && !out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_f32(values, values_count, out0, out_capacity);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_f64(
    const double *values,
    size_t values_count,
    double *out0,
    size_t out_capacity);
hmath_status hmath_scalar_prefix_sum_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0,
    size_t out_capacity) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (values_count + 1 > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "output byte span exceeds ptrdiff_t");
    if (out_capacity < values_count + 1)
        return hm_error(HMATH_BOUNDS_ERROR, "insufficient output capacity");
    if ((values_count + 1) && !out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_f64(values, values_count, out0, out_capacity);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_rational(
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_rational(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * values_count; ++i) {
        if (!hm_decimal(values[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = values[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_rational(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_integer(
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_integer(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char * **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (values_count && !values))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < values_count; ++i) if (!hm_decimal(values[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_integer(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_i8(
    const int8_t *values,
    size_t values_count,
    int8_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_i8(
    hmath_context *context,
    const int8_t *values,
    size_t values_count,
    int8_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_i8(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_i16(
    const int16_t *values,
    size_t values_count,
    int16_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_i16(
    hmath_context *context,
    const int16_t *values,
    size_t values_count,
    int16_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_i16(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_i32(
    const int32_t *values,
    size_t values_count,
    int32_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_i32(
    hmath_context *context,
    const int32_t *values,
    size_t values_count,
    int32_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_i32(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_i64(
    const int64_t *values,
    size_t values_count,
    int64_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_i64(
    hmath_context *context,
    const int64_t *values,
    size_t values_count,
    int64_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_i64(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_u8(
    const uint8_t *values,
    size_t values_count,
    uint8_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_u8(
    hmath_context *context,
    const uint8_t *values,
    size_t values_count,
    uint8_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_u8(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_u16(
    const uint16_t *values,
    size_t values_count,
    uint16_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_u16(
    hmath_context *context,
    const uint16_t *values,
    size_t values_count,
    uint16_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_u16(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_u32(
    const uint32_t *values,
    size_t values_count,
    uint32_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_u32(
    hmath_context *context,
    const uint32_t *values,
    size_t values_count,
    uint32_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_u32(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_u64(
    const uint64_t *values,
    size_t values_count,
    uint64_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_u64(
    hmath_context *context,
    const uint64_t *values,
    size_t values_count,
    uint64_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_u64(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_int(
    const ptrdiff_t *values,
    size_t values_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_int(
    hmath_context *context,
    const ptrdiff_t *values,
    size_t values_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_int(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_word(
    const size_t *values,
    size_t values_count,
    size_t **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_word(
    hmath_context *context,
    const size_t *values,
    size_t values_count,
    size_t **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_word(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_c64(
    float const *values,
    size_t values_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_c64(
    hmath_context *context,
    float const *values,
    size_t values_count,
    float **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_c64(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_prefix_sum_c128(
    double const *values,
    size_t values_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_scalar_prefix_sum_c128(
    hmath_context *context,
    double const *values,
    size_t values_count,
    double **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_prefix_sum_c128(values, values_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_sin_checked_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_sin_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_sin_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_sin_checked_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_sin_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_sin_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_cos_checked_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_cos_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_cos_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_cos_checked_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_cos_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_cos_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_tan_checked_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_tan_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_tan_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_tan_checked_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_tan_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_tan_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_asin_checked_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_asin_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_asin_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_asin_checked_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_asin_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_asin_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_acos_checked_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_acos_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_acos_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_acos_checked_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_acos_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_acos_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_atan_checked_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_atan_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_atan_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_atan_checked_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_atan_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_atan_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_sec_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_sec_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_sec_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_sec_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_sec_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_sec_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_csc_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_csc_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_csc_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_csc_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_csc_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_csc_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_cot_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_cot_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_cot_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_cot_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_cot_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_cot_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_asec_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_asec_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_asec_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_asec_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_asec_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_asec_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_acsc_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_acsc_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_acsc_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_acsc_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_acsc_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_acsc_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_acot_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_acot_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_acot_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_acot_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_acot_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_acot_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_sinh_checked_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_sinh_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_sinh_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_sinh_checked_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_sinh_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_sinh_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_cosh_checked_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_cosh_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_cosh_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_cosh_checked_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_cosh_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_cosh_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_tanh_checked_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_tanh_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_tanh_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_tanh_checked_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_tanh_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_tanh_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_asinh_checked_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_asinh_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_asinh_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_asinh_checked_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_asinh_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_asinh_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_acosh_checked_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_acosh_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_acosh_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_acosh_checked_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_acosh_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_acosh_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_atanh_checked_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_atanh_checked_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_atanh_checked_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_atanh_checked_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_atanh_checked_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_atanh_checked_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_sech_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_sech_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_sech_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_sech_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_sech_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_sech_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_csch_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_csch_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_csch_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_csch_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_csch_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_csch_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_coth_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_coth_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_coth_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_coth_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_coth_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_coth_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_asech_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_asech_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_asech_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_asech_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_asech_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_asech_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_acsch_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_acsch_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_acsch_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_acsch_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_acsch_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_acsch_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_acoth_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_acoth_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_acoth_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_acoth_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_acoth_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_acoth_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_normalize_angle_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_normalize_angle_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_normalize_angle_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_normalize_angle_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_normalize_angle_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_normalize_angle_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_normalize_signed_angle_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_normalize_signed_angle_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_normalize_signed_angle_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_normalize_signed_angle_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_normalize_signed_angle_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_normalize_signed_angle_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_versine_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_versine_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_versine_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_versine_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_versine_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_versine_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_haversine_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_haversine_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_haversine_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_haversine_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_haversine_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_haversine_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_sinc_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_sinc_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_sinc_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_sinc_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_sinc_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_sinc_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_cosc_f32(
    float x,
    float *out0);
hmath_status hmath_trigonometry_cosc_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_cosc_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_cosc_f64(
    double x,
    double *out0);
hmath_status hmath_trigonometry_cosc_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_cosc_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_atan2_checked_f32(
    float y,
    float x,
    float *out0);
hmath_status hmath_trigonometry_atan2_checked_f32(
    hmath_context *context,
    float y,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_atan2_checked_f32(y, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_atan2_checked_f64(
    double y,
    double x,
    double *out0);
hmath_status hmath_trigonometry_atan2_checked_f64(
    hmath_context *context,
    double y,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_atan2_checked_f64(y, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_sincos_f32(
    float x,
    float *out0,
    float *out1);
hmath_status hmath_trigonometry_sincos_f32(
    hmath_context *context,
    float x,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_sincos_f32(x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_sincos_f64(
    double x,
    double *out0,
    double *out1);
hmath_status hmath_trigonometry_sincos_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_sincos_f64(x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_wrap_f32(
    float low,
    float high,
    float x,
    float *out0);
hmath_status hmath_trigonometry_wrap_f32(
    hmath_context *context,
    float low,
    float high,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_wrap_f32(low, high, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_wrap_f64(
    double low,
    double high,
    double x,
    double *out0);
hmath_status hmath_trigonometry_wrap_f64(
    hmath_context *context,
    double low,
    double high,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_wrap_f64(low, high, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_angle_difference_f32(
    float a,
    float b,
    float *out0);
hmath_status hmath_trigonometry_angle_difference_f32(
    hmath_context *context,
    float a,
    float b,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_angle_difference_f32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_angle_difference_f64(
    double a,
    double b,
    double *out0);
hmath_status hmath_trigonometry_angle_difference_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_angle_difference_f64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_great_circle_angle_f32(
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0);
hmath_status hmath_trigonometry_great_circle_angle_f32(
    hmath_context *context,
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_great_circle_angle_f32(a_0, a_1, b_0, b_1, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_great_circle_angle_f64(
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0);
hmath_status hmath_trigonometry_great_circle_angle_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_great_circle_angle_f64(a_0, a_1, b_0, b_1, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_great_circle_distance_f32(
    float radius,
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0);
hmath_status hmath_trigonometry_great_circle_distance_f32(
    hmath_context *context,
    float radius,
    float a_0,
    float a_1,
    float b_0,
    float b_1,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_great_circle_distance_f32(radius, a_0, a_1, b_0, b_1, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_great_circle_distance_f64(
    double radius,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0);
hmath_status hmath_trigonometry_great_circle_distance_f64(
    hmath_context *context,
    double radius,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_great_circle_distance_f64(radius, a_0, a_1, b_0, b_1, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_spherical_side_f32(
    float a,
    float b,
    float included,
    float *out0);
hmath_status hmath_trigonometry_spherical_side_f32(
    hmath_context *context,
    float a,
    float b,
    float included,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_spherical_side_f32(a, b, included, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_spherical_side_f64(
    double a,
    double b,
    double included,
    double *out0);
hmath_status hmath_trigonometry_spherical_side_f64(
    hmath_context *context,
    double a,
    double b,
    double included,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_spherical_side_f64(a, b, included, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_spherical_angles_f32(
    float a,
    float b,
    float c,
    float *out0,
    float *out1,
    float *out2);
hmath_status hmath_trigonometry_spherical_angles_f32(
    hmath_context *context,
    float a,
    float b,
    float c,
    float *out0,
    float *out1,
    float *out2) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_spherical_angles_f32(a, b, c, out0, out1, out2);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_spherical_angles_f64(
    double a,
    double b,
    double c,
    double *out0,
    double *out1,
    double *out2);
hmath_status hmath_trigonometry_spherical_angles_f64(
    hmath_context *context,
    double a,
    double b,
    double c,
    double *out0,
    double *out1,
    double *out2) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_spherical_angles_f64(a, b, c, out0, out1, out2);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_spherical_excess_f32(
    float a,
    float b,
    float c,
    float *out0);
hmath_status hmath_trigonometry_spherical_excess_f32(
    hmath_context *context,
    float a,
    float b,
    float c,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_spherical_excess_f32(a, b, c, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_spherical_excess_f64(
    double a,
    double b,
    double c,
    double *out0);
hmath_status hmath_trigonometry_spherical_excess_f64(
    hmath_context *context,
    double a,
    double b,
    double c,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_spherical_excess_f64(a, b, c, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_sin_f32(
    float z_0,
    float z_1,
    float *out0,
    float *out1);
hmath_status hmath_trigonometry_complex_sin_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_sin_f32(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_sin_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_trigonometry_complex_sin_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_sin_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_cos_f32(
    float z_0,
    float z_1,
    float *out0,
    float *out1);
hmath_status hmath_trigonometry_complex_cos_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_cos_f32(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_cos_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_trigonometry_complex_cos_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_cos_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_tan_f32(
    float z_0,
    float z_1,
    float *out0,
    float *out1);
hmath_status hmath_trigonometry_complex_tan_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_tan_f32(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_tan_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_trigonometry_complex_tan_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_tan_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_asin_f32(
    float z_0,
    float z_1,
    float *out0,
    float *out1);
hmath_status hmath_trigonometry_complex_asin_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_asin_f32(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_asin_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_trigonometry_complex_asin_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_asin_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_acos_f32(
    float z_0,
    float z_1,
    float *out0,
    float *out1);
hmath_status hmath_trigonometry_complex_acos_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_acos_f32(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_acos_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_trigonometry_complex_acos_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_acos_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_atan_f32(
    float z_0,
    float z_1,
    float *out0,
    float *out1);
hmath_status hmath_trigonometry_complex_atan_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_atan_f32(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_atan_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_trigonometry_complex_atan_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_atan_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_sinh_f32(
    float z_0,
    float z_1,
    float *out0,
    float *out1);
hmath_status hmath_trigonometry_complex_sinh_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_sinh_f32(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_sinh_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_trigonometry_complex_sinh_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_sinh_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_cosh_f32(
    float z_0,
    float z_1,
    float *out0,
    float *out1);
hmath_status hmath_trigonometry_complex_cosh_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_cosh_f32(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_cosh_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_trigonometry_complex_cosh_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_cosh_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_tanh_f32(
    float z_0,
    float z_1,
    float *out0,
    float *out1);
hmath_status hmath_trigonometry_complex_tanh_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_tanh_f32(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_tanh_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_trigonometry_complex_tanh_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_tanh_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_asinh_f32(
    float z_0,
    float z_1,
    float *out0,
    float *out1);
hmath_status hmath_trigonometry_complex_asinh_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_asinh_f32(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_asinh_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_trigonometry_complex_asinh_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_asinh_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_acosh_f32(
    float z_0,
    float z_1,
    float *out0,
    float *out1);
hmath_status hmath_trigonometry_complex_acosh_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_acosh_f32(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_acosh_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_trigonometry_complex_acosh_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_acosh_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_atanh_f32(
    float z_0,
    float z_1,
    float *out0,
    float *out1);
hmath_status hmath_trigonometry_complex_atanh_f32(
    hmath_context *context,
    float z_0,
    float z_1,
    float *out0,
    float *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_atanh_f32(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_complex_atanh_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_trigonometry_complex_atanh_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_complex_atanh_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_periodic_sawtooth_f32(
    float period,
    float x,
    float *out0);
hmath_status hmath_trigonometry_periodic_sawtooth_f32(
    hmath_context *context,
    float period,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_periodic_sawtooth_f32(period, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_periodic_sawtooth_f64(
    double period,
    double x,
    double *out0);
hmath_status hmath_trigonometry_periodic_sawtooth_f64(
    hmath_context *context,
    double period,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_periodic_sawtooth_f64(period, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_periodic_triangle_f32(
    float period,
    float x,
    float *out0);
hmath_status hmath_trigonometry_periodic_triangle_f32(
    hmath_context *context,
    float period,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_periodic_triangle_f32(period, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_periodic_triangle_f64(
    double period,
    double x,
    double *out0);
hmath_status hmath_trigonometry_periodic_triangle_f64(
    hmath_context *context,
    double period,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_periodic_triangle_f64(period, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_periodic_square_f32(
    float period,
    float x,
    float *out0);
hmath_status hmath_trigonometry_periodic_square_f32(
    hmath_context *context,
    float period,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_periodic_square_f32(period, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_trigonometry_periodic_square_f64(
    double period,
    double x,
    double *out0);
hmath_status hmath_trigonometry_periodic_square_f64(
    hmath_context *context,
    double period,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_trigonometry_periodic_square_f64(period, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_mean_f32(
    const float *values,
    size_t values_count,
    float *out0);
hmath_status hmath_statistics_mean_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_mean_f32(values, values_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_mean_f64(
    const double *values,
    size_t values_count,
    double *out0);
hmath_status hmath_statistics_mean_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_mean_f64(values, values_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_mean_rational(
    const char * const *values,
    size_t values_count,
    char **out0,
    char **out1);
hmath_status hmath_statistics_mean_rational(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char **out0,
    char **out1) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * values_count; ++i) {
        if (!hm_decimal(values[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = values[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_mean_rational(values, values_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_mean_c64(
    float const *values,
    size_t values_count,
    float *out0,
    float *out1);
hmath_status hmath_statistics_mean_c64(
    hmath_context *context,
    float const *values,
    size_t values_count,
    float *out0,
    float *out1) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_mean_c64(values, values_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_mean_c128(
    double const *values,
    size_t values_count,
    double *out0,
    double *out1);
hmath_status hmath_statistics_mean_c128(
    hmath_context *context,
    double const *values,
    size_t values_count,
    double *out0,
    double *out1) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_mean_c128(values, values_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_variance_f32(
    const float *values,
    size_t values_count,
    float *out0);
hmath_status hmath_statistics_variance_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_variance_f32(values, values_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_variance_f64(
    const double *values,
    size_t values_count,
    double *out0);
hmath_status hmath_statistics_variance_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_variance_f64(values, values_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_variance_rational(
    const char * const *values,
    size_t values_count,
    char **out0,
    char **out1);
hmath_status hmath_statistics_variance_rational(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char **out0,
    char **out1) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * values_count; ++i) {
        if (!hm_decimal(values[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = values[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_variance_rational(values, values_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_variance_c64(
    float const *values,
    size_t values_count,
    float *out0,
    float *out1);
hmath_status hmath_statistics_variance_c64(
    hmath_context *context,
    float const *values,
    size_t values_count,
    float *out0,
    float *out1) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_variance_c64(values, values_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_variance_c128(
    double const *values,
    size_t values_count,
    double *out0,
    double *out1);
hmath_status hmath_statistics_variance_c128(
    hmath_context *context,
    double const *values,
    size_t values_count,
    double *out0,
    double *out1) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_variance_c128(values, values_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_standard_deviation_f32(
    const float *values,
    size_t values_count,
    float *out0);
hmath_status hmath_statistics_standard_deviation_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_standard_deviation_f32(values, values_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_standard_deviation_f64(
    const double *values,
    size_t values_count,
    double *out0);
hmath_status hmath_statistics_standard_deviation_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_standard_deviation_f64(values, values_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_standard_deviation_c64(
    float const *values,
    size_t values_count,
    float *out0,
    float *out1);
hmath_status hmath_statistics_standard_deviation_c64(
    hmath_context *context,
    float const *values,
    size_t values_count,
    float *out0,
    float *out1) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_standard_deviation_c64(values, values_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_standard_deviation_c128(
    double const *values,
    size_t values_count,
    double *out0,
    double *out1);
hmath_status hmath_statistics_standard_deviation_c128(
    hmath_context *context,
    double const *values,
    size_t values_count,
    double *out0,
    double *out1) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_standard_deviation_c128(values, values_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_median_f32(
    const float *values,
    size_t values_count,
    float *out0);
hmath_status hmath_statistics_median_f32(
    hmath_context *context,
    const float *values,
    size_t values_count,
    float *out0) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_median_f32(values, values_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_median_f64(
    const double *values,
    size_t values_count,
    double *out0);
hmath_status hmath_statistics_median_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    double *out0) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_median_f64(values, values_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_median_rational(
    const char * const *values,
    size_t values_count,
    char **out0,
    char **out1);
hmath_status hmath_statistics_median_rational(
    hmath_context *context,
    const char * const *values,
    size_t values_count,
    char **out0,
    char **out1) {
    if (values_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * values_count; ++i) {
        if (!hm_decimal(values[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = values[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_median_rational(values, values_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_pi_constant_f32(
    float *out0);
hmath_status hmath_constants_pi_constant_f32(
    hmath_context *context,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_pi_constant_f32(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_pi_constant_f64(
    double *out0);
hmath_status hmath_constants_pi_constant_f64(
    hmath_context *context,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_pi_constant_f64(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_e_constant_f32(
    float *out0);
hmath_status hmath_constants_e_constant_f32(
    hmath_context *context,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_e_constant_f32(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_e_constant_f64(
    double *out0);
hmath_status hmath_constants_e_constant_f64(
    hmath_context *context,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_e_constant_f64(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_tau_f32(
    float *out0);
hmath_status hmath_constants_tau_f32(
    hmath_context *context,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_tau_f32(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_tau_f64(
    double *out0);
hmath_status hmath_constants_tau_f64(
    hmath_context *context,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_tau_f64(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_golden_ratio_f32(
    float *out0);
hmath_status hmath_constants_golden_ratio_f32(
    hmath_context *context,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_golden_ratio_f32(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_golden_ratio_f64(
    double *out0);
hmath_status hmath_constants_golden_ratio_f64(
    hmath_context *context,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_golden_ratio_f64(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_euler_mascheroni_f32(
    float *out0);
hmath_status hmath_constants_euler_mascheroni_f32(
    hmath_context *context,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_euler_mascheroni_f32(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_euler_mascheroni_f64(
    double *out0);
hmath_status hmath_constants_euler_mascheroni_f64(
    hmath_context *context,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_euler_mascheroni_f64(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_catalan_constant_f32(
    float *out0);
hmath_status hmath_constants_catalan_constant_f32(
    hmath_context *context,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_catalan_constant_f32(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_catalan_constant_f64(
    double *out0);
hmath_status hmath_constants_catalan_constant_f64(
    hmath_context *context,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_catalan_constant_f64(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_apery_constant_f32(
    float *out0);
hmath_status hmath_constants_apery_constant_f32(
    hmath_context *context,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_apery_constant_f32(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_apery_constant_f64(
    double *out0);
hmath_status hmath_constants_apery_constant_f64(
    hmath_context *context,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_apery_constant_f64(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_sqrt2_f32(
    float *out0);
hmath_status hmath_constants_sqrt2_f32(
    hmath_context *context,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_sqrt2_f32(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_sqrt2_f64(
    double *out0);
hmath_status hmath_constants_sqrt2_f64(
    hmath_context *context,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_sqrt2_f64(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_sqrt3_f32(
    float *out0);
hmath_status hmath_constants_sqrt3_f32(
    hmath_context *context,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_sqrt3_f32(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_sqrt3_f64(
    double *out0);
hmath_status hmath_constants_sqrt3_f64(
    hmath_context *context,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_sqrt3_f64(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_ln2_f32(
    float *out0);
hmath_status hmath_constants_ln2_f32(
    hmath_context *context,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_ln2_f32(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_ln2_f64(
    double *out0);
hmath_status hmath_constants_ln2_f64(
    hmath_context *context,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_ln2_f64(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_ln10_f32(
    float *out0);
hmath_status hmath_constants_ln10_f32(
    hmath_context *context,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_ln10_f32(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_ln10_f64(
    double *out0);
hmath_status hmath_constants_ln10_f64(
    hmath_context *context,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_ln10_f64(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_infinity_f32(
    float *out0);
hmath_status hmath_constants_infinity_f32(
    hmath_context *context,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_infinity_f32(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_infinity_f64(
    double *out0);
hmath_status hmath_constants_infinity_f64(
    hmath_context *context,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_infinity_f64(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_nan_f32(
    float *out0);
hmath_status hmath_constants_nan_f32(
    hmath_context *context,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_nan_f32(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_constants_nan_f64(
    double *out0);
hmath_status hmath_constants_nan_f64(
    hmath_context *context,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_constants_nan_f64(out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_multinomial(
    const char * const *ks,
    size_t ks_count,
    char **out0);
hmath_status hmath_scalar_multinomial(
    hmath_context *context,
    const char * const *ks,
    size_t ks_count,
    char **out0) {
    if (ks_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (ks_count && !ks))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < ks_count; ++i) if (!hm_decimal(ks[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (ks_count && !ks)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_multinomial(ks, ks_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_gcd_integer(
    const char *argument1,
    const char *argument2,
    char **out0);
hmath_status hmath_numbertheory_gcd_integer(
    hmath_context *context,
    const char *argument1,
    const char *argument2,
    char **out0) {
    if (!hm_decimal(argument1))
        return hm_error(HMATH_INVALID_ARGUMENT, "argument1: expected signed decimal Integer");
    if (!hm_decimal(argument2))
        return hm_error(HMATH_INVALID_ARGUMENT, "argument2: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_gcd_integer(argument1, argument2, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_lcm_integer(
    const char *argument1,
    const char *argument2,
    char **out0);
hmath_status hmath_numbertheory_lcm_integer(
    hmath_context *context,
    const char *argument1,
    const char *argument2,
    char **out0) {
    if (!hm_decimal(argument1))
        return hm_error(HMATH_INVALID_ARGUMENT, "argument1: expected signed decimal Integer");
    if (!hm_decimal(argument2))
        return hm_error(HMATH_INVALID_ARGUMENT, "argument2: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_lcm_integer(argument1, argument2, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_extended_g_c_d(
    const char *a,
    const char *b,
    char **out0,
    char **out1,
    char **out2);
hmath_status hmath_numbertheory_extended_g_c_d(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0,
    char **out1,
    char **out2) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(b))
        return hm_error(HMATH_INVALID_ARGUMENT, "b: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_extended_g_c_d(a, b, out0, out1, out2);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_bezout(
    const char *a,
    const char *b,
    char **out0,
    char **out1);
hmath_status hmath_numbertheory_bezout(
    hmath_context *context,
    const char *a,
    const char *b,
    char **out0,
    char **out1) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(b))
        return hm_error(HMATH_INVALID_ARGUMENT, "b: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_bezout(a, b, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_mod_pow(
    const char *a,
    const char *e,
    const char *m,
    char **out0);
hmath_status hmath_numbertheory_mod_pow(
    hmath_context *context,
    const char *a,
    const char *e,
    const char *m,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(e))
        return hm_error(HMATH_INVALID_ARGUMENT, "e: expected signed decimal Integer");
    if (!hm_decimal(m))
        return hm_error(HMATH_INVALID_ARGUMENT, "m: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_mod_pow(a, e, m, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_mod_inverse(
    const char *a,
    const char *m,
    char **out0);
hmath_status hmath_numbertheory_mod_inverse(
    hmath_context *context,
    const char *a,
    const char *m,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(m))
        return hm_error(HMATH_INVALID_ARGUMENT, "m: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_mod_inverse(a, m, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_integer_square_root(
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_integer_square_root(
    hmath_context *context,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_integer_square_root(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_is_prime_exact(
    ptrdiff_t budget,
    const char *n,
    int *out0);
hmath_status hmath_numbertheory_is_prime_exact(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    int *out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_is_prime_exact(budget, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_next_prime(
    ptrdiff_t budget,
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_next_prime(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_next_prime(budget, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_miller_rabin(
    const char * const *bases,
    size_t bases_count,
    const char *n,
    int *out0);
hmath_status hmath_numbertheory_miller_rabin(
    hmath_context *context,
    const char * const *bases,
    size_t bases_count,
    const char *n,
    int *out0) {
    if (bases_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (bases_count && !bases))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < bases_count; ++i) if (!hm_decimal(bases[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (bases_count && !bases)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_miller_rabin(bases, bases_count, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_baillie_p_s_w(
    const char *n,
    int *out0);
hmath_status hmath_numbertheory_baillie_p_s_w(
    hmath_context *context,
    const char *n,
    int *out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_baillie_p_s_w(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_sieve_eratosthenes(
    ptrdiff_t bound,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_numbertheory_sieve_eratosthenes(
    hmath_context *context,
    ptrdiff_t bound,
    char * **out_data,
    size_t *out_count) {
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_sieve_eratosthenes(bound, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_sieve_atkin(
    ptrdiff_t bound,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_numbertheory_sieve_atkin(
    hmath_context *context,
    ptrdiff_t bound,
    char * **out_data,
    size_t *out_count) {
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_sieve_atkin(bound, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_segmented_sieve(
    const char *lo,
    const char *hi,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_numbertheory_segmented_sieve(
    hmath_context *context,
    const char *lo,
    const char *hi,
    char * **out_data,
    size_t *out_count) {
    if (!hm_decimal(lo))
        return hm_error(HMATH_INVALID_ARGUMENT, "lo: expected signed decimal Integer");
    if (!hm_decimal(hi))
        return hm_error(HMATH_INVALID_ARGUMENT, "hi: expected signed decimal Integer");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_segmented_sieve(lo, hi, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_pollard_rho(
    ptrdiff_t budget,
    const char *seed,
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_pollard_rho(
    hmath_context *context,
    ptrdiff_t budget,
    const char *seed,
    const char *n,
    char **out0) {
    if (!hm_decimal(seed))
        return hm_error(HMATH_INVALID_ARGUMENT, "seed: expected signed decimal Integer");
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_pollard_rho(budget, seed, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_pollard_p_minus_one(
    ptrdiff_t bound,
    const char *base,
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_pollard_p_minus_one(
    hmath_context *context,
    ptrdiff_t bound,
    const char *base,
    const char *n,
    char **out0) {
    if (!hm_decimal(base))
        return hm_error(HMATH_INVALID_ARGUMENT, "base: expected signed decimal Integer");
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_pollard_p_minus_one(bound, base, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_fermat_factor(
    ptrdiff_t budget,
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_fermat_factor(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_fermat_factor(budget, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_divisors(
    ptrdiff_t budget,
    const char *n,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_numbertheory_divisors(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char * **out_data,
    size_t *out_count) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_divisors(budget, n, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_divisor_sum(
    ptrdiff_t budget,
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_divisor_sum(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_divisor_sum(budget, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_divisor_count(
    ptrdiff_t budget,
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_divisor_count(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_divisor_count(budget, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_euler_totient(
    ptrdiff_t budget,
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_euler_totient(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_euler_totient(budget, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_carmichael(
    ptrdiff_t budget,
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_carmichael(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_carmichael(budget, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_mobius(
    ptrdiff_t budget,
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_mobius(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_mobius(budget, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_liouville(
    ptrdiff_t budget,
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_liouville(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_liouville(budget, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_multiplicative_order(
    ptrdiff_t budget,
    const char *a,
    const char *m,
    char **out0);
hmath_status hmath_numbertheory_multiplicative_order(
    hmath_context *context,
    ptrdiff_t budget,
    const char *a,
    const char *m,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(m))
        return hm_error(HMATH_INVALID_ARGUMENT, "m: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_multiplicative_order(budget, a, m, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_primitive_root(
    ptrdiff_t budget,
    const char *m,
    char **out0);
hmath_status hmath_numbertheory_primitive_root(
    hmath_context *context,
    ptrdiff_t budget,
    const char *m,
    char **out0) {
    if (!hm_decimal(m))
        return hm_error(HMATH_INVALID_ARGUMENT, "m: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_primitive_root(budget, m, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_discrete_log(
    ptrdiff_t budget,
    const char *a,
    const char *b,
    const char *m,
    char **out0);
hmath_status hmath_numbertheory_discrete_log(
    hmath_context *context,
    ptrdiff_t budget,
    const char *a,
    const char *b,
    const char *m,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(b))
        return hm_error(HMATH_INVALID_ARGUMENT, "b: expected signed decimal Integer");
    if (!hm_decimal(m))
        return hm_error(HMATH_INVALID_ARGUMENT, "m: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_discrete_log(budget, a, b, m, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_legendre_symbol(
    ptrdiff_t budget,
    const char *a,
    const char *p,
    char **out0);
hmath_status hmath_numbertheory_legendre_symbol(
    hmath_context *context,
    ptrdiff_t budget,
    const char *a,
    const char *p,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(p))
        return hm_error(HMATH_INVALID_ARGUMENT, "p: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_legendre_symbol(budget, a, p, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_jacobi_symbol(
    const char *a,
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_jacobi_symbol(
    hmath_context *context,
    const char *a,
    const char *n,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_jacobi_symbol(a, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_kronecker_symbol(
    const char *a,
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_kronecker_symbol(
    hmath_context *context,
    const char *a,
    const char *n,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_kronecker_symbol(a, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_tonelli_shanks(
    ptrdiff_t budget,
    const char *a,
    const char *p,
    char **out0);
hmath_status hmath_numbertheory_tonelli_shanks(
    hmath_context *context,
    ptrdiff_t budget,
    const char *a,
    const char *p,
    char **out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(p))
        return hm_error(HMATH_INVALID_ARGUMENT, "p: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_tonelli_shanks(budget, a, p, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_continued_fraction(
    const char *r_numerator,
    const char *r_denominator,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_numbertheory_continued_fraction(
    hmath_context *context,
    const char *r_numerator,
    const char *r_denominator,
    char * **out_data,
    size_t *out_count) {
    if (!hm_decimal(r_numerator) || !hm_decimal(r_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *r_digit = r_denominator;
    if (*r_digit == '-') ++r_digit;
    while (*r_digit == '0') ++r_digit;
    if (!*r_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_continued_fraction(r_numerator, r_denominator, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_from_continued_fraction(
    const char * const *argument1,
    size_t argument1_count,
    char **out0,
    char **out1);
hmath_status hmath_numbertheory_from_continued_fraction(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    char **out0,
    char **out1) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (argument1_count && !argument1))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < argument1_count; ++i) if (!hm_decimal(argument1[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_from_continued_fraction(argument1, argument1_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_convergents(
    const char * const *xs,
    size_t xs_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_numbertheory_convergents(
    hmath_context *context,
    const char * const *xs,
    size_t xs_count,
    char * **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (xs_count && !xs))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < xs_count; ++i) if (!hm_decimal(xs[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_convergents(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_farey(
    const char *n,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_numbertheory_farey(
    hmath_context *context,
    const char *n,
    char * **out_data,
    size_t *out_count) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_farey(n, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_pell_fundamental(
    ptrdiff_t budget,
    const char *d,
    char **out0,
    char **out1);
hmath_status hmath_numbertheory_pell_fundamental(
    hmath_context *context,
    ptrdiff_t budget,
    const char *d,
    char **out0,
    char **out1) {
    if (!hm_decimal(d))
        return hm_error(HMATH_INVALID_ARGUMENT, "d: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_pell_fundamental(budget, d, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_is_perfect_number(
    ptrdiff_t budget,
    const char *n,
    int *out0);
hmath_status hmath_numbertheory_is_perfect_number(
    hmath_context *context,
    ptrdiff_t budget,
    const char *n,
    int *out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_is_perfect_number(budget, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_are_amicable(
    ptrdiff_t budget,
    const char *a,
    const char *b,
    int *out0);
hmath_status hmath_numbertheory_are_amicable(
    hmath_context *context,
    ptrdiff_t budget,
    const char *a,
    const char *b,
    int *out0) {
    if (!hm_decimal(a))
        return hm_error(HMATH_INVALID_ARGUMENT, "a: expected signed decimal Integer");
    if (!hm_decimal(b))
        return hm_error(HMATH_INVALID_ARGUMENT, "b: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_are_amicable(budget, a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_partition_count(
    ptrdiff_t n,
    char **out0);
hmath_status hmath_numbertheory_partition_count(
    hmath_context *context,
    ptrdiff_t n,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_partition_count(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numbertheory_fibonacci_fast(
    const char *n,
    char **out0);
hmath_status hmath_numbertheory_fibonacci_fast(
    hmath_context *context,
    const char *n,
    char **out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numbertheory_fibonacci_fast(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_permutations_count(
    ptrdiff_t n,
    ptrdiff_t k,
    char **out0);
hmath_status hmath_combinatorics_permutations_count(
    hmath_context *context,
    ptrdiff_t n,
    ptrdiff_t k,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_permutations_count(n, k, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_combinations_count(
    ptrdiff_t n,
    ptrdiff_t k,
    char **out0);
hmath_status hmath_combinatorics_combinations_count(
    hmath_context *context,
    ptrdiff_t n,
    ptrdiff_t k,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_combinations_count(n, k, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_multinomial(
    ptrdiff_t const *argument1,
    size_t argument1_count,
    char **out0);
hmath_status hmath_combinatorics_multinomial(
    hmath_context *context,
    ptrdiff_t const *argument1,
    size_t argument1_count,
    char **out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t) || (argument1_count && !argument1))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_multinomial(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_rank_permutation(
    ptrdiff_t const *p,
    size_t p_count,
    char **out0);
hmath_status hmath_combinatorics_rank_permutation(
    hmath_context *context,
    ptrdiff_t const *p,
    size_t p_count,
    char **out0) {
    if (p_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t) || (p_count && !p))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    if (p_count && !p)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_rank_permutation(p, p_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_unrank_permutation(
    ptrdiff_t n,
    const char *r,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_combinatorics_unrank_permutation(
    hmath_context *context,
    ptrdiff_t n,
    const char *r,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (!hm_decimal(r))
        return hm_error(HMATH_INVALID_ARGUMENT, "r: expected signed decimal Integer");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_unrank_permutation(n, r, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_rank_combination(
    ptrdiff_t n,
    ptrdiff_t const *xs,
    size_t xs_count,
    char **out0);
hmath_status hmath_combinatorics_rank_combination(
    hmath_context *context,
    ptrdiff_t n,
    ptrdiff_t const *xs,
    size_t xs_count,
    char **out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t) || (xs_count && !xs))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_rank_combination(n, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_unrank_combination(
    ptrdiff_t n,
    ptrdiff_t k,
    const char *r,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_combinatorics_unrank_combination(
    hmath_context *context,
    ptrdiff_t n,
    ptrdiff_t k,
    const char *r,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (!hm_decimal(r))
        return hm_error(HMATH_INVALID_ARGUMENT, "r: expected signed decimal Integer");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_unrank_combination(n, k, r, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_derangement_count(
    ptrdiff_t n,
    char **out0);
hmath_status hmath_combinatorics_derangement_count(
    hmath_context *context,
    ptrdiff_t n,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_derangement_count(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_stirling_first(
    ptrdiff_t argument1,
    ptrdiff_t argument2,
    char **out0);
hmath_status hmath_combinatorics_stirling_first(
    hmath_context *context,
    ptrdiff_t argument1,
    ptrdiff_t argument2,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_stirling_first(argument1, argument2, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_stirling_second(
    ptrdiff_t argument1,
    ptrdiff_t argument2,
    char **out0);
hmath_status hmath_combinatorics_stirling_second(
    hmath_context *context,
    ptrdiff_t argument1,
    ptrdiff_t argument2,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_stirling_second(argument1, argument2, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_bell_number(
    ptrdiff_t n,
    char **out0);
hmath_status hmath_combinatorics_bell_number(
    hmath_context *context,
    ptrdiff_t n,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_bell_number(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_eulerian_number(
    ptrdiff_t argument1,
    ptrdiff_t argument2,
    char **out0);
hmath_status hmath_combinatorics_eulerian_number(
    hmath_context *context,
    ptrdiff_t argument1,
    ptrdiff_t argument2,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_eulerian_number(argument1, argument2, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_lah_number(
    ptrdiff_t n,
    ptrdiff_t k,
    char **out0);
hmath_status hmath_combinatorics_lah_number(
    hmath_context *context,
    ptrdiff_t n,
    ptrdiff_t k,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_lah_number(n, k, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_catalan_number(
    ptrdiff_t argument1,
    char **out0);
hmath_status hmath_combinatorics_catalan_number(
    hmath_context *context,
    ptrdiff_t argument1,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_catalan_number(argument1, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_fibonacci(
    ptrdiff_t n,
    char **out0);
hmath_status hmath_combinatorics_fibonacci(
    hmath_context *context,
    ptrdiff_t n,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_fibonacci(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_lucas(
    ptrdiff_t n,
    char **out0);
hmath_status hmath_combinatorics_lucas(
    hmath_context *context,
    ptrdiff_t n,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_lucas(n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_inclusion_exclusion(
    ptrdiff_t n,
    const char * const *sizes,
    size_t sizes_count,
    char **out0);
hmath_status hmath_combinatorics_inclusion_exclusion(
    hmath_context *context,
    ptrdiff_t n,
    const char * const *sizes,
    size_t sizes_count,
    char **out0) {
    if (sizes_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (sizes_count && !sizes))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < sizes_count; ++i) if (!hm_decimal(sizes[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (sizes_count && !sizes)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_inclusion_exclusion(n, sizes, sizes_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_multiset_count_f32(
    const float *argument1,
    size_t argument1_count,
    char **out0);
hmath_status hmath_combinatorics_multiset_count_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    char **out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_multiset_count_f32(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_multiset_count_f64(
    const double *argument1,
    size_t argument1_count,
    char **out0);
hmath_status hmath_combinatorics_multiset_count_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    char **out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_multiset_count_f64(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_linear_recurrence(
    ptrdiff_t n,
    const char * const *cs,
    size_t cs_count,
    const char * const *initial,
    size_t initial_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_combinatorics_linear_recurrence(
    hmath_context *context,
    ptrdiff_t n,
    const char * const *cs,
    size_t cs_count,
    const char * const *initial,
    size_t initial_count,
    char * **out_data,
    size_t *out_count) {
    if (cs_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (cs_count && !cs))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < cs_count; ++i) if (!hm_decimal(cs[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (cs_count && !cs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (initial_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (initial_count && !initial))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < initial_count; ++i) if (!hm_decimal(initial[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (initial_count && !initial)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_linear_recurrence(n, cs, cs_count, initial, initial_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_convolve_series(
    ptrdiff_t n,
    const char * const *a,
    size_t a_count,
    const char * const *b,
    size_t b_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_combinatorics_convolve_series(
    hmath_context *context,
    ptrdiff_t n,
    const char * const *a,
    size_t a_count,
    const char * const *b,
    size_t b_count,
    char * **out_data,
    size_t *out_count) {
    if (a_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (a_count && !a))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < a_count; ++i) if (!hm_decimal(a[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (a_count && !a)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (b_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (b_count && !b))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < b_count; ++i) if (!hm_decimal(b[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (b_count && !b)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_convolve_series(n, a, a_count, b, b_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_finite_sum_f32(
    const float *argument1,
    size_t argument1_count,
    float *out0);
hmath_status hmath_combinatorics_finite_sum_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_finite_sum_f32(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_combinatorics_finite_sum_f64(
    const double *argument1,
    size_t argument1_count,
    double *out0);
hmath_status hmath_combinatorics_finite_sum_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_combinatorics_finite_sum_f64(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_f32(
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float *out0);
hmath_status hmath_linear_dot_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_f32(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_f64(
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double *out0);
hmath_status hmath_linear_dot_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_f64(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_rational(
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char **out0,
    char **out1);
hmath_status hmath_linear_dot_rational(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char **out0,
    char **out1) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * argument1_count; ++i) {
        if (!hm_decimal(argument1[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = argument1[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * argument2_count; ++i) {
        if (!hm_decimal(argument2[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = argument2[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_rational(argument1, argument1_count, argument2, argument2_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_integer(
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char **out0);
hmath_status hmath_linear_dot_integer(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char **out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (argument1_count && !argument1))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < argument1_count; ++i) if (!hm_decimal(argument1[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (argument2_count && !argument2))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < argument2_count; ++i) if (!hm_decimal(argument2[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_integer(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_i8(
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t *out0);
hmath_status hmath_linear_dot_i8(
    hmath_context *context,
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_i8(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_i16(
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t *out0);
hmath_status hmath_linear_dot_i16(
    hmath_context *context,
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_i16(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_i32(
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t *out0);
hmath_status hmath_linear_dot_i32(
    hmath_context *context,
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_i32(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_i64(
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t *out0);
hmath_status hmath_linear_dot_i64(
    hmath_context *context,
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_i64(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_u8(
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t *out0);
hmath_status hmath_linear_dot_u8(
    hmath_context *context,
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_u8(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_u16(
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t *out0);
hmath_status hmath_linear_dot_u16(
    hmath_context *context,
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_u16(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_u32(
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t *out0);
hmath_status hmath_linear_dot_u32(
    hmath_context *context,
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_u32(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_u64(
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t *out0);
hmath_status hmath_linear_dot_u64(
    hmath_context *context,
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_u64(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_int(
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t *out0);
hmath_status hmath_linear_dot_int(
    hmath_context *context,
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_int(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_word(
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t *out0);
hmath_status hmath_linear_dot_word(
    hmath_context *context,
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_word(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_c64(
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float *out0,
    float *out1);
hmath_status hmath_linear_dot_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float *out0,
    float *out1) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_c64(argument1, argument1_count, argument2, argument2_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_c128(
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double *out0,
    double *out1);
hmath_status hmath_linear_dot_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double *out0,
    double *out1) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_c128(argument1, argument1_count, argument2, argument2_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_f32(
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float *out0);
hmath_status hmath_linear_dot_checked_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_f32(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_f64(
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double *out0);
hmath_status hmath_linear_dot_checked_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_f64(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_rational(
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char **out0,
    char **out1);
hmath_status hmath_linear_dot_checked_rational(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char **out0,
    char **out1) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * argument1_count; ++i) {
        if (!hm_decimal(argument1[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = argument1[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * argument2_count; ++i) {
        if (!hm_decimal(argument2[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = argument2[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_rational(argument1, argument1_count, argument2, argument2_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_integer(
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char **out0);
hmath_status hmath_linear_dot_checked_integer(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char **out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (argument1_count && !argument1))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < argument1_count; ++i) if (!hm_decimal(argument1[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (argument2_count && !argument2))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < argument2_count; ++i) if (!hm_decimal(argument2[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_integer(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_i8(
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t *out0);
hmath_status hmath_linear_dot_checked_i8(
    hmath_context *context,
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_i8(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_i16(
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t *out0);
hmath_status hmath_linear_dot_checked_i16(
    hmath_context *context,
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_i16(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_i32(
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t *out0);
hmath_status hmath_linear_dot_checked_i32(
    hmath_context *context,
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_i32(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_i64(
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t *out0);
hmath_status hmath_linear_dot_checked_i64(
    hmath_context *context,
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_i64(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_u8(
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t *out0);
hmath_status hmath_linear_dot_checked_u8(
    hmath_context *context,
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_u8(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_u16(
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t *out0);
hmath_status hmath_linear_dot_checked_u16(
    hmath_context *context,
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_u16(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_u32(
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t *out0);
hmath_status hmath_linear_dot_checked_u32(
    hmath_context *context,
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_u32(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_u64(
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t *out0);
hmath_status hmath_linear_dot_checked_u64(
    hmath_context *context,
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_u64(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_int(
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t *out0);
hmath_status hmath_linear_dot_checked_int(
    hmath_context *context,
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_int(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_word(
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t *out0);
hmath_status hmath_linear_dot_checked_word(
    hmath_context *context,
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_word(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_c64(
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float *out0,
    float *out1);
hmath_status hmath_linear_dot_checked_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float *out0,
    float *out1) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_c64(argument1, argument1_count, argument2, argument2_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_dot_checked_c128(
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double *out0,
    double *out1);
hmath_status hmath_linear_dot_checked_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double *out0,
    double *out1) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_dot_checked_c128(argument1, argument1_count, argument2, argument2_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_magnitude_f32(
    const float *argument1,
    size_t argument1_count,
    float *out0);
hmath_status hmath_linear_magnitude_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_magnitude_f32(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_magnitude_f64(
    const double *argument1,
    size_t argument1_count,
    double *out0);
hmath_status hmath_linear_magnitude_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_magnitude_f64(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_magnitude_c64(
    float const *argument1,
    size_t argument1_count,
    float *out0,
    float *out1);
hmath_status hmath_linear_magnitude_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float *out0,
    float *out1) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_magnitude_c64(argument1, argument1_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_magnitude_c128(
    double const *argument1,
    size_t argument1_count,
    double *out0,
    double *out1);
hmath_status hmath_linear_magnitude_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double *out0,
    double *out1) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_magnitude_c128(argument1, argument1_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_normalize_f32(
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_linear_normalize_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_normalize_f32(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_normalize_f64(
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_linear_normalize_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_normalize_f64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_normalize_c64(
    float const *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_linear_normalize_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_normalize_c64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_normalize_c128(
    double const *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_linear_normalize_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_normalize_c128(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_f32(
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_f32(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_f64(
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_f64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_rational(
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_rational(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * argument1_count; ++i) {
        if (!hm_decimal(argument1[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = argument1[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * argument2_count; ++i) {
        if (!hm_decimal(argument2[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = argument2[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_rational(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_integer(
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_integer(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (argument1_count && !argument1))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < argument1_count; ++i) if (!hm_decimal(argument1[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (argument2_count && !argument2))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < argument2_count; ++i) if (!hm_decimal(argument2[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_integer(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_i8(
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_i8(
    hmath_context *context,
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_i8(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_i16(
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_i16(
    hmath_context *context,
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_i16(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_i32(
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_i32(
    hmath_context *context,
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_i32(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_i64(
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_i64(
    hmath_context *context,
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_i64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_u8(
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_u8(
    hmath_context *context,
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_u8(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_u16(
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_u16(
    hmath_context *context,
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_u16(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_u32(
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_u32(
    hmath_context *context,
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_u32(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_u64(
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_u64(
    hmath_context *context,
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_u64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_int(
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_int(
    hmath_context *context,
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_int(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_word(
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_word(
    hmath_context *context,
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_word(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_c64(
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_c64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_c128(
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_c128(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_f32(
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_f32(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_f64(
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_f64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_rational(
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_rational(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * argument1_count; ++i) {
        if (!hm_decimal(argument1[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = argument1[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * argument2_count; ++i) {
        if (!hm_decimal(argument2[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = argument2[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_rational(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_integer(
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_integer(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (argument1_count && !argument1))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < argument1_count; ++i) if (!hm_decimal(argument1[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (argument2_count && !argument2))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < argument2_count; ++i) if (!hm_decimal(argument2[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_integer(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_i8(
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_i8(
    hmath_context *context,
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_i8(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_i16(
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_i16(
    hmath_context *context,
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_i16(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_i32(
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_i32(
    hmath_context *context,
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_i32(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_i64(
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_i64(
    hmath_context *context,
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_i64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_u8(
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_u8(
    hmath_context *context,
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_u8(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_u16(
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_u16(
    hmath_context *context,
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_u16(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_u32(
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_u32(
    hmath_context *context,
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_u32(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_u64(
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_u64(
    hmath_context *context,
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_u64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_int(
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_int(
    hmath_context *context,
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_int(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_word(
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_word(
    hmath_context *context,
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_word(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_c64(
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_c64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_add_checked_c128(
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_linear_add_checked_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_add_checked_c128(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_f32(
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_f32(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_f64(
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_f64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_rational(
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_rational(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * argument1_count; ++i) {
        if (!hm_decimal(argument1[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = argument1[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * argument2_count; ++i) {
        if (!hm_decimal(argument2[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = argument2[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_rational(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_integer(
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_integer(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (argument1_count && !argument1))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < argument1_count; ++i) if (!hm_decimal(argument1[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (argument2_count && !argument2))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < argument2_count; ++i) if (!hm_decimal(argument2[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_integer(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_i8(
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_i8(
    hmath_context *context,
    const int8_t *argument1,
    size_t argument1_count,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_i8(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_i16(
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_i16(
    hmath_context *context,
    const int16_t *argument1,
    size_t argument1_count,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_i16(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_i32(
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_i32(
    hmath_context *context,
    const int32_t *argument1,
    size_t argument1_count,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_i32(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_i64(
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_i64(
    hmath_context *context,
    const int64_t *argument1,
    size_t argument1_count,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_i64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_u8(
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_u8(
    hmath_context *context,
    const uint8_t *argument1,
    size_t argument1_count,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_u8(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_u16(
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_u16(
    hmath_context *context,
    const uint16_t *argument1,
    size_t argument1_count,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_u16(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_u32(
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_u32(
    hmath_context *context,
    const uint32_t *argument1,
    size_t argument1_count,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_u32(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_u64(
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_u64(
    hmath_context *context,
    const uint64_t *argument1,
    size_t argument1_count,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_u64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_int(
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_int(
    hmath_context *context,
    const ptrdiff_t *argument1,
    size_t argument1_count,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_int(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_word(
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_word(
    hmath_context *context,
    const size_t *argument1,
    size_t argument1_count,
    const size_t *argument2,
    size_t argument2_count,
    size_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_word(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_c64(
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_c64(
    hmath_context *context,
    float const *argument1,
    size_t argument1_count,
    float const *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_c64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_subtract_checked_c128(
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_linear_subtract_checked_c128(
    hmath_context *context,
    double const *argument1,
    size_t argument1_count,
    double const *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_subtract_checked_c128(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_f32(
    float argument1,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_f32(
    hmath_context *context,
    float argument1,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_f32(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_f64(
    double argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_f64(
    hmath_context *context,
    double argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_f64(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_rational(
    const char *argument1_numerator,
    const char *argument1_denominator,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_rational(
    hmath_context *context,
    const char *argument1_numerator,
    const char *argument1_denominator,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count) {
    if (!hm_decimal(argument1_numerator) || !hm_decimal(argument1_denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal components");
    const char *argument1_digit = argument1_denominator;
    if (*argument1_digit == '-') ++argument1_digit;
    while (*argument1_digit == '0') ++argument1_digit;
    if (!*argument1_digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational denominator");
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(const char *)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    for (size_t i = 0; i < 2 * argument2_count; ++i) {
        if (!hm_decimal(argument2[i]))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational list component");
        if (i % 2) {
            const char *digit = argument2[i];
            if (*digit == '-') ++digit;
            while (*digit == '0') ++digit;
            if (!*digit)
        return hm_error(HMATH_INVALID_ARGUMENT, "zero Rational list denominator");
        }
    }
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_rational(argument1_numerator, argument1_denominator, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_integer(
    const char *argument1,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_integer(
    hmath_context *context,
    const char *argument1,
    const char * const *argument2,
    size_t argument2_count,
    char * **out_data,
    size_t *out_count) {
    if (!hm_decimal(argument1))
        return hm_error(HMATH_INVALID_ARGUMENT, "argument1: expected signed decimal Integer");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (argument2_count && !argument2))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < argument2_count; ++i) if (!hm_decimal(argument2[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_integer(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_i8(
    int8_t argument1,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_i8(
    hmath_context *context,
    int8_t argument1,
    const int8_t *argument2,
    size_t argument2_count,
    int8_t **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_i8(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_i16(
    int16_t argument1,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_i16(
    hmath_context *context,
    int16_t argument1,
    const int16_t *argument2,
    size_t argument2_count,
    int16_t **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_i16(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_i32(
    int32_t argument1,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_i32(
    hmath_context *context,
    int32_t argument1,
    const int32_t *argument2,
    size_t argument2_count,
    int32_t **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_i32(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_i64(
    int64_t argument1,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_i64(
    hmath_context *context,
    int64_t argument1,
    const int64_t *argument2,
    size_t argument2_count,
    int64_t **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(int64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_i64(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_u8(
    uint8_t argument1,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_u8(
    hmath_context *context,
    uint8_t argument1,
    const uint8_t *argument2,
    size_t argument2_count,
    uint8_t **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint8_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_u8(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_u16(
    uint16_t argument1,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_u16(
    hmath_context *context,
    uint16_t argument1,
    const uint16_t *argument2,
    size_t argument2_count,
    uint16_t **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint16_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_u16(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_u32(
    uint32_t argument1,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_u32(
    hmath_context *context,
    uint32_t argument1,
    const uint32_t *argument2,
    size_t argument2_count,
    uint32_t **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_u32(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_u64(
    uint64_t argument1,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_u64(
    hmath_context *context,
    uint64_t argument1,
    const uint64_t *argument2,
    size_t argument2_count,
    uint64_t **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(uint64_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_u64(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_int(
    ptrdiff_t argument1,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_int(
    hmath_context *context,
    ptrdiff_t argument1,
    const ptrdiff_t *argument2,
    size_t argument2_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_int(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_word(
    size_t argument1,
    const size_t *argument2,
    size_t argument2_count,
    size_t **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_word(
    hmath_context *context,
    size_t argument1,
    const size_t *argument2,
    size_t argument2_count,
    size_t **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(size_t))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_word(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_c64(
    float argument1_0,
    float argument1_1,
    float const *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_c64(
    hmath_context *context,
    float argument1_0,
    float argument1_1,
    float const *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(float)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_c64(argument1_0, argument1_1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_linear_scale_c128(
    double argument1_0,
    double argument1_1,
    double const *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_linear_scale_c128(
    hmath_context *context,
    double argument1_0,
    double argument1_1,
    double const *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / (2 * sizeof(double)))
        return hm_error(HMATH_OVERFLOW, "paired list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL paired list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_linear_scale_c128(argument1_0, argument1_1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_special_gamma_f64(
    double x,
    double *out0);
hmath_status hmath_special_gamma_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_gamma_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_log_gamma_f64(
    double x,
    double *out0);
hmath_status hmath_special_log_gamma_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_log_gamma_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_log_beta_f64(
    double a,
    double b,
    double *out0);
hmath_status hmath_special_log_beta_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_log_beta_f64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_beta_f64(
    double a,
    double b,
    double *out0);
hmath_status hmath_special_beta_f64(
    hmath_context *context,
    double a,
    double b,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_beta_f64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_gamma_p_f64(
    double a,
    double x,
    double *out0);
hmath_status hmath_special_gamma_p_f64(
    hmath_context *context,
    double a,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_gamma_p_f64(a, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_gamma_q_f64(
    double a,
    double x,
    double *out0);
hmath_status hmath_special_gamma_q_f64(
    hmath_context *context,
    double a,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_gamma_q_f64(a, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_incomplete_gamma_f64(
    double a,
    double x,
    double *out0);
hmath_status hmath_special_incomplete_gamma_f64(
    hmath_context *context,
    double a,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_incomplete_gamma_f64(a, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_beta_i_f64(
    double a,
    double b,
    double x,
    double *out0);
hmath_status hmath_special_beta_i_f64(
    hmath_context *context,
    double a,
    double b,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_beta_i_f64(a, b, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_incomplete_beta_f64(
    double a,
    double b,
    double x,
    double *out0);
hmath_status hmath_special_incomplete_beta_f64(
    hmath_context *context,
    double a,
    double b,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_incomplete_beta_f64(a, b, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_digamma_f64(
    double x,
    double *out0);
hmath_status hmath_special_digamma_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_digamma_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_trigamma_f64(
    double argument1,
    double *out0);
hmath_status hmath_special_trigamma_f64(
    hmath_context *context,
    double argument1,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_trigamma_f64(argument1, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_polygamma_f64(
    ptrdiff_t n,
    double x,
    double *out0);
hmath_status hmath_special_polygamma_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_polygamma_f64(n, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_erf_f64(
    double x,
    double *out0);
hmath_status hmath_special_erf_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_erf_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_erfc_f64(
    double x,
    double *out0);
hmath_status hmath_special_erfc_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_erfc_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_erfcx_f64(
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_erfcx_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_erfcx_f64(x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_normal_c_d_f_f64(
    double x,
    double *out0);
hmath_status hmath_special_normal_c_d_f_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_normal_c_d_f_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_normal_quantile_f64(
    double p,
    double *out0);
hmath_status hmath_special_normal_quantile_f64(
    hmath_context *context,
    double p,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_normal_quantile_f64(p, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_inverse_erf_f64(
    double x,
    double *out0);
hmath_status hmath_special_inverse_erf_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_inverse_erf_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_dawson_f64(
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_dawson_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_dawson_f64(x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_exponential_integral_f64(
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_exponential_integral_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_exponential_integral_f64(n, x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_logarithmic_integral_f64(
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_logarithmic_integral_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_logarithmic_integral_f64(x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_sine_integral_f64(
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_sine_integral_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_sine_integral_f64(x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_cosine_integral_f64(
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_cosine_integral_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_cosine_integral_f64(x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_fresnel_f64(
    double x,
    double *out0,
    double *out1,
    double *out2,
    double *out3);
hmath_status hmath_special_fresnel_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1,
    double *out2,
    double *out3) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out3)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_fresnel_f64(x, out0, out1, out2, out3);
    hm_leave();
    return status;
}
extern int hm_numeric_special_elliptic_f_f64(
    double phi,
    double m,
    double *out0,
    double *out1);
hmath_status hmath_special_elliptic_f_f64(
    hmath_context *context,
    double phi,
    double m,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_elliptic_f_f64(phi, m, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_elliptic_e_f64(
    double phi,
    double m,
    double *out0,
    double *out1);
hmath_status hmath_special_elliptic_e_f64(
    hmath_context *context,
    double phi,
    double m,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_elliptic_e_f64(phi, m, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_elliptic_pi_f64(
    double n,
    double phi,
    double m,
    double *out0,
    double *out1);
hmath_status hmath_special_elliptic_pi_f64(
    hmath_context *context,
    double n,
    double phi,
    double m,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_elliptic_pi_f64(n, phi, m, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_jacobi_elliptic_f64(
    double u,
    double m,
    double *out0,
    double *out1,
    double *out2);
hmath_status hmath_special_jacobi_elliptic_f64(
    hmath_context *context,
    double u,
    double m,
    double *out0,
    double *out1,
    double *out2) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_jacobi_elliptic_f64(u, m, out0, out1, out2);
    hm_leave();
    return status;
}
extern int hm_numeric_special_bessel_j_f64(
    ptrdiff_t n,
    double x,
    double *out0);
hmath_status hmath_special_bessel_j_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_bessel_j_f64(n, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_bessel_y_f64(
    ptrdiff_t n,
    double x,
    double *out0);
hmath_status hmath_special_bessel_y_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_bessel_y_f64(n, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_bessel_i_f64(
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_bessel_i_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_bessel_i_f64(n, x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_scaled_bessel_i_f64(
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_scaled_bessel_i_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_scaled_bessel_i_f64(n, x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_bessel_k_f64(
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_bessel_k_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_bessel_k_f64(n, x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_scaled_bessel_k_f64(
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_scaled_bessel_k_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_scaled_bessel_k_f64(n, x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_spherical_bessel_j_f64(
    ptrdiff_t n,
    double x,
    double *out0);
hmath_status hmath_special_spherical_bessel_j_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_spherical_bessel_j_f64(n, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_spherical_bessel_y_f64(
    ptrdiff_t n,
    double x,
    double *out0);
hmath_status hmath_special_spherical_bessel_y_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_spherical_bessel_y_f64(n, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_airy_f64(
    double x,
    double *out0,
    double *out1,
    double *out2,
    double *out3,
    double *out4,
    double *out5,
    double *out6,
    double *out7);
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
    double *out7) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out3)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out4)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out5)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out6)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out7)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_airy_f64(x, out0, out1, out2, out3, out4, out5, out6, out7);
    hm_leave();
    return status;
}
extern int hm_numeric_special_struve_f64(
    double nu,
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_struve_f64(
    hmath_context *context,
    double nu,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_struve_f64(nu, x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_hypergeometric_f64(
    const double *as,
    size_t as_count,
    const double *bs,
    size_t bs_count,
    double z,
    double *out0,
    double *out1);
hmath_status hmath_special_hypergeometric_f64(
    hmath_context *context,
    const double *as,
    size_t as_count,
    const double *bs,
    size_t bs_count,
    double z,
    double *out0,
    double *out1) {
    if (as_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (as_count && !as)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (bs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (bs_count && !bs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_hypergeometric_f64(as, as_count, bs, bs_count, z, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_hypergeometric1_f1_f64(
    double a,
    double b,
    double z,
    double *out0,
    double *out1);
hmath_status hmath_special_hypergeometric1_f1_f64(
    hmath_context *context,
    double a,
    double b,
    double z,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_hypergeometric1_f1_f64(a, b, z, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_hypergeometric2_f1_f64(
    double a,
    double b,
    double c,
    double z,
    double *out0,
    double *out1);
hmath_status hmath_special_hypergeometric2_f1_f64(
    hmath_context *context,
    double a,
    double b,
    double c,
    double z,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_hypergeometric2_f1_f64(a, b, c, z, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_legendre_f64(
    ptrdiff_t n,
    double x,
    double *out0);
hmath_status hmath_special_legendre_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_legendre_f64(n, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_associated_legendre_f64(
    ptrdiff_t l,
    ptrdiff_t m,
    double x,
    double *out0);
hmath_status hmath_special_associated_legendre_f64(
    hmath_context *context,
    ptrdiff_t l,
    ptrdiff_t m,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_associated_legendre_f64(l, m, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_hurwitz_zeta_f64(
    double s,
    double q,
    double *out0,
    double *out1);
hmath_status hmath_special_hurwitz_zeta_f64(
    hmath_context *context,
    double s,
    double q,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_hurwitz_zeta_f64(s, q, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_riemann_zeta_f64(
    double s,
    double *out0,
    double *out1);
hmath_status hmath_special_riemann_zeta_f64(
    hmath_context *context,
    double s,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_riemann_zeta_f64(s, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_polylogarithm_f64(
    double s,
    double z,
    double *out0,
    double *out1);
hmath_status hmath_special_polylogarithm_f64(
    hmath_context *context,
    double s,
    double z,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_polylogarithm_f64(s, z, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_dilogarithm_f64(
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_dilogarithm_f64(
    hmath_context *context,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_dilogarithm_f64(x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_lambert_w_f64(
    ptrdiff_t branch,
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_lambert_w_f64(
    hmath_context *context,
    ptrdiff_t branch,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_lambert_w_f64(branch, x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_debye_f64(
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_debye_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_debye_f64(n, x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_clausen_f64(
    double theta,
    double *out0,
    double *out1);
hmath_status hmath_special_clausen_f64(
    hmath_context *context,
    double theta,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_clausen_f64(theta, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_fermi_dirac_f64(
    double order,
    double eta,
    double *out0,
    double *out1);
hmath_status hmath_special_fermi_dirac_f64(
    hmath_context *context,
    double order,
    double eta,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_fermi_dirac_f64(order, eta, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_bose_einstein_f64(
    double order,
    double eta,
    double *out0,
    double *out1);
hmath_status hmath_special_bose_einstein_f64(
    hmath_context *context,
    double order,
    double eta,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_bose_einstein_f64(order, eta, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_coulomb_wave_f64(
    ptrdiff_t l,
    double eta,
    double rho,
    double *out0,
    double *out1,
    double *out2,
    double *out3);
hmath_status hmath_special_coulomb_wave_f64(
    hmath_context *context,
    ptrdiff_t l,
    double eta,
    double rho,
    double *out0,
    double *out1,
    double *out2,
    double *out3) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out3)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_coulomb_wave_f64(l, eta, rho, out0, out1, out2, out3);
    hm_leave();
    return status;
}
extern int hm_numeric_special_gegenbauer_f64(
    ptrdiff_t n,
    double a,
    double x,
    double *out0);
hmath_status hmath_special_gegenbauer_f64(
    hmath_context *context,
    ptrdiff_t n,
    double a,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_gegenbauer_f64(n, a, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_parabolic_cylinder_f64(
    double nu,
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_parabolic_cylinder_f64(
    hmath_context *context,
    double nu,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_parabolic_cylinder_f64(nu, x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_mathieu_f64(
    int evenMode,
    ptrdiff_t n,
    double q,
    double x,
    double *out0,
    double *out1,
    double *out2);
hmath_status hmath_special_mathieu_f64(
    hmath_context *context,
    int evenMode,
    ptrdiff_t n,
    double q,
    double x,
    double *out0,
    double *out1,
    double *out2) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_mathieu_f64(evenMode, n, q, x, out0, out1, out2);
    hm_leave();
    return status;
}
extern int hm_numeric_special_bernoulli_polynomial_f64(
    ptrdiff_t n,
    double x,
    double *out0);
hmath_status hmath_special_bernoulli_polynomial_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_bernoulli_polynomial_f64(n, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_euler_polynomial_f64(
    ptrdiff_t n,
    double x,
    double *out0);
hmath_status hmath_special_euler_polynomial_f64(
    hmath_context *context,
    ptrdiff_t n,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_euler_polynomial_f64(n, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_wigner3j_f64(
    ptrdiff_t j1,
    ptrdiff_t j2,
    ptrdiff_t j3,
    ptrdiff_t m1,
    ptrdiff_t m2,
    ptrdiff_t m3,
    double *out0);
hmath_status hmath_special_wigner3j_f64(
    hmath_context *context,
    ptrdiff_t j1,
    ptrdiff_t j2,
    ptrdiff_t j3,
    ptrdiff_t m1,
    ptrdiff_t m2,
    ptrdiff_t m3,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_wigner3j_f64(j1, j2, j3, m1, m2, m3, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_wigner6j_f64(
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t c,
    ptrdiff_t d,
    ptrdiff_t e,
    ptrdiff_t f,
    double *out0);
hmath_status hmath_special_wigner6j_f64(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t c,
    ptrdiff_t d,
    ptrdiff_t e,
    ptrdiff_t f,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_wigner6j_f64(a, b, c, d, e, f, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_wigner9j_f64(
    ptrdiff_t const *js,
    size_t js_count,
    double *out0);
hmath_status hmath_special_wigner9j_f64(
    hmath_context *context,
    ptrdiff_t const *js,
    size_t js_count,
    double *out0) {
    if (js_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t) || (js_count && !js))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    if (js_count && !js)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_wigner9j_f64(js, js_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_special_clebsch_gordan_f64(
    ptrdiff_t j1,
    ptrdiff_t m1,
    ptrdiff_t j2,
    ptrdiff_t m2,
    ptrdiff_t j,
    ptrdiff_t m,
    double *out0);
hmath_status hmath_special_clebsch_gordan_f64(
    hmath_context *context,
    ptrdiff_t j1,
    ptrdiff_t m1,
    ptrdiff_t j2,
    ptrdiff_t m2,
    ptrdiff_t j,
    ptrdiff_t m,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_clebsch_gordan_f64(j1, m1, j2, m2, j, m, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_complex_to_polar_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_complex_to_polar_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_complex_to_polar_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_probability_gamma_poisson_update_f64(
    double shapePrior,
    double ratePrior,
    ptrdiff_t const *xs,
    size_t xs_count,
    double *out0,
    double *out1);
hmath_status hmath_probability_gamma_poisson_update_f64(
    hmath_context *context,
    double shapePrior,
    double ratePrior,
    ptrdiff_t const *xs,
    size_t xs_count,
    double *out0,
    double *out1) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t) || (xs_count && !xs))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_probability_gamma_poisson_update_f64(shapePrior, ratePrior, xs, xs_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_probability_normal_normal_update_f64(
    double mu,
    double priorVariance,
    double observationVariance,
    const double *xs,
    size_t xs_count,
    double *out0,
    double *out1);
hmath_status hmath_probability_normal_normal_update_f64(
    hmath_context *context,
    double mu,
    double priorVariance,
    double observationVariance,
    const double *xs,
    size_t xs_count,
    double *out0,
    double *out1) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_probability_normal_normal_update_f64(mu, priorVariance, observationVariance, xs, xs_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_probability_conditional_probability_f64(
    double joint,
    double given,
    double *out0);
hmath_status hmath_probability_conditional_probability_f64(
    hmath_context *context,
    double joint,
    double given,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_probability_conditional_probability_f64(joint, given, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_probability_bayes_f64(
    const double *priors,
    size_t priors_count,
    const double *likelihoods,
    size_t likelihoods_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_probability_bayes_f64(
    hmath_context *context,
    const double *priors,
    size_t priors_count,
    const double *likelihoods,
    size_t likelihoods_count,
    double **out_data,
    size_t *out_count) {
    if (priors_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (priors_count && !priors)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (likelihoods_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (likelihoods_count && !likelihoods)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_probability_bayes_f64(priors, priors_count, likelihoods, likelihoods_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_probability_multinomial_p_m_f_f64(
    const double *ps,
    size_t ps_count,
    ptrdiff_t const *counts,
    size_t counts_count,
    double *out0);
hmath_status hmath_probability_multinomial_p_m_f_f64(
    hmath_context *context,
    const double *ps,
    size_t ps_count,
    ptrdiff_t const *counts,
    size_t counts_count,
    double *out0) {
    if (ps_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ps_count && !ps)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (counts_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t) || (counts_count && !counts))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    if (counts_count && !counts)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_probability_multinomial_p_m_f_f64(ps, ps_count, counts, counts_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_probability_dirichlet_density_f64(
    const double *as,
    size_t as_count,
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_probability_dirichlet_density_f64(
    hmath_context *context,
    const double *as,
    size_t as_count,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (as_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (as_count && !as)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_probability_dirichlet_density_f64(as, as_count, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_complex_complex_f64(
    double real,
    double imaginary,
    double *out0,
    double *out1);
hmath_status hmath_complex_complex_f64(
    hmath_context *context,
    double real,
    double imaginary,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_complex_complex_f64(real, imaginary, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_complex_reciprocal_f64(
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_complex_reciprocal_f64(
    hmath_context *context,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_complex_reciprocal_f64(z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_complex_add_f64(
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
hmath_status hmath_complex_add_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_complex_add_f64(a_0, a_1, b_0, b_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_complex_subtract_complex_f64(
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
hmath_status hmath_complex_subtract_complex_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_complex_subtract_complex_f64(a_0, a_1, b_0, b_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_complex_multiply_f64(
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
hmath_status hmath_complex_multiply_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_complex_multiply_f64(a_0, a_1, b_0, b_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_complex_divide_f64(
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
hmath_status hmath_complex_divide_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_complex_divide_f64(a_0, a_1, b_0, b_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_complex_power_f64(
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1);
hmath_status hmath_complex_power_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_complex_power_f64(a_0, a_1, b_0, b_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_complex_from_polar_f64(
    double radius,
    double angle,
    double *out0,
    double *out1);
hmath_status hmath_complex_from_polar_f64(
    hmath_context *context,
    double radius,
    double angle,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_complex_from_polar_f64(radius, angle, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_complex_rotate_f64(
    double angle,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_complex_rotate_f64(
    hmath_context *context,
    double angle,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_complex_rotate_f64(angle, z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_hankel_f64(
    ptrdiff_t kind,
    ptrdiff_t order,
    double x,
    double *out0,
    double *out1);
hmath_status hmath_special_hankel_f64(
    hmath_context *context,
    ptrdiff_t kind,
    ptrdiff_t order,
    double x,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_hankel_f64(kind, order, x, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_spherical_harmonic_f64(
    ptrdiff_t degree,
    ptrdiff_t order,
    double theta,
    double phi,
    double *out0,
    double *out1);
hmath_status hmath_special_spherical_harmonic_f64(
    hmath_context *context,
    ptrdiff_t degree,
    ptrdiff_t order,
    double theta,
    double phi,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_spherical_harmonic_f64(degree, order, theta, phi, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_special_complex1_f1_f64(
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double z_0,
    double z_1,
    double *out0,
    double *out1);
hmath_status hmath_special_complex1_f1_f64(
    hmath_context *context,
    double a_0,
    double a_1,
    double b_0,
    double b_1,
    double z_0,
    double z_1,
    double *out0,
    double *out1) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_special_complex1_f1_f64(a_0, a_1, b_0, b_1, z_0, z_1, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_api_algebra_inner_product_f32(
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float *out0);
hmath_status hmath_api_algebra_inner_product_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    float *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_api_algebra_inner_product_f32(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_api_algebra_inner_product_f64(
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double *out0);
hmath_status hmath_api_algebra_inner_product_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_api_algebra_inner_product_f64(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_lower_bound_f32(
    float x,
    const float *xs,
    size_t xs_count,
    ptrdiff_t *out0);
hmath_status hmath_algorithms_lower_bound_f32(
    hmath_context *context,
    float x,
    const float *xs,
    size_t xs_count,
    ptrdiff_t *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_lower_bound_f32(x, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_lower_bound_f64(
    double x,
    const double *xs,
    size_t xs_count,
    ptrdiff_t *out0);
hmath_status hmath_algorithms_lower_bound_f64(
    hmath_context *context,
    double x,
    const double *xs,
    size_t xs_count,
    ptrdiff_t *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_lower_bound_f64(x, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_upper_bound_f32(
    float x,
    const float *xs,
    size_t xs_count,
    ptrdiff_t *out0);
hmath_status hmath_algorithms_upper_bound_f32(
    hmath_context *context,
    float x,
    const float *xs,
    size_t xs_count,
    ptrdiff_t *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_upper_bound_f32(x, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_upper_bound_f64(
    double x,
    const double *xs,
    size_t xs_count,
    ptrdiff_t *out0);
hmath_status hmath_algorithms_upper_bound_f64(
    hmath_context *context,
    double x,
    const double *xs,
    size_t xs_count,
    ptrdiff_t *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_upper_bound_f64(x, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_quickselect_f32(
    ptrdiff_t k,
    const float *xs,
    size_t xs_count,
    float *out0);
hmath_status hmath_algorithms_quickselect_f32(
    hmath_context *context,
    ptrdiff_t k,
    const float *xs,
    size_t xs_count,
    float *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_quickselect_f32(k, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_quickselect_f64(
    ptrdiff_t k,
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_algorithms_quickselect_f64(
    hmath_context *context,
    ptrdiff_t k,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_quickselect_f64(k, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_introselect_f32(
    ptrdiff_t k,
    const float *xs,
    size_t xs_count,
    float *out0);
hmath_status hmath_algorithms_introselect_f32(
    hmath_context *context,
    ptrdiff_t k,
    const float *xs,
    size_t xs_count,
    float *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_introselect_f32(k, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_introselect_f64(
    ptrdiff_t k,
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_algorithms_introselect_f64(
    hmath_context *context,
    ptrdiff_t k,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_introselect_f64(k, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_partial_sort_f32(
    ptrdiff_t argument1,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_partial_sort_f32(
    hmath_context *context,
    ptrdiff_t argument1,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_partial_sort_f32(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_partial_sort_f64(
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_partial_sort_f64(
    hmath_context *context,
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_partial_sort_f64(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_merge_sort_f32(
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_merge_sort_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_merge_sort_f32(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_merge_sort_f64(
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_merge_sort_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_merge_sort_f64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_quicksort_f32(
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_quicksort_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_quicksort_f32(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_quicksort_f64(
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_quicksort_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_quicksort_f64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_heapsort_f32(
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_heapsort_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_heapsort_f32(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_heapsort_f64(
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_heapsort_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_heapsort_f64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_introsort_f32(
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_introsort_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_introsort_f32(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_introsort_f64(
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_introsort_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_introsort_f64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_counting_sort(
    ptrdiff_t budget,
    ptrdiff_t const *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_counting_sort(
    hmath_context *context,
    ptrdiff_t budget,
    ptrdiff_t const *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t) || (xs_count && !xs))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_counting_sort(budget, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_radix_sort(
    const char * const *argument1,
    size_t argument1_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_radix_sort(
    hmath_context *context,
    const char * const *argument1,
    size_t argument1_count,
    char * **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (argument1_count && !argument1))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < argument1_count; ++i) if (!hm_decimal(argument1[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_radix_sort(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_bucket_sort_f64(
    ptrdiff_t buckets,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_bucket_sort_f64(
    hmath_context *context,
    ptrdiff_t buckets,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_bucket_sort_f64(buckets, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_argsort_f32(
    const float *argument1,
    size_t argument1_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_argsort_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_argsort_f32(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_argsort_f64(
    const double *argument1,
    size_t argument1_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_argsort_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_argsort_f64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_top_k_f32(
    ptrdiff_t argument1,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_top_k_f32(
    hmath_context *context,
    ptrdiff_t argument1,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_top_k_f32(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_top_k_f64(
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_top_k_f64(
    hmath_context *context,
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_top_k_f64(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_quantile_select_f64(
    double q,
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_algorithms_quantile_select_f64(
    hmath_context *context,
    double q,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_quantile_select_f64(q, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_deduplicate_f32(
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_deduplicate_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_deduplicate_f32(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_deduplicate_f64(
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_deduplicate_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_deduplicate_f64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_prefix_sums_f32(
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_prefix_sums_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_prefix_sums_f32(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_prefix_sums_f64(
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_prefix_sums_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_prefix_sums_f64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_suffix_sums_f32(
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_suffix_sums_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_suffix_sums_f32(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_suffix_sums_f64(
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_suffix_sums_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_suffix_sums_f64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_difference_array_f32(
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_difference_array_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_difference_array_f32(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_difference_array_f64(
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_difference_array_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_difference_array_f64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_apply_differences_f32(
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_apply_differences_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_apply_differences_f32(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_apply_differences_f64(
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_apply_differences_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_apply_differences_f64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_binary_lift(
    ptrdiff_t const *next,
    size_t next_count,
    const char *steps,
    ptrdiff_t start,
    ptrdiff_t *out0);
hmath_status hmath_algorithms_binary_lift(
    hmath_context *context,
    ptrdiff_t const *next,
    size_t next_count,
    const char *steps,
    ptrdiff_t start,
    ptrdiff_t *out0) {
    if (next_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t) || (next_count && !next))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    if (next_count && !next)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!hm_decimal(steps))
        return hm_error(HMATH_INVALID_ARGUMENT, "steps: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_binary_lift(next, next_count, steps, start, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_polynomial_hash(
    const char *base,
    const char *modulus,
    const char * const *xs,
    size_t xs_count,
    char **out0);
hmath_status hmath_algorithms_polynomial_hash(
    hmath_context *context,
    const char *base,
    const char *modulus,
    const char * const *xs,
    size_t xs_count,
    char **out0) {
    if (!hm_decimal(base))
        return hm_error(HMATH_INVALID_ARGUMENT, "base: expected signed decimal Integer");
    if (!hm_decimal(modulus))
        return hm_error(HMATH_INVALID_ARGUMENT, "modulus: expected signed decimal Integer");
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (xs_count && !xs))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < xs_count; ++i) if (!hm_decimal(xs[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_polynomial_hash(base, modulus, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_algorithms_rolling_hashes(
    const char *base,
    const char *modulus,
    ptrdiff_t width,
    const char * const *xs,
    size_t xs_count,
    char * **out_data,
    size_t *out_count);
hmath_status hmath_algorithms_rolling_hashes(
    hmath_context *context,
    const char *base,
    const char *modulus,
    ptrdiff_t width,
    const char * const *xs,
    size_t xs_count,
    char * **out_data,
    size_t *out_count) {
    if (!hm_decimal(base))
        return hm_error(HMATH_INVALID_ARGUMENT, "base: expected signed decimal Integer");
    if (!hm_decimal(modulus))
        return hm_error(HMATH_INVALID_ARGUMENT, "modulus: expected signed decimal Integer");
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(const char *) || (xs_count && !xs))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    for (size_t i = 0; i < xs_count; ++i) if (!hm_decimal(xs[i])) return hm_error(HMATH_INVALID_ARGUMENT, "invalid Integer list element");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_algorithms_rolling_hashes(base, modulus, width, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_datastructure_monotonic_minima_f32(
    ptrdiff_t argument1,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_datastructure_monotonic_minima_f32(
    hmath_context *context,
    ptrdiff_t argument1,
    const float *argument2,
    size_t argument2_count,
    float **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_datastructure_monotonic_minima_f32(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_datastructure_monotonic_minima_f64(
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_datastructure_monotonic_minima_f64(
    hmath_context *context,
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_datastructure_monotonic_minima_f64(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_core_log_softmax_f64(
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_deeplearning_core_log_softmax_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_core_log_softmax_f64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_core_softmax_f64(
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_deeplearning_core_softmax_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_core_softmax_f64(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_core_sparsemax_f64(
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_deeplearning_core_sparsemax_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_core_sparsemax_f64(argument1, argument1_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_core_gated_linear_unit_f64(
    const double *values,
    size_t values_count,
    const double *gate,
    size_t gate_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_deeplearning_core_gated_linear_unit_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    const double *gate,
    size_t gate_count,
    double **out_data,
    size_t *out_count) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (gate_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (gate_count && !gate)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_core_gated_linear_unit_f64(values, values_count, gate, gate_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_core_categorical_cross_entropy_logits_f64(
    const double *target,
    size_t target_count,
    const double *logits,
    size_t logits_count,
    double *out0);
hmath_status hmath_deeplearning_core_categorical_cross_entropy_logits_f64(
    hmath_context *context,
    const double *target,
    size_t target_count,
    const double *logits,
    size_t logits_count,
    double *out0) {
    if (target_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (target_count && !target)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (logits_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (logits_count && !logits)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_core_categorical_cross_entropy_logits_f64(target, target_count, logits, logits_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_core_regularization_f64(
    double l1,
    double l2,
    const double *weights,
    size_t weights_count,
    double *out0);
hmath_status hmath_deeplearning_core_regularization_f64(
    hmath_context *context,
    double l1,
    double l2,
    const double *weights,
    size_t weights_count,
    double *out0) {
    if (weights_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (weights_count && !weights)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_core_regularization_f64(l1, l2, weights, weights_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_core_contrastive_loss_f64(
    double margin,
    int similar,
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double *out0);
hmath_status hmath_deeplearning_core_contrastive_loss_f64(
    hmath_context *context,
    double margin,
    int similar,
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double *out0) {
    if (a_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (a_count && !a)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (b_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (b_count && !b)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_core_contrastive_loss_f64(margin, similar, a, a_count, b, b_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_core_triplet_loss_f64(
    double margin,
    const double *anchor,
    size_t anchor_count,
    const double *positive,
    size_t positive_count,
    const double *negative,
    size_t negative_count,
    double *out0);
hmath_status hmath_deeplearning_core_triplet_loss_f64(
    hmath_context *context,
    double margin,
    const double *anchor,
    size_t anchor_count,
    const double *positive,
    size_t positive_count,
    const double *negative,
    size_t negative_count,
    double *out0) {
    if (anchor_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (anchor_count && !anchor)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (positive_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (positive_count && !positive)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (negative_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (negative_count && !negative)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_core_triplet_loss_f64(margin, anchor, anchor_count, positive, positive_count, negative, negative_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_core_focal_loss_f64(
    double alpha,
    double gamma,
    const double *target,
    size_t target_count,
    const double *prediction,
    size_t prediction_count,
    double *out0);
hmath_status hmath_deeplearning_core_focal_loss_f64(
    hmath_context *context,
    double alpha,
    double gamma,
    const double *target,
    size_t target_count,
    const double *prediction,
    size_t prediction_count,
    double *out0) {
    if (target_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (target_count && !target)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (prediction_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (prediction_count && !prediction)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_core_focal_loss_f64(alpha, gamma, target, target_count, prediction, prediction_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_core_dice_loss_f64(
    double smooth,
    const double *target,
    size_t target_count,
    const double *prediction,
    size_t prediction_count,
    double *out0);
hmath_status hmath_deeplearning_core_dice_loss_f64(
    hmath_context *context,
    double smooth,
    const double *target,
    size_t target_count,
    const double *prediction,
    size_t prediction_count,
    double *out0) {
    if (target_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (target_count && !target)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (prediction_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (prediction_count && !prediction)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_core_dice_loss_f64(smooth, target, target_count, prediction, prediction_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_core_iou_loss_f64(
    double smooth,
    const double *target,
    size_t target_count,
    const double *prediction,
    size_t prediction_count,
    double *out0);
hmath_status hmath_deeplearning_core_iou_loss_f64(
    hmath_context *context,
    double smooth,
    const double *target,
    size_t target_count,
    const double *prediction,
    size_t prediction_count,
    double *out0) {
    if (target_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (target_count && !target)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (prediction_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (prediction_count && !prediction)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_core_iou_loss_f64(smooth, target, target_count, prediction, prediction_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_metrics_perplexity_f64(
    const double *logs,
    size_t logs_count,
    double *out0);
hmath_status hmath_deeplearning_metrics_perplexity_f64(
    hmath_context *context,
    const double *logs,
    size_t logs_count,
    double *out0) {
    if (logs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (logs_count && !logs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_metrics_perplexity_f64(logs, logs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_metrics_margin_ranking_loss_f64(
    double margin,
    const double *labels,
    size_t labels_count,
    const double *left,
    size_t left_count,
    const double *right,
    size_t right_count,
    double *out0);
hmath_status hmath_deeplearning_metrics_margin_ranking_loss_f64(
    hmath_context *context,
    double margin,
    const double *labels,
    size_t labels_count,
    const double *left,
    size_t left_count,
    const double *right,
    size_t right_count,
    double *out0) {
    if (labels_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (labels_count && !labels)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (left_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (left_count && !left)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (right_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (right_count && !right)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_metrics_margin_ranking_loss_f64(margin, labels, labels_count, left, left_count, right, right_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_precision_gradient_norm_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_deeplearning_precision_gradient_norm_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_precision_gradient_norm_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_deeplearning_precision_clip_gradients_f64(
    double argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_deeplearning_precision_clip_gradients_f64(
    hmath_context *context,
    double argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_deeplearning_precision_clip_gradients_f64(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_discrete_set_union_f32(
    const float *a,
    size_t a_count,
    const float *b,
    size_t b_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_discrete_set_union_f32(
    hmath_context *context,
    const float *a,
    size_t a_count,
    const float *b,
    size_t b_count,
    float **out_data,
    size_t *out_count) {
    if (a_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (a_count && !a)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (b_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (b_count && !b)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_discrete_set_union_f32(a, a_count, b, b_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_discrete_set_union_f64(
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_discrete_set_union_f64(
    hmath_context *context,
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double **out_data,
    size_t *out_count) {
    if (a_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (a_count && !a)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (b_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (b_count && !b)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_discrete_set_union_f64(a, a_count, b, b_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_discrete_set_intersection_f32(
    const float *a,
    size_t a_count,
    const float *b,
    size_t b_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_discrete_set_intersection_f32(
    hmath_context *context,
    const float *a,
    size_t a_count,
    const float *b,
    size_t b_count,
    float **out_data,
    size_t *out_count) {
    if (a_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (a_count && !a)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (b_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (b_count && !b)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_discrete_set_intersection_f32(a, a_count, b, b_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_discrete_set_intersection_f64(
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_discrete_set_intersection_f64(
    hmath_context *context,
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double **out_data,
    size_t *out_count) {
    if (a_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (a_count && !a)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (b_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (b_count && !b)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_discrete_set_intersection_f64(a, a_count, b, b_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_discrete_set_difference_f32(
    const float *a,
    size_t a_count,
    const float *b,
    size_t b_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_discrete_set_difference_f32(
    hmath_context *context,
    const float *a,
    size_t a_count,
    const float *b,
    size_t b_count,
    float **out_data,
    size_t *out_count) {
    if (a_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (a_count && !a)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (b_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (b_count && !b)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_discrete_set_difference_f32(a, a_count, b, b_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_discrete_set_difference_f64(
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_discrete_set_difference_f64(
    hmath_context *context,
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double **out_data,
    size_t *out_count) {
    if (a_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (a_count && !a)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (b_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (b_count && !b)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_discrete_set_difference_f64(a, a_count, b, b_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_discrete_symmetric_difference_f32(
    const float *a,
    size_t a_count,
    const float *b,
    size_t b_count,
    float **out_data,
    size_t *out_count);
hmath_status hmath_discrete_symmetric_difference_f32(
    hmath_context *context,
    const float *a,
    size_t a_count,
    const float *b,
    size_t b_count,
    float **out_data,
    size_t *out_count) {
    if (a_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (a_count && !a)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (b_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (b_count && !b)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_discrete_symmetric_difference_f32(a, a_count, b, b_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_discrete_symmetric_difference_f64(
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_discrete_symmetric_difference_f64(
    hmath_context *context,
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double **out_data,
    size_t *out_count) {
    if (a_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (a_count && !a)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (b_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (b_count && !b)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_discrete_symmetric_difference_f64(a, a_count, b, b_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_fourier_frequencies_f64(
    ptrdiff_t n,
    double spacing,
    double **out_data,
    size_t *out_count);
hmath_status hmath_fourier_frequencies_f64(
    hmath_context *context,
    ptrdiff_t n,
    double spacing,
    double **out_data,
    size_t *out_count) {
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_fourier_frequencies_f64(n, spacing, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_fourier_fft_shift_f64(
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_fourier_fft_shift_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_fourier_fft_shift_f64(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_fourier_ifft_shift_f64(
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_fourier_ifft_shift_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_fourier_ifft_shift_f64(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_fourier_hartley_f64(
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_fourier_hartley_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_fourier_hartley_f64(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_fourier_periodogram_f64(
    double rate,
    const double *window,
    size_t window_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_fourier_periodogram_f64(
    hmath_context *context,
    double rate,
    const double *window,
    size_t window_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (window_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (window_count && !window)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_fourier_periodogram_f64(rate, window, window_count, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_fourier_welch_f64(
    double rate,
    const double *window,
    size_t window_count,
    ptrdiff_t hop,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_fourier_welch_f64(
    hmath_context *context,
    double rate,
    const double *window,
    size_t window_count,
    ptrdiff_t hop,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (window_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (window_count && !window)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_fourier_welch_f64(rate, window, window_count, hop, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_fourier_cepstrum_f64(
    double floorValue,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_fourier_cepstrum_f64(
    hmath_context *context,
    double floorValue,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_fourier_cepstrum_f64(floorValue, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_fourier_hilbert_f64(
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_fourier_hilbert_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_fourier_hilbert_f64(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_geometry_primitives_hamming_distance_f32(
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    ptrdiff_t *out0);
hmath_status hmath_geometry_primitives_hamming_distance_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    const float *argument2,
    size_t argument2_count,
    ptrdiff_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_geometry_primitives_hamming_distance_f32(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_geometry_primitives_hamming_distance_f64(
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    ptrdiff_t *out0);
hmath_status hmath_geometry_primitives_hamming_distance_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    ptrdiff_t *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_geometry_primitives_hamming_distance_f64(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_geometry_primitives_jaccard_distance_f64(
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double *out0);
hmath_status hmath_geometry_primitives_jaccard_distance_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_geometry_primitives_jaccard_distance_f64(argument1, argument1_count, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_graph_core_finite_f64(
    double x,
    int *out0);
hmath_status hmath_graph_core_finite_f64(
    hmath_context *context,
    double x,
    int *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_graph_core_finite_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_image_color_srgb_to_linear_f64(
    double x,
    double *out0);
hmath_status hmath_image_color_srgb_to_linear_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_image_color_srgb_to_linear_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_image_color_linear_to_srgb_f64(
    double x,
    double *out0);
hmath_status hmath_image_color_linear_to_srgb_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_image_color_linear_to_srgb_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_interpolation_evaluate_chebyshev_f64(
    const double *cs,
    size_t cs_count,
    double a,
    double b,
    double x,
    double *out0);
hmath_status hmath_interpolation_evaluate_chebyshev_f64(
    hmath_context *context,
    const double *cs,
    size_t cs_count,
    double a,
    double b,
    double x,
    double *out0) {
    if (cs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (cs_count && !cs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_interpolation_evaluate_chebyshev_f64(cs, cs_count, a, b, x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_next_after_f32(
    float argument1,
    float argument2,
    float *out0);
hmath_status hmath_numeric_next_after_f32(
    hmath_context *context,
    float argument1,
    float argument2,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_next_after_f32(argument1, argument2, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_next_after_f64(
    double argument1,
    double argument2,
    double *out0);
hmath_status hmath_numeric_next_after_f64(
    hmath_context *context,
    double argument1,
    double argument2,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_next_after_f64(argument1, argument2, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_ldexp_f32(
    float argument1,
    ptrdiff_t argument2,
    float *out0);
hmath_status hmath_numeric_ldexp_f32(
    hmath_context *context,
    float argument1,
    ptrdiff_t argument2,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_ldexp_f32(argument1, argument2, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_ldexp_f64(
    double argument1,
    ptrdiff_t argument2,
    double *out0);
hmath_status hmath_numeric_ldexp_f64(
    hmath_context *context,
    double argument1,
    ptrdiff_t argument2,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_ldexp_f64(argument1, argument2, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_ulp_distance_f64(
    double a,
    double b,
    char **out0);
hmath_status hmath_numeric_ulp_distance_f64(
    hmath_context *context,
    double a,
    double b,
    char **out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_ulp_distance_f64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_within_u_l_ps_f64(
    const char *n,
    double a,
    double b,
    int *out0);
hmath_status hmath_numeric_within_u_l_ps_f64(
    hmath_context *context,
    const char *n,
    double a,
    double b,
    int *out0) {
    if (!hm_decimal(n))
        return hm_error(HMATH_INVALID_ARGUMENT, "n: expected signed decimal Integer");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_within_u_l_ps_f64(n, a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_kahan_sum_f32(
    const float *argument1,
    size_t argument1_count,
    float *out0);
hmath_status hmath_numeric_kahan_sum_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_kahan_sum_f32(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_kahan_sum_f64(
    const double *argument1,
    size_t argument1_count,
    double *out0);
hmath_status hmath_numeric_kahan_sum_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_kahan_sum_f64(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_neumaier_sum_f32(
    const float *argument1,
    size_t argument1_count,
    float *out0);
hmath_status hmath_numeric_neumaier_sum_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_neumaier_sum_f32(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_neumaier_sum_f64(
    const double *argument1,
    size_t argument1_count,
    double *out0);
hmath_status hmath_numeric_neumaier_sum_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_neumaier_sum_f64(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_pairwise_sum_f32(
    const float *argument1,
    size_t argument1_count,
    float *out0);
hmath_status hmath_numeric_pairwise_sum_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_pairwise_sum_f32(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_pairwise_sum_f64(
    const double *argument1,
    size_t argument1_count,
    double *out0);
hmath_status hmath_numeric_pairwise_sum_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_pairwise_sum_f64(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_logsumexp_f32(
    const float *argument1,
    size_t argument1_count,
    float *out0);
hmath_status hmath_numeric_logsumexp_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_logsumexp_f32(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_logsumexp_f64(
    const double *argument1,
    size_t argument1_count,
    double *out0);
hmath_status hmath_numeric_logsumexp_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_logsumexp_f64(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_sum_error_bound_f32(
    const float *argument1,
    size_t argument1_count,
    float *out0);
hmath_status hmath_numeric_sum_error_bound_f32(
    hmath_context *context,
    const float *argument1,
    size_t argument1_count,
    float *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(float))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_sum_error_bound_f32(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_numeric_sum_error_bound_f64(
    const double *argument1,
    size_t argument1_count,
    double *out0);
hmath_status hmath_numeric_sum_error_bound_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_numeric_sum_error_bound_f64(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_optimization_common_dot_f64(
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double *out0);
hmath_status hmath_optimization_common_dot_f64(
    hmath_context *context,
    const double *a,
    size_t a_count,
    const double *b,
    size_t b_count,
    double *out0) {
    if (a_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (a_count && !a)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (b_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (b_count && !b)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_optimization_common_dot_f64(a, a_count, b, b_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_optimization_common_norm_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_optimization_common_norm_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_optimization_common_norm_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_optimization_common_add_f64(
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_optimization_common_add_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_optimization_common_add_f64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_optimization_common_sub_f64(
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_optimization_common_sub_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_optimization_common_sub_f64(argument1, argument1_count, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_optimization_common_scale_f64(
    double argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_optimization_common_scale_f64(
    hmath_context *context,
    double argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_optimization_common_scale_f64(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_random_importance_f64(
    const double *values,
    size_t values_count,
    const double *weights,
    size_t weights_count,
    double *out0);
hmath_status hmath_random_importance_f64(
    hmath_context *context,
    const double *values,
    size_t values_count,
    const double *weights,
    size_t weights_count,
    double *out0) {
    if (values_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (values_count && !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (weights_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (weights_count && !weights)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_random_importance_f64(values, values_count, weights, weights_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_random_halton_f64(
    ptrdiff_t dimension,
    ptrdiff_t index,
    double **out_data,
    size_t *out_count);
hmath_status hmath_random_halton_f64(
    hmath_context *context,
    ptrdiff_t dimension,
    ptrdiff_t index,
    double **out_data,
    size_t *out_count) {
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_random_halton_f64(dimension, index, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_random_sobol_f64(
    ptrdiff_t dimension,
    ptrdiff_t index,
    double **out_data,
    size_t *out_count);
hmath_status hmath_random_sobol_f64(
    hmath_context *context,
    ptrdiff_t dimension,
    ptrdiff_t index,
    double **out_data,
    size_t *out_count) {
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_random_sobol_f64(dimension, index, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_random_faure_f64(
    ptrdiff_t d,
    ptrdiff_t ix,
    double **out_data,
    size_t *out_count);
hmath_status hmath_random_faure_f64(
    hmath_context *context,
    ptrdiff_t d,
    ptrdiff_t ix,
    double **out_data,
    size_t *out_count) {
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_random_faure_f64(d, ix, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_convolution_f64(
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_convolution_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (ys_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ys_count && !ys)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_convolution_f64(xs, xs_count, ys, ys_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_circular_convolution_f64(
    const double *x,
    size_t x_count,
    const double *y,
    size_t y_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_circular_convolution_f64(
    hmath_context *context,
    const double *x,
    size_t x_count,
    const double *y,
    size_t y_count,
    double **out_data,
    size_t *out_count) {
    if (x_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (x_count && !x)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (y_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (y_count && !y)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_circular_convolution_f64(x, x_count, y, y_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_correlation_f64(
    const double *x,
    size_t x_count,
    const double *y,
    size_t y_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_correlation_f64(
    hmath_context *context,
    const double *x,
    size_t x_count,
    const double *y,
    size_t y_count,
    double **out_data,
    size_t *out_count) {
    if (x_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (x_count && !x)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (y_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (y_count && !y)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_correlation_f64(x, x_count, y, y_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_autocorrelation_f64(
    const double *x,
    size_t x_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_autocorrelation_f64(
    hmath_context *context,
    const double *x,
    size_t x_count,
    double **out_data,
    size_t *out_count) {
    if (x_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (x_count && !x)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_autocorrelation_f64(x, x_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_overlap_add_f64(
    ptrdiff_t block,
    const double *kernel,
    size_t kernel_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_overlap_add_f64(
    hmath_context *context,
    ptrdiff_t block,
    const double *kernel,
    size_t kernel_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (kernel_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (kernel_count && !kernel)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_overlap_add_f64(block, kernel, kernel_count, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_overlap_save_f64(
    ptrdiff_t fftLength,
    const double *kernel,
    size_t kernel_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_overlap_save_f64(
    hmath_context *context,
    ptrdiff_t fftLength,
    const double *kernel,
    size_t kernel_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (kernel_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (kernel_count && !kernel)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_overlap_save_f64(fftLength, kernel, kernel_count, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_moving_average_f64(
    ptrdiff_t count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_moving_average_f64(
    hmath_context *context,
    ptrdiff_t count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_moving_average_f64(count, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_median_filter_f64(
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_median_filter_f64(
    hmath_context *context,
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_median_filter_f64(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_gaussian_filter_f64(
    ptrdiff_t width,
    double sigma,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_gaussian_filter_f64(
    hmath_context *context,
    ptrdiff_t width,
    double sigma,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_gaussian_filter_f64(width, sigma, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_savitzky_golay_f64(
    ptrdiff_t width,
    ptrdiff_t degree,
    ptrdiff_t derivative,
    double spacing,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_savitzky_golay_f64(
    hmath_context *context,
    ptrdiff_t width,
    ptrdiff_t degree,
    ptrdiff_t derivative,
    double spacing,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_savitzky_golay_f64(width, degree, derivative, spacing, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_downsample_f64(
    ptrdiff_t factor,
    ptrdiff_t offset,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_downsample_f64(
    hmath_context *context,
    ptrdiff_t factor,
    ptrdiff_t offset,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_downsample_f64(factor, offset, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_upsample_f64(
    ptrdiff_t factor,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_upsample_f64(
    hmath_context *context,
    ptrdiff_t factor,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_upsample_f64(factor, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_resample_polyphase_f64(
    ptrdiff_t up,
    ptrdiff_t down,
    const double *kernel,
    size_t kernel_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_resample_polyphase_f64(
    hmath_context *context,
    ptrdiff_t up,
    ptrdiff_t down,
    const double *kernel,
    size_t kernel_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (kernel_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (kernel_count && !kernel)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_resample_polyphase_f64(up, down, kernel, kernel_count, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_resample_f64(
    ptrdiff_t up,
    ptrdiff_t down,
    ptrdiff_t taps,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_resample_f64(
    hmath_context *context,
    ptrdiff_t up,
    ptrdiff_t down,
    ptrdiff_t taps,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_resample_f64(up, down, taps, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_anti_alias_f64(
    ptrdiff_t factor,
    ptrdiff_t taps,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_anti_alias_f64(
    hmath_context *context,
    ptrdiff_t factor,
    ptrdiff_t taps,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_anti_alias_f64(factor, taps, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_zero_crossings_f64(
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_zero_crossings_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_zero_crossings_f64(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_envelope_f64(
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_envelope_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_envelope_f64(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_unwrap_phase_f64(
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_unwrap_phase_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_unwrap_phase_f64(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_detrend_f64(
    int linear,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_detrend_f64(
    hmath_context *context,
    int linear,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_detrend_f64(linear, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_normalize_f64(
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_normalize_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_normalize_f64(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_smooth_f64(
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_signal_smooth_f64(
    hmath_context *context,
    ptrdiff_t argument1,
    const double *argument2,
    size_t argument2_count,
    double **out_data,
    size_t *out_count) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_smooth_f64(argument1, argument2, argument2_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_noise_estimate_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_signal_noise_estimate_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_noise_estimate_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_signal_to_noise_f64(
    const double *signal,
    size_t signal_count,
    const double *noise,
    size_t noise_count,
    double *out0);
hmath_status hmath_signal_signal_to_noise_f64(
    hmath_context *context,
    const double *signal,
    size_t signal_count,
    const double *noise,
    size_t noise_count,
    double *out0) {
    if (signal_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (signal_count && !signal)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (noise_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (noise_count && !noise)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_signal_to_noise_f64(signal, signal_count, noise, noise_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_signal_rms_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_signal_rms_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_signal_rms_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_arithmetic_mean_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_arithmetic_mean_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_arithmetic_mean_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_weighted_mean_f64(
    const double *xs,
    size_t xs_count,
    const double *ws,
    size_t ws_count,
    double *out0);
hmath_status hmath_statistics_advanced_weighted_mean_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    const double *ws,
    size_t ws_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (ws_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ws_count && !ws)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_weighted_mean_f64(xs, xs_count, ws, ws_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_geometric_mean_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_geometric_mean_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_geometric_mean_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_harmonic_mean_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_harmonic_mean_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_harmonic_mean_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_rms_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_rms_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_rms_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_trimmed_mean_f64(
    double fraction,
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_trimmed_mean_f64(
    hmath_context *context,
    double fraction,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_trimmed_mean_f64(fraction, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_winsorized_mean_f64(
    double fraction,
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_winsorized_mean_f64(
    hmath_context *context,
    double fraction,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_winsorized_mean_f64(fraction, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_quantile_f64(
    double p,
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_quantile_f64(
    hmath_context *context,
    double p,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_quantile_f64(p, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_median_f64(
    const double *argument1,
    size_t argument1_count,
    double *out0);
hmath_status hmath_statistics_advanced_median_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_median_f64(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_percentile_f64(
    double argument1,
    const double *argument2,
    size_t argument2_count,
    double *out0);
hmath_status hmath_statistics_advanced_percentile_f64(
    hmath_context *context,
    double argument1,
    const double *argument2,
    size_t argument2_count,
    double *out0) {
    if (argument2_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument2_count && !argument2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_percentile_f64(argument1, argument2, argument2_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_modes_f64(
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_statistics_advanced_modes_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_modes_f64(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_interquartile_range_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_interquartile_range_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_interquartile_range_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_median_absolute_deviation_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_median_absolute_deviation_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_median_absolute_deviation_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_data_range_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_data_range_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_data_range_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_central_moment_f64(
    ptrdiff_t k,
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_central_moment_f64(
    hmath_context *context,
    ptrdiff_t k,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_central_moment_f64(k, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_population_variance_f64(
    const double *argument1,
    size_t argument1_count,
    double *out0);
hmath_status hmath_statistics_advanced_population_variance_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_population_variance_f64(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_sample_variance_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_sample_variance_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_sample_variance_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_population_s_d_f64(
    const double *argument1,
    size_t argument1_count,
    double *out0);
hmath_status hmath_statistics_advanced_population_s_d_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_population_s_d_f64(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_sample_s_d_f64(
    const double *argument1,
    size_t argument1_count,
    double *out0);
hmath_status hmath_statistics_advanced_sample_s_d_f64(
    hmath_context *context,
    const double *argument1,
    size_t argument1_count,
    double *out0) {
    if (argument1_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (argument1_count && !argument1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_sample_s_d_f64(argument1, argument1_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_coefficient_of_variation_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_coefficient_of_variation_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_coefficient_of_variation_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_skewness_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_skewness_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_skewness_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_kurtosis_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_kurtosis_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_kurtosis_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_covariance_f64(
    int sampleCorrection,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
hmath_status hmath_statistics_advanced_covariance_f64(
    hmath_context *context,
    int sampleCorrection,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (ys_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ys_count && !ys)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_covariance_f64(sampleCorrection, xs, xs_count, ys, ys_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_correlation_f64(
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
hmath_status hmath_statistics_advanced_correlation_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (ys_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ys_count && !ys)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_correlation_f64(xs, xs_count, ys, ys_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_spearman_f64(
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
hmath_status hmath_statistics_advanced_spearman_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (ys_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ys_count && !ys)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_spearman_f64(xs, xs_count, ys, ys_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_kendall_f64(
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
hmath_status hmath_statistics_advanced_kendall_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (ys_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ys_count && !ys)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_kendall_f64(xs, xs_count, ys, ys_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_autocorrelation_f64(
    ptrdiff_t lag,
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_autocorrelation_f64(
    hmath_context *context,
    ptrdiff_t lag,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_autocorrelation_f64(lag, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_cross_correlation_f64(
    ptrdiff_t lag,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
hmath_status hmath_statistics_advanced_cross_correlation_f64(
    hmath_context *context,
    ptrdiff_t lag,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (ys_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ys_count && !ys)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_cross_correlation_f64(lag, xs, xs_count, ys, ys_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_moving_average_f64(
    ptrdiff_t window,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_statistics_advanced_moving_average_f64(
    hmath_context *context,
    ptrdiff_t window,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_moving_average_f64(window, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_moving_variance_f64(
    ptrdiff_t window,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_statistics_advanced_moving_variance_f64(
    hmath_context *context,
    ptrdiff_t window,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_moving_variance_f64(window, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_exponential_moving_average_f64(
    double alpha,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_statistics_advanced_exponential_moving_average_f64(
    hmath_context *context,
    double alpha,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_exponential_moving_average_f64(alpha, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_entropy_f64(
    const double *ps,
    size_t ps_count,
    double *out0);
hmath_status hmath_statistics_advanced_entropy_f64(
    hmath_context *context,
    const double *ps,
    size_t ps_count,
    double *out0) {
    if (ps_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ps_count && !ps)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_entropy_f64(ps, ps_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_kl_divergence_f64(
    const double *p,
    size_t p_count,
    const double *q,
    size_t q_count,
    double *out0);
hmath_status hmath_statistics_advanced_kl_divergence_f64(
    hmath_context *context,
    const double *p,
    size_t p_count,
    const double *q,
    size_t q_count,
    double *out0) {
    if (p_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (p_count && !p)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (q_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (q_count && !q)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_kl_divergence_f64(p, p_count, q, q_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_js_divergence_f64(
    const double *p,
    size_t p_count,
    const double *q,
    size_t q_count,
    double *out0);
hmath_status hmath_statistics_advanced_js_divergence_f64(
    hmath_context *context,
    const double *p,
    size_t p_count,
    const double *q,
    size_t q_count,
    double *out0) {
    if (p_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (p_count && !p)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (q_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (q_count && !q)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_js_divergence_f64(p, p_count, q, q_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_z_scores_f64(
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_statistics_advanced_z_scores_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_z_scores_f64(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_standard_error_f64(
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_standard_error_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_standard_error_f64(xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_confidence_interval_f64(
    double level,
    const double *xs,
    size_t xs_count,
    double *out0,
    double *out1);
hmath_status hmath_statistics_advanced_confidence_interval_f64(
    hmath_context *context,
    double level,
    const double *xs,
    size_t xs_count,
    double *out0,
    double *out1) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    if (!out1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_confidence_interval_f64(level, xs, xs_count, out0, out1);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_bonferroni_f64(
    const double *ps,
    size_t ps_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_statistics_advanced_bonferroni_f64(
    hmath_context *context,
    const double *ps,
    size_t ps_count,
    double **out_data,
    size_t *out_count) {
    if (ps_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ps_count && !ps)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_bonferroni_f64(ps, ps_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_benjamini_hochberg_f64(
    const double *ps,
    size_t ps_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_statistics_advanced_benjamini_hochberg_f64(
    hmath_context *context,
    const double *ps,
    size_t ps_count,
    double **out_data,
    size_t *out_count) {
    if (ps_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ps_count && !ps)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_benjamini_hochberg_f64(ps, ps_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_cohens_d_f64(
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
hmath_status hmath_statistics_advanced_cohens_d_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (ys_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ys_count && !ys)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_cohens_d_f64(xs, xs_count, ys, ys_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_normal_test_power_f64(
    double alpha,
    double standardizedEffect,
    ptrdiff_t n,
    double *out0);
hmath_status hmath_statistics_advanced_normal_test_power_f64(
    hmath_context *context,
    double alpha,
    double standardizedEffect,
    ptrdiff_t n,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_normal_test_power_f64(alpha, standardizedEffect, n, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_normal_sample_size_f64(
    double alpha,
    double power,
    double effect,
    ptrdiff_t *out0);
hmath_status hmath_statistics_advanced_normal_sample_size_f64(
    hmath_context *context,
    double alpha,
    double power,
    double effect,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_normal_sample_size_f64(alpha, power, effect, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_tukey_outliers_f64(
    double multiplier,
    const double *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_statistics_advanced_tukey_outliers_f64(
    hmath_context *context,
    double multiplier,
    const double *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_tukey_outliers_f64(multiplier, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_statistics_advanced_huber_location_f64(
    double tuning,
    const double *xs,
    size_t xs_count,
    double *out0);
hmath_status hmath_statistics_advanced_huber_location_f64(
    hmath_context *context,
    double tuning,
    const double *xs,
    size_t xs_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_statistics_advanced_huber_location_f64(tuning, xs, xs_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_tensor_shape_size(
    ptrdiff_t const *dims,
    size_t dims_count,
    ptrdiff_t *out0);
hmath_status hmath_tensor_shape_size(
    hmath_context *context,
    ptrdiff_t const *dims,
    size_t dims_count,
    ptrdiff_t *out0) {
    if (dims_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t) || (dims_count && !dims))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    if (dims_count && !dims)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_tensor_shape_size(dims, dims_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_tensor_infer_broadcast(
    ptrdiff_t const *as,
    size_t as_count,
    ptrdiff_t const *bs,
    size_t bs_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_tensor_infer_broadcast(
    hmath_context *context,
    ptrdiff_t const *as,
    size_t as_count,
    ptrdiff_t const *bs,
    size_t bs_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (as_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t) || (as_count && !as))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    if (as_count && !as)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (bs_count > (size_t)PTRDIFF_MAX / sizeof(ptrdiff_t) || (bs_count && !bs))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid list input span");
    if (bs_count && !bs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_tensor_infer_broadcast(as, as_count, bs, bs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_timeseries_core_exponential_average_f64(
    double alpha,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_timeseries_core_exponential_average_f64(
    hmath_context *context,
    double alpha,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_timeseries_core_exponential_average_f64(alpha, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_timeseries_core_weighted_average_f64(
    const double *ws,
    size_t ws_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_timeseries_core_weighted_average_f64(
    hmath_context *context,
    const double *ws,
    size_t ws_count,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (ws_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ws_count && !ws)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_timeseries_core_weighted_average_f64(ws, ws_count, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_timeseries_core_cumulative_returns_f64(
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_timeseries_core_cumulative_returns_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_timeseries_core_cumulative_returns_f64(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_timeseries_core_logarithmic_returns_f64(
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_timeseries_core_logarithmic_returns_f64(
    hmath_context *context,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_timeseries_core_logarithmic_returns_f64(xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_timeseries_core_difference_f64(
    ptrdiff_t order,
    ptrdiff_t lag,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_timeseries_core_difference_f64(
    hmath_context *context,
    ptrdiff_t order,
    ptrdiff_t lag,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_timeseries_core_difference_f64(order, lag, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_timeseries_core_autocorrelation_f64(
    ptrdiff_t lags,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_timeseries_core_autocorrelation_f64(
    hmath_context *context,
    ptrdiff_t lags,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_timeseries_core_autocorrelation_f64(lags, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_timeseries_core_cross_correlation_f64(
    ptrdiff_t lag,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0);
hmath_status hmath_timeseries_core_cross_correlation_f64(
    hmath_context *context,
    ptrdiff_t lag,
    const double *xs,
    size_t xs_count,
    const double *ys,
    size_t ys_count,
    double *out0) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (ys_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (ys_count && !ys)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_timeseries_core_cross_correlation_f64(lag, xs, xs_count, ys, ys_count, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_timeseries_core_partial_autocorrelation_f64(
    ptrdiff_t order,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count);
hmath_status hmath_timeseries_core_partial_autocorrelation_f64(
    hmath_context *context,
    ptrdiff_t order,
    const double *xs,
    size_t xs_count,
    double **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_timeseries_core_partial_autocorrelation_f64(order, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_timeseries_diagnostics_change_points_f64(
    double penalty,
    ptrdiff_t minSegment,
    const double *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_timeseries_diagnostics_change_points_f64(
    hmath_context *context,
    double penalty,
    ptrdiff_t minSegment,
    const double *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_timeseries_diagnostics_change_points_f64(penalty, minSegment, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_timeseries_diagnostics_cusum_f64(
    double mean,
    double sd,
    double drift,
    double threshold,
    const double *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_timeseries_diagnostics_cusum_f64(
    hmath_context *context,
    double mean,
    double sd,
    double drift,
    double threshold,
    const double *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_timeseries_diagnostics_cusum_f64(mean, sd, drift, threshold, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_timeseries_diagnostics_anomalies_f64(
    double threshold,
    const double *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count);
hmath_status hmath_timeseries_diagnostics_anomalies_f64(
    hmath_context *context,
    double threshold,
    const double *xs,
    size_t xs_count,
    ptrdiff_t **out_data,
    size_t *out_count) {
    if (xs_count > (size_t)PTRDIFF_MAX / sizeof(double))
        return hm_error(HMATH_OVERFLOW, "list byte span exceeds ptrdiff_t");
    if (xs_count && !xs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL list input");
    if (!out_data || !out_count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL dynamic output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_timeseries_diagnostics_anomalies_f64(threshold, xs, xs_count, out_data, out_count);
    hm_leave();
    return status;
}
extern int hm_numeric_units_radians_to_degrees_f32(
    float x,
    float *out0);
hmath_status hmath_units_radians_to_degrees_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_units_radians_to_degrees_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_units_radians_to_degrees_f64(
    double x,
    double *out0);
hmath_status hmath_units_radians_to_degrees_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_units_radians_to_degrees_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_units_degrees_to_radians_f32(
    float x,
    float *out0);
hmath_status hmath_units_degrees_to_radians_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_units_degrees_to_radians_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_units_degrees_to_radians_f64(
    double x,
    double *out0);
hmath_status hmath_units_degrees_to_radians_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_units_degrees_to_radians_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_units_radians_to_gradians_f32(
    float x,
    float *out0);
hmath_status hmath_units_radians_to_gradians_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_units_radians_to_gradians_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_units_radians_to_gradians_f64(
    double x,
    double *out0);
hmath_status hmath_units_radians_to_gradians_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_units_radians_to_gradians_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_units_gradians_to_radians_f32(
    float x,
    float *out0);
hmath_status hmath_units_gradians_to_radians_f32(
    hmath_context *context,
    float x,
    float *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_units_gradians_to_radians_f32(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_units_gradians_to_radians_f64(
    double x,
    double *out0);
hmath_status hmath_units_gradians_to_radians_f64(
    hmath_context *context,
    double x,
    double *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_units_gradians_to_radians_f64(x, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_add_i8(
    int8_t a,
    int8_t b,
    int8_t *out0);
hmath_status hmath_scalar_saturating_add_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_add_i8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_add_i16(
    int16_t a,
    int16_t b,
    int16_t *out0);
hmath_status hmath_scalar_saturating_add_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_add_i16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_add_i32(
    int32_t a,
    int32_t b,
    int32_t *out0);
hmath_status hmath_scalar_saturating_add_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_add_i32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_add_i64(
    int64_t a,
    int64_t b,
    int64_t *out0);
hmath_status hmath_scalar_saturating_add_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_add_i64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_add_u8(
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
hmath_status hmath_scalar_saturating_add_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_add_u8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_add_u16(
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
hmath_status hmath_scalar_saturating_add_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_add_u16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_add_u32(
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
hmath_status hmath_scalar_saturating_add_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_add_u32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_add_u64(
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
hmath_status hmath_scalar_saturating_add_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_add_u64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_add_int(
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
hmath_status hmath_scalar_saturating_add_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_add_int(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_add_word(
    size_t a,
    size_t b,
    size_t *out0);
hmath_status hmath_scalar_saturating_add_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_add_word(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_subtract_i8(
    int8_t a,
    int8_t b,
    int8_t *out0);
hmath_status hmath_scalar_saturating_subtract_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_subtract_i8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_subtract_i16(
    int16_t a,
    int16_t b,
    int16_t *out0);
hmath_status hmath_scalar_saturating_subtract_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_subtract_i16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_subtract_i32(
    int32_t a,
    int32_t b,
    int32_t *out0);
hmath_status hmath_scalar_saturating_subtract_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_subtract_i32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_subtract_i64(
    int64_t a,
    int64_t b,
    int64_t *out0);
hmath_status hmath_scalar_saturating_subtract_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_subtract_i64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_subtract_u8(
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
hmath_status hmath_scalar_saturating_subtract_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_subtract_u8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_subtract_u16(
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
hmath_status hmath_scalar_saturating_subtract_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_subtract_u16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_subtract_u32(
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
hmath_status hmath_scalar_saturating_subtract_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_subtract_u32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_subtract_u64(
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
hmath_status hmath_scalar_saturating_subtract_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_subtract_u64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_subtract_int(
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
hmath_status hmath_scalar_saturating_subtract_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_subtract_int(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_subtract_word(
    size_t a,
    size_t b,
    size_t *out0);
hmath_status hmath_scalar_saturating_subtract_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_subtract_word(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_multiply_i8(
    int8_t a,
    int8_t b,
    int8_t *out0);
hmath_status hmath_scalar_saturating_multiply_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_multiply_i8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_multiply_i16(
    int16_t a,
    int16_t b,
    int16_t *out0);
hmath_status hmath_scalar_saturating_multiply_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_multiply_i16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_multiply_i32(
    int32_t a,
    int32_t b,
    int32_t *out0);
hmath_status hmath_scalar_saturating_multiply_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_multiply_i32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_multiply_i64(
    int64_t a,
    int64_t b,
    int64_t *out0);
hmath_status hmath_scalar_saturating_multiply_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_multiply_i64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_multiply_u8(
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
hmath_status hmath_scalar_saturating_multiply_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_multiply_u8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_multiply_u16(
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
hmath_status hmath_scalar_saturating_multiply_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_multiply_u16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_multiply_u32(
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
hmath_status hmath_scalar_saturating_multiply_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_multiply_u32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_multiply_u64(
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
hmath_status hmath_scalar_saturating_multiply_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_multiply_u64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_multiply_int(
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
hmath_status hmath_scalar_saturating_multiply_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_multiply_int(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_saturating_multiply_word(
    size_t a,
    size_t b,
    size_t *out0);
hmath_status hmath_scalar_saturating_multiply_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_saturating_multiply_word(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_add_i8(
    int8_t a,
    int8_t b,
    int8_t *out0);
hmath_status hmath_scalar_checked_add_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_add_i8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_add_i16(
    int16_t a,
    int16_t b,
    int16_t *out0);
hmath_status hmath_scalar_checked_add_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_add_i16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_add_i32(
    int32_t a,
    int32_t b,
    int32_t *out0);
hmath_status hmath_scalar_checked_add_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_add_i32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_add_i64(
    int64_t a,
    int64_t b,
    int64_t *out0);
hmath_status hmath_scalar_checked_add_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_add_i64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_add_u8(
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
hmath_status hmath_scalar_checked_add_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_add_u8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_add_u16(
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
hmath_status hmath_scalar_checked_add_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_add_u16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_add_u32(
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
hmath_status hmath_scalar_checked_add_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_add_u32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_add_u64(
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
hmath_status hmath_scalar_checked_add_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_add_u64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_add_int(
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
hmath_status hmath_scalar_checked_add_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_add_int(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_add_word(
    size_t a,
    size_t b,
    size_t *out0);
hmath_status hmath_scalar_checked_add_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_add_word(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_subtract_i8(
    int8_t a,
    int8_t b,
    int8_t *out0);
hmath_status hmath_scalar_checked_subtract_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_subtract_i8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_subtract_i16(
    int16_t a,
    int16_t b,
    int16_t *out0);
hmath_status hmath_scalar_checked_subtract_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_subtract_i16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_subtract_i32(
    int32_t a,
    int32_t b,
    int32_t *out0);
hmath_status hmath_scalar_checked_subtract_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_subtract_i32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_subtract_i64(
    int64_t a,
    int64_t b,
    int64_t *out0);
hmath_status hmath_scalar_checked_subtract_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_subtract_i64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_subtract_u8(
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
hmath_status hmath_scalar_checked_subtract_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_subtract_u8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_subtract_u16(
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
hmath_status hmath_scalar_checked_subtract_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_subtract_u16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_subtract_u32(
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
hmath_status hmath_scalar_checked_subtract_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_subtract_u32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_subtract_u64(
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
hmath_status hmath_scalar_checked_subtract_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_subtract_u64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_subtract_int(
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
hmath_status hmath_scalar_checked_subtract_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_subtract_int(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_subtract_word(
    size_t a,
    size_t b,
    size_t *out0);
hmath_status hmath_scalar_checked_subtract_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_subtract_word(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_multiply_i8(
    int8_t a,
    int8_t b,
    int8_t *out0);
hmath_status hmath_scalar_checked_multiply_i8(
    hmath_context *context,
    int8_t a,
    int8_t b,
    int8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_multiply_i8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_multiply_i16(
    int16_t a,
    int16_t b,
    int16_t *out0);
hmath_status hmath_scalar_checked_multiply_i16(
    hmath_context *context,
    int16_t a,
    int16_t b,
    int16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_multiply_i16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_multiply_i32(
    int32_t a,
    int32_t b,
    int32_t *out0);
hmath_status hmath_scalar_checked_multiply_i32(
    hmath_context *context,
    int32_t a,
    int32_t b,
    int32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_multiply_i32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_multiply_i64(
    int64_t a,
    int64_t b,
    int64_t *out0);
hmath_status hmath_scalar_checked_multiply_i64(
    hmath_context *context,
    int64_t a,
    int64_t b,
    int64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_multiply_i64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_multiply_u8(
    uint8_t a,
    uint8_t b,
    uint8_t *out0);
hmath_status hmath_scalar_checked_multiply_u8(
    hmath_context *context,
    uint8_t a,
    uint8_t b,
    uint8_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_multiply_u8(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_multiply_u16(
    uint16_t a,
    uint16_t b,
    uint16_t *out0);
hmath_status hmath_scalar_checked_multiply_u16(
    hmath_context *context,
    uint16_t a,
    uint16_t b,
    uint16_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_multiply_u16(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_multiply_u32(
    uint32_t a,
    uint32_t b,
    uint32_t *out0);
hmath_status hmath_scalar_checked_multiply_u32(
    hmath_context *context,
    uint32_t a,
    uint32_t b,
    uint32_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_multiply_u32(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_multiply_u64(
    uint64_t a,
    uint64_t b,
    uint64_t *out0);
hmath_status hmath_scalar_checked_multiply_u64(
    hmath_context *context,
    uint64_t a,
    uint64_t b,
    uint64_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_multiply_u64(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_multiply_int(
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0);
hmath_status hmath_scalar_checked_multiply_int(
    hmath_context *context,
    ptrdiff_t a,
    ptrdiff_t b,
    ptrdiff_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_multiply_int(a, b, out0);
    hm_leave();
    return status;
}
extern int hm_numeric_scalar_checked_multiply_word(
    size_t a,
    size_t b,
    size_t *out0);
hmath_status hmath_scalar_checked_multiply_word(
    hmath_context *context,
    size_t a,
    size_t b,
    size_t *out0) {
    if (!out0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL output");
    hmath_status status = hm_enter(context);
    if (status)
        return status;
    status = (hmath_status)hm_numeric_scalar_checked_multiply_word(a, b, out0);
    hm_leave();
    return status;
}
