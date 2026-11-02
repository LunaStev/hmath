/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_autodiff.h"
#include "hmath_error.h"
#include <assert.h>
#include <string.h>
static const char payload[] = "full\0payload\xED\xA0\x80";
static hmath_status checked_rule(const double *values, size_t count, void *userdata,
                                 double *value, double *partials, size_t capacity,
                                 size_t *written, hmath_callback_error *error) {
    (void)values;
    (void)count;
    (void)userdata;
    (void)value;
    (void)partials;
    (void)capacity;
    (void)written;
    memset(error, 0, sizeof(*error));
    error->kind = HMATH_MATH_NON_CONVERGENCE;
    error->details[0] = 123;
    error->message = payload;
    error->message_length = sizeof(payload) - 1;
    return HMATH_MATH_ERROR;
}
int main(void) {
    assert(hmath_init() == HMATH_INIT_OK);
    hmath_ad_expr *input = NULL, *output = NULL;
    assert(hmath_ad_variable(NULL, 0, &input) == HMATH_OK);
    const hmath_ad_expr *arguments[] = {input};
    assert(hmath_ad_custom_operation_checked(NULL, checked_rule, NULL, arguments, 1, &output) == HMATH_OK);
    hmath_ad_release(input);
    double point = 2, result[] = {37, 53};
    assert(hmath_ad_value_and_gradient(NULL, output, &point, 1, result, 2) == HMATH_MATH_ERROR);
    assert(result[0] == 37 && result[1] == 53);
    hmath_math_error error;
    assert(hmath_last_math_error(&error) == 1);
    assert(error.kind == HMATH_MATH_NON_CONVERGENCE && error.details[0] == 123);
    assert(error.message_length == sizeof(payload) - 1);
    assert(memcmp(error.message, payload, sizeof(payload) - 1) == 0);
    hmath_callback_error forwarded;
    assert(hmath_callback_capture_error(HMATH_MATH_ERROR, &forwarded) == 1);
    assert(forwarded.kind == error.kind && forwarded.message_length == error.message_length);
    hmath_ad_release(output);
    /* A bounded original Num instance keeps its wraparound through AD. */
    hmath_value *base = NULL, *unit = NULL, *coefficient = NULL;
    hmath_ad_dual *base_handle = NULL, *unit_handle = NULL, *dual = NULL;
    hmath_ad_handle *squared = NULL;
    assert(hmath_value_integral(NULL, HMATH_COEFFICIENT_INT8, "120", &base) == HMATH_OK);
    assert(hmath_value_integral(NULL, HMATH_COEFFICIENT_INT8, "1", &unit) == HMATH_OK);
    assert(hmath_ad_value_export(NULL, base, &base_handle) == HMATH_OK);
    assert(hmath_ad_value_export(NULL, unit, &unit_handle) == HMATH_OK);
    assert(hmath_ad_dual_nested(NULL, base_handle, unit_handle, &dual) == HMATH_OK);
    assert(hmath_ad_binary(NULL, HMATH_AD_MULTIPLY, dual, dual, &squared) == HMATH_OK);
    hmath_ad_dual *primal = NULL, *tangent = NULL;
    assert(hmath_ad_dual_parts(squared, &primal, &tangent) == HMATH_OK);
    assert(hmath_ad_value_import(NULL, primal, &coefficient) == HMATH_OK);
    char *numerator = NULL, *denominator = NULL;
    assert(hmath_value_get_exact(coefficient, &numerator, &denominator) == HMATH_OK);
    assert(strcmp(numerator, "64") == 0 && strcmp(denominator, "1") == 0);
    hmath_value_string_free(numerator);
    hmath_value_string_free(denominator);
    hmath_value_release(base);
    hmath_value_release(unit);
    hmath_value_release(coefficient);
    hmath_ad_release(base_handle);
    hmath_ad_release(unit_handle);
    hmath_ad_release(dual);
    hmath_ad_release(squared);
    hmath_ad_release(primal);
    hmath_ad_release(tangent);
    assert(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
