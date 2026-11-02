/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_image.h"
#include "hmath_error.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
static hmath_status add_one(const hmath_value *arguments, void *userdata, hmath_value **out) {
    (void)userdata;
    hmath_value *first = NULL;
    double real = 0, imaginary = 0;
    hmath_status status = hmath_value_item(NULL, arguments, 0, &first);
    if (!status) status = hmath_value_get_f64(first, &real, &imaginary);
    hmath_value_release(first);
    return status ? status : hmath_value_f64(NULL, real + 1, out);
}
static hmath_status source_error(const hmath_value *arguments, void *userdata, hmath_value **out) {
    (void)arguments;
    hmath_value *power = NULL;
    hmath_status status = hmath_value_f64(NULL, -1, &power);
    if (!status) status = hmath_image_gamma(NULL, power, (hmath_value *)userdata, out);
    hmath_value_release(power);
    return status;
}
int main(void) {
    hmath_value *two = NULL, *one = NULL, *quarter = NULL, *shape = NULL, *values = NULL;
    hmath_value *image = NULL, *mapped = NULL, *tensor = NULL, *child = NULL;
    hmath_value *unchanged = (hmath_value *)(uintptr_t)1;
    assert(hmath_init() == HMATH_OK);
    assert(hmath_value_index(NULL, 2, &two) == HMATH_OK);
    assert(hmath_value_index(NULL, 1, &one) == HMATH_OK);
    assert(hmath_value_f64(NULL, 0.25, &quarter) == HMATH_OK);
    const hmath_value *axes[] = {two, two};
    const hmath_value *pixels[] = {quarter, quarter, quarter, quarter};
    assert(hmath_value_list(NULL, axes, 2, &shape) == HMATH_OK);
    assert(hmath_value_list(NULL, pixels, 4, &values) == HMATH_OK);
    assert(hmath_image_image(NULL, shape, one, values, &image) == HMATH_OK);
    assert(hmath_image_map_image(NULL, add_one, NULL, image, &mapped) == HMATH_OK);
    assert(hmath_image_image_values(NULL, mapped, &child) == HMATH_OK);
    hmath_value_release(mapped);
    mapped = NULL;
    assert(hmath_value_item(NULL, child, 0, &mapped) == HMATH_OK);
    double real = 0, imaginary = 0;
    assert(hmath_value_get_f64(mapped, &real, &imaginary) == HMATH_OK && real == 1.25);
    hmath_value_release(mapped);
    hmath_value_release(child);
    assert(hmath_image_map_image(NULL, source_error, image, image, &unchanged) == HMATH_MATH_ERROR);
    assert(unchanged == (hmath_value *)(uintptr_t)1);
    hmath_math_error error;
    assert(hmath_last_math_error(&error) && error.kind == HMATH_MATH_INVALID_ARGUMENT);
    assert(hmath_image_to_tensor(NULL, image, &tensor) == HMATH_OK);
    hmath_value_release(image);
    assert(hmath_image_tensor_shape(NULL, tensor, &child) == HMATH_OK);
    assert(hmath_value_item(NULL, child, 0, &mapped) == HMATH_OK);
    ptrdiff_t axis = 0;
    assert(hmath_value_get_index(mapped, &axis) == HMATH_OK && axis == 2);
    hmath_value_release(mapped);
    hmath_value_release(child);
    assert(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_value_release(tensor);
    assert(hmath_image_image(NULL, NULL, one, values, &unchanged) == HMATH_INVALID_ARGUMENT);
    assert(unchanged == (hmath_value *)(uintptr_t)1);
    hmath_value_release(values);
    hmath_value_release(shape);
    hmath_value_release(quarter);
    hmath_value_release(one);
    hmath_value_release(two);
    assert(hmath_runtime_shutdown() == HMATH_OK);
    puts("Image C callback, MathError, Tensor lifetime and output contracts passed.");
    return 0;
}
