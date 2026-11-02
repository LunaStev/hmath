/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_ERROR_H
#define HMATH_ERROR_H
#include "hmath.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Stable transport for the original Haskell MathError sum type. Tuple fields
 * are flattened in source order into details. Unused details are ignored.
 * message is borrowed UTF-8 with an explicit byte length (embedded NUL allowed).
 * Haskell surrogate Char codepoints use the surrogatepass/WTF8 extension.
 * Callback error memory lives until the callback result has been consumed.
 * The last-error query instead borrows library memory until the next checked
 * operation on this thread; copy it before calling another numerical API. */
typedef enum hmath_math_error_kind {
    HMATH_MATH_NEGATIVE_DIMENSIONS = 1,
    HMATH_MATH_ELEMENT_COUNT_OVERFLOW = 2,
    HMATH_MATH_ELEMENT_COUNT_MISMATCH = 3,
    HMATH_MATH_SHAPE_MISMATCH = 4,
    HMATH_MATH_INNER_DIMENSION_MISMATCH = 5,
    HMATH_MATH_INDEX_OUT_OF_BOUNDS = 6,
    HMATH_MATH_SLICE_OUT_OF_BOUNDS = 7,
    HMATH_MATH_VECTOR_LENGTH_MISMATCH = 8,
    HMATH_MATH_NON_SQUARE_MATRIX = 9,
    HMATH_MATH_INVALID_TOLERANCE = 10,
    HMATH_MATH_SINGULAR_MATRIX = 11,
    HMATH_MATH_NEAR_SINGULAR_MATRIX = 12,
    HMATH_MATH_NON_FINITE_MATRIX_ENTRY = 13,
    HMATH_MATH_NON_FINITE_VECTOR_ENTRY = 14,
    HMATH_MATH_NON_FINITE_RESULT = 15,
    HMATH_MATH_RIGHT_HAND_SIDE_MISMATCH = 16,
    HMATH_MATH_DOMAIN_ERROR = 17,
    HMATH_MATH_INVALID_ARGUMENT = 18,
    HMATH_MATH_NON_CONVERGENCE = 19,
    HMATH_MATH_RANK_DEFICIENT = 20,
    HMATH_MATH_NOT_POSITIVE_DEFINITE = 21
} hmath_math_error_kind;
typedef struct hmath_math_error {
    uint32_t kind;
    ptrdiff_t details[6];
    const char *message;
    size_t message_length;
} hmath_math_error;
/* Query only: returns 1 when a complete structured MathError is available,
 * otherwise 0. It does not modify the last status/message. NULL out returns 0. */
HMATH_API int hmath_last_math_error(hmath_math_error *out);
#ifdef __cplusplus
}
#endif
#endif
