// SPDX-License-Identifier: MPL-2.0

/* Test-only ABI implementation: corrupt exactly one numerical export. */
#include <math.h>
#include <stdio.h>

#include "hmath.h"

#if !defined(HMATH_TEST_FAULT) || HMATH_TEST_FAULT < 1 || HMATH_TEST_FAULT > 4
#error "Select one test fault: addition=1, factorial=2, mean=3, dot=4"
#endif

int hmath_init(void) {
    return HMATH_INIT_OK;
}

void hmath_shutdown(void) {
    fputs("HMATH_TEST_SHUTDOWN\n", stderr);
}

double hmath_add_f64(double a, double b) {
    if (HMATH_TEST_FAULT == 1) {
        return NAN;
    }
    return a + b;
}

long long hmath_factorial(int n) {
    if (n < 0 || n > 20) {
        return -1;
    }

    long long result = 1;
    for (int i = 2; i <= n; ++i) {
        result *= i;
    }
    return result + (HMATH_TEST_FAULT == 2 && n == 10 ? 1 : 0);
}

double hmath_mean_f64(const double *values, size_t count) {
    if (values == NULL || count == 0) {
        return NAN;
    }

    double total = 0;
    for (size_t i = 0; i < count; ++i) {
        total += values[i];
    }
    return total / count + (HMATH_TEST_FAULT == 3 ? 1.0 : 0.0);
}

double hmath_dot_f64(const double *a, const double *b, size_t count) {
    if (count == 0) {
        return 0;
    }
    if (a == NULL || b == NULL) {
        return NAN;
    }
    if (HMATH_TEST_FAULT == 4) {
        return INFINITY;
    }

    double result = 0;
    for (size_t i = 0; i < count; ++i) {
        result += a[i] * b[i];
    }
    return result;
}
