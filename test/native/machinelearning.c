/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_machinelearning.h"
#include "hmath_error.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
static hmath_status score(const hmath_value *arguments, void *userdata,
                          hmath_value **out, hmath_math_error *error) {
    (void)userdata;
    (void)error;
    hmath_value *parameter = NULL, *fold = NULL, *indices = NULL;
    double real = 0, imaginary = 0;
    hmath_status status = hmath_value_item(NULL, arguments, 0, &parameter);
    if (!status) status = hmath_value_get_f64(parameter, &real, &imaginary);
    if (!status) status = hmath_value_item(NULL, arguments, 1, &fold);
    if (!status) status = hmath_ml_validation_indices(NULL, fold, &indices);
    int kind = 0, dtype = 0;
    size_t count = 0;
    if (!status) status = hmath_value_info(indices, &kind, &dtype, &count);
    hmath_value_release(parameter);
    hmath_value_release(fold);
    hmath_value_release(indices);
    return status ? status : hmath_value_f64(NULL, real + (double)count, out);
}
static hmath_status domain(const hmath_value *arguments, void *userdata,
                           hmath_value **out, hmath_math_error *error) {
    (void)arguments;
    (void)userdata;
    (void)out;
    memset(error, 0, sizeof *error);
    error->kind = HMATH_MATH_DOMAIN_ERROR;
    error->message = "validation failed";
    error->message_length = strlen(error->message);
    return HMATH_MATH_ERROR;
}
int main(void) {
    hmath_value *one = NULL, *two = NULL, *zero_index = NULL, *one_index = NULL;
    hmath_value *training = NULL, *validation = NULL, *fold = NULL, *folds = NULL;
    hmath_value *candidates = NULL, *callback = NULL, *result = NULL, *child = NULL;
    hmath_value *unchanged = (hmath_value *)(uintptr_t)1;
    assert(hmath_init() == HMATH_OK);
    assert(hmath_value_f64(NULL, 1, &one) == HMATH_OK);
    assert(hmath_value_f64(NULL, 2, &two) == HMATH_OK);
    assert(hmath_value_index(NULL, 0, &zero_index) == HMATH_OK);
    assert(hmath_value_index(NULL, 1, &one_index) == HMATH_OK);
    const hmath_value *training_values[] = {zero_index}, *validation_values[] = {one_index};
    assert(hmath_value_list(NULL, training_values, 1, &training) == HMATH_OK);
    assert(hmath_value_list(NULL, validation_values, 1, &validation) == HMATH_OK);
    assert(hmath_ml_fold(NULL, training, validation, &fold) == HMATH_OK);
    const hmath_value *fold_values[] = {fold}, *parameters[] = {two, one};
    assert(hmath_value_list(NULL, fold_values, 1, &folds) == HMATH_OK);
    assert(hmath_value_list(NULL, parameters, 2, &candidates) == HMATH_OK);
    assert(hmath_linear_callback(NULL, score, NULL, &callback) == HMATH_OK);
    assert(hmath_ml_grid_search(NULL, candidates, folds, callback, &result) == HMATH_OK);
    assert(hmath_value_item(NULL, result, 0, &child) == HMATH_OK);
    double real = 0, imaginary = 0;
    assert(hmath_value_get_f64(child, &real, &imaginary) == HMATH_OK && real == 1);
    hmath_value_release(child);
    hmath_value_release(result);
    hmath_value_release(callback);
    assert(hmath_linear_callback(NULL, domain, NULL, &callback) == HMATH_OK);
    assert(hmath_ml_grid_search(NULL, candidates, folds, callback, &unchanged) == HMATH_MATH_ERROR);
    assert(unchanged == (hmath_value *)(uintptr_t)1);
    hmath_math_error error;
    assert(hmath_last_math_error(&error) && error.kind == HMATH_MATH_DOMAIN_ERROR);
    assert(error.message_length == 17 && memcmp(error.message, "validation failed", 17) == 0);
    hmath_value_release(callback);
    hmath_value *large = NULL, *small = NULL, *labels = NULL, *encoder = NULL, *codes = NULL;
    assert(hmath_value_integer(NULL, "100000000000000000000000000000000000000000000000003", &large) == HMATH_OK);
    assert(hmath_value_integer(NULL, "1", &small) == HMATH_OK);
    const hmath_value *label_values[] = {large, small, large};
    assert(hmath_value_list(NULL, label_values, 3, &labels) == HMATH_OK);
    assert(hmath_ml_fit_encoder(NULL, labels, NULL, &encoder) == HMATH_OK);
    assert(hmath_ml_label_encode(NULL, encoder, labels, &codes) == HMATH_OK);
    assert(hmath_ml_label_decode(NULL, encoder, codes, &result) == HMATH_OK);
    hmath_value_release(encoder);
    assert(hmath_value_item(NULL, result, 0, &child) == HMATH_OK);
    char *numerator = NULL, *denominator = NULL;
    assert(hmath_value_get_exact(child, &numerator, &denominator) == HMATH_OK);
    assert(strcmp(numerator, "100000000000000000000000000000000000000000000000003") == 0);
    hmath_value_string_free(numerator);
    hmath_value_string_free(denominator);
    hmath_value_release(child);
    hmath_value_release(result);
    assert(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_value_release(codes);
    hmath_value_release(labels);
    hmath_value_release(large);
    hmath_value_release(small);
    hmath_value_release(fold);
    hmath_value_release(folds);
    hmath_value_release(candidates);
    hmath_value_release(training);
    hmath_value_release(validation);
    hmath_value_release(zero_index);
    hmath_value_release(one_index);
    hmath_value_release(one);
    hmath_value_release(two);
    assert(hmath_runtime_shutdown() == HMATH_OK);
    puts("ML C checked callbacks, exact label dictionaries, independent ownership and output contracts passed.");
    return 0;
}
