/* SPDX-License-Identifier: MPL-2.0 */
/* Compile and run as both C99 and C++17 against the same public ABI. */
#include "hmath_optimization.h"
#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <string.h>

static double number(const hmath_value *value) {
    double real, imaginary;
    assert(hmath_value_get_f64(value, &real, &imaginary) == HMATH_OK);
    assert(imaginary == 0);
    return real;
}
static hmath_value *scalar(double real) {
    hmath_value *value = NULL;
    assert(hmath_value_f64(NULL, real, &value) == HMATH_OK);
    return value;
}
static hmath_status objective(const hmath_value *argument, void *userdata, hmath_value **out,
                              hmath_math_error *error) {
    (void)error;
    hmath_value *item = NULL;
    assert(hmath_value_item(NULL, argument, 0, &item) == HMATH_OK);
    double x = number(item);
    hmath_value_release(item);
    unsigned *calls = (unsigned *)userdata;
    ++*calls;
    return hmath_value_f64(NULL, x * x, out);
}
static hmath_status fail(const hmath_value *argument, void *userdata, hmath_value **out,
                         hmath_math_error *error) {
    (void)argument;
    (void)userdata;
    (void)out;
    static const char message[] = "domain\0full\xe2\x98\x83";
    error->kind = HMATH_MATH_DOMAIN_ERROR;
    error->message = message;
    error->message_length = sizeof message - 1;
    return HMATH_MATH_ERROR;
}
static hmath_status identity(const hmath_value *argument, void *userdata, hmath_value **out,
                             hmath_math_error *error) {
    (void)userdata;
    (void)error;
    hmath_value_retain((hmath_value *)argument);
    *out = (hmath_value *)argument;
    return HMATH_OK;
}
int main(void) {
    assert(hmath_init() == HMATH_INIT_OK);
    unsigned calls = 0;
    hmath_value *options = NULL, *method = NULL, *function = NULL, *lower = scalar(-2),
                *upper = scalar(3);
    assert(hmath_optimization_default_optimize_options(NULL, &options) == HMATH_OK);
    assert(hmath_optimization_brent_search_create(NULL, &method) == HMATH_OK);
    assert(hmath_optimization_callback(NULL, 0, objective, &calls, &function) == HMATH_OK);
    hmath_value *result = NULL, *point = NULL, *item = NULL;
    assert(hmath_optimization_minimize_scalar(NULL, method, options, function, lower, upper,
                                              &result) == HMATH_OK);
    assert(calls > 1);
    assert(hmath_optimization_opt_point(NULL, result, &point) == HMATH_OK);
    assert(hmath_value_item(NULL, point, 0, &item) == HMATH_OK);
    assert(fabs(number(item)) < 1e-7);
    hmath_value_release(item);
    hmath_value_release(point);
    hmath_value_release(result);

    hmath_value *bad = NULL;
    assert(hmath_optimization_callback(NULL, 0, fail, NULL, &bad) == HMATH_OK);
    result = (hmath_value *)(uintptr_t)0x1234;
    assert(hmath_optimization_minimize_scalar(NULL, method, options, bad, lower, upper, &result) ==
           HMATH_MATH_ERROR);
    assert(result == (hmath_value *)(uintptr_t)0x1234);
    hmath_math_error error;
    assert(hmath_last_math_error(&error) == 1);
    assert(error.kind == HMATH_MATH_DOMAIN_ERROR);
    assert(error.message_length == sizeof "domain\0full\xe2\x98\x83" - 1);
    assert(memcmp(error.message, "domain\0full\xe2\x98\x83", error.message_length) == 0);
    assert(hmath_last_math_error(&error) == 1); /* a query does not consume */
    hmath_value *weight = scalar(1), *weights = NULL, *functions = NULL, *derived = NULL;
    const hmath_value *items[1] = {weight};
    assert(hmath_value_list(NULL, items, 1, &weights) == HMATH_OK);
    assert(hmath_last_math_error(&error) == 0); /* a checked success clears */
    items[0] = function;
    assert(hmath_value_list(NULL, items, 1, &functions) == HMATH_OK);
    assert(hmath_optimization_weighted_objective(NULL, weights, functions, &derived) == HMATH_OK);
    hmath_value_release(functions);
    hmath_value_release(function); /* derived owns its Haskell function closure */
    const hmath_value *arg_items[1] = {upper};
    hmath_value *args = NULL, *answer = NULL;
    assert(hmath_value_list(NULL, arg_items, 1, &args) == HMATH_OK);
    const hmath_value *argv[1] = {args};
    assert(hmath_optimization_function_apply(NULL, derived, argv, 1, &answer) == HMATH_OK);
    assert(number(answer) == 9);
    hmath_value_release(answer);

    /* A callback may return a borrowed input after explicitly retaining it. */
    hmath_value *gradient = NULL, *gradients = NULL, *batch = NULL;
    assert(hmath_optimization_callback(NULL, 1, identity, NULL, &gradient) == HMATH_OK);
    items[0] = gradient;
    assert(hmath_value_list(NULL, items, 1, &gradients) == HMATH_OK);
    assert(hmath_optimization_mini_batch_gradient(NULL, gradients, &batch) == HMATH_OK);
    assert(hmath_optimization_function_apply(NULL, batch, argv, 1, &answer) == HMATH_OK);
    assert(hmath_value_item(NULL, answer, 0, &item) == HMATH_OK);
    assert(number(item) == 3);
    hmath_value_release(item);
    hmath_value_release(answer);
    assert(hmath_runtime_shutdown() == HMATH_BUSY);

    /* Old state handles keep their ABI and interoperate with Value states. */
    hmath_optimizer_state *state = NULL, *exported = NULL;
    hmath_value *boxed = NULL;
    assert(hmath_initialize_optimizer(NULL, 1, &state) == HMATH_OK);
    assert(hmath_optimization_state_import(NULL, state, &boxed) == HMATH_OK);
    hmath_optimizer_state_release(state);
    assert(hmath_optimization_state_export(NULL, boxed, &exported) == HMATH_OK);
    hmath_optimizer_state_release(exported);
    hmath_value_release(boxed);
    hmath_value_release(gradient);
    hmath_value_release(gradients);
    hmath_value_release(batch);
    hmath_value_release(args);
    hmath_value_release(derived);
    hmath_value_release(weights);
    hmath_value_release(weight);
    hmath_value_release(bad);
    hmath_value_release(method);
    hmath_value_release(options);
    hmath_value_release(lower);
    hmath_value_release(upper);
    assert(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
