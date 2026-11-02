/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_deeplearning.h"
#include <assert.h>
#include <stdint.h>
#include <string.h>

int main(void) {
    assert(hmath_init() == HMATH_INIT_OK);
    hmath_value *kind = NULL, *zero = NULL, *result = NULL;
    assert(hmath_neural_core_sigmoid_create(NULL, &kind) == HMATH_OK);
    assert(hmath_value_f64(NULL, 0, &zero) == HMATH_OK);
    assert(hmath_neural_core_activation(NULL, kind, zero, &result) == HMATH_OK);
    double real, imaginary;
    assert(hmath_value_get_f64(result, &real, &imaginary) == HMATH_OK && real == 0.5);
    hmath_value_release(result);
    hmath_ad_expr *input = NULL, *expression = NULL;
    hmath_value *wrapped = NULL, *output = NULL;
    assert(hmath_ad_variable(NULL, 0, &input) == HMATH_OK);
    assert(hmath_ad_value_import(NULL, input, &wrapped) == HMATH_OK);
    assert(hmath_neural_core_activation_expr(NULL, kind, wrapped, &output) == HMATH_OK);
    assert(hmath_ad_value_export(NULL, output, &expression) == HMATH_OK);
    hmath_value_release(output);
    hmath_value_release(wrapped);
    hmath_ad_release(input);
    double point = 0, evaluated[2] = {0, 0};
    assert(hmath_ad_value_and_gradient(NULL, expression, &point, 1, evaluated, 2) == HMATH_OK);
    assert(evaluated[0] == 0.5 && evaluated[1] == 0.25);
    hmath_ad_release(expression);
    hmath_value *elu = NULL;
    assert(hmath_neural_core_elu_create(NULL, zero, &elu) == HMATH_OK);
    hmath_value *sentinel = (hmath_value *)(uintptr_t)0x1234;
    assert(hmath_neural_core_activation(NULL, elu, zero, &sentinel) == HMATH_MATH_ERROR);
    assert(sentinel == (hmath_value *)(uintptr_t)0x1234);
    hmath_math_error error;
    assert(hmath_last_math_error(&error) == 1 && error.kind == HMATH_MATH_DOMAIN_ERROR);
    const char message[] = "positive ELU alpha required";
    assert(error.message_length == strlen(message) && memcmp(error.message, message, strlen(message)) == 0);
    hmath_value_release(elu);
    hmath_value_release(kind);
    hmath_value_release(zero);
    assert(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
