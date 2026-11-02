/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_geometry.h"
#include "hmath_error.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
static void presence(hmath_value *value, int expected) {
    hmath_value *flag = NULL, *inner = NULL;
    assert(hmath_value_item(NULL, value, 0, &flag) == HMATH_OK);
    int present = -1;
    assert(hmath_value_get_boolean(flag, &present) == HMATH_OK && present == expected);
    assert(hmath_value_item(NULL, value, 1, &inner) == HMATH_OK);
    int kind = -1, dtype = 0;
    size_t count = 0;
    assert(hmath_value_info(inner, &kind, &dtype, &count) == HMATH_OK && kind == 0);
    hmath_value_release(flag);
    hmath_value_release(inner);
}
int main(void) {
    hmath_value *zero = NULL, *one = NULL, *negative = NULL, *point = NULL, *normal = NULL;
    hmath_value *plane = NULL, *shifted = NULL, *result = NULL, *circle = NULL, *fields = NULL;
    hmath_value *unchanged = (hmath_value *)(uintptr_t)1;
    assert(hmath_init() == HMATH_OK);
    assert(hmath_value_f64(NULL, 0, &zero) == HMATH_OK);
    assert(hmath_value_f64(NULL, 1, &one) == HMATH_OK);
    assert(hmath_value_f64(NULL, -1, &negative) == HMATH_OK);
    assert(hmath_geometry_p3(NULL, zero, zero, one, &normal) == HMATH_OK);
    assert(hmath_geometry_plane(NULL, normal, zero, &plane) == HMATH_OK);
    assert(hmath_geometry_plane(NULL, normal, one, &shifted) == HMATH_OK);
    assert(hmath_geometry_plane_intersection(NULL, plane, shifted, &result) == HMATH_OK);
    presence(result, 0);
    hmath_value_release(result);
    assert(hmath_geometry_plane_intersection(NULL, plane, plane, &result) == HMATH_OK);
    presence(result, 1);
    hmath_value_release(result);
    assert(hmath_geometry_p2(NULL, zero, zero, &point) == HMATH_OK);
    assert(hmath_geometry_circle(NULL, point, negative, &circle) == HMATH_OK);
    assert(hmath_geometry_parts(NULL, circle, &result) == HMATH_OK);
    hmath_value_release(circle);
    assert(hmath_value_item(NULL, result, 1, &fields) == HMATH_OK);
    hmath_value_release(result);
    assert(hmath_value_item(NULL, fields, 0, &result) == HMATH_OK);
    int kind = 0, dtype = 0;
    size_t count = 0;
    assert(hmath_value_info(result, &kind, &dtype, &count) == HMATH_OK && kind == 169);
    hmath_value_release(result);
    hmath_value_release(fields);
    assert(hmath_geometry_plane_intersection(NULL, point, plane, &unchanged) == HMATH_INVALID_ARGUMENT);
    assert(unchanged == (hmath_value *)(uintptr_t)1);
    assert(hmath_geometry_parts(NULL, NULL, &unchanged) == HMATH_INVALID_ARGUMENT);
    assert(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_value_release(point);
    hmath_value_release(plane);
    hmath_value_release(shifted);
    hmath_value_release(normal);
    hmath_value_release(zero);
    hmath_value_release(one);
    hmath_value_release(negative);
    assert(hmath_runtime_shutdown() == HMATH_OK);
    puts("Geometry C nested Maybe, raw constructors, typed child lifetime and output contracts passed.");
    return 0;
}
