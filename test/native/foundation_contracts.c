/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_algebra.h"
#include "hmath_expression_error.h"
#include "hmath_interchange_error.h"
#include "hmath_matrix_value.h"
#include "hmath_shape.h"
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
static void integer_is(const hmath_value *value, const char *expected) {
    char *numerator = NULL, *denominator = NULL;
    CHECK(hmath_value_get_exact(value, &numerator, &denominator) == HMATH_OK);
    CHECK(strcmp(numerator, expected) == 0 && strcmp(denominator, "1") == 0);
    hmath_value_string_free(numerator);
    hmath_value_string_free(denominator);
}
static hmath_status residual(const hmath_value *input, void *userdata, hmath_value **out,
                             hmath_math_error *error) {
    (void)userdata;
    (void)error;
    int kind = -1, dtype = -1;
    size_t count = 0;
    CHECK(hmath_value_info(input, &kind, &dtype, &count) == HMATH_OK && kind == 5 && count == 1);
    return hmath_value_f64(NULL, 1.0, out);
}
static hmath_status stagnant(const hmath_value *input, void *userdata, hmath_value **out,
                             hmath_math_error *error) {
    (void)input;
    (void)userdata;
    (void)error;
    return hmath_value_boolean(NULL, 0, out);
}
static hmath_status failed_step(const hmath_value *input, void *userdata, hmath_value **out,
                                hmath_math_error *error) {
    (void)input;
    (void)out;
    int status = *(int *)userdata;
    static const char message[] = "failed\0\xce\xb1";
    memset(error, 0, sizeof *error);
    error->message = message;
    error->message_length = sizeof message - 1;
    if (status == HMATH_MATH_ERROR) {
        error->kind = HMATH_MATH_NON_CONVERGENCE;
        error->details[0] = 17;
    } else if (status == HMATH_EXPRESSION_ERROR) {
        error->kind = HMATH_EXPRESSION_TYPE_MISMATCH;
        error->details[0] = 19;
        error->details[1] = 3;
        error->details[2] = 5;
    } else
        error->kind = HMATH_INTERCHANGE_INVALID_DATA;
    return (hmath_status)status;
}
int main(void) {
    CHECK(hmath_init() == HMATH_OK);
    hmath_value *one = NULL, *two = NULL, *zero = NULL, *index_zero = NULL, *index_two = NULL,
                *list = NULL, *original = NULL, *changed = NULL, *sum = NULL;
    CHECK(hmath_value_integer(NULL, "1", &one) == HMATH_OK);
    CHECK(hmath_value_integer(NULL, "2", &two) == HMATH_OK);
    CHECK(hmath_value_integer(NULL, "0", &zero) == HMATH_OK);
    CHECK(hmath_value_index(NULL, 0, &index_zero) == HMATH_OK);
    CHECK(hmath_value_index(NULL, 2, &index_two) == HMATH_OK);
    const hmath_value *entries[] = {one, two};
    CHECK(hmath_value_list(NULL, entries, 2, &list) == HMATH_OK);
    CHECK(hmath_foundation_datastructure_fenwick(NULL, list, &original) == HMATH_OK);
    CHECK(hmath_foundation_datastructure_fenwick_add(NULL, index_zero, two, original, &changed) ==
          HMATH_OK);
    CHECK(hmath_foundation_datastructure_fenwick_prefix(NULL, index_two, original, &sum) ==
          HMATH_OK);
    integer_is(sum, "3");
    hmath_value_release(sum);
    CHECK(hmath_foundation_datastructure_fenwick_prefix(NULL, index_two, changed, &sum) ==
          HMATH_OK);
    integer_is(sum, "5");
    hmath_value_release(sum);
    hmath_value_release(original);
    hmath_value_release(changed);

    /* A source Field instance is not invented for Integer. */
    hmath_value *sentinel = one;
    CHECK(hmath_algebra_api_invert(NULL, one, one, &sentinel) == HMATH_UNSUPPORTED &&
          sentinel == one);
    hmath_value *rational = NULL, *exact = NULL, *combined = NULL, *fraction = NULL;
    CHECK(hmath_value_rational(NULL, "1", "3", &rational) == HMATH_OK);
    CHECK(hmath_algebra_api_new_exact(NULL, rational, &exact) == HMATH_OK);
    CHECK(hmath_algebra_api_plus(NULL, exact, exact, exact, &combined) == HMATH_OK);
    CHECK(hmath_algebra_api_get_exact(NULL, combined, &fraction) == HMATH_OK);
    char *n = NULL, *d = NULL;
    CHECK(hmath_value_get_exact(fraction, &n, &d) == HMATH_OK && strcmp(n, "2") == 0 &&
          strcmp(d, "3") == 0);
    hmath_value_string_free(n);
    hmath_value_string_free(d);
    hmath_value_release(fraction);
    hmath_value_release(combined);
    hmath_value_release(exact);
    hmath_value_release(rational);

    /* Real nominal dimensions survive transpose and dynamic conversion. */
    hmath_value *matrix_values = NULL, *matrix = NULL, *static_matrix = NULL, *transpose = NULL,
                *dynamic = NULL, *values = NULL;
    const hmath_value *four[] = {one, two, two, one};
    CHECK(hmath_value_list(NULL, four, 4, &matrix_values) == HMATH_OK);
    CHECK(hmath_algebra_api_matrix_construct(NULL, zero, index_two, index_two, matrix_values,
                                             &matrix) == HMATH_OK);
    CHECK(hmath_shape_static_matrix(NULL, two, two, matrix, &static_matrix) == HMATH_OK);
    CHECK(hmath_shape_static_transpose(NULL, static_matrix, &transpose) == HMATH_OK);
    CHECK(hmath_shape_dynamic_matrix(NULL, transpose, &dynamic) == HMATH_OK);
    CHECK(hmath_matrix_value_to_list(NULL, dynamic, &values) == HMATH_OK);
    hmath_value *entry = NULL;
    CHECK(hmath_value_item(NULL, values, 1, &entry) == HMATH_OK);
    integer_is(entry, "2");
    hmath_value_release(entry);
    sentinel = one;
    CHECK(hmath_shape_static_matrix(NULL, one, two, matrix, &sentinel) == HMATH_MATH_ERROR &&
          sentinel == one);
    hmath_math_error math;
    CHECK(hmath_last_math_error(&math) == 1 && math.kind == HMATH_MATH_SHAPE_MISMATCH &&
          math.details[0] == 1 && math.details[1] == 2 && math.details[2] == 2 &&
          math.details[3] == 2);
    hmath_value_release(values);
    hmath_value_release(dynamic);
    hmath_value_release(transpose);
    hmath_value_release(static_matrix);
    hmath_value_release(matrix);
    hmath_value_release(matrix_values);

    /* An explicit actual Ord(Maybe Integer) dictionary permits all-Nothing
     * collections, without inventing an ordering on arbitrary foreign handles. */
    hmath_value *optional = NULL, *none = NULL, *missing = NULL, *heap = NULL, *popped = NULL;
    CHECK(hmath_foundation_optional_type(NULL, zero, &optional) == HMATH_OK);
    CHECK(hmath_value_none(NULL, &none) == HMATH_OK);
    const hmath_value *missing_items[] = {none, none};
    CHECK(hmath_value_list(NULL, missing_items, 2, &missing) == HMATH_OK);
    CHECK(hmath_foundation_heap_from_list_typed(NULL, optional, missing, &heap) == HMATH_OK);
    CHECK(hmath_foundation_datastructure_heap_pop(NULL, heap, &popped) == HMATH_OK);
    CHECK(hmath_value_item(NULL, popped, 0, &entry) == HMATH_OK);
    int kind = -1, dtype = -1;
    size_t count = 0;
    CHECK(hmath_value_info(entry, &kind, &dtype, &count) == HMATH_OK && kind == 0);
    hmath_value_release(entry);
    hmath_value_release(popped);
    hmath_value_release(heap);
    hmath_value_release(missing);
    hmath_value_release(none);
    hmath_value_release(optional);

    /* Checked MathError callbacks become source Left; foreign Expr/Interchange
     * errors abort while retaining their complete positioned/domain payload. */
    hmath_value *limit = NULL, *tolerance = NULL, *options = NULL, *step = NULL, *measure = NULL,
                *equal = NULL;
    CHECK(hmath_value_index(NULL, 1, &limit) == HMATH_OK);
    CHECK(hmath_value_f64(NULL, 0.0, &tolerance) == HMATH_OK);
    CHECK(hmath_foundation_convergence_new_iteration_options(NULL, limit, tolerance, tolerance,
                                                             &options) == HMATH_OK);
    CHECK(hmath_linear_callback(NULL, residual, NULL, &measure) == HMATH_OK);
    CHECK(hmath_linear_callback(NULL, stagnant, NULL, &equal) == HMATH_OK);
    for (int status = HMATH_MATH_ERROR; status <= HMATH_INTERCHANGE_ERROR; ++status) {
        CHECK(hmath_linear_callback(NULL, failed_step, &status, &step) == HMATH_OK);
        sentinel = one;
        CHECK(hmath_foundation_convergence_iterate_until(NULL, options, step, measure, equal, zero,
                                                         &sentinel) == (hmath_status)status &&
              sentinel == one);
        if (status == HMATH_MATH_ERROR)
            CHECK(hmath_last_math_error(&math) == 1 && math.kind == HMATH_MATH_NON_CONVERGENCE &&
                  math.details[0] == 17 && math.message_length == 9 &&
                  memcmp(math.message, "failed\0\xce\xb1", 9) == 0);
        else if (status == HMATH_EXPRESSION_ERROR) {
            hmath_expression_error expression;
            CHECK(hmath_last_expression_error(&expression) == 1 &&
                  expression.kind == HMATH_EXPRESSION_TYPE_MISMATCH &&
                  expression.source_offset == 19 && expression.source_line == 3 &&
                  expression.source_column == 5 && expression.message_length == 9);
        } else {
            hmath_interchange_error interchange;
            CHECK(hmath_last_interchange_error(&interchange) == 1 &&
                  interchange.kind == HMATH_INTERCHANGE_INVALID_DATA &&
                  interchange.message_length == 9);
        }
        hmath_value_release(step);
    }
    hmath_value_release(options);
    hmath_value_release(limit);
    hmath_value_release(tolerance);
    hmath_value_release(measure);
    hmath_value_release(equal);
    hmath_value_release(one);
    hmath_value_release(two);
    hmath_value_release(zero);
    hmath_value_release(index_zero);
    hmath_value_release(index_two);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_value_release(list);
    CHECK(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
