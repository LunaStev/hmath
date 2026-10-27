// SPDX-License-Identifier: MPL-2.0

#ifndef HMATH_H
#define HMATH_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

int hmath_init(void);
void hmath_shutdown(void);

double hmath_add_f64(double a, double b);

long long hmath_factorial(int n);

double hmath_mean_f64(const double *values, size_t count);

double hmath_dot_f64(
    const double *a,
    const double *b,
    size_t count
);

#ifdef __cplusplus
}
#endif

#endif
