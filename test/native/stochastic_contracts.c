/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_stochastic.h"
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
static hmath_status checked_failure(const hmath_value *input, void *userdata, hmath_value **out,
                                    hmath_math_error *error) {
    (void)input;
    (void)userdata;
    (void)out;
    static const char message[] = {'s', '\0', (char)0xce, (char)0xb1};
    error->kind = HMATH_MATH_NON_CONVERGENCE;
    error->details[0] = 7;
    error->message = message;
    error->message_length = sizeof message;
    return HMATH_MATH_ERROR;
}
int main(void) {
    CHECK(hmath_init() == HMATH_OK);
    hmath_value *generator = NULL, *seed = NULL, *state = NULL, *pair = NULL, *word = NULL,
                *next = NULL;
    CHECK(hmath_stochastic_random_new_pcg32(NULL, &generator) == HMATH_OK);
    CHECK(hmath_value_integral(NULL, HMATH_COEFFICIENT_UINT64, "18446744073709551615", &seed) ==
          HMATH_OK);
    CHECK(hmath_stochastic_random_seed_rng(NULL, generator, seed, &state) == HMATH_OK);
    hmath_value_release(generator);
    hmath_value_release(seed);
    CHECK(hmath_stochastic_random_next_word64(NULL, state, &pair) == HMATH_OK);
    CHECK(hmath_value_item(NULL, pair, 0, &word) == HMATH_OK);
    CHECK(hmath_value_item(NULL, pair, 1, &next) == HMATH_OK);
    hmath_value_release(pair);
    hmath_value_release(state);
    int kind = -1, dtype = -1;
    size_t count = 99;
    CHECK(hmath_value_info(word, &kind, &dtype, &count) == HMATH_OK && kind == 1 && dtype == 13);
    char *numerator = NULL, *denominator = NULL;
    CHECK(hmath_value_get_exact(word, &numerator, &denominator) == HMATH_OK &&
          strlen(numerator) <= 20 && strcmp(denominator, "1") == 0);
    hmath_value_string_free(numerator);
    hmath_value_string_free(denominator);
    hmath_value_release(word);
    hmath_value *serialized = NULL, *restored = NULL, *same = NULL;
    CHECK(hmath_stochastic_random_serialize_rng(NULL, next, &serialized) == HMATH_OK);
    CHECK(hmath_stochastic_random_restore_rng(NULL, serialized, &restored) == HMATH_OK);
    CHECK(hmath_stochastic_equal(NULL, next, restored, &same) == HMATH_OK);
    int equal = 0;
    CHECK(hmath_value_get_boolean(same, &equal) == HMATH_OK && equal == 1);
    hmath_value_release(same);
    hmath_value_release(serialized);
    hmath_value_release(next);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_value *callback = NULL, *out = (hmath_value *)(uintptr_t)1;
    CHECK(hmath_linear_callback(NULL, checked_failure, NULL, &callback) == HMATH_OK);
    CHECK(hmath_stochastic_random_inverse_transform(NULL, callback, restored, &out) ==
              HMATH_MATH_ERROR &&
          out == (hmath_value *)(uintptr_t)1);
    hmath_math_error error;
    CHECK(hmath_last_math_error(&error) == 1 && error.kind == HMATH_MATH_NON_CONVERGENCE &&
          error.details[0] == 7 && error.message_length == 4 &&
          memcmp(error.message, "s\0\xce\xb1", 4) == 0);
    hmath_value_release(callback);
    hmath_value_release(restored);
    CHECK(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
