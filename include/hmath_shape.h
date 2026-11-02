/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_SHAPE_H
#define HMATH_SHAPE_H
#include "hmath_foundation.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Original runtime and nominal type-indexed shapes. Implicit Haskell Nat
 * indices become explicit nonnegative Integer Values; KnownNat/KnownShape
 * dictionaries are reified, never coerced. Source Int overflow and dimension
 * checks remain. Shape patterns are read-only views. Matrix/Tensor results
 * interoperate with their ordinary public APIs. Inputs borrow; outputs own a
 * Value; failure leaves *out untouched. */
/* HMath.API.Shape.shapeDimensions */
HMATH_API hmath_status hmath_shape_shape_dimensions(hmath_context *context,
                                                    const hmath_value *shape, hmath_value **out);
/* HMath.API.Shape.shapeElements */
HMATH_API hmath_status hmath_shape_shape_elements(hmath_context *context, const hmath_value *shape,
                                                  hmath_value **out);
/* HMath.API.Shape.makeShape */
HMATH_API hmath_status hmath_shape_make_shape(hmath_context *context, const hmath_value *dimensions,
                                              hmath_value **out);
/* HMath.API.Shape.ScalarShape */
HMATH_API hmath_status hmath_shape_scalar_shape(hmath_context *context, const hmath_value *shape,
                                                hmath_value **out);
/* HMath.API.Shape.VectorShape */
HMATH_API hmath_status hmath_shape_vector_shape(hmath_context *context, const hmath_value *shape,
                                                hmath_value **out);
/* HMath.API.Shape.MatrixShape */
HMATH_API hmath_status hmath_shape_matrix_shape(hmath_context *context, const hmath_value *shape,
                                                hmath_value **out);
/* HMath.API.Shape.staticMatrix */
HMATH_API hmath_status hmath_shape_static_matrix(hmath_context *context, const hmath_value *rows,
                                                 const hmath_value *columns,
                                                 const hmath_value *matrix, hmath_value **out);
/* HMath.API.Shape.dynamicMatrix */
HMATH_API hmath_status hmath_shape_dynamic_matrix(hmath_context *context, const hmath_value *matrix,
                                                  hmath_value **out);
/* HMath.API.Shape.staticMultiply */
HMATH_API hmath_status hmath_shape_static_multiply(hmath_context *context, const hmath_value *left,
                                                   const hmath_value *right, hmath_value **out);
/* HMath.API.Shape.staticTranspose */
HMATH_API hmath_status hmath_shape_static_transpose(hmath_context *context,
                                                    const hmath_value *matrix, hmath_value **out);
/* HMath.API.Shape.reflectedShape */
HMATH_API hmath_status hmath_shape_reflected_shape(hmath_context *context,
                                                   const hmath_value *dimensions,
                                                   hmath_value **out);
/* HMath.API.Shape.staticTensor */
HMATH_API hmath_status hmath_shape_static_tensor(hmath_context *context,
                                                 const hmath_value *dimensions,
                                                 const hmath_value *tensor, hmath_value **out);
/* HMath.API.Shape.dynamicTensor */
HMATH_API hmath_status hmath_shape_dynamic_tensor(hmath_context *context, const hmath_value *tensor,
                                                  hmath_value **out);
/* HMath.API.Shape.coordinates */
HMATH_API hmath_status hmath_shape_coordinates(hmath_context *context, const hmath_value *prototype,
                                               const hmath_value *count, const hmath_value *values,
                                               hmath_value **out);
/* HMath.API.Shape.coordinateValues */
HMATH_API hmath_status hmath_shape_coordinate_values(hmath_context *context,
                                                     const hmath_value *coordinates,
                                                     hmath_value **out);
/* HMath.API.Shape.coordinatesToVector */
HMATH_API hmath_status hmath_shape_coordinates_to_vector(hmath_context *context,
                                                         const hmath_value *coordinates,
                                                         hmath_value **out);
#ifdef __cplusplus
}
#endif
#endif
