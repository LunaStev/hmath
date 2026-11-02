/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_VALUE_H
#define HMATH_VALUE_H
#include "hmath.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Lossless owned values shared by structured mathematical APIs. Each owned
 * handle pins the runtime; release every reference before final shutdown.
 * Inputs are borrowed for each synchronous call. Outputs remain untouched on
 * errors. Containers retain their Haskell values independently of input owners.
 * Exact integer/rational text is signed ASCII decimal, not a floating encoding. */
typedef struct hmath_value hmath_value;
typedef enum hmath_coefficient_type {
    HMATH_COEFFICIENT_FLOAT64 = 0,
    HMATH_COEFFICIENT_FLOAT32 = 1,
    HMATH_COEFFICIENT_INTEGER = 2,
    HMATH_COEFFICIENT_RATIONAL = 3,
    HMATH_COEFFICIENT_COMPLEX128 = 4,
    HMATH_COEFFICIENT_COMPLEX64 = 5,
    HMATH_COEFFICIENT_INT8 = 6,
    HMATH_COEFFICIENT_INT16 = 7,
    HMATH_COEFFICIENT_INT32 = 8,
    HMATH_COEFFICIENT_INT64 = 9,
    HMATH_COEFFICIENT_UINT8 = 10,
    HMATH_COEFFICIENT_UINT16 = 11,
    HMATH_COEFFICIENT_UINT32 = 12,
    HMATH_COEFFICIENT_UINT64 = 13,
    HMATH_COEFFICIENT_INTP = 14,
    HMATH_COEFFICIENT_UINTP = 15
} hmath_coefficient_type;
/* Kinds: 0 None, 1 scalar coefficient, 2 Haskell Int, 3 Boolean,
 * 4 list, 5 tuple, 6 polynomial, 7 power series, 8 rational function,
 * 9 dense matrix, 10 String (Unicode codepoints); other documented domains reserve additional
 * opaque kinds. dtype=-1 means not a coefficient-bearing object. count is logical length. info is a
 * metadata query and does not alter last-error state. */
HMATH_API hmath_status hmath_value_info(const hmath_value *value, int *kind, int *dtype,
                                        size_t *count);
HMATH_API void hmath_value_retain(hmath_value *value);
HMATH_API void hmath_value_release(hmath_value *value);
HMATH_API hmath_status hmath_value_f32(hmath_context *context, float value, hmath_value **out);
HMATH_API hmath_status hmath_value_f64(hmath_context *context, double value, hmath_value **out);
HMATH_API hmath_status hmath_value_complex_f32(hmath_context *context, float real, float imaginary,
                                               hmath_value **out);
HMATH_API hmath_status hmath_value_complex_f64(hmath_context *context, double real,
                                               double imaginary, hmath_value **out);
HMATH_API hmath_status hmath_value_integer(hmath_context *context, const char *decimal,
                                           hmath_value **out);
HMATH_API hmath_status hmath_value_integral(hmath_context *context, hmath_coefficient_type dtype,
                                            const char *decimal, hmath_value **out);
HMATH_API hmath_status hmath_value_rational(hmath_context *context, const char *numerator,
                                            const char *denominator, hmath_value **out);
HMATH_API hmath_status hmath_value_index(hmath_context *context, ptrdiff_t value,
                                         hmath_value **out);
HMATH_API hmath_status hmath_value_boolean(hmath_context *context, int value, hmath_value **out);
HMATH_API hmath_status hmath_value_none(hmath_context *context, hmath_value **out);
HMATH_API hmath_status hmath_value_list(hmath_context *context, const hmath_value *const *items,
                                        size_t count, hmath_value **out);
HMATH_API hmath_status hmath_value_tuple(hmath_context *context, const hmath_value *const *items,
                                         size_t count, hmath_value **out);
HMATH_API hmath_status hmath_value_item(hmath_context *context, const hmath_value *sequence,
                                        ptrdiff_t index, hmath_value **out);
/* Typed scalar accessors reject mismatched coefficient types; no narrowing.
 * Real scalar getters set imaginary to zero. Both output pointers are required.
 * Exact getter returns two owned decimal strings (denominator=1 for integers).
 * Release returned strings with hmath_value_string_free. */
HMATH_API hmath_status hmath_value_get_f32(const hmath_value *value, float *real, float *imaginary);
HMATH_API hmath_status hmath_value_get_f64(const hmath_value *value, double *real,
                                           double *imaginary);
HMATH_API hmath_status hmath_value_get_exact(const hmath_value *value, char **numerator,
                                             char **denominator);
HMATH_API hmath_status hmath_value_get_index(const hmath_value *value, ptrdiff_t *out);
HMATH_API hmath_status hmath_value_get_boolean(const hmath_value *value, int *out);
/* String uses Unicode codepoints, not UTF-8 bytes: preserves embedded NUL and
 * every Haskell Char, including surrogate codepoints, without normalization. */
HMATH_API hmath_status hmath_value_text(hmath_context *context, const uint32_t *codepoints,
                                        size_t count, hmath_value **out);
HMATH_API hmath_status hmath_value_get_text(const hmath_value *value, uint32_t *out,
                                            size_t capacity);
HMATH_API void hmath_value_string_free(char *value);
#ifdef __cplusplus
}
#endif
#endif
