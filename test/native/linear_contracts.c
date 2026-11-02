/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_linear.h"
#include "hmath_matrix_value.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define CHECK(x)                                                                                   \
    do {                                                                                           \
        if (!(x)) {                                                                                \
            fprintf(stderr, "%s:%d: %s (%s)\n", __FILE__, __LINE__, #x,                            \
                    hmath_last_error_message());                                                   \
            exit(1);                                                                               \
        }                                                                                          \
    } while (0)
static hmath_status callback(const hmath_value *input, void *userdata, hmath_value **out,
                             hmath_math_error *error) {
    (void)error;
    hmath_value *row = NULL, *column = NULL;
    ptrdiff_t r = -1, c = -1;
    CHECK(hmath_value_item(NULL, input, 0, &row) == HMATH_OK);
    CHECK(hmath_value_item(NULL, input, 1, &column) == HMATH_OK);
    CHECK(hmath_value_get_index(row, &r) == HMATH_OK &&
          hmath_value_get_index(column, &c) == HMATH_OK);
    hmath_value_release(row);
    hmath_value_release(column);
    ++*(int *)userdata;
    return hmath_value_f32(NULL, (float)(r + c), out);
}
int main(void) {
    CHECK(hmath_init() == HMATH_OK);
    hmath_value *prototype = NULL, *rows = NULL, *columns = NULL, *function = NULL, *matrix = NULL,
                *type = NULL;
    CHECK(hmath_value_f32(NULL, 0, &prototype) == HMATH_OK);
    CHECK(hmath_value_index(NULL, 2, &rows) == HMATH_OK);
    CHECK(hmath_value_index(NULL, 3, &columns) == HMATH_OK);
    int calls = 0;
    CHECK(hmath_linear_callback(NULL, callback, &calls, &function) == HMATH_OK);
    CHECK(hmath_linear_matrix_advanced_generate_matrix(NULL, prototype, rows, columns, function,
                                                       &matrix) == HMATH_OK &&
          calls == 6);
    hmath_value_release(function);
    int kind = -1, dtype = -1;
    size_t count = 99;
    CHECK(hmath_value_info(matrix, &kind, &dtype, &count) == HMATH_OK && kind == 9 && dtype == 1 &&
          count == 6);
    hmath_dense_matrix *dense = NULL;
    CHECK(hmath_dense_from_value(NULL, matrix, &dense) == HMATH_OK &&
          hmath_dense_precision(dense) == 32);
    hmath_value_release(matrix);
    float values[] = {99, 99, 99, 99, 99, 99, 99};
    CHECK(hmath_dense_values_f32(NULL, dense, values, 6) == HMATH_OK && values[0] == 0 &&
          values[1] == 1 && values[5] == 3 && values[6] == 99);
    hmath_dense_release(dense);
    /* Original KnownNat mismatch is checked, not a changed dynamic-vector API. */
    hmath_value *element = NULL, *list = NULL, *fixed = NULL;
    CHECK(hmath_value_f32(NULL, 1, &element) == HMATH_OK);
    const hmath_value *items[] = {element};
    CHECK(hmath_value_list(NULL, items, 1, &list) == HMATH_OK);
    CHECK(hmath_linear_vector_fixed_vector(NULL, prototype, rows, list, &fixed) ==
              HMATH_MATH_ERROR &&
          fixed == NULL);
    hmath_math_error math;
    CHECK(hmath_last_math_error(&math) == 1 && math.kind == HMATH_MATH_INVALID_ARGUMENT);
    hmath_value_release(list);
    hmath_value_release(element);
    /* An immutable backend/record handle pins the runtime independently. */
    hmath_value *backend = NULL, *info = NULL;
    CHECK(hmath_linear_backend_pure_backend(NULL, &backend) == HMATH_OK);
    CHECK(hmath_linear_backend_backend_info(NULL, backend, &info) == HMATH_OK);
    hmath_value_release(backend);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    CHECK(hmath_linear_object_type(NULL, info, &type) == HMATH_OK);
    CHECK(hmath_value_info(type, &kind, &dtype, &count) == HMATH_OK && kind == 10 && count == 25);
    uint32_t text[25];
    CHECK(hmath_value_get_text(type, text, 25) == HMATH_OK && text[0] == 'H' && text[24] == 'o');
    hmath_value_release(type);
    hmath_value_release(info);
    hmath_value_release(rows);
    hmath_value_release(columns);
    hmath_value_release(prototype);
    CHECK(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
