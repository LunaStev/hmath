/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_BYTES_H
#define HMATH_BYTES_H
#include "hmath_value.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Owned immutable strict ByteString, Value kind450, count=byte length. */
HMATH_API hmath_status hmath_bytes_copy(hmath_context *context, const void *data, size_t count,
                                        hmath_value **out);
/* Query only; both outputs are required and unchanged on error. The returned
 * span is read-only and borrowed until the owning Value's last release. Keep
 * a retained reference alive for every view; no terminator is implied. */
HMATH_API hmath_status hmath_bytes_data(const hmath_value *bytes, const unsigned char **data,
                                        size_t *count);
#ifdef __cplusplus
}
#endif
#endif
