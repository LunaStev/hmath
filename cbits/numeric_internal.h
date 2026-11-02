/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_NUMERIC_INTERNAL_H
#define HMATH_NUMERIC_INTERNAL_H
#include "native_internal.h"
#include <stdint.h>

/* Decimal transport for arbitrary-precision Integer, not an arithmetic limit. */
static inline int hm_decimal(const char *value) {
    if (!value)
        return 0;
    if (*value == '-')
        ++value;
    if (!*value)
        return 0;
    for (; *value; ++value)
        if (*value < '0' || *value > '9')
            return 0;
    return 1;
}
#endif
