/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_tensor_bindings.h"
#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <string.h>
static hmath_status square(const hmath_value *arguments, void *userdata, hmath_value **out,
                           hmath_callback_error *error) {
    (void)error;
    hmath_value *item = NULL;
    float value, imaginary;
    assert(hmath_value_item(NULL, arguments, 0, &item) == HMATH_OK);
    assert(hmath_value_get_f32(item, &value, &imaginary) == HMATH_OK);
    hmath_value_release(item);
    ++*(int *)userdata;
    return hmath_value_f32(NULL, value * value, out);
}
static hmath_status mutate(void *pointer, const hmath_value *metadata, void *userdata,
                           hmath_value **out, hmath_callback_error *error) {
    (void)userdata;
    (void)error;
    hmath_value *bytes = NULL;
    ptrdiff_t itemsize;
    assert(hmath_value_item(NULL, metadata, 3, &bytes) == HMATH_OK);
    assert(hmath_value_get_index(bytes, &itemsize) == HMATH_OK && itemsize == sizeof(float));
    hmath_value_release(bytes);
    ((float *)pointer)[0] = 7;
    return hmath_value_none(NULL, out);
}
int main(void) {
    assert(hmath_init() == HMATH_INIT_OK);
    hmath_value *type = NULL, *dimension = NULL, *shape = NULL, *first = NULL, *second = NULL,
                *elements = NULL, *tensor = NULL;
    assert(hmath_value_f32(NULL, 0, &type) == HMATH_OK);
    assert(hmath_value_index(NULL, 2, &dimension) == HMATH_OK);
    const hmath_value *dims[] = {dimension};
    assert(hmath_value_list(NULL, dims, 1, &shape) == HMATH_OK);
    assert(hmath_value_f32(NULL, 2, &first) == HMATH_OK);
    assert(hmath_value_f32(NULL, 3, &second) == HMATH_OK);
    const hmath_value *values[] = {first, second};
    assert(hmath_value_list(NULL, values, 2, &elements) == HMATH_OK);
    assert(hmath_tensor_object_tensor(NULL, type, shape, elements, &tensor) == HMATH_OK);
    int count = 0;
    hmath_value *callback = NULL, *leaf = NULL, *graph = NULL, *result = NULL, *items = NULL,
                *item = NULL;
    assert(hmath_tensor_object_callback(NULL, square, &count, &callback) == HMATH_OK);
    assert(hmath_tensor_object_input_graph(NULL, tensor, &leaf) == HMATH_OK);
    assert(hmath_tensor_object_map_graph(NULL, type, callback, leaf, &graph) == HMATH_OK);
    assert(count == 0);
    hmath_value_release(callback);
    hmath_value_release(leaf);
    hmath_value_release(tensor);
    assert(hmath_tensor_object_evaluate_graph(NULL, graph, &result) == HMATH_OK && count == 2);
    assert(hmath_tensor_object_tensor_values(NULL, result, &items) == HMATH_OK);
    assert(hmath_value_item(NULL, items, 1, &item) == HMATH_OK);
    float real, imaginary;
    assert(hmath_value_get_f32(item, &real, &imaginary) == HMATH_OK && real == 9);
    hmath_value_release(item);
    hmath_value_release(items);
    hmath_value *mutable_tensor = NULL, *buffer_callback = NULL, *unit = NULL;
    assert(hmath_tensor_object_thaw_tensor(NULL, result, &mutable_tensor) == HMATH_OK);
    assert(hmath_tensor_object_buffer_callback(NULL, mutate, NULL, &buffer_callback) == HMATH_OK);
    assert(hmath_tensor_object_with_mutable_buffer(NULL, mutable_tensor, buffer_callback, &unit) ==
           HMATH_OK);
    hmath_value_release(unit);
    hmath_value_release(buffer_callback);
    hmath_value *frozen = NULL;
    assert(hmath_tensor_object_freeze_tensor(NULL, mutable_tensor, &frozen) == HMATH_OK);
    assert(hmath_tensor_object_tensor_values(NULL, frozen, &items) == HMATH_OK);
    assert(hmath_value_item(NULL, items, 0, &item) == HMATH_OK);
    assert(hmath_value_get_f32(item, &real, &imaginary) == HMATH_OK && real == 7);
    hmath_value_release(item);
    hmath_value_release(items);
    hmath_value_release(frozen);
    hmath_value_release(mutable_tensor);
    hmath_value_release(result);
    hmath_value *invalid = (hmath_value *)(uintptr_t)0x1234;
    assert(hmath_tensor_object_tensor(NULL, type, shape, NULL, &invalid) == HMATH_INVALID_ARGUMENT);
    assert(invalid == (hmath_value *)(uintptr_t)0x1234);
    assert(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_value_release(graph);
    hmath_value_release(type);
    hmath_value_release(dimension);
    hmath_value_release(shape);
    hmath_value_release(first);
    hmath_value_release(second);
    hmath_value_release(elements);
    assert(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
