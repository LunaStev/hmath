// SPDX-License-Identifier: MPL-2.0

#include <limits.h>
#include <math.h>
#include <stdio.h>

#include "hmath.h"

static int check_finite(const char *name, double actual, double expected) {
    double scale = fabs(expected) > 1.0 ? fabs(expected) : 1.0;

    if (!isfinite(actual) || fabs(actual - expected) > 1e-12 * scale) {
        fprintf(stderr, "%s: expected %.17g, got %.17g\n", name, expected, actual);
        return 1;
    }
    return 0;
}

static int check_integer(const char *name, long long actual, long long expected) {
    if (actual != expected) {
        fprintf(stderr, "%s: expected %lld, got %lld\n", name, expected, actual);
        return 1;
    }
    return 0;
}

static int check_nan(const char *name, double actual) {
    if (!isnan(actual)) {
        fprintf(stderr, "%s: expected NaN, got %.17g\n", name, actual);
        return 1;
    }
    return 0;
}

int main(void) {
    if (hmath_init() != 0) {
        fprintf(stderr, "Failed to initialize HMath\n");
        return 1;
    }

    double values[] = {10.25, 20.5, 30.75, 40.0};
    double a[] = {1.5, -2.25, 3.75};
    double b[] = {2.0, 0.5, -4.0};
    int failures = 0;

    double sum = hmath_add_f64(10.25, 20.5);
    double average = hmath_mean_f64(values, 4);
    long long factorial = hmath_factorial(10);
    double dot = hmath_dot_f64(a, b, 3);

    printf("HMath C FFI Test\n");
    printf("Add: %f\n", sum);
    printf("Mean: %f\n", average);
    printf("Factorial: %lld\n", factorial);
    printf("Dot: %f\n", dot);

    failures += check_finite("addition", sum, 30.75);
    failures += check_integer("factorial(0)", hmath_factorial(0), 1);
    failures += check_integer("factorial(10)", factorial, 3628800);
    failures += check_integer("factorial(20)", hmath_factorial(20), 2432902008176640000LL);
    failures += check_integer("factorial(-1)", hmath_factorial(-1), -1);
    failures += check_integer("factorial(21)", hmath_factorial(21), -1);
    failures += check_integer("factorial(INT_MIN)", hmath_factorial(INT_MIN), -1);
    failures += check_integer("factorial(INT_MAX)", hmath_factorial(INT_MAX), -1);

    failures += check_finite("mean", average, 25.375);
    failures += check_nan("mean(NULL, 4)", hmath_mean_f64(NULL, 4));
    failures += check_nan("mean(values, 0)", hmath_mean_f64(values, 0));
    failures += check_nan("mean(NULL, 0)", hmath_mean_f64(NULL, 0));

    failures += check_finite("dot", dot, -13.125);
    failures += check_finite("dot(a, b, 0)", hmath_dot_f64(a, b, 0), 0.0);
    failures += check_finite("dot(NULL, b, 0)", hmath_dot_f64(NULL, b, 0), 0.0);
    failures += check_finite("dot(a, NULL, 0)", hmath_dot_f64(a, NULL, 0), 0.0);
    failures += check_finite("dot(NULL, NULL, 0)", hmath_dot_f64(NULL, NULL, 0), 0.0);
    failures += check_nan("dot(NULL, b, 3)", hmath_dot_f64(NULL, b, 3));
    failures += check_nan("dot(a, NULL, 3)", hmath_dot_f64(a, NULL, 3));
    failures += check_nan("dot(NULL, NULL, 3)", hmath_dot_f64(NULL, NULL, 3));

    hmath_shutdown();

    if (failures != 0) {
        fprintf(stderr, "%d HMath C FFI check(s) failed\n", failures);
        return 1;
    }
    printf("All HMath C FFI checks passed\n");
    return 0;
}
