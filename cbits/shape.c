/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_shape.h"
#include "value_internal.h"
extern int hm_shape_apply(int, void *const *, size_t, void **);
hmath_status hmath_shape_shape_dimensions(hmath_context *context, const hmath_value *shape,
                                          hmath_value **out) {
    if (!out || !shape)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(shape)};
    return hm_value_finish(result, hm_shape_apply(0, args, 1, &result->stable), out);
}
hmath_status hmath_shape_shape_elements(hmath_context *context, const hmath_value *shape,
                                        hmath_value **out) {
    if (!out || !shape)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(shape)};
    return hm_value_finish(result, hm_shape_apply(1, args, 1, &result->stable), out);
}
hmath_status hmath_shape_make_shape(hmath_context *context, const hmath_value *dimensions,
                                    hmath_value **out) {
    if (!out || !dimensions)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(dimensions)};
    return hm_value_finish(result, hm_shape_apply(2, args, 1, &result->stable), out);
}
hmath_status hmath_shape_scalar_shape(hmath_context *context, const hmath_value *shape,
                                      hmath_value **out) {
    if (!out || !shape)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(shape)};
    return hm_value_finish(result, hm_shape_apply(3, args, 1, &result->stable), out);
}
hmath_status hmath_shape_vector_shape(hmath_context *context, const hmath_value *shape,
                                      hmath_value **out) {
    if (!out || !shape)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(shape)};
    return hm_value_finish(result, hm_shape_apply(4, args, 1, &result->stable), out);
}
hmath_status hmath_shape_matrix_shape(hmath_context *context, const hmath_value *shape,
                                      hmath_value **out) {
    if (!out || !shape)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(shape)};
    return hm_value_finish(result, hm_shape_apply(5, args, 1, &result->stable), out);
}
hmath_status hmath_shape_static_matrix(hmath_context *context, const hmath_value *rows,
                                       const hmath_value *columns, const hmath_value *matrix,
                                       hmath_value **out) {
    if (!out || !rows || !columns || !matrix)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(rows), hm_value_stable(columns), hm_value_stable(matrix)};
    return hm_value_finish(result, hm_shape_apply(6, args, 3, &result->stable), out);
}
hmath_status hmath_shape_dynamic_matrix(hmath_context *context, const hmath_value *matrix,
                                        hmath_value **out) {
    if (!out || !matrix)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(matrix)};
    return hm_value_finish(result, hm_shape_apply(7, args, 1, &result->stable), out);
}
hmath_status hmath_shape_static_multiply(hmath_context *context, const hmath_value *left,
                                         const hmath_value *right, hmath_value **out) {
    if (!out || !left || !right)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(left), hm_value_stable(right)};
    return hm_value_finish(result, hm_shape_apply(8, args, 2, &result->stable), out);
}
hmath_status hmath_shape_static_transpose(hmath_context *context, const hmath_value *matrix,
                                          hmath_value **out) {
    if (!out || !matrix)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(matrix)};
    return hm_value_finish(result, hm_shape_apply(9, args, 1, &result->stable), out);
}
hmath_status hmath_shape_reflected_shape(hmath_context *context, const hmath_value *dimensions,
                                         hmath_value **out) {
    if (!out || !dimensions)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(dimensions)};
    return hm_value_finish(result, hm_shape_apply(10, args, 1, &result->stable), out);
}
hmath_status hmath_shape_static_tensor(hmath_context *context, const hmath_value *dimensions,
                                       const hmath_value *tensor, hmath_value **out) {
    if (!out || !dimensions || !tensor)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(dimensions), hm_value_stable(tensor)};
    return hm_value_finish(result, hm_shape_apply(11, args, 2, &result->stable), out);
}
hmath_status hmath_shape_dynamic_tensor(hmath_context *context, const hmath_value *tensor,
                                        hmath_value **out) {
    if (!out || !tensor)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(tensor)};
    return hm_value_finish(result, hm_shape_apply(12, args, 1, &result->stable), out);
}
hmath_status hmath_shape_coordinates(hmath_context *context, const hmath_value *prototype,
                                     const hmath_value *count, const hmath_value *values,
                                     hmath_value **out) {
    if (!out || !prototype || !count || !values)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(count), hm_value_stable(values)};
    return hm_value_finish(result, hm_shape_apply(13, args, 3, &result->stable), out);
}
hmath_status hmath_shape_coordinate_values(hmath_context *context, const hmath_value *coordinates,
                                           hmath_value **out) {
    if (!out || !coordinates)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(coordinates)};
    return hm_value_finish(result, hm_shape_apply(14, args, 1, &result->stable), out);
}
hmath_status hmath_shape_coordinates_to_vector(hmath_context *context,
                                               const hmath_value *coordinates, hmath_value **out) {
    if (!out || !coordinates)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL shape argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(coordinates)};
    return hm_value_finish(result, hm_shape_apply(15, args, 1, &result->stable), out);
}
