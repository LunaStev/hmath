/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_autodiff.h"
#include "hmath_error.h"
#include "hmath_numeric_objects.h"
#include "hmath_numeric_types.h"
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK(condition)                                                                           \
    do {                                                                                           \
        if (!(condition)) {                                                                        \
            fprintf(stderr, "%s:%d: %s (%s)\n", __FILE__, __LINE__, #condition,                    \
                    hmath_last_error_message());                                                   \
            exit(1);                                                                               \
        }                                                                                          \
    } while (0)
typedef hmath_status (*unary_value)(hmath_context *, const hmath_value *, const hmath_value *,
                                    hmath_value **);
typedef hmath_status (*binary_value)(hmath_context *, const hmath_value *, const hmath_value *,
                                     const hmath_value *, hmath_value **);
static double scalar(const hmath_value *value) {
    double real = 0, imaginary = 1;
    CHECK(hmath_value_get_f64(value, &real, &imaginary) == HMATH_OK && imaginary == 0);
    return real;
}
static hmath_value *item(const hmath_value *value, ptrdiff_t index) {
    hmath_value *out = NULL;
    CHECK(hmath_value_item(NULL, value, index, &out) == HMATH_OK);
    return out;
}
static void metadata(const hmath_value *value, int expected_kind, int expected_dtype,
                     size_t expected_length) {
    int kind = -1, dtype = -1;
    size_t count = 99;
    CHECK(hmath_value_info(value, &kind, &dtype, &count) == HMATH_OK && kind == expected_kind &&
          dtype == expected_dtype && count == expected_length);
}
static void dual_parts(const hmath_value *value, double expected_primal, double expected_tangent) {
    hmath_value *a = NULL, *b = NULL;
    CHECK(hmath_numeric_types_primal(NULL, value, &a) == HMATH_OK);
    CHECK(hmath_numeric_types_tangent(NULL, value, &b) == HMATH_OK);
    CHECK(scalar(a) == expected_primal && scalar(b) == expected_tangent);
    hmath_value_release(a);
    hmath_value_release(b);
}
static void exact_is(const hmath_value *value, const char *expected) {
    char *n = NULL, *d = NULL;
    CHECK(hmath_value_get_exact(value, &n, &d) == HMATH_OK && strcmp(n, expected) == 0 &&
          strcmp(d, "1") == 0);
    hmath_value_string_free(n);
    hmath_value_string_free(d);
}
int main(void) {
    CHECK(hmath_init() == HMATH_OK);
    hmath_value *x = NULL, *y = NULL, *half = NULL, *empty = NULL, *list = NULL, *result = NULL;
    CHECK(hmath_value_f64(NULL, 2, &x) == HMATH_OK);
    CHECK(hmath_value_f64(NULL, 3, &y) == HMATH_OK);
    CHECK(hmath_value_f64(NULL, 0.5, &half) == HMATH_OK);
    CHECK(hmath_value_list(NULL, NULL, 0, &empty) == HMATH_OK);
    const hmath_value *values[] = {x, y};
    CHECK(hmath_value_list(NULL, values, 2, &list) == HMATH_OK);
    CHECK(hmath_basic_clamp_value(NULL, x, x, y, half, &result) == HMATH_OK && scalar(result) == 2);
    hmath_value_release(result);
    CHECK(hmath_basic_lerp_value(NULL, x, x, y, half, &result) == HMATH_OK &&
          scalar(result) == 2.5);
    hmath_value_release(result);
    const binary_value binaries[] = {hmath_scalar_add_value, hmath_scalar_subtract_scalar_value,
                                     hmath_scalar_multiply_value, hmath_scalar_minimum_scalar_value,
                                     hmath_scalar_maximum_scalar_value};
    const double expected_binary[] = {5, -1, 6, 2, 3};
    for (size_t i = 0; i < sizeof binaries / sizeof *binaries; ++i) {
        CHECK(binaries[i](NULL, x, x, y, &result) == HMATH_OK &&
              scalar(result) == expected_binary[i]);
        hmath_value_release(result);
    }
    const unary_value unary[] = {hmath_scalar_absolute_value, hmath_scalar_sign_value};
    for (size_t i = 0; i < sizeof unary / sizeof *unary; ++i) {
        CHECK(unary[i](NULL, x, x, &result) == HMATH_OK && scalar(result) == (i ? 1 : 2));
        hmath_value_release(result);
    }
    const unary_value scans[] = {hmath_scalar_cumulative_sum_value,
                                 hmath_scalar_cumulative_product_value,
                                 hmath_scalar_prefix_sum_value};
    const double expected_scan[] = {5, 6, 5};
    for (size_t i = 0; i < sizeof scans / sizeof *scans; ++i) {
        CHECK(scans[i](NULL, x, list, &result) == HMATH_OK);
        hmath_value *last = item(result, i == 2 ? 2 : 1);
        CHECK(scalar(last) == expected_scan[i]);
        hmath_value_release(last);
        hmath_value_release(result);
    }
    const unary_value statistics[] = {hmath_statistics_mean_value, hmath_statistics_variance_value,
                                      hmath_statistics_standard_deviation_value,
                                      hmath_statistics_median_value};
    const double expected_stats[] = {2.5, 0.25, 0.5, 2.5};
    for (size_t i = 0; i < sizeof statistics / sizeof *statistics; ++i) {
        CHECK(statistics[i](NULL, x, list, &result) == HMATH_OK &&
              scalar(result) == expected_stats[i]);
        hmath_value_release(result);
        hmath_value *sentinel = x;
        CHECK(statistics[i](NULL, x, empty, &sentinel) == HMATH_HASKELL_EXCEPTION && sentinel == x);
    }
    CHECK(hmath_linear_dot_value(NULL, x, list, list, &result) == HMATH_OK && scalar(result) == 13);
    hmath_value_release(result);
    CHECK(hmath_linear_dot_checked_value(NULL, x, list, list, &result) == HMATH_OK &&
          scalar(result) == 13);
    hmath_value_release(result);
    CHECK(hmath_linear_magnitude_value(NULL, x, list, &result) == HMATH_OK &&
          scalar(result) == sqrt(13));
    hmath_value_release(result);
    CHECK(hmath_linear_normalize_value(NULL, x, list, &result) == HMATH_OK);
    hmath_value *first = item(result, 0);
    CHECK(scalar(first) == 2 / sqrt(13));
    hmath_value_release(first);
    hmath_value_release(result);
    const binary_value linear[] = {hmath_linear_add_value, hmath_linear_add_checked_value,
                                   hmath_linear_subtract_checked_value};
    for (size_t i = 0; i < sizeof linear / sizeof *linear; ++i) {
        CHECK(linear[i](NULL, x, list, list, &result) == HMATH_OK);
        first = item(result, 0);
        CHECK(scalar(first) == (i == 2 ? 0 : 4));
        hmath_value_release(first);
        hmath_value_release(result);
    }
    CHECK(hmath_linear_scale_value(NULL, x, x, list, &result) == HMATH_OK);
    first = item(result, 1);
    CHECK(scalar(first) == 6);
    hmath_value_release(first);
    hmath_value_release(result);
    hmath_value *sentinel = x;
    CHECK(hmath_linear_dot_checked_value(NULL, x, list, empty, &sentinel) == HMATH_MATH_ERROR &&
          sentinel == x);
    hmath_math_error error;
    CHECK(hmath_last_math_error(&error) == 1 && error.kind == HMATH_MATH_VECTOR_LENGTH_MISMATCH &&
          error.details[0] == 2 && error.details[1] == 0);
    CHECK(hmath_linear_dot_value(NULL, x, list, empty, &sentinel) == HMATH_HASKELL_EXCEPTION &&
          sentinel == x && strstr(hmath_last_error_message(), "dot: dimension mismatch") != NULL);
    hmath_value *bounded = NULL, *unit = NULL;
    CHECK(hmath_value_integral(NULL, HMATH_COEFFICIENT_INT8, "127", &bounded) == HMATH_OK);
    CHECK(hmath_value_integral(NULL, HMATH_COEFFICIENT_INT8, "1", &unit) == HMATH_OK);
    const binary_value bounded_functions[] = {
        hmath_scalar_saturating_add_value,      hmath_scalar_saturating_subtract_value,
        hmath_scalar_saturating_multiply_value, hmath_scalar_checked_add_value,
        hmath_scalar_checked_subtract_value,    hmath_scalar_checked_multiply_value};
    const char *expected_bounded[] = {"127", "126", "127", NULL, "126", "127"};
    for (size_t i = 0; i < sizeof bounded_functions / sizeof *bounded_functions; ++i) {
        sentinel = x;
        hmath_status status = bounded_functions[i](NULL, bounded, bounded, unit, &sentinel);
        if (expected_bounded[i]) {
            CHECK(status == HMATH_OK);
            exact_is(sentinel, expected_bounded[i]);
            hmath_value_release(sentinel);
        } else {
            CHECK(status == HMATH_MATH_ERROR && sentinel == x);
            CHECK(hmath_last_math_error(&error) == 1 && error.kind == HMATH_MATH_DOMAIN_ERROR);
        }
    }
    CHECK(hmath_scalar_positive_modulo_value(NULL, bounded, bounded, unit, &result) == HMATH_OK);
    exact_is(result, "0");
    hmath_value_release(result);
    hmath_value_release(bounded);
    hmath_value_release(unit);

    /* Both Numeric.Dual components and nested witnesses survive, including an
     * empty-list zero selected solely by an explicit original prototype. */
    hmath_value *dual = NULL, *other = NULL, *tangent = NULL, *nested = NULL, *nested_sum = NULL;
    CHECK(hmath_value_f64(NULL, 1, &tangent) == HMATH_OK);
    CHECK(hmath_numeric_types_dual(NULL, x, tangent, &dual) == HMATH_OK);
    CHECK(hmath_numeric_types_dual(NULL, y, x, &other) == HMATH_OK);
    CHECK(hmath_scalar_multiply_value(NULL, dual, dual, other, &result) == HMATH_OK);
    dual_parts(result, 6, 7);
    hmath_value_release(result);
    CHECK(hmath_numeric_types_dual(NULL, dual, other, &nested) == HMATH_OK);
    CHECK(hmath_scalar_add_value(NULL, nested, nested, nested, &nested_sum) == HMATH_OK);
    hmath_value *primal = NULL;
    CHECK(hmath_numeric_types_primal(NULL, nested_sum, &primal) == HMATH_OK);
    dual_parts(primal, 4, 2);
    hmath_value_release(primal);
    hmath_value_release(nested_sum);
    CHECK(hmath_linear_dot_value(NULL, nested, empty, empty, &result) == HMATH_OK);
    CHECK(hmath_numeric_types_primal(NULL, result, &primal) == HMATH_OK);
    dual_parts(primal, 0, 0);
    hmath_value_release(primal);
    hmath_value_release(result);
    sentinel = x;
    CHECK(hmath_scalar_minimum_scalar_value(NULL, dual, dual, other, &sentinel) ==
              HMATH_UNSUPPORTED &&
          sentinel == x);
    CHECK(hmath_statistics_median_value(NULL, dual, list, &sentinel) == HMATH_UNSUPPORTED &&
          sentinel == x);
    CHECK(hmath_scalar_positive_modulo_value(NULL, dual, dual, other, &sentinel) ==
              HMATH_UNSUPPORTED &&
          sentinel == x);
    hmath_value *quaternion = NULL;
    CHECK(hmath_numeric_types_quaternion(NULL, x, y, tangent, half, &quaternion) == HMATH_OK);
    CHECK(hmath_scalar_multiply_value(NULL, quaternion, quaternion, quaternion, &result) ==
          HMATH_OK);
    metadata(result, 1, 21, 0);
    hmath_value_release(result);
    sentinel = x;
    CHECK(hmath_basic_lerp_value(NULL, quaternion, quaternion, quaternion, quaternion, &sentinel) ==
              HMATH_UNSUPPORTED &&
          sentinel == x);

    /* Original AD.Dual is a separate type; its original Ord compares primals
     * only, retaining the selected operand's full tangent. */
    hmath_ad_dual *ad_left = NULL, *ad_right = NULL;
    hmath_value *ad_value = NULL, *ad_other = NULL;
    CHECK(hmath_ad_dual_create(NULL, 2, 7, &ad_left) == HMATH_OK);
    CHECK(hmath_ad_dual_create(NULL, 3, 11, &ad_right) == HMATH_OK);
    CHECK(hmath_ad_value_import(NULL, ad_left, &ad_value) == HMATH_OK);
    CHECK(hmath_ad_value_import(NULL, ad_right, &ad_other) == HMATH_OK);
    CHECK(hmath_scalar_minimum_scalar_value(NULL, ad_value, ad_value, ad_other, &result) ==
          HMATH_OK);
    hmath_ad_handle *converted = NULL;
    CHECK(hmath_ad_value_export(NULL, result, &converted) == HMATH_OK);
    double parts[2];
    CHECK(hmath_ad_values_copy(converted, parts, 2) == HMATH_OK && parts[0] == 2 && parts[1] == 7);
    hmath_ad_release(converted);
    hmath_value_release(result);
    sentinel = x;
    CHECK(hmath_scalar_add_value(NULL, dual, dual, ad_value, &sentinel) == HMATH_INVALID_ARGUMENT &&
          sentinel == x);

    /* Symbolic results remain original graph nodes; Eq-dependent normalization
     * is unavailable rather than receiving an invented expression equality. */
    hmath_ad_expr *expression = NULL;
    hmath_value *expression_value = NULL;
    CHECK(hmath_ad_variable(NULL, 0, &expression) == HMATH_OK);
    CHECK(hmath_ad_value_import(NULL, expression, &expression_value) == HMATH_OK);
    CHECK(hmath_scalar_multiply_value(NULL, expression_value, expression_value, expression_value,
                                      &result) == HMATH_OK);
    metadata(result, 287, 0, 0);
    CHECK(hmath_ad_value_export(NULL, result, &converted) == HMATH_OK);
    hmath_ad_graph *graph = NULL;
    CHECK(hmath_ad_compile_graph(NULL, 1, converted, &graph) == HMATH_OK);
    double input = 1.25, output = 0;
    CHECK(hmath_ad_evaluate_graph(NULL, graph, &input, 1, &output, 1) == HMATH_OK &&
          output == 1.5625);
    hmath_ad_release(graph);
    hmath_ad_release(converted);
    hmath_value_release(result);
    sentinel = x;
    CHECK(hmath_linear_normalize_value(NULL, expression_value, empty, &sentinel) ==
              HMATH_UNSUPPORTED &&
          sentinel == x);
    CHECK(hmath_scalar_minimum_scalar_value(NULL, expression_value, expression_value,
                                            expression_value, &sentinel) == HMATH_UNSUPPORTED &&
          sentinel == x);
    hmath_value_release(expression_value);
    hmath_ad_release(expression);
    hmath_value_release(ad_value);
    hmath_value_release(ad_other);
    hmath_ad_release(ad_left);
    hmath_ad_release(ad_right);
    hmath_value_release(quaternion);
    hmath_value_release(nested);
    hmath_value_release(dual);
    hmath_value_release(other);
    hmath_value_release(tangent);
    hmath_value_release(x);
    hmath_value_release(y);
    hmath_value_release(half);
    hmath_value_release(empty);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_value_release(list);
    CHECK(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
