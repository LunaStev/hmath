/* SPDX-License-Identifier: MPL-2.0 */
/* Link with cbits/native.c and this deterministic boundary spy, without GHC.
 * These checks verify input borrowing and result ownership, not numerics. */
#include "native_internal.h"
#include <math.h>
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
static unsigned calls, freed;
static int failure;
static const double *seen_a, *seen_b;
static double *seen_output;
static double observed[4];
static hmath_context *cancel_after_kernel;
hmath_status hm_enter(hmath_context *context) {
    if (hm_cancelled(context))
        return hm_error(HMATH_CANCELLED, "cancelled");
    ++calls;
    return HMATH_OK;
}
void hm_leave(void) {
    CHECK(calls > 0);
    --calls;
}
int hm_haskell_kernel(int op, const double *a, const double *b, size_t n, size_t rows, size_t inner,
                      size_t columns, double *out) {
    seen_a = a;
    seen_b = b;
    seen_output = out;
    for (size_t i = 0; i < n && i < 4; ++i)
        observed[i] = a[i];
    if (cancel_after_kernel)
        hmath_context_cancel(cancel_after_kernel);
    if (failure)
        return failure;
    if (op == 1 || op == 2) {
        *out = 0;
        for (size_t i = 0; i < n; ++i)
            *out += op == 1 ? a[i] : a[i] * b[i];
    } else if (op == 3) {
        for (size_t i = 0; i < n; ++i)
            out[i] = a[i] + b[i];
    } else if (op == 4) {
        for (size_t i = 0; i < rows; ++i)
            for (size_t j = 0; j < columns; ++j) {
                double value = 0;
                for (size_t k = 0; k < inner; ++k)
                    value += a[i * inner + k] * b[k * columns + j];
                out[i * columns + j] = value;
            }
    } else
        CHECK(0);
    return 0;
}
static void released(void *user, const double *data) {
    CHECK(user == &freed);
    CHECK(data != NULL);
    ++freed;
}
int main(void) {
    double plain[] = {1, 2, 3, 4}, strided[] = {1, 99, 2, 99, 3, 99, 4};
    size_t shape[] = {2, 2}, strides[] = {4, 2};
    hmath_tensor *a = NULL, *b = NULL, *sparse = NULL, *result = NULL;
    CHECK(hmath_tensor_borrow(plain, 4, shape, NULL, 2, released, &freed, &a) == HMATH_OK);
    CHECK(hmath_tensor_borrow(plain, 4, shape, NULL, 2, released, &freed, &b) == HMATH_OK);
    CHECK(hmath_tensor_borrow(strided, 7, shape, strides, 2, NULL, NULL, &sparse) == HMATH_OK);
    double value = 0;
    CHECK(hmath_tensor_sum(NULL, a, &value) == HMATH_OK && value == 10);
    CHECK(seen_a == plain && seen_b == NULL && calls == 0 && freed == 0);
    CHECK(hmath_tensor_dot(NULL, a, b, &value) == HMATH_OK && value == 30);
    CHECK(seen_a == plain && seen_b == plain && calls == 0);
    CHECK(hmath_tensor_sum(NULL, sparse, &value) == HMATH_OK && value == 10);
    CHECK(seen_a != strided && observed[0] == 1 && observed[1] == 2 && observed[2] == 3 &&
          observed[3] == 4);
    CHECK(hmath_tensor_add(NULL, a, b, &result) == HMATH_OK);
    const double *data = NULL;
    size_t count = 0;
    CHECK(hmath_tensor_data(result, &data, &count) == HMATH_OK && count == 4);
    CHECK(data == seen_output && data[0] == 2 && data[3] == 8);
    CHECK(seen_a == plain && seen_b == plain && (uintptr_t)data % 64 == 0);
    hmath_tensor_release(result);
    result = NULL;
    CHECK(hmath_tensor_matmul(NULL, sparse, b, &result) == HMATH_OK);
    CHECK(seen_a != strided && seen_b == plain);
    CHECK(hmath_tensor_data(result, &data, &count) == HMATH_OK && data == seen_output);
    CHECK(data[0] == 7 && data[1] == 10 && data[2] == 15 && data[3] == 22);
    hmath_tensor_release(result);
    result = NULL;
    failure = HMATH_OVERFLOW;
    CHECK(hmath_tensor_add(NULL, a, b, &result) == HMATH_OVERFLOW && result == NULL && calls == 0);
    failure = 0;
    CHECK(hmath_context_create(&cancel_after_kernel) == HMATH_OK);
    CHECK(hmath_tensor_matmul(cancel_after_kernel, a, b, &result) == HMATH_CANCELLED &&
          result == NULL && calls == 0);
    hmath_context_release(cancel_after_kernel);
    cancel_after_kernel = NULL;
    /* Empty borrowed storage may be NULL; synchronous kernels do not read it. */
    hmath_tensor *empty = NULL;
    size_t empty_shape[] = {0};
    CHECK(hmath_tensor_borrow(NULL, 0, empty_shape, NULL, 1, NULL, NULL, &empty) == HMATH_OK);
    CHECK(hmath_tensor_sum(NULL, empty, &value) == HMATH_OK && value == 0 && seen_a == NULL);
    CHECK(hmath_tensor_add(NULL, empty, empty, &result) == HMATH_OK);
    CHECK(hmath_tensor_data(result, &data, &count) == HMATH_OK && count == 0 &&
          data == seen_output);
    hmath_tensor_release(result);
    hmath_tensor_release(empty);
    hmath_tensor *view = NULL;
    size_t flat[] = {4};
    CHECK(hmath_tensor_reshape(a, flat, 1, &view) == HMATH_OK);
    hmath_tensor_release(a);
    CHECK(freed == 0);
    hmath_tensor_release(view);
    CHECK(freed == 1);
    hmath_tensor_release(b);
    CHECK(freed == 2);
    hmath_tensor_release(sparse);
    CHECK(calls == 0);
    return 0;
}
