/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_INTERCHANGE_ERROR_H
#define HMATH_INTERCHANGE_ERROR_H
#include "hmath.h"
#ifdef __cplusplus
extern "C" {
#endif
typedef enum hmath_interchange_error_kind {
    HMATH_INTERCHANGE_INVALID_DATA = 0,
    HMATH_INTERCHANGE_UNSUPPORTED = 1,
    HMATH_INTERCHANGE_LIMIT_EXCEEDED = 2,
    HMATH_INTERCHANGE_IO_ERROR = 3
} hmath_interchange_error_kind;
typedef struct hmath_interchange_error {
    uint32_t kind;
    const char *message;
    size_t message_length;
} hmath_interchange_error;
/* Query only. Returns1 when status13's complete original payload is available.
 * Message is borrowed until the next checked operation on this thread. Its
 * explicit byte length preserves NUL; surrogate Char values use WTF8. */
HMATH_API int hmath_last_interchange_error(hmath_interchange_error *out);
#ifdef __cplusplus
}
#endif
#endif
