/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_NATIVE_INTERNAL_H
#define HMATH_NATIVE_INTERNAL_H
#include "hmath.h"
#include <stdatomic.h>
struct hmath_context {
    atomic_size_t refs;
    atomic_int cancelled;
};
typedef struct hmath_storage {
    atomic_size_t refs;
    const double *data;
    size_t count;
    hmath_buffer_deleter deleter;
    void *userdata;
} hmath_storage;
struct hmath_tensor {
    atomic_size_t refs;
    size_t rank, count, shape[HMATH_MAX_RANK], strides[HMATH_MAX_RANK];
    hmath_storage *storage;
};
hmath_status hm_error(hmath_status code, const char *message);
hmath_status hm_enter(hmath_context *context);
void hm_leave(void);
int hm_cancelled(const hmath_context *context);
int hm_haskell_kernel(int op, const double *a, const double *b, size_t n, size_t rows, size_t inner,
                      size_t columns, double *out);
int hm_haskell_legacy(int op, const double *a, const double *b, size_t n, double *out);
#endif
