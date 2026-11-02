/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_rotations.h"
#include "hmath_error.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
int main(void) {
    hmath_value *one = NULL, *zero = NULL, *q = NULL, *rotation = NULL;
    hmath_value *components = NULL, *component = NULL;
    hmath_value *unchanged = (hmath_value *)(uintptr_t)1;
    double real = 0, imaginary = 0;
    assert(hmath_init() == HMATH_OK);
    assert(hmath_value_f64(NULL, 1, &one) == HMATH_OK);
    assert(hmath_value_f64(NULL, 0, &zero) == HMATH_OK);
    assert(hmath_quaternion_quaternion(NULL, one, zero, zero, zero, &q) == HMATH_OK);
    assert(hmath_rotation_so3(NULL, q, &rotation) == HMATH_OK);
    hmath_value_release(q);
    assert(hmath_rotation_rotation_quaternion(NULL, rotation, &q) == HMATH_OK);
    hmath_value_release(rotation);
    assert(hmath_quaternion_components(NULL, q, &components) == HMATH_OK);
    hmath_value_release(q);
    assert(hmath_value_item(NULL, components, 0, &component) == HMATH_OK);
    hmath_value_release(components);
    assert(hmath_value_get_f64(component, &real, &imaginary) == HMATH_OK && real == 1);
    hmath_value_release(component);
    assert(hmath_quaternion_quaternion(NULL, zero, zero, zero, zero, &q) == HMATH_OK);
    assert(hmath_quaternion_normalize(NULL, q, &unchanged) == HMATH_MATH_ERROR);
    assert(unchanged == (hmath_value *)(uintptr_t)1);
    hmath_math_error error;
    assert(hmath_last_math_error(&error) && error.kind == HMATH_MATH_DOMAIN_ERROR);
    assert(hmath_rotation_so3(NULL, one, &unchanged) == HMATH_INVALID_ARGUMENT);
    assert(unchanged == (hmath_value *)(uintptr_t)1);
    assert(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_value_release(q);
    hmath_value_release(one);
    hmath_value_release(zero);
    assert(hmath_runtime_shutdown() == HMATH_OK);
    puts("Quaternion/Rotation C ownership, distinct types and MathError contracts passed.");
    return 0;
}
