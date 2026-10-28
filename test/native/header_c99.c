/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath.h"
#include "hmath_dlpack.h"
int main(void) {
    double result;
    return hmath_init() || hmath_abi_version() != HMATH_ABI_VERSION ||
           hmath_scalar_add(NULL, 2, 3, &result) || result != 5 || hmath_runtime_shutdown();
}
