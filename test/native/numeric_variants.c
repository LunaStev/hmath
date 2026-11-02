/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_numeric.h"
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

int main(void) {
    CHECK(hmath_init() == HMATH_INIT_OK);
    int8_t signed_result = 55;
    CHECK(hmath_scalar_add_i8(NULL, INT8_MAX, 1, &signed_result) == HMATH_OK);
    CHECK(signed_result == INT8_MIN);
    CHECK(hmath_scalar_saturating_add_i8(NULL, INT8_MAX, 1, &signed_result) == HMATH_OK);
    CHECK(signed_result == INT8_MAX);
    signed_result = 55;
    CHECK(hmath_scalar_checked_add_i8(NULL, INT8_MAX, 1, &signed_result) == HMATH_MATH_ERROR);
    CHECK(signed_result == 55);
    CHECK(strcmp(hmath_last_error_message(), "DomainError \"integer overflow\"") == 0);
    uint64_t unsigned_result = 99;
    CHECK(hmath_scalar_add_u64(NULL, UINT64_MAX, 1, &unsigned_result) == HMATH_OK);
    CHECK(unsigned_result == 0);

    char *numerator = NULL, *denominator = NULL;
    CHECK(hmath_scalar_add_rational(NULL, "1", "3", "1", "7", &numerator, &denominator) ==
          HMATH_OK);
    CHECK(strcmp(numerator, "10") == 0 && strcmp(denominator, "21") == 0);
    hmath_numeric_string_free(numerator);
    hmath_numeric_string_free(denominator);
    numerator = denominator = NULL;
    CHECK(hmath_scalar_add_rational(NULL, "1", "0", "1", "7", &numerator, &denominator) ==
          HMATH_INVALID_ARGUMENT);
    CHECK(numerator == NULL && denominator == NULL);
    CHECK(hmath_scalar_positive_modulo(NULL, "-7", "5", &numerator) == HMATH_OK);
    CHECK(strcmp(numerator, "3") == 0);
    hmath_numeric_string_free(numerator);

    /* Counts describe logical rationals, not their numerator/denominator pairs. */
    const char *input[] = {"1", "3", "1", "7"};
    char **output = NULL;
    size_t count = 999;
    CHECK(hmath_scalar_prefix_sum_rational(NULL, input, 2, &output, &count) == HMATH_OK);
    CHECK(count == 3);
    CHECK(strcmp(output[0], "0") == 0 && strcmp(output[1], "1") == 0);
    CHECK(strcmp(output[4], "10") == 0 && strcmp(output[5], "21") == 0);
    for (size_t i = 0; i < 2 * count; ++i)
        hmath_numeric_string_free(output[i]);
    hmath_numeric_buffer_free(output);

    /* Original Haskell dot is bilinear, with no conjugation for Complex. */
    const double left[] = {1, 2}, right[] = {3, 4};
    double real = 99, imaginary = 99;
    CHECK(hmath_linear_dot_c128(NULL, left, 1, right, 1, &real, &imaginary) == HMATH_OK);
    CHECK(real == -5 && imaginary == 10);
    CHECK(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
