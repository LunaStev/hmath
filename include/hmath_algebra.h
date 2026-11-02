/* SPDX-License-Identifier: MPL-2.0 */
/* Generated original algebra typeclass instances and checked field APIs. */
#ifndef HMATH_ALGEBRA_H
#define HMATH_ALGEBRA_H
#include "hmath_foundation.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Explicit prototype parameters select actual source instances. They are not
 * conversions. Old Algebra: Integer/Rational/Polynomial, Additive groups and
 * Integer/Rational list modules. API.Algebra: Integer/Rational/Float/Double/
 * Complex Double/Exact; unsupported original instances return Unsupported.
 * Exact has no Num instance. Inputs borrow; outputs own an independent Value.
 * Failure leaves *out untouched; release outputs using hmath_value_release. */
/* HMath.Algebra.linearCombination */
HMATH_API hmath_status hmath_algebra_core_linear_combination(hmath_context *context,
                                                             const hmath_value *prototype,
                                                             const hmath_value *a0,
                                                             const hmath_value *a1,
                                                             hmath_value **out);
/* HMath.Algebra.semiringLaws */
HMATH_API hmath_status hmath_algebra_core_semiring_laws(hmath_context *context,
                                                        const hmath_value *prototype,
                                                        const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.ringLaws */
HMATH_API hmath_status hmath_algebra_core_ring_laws(hmath_context *context,
                                                    const hmath_value *prototype,
                                                    const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.fieldLaws */
HMATH_API hmath_status hmath_algebra_core_field_laws(hmath_context *context,
                                                     const hmath_value *prototype,
                                                     const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.groupLaws */
HMATH_API hmath_status hmath_algebra_core_group_laws(hmath_context *context,
                                                     const hmath_value *prototype,
                                                     const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.moduleLaws */
HMATH_API hmath_status hmath_algebra_core_module_laws(hmath_context *context,
                                                      const hmath_value *prototype,
                                                      const hmath_value *a0, const hmath_value *a1,
                                                      hmath_value **out);
/* HMath.Algebra.modular */
HMATH_API hmath_status hmath_algebra_core_modular(hmath_context *context, const hmath_value *a0,
                                                  const hmath_value *a1, hmath_value **out);
/* HMath.Algebra.modularValue */
HMATH_API hmath_status hmath_algebra_core_modular_value(hmath_context *context,
                                                        const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.modularModulus */
HMATH_API hmath_status hmath_algebra_core_modular_modulus(hmath_context *context,
                                                          const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.addModular */
HMATH_API hmath_status hmath_algebra_core_add_modular(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, hmath_value **out);
/* HMath.Algebra.subtractModular */
HMATH_API hmath_status hmath_algebra_core_subtract_modular(hmath_context *context,
                                                           const hmath_value *a0,
                                                           const hmath_value *a1,
                                                           hmath_value **out);
/* HMath.Algebra.multiplyModular */
HMATH_API hmath_status hmath_algebra_core_multiply_modular(hmath_context *context,
                                                           const hmath_value *a0,
                                                           const hmath_value *a1,
                                                           hmath_value **out);
/* HMath.Algebra.inverseModular */
HMATH_API hmath_status hmath_algebra_core_inverse_modular(hmath_context *context,
                                                          const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.powerModular */
HMATH_API hmath_status hmath_algebra_core_power_modular(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1, hmath_value **out);
/* HMath.Algebra.finiteField */
HMATH_API hmath_status hmath_algebra_core_finite_field(hmath_context *context,
                                                       const hmath_value *a0, const hmath_value *a1,
                                                       const hmath_value *a2, hmath_value **out);
/* HMath.Algebra.primeField */
HMATH_API hmath_status hmath_algebra_core_prime_field(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, hmath_value **out);
/* HMath.Algebra.fieldCharacteristic */
HMATH_API hmath_status hmath_algebra_core_field_characteristic(hmath_context *context,
                                                               const hmath_value *a0,
                                                               hmath_value **out);
/* HMath.Algebra.fieldDegree */
HMATH_API hmath_status hmath_algebra_core_field_degree(hmath_context *context,
                                                       const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.fieldCardinality */
HMATH_API hmath_status hmath_algebra_core_field_cardinality(hmath_context *context,
                                                            const hmath_value *a0,
                                                            hmath_value **out);
/* HMath.Algebra.fieldModulus */
HMATH_API hmath_status hmath_algebra_core_field_modulus(hmath_context *context,
                                                        const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.fieldElement */
HMATH_API hmath_status hmath_algebra_core_field_element(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1, hmath_value **out);
/* HMath.Algebra.fieldElementCoefficients */
HMATH_API hmath_status hmath_algebra_core_field_element_coefficients(hmath_context *context,
                                                                     const hmath_value *a0,
                                                                     hmath_value **out);
/* HMath.Algebra.fieldElements */
HMATH_API hmath_status hmath_algebra_core_field_elements(hmath_context *context,
                                                         const hmath_value *a0,
                                                         const hmath_value *a1, hmath_value **out);
/* HMath.Algebra.addField */
HMATH_API hmath_status hmath_algebra_core_add_field(hmath_context *context, const hmath_value *a0,
                                                    const hmath_value *a1, hmath_value **out);
/* HMath.Algebra.negateField */
HMATH_API hmath_status hmath_algebra_core_negate_field(hmath_context *context,
                                                       const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.subtractField */
HMATH_API hmath_status hmath_algebra_core_subtract_field(hmath_context *context,
                                                         const hmath_value *a0,
                                                         const hmath_value *a1, hmath_value **out);
/* HMath.Algebra.multiplyField */
HMATH_API hmath_status hmath_algebra_core_multiply_field(hmath_context *context,
                                                         const hmath_value *a0,
                                                         const hmath_value *a1, hmath_value **out);
/* HMath.Algebra.inverseFieldElement */
HMATH_API hmath_status hmath_algebra_core_inverse_field_element(hmath_context *context,
                                                                const hmath_value *a0,
                                                                hmath_value **out);
/* HMath.Algebra.powerField */
HMATH_API hmath_status hmath_algebra_core_power_field(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, hmath_value **out);
/* HMath.Algebra.finiteFieldLaws */
HMATH_API hmath_status hmath_algebra_core_finite_field_laws(hmath_context *context,
                                                            const hmath_value *a0,
                                                            const hmath_value *a1,
                                                            hmath_value **out);
/* HMath.Algebra.getAdditive */
HMATH_API hmath_status hmath_algebra_core_get_additive(hmath_context *context,
                                                       const hmath_value *prototype,
                                                       const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.Additive */
HMATH_API hmath_status hmath_algebra_core_new_additive(hmath_context *context,
                                                       const hmath_value *prototype,
                                                       const hmath_value *a0, hmath_value **out);
/* HMath.API.Algebra.horner */
HMATH_API hmath_status hmath_algebra_api_horner(hmath_context *context,
                                                const hmath_value *prototype, const hmath_value *a0,
                                                const hmath_value *a1, hmath_value **out);
/* HMath.API.Algebra.innerProduct */
HMATH_API hmath_status hmath_algebra_api_inner_product(hmath_context *context,
                                                       const hmath_value *prototype,
                                                       const hmath_value *a0, const hmath_value *a1,
                                                       hmath_value **out);
/* HMath.API.Algebra.getExact */
HMATH_API hmath_status hmath_algebra_api_get_exact(hmath_context *context, const hmath_value *a0,
                                                   hmath_value **out);
/* HMath.API.Algebra.Exact */
HMATH_API hmath_status hmath_algebra_api_new_exact(hmath_context *context, const hmath_value *a0,
                                                   hmath_value **out);
/* HMath.Algebra.zero */
HMATH_API hmath_status hmath_algebra_core_zero(hmath_context *context, const hmath_value *prototype,
                                               hmath_value **out);
/* HMath.Algebra.one */
HMATH_API hmath_status hmath_algebra_core_one(hmath_context *context, const hmath_value *prototype,
                                              hmath_value **out);
/* HMath.Algebra.plus */
HMATH_API hmath_status hmath_algebra_core_plus(hmath_context *context, const hmath_value *prototype,
                                               const hmath_value *a0, const hmath_value *a1,
                                               hmath_value **out);
/* HMath.Algebra.times */
HMATH_API hmath_status hmath_algebra_core_times(hmath_context *context,
                                                const hmath_value *prototype, const hmath_value *a0,
                                                const hmath_value *a1, hmath_value **out);
/* HMath.Algebra.negateRing */
HMATH_API hmath_status hmath_algebra_core_negate_ring(hmath_context *context,
                                                      const hmath_value *prototype,
                                                      const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.inverseField */
HMATH_API hmath_status hmath_algebra_core_inverse_field(hmath_context *context,
                                                        const hmath_value *prototype,
                                                        const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.groupIdentity */
HMATH_API hmath_status hmath_algebra_core_group_identity(hmath_context *context,
                                                         const hmath_value *prototype,
                                                         hmath_value **out);
/* HMath.Algebra.groupCombine */
HMATH_API hmath_status hmath_algebra_core_group_combine(hmath_context *context,
                                                        const hmath_value *prototype,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1, hmath_value **out);
/* HMath.Algebra.groupInverse */
HMATH_API hmath_status hmath_algebra_core_group_inverse(hmath_context *context,
                                                        const hmath_value *prototype,
                                                        const hmath_value *a0, hmath_value **out);
/* HMath.Algebra.moduleScale */
HMATH_API hmath_status hmath_algebra_core_module_scale(hmath_context *context,
                                                       const hmath_value *prototype,
                                                       const hmath_value *a0, const hmath_value *a1,
                                                       hmath_value **out);
/* HMath.Algebra.moduleAdd */
HMATH_API hmath_status hmath_algebra_core_module_add(hmath_context *context,
                                                     const hmath_value *prototype,
                                                     const hmath_value *a0, const hmath_value *a1,
                                                     hmath_value **out);
/* HMath.API.Algebra.zero */
HMATH_API hmath_status hmath_algebra_api_zero(hmath_context *context, const hmath_value *prototype,
                                              hmath_value **out);
/* HMath.API.Algebra.one */
HMATH_API hmath_status hmath_algebra_api_one(hmath_context *context, const hmath_value *prototype,
                                             hmath_value **out);
/* HMath.API.Algebra.plus */
HMATH_API hmath_status hmath_algebra_api_plus(hmath_context *context, const hmath_value *prototype,
                                              const hmath_value *a0, const hmath_value *a1,
                                              hmath_value **out);
/* HMath.API.Algebra.times */
HMATH_API hmath_status hmath_algebra_api_times(hmath_context *context, const hmath_value *prototype,
                                               const hmath_value *a0, const hmath_value *a1,
                                               hmath_value **out);
/* HMath.API.Algebra.negative */
HMATH_API hmath_status hmath_algebra_api_negative(hmath_context *context,
                                                  const hmath_value *prototype,
                                                  const hmath_value *a0, hmath_value **out);
/* HMath.API.Algebra.integer */
HMATH_API hmath_status hmath_algebra_api_integer(hmath_context *context,
                                                 const hmath_value *prototype,
                                                 const hmath_value *a0, hmath_value **out);
/* HMath.API.Algebra.invert */
HMATH_API hmath_status hmath_algebra_api_invert(hmath_context *context,
                                                const hmath_value *prototype, const hmath_value *a0,
                                                hmath_value **out);
/* HMath.API.Algebra.conjugateScalar */
HMATH_API hmath_status hmath_algebra_api_conjugate_scalar(hmath_context *context,
                                                          const hmath_value *prototype,
                                                          const hmath_value *a0, hmath_value **out);
/* HMath.API.Algebra.machineEpsilon */
HMATH_API hmath_status hmath_algebra_api_machine_epsilon(hmath_context *context,
                                                         const hmath_value *prototype,
                                                         hmath_value **out);
/* HMath.API.Algebra.finiteScalar */
HMATH_API hmath_status hmath_algebra_api_finite_scalar(hmath_context *context,
                                                       const hmath_value *prototype,
                                                       const hmath_value *a0, hmath_value **out);
/* HMath.API.Algebra.rational */
HMATH_API hmath_status hmath_algebra_api_rational(hmath_context *context,
                                                  const hmath_value *prototype,
                                                  const hmath_value *a0, hmath_value **out);
/* HMath.API.Algebra.matrixDimensions */
HMATH_API hmath_status hmath_algebra_api_matrix_dimensions(hmath_context *context,
                                                           const hmath_value *a0,
                                                           hmath_value **out);
/* HMath.API.Algebra.matrixElements */
HMATH_API hmath_status hmath_algebra_api_matrix_elements(hmath_context *context,
                                                         const hmath_value *a0, hmath_value **out);
/* HMath.API.Algebra.matrixConstruct */
HMATH_API hmath_status hmath_algebra_api_matrix_construct(hmath_context *context,
                                                          const hmath_value *prototype,
                                                          const hmath_value *a0,
                                                          const hmath_value *a1,
                                                          const hmath_value *a2, hmath_value **out);
/* HMath.API.Algebra.tensorDimensions */
HMATH_API hmath_status hmath_algebra_api_tensor_dimensions(hmath_context *context,
                                                           const hmath_value *a0,
                                                           hmath_value **out);
/* HMath.API.Algebra.tensorElements */
HMATH_API hmath_status hmath_algebra_api_tensor_elements(hmath_context *context,
                                                         const hmath_value *a0, hmath_value **out);
/* HMath.API.Algebra.tensorConstruct */
HMATH_API hmath_status hmath_algebra_api_tensor_construct(hmath_context *context,
                                                          const hmath_value *prototype,
                                                          const hmath_value *a0,
                                                          const hmath_value *a1, hmath_value **out);
/* HMath.API.Algebra.vectorPlus */
HMATH_API hmath_status hmath_algebra_api_vector_plus(hmath_context *context,
                                                     const hmath_value *prototype,
                                                     const hmath_value *a0, const hmath_value *a1,
                                                     hmath_value **out);
/* HMath.API.Algebra.vectorScale */
HMATH_API hmath_status hmath_algebra_api_vector_scale(hmath_context *context,
                                                      const hmath_value *prototype,
                                                      const hmath_value *a0, const hmath_value *a1,
                                                      hmath_value **out);
/* HMath.API.Algebra.differential */
HMATH_API hmath_status hmath_algebra_api_differential(hmath_context *context, const hmath_value *a0,
                                                      hmath_value **out);
HMATH_API hmath_status hmath_algebra_api_exact_element_type(hmath_context *context,
                                                            hmath_value **out);
#ifdef __cplusplus
}
#endif
#endif
