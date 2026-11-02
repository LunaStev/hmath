/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_execution.h"
#include <stdio.h>

int main(void) {
    double a[] = {1, 2, 3, 4}, b[] = {1, 0, 0, 1}, c[] = {0, 0, 0, 0};
    hmath_execution *execution = NULL;
    hmath_execution_view av = {a, 4, 2, 2, 2}, bv = {b, 4, 2, 2, 2};
    hmath_execution_output cv = {c, 4, 2, 2, 2};
    if (hmath_init() != 0 || hmath_execution_create(NULL, &execution) != HMATH_OK ||
        hmath_execution_gemm_f64(execution, NULL, 1, &av, &bv, 0, &cv) != HMATH_OK) {
        fprintf(stderr, "%s\n", hmath_last_error_message());
        return 1;
    }
    if (c[0] != 1 || c[1] != 2 || c[2] != 3 || c[3] != 4)
        return 1;
    hmath_execution_release(execution);
    return hmath_runtime_shutdown() == HMATH_OK ? 0 : 1;
}
