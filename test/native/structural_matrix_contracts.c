/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_matrix_value.h"
#include <stdio.h>
#include <stdlib.h>
#define CHECK(x)                                                                                   \
    do {                                                                                           \
        if (!(x)) {                                                                                \
            fprintf(stderr, "line%d: %s\n", __LINE__, hmath_last_error_message());                 \
            exit(1);                                                                               \
        }                                                                                          \
    } while (0)
int main(void) {
    CHECK(hmath_init() == HMATH_OK);
    hmath_value *yes = NULL, *no = NULL, *one = NULL, *two = NULL, *list = NULL, *matrix = NULL,
                *column = NULL, *output = NULL;
    CHECK(hmath_value_boolean(NULL, 1, &yes) == HMATH_OK &&
          hmath_value_boolean(NULL, 0, &no) == HMATH_OK);
    CHECK(hmath_value_index(NULL, 1, &one) == HMATH_OK &&
          hmath_value_index(NULL, 2, &two) == HMATH_OK);
    const hmath_value *items[] = {yes, no};
    CHECK(hmath_value_list(NULL, items, 2, &list) == HMATH_OK);
    CHECK(hmath_matrix_value_from_list_checked(NULL, no, one, two, list, &matrix) == HMATH_OK);
    int kind = -1, dtype = -1;
    size_t count = 0;
    CHECK(hmath_value_info(matrix, &kind, &dtype, &count) == HMATH_OK && kind == 9 &&
          dtype == HMATH_MATRIX_BOOL && count == 2);
    CHECK(hmath_matrix_value_transpose_matrix(NULL, matrix, &column) == HMATH_OK);
    hmath_value_release(matrix);
    hmath_value_release(list);
    hmath_value_release(yes);
    CHECK(hmath_matrix_value_to_list(NULL, column, &list) == HMATH_OK);
    CHECK(hmath_value_item(NULL, list, 0, &output) == HMATH_OK);
    int boolean = 0;
    CHECK(hmath_value_get_boolean(output, &boolean) == HMATH_OK && boolean == 1);
    hmath_value_release(output);
    hmath_value_release(list);
    output = (hmath_value *)(uintptr_t)1;
    CHECK(hmath_matrix_value_zero_matrix(NULL, no, one, two, &output) == HMATH_UNSUPPORTED &&
          output == (hmath_value *)(uintptr_t)1);
    hmath_value_release(column);
    hmath_value_release(no);
    hmath_value_release(one);
    hmath_value_release(two);
    CHECK(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
