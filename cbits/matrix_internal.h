/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_MATRIX_INTERNAL_H
#define HMATH_MATRIX_INTERNAL_H
#include "native_internal.h"
/* Shared private layout; every stable pointer owns one runtime reservation. */
struct hmath_dense_object {
    atomic_size_t refs;
    unsigned kind, precision;
    void *stable;
};
#endif
