/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_error.h"
#include "hmath_spectral.h"
#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <string.h>

int main(void) {
    hmath_value *direction = NULL, *algorithm = NULL, *count = NULL, *plan = NULL;
    hmath_context *context = NULL;
    hmath_math_error error;
    double buffer[] = {1, 0, 2, 0, 3, 0, 4, 0};
    double before[8];
    assert(hmath_init() == HMATH_OK);
    assert(hmath_fourier_value_forward(NULL, &direction) == HMATH_OK);
    assert(hmath_fourier_value_automatic(NULL, &algorithm) == HMATH_OK);
    assert(hmath_value_index(NULL, 4, &count) == HMATH_OK);
    assert(hmath_fourier_value_plan_fft(NULL, direction, algorithm, count, &plan) == HMATH_OK);
    hmath_value_release(direction);
    hmath_value_release(algorithm);
    hmath_value_release(count);
    memcpy(before, buffer, sizeof buffer);
    assert(hmath_fourier_value_fft_in_place(NULL, plan, buffer, 3) == HMATH_MATH_ERROR);
    assert(memcmp(buffer, before, sizeof buffer) == 0);
    assert(hmath_last_math_error(&error));
    assert(hmath_fourier_value_fft_in_place(NULL, plan, NULL, 4) == HMATH_MATH_ERROR);
    buffer[2] = NAN;
    memcpy(before, buffer, sizeof buffer);
    assert(hmath_fourier_value_fft_in_place(NULL, plan, buffer, 4) == HMATH_MATH_ERROR);
    assert(memcmp(buffer, before, sizeof buffer) == 0);
    buffer[2] = 2;
    assert(hmath_context_create(&context) == HMATH_OK);
    hmath_context_cancel(context);
    memcpy(before, buffer, sizeof buffer);
    assert(hmath_fourier_value_fft_in_place(context, plan, buffer, 4) == HMATH_CANCELLED);
    assert(memcmp(buffer, before, sizeof buffer) == 0);
    hmath_context_release(context);
    assert(hmath_fourier_value_fft_in_place(NULL, plan, buffer, 4) == HMATH_OK);
    assert(fabs(buffer[0] - 10) < 1e-12);
    assert(fabs(buffer[2] + 2) < 1e-12 && fabs(buffer[3] - 2) < 1e-12);
    assert(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_value_release(plan);
    assert(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
