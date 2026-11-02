/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_numeric.h"
#include "hmath_optimization.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK(test)                                                                                \
    do {                                                                                           \
        if (!(test)) {                                                                             \
            fprintf(stderr, "%s:%d: %s (%s)\n", __FILE__, __LINE__, #test,                         \
                    hmath_last_error_message());                                                   \
            exit(1);                                                                               \
        }                                                                                          \
    } while (0)

int main(void) {
    double output = 123.0;
    CHECK(hmath_scalar_hypot_f64(NULL, 3, 4, &output) == HMATH_RUNTIME_ERROR);
    CHECK(output == 123.0);
    CHECK(hmath_init() == HMATH_INIT_OK);
    CHECK(hmath_scalar_divide_f64(NULL, 1, 0, &output) == HMATH_MATH_ERROR);
    CHECK(output == 123.0);
    CHECK(strcmp(hmath_last_error_message(), "DomainError \"division by zero\"") == 0);
    CHECK(hmath_constants_infinity_f64(NULL, &output) == HMATH_OK && isinf(output));
    CHECK(hmath_scalar_add_f64(NULL, INFINITY, 1, &output) == HMATH_OK && isinf(output));
    CHECK(hmath_scalar_hypot_f64(NULL, 3, 4, NULL) == HMATH_INVALID_ARGUMENT);

    float single = 123.0f;
    CHECK(hmath_scalar_add_f32(NULL, 16777216.0f, 1.0f, &single) == HMATH_OK);
    CHECK(single == 16777216.0f);
    CHECK(hmath_scalar_add_f64(NULL, 16777216.0, 1.0, &output) == HMATH_OK);
    CHECK(output == 16777217.0);

    double values[] = {1, 2, 3}, prefix[] = {99, 99, 99, 99, 99};
    CHECK(hmath_scalar_prefix_sum_f64(NULL, values, 3, prefix, 3) == HMATH_BOUNDS_ERROR);
    CHECK(prefix[0] == 99 && prefix[3] == 99 && prefix[4] == 99);
    CHECK(hmath_scalar_prefix_sum_f64(NULL, values, 3, prefix, 4) == HMATH_OK);
    CHECK(prefix[0] == 0 && prefix[1] == 1 && prefix[2] == 3 && prefix[3] == 6 && prefix[4] == 99);
    CHECK(hmath_scalar_prefix_sum_f64(NULL, NULL, 0, NULL, 0) == HMATH_BOUNDS_ERROR);
    CHECK(hmath_scalar_prefix_sum_f64(NULL, NULL, 0, prefix, 1) == HMATH_OK && prefix[0] == 0);

    char *integer = NULL;
    CHECK(hmath_basic_factorial(NULL, "100", &integer) == HMATH_OK);
    CHECK(strlen(integer) == 158 && strncmp(integer, "933262154439", 12) == 0);
    hmath_numeric_string_free(integer);
    integer = NULL;
    CHECK(hmath_basic_factorial(NULL, "-1", &integer) == HMATH_HASKELL_EXCEPTION);
    CHECK(integer == NULL);
    CHECK(hmath_basic_factorial(NULL, "1oops", &integer) == HMATH_INVALID_ARGUMENT);
    CHECK(integer == NULL);

    hmath_context *context = NULL;
    CHECK(hmath_context_create(&context) == HMATH_OK);
    hmath_context_cancel(context);
    output = 99;
    CHECK(hmath_scalar_hypot_f64(context, 3, 4, &output) == HMATH_CANCELLED && output == 99);
    hmath_context_release(context);

    hmath_optimizer_state *state = NULL, *next = NULL;
    CHECK(hmath_initialize_optimizer(NULL, -1, &state) == HMATH_MATH_ERROR);
    CHECK(state == NULL);
    CHECK(hmath_initialize_optimizer(NULL, 1, &state) == HMATH_OK);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    double parameter = 1, gradient = 2, updated = 99;
    CHECK(hmath_optimizer_step(NULL, HMATH_ADAM, 0.1, state, &parameter, 1, &gradient, 0, &updated,
                               1, &next) == HMATH_MATH_ERROR);
    CHECK(updated == 99 && next == NULL);
    CHECK(hmath_optimizer_step(NULL, HMATH_ADAM, 0.1, state, &parameter, 1, &gradient, 1, &updated,
                               0, &next) == HMATH_BOUNDS_ERROR);
    CHECK(updated == 99 && next == NULL);
    CHECK(hmath_optimizer_step(NULL, HMATH_ADAM, 0.1, state, &parameter, 1, &gradient, 1, &updated,
                               1, &next) == HMATH_OK);
    CHECK(fabs(updated - 0.9) < 1e-8);
    hmath_optimizer_state_retain(state);
    hmath_optimizer_state_release(state);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_optimizer_state_release(state);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_optimizer_state_release(next);
    hmath_optimizer_state_release(NULL);
    CHECK(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
