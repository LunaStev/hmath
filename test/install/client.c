/* SPDX-License-Identifier: MPL-2.0 */
#include <hmath.h>
#include <math.h>
int main(void) {
    const double a[] = {1, 2, 3};
    if (hmath_init() != HMATH_INIT_OK)
        return 1;
    const double result = hmath_dot_f64(a, a, 3);
    hmath_shutdown();
    return fabs(result - 14) < 1e-12 ? 0 : 2;
}
