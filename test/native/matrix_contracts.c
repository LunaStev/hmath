/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_matrix.h"
#include <math.h>
#include <stdint.h>
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
int main(void) {
    CHECK(hmath_init() == 0);
    double data[] = {4, 2, 1, 3};
    hmath_dense_matrix *matrix = NULL, *none = NULL, *transposed = NULL;
    CHECK(hmath_dense_from_list_checked_f64(NULL, 2, 2, data, 4, &matrix) == HMATH_OK);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    CHECK(hmath_dense_precision(matrix) == 64);
    CHECK(hmath_dense_from_list_f64(NULL, 2, 3, data, 4, &none) == HMATH_OK && none == NULL);
    CHECK(hmath_last_error_code() == HMATH_OK);
    CHECK(hmath_dense_from_list_checked_f64(NULL, 2, 3, data, 4, &none) == HMATH_MATH_ERROR &&
          none == NULL);
    CHECK(strcmp(hmath_last_error_message(), "ElementCountMismatch 6 4") == 0);
    ptrdiff_t rows = -1, columns = -1;
    CHECK(hmath_dense_shape(NULL, matrix, &rows, &columns) == HMATH_OK && rows == 2 &&
          columns == 2);
    CHECK(hmath_last_error_code() == HMATH_OK);
    double value = 99;
    int found = 99;
    CHECK(hmath_dense_at_f64(NULL, matrix, 2, 0, &value, &found) == HMATH_OK && found == 0 &&
          value == 99);
    CHECK(hmath_dense_at_checked_f64(NULL, matrix, 2, 0, &value) == HMATH_MATH_ERROR &&
          value == 99);
    double out[] = {99, 99, 99, 99, 99};
    CHECK(hmath_dense_values_f64(NULL, matrix, out, 3) == HMATH_BOUNDS_ERROR && out[0] == 99 &&
          out[4] == 99);
    CHECK(hmath_dense_values_f64(NULL, matrix, out, 4) == HMATH_OK && out[0] == 4 && out[3] == 3 &&
          out[4] == 99);
    hmath_dense_lu *lu = NULL;
    CHECK(hmath_dense_lu_lu_decompose_f64(NULL, matrix, &lu) == HMATH_OK);
    hmath_dense_release(matrix);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    CHECK(hmath_dense_lu_determinant_lu_f64(NULL, lu, &value) == HMATH_OK &&
          fabs(value - 10) < 1e-12);
    hmath_dense_indices *permutation = NULL;
    CHECK(hmath_dense_lu_lu_permutation_f64(NULL, lu, &permutation) == HMATH_OK);
    ptrdiff_t indices[] = {-1, -1, -1};
    CHECK(hmath_dense_indices_copy(NULL, permutation, indices, 1) == HMATH_BOUNDS_ERROR &&
          indices[0] == -1);
    CHECK(hmath_dense_indices_copy(NULL, permutation, indices, 2) == HMATH_OK && indices[0] == 0 &&
          indices[1] == 1 && indices[2] == -1);
    hmath_dense_release(permutation);
    hmath_dense_release(lu);
    CHECK(hmath_dense_from_list_checked_f64(NULL, 0, PTRDIFF_MAX, NULL, 0, &matrix) == HMATH_OK);
    CHECK(hmath_dense_transpose_matrix_f64(NULL, matrix, &transposed) == HMATH_OK);
    CHECK(hmath_dense_shape(NULL, transposed, &rows, &columns) == HMATH_OK && rows == PTRDIFF_MAX &&
          columns == 0);
    hmath_dense_release(matrix);
    hmath_dense_release(transposed);
    float f[] = {16777216, 1};
    CHECK(hmath_dense_from_list_checked_f32(NULL, 1, 2, f, 2, &matrix) == HMATH_OK);
    CHECK(hmath_dense_precision(matrix) == 32);
    CHECK(hmath_dense_lu_determinant_f64(NULL, matrix, &value) == HMATH_INVALID_ARGUMENT);
    hmath_dense_release(matrix);
    hmath_dense_release(NULL);
    CHECK(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
