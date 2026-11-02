/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_EXPRESSION_ERROR_H
#define HMATH_EXPRESSION_ERROR_H
#include "hmath.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Original HMath.Expression.ExprError, independent of MathError. */
typedef enum hmath_expression_error_kind {
    HMATH_EXPRESSION_SYNTAX_ERROR = 0,
    HMATH_EXPRESSION_UNKNOWN_NAME = 1,
    HMATH_EXPRESSION_TYPE_MISMATCH = 2,
    HMATH_EXPRESSION_DOMAIN_FAILURE = 3,
    HMATH_EXPRESSION_NON_FINITE = 4,
    HMATH_EXPRESSION_STEP_LIMIT = 5,
    HMATH_EXPRESSION_DEPTH_LIMIT = 6,
    HMATH_EXPRESSION_MEMORY_LIMIT = 7,
    HMATH_EXPRESSION_INVALID_LIMITS = 8,
    HMATH_EXPRESSION_UNSUPPORTED = 9
} hmath_expression_error_kind;
typedef struct hmath_expression_error {
    uint32_t kind;
    ptrdiff_t source_offset;
    ptrdiff_t source_line;
    ptrdiff_t source_column;
    const char *message;
    size_t message_length;
} hmath_expression_error;
/* Query only. Message is library-owned UTF8 (surrogatepass/WTF8 for isolated
 * Haskell Char surrogates), with embedded NUL and full explicit length. Copy
 * before the next checked operation on this thread. Returns 1 iff present. */
HMATH_API int hmath_last_expression_error(hmath_expression_error *out);
#ifdef __cplusplus
}
#endif
#endif
