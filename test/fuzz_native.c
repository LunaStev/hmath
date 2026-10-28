/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath.h"
#include "hmath_dlpack.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* Metadata/ownership fuzzing does not enter a GHC runtime. Any accidental
 * numerical call aborts, so a stub cannot masquerade as a tested kernel. */
hmath_status hm_enter(hmath_context *context) {
    (void)context;
    abort();
}
void hm_leave(void) { abort(); }
int hm_haskell_kernel(int op, const double *a, const double *b, size_t n, size_t rows, size_t inner,
                      size_t columns, double *out) {
    (void)op;
    (void)a;
    (void)b;
    (void)n;
    (void)rows;
    (void)inner;
    (void)columns;
    (void)out;
    abort();
}
int LLVMFuzzerTestOneInput(const uint8_t *bytes, size_t size) {
    if (size < 18)
        return 0;
    double values[64] = {0}, output[64] = {0};
    size_t shape[8] = {0}, strides[8] = {0}, metadata[8] = {0};
    const size_t rank = bytes[0] % 9;
    const size_t count = bytes[1] % 65;
    for (size_t i = 0; i < rank; ++i) {
        shape[i] = bytes[2 + i];
        strides[i] = bytes[10 + i];
    }
    const size_t available = size - 18 < sizeof values ? size - 18 : sizeof values;
    memcpy(values, bytes + 18, available);
    hmath_tensor *tensor = NULL;
    hmath_status status = hmath_tensor_copy(values, count, shape, rank, &tensor);
    if (status == HMATH_OK) {
        if (hmath_tensor_count(tensor) != count)
            abort();
        if (hmath_tensor_copy_to(tensor, output, 64) != HMATH_OK)
            abort();
        hmath_tensor *view = NULL;
        size_t flat[] = {count};
        if (hmath_tensor_reshape(tensor, flat, 1, &view) != HMATH_OK)
            abort();
        hmath_tensor_release(view);
        struct DLManagedTensorVersioned *managed = NULL;
        if (hmath_dlpack_export_versioned(tensor, &managed) != HMATH_OK)
            abort();
        hmath_tensor *roundtrip = NULL;
        if (hmath_dlpack_import_versioned(managed, count, &roundtrip) != HMATH_OK)
            abort();
        hmath_tensor_release(roundtrip);
        hmath_tensor_release(tensor);
    } else if (tensor != NULL)
        abort();
    tensor = NULL;
    status = hmath_tensor_borrow(values, 64, shape, strides, rank, NULL, NULL, &tensor);
    if (status == HMATH_OK) {
        (void)hmath_tensor_metadata(tensor, metadata, strides, bytes[1] % 9);
        (void)hmath_tensor_copy_to(tensor, output, 64);
        hmath_tensor_release(tensor);
    } else if (tensor != NULL)
        abort();
    void *buffer = NULL;
    if (hmath_buffer_alloc(count * 8, (size_t)1 << (bytes[2] % 14), &buffer) == HMATH_OK)
        hmath_buffer_free(buffer);
    return 0;
}
