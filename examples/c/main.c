// SPDX-License-Identifier: MPL-2.0

#include <stdio.h>

#include "hmath.h"

int main(void) {
    if (hmath_init() != 0) {
        fprintf(stderr, "Failed to initialize HMath\n");
        return 1;
    }

    double values[] = {10.0, 20.0, 30.0, 40.0};

    double sum = hmath_add_f64(10.0, 20.0);
    double average = hmath_mean_f64(values, 4);
    long long factorial = hmath_factorial(10);

    printf("HMath C FFI Test\n");
    printf("Add: %f\n", sum);
    printf("Mean: %f\n", average);
    printf("Factorial: %lld\n", factorial);

    hmath_shutdown();

    return 0;
}
