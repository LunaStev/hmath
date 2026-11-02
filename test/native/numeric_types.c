/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_numeric_types.h"
#include "hmath_error.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static hmath_status square(const hmath_numeric_value *input, void *userdata,
                           hmath_numeric_value **out) {
    (void)userdata;
    return hmath_numeric_types_binary(NULL, 2, input, input, out);
}
static hmath_status source_error(const hmath_numeric_value *input, void *userdata,
                                hmath_numeric_value **out) {
    (void)input;
    (void)userdata;
    return hmath_numeric_types_interval(NULL, 2, 1, out);
}
static hmath_status identity(const hmath_numeric_value *input, void *userdata,
                             hmath_numeric_value **out) {
    (void)userdata;
    hmath_numeric_types_retain((hmath_numeric_value *)input);
    *out = (hmath_numeric_value *)input;
    return HMATH_OK;
}
int main(void) {
    hmath_numeric_value *value = NULL, *rounded = NULL, *child = NULL, *result = NULL;
    hmath_numeric_value *unchanged = (hmath_numeric_value *)(uintptr_t)1;
    double real = 0, imaginary = 0;
    assert(hmath_init() == HMATH_OK);
    assert(hmath_value_f64(NULL, -2, &value) == HMATH_OK);
    assert(hmath_numeric_types_derivative(NULL, square, NULL, value, &result) == HMATH_OK);
    assert(hmath_value_get_f64(result, &real, &imaginary) == HMATH_OK && real == -4);
    hmath_numeric_types_release(result);
    result = NULL;
    assert(hmath_numeric_types_derivative(NULL, identity, NULL, value, &result) == HMATH_OK);
    assert(hmath_value_get_f64(result, &real, &imaginary) == HMATH_OK && real == 1);
    hmath_numeric_types_release(result);
    result = NULL;
    assert(hmath_numeric_types_derivative(NULL, source_error, NULL, value, &unchanged) == HMATH_MATH_ERROR);
    assert(unchanged == (hmath_numeric_value *)(uintptr_t)1);
    hmath_math_error error;
    assert(hmath_last_math_error(&error));
    assert(error.kind == HMATH_MATH_DOMAIN_ERROR);
    assert(error.message_length > 0);
    const int flags[] = {HMATH_INEXACT, HMATH_INVALID_OPERATION, HMATH_INEXACT};
    assert(hmath_numeric_types_rounded(NULL, value, flags, 3, &rounded) == HMATH_OK);
    assert(hmath_numeric_types_rounded_value(NULL, rounded, &child) == HMATH_OK);
    hmath_numeric_types_release(rounded);
    hmath_numeric_types_release(value);
    rounded = value = NULL;
    assert(hmath_value_get_f64(child, &real, &imaginary) == HMATH_OK && real == -2);
    assert(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_numeric_types_release(child);
    child = NULL;
    assert(hmath_numeric_types_float16(NULL, HMATH_NEAREST_EVEN, 1.1, &rounded) == HMATH_OK);
    assert(hmath_numeric_types_rounded_value(NULL, rounded, &child) == HMATH_OK);
    assert(hmath_numeric_types_float16_bits(NULL, child, &result) == HMATH_OK);
    char *numerator = NULL, *denominator = NULL;
    assert(hmath_value_get_exact(result, &numerator, &denominator) == HMATH_OK);
    assert(strcmp(numerator, "15462") == 0 && strcmp(denominator, "1") == 0);
    hmath_value_string_free(numerator);
    hmath_value_string_free(denominator);
    hmath_numeric_types_release(result);
    hmath_numeric_types_release(child);
    hmath_numeric_types_release(rounded);
    assert(hmath_numeric_types_big_float(NULL, 200, HMATH_NEAREST_EVEN, "1", "0", &unchanged) == HMATH_INVALID_ARGUMENT);
    assert(unchanged == (hmath_numeric_value *)(uintptr_t)1);
    assert(hmath_numeric_types_rounded(NULL, NULL, flags, 3, &unchanged) == HMATH_INVALID_ARGUMENT);
    assert(hmath_numeric_types_float16_from_bits(NULL, 0, NULL) == HMATH_INVALID_ARGUMENT);
    assert(hmath_numeric_types_kind(NULL) == 0);
    hmath_numeric_types_release(NULL);
    assert(hmath_runtime_shutdown() == HMATH_OK);
    puts("Numeric C callback, ownership, flags and error contracts passed.");
    return 0;
}
