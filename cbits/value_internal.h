/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_VALUE_INTERNAL_H
#define HMATH_VALUE_INTERNAL_H
#include "hmath_value.h"
#include "native_internal.h"
struct hmath_value {
    atomic_size_t refs;
    void *stable;
    int kind, dtype;
    size_t count;
};
/* begin reserves the runtime and allocates a private output owner. finish
 * transfers this reservation on success, or frees every temporary on error.
 * A successful domain Haskell call must write an owned StablePtr Value. */
hmath_status hm_value_begin(hmath_context *context, hmath_value **temporary);
hmath_status hm_value_finish(hmath_value *temporary, int status, hmath_value **out);
void *hm_value_stable(const hmath_value *value);
#endif
