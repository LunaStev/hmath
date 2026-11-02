/* SPDX-License-Identifier: MPL-2.0 */
#include "numeric_internal.h"
#include "value_internal.h"
#include <stdlib.h>
extern void hm_value_free(void *stable);
extern int hm_value_info(void *stable, int *kind, int *dtype, size_t *count);
extern int hm_value_real_f32(float real, float imaginary, int complex, void **out);
extern int hm_value_real_f64(double real, double imaginary, int complex, void **out);
extern int hm_value_exact(int dtype, const char *numerator, const char *denominator, void **out);
extern int hm_value_index(ptrdiff_t value, void **out);
extern int hm_value_boolean(int value, void **out);
extern int hm_value_none(void **out);
extern int hm_value_sequence(int tuple, void *const *items, size_t count, void **out);
extern int hm_value_item(void *value, size_t index, void **out);
extern int hm_value_get_real_f32(void *value, float *real, float *imaginary);
extern int hm_value_get_real_f64(void *value, double *real, double *imaginary);
extern int hm_value_get_exact(void *value, char **numerator, char **denominator);
extern int hm_value_get_index(void *value, ptrdiff_t *out);
extern int hm_value_get_boolean(void *value, int *out);

extern int hm_value_text(const uint32_t *input, size_t count, void **out);
extern int hm_value_get_text(void *value, uint32_t *out);
hmath_status hm_value_begin(hmath_context *context, hmath_value **temporary) {
    hmath_value *value = calloc(1, sizeof *value);
    if (!value)
        return hm_error(HMATH_ALLOCATION_FAILED, "value owner allocation failed");
    hmath_status status = hm_enter(context);
    if (status) {
        free(value);
        return status;
    }
    atomic_init(&value->refs, 1);
    *temporary = value;
    return HMATH_OK;
}
hmath_status hm_value_finish(hmath_value *temporary, int code, hmath_value **out) {
    if (!code && !temporary->stable)
        code = hm_error(HMATH_RUNTIME_ERROR, "missing Haskell value result");
    if (!code)
        code = hm_value_info(temporary->stable, &temporary->kind, &temporary->dtype,
                             &temporary->count);
    if (!code && temporary->count > (size_t)PTRDIFF_MAX)
        code = hm_error(HMATH_OVERFLOW, "value metadata length exceeds Haskell Int");
    if (code) {
        if (temporary->stable)
            hm_value_free(temporary->stable);
        free(temporary);
        hm_leave();
        return (hmath_status)code;
    }
    *out = temporary;
    return HMATH_OK;
}
void *hm_value_stable(const hmath_value *value) { return value ? value->stable : NULL; }
void hmath_value_retain(hmath_value *value) {
    if (value)
        atomic_fetch_add_explicit(&value->refs, 1, memory_order_relaxed);
}
void hmath_value_release(hmath_value *value) {
    if (value && atomic_fetch_sub_explicit(&value->refs, 1, memory_order_acq_rel) == 1) {
        hm_value_free(value->stable);
        free(value);
        hm_leave();
    }
}
hmath_status hmath_value_info(const hmath_value *value, int *kind, int *dtype, size_t *count) {
    if (!value || !kind || !dtype || !count)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL value metadata argument");
    *kind = value->kind;
    *dtype = value->dtype;
    *count = value->count;
    return HMATH_OK;
}
void hmath_value_string_free(char *value) { free(value); }
#define BEGIN_VALUE()                                                                              \
    if (!out)                                                                                      \
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL value output");                              \
    hmath_value *result;                                                                           \
    hmath_status status = hm_value_begin(context, &result);                                        \
    if (status)                                                                                    \
    return status
hmath_status hmath_value_f32(hmath_context *context, float value, hmath_value **out) {
    BEGIN_VALUE();
    return hm_value_finish(result, hm_value_real_f32(value, 0, 0, &result->stable), out);
}
hmath_status hmath_value_f64(hmath_context *context, double value, hmath_value **out) {
    BEGIN_VALUE();
    return hm_value_finish(result, hm_value_real_f64(value, 0, 0, &result->stable), out);
}
hmath_status hmath_value_complex_f32(hmath_context *context, float real, float imaginary,
                                     hmath_value **out) {
    BEGIN_VALUE();
    return hm_value_finish(result, hm_value_real_f32(real, imaginary, 1, &result->stable), out);
}
hmath_status hmath_value_complex_f64(hmath_context *context, double real, double imaginary,
                                     hmath_value **out) {
    BEGIN_VALUE();
    return hm_value_finish(result, hm_value_real_f64(real, imaginary, 1, &result->stable), out);
}
hmath_status hmath_value_integral(hmath_context *context, hmath_coefficient_type dtype,
                                  const char *decimal, hmath_value **out) {
    if (!hm_decimal(decimal) || (dtype != 2 && (dtype < 6 || dtype > 15)))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid integral type/decimal representation");
    BEGIN_VALUE();
    return hm_value_finish(result, hm_value_exact(dtype, decimal, "1", &result->stable), out);
}
hmath_status hmath_value_integer(hmath_context *context, const char *decimal, hmath_value **out) {
    return hmath_value_integral(context, HMATH_COEFFICIENT_INTEGER, decimal, out);
}
hmath_status hmath_value_rational(hmath_context *context, const char *numerator,
                                  const char *denominator, hmath_value **out) {
    if (!hm_decimal(numerator) || !hm_decimal(denominator))
        return hm_error(HMATH_INVALID_ARGUMENT, "invalid Rational decimal representation");
    BEGIN_VALUE();
    return hm_value_finish(result, hm_value_exact(3, numerator, denominator, &result->stable), out);
}
hmath_status hmath_value_index(hmath_context *context, ptrdiff_t value, hmath_value **out) {
    BEGIN_VALUE();
    return hm_value_finish(result, hm_value_index(value, &result->stable), out);
}
hmath_status hmath_value_boolean(hmath_context *context, int value, hmath_value **out) {
    BEGIN_VALUE();
    return hm_value_finish(result, hm_value_boolean(value, &result->stable), out);
}
hmath_status hmath_value_none(hmath_context *context, hmath_value **out) {
    BEGIN_VALUE();
    return hm_value_finish(result, hm_value_none(&result->stable), out);
}
static hmath_status sequence(hmath_context *context, int tuple, const hmath_value *const *items,
                             size_t count, hmath_value **out) {
    if (count && !items)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL value sequence storage");
    if (count > (size_t)PTRDIFF_MAX / sizeof(void *))
        return hm_error(HMATH_OVERFLOW, "value sequence span exceeds ptrdiff_t");
    for (size_t i = 0; i < count; ++i)
        if (!items[i])
            return hm_error(HMATH_INVALID_ARGUMENT, "NULL sequence item");
    BEGIN_VALUE();
    void **stable = count ? malloc(count * sizeof *stable) : NULL;
    if (count && !stable)
        return hm_value_finish(
            result, hm_error(HMATH_ALLOCATION_FAILED, "value sequence scratch allocation failed"),
            out);
    for (size_t i = 0; i < count; ++i)
        stable[i] = items[i]->stable;
    int code = hm_value_sequence(tuple, stable, count, &result->stable);
    free(stable);
    return hm_value_finish(result, code, out);
}
hmath_status hmath_value_list(hmath_context *context, const hmath_value *const *items, size_t count,
                              hmath_value **out) {
    return sequence(context, 0, items, count, out);
}
hmath_status hmath_value_tuple(hmath_context *context, const hmath_value *const *items,
                               size_t count, hmath_value **out) {
    return sequence(context, 1, items, count, out);
}
hmath_status hmath_value_item(hmath_context *context, const hmath_value *sequence, ptrdiff_t index,
                              hmath_value **out) {
    if (!sequence || (sequence->kind != 4 && sequence->kind != 5))
        return hm_error(HMATH_INVALID_ARGUMENT, "value is not a list/tuple");
    if (index < 0 || (size_t)index >= sequence->count)
        return hm_error(HMATH_BOUNDS_ERROR, "value item index out of range");
    BEGIN_VALUE();
    return hm_value_finish(result, hm_value_item(sequence->stable, (size_t)index, &result->stable),
                           out);
}
#define SCALAR_ACCESSOR(name, valid_types, ctype, call)                                            \
    hmath_status name(const hmath_value *value, ctype *a, ctype *b) {                              \
        if (!value || value->kind != 1 || !(valid_types) || !a || !b || a == b)                    \
            return hm_error(HMATH_INVALID_ARGUMENT, "value scalar type/output mismatch");          \
        hmath_status status = hm_enter(NULL);                                                      \
        if (status)                                                                                \
            return status;                                                                         \
        int code = call(value->stable, a, b);                                                      \
        hm_leave();                                                                                \
        return (hmath_status)code;                                                                 \
    }
SCALAR_ACCESSOR(hmath_value_get_f32, value->dtype == 1 || value->dtype == 5, float,
                hm_value_get_real_f32)
SCALAR_ACCESSOR(hmath_value_get_f64, value->dtype == 0 || value->dtype == 4, double,
                hm_value_get_real_f64)
SCALAR_ACCESSOR(hmath_value_get_exact,
                value->dtype == 2 || value->dtype == 3 || (value->dtype >= 6 && value->dtype <= 15),
                char *, hm_value_get_exact)
#undef SCALAR_ACCESSOR
hmath_status hmath_value_get_index(const hmath_value *value, ptrdiff_t *out) {
    if (!value || value->kind != 2 || !out)
        return hm_error(HMATH_INVALID_ARGUMENT, "expected index and output");
    hmath_status status = hm_enter(NULL);
    if (status)
        return status;
    int code = hm_value_get_index(value->stable, out);
    hm_leave();
    return (hmath_status)code;
}
hmath_status hmath_value_get_boolean(const hmath_value *value, int *out) {
    if (!value || value->kind != 3 || !out)
        return hm_error(HMATH_INVALID_ARGUMENT, "expected Boolean and output");
    hmath_status status = hm_enter(NULL);
    if (status)
        return status;
    int code = hm_value_get_boolean(value->stable, out);
    hm_leave();
    return (hmath_status)code;
}

hmath_status hmath_value_text(hmath_context *context, const uint32_t *codepoints, size_t count,
                              hmath_value **out) {
    if (count && !codepoints)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL String codepoint storage");
    if (count > (size_t)PTRDIFF_MAX / sizeof(uint32_t))
        return hm_error(HMATH_OVERFLOW, "String codepoint span exceeds ptrdiff_t");
    for (size_t i = 0; i < count; ++i)
        if (codepoints[i] > 0x10ffffu)
            return hm_error(HMATH_INVALID_ARGUMENT, "codepoint exceeds Haskell Char range");
    BEGIN_VALUE();
    return hm_value_finish(result, hm_value_text(codepoints, count, &result->stable), out);
}
hmath_status hmath_value_get_text(const hmath_value *value, uint32_t *out, size_t capacity) {
    if (!value || value->kind != 10 || (value->count && !out))
        return hm_error(HMATH_INVALID_ARGUMENT, "expected String value and output");
    if (capacity < value->count)
        return hm_error(HMATH_BOUNDS_ERROR, "insufficient String codepoint output capacity");
    hmath_status status = hm_enter(NULL);
    if (status)
        return status;
    int code = hm_value_get_text(value->stable, out);
    hm_leave();
    return (hmath_status)code;
}
