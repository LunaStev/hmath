/* SPDX-License-Identifier: MPL-2.0 */
#include <stdint.h>
#if defined(_WIN32)
__declspec(dllexport)
#endif
uint32_t hmath_abi_version(void) {
    return 2;
}
