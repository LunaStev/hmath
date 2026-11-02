/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_matrix_value.h"
#include "hmath_polynomial.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define CHECK(x)                                                                                   \
    do {                                                                                           \
        if (!(x)) {                                                                                \
            fprintf(stderr, "%s:%d: %s (%s)\n", __FILE__, __LINE__, #x,                            \
                    hmath_last_error_message());                                                   \
            exit(1);                                                                               \
        }                                                                                          \
    } while (0)
static hmath_status fail_callback(double input, double *out, void *userdata,
                                  hmath_math_error *error) {
    (void)input;
    (void)out;
    (void)userdata;
    static const char message[] = {'x', '\0', (char)0xce, (char)0xb1};
    error->kind = HMATH_MATH_DOMAIN_ERROR;
    error->message = message;
    error->message_length = sizeof message;
    return HMATH_MATH_ERROR;
}
int main(void) {
    CHECK(hmath_init() == HMATH_OK);
    hmath_value *zero = NULL, *one = NULL, *minus = NULL, *values = NULL, *p = NULL;
    CHECK(hmath_value_rational(NULL, "0", "1", &zero) == HMATH_OK);
    CHECK(hmath_value_rational(NULL, "1", "1", &one) == HMATH_OK);
    CHECK(hmath_value_rational(NULL, "-1", "1", &minus) == HMATH_OK);
    const hmath_value *items[] = {minus, zero, one, zero};
    CHECK(hmath_value_list(NULL, items, 4, &values) == HMATH_OK);
    CHECK(hmath_polynomial_polynomial(NULL, zero, values, &p) == HMATH_OK);
    int kind = -1, dtype = -1;
    size_t count = 99;
    CHECK(hmath_value_info(p, &kind, &dtype, &count) == HMATH_OK && kind == 6 && dtype == 3 &&
          count == 3);
    hmath_value_release(values);
    hmath_value_release(minus);
    hmath_value_release(one);
    hmath_value *matrix = NULL, *squared = NULL;
    CHECK(hmath_polynomial_companion_matrix(NULL, p, &matrix) == HMATH_OK);
    hmath_value_release(p);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    CHECK(hmath_value_info(matrix, &kind, &dtype, &count) == HMATH_OK && kind == 9 && dtype == 3 &&
          count == 4);
    CHECK(hmath_matrix_value_multiply_checked(NULL, matrix, matrix, &squared) == HMATH_OK);
    CHECK(hmath_matrix_value_to_list(NULL, squared, &values) == HMATH_OK);
    const char *expected[] = {"1", "0", "0", "1"};
    for (ptrdiff_t i = 0; i < 4; i++) {
        hmath_value *value = NULL;
        char *n = NULL, *d = NULL;
        CHECK(hmath_value_item(NULL, values, i, &value) == HMATH_OK);
        CHECK(hmath_value_get_exact(value, &n, &d) == HMATH_OK && strcmp(n, expected[i]) == 0 &&
              strcmp(d, "1") == 0);
        hmath_value_string_free(n);
        hmath_value_string_free(d);
        hmath_value_release(value);
    }
    hmath_value_release(values);
    hmath_value_release(squared);
    hmath_value *bad = NULL, *index = NULL, *result = (hmath_value *)(uintptr_t)1;
    CHECK(hmath_value_index(NULL, -1, &bad) == HMATH_OK);
    CHECK(hmath_value_index(NULL, 0, &index) == HMATH_OK);
    CHECK(hmath_matrix_value_at(NULL, matrix, bad, index, &values) == HMATH_OK);
    CHECK(hmath_value_info(values, &kind, &dtype, &count) == HMATH_OK && kind == 0);
    hmath_value_release(values);
    CHECK(hmath_matrix_value_at_checked(NULL, matrix, bad, index, &result) == HMATH_MATH_ERROR &&
          result == (hmath_value *)(uintptr_t)1);
    hmath_math_error error;
    CHECK(hmath_last_math_error(&error) == 1 && error.kind == HMATH_MATH_INDEX_OUT_OF_BOUNDS &&
          error.details[0] == 2 && error.details[2] == -1);
    hmath_value_release(matrix);
    hmath_value_release(bad);
    hmath_value *maximum = NULL;
    CHECK(hmath_value_index(NULL, PTRDIFF_MAX, &maximum) == HMATH_OK);
    CHECK(hmath_matrix_value_zero_matrix_checked(NULL, zero, index, maximum, &matrix) == HMATH_OK);
    CHECK(hmath_matrix_value_shape(NULL, matrix, &values) == HMATH_OK);
    hmath_value *maximumInput = maximum;
    CHECK(hmath_value_item(NULL, values, 1, &maximum) == HMATH_OK);
    ptrdiff_t dimension = -1;
    CHECK(hmath_value_get_index(maximum, &dimension) == HMATH_OK && dimension == PTRDIFF_MAX);
    hmath_value_release(maximum);
    hmath_value_release(values);
    hmath_value_release(matrix);
    /* Callback structured error retains constructor, Unicode and embedded NUL. */
    CHECK(hmath_polynomial_chebyshev_approximation(NULL, 2, fail_callback, NULL, &result) ==
              HMATH_MATH_ERROR &&
          result == (hmath_value *)(uintptr_t)1);
    CHECK(hmath_last_math_error(&error) == 1 && error.kind == HMATH_MATH_DOMAIN_ERROR &&
          error.message_length == 4 && memcmp(error.message, "x\0\xce\xb1", 4) == 0);
    hmath_value_release(zero);
    hmath_value_release(index);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY); /* maximum input was independently owned */
    hmath_value_release(maximumInput);
    CHECK(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
