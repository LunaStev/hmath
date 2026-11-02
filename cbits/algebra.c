/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_algebra.h"
#include "value_internal.h"
extern int hm_algebra_apply(int, void *const *, size_t, void **);
hmath_status hmath_algebra_core_linear_combination(hmath_context *context,
                                                   const hmath_value *prototype,
                                                   const hmath_value *a0, const hmath_value *a1,
                                                   hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(0, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_core_semiring_laws(hmath_context *context, const hmath_value *prototype,
                                              const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(1, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_ring_laws(hmath_context *context, const hmath_value *prototype,
                                          const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(2, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_field_laws(hmath_context *context, const hmath_value *prototype,
                                           const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(3, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_group_laws(hmath_context *context, const hmath_value *prototype,
                                           const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(4, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_module_laws(hmath_context *context, const hmath_value *prototype,
                                            const hmath_value *a0, const hmath_value *a1,
                                            hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(5, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_core_modular(hmath_context *context, const hmath_value *a0,
                                        const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(6, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_modular_value(hmath_context *context, const hmath_value *a0,
                                              hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(7, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_modular_modulus(hmath_context *context, const hmath_value *a0,
                                                hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(8, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_add_modular(hmath_context *context, const hmath_value *a0,
                                            const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(9, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_subtract_modular(hmath_context *context, const hmath_value *a0,
                                                 const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(10, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_multiply_modular(hmath_context *context, const hmath_value *a0,
                                                 const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(11, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_inverse_modular(hmath_context *context, const hmath_value *a0,
                                                hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(12, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_power_modular(hmath_context *context, const hmath_value *a0,
                                              const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(13, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_finite_field(hmath_context *context, const hmath_value *a0,
                                             const hmath_value *a1, const hmath_value *a2,
                                             hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_algebra_apply(14, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_core_prime_field(hmath_context *context, const hmath_value *a0,
                                            const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(15, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_field_characteristic(hmath_context *context, const hmath_value *a0,
                                                     hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(16, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_field_degree(hmath_context *context, const hmath_value *a0,
                                             hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(17, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_field_cardinality(hmath_context *context, const hmath_value *a0,
                                                  hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(18, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_field_modulus(hmath_context *context, const hmath_value *a0,
                                              hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(19, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_field_element(hmath_context *context, const hmath_value *a0,
                                              const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(20, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_field_element_coefficients(hmath_context *context,
                                                           const hmath_value *a0,
                                                           hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(21, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_field_elements(hmath_context *context, const hmath_value *a0,
                                               const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(22, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_add_field(hmath_context *context, const hmath_value *a0,
                                          const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(23, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_negate_field(hmath_context *context, const hmath_value *a0,
                                             hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(24, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_subtract_field(hmath_context *context, const hmath_value *a0,
                                               const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(25, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_multiply_field(hmath_context *context, const hmath_value *a0,
                                               const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(26, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_inverse_field_element(hmath_context *context, const hmath_value *a0,
                                                      hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(27, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_power_field(hmath_context *context, const hmath_value *a0,
                                            const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(28, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_finite_field_laws(hmath_context *context, const hmath_value *a0,
                                                  const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(29, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_get_additive(hmath_context *context, const hmath_value *prototype,
                                             const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(30, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_new_additive(hmath_context *context, const hmath_value *prototype,
                                             const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(31, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_api_horner(hmath_context *context, const hmath_value *prototype,
                                      const hmath_value *a0, const hmath_value *a1,
                                      hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(32, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_api_inner_product(hmath_context *context, const hmath_value *prototype,
                                             const hmath_value *a0, const hmath_value *a1,
                                             hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(33, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_api_get_exact(hmath_context *context, const hmath_value *a0,
                                         hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(34, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_api_new_exact(hmath_context *context, const hmath_value *a0,
                                         hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(35, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_zero(hmath_context *context, const hmath_value *prototype,
                                     hmath_value **out) {
    if (!out || !prototype)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype)};
    return hm_value_finish(result, hm_algebra_apply(36, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_one(hmath_context *context, const hmath_value *prototype,
                                    hmath_value **out) {
    if (!out || !prototype)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype)};
    return hm_value_finish(result, hm_algebra_apply(37, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_plus(hmath_context *context, const hmath_value *prototype,
                                     const hmath_value *a0, const hmath_value *a1,
                                     hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(38, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_core_times(hmath_context *context, const hmath_value *prototype,
                                      const hmath_value *a0, const hmath_value *a1,
                                      hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(39, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_core_negate_ring(hmath_context *context, const hmath_value *prototype,
                                            const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(40, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_inverse_field(hmath_context *context, const hmath_value *prototype,
                                              const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(41, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_group_identity(hmath_context *context, const hmath_value *prototype,
                                               hmath_value **out) {
    if (!out || !prototype)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype)};
    return hm_value_finish(result, hm_algebra_apply(42, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_core_group_combine(hmath_context *context, const hmath_value *prototype,
                                              const hmath_value *a0, const hmath_value *a1,
                                              hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(43, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_core_group_inverse(hmath_context *context, const hmath_value *prototype,
                                              const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(44, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_core_module_scale(hmath_context *context, const hmath_value *prototype,
                                             const hmath_value *a0, const hmath_value *a1,
                                             hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(45, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_core_module_add(hmath_context *context, const hmath_value *prototype,
                                           const hmath_value *a0, const hmath_value *a1,
                                           hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(46, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_api_zero(hmath_context *context, const hmath_value *prototype,
                                    hmath_value **out) {
    if (!out || !prototype)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype)};
    return hm_value_finish(result, hm_algebra_apply(47, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_api_one(hmath_context *context, const hmath_value *prototype,
                                   hmath_value **out) {
    if (!out || !prototype)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype)};
    return hm_value_finish(result, hm_algebra_apply(48, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_api_plus(hmath_context *context, const hmath_value *prototype,
                                    const hmath_value *a0, const hmath_value *a1,
                                    hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(49, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_api_times(hmath_context *context, const hmath_value *prototype,
                                     const hmath_value *a0, const hmath_value *a1,
                                     hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(50, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_api_negative(hmath_context *context, const hmath_value *prototype,
                                        const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(51, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_api_integer(hmath_context *context, const hmath_value *prototype,
                                       const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(52, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_api_invert(hmath_context *context, const hmath_value *prototype,
                                      const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(53, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_api_conjugate_scalar(hmath_context *context,
                                                const hmath_value *prototype, const hmath_value *a0,
                                                hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(54, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_api_machine_epsilon(hmath_context *context, const hmath_value *prototype,
                                               hmath_value **out) {
    if (!out || !prototype)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype)};
    return hm_value_finish(result, hm_algebra_apply(55, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_api_finite_scalar(hmath_context *context, const hmath_value *prototype,
                                             const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(56, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_api_rational(hmath_context *context, const hmath_value *prototype,
                                        const hmath_value *a0, hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(57, args, 2, &result->stable), out);
}
hmath_status hmath_algebra_api_matrix_dimensions(hmath_context *context, const hmath_value *a0,
                                                 hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(58, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_api_matrix_elements(hmath_context *context, const hmath_value *a0,
                                               hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(59, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_api_matrix_construct(hmath_context *context,
                                                const hmath_value *prototype, const hmath_value *a0,
                                                const hmath_value *a1, const hmath_value *a2,
                                                hmath_value **out) {
    if (!out || !prototype || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1),
                    hm_value_stable(a2)};
    return hm_value_finish(result, hm_algebra_apply(60, args, 4, &result->stable), out);
}
hmath_status hmath_algebra_api_tensor_dimensions(hmath_context *context, const hmath_value *a0,
                                                 hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(61, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_api_tensor_elements(hmath_context *context, const hmath_value *a0,
                                               hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(62, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_api_tensor_construct(hmath_context *context,
                                                const hmath_value *prototype, const hmath_value *a0,
                                                const hmath_value *a1, hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(63, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_api_vector_plus(hmath_context *context, const hmath_value *prototype,
                                           const hmath_value *a0, const hmath_value *a1,
                                           hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(64, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_api_vector_scale(hmath_context *context, const hmath_value *prototype,
                                            const hmath_value *a0, const hmath_value *a1,
                                            hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_algebra_apply(65, args, 3, &result->stable), out);
}
hmath_status hmath_algebra_api_differential(hmath_context *context, const hmath_value *a0,
                                            hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL algebra argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_algebra_apply(66, args, 1, &result->stable), out);
}
hmath_status hmath_algebra_api_exact_element_type(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL element type output");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    return hm_value_finish(result, hm_algebra_apply(-1, NULL, 0, &result->stable), out);
}
