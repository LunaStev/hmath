/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_autodiff.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define CHECK(c)                                                                                   \
    do {                                                                                           \
        if (!(c)) {                                                                                \
            fprintf(stderr, "%s:%d: %s (%s)\n", __FILE__, __LINE__, #c,                            \
                    hmath_last_error_message());                                                   \
            exit(1);                                                                               \
        }                                                                                          \
    } while (0)
static hmath_status cube_rule(const double *values, size_t count, void *userdata, double *value,
                              double *partials, size_t capacity, size_t *partial_count,
                              const char **error_message) {
    (void)userdata;
    (void)error_message;
    CHECK(count == 1 && capacity == 1);
    *value = values[0] * values[0] * values[0];
    partials[0] = 3 * values[0] * values[0];
    *partial_count = 1;
    return HMATH_OK;
}
static hmath_status square_builder(const hmath_ad_expr *const *values, size_t count, void *userdata,
                                   hmath_ad_expr **out, const char **error_message) {
    (void)userdata;
    (void)error_message;
    CHECK(count == 1);
    return hmath_ad_binary(NULL, HMATH_AD_MULTIPLY, values[0], values[0], out);
}
static hmath_status domain_rule(const double *values, size_t count, void *userdata, double *value,
                                double *partials, size_t capacity, size_t *partial_count,
                                const char **error_message) {
    (void)values;
    (void)count;
    (void)userdata;
    (void)value;
    (void)partials;
    (void)capacity;
    (void)partial_count;
    *error_message = "DomainError \"custom domain\"";
    return HMATH_MATH_ERROR;
}
int main(void) {
    CHECK(hmath_init() == HMATH_INIT_OK);
    hmath_ad_expr *x = NULL, *squared = NULL, *invalid = NULL;
    hmath_ad_graph *graph = NULL;
    CHECK(hmath_ad_variable(NULL, 0, &x) == HMATH_OK);
    CHECK(hmath_ad_binary(NULL, HMATH_AD_MULTIPLY, x, x, &squared) == HMATH_OK);
    CHECK(hmath_ad_compile_graph(NULL, 1, squared, &graph) == HMATH_OK);
    double input = 3, output = 99, gradient[] = {99, 99};
    CHECK(hmath_ad_evaluate_graph(NULL, graph, &input, 1, &output, 0) == HMATH_BOUNDS_ERROR);
    CHECK(output == 99);
    CHECK(hmath_ad_value_and_gradient(NULL, squared, &input, 1, gradient, 1) == HMATH_BOUNDS_ERROR);
    CHECK(gradient[0] == 99 && gradient[1] == 99);
    CHECK(hmath_ad_value_and_gradient(NULL, squared, &input, 1, gradient, 2) == HMATH_OK);
    CHECK(gradient[0] == 9 && gradient[1] == 6);
    CHECK(hmath_ad_variable(NULL, -1, &invalid) == HMATH_OK);
    hmath_ad_graph *failure = NULL;
    CHECK(hmath_ad_compile_graph(NULL, 0, invalid, &failure) == HMATH_MATH_ERROR);
    CHECK(failure == NULL &&
          strcmp(hmath_last_error_message(), "InvalidArgument \"graph input index\"") == 0);
    hmath_ad_release(invalid);
    CHECK(hmath_ad_constant(NULL, NAN, &invalid) == HMATH_OK);
    CHECK(hmath_ad_compile_graph(NULL, 0, invalid, &failure) == HMATH_MATH_ERROR);
    CHECK(failure == NULL && strcmp(hmath_last_error_message(), "NonFiniteResult") == 0);
    hmath_ad_release(invalid);
    CHECK(hmath_ad_gradient(NULL, graph, &input, 1, gradient, 2) == HMATH_INVALID_ARGUMENT);
    hmath_ad_dual *dual = NULL, *dual_square = NULL;
    CHECK(hmath_ad_dual_create(NULL, 3, 1, &dual) == HMATH_OK);
    CHECK(hmath_ad_binary(NULL, HMATH_AD_MULTIPLY, dual, dual, &dual_square) == HMATH_OK);
    CHECK(hmath_ad_values_copy(dual_square, gradient, 2) == HMATH_OK);
    CHECK(gradient[0] == 9 && gradient[1] == 6);
    CHECK(hmath_last_error_code() == HMATH_OK);
    hmath_ad_release(dual);
    hmath_ad_release(dual_square);
    hmath_ad_tensor *empty = NULL;
    ptrdiff_t shape[] = {0};
    size_t count, rank;
    CHECK(hmath_ad_tensor_create(NULL, shape, 1, NULL, 0, &empty) == HMATH_OK);
    CHECK(hmath_ad_metadata(empty, &count, &rank) == HMATH_OK && count == 0 && rank == 1);
    CHECK(hmath_ad_tensor_values(empty, NULL, 0) == HMATH_OK);
    hmath_ad_release(empty);
    hmath_ad_dual *seed_a = NULL, *seed_b = NULL, *nested = NULL, *nested_square = NULL,
                  *nested_cube = NULL, *primal_part = NULL, *tangent_part = NULL;
    CHECK(hmath_ad_dual_create(NULL, 3, 1, &seed_a) == HMATH_OK);
    CHECK(hmath_ad_dual_create(NULL, 1, 0, &seed_b) == HMATH_OK);
    CHECK(hmath_ad_dual_nested(NULL, seed_a, seed_b, &nested) == HMATH_OK);
    size_t depth;
    CHECK(hmath_ad_dual_depth(nested, &depth) == HMATH_OK && depth == 2);
    CHECK(hmath_ad_binary(NULL, HMATH_AD_MULTIPLY, nested, nested, &nested_square) == HMATH_OK);
    CHECK(hmath_ad_binary(NULL, HMATH_AD_MULTIPLY, nested_square, nested, &nested_cube) ==
          HMATH_OK);
    CHECK(hmath_ad_dual_parts(nested_cube, &primal_part, &tangent_part) == HMATH_OK);
    CHECK(hmath_ad_values_copy(tangent_part, gradient, 2) == HMATH_OK && gradient[0] == 27 &&
          gradient[1] == 18);
    hmath_ad_release(seed_a);
    hmath_ad_release(seed_b);
    hmath_ad_release(nested);
    hmath_ad_release(nested_square);
    hmath_ad_release(nested_cube);
    hmath_ad_release(primal_part);
    hmath_ad_release(tangent_part);
    hmath_ad_dual *small = NULL, *one = NULL, *sum = NULL, *large = NULL, *square = NULL,
                  *ep = NULL, *et = NULL, *ratio = NULL, *reciprocal = NULL;
    CHECK(hmath_ad_dual_create_f32(NULL, 16777216, 1, &small) == HMATH_OK);
    CHECK(hmath_ad_dual_create_f32(NULL, 1, 0, &one) == HMATH_OK);
    CHECK(hmath_ad_binary(NULL, HMATH_AD_ADD, small, one, &sum) == HMATH_OK);
    CHECK(hmath_ad_values_copy(sum, gradient, 2) == HMATH_OK && gradient[0] == 16777216 &&
          gradient[1] == 1);
    hmath_ad_release(small);
    hmath_ad_release(one);
    hmath_ad_release(sum);
    CHECK(hmath_ad_dual_create_integer(NULL, "9007199254740993", "1", &large) == HMATH_OK);
    CHECK(hmath_ad_binary(NULL, HMATH_AD_MULTIPLY, large, large, &square) == HMATH_OK);
    CHECK(hmath_ad_dual_parts(square, &ep, &et) == HMATH_OK);
    char *numerator = NULL, *denominator = NULL;
    CHECK(hmath_ad_scalar_text(ep, &numerator, &denominator) == HMATH_OK);
    CHECK(strcmp(numerator, "81129638414606699710187514626049") == 0 &&
          strcmp(denominator, "1") == 0);
    hmath_ad_string_free(numerator);
    hmath_ad_string_free(denominator);
    hmath_ad_release(ep);
    hmath_ad_release(et);
    hmath_ad_release(large);
    hmath_ad_release(square);
    CHECK(hmath_ad_dual_create_rational(NULL, "2", "3", "1", "1", &ratio) == HMATH_OK);
    CHECK(hmath_ad_unary(NULL, HMATH_AD_RECIPROCAL, ratio, &reciprocal) == HMATH_OK);
    CHECK(hmath_ad_dual_parts(reciprocal, &ep, &et) == HMATH_OK);
    CHECK(hmath_ad_scalar_text(et, &numerator, &denominator) == HMATH_OK);
    CHECK(strcmp(numerator, "-9") == 0 && strcmp(denominator, "4") == 0);
    hmath_ad_string_free(numerator);
    hmath_ad_string_free(denominator);
    hmath_ad_release(ep);
    hmath_ad_release(et);
    hmath_ad_release(ratio);
    hmath_ad_release(reciprocal);
    const hmath_ad_expr *custom_inputs[] = {x};
    hmath_ad_expr *custom = NULL, *checkpoint = NULL;
    CHECK(hmath_ad_custom_operation(NULL, cube_rule, NULL, custom_inputs, 1, &custom) == HMATH_OK);
    CHECK(hmath_ad_value_and_gradient(NULL, custom, &input, 1, gradient, 2) == HMATH_OK);
    CHECK(gradient[0] == 27 && gradient[1] == 27);
    hmath_ad_release(custom);
    CHECK(hmath_ad_checkpoint(NULL, square_builder, NULL, custom_inputs, 1, &checkpoint) ==
          HMATH_OK);
    CHECK(hmath_ad_value_and_gradient(NULL, checkpoint, &input, 1, gradient, 2) == HMATH_OK);
    CHECK(gradient[0] == 9 && gradient[1] == 6);
    hmath_ad_release(checkpoint);
    CHECK(hmath_ad_custom_operation(NULL, domain_rule, NULL, custom_inputs, 1, &custom) ==
          HMATH_OK);
    gradient[0] = 99;
    gradient[1] = 99;
    CHECK(hmath_ad_value_and_gradient(NULL, custom, &input, 1, gradient, 2) == HMATH_MATH_ERROR);
    CHECK(strcmp(hmath_last_error_message(), "DomainError \"custom domain\"") == 0);
    CHECK(gradient[0] == 99 && gradient[1] == 99);
    hmath_ad_release(custom);
    hmath_ad_release(x);
    hmath_ad_release(squared);
    CHECK(hmath_ad_evaluate_graph(NULL, graph, &input, 1, &output, 1) == HMATH_OK && output == 9);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_ad_release(graph);
    hmath_ad_release(NULL);
    CHECK(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
