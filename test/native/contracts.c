/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath.h"
#include "hmath_dlpack.h"
#include <float.h>
#include <math.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define CHECK(x)                                                                                   \
    do {                                                                                           \
        if (!(x)) {                                                                                \
            fprintf(stderr, "native contract failure at %s:%d: %s (%s)\n", __FILE__, __LINE__, #x, \
                    hmath_last_error_message());                                                   \
            exit(1);                                                                               \
        }                                                                                          \
    } while (0)
#define OK(x) CHECK((x) == HMATH_OK)
/* Independent public DLPack ABI layouts, not HMath implementation headers. */
typedef struct {
    void *data;
    struct {
        int32_t kind, id;
    } device;
    int32_t rank;
    struct {
        uint8_t code, bits;
        uint16_t lanes;
    } type;
    int64_t *shape, *strides;
    uint64_t offset;
} DLTensorTest;
struct DLManagedTensor {
    DLTensorTest tensor;
    void *context;
    void (*deleter)(struct DLManagedTensor *);
};
struct DLManagedTensorVersioned {
    struct {
        uint32_t major, minor;
    } version;
    void *context;
    void (*deleter)(struct DLManagedTensorVersioned *);
    uint64_t flags;
    DLTensorTest tensor;
};
static int freed;
static void count_free(void *user, const double *data) {
    CHECK(user == &freed);
    CHECK(data != NULL);
    ++freed;
}
static hmath_status times_two(double x, size_t i, void *user, double *out) {
    (void)i;
    CHECK(user == &freed);
    *out = 2 * x;
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    return HMATH_OK;
}
static hmath_status cancel_map(double x, size_t i, void *user, double *out) {
    *out = x;
    if (i == 1)
        hmath_context_cancel(user);
    return HMATH_OK;
}
static hmath_status callback_error(double x, size_t i, void *user, double *out) {
    (void)x;
    (void)i;
    (void)user;
    (void)out;
    return HMATH_INVALID_ARGUMENT;
}
static pthread_mutex_t gate = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t condition = PTHREAD_COND_INITIALIZER;
static int entered, finish;
static hmath_status blocked(double x, size_t i, void *user, double *out) {
    (void)i;
    (void)user;
    pthread_mutex_lock(&gate);
    entered = 1;
    pthread_cond_signal(&condition);
    while (!finish)
        pthread_cond_wait(&condition, &gate);
    pthread_mutex_unlock(&gate);
    *out = x;
    return HMATH_OK;
}
static void *blocked_worker(void *arg) {
    hmath_tensor *out = NULL;
    OK(hmath_tensor_map(NULL, arg, blocked, NULL, &out));
    hmath_tensor_release(out);
    return NULL;
}
static void *worker(void *arg) {
    const hmath_tensor *t = arg;
    for (int i = 0; i < 200; ++i) {
        double v;
        OK(hmath_tensor_sum(NULL, t, &v));
        CHECK(v == 10);
        hmath_tensor_retain((hmath_tensor *)t);
        hmath_tensor_release((hmath_tensor *)t);
    }
    CHECK(hmath_scalar_add(NULL, NAN, 0, NULL) == HMATH_INVALID_ARGUMENT);
    CHECK(hmath_last_error_code() == HMATH_INVALID_ARGUMENT);
    return NULL;
}
int main(void) {
    CHECK(hmath_abi_version() == 1);
    CHECK(strlen(hmath_library_version()) > 0);
    CHECK(strlen(hmath_build_info()) > 0);
    CHECK(strlen(hmath_backend_version()) > 0);
    CHECK(strcmp(hmath_status_string(HMATH_OK), "ok") == 0);
    double answer = 77;
    CHECK(hmath_scalar_add(NULL, 1, 2, &answer) == HMATH_RUNTIME_ERROR);
    CHECK(answer == 77);
    OK(hmath_runtime_shutdown());
    CHECK(hmath_init() == 0);
    CHECK(hmath_init() == 0);
    OK(hmath_scalar_add(NULL, 2, 3, &answer));
    CHECK(answer == 5);
    CHECK(hmath_scalar_add(NULL, DBL_MAX, DBL_MAX, &answer) == HMATH_OVERFLOW);
    CHECK(answer == 5);
    CHECK(hmath_add_f64(2, 3) == 5);
    CHECK(hmath_factorial(20) == 2432902008176640000LL);
    CHECK(hmath_factorial(21) == -1);
    CHECK(isnan(hmath_mean_f64(NULL, 0)));
    CHECK(hmath_dot_f64(NULL, NULL, 0) == 0);
    double data[] = {1, 2, 3, 4};
    size_t shape[] = {2, 2};
    hmath_tensor *a = NULL, *b = NULL, *out = NULL;
    OK(hmath_matrix_copy(data, 4, 2, 2, &a));
    OK(hmath_tensor_sum(NULL, a, &answer));
    CHECK(answer == 10);
    OK(hmath_tensor_dot(NULL, a, a, &answer));
    CHECK(answer == 30);
    OK(hmath_tensor_matmul(NULL, a, a, &out));
    double result[4];
    OK(hmath_tensor_copy_to(out, result, 4));
    CHECK(result[0] == 7 && result[1] == 10 && result[2] == 15 && result[3] == 22);
    hmath_tensor_release(out);
    OK(hmath_tensor_add(NULL, a, a, &out));
    OK(hmath_tensor_copy_to(out, result, 4));
    CHECK(result[0] == 2 && result[3] == 8);
    hmath_tensor_release(out);
    CHECK(hmath_tensor_copy(data, 3, shape, 2, &out) == HMATH_SHAPE_ERROR);
    CHECK(!out);
    CHECK(hmath_tensor_copy(NULL, 4, shape, 2, &out) == HMATH_INVALID_ARGUMENT);
    CHECK(hmath_tensor_copy(data, 4, NULL, 2, &out) == HMATH_SHAPE_ERROR);
    CHECK(hmath_tensor_copy(data, 4, shape, 9, &out) == HMATH_SHAPE_ERROR);
    size_t huge[] = {SIZE_MAX, 2};
    CHECK(hmath_tensor_copy(data, 4, huge, 2, &out) == HMATH_OVERFLOW);
    CHECK(hmath_tensor_copy_to(a, result, 3) == HMATH_BOUNDS_ERROR);
    size_t dims[2], strides[2];
    OK(hmath_tensor_metadata(a, dims, strides, 2));
    CHECK(dims[0] == 2 && strides[0] == 2 && strides[1] == 1);
    CHECK(hmath_tensor_metadata(a, dims, strides, 1) == HMATH_BOUNDS_ERROR);
    const double *borrowed;
    size_t storage;
    OK(hmath_tensor_data(a, &borrowed, &storage));
    CHECK(storage == 4 && borrowed[2] == 3);
    CHECK(hmath_tensor_copy_to(a, (double *)borrowed, 4) == HMATH_INVALID_ARGUMENT);
    _Alignas(double) unsigned char misaligned[32];
    CHECK(hmath_vector_copy((const double *)(misaligned + 1), 1, &out) == HMATH_INVALID_ARGUMENT);
    CHECK(hmath_scalar_add(NULL, 1, 2, (double *)(misaligned + 1)) == HMATH_INVALID_ARGUMENT);
    CHECK(hmath_tensor_sum(NULL, a, (double *)(misaligned + 1)) == HMATH_INVALID_ARGUMENT);
    CHECK(hmath_tensor_dot(NULL, a, a, (double *)(misaligned + 1)) == HMATH_INVALID_ARGUMENT);
    const hmath_tensor *alignment_batch[] = {a};
    size_t alignment_completed = 7;
    CHECK(hmath_batch_sum(NULL, alignment_batch, 1, (double *)(misaligned + 1),
                          &alignment_completed) == HMATH_INVALID_ARGUMENT);
    CHECK(alignment_completed == 0);
    _Alignas(size_t) unsigned char bad_count[sizeof(size_t) + 1];
    CHECK(hmath_batch_sum(NULL, alignment_batch, 1, &answer, (size_t *)(bad_count + 1)) ==
          HMATH_INVALID_ARGUMENT);

    double bad[] = {NAN};
    CHECK(hmath_vector_copy(bad, 1, &out) == HMATH_INVALID_ARGUMENT);
    bad[0] = INFINITY;
    CHECK(hmath_vector_copy(bad, 1, &out) == HMATH_INVALID_ARGUMENT);
    size_t transpose[] = {1, 2};
    OK(hmath_tensor_borrow(data, 4, shape, transpose, 2, count_free, &freed, &b));
    OK(hmath_tensor_copy_to(b, result, 4));
    CHECK(result[0] == 1 && result[1] == 3 && result[2] == 2 && result[3] == 4);
    size_t four = 4;
    CHECK(hmath_tensor_reshape(b, &four, 1, &out) == HMATH_SHAPE_ERROR);
    hmath_tensor_retain(b);
    hmath_tensor_release(b);
    CHECK(freed == 0);
    hmath_tensor_release(b);
    CHECK(freed == 1);
    OK(hmath_tensor_borrow(data, 4, shape, NULL, 2, count_free, &freed, &b));
    OK(hmath_tensor_reshape(b, &four, 1, &out));
    hmath_tensor_release(b);
    CHECK(freed == 1);
    OK(hmath_tensor_sum(NULL, out, &answer));
    CHECK(answer == 10);
    hmath_tensor_release(out);
    CHECK(freed == 2);
    size_t invalid_steps[] = {4, 1};
    CHECK(hmath_tensor_borrow(data, 4, shape, invalid_steps, 2, count_free, &freed, &out) ==
          HMATH_BOUNDS_ERROR);
    CHECK(freed == 2);
    void *aligned = NULL;
    OK(hmath_buffer_alloc(19, 256, &aligned));
    CHECK((uintptr_t)aligned % 256 == 0);
    hmath_buffer_free(aligned);
    CHECK(hmath_buffer_alloc(8, 3, &aligned) == HMATH_INVALID_ARGUMENT);
    CHECK(!aligned);
    CHECK(hmath_buffer_alloc(SIZE_MAX, 64, &aligned) == HMATH_OVERFLOW);
    hmath_context *c = NULL;
    OK(hmath_context_create(&c));
    hmath_context_retain(c);
    hmath_context_release(c);
    hmath_context_cancel(c);
    answer = 77;
    CHECK(hmath_tensor_sum(c, a, &answer) == HMATH_CANCELLED);
    CHECK(answer == 77);
    hmath_context_reset(c);
    OK(hmath_tensor_sum(c, a, &answer));
    OK(hmath_tensor_map(c, a, times_two, &freed, &out));
    OK(hmath_tensor_sum(c, out, &answer));
    CHECK(answer == 20);
    hmath_tensor_release(out);
    CHECK(hmath_tensor_map(c, a, cancel_map, c, &out) == HMATH_CANCELLED);
    CHECK(!out);
    hmath_context_reset(c);
    CHECK(hmath_tensor_map(c, a, callback_error, NULL, &out) == HMATH_INVALID_ARGUMENT);
    CHECK(!out);
    const hmath_tensor *batch[] = {a, NULL, a};
    double sums[] = {-1, -1, -1};
    size_t completed = 99;
    CHECK(hmath_batch_sum(c, batch, 3, sums, &completed) == HMATH_INVALID_ARGUMENT);
    CHECK(completed == 1 && sums[0] == 10 && sums[1] == -1 && sums[2] == -1);
    CHECK(hmath_batch_sum(c, batch, 4097, sums, &completed) == HMATH_OVERFLOW);
    hmath_context_release(c);
    /* Empty dimensions and every small rectangular matrix shape. */
    for (size_t rows = 0; rows < 5; ++rows)
        for (size_t inner = 0; inner < 5; ++inner)
            for (size_t columns = 0; columns < 5; ++columns) {
                double x[16], y[16], z[16];
                for (size_t i = 0; i < 16; ++i) {
                    x[i] = (double)(i + 1);
                    y[i] = (double)((int)(i % 3) - 1);
                }
                hmath_tensor *l, *r, *p;
                OK(hmath_matrix_copy(x, rows * inner, rows, inner, &l));
                OK(hmath_matrix_copy(y, inner * columns, inner, columns, &r));
                OK(hmath_tensor_matmul(NULL, l, r, &p));
                OK(hmath_tensor_copy_to(p, z, rows * columns));
                for (size_t i = 0; i < rows; ++i)
                    for (size_t j = 0; j < columns; ++j) {
                        double expected = 0;
                        for (size_t k = 0; k < inner; ++k)
                            expected += x[i * inner + k] * y[k * columns + j];
                        CHECK(z[i * columns + j] == expected);
                    }
                hmath_tensor_release(l);
                hmath_tensor_release(r);
                hmath_tensor_release(p);
            }
    size_t empty_shape[] = {0, 0, 110, 0, 97, 221, 146, 49};
    size_t empty_flat = 0;
    OK(hmath_tensor_copy(NULL, 0, empty_shape, 8, &b));
    OK(hmath_tensor_reshape(b, &empty_flat, 1, &out));
    hmath_tensor_release(out);
    hmath_tensor_release(b);
    size_t trailing_zero[] = {1048576, 1048576, 0};
    OK(hmath_tensor_copy(NULL, 0, trailing_zero, 3, &b));
    OK(hmath_tensor_reshape(b, &empty_flat, 1, &out));
    hmath_tensor_release(out);
    hmath_tensor_release(b);
    struct DLManagedTensor *dl = NULL;
    OK(hmath_dlpack_export(a, &dl));
    CHECK(dl->tensor.rank == 2 && dl->tensor.type.code == 2 && dl->tensor.type.bits == 64);
    ((double *)dl->tensor.data)[0] = 9;
    OK(hmath_tensor_sum(NULL, a, &answer));
    CHECK(answer == 10);
    OK(hmath_dlpack_import(dl, 4, &b));
    OK(hmath_tensor_sum(NULL, b, &answer));
    CHECK(answer == 18);
    hmath_tensor_release(b);
    struct DLManagedTensorVersioned *dv = NULL;
    OK(hmath_dlpack_export_versioned(a, &dv));
    CHECK(dv->version.major == 1 && dv->flags == 1);
    CHECK(dv->tensor.data == borrowed);
    dv->version.major = 9;
    CHECK(hmath_dlpack_import_versioned(dv, 4, &b) == HMATH_UNSUPPORTED);
    CHECK(!b);
    dv->version.major = 1;
    dv->flags = 8;
    CHECK(hmath_dlpack_import_versioned(dv, 4, &b) == HMATH_UNSUPPORTED);
    dv->flags = 1;
    dv->tensor.strides[0] = -1;
    CHECK(hmath_dlpack_import_versioned(dv, 4, &b) == HMATH_UNSUPPORTED);
    dv->tensor.strides[0] = 2;
    CHECK(hmath_dlpack_import_versioned(dv, 3, &b) == HMATH_BOUNDS_ERROR);
    OK(hmath_dlpack_import_versioned(dv, 4, &b));
    hmath_tensor_release(b);
    pthread_t threads[4];
    OK(hmath_scalar_add(NULL, 1, 1, &answer));
    for (size_t i = 0; i < 4; ++i)
        CHECK(pthread_create(&threads[i], NULL, worker, a) == 0);
    for (size_t i = 0; i < 4; ++i)
        CHECK(pthread_join(threads[i], NULL) == 0);
    CHECK(hmath_last_error_code() == HMATH_OK);
    pthread_t waiting;
    CHECK(pthread_create(&waiting, NULL, blocked_worker, a) == 0);
    pthread_mutex_lock(&gate);
    while (!entered)
        pthread_cond_wait(&condition, &gate);
    pthread_mutex_unlock(&gate);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    pthread_mutex_lock(&gate);
    finish = 1;
    pthread_cond_signal(&condition);
    pthread_mutex_unlock(&gate);
    CHECK(pthread_join(waiting, NULL) == 0);
    /* Private probe deliberately throws before any memory write. */
    extern int hm_haskell_kernel(int, const double *, const double *, size_t, size_t, size_t,
                                 size_t, double *);
    answer = 77;
    CHECK(hm_haskell_kernel(99, data, data, 4, 0, 0, 0, &answer) == HMATH_HASKELL_EXCEPTION);
    CHECK(answer == 77);
    hmath_tensor_release(a);
    hmath_tensor_release(NULL);
    hmath_context_release(NULL);
    OK(hmath_runtime_shutdown());
    CHECK(hmath_init() == HMATH_INIT_ALREADY_SHUT_DOWN);
    CHECK(hmath_scalar_add(NULL, 1, 2, &answer) == HMATH_RUNTIME_ERROR);
    CHECK(isnan(hmath_add_f64(1, 2)));
    OK(hmath_runtime_shutdown());
    puts("Native ABI: lifecycle, Haskell exceptions, shapes, 125 matrix products, ownership, "
         "DLPack, callbacks, cancellation, TLS and threads passed");
    return 0;
}
