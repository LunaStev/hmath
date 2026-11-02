/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_bytes.h"
#include "value_internal.h"
extern int hm_bytes_copy(const void *, size_t, void **);
extern int hm_bytes_data(void *, const unsigned char **, size_t *);
hmath_status hmath_bytes_copy(hmath_context *context, const void *data, size_t count,
                              hmath_value **out) {
    if (!out || (count && !data))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid byte span/output");
    if (count > (size_t)PTRDIFF_MAX)
        return hm_error(HMATH_OVERFLOW, "byte span exceeds Haskell Int");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    return hm_value_finish(temporary, hm_bytes_copy(data, count, &temporary->stable), out);
}
hmath_status hmath_bytes_data(const hmath_value *bytes, const unsigned char **data, size_t *count) {
    if (!bytes || !data || !count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL byte metadata argument");
    return (hmath_status)hm_bytes_data(hm_value_stable(bytes), data, count);
}
