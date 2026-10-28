/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_dlpack.h"
#include "native_internal.h"
#include <stdlib.h>
/* Wire layouts defined by the DLPack ABI. Kept private so applications can
 * include any compatible official DLPack header without duplicate typedefs. */
typedef struct {
    int32_t device_type, device_id;
} HMDevice;
typedef struct {
    uint8_t code, bits;
    uint16_t lanes;
} HMType;
typedef struct {
    void *data;
    HMDevice device;
    int32_t ndim;
    HMType dtype;
    int64_t *shape, *strides;
    uint64_t byte_offset;
} HMDLTensor;
struct DLManagedTensor {
    HMDLTensor dl_tensor;
    void *manager_ctx;
    void (*deleter)(struct DLManagedTensor *);
};
struct DLManagedTensorVersioned {
    struct {
        uint32_t major, minor;
    } version;
    void *manager_ctx;
    void (*deleter)(struct DLManagedTensorVersioned *);
    uint64_t flags;
    HMDLTensor dl_tensor;
};
typedef struct {
    hmath_tensor *tensor;
    int64_t shape[8], strides[8];
} ExportOwner;
static void fill_dlpack_view(HMDLTensor *dl, ExportOwner *owner) {
    hmath_tensor *t = owner->tensor;
    dl->data = t->count ? (void *)t->storage->data : NULL;
    dl->device = (HMDevice){1, 0};
    dl->ndim = (int32_t)t->rank;
    dl->dtype = (HMType){2, 64, 1};
    for (size_t i = 0; i < t->rank; ++i) {
        owner->shape[i] = (int64_t)t->shape[i];
        owner->strides[i] = (int64_t)t->strides[i];
    }
    dl->shape = owner->shape;
    dl->strides = owner->strides;
    dl->byte_offset = 0;
}
static void release_legacy(struct DLManagedTensor *t) {
    if (t) {
        ExportOwner *o = t->manager_ctx;
        hmath_tensor_release(o->tensor);
        free(o);
        free(t);
    }
}
static void release_versioned(struct DLManagedTensorVersioned *t) {
    if (t) {
        ExportOwner *o = t->manager_ctx;
        hmath_tensor_release(o->tensor);
        free(o);
        free(t);
    }
}
hmath_status hmath_dlpack_export(const hmath_tensor *t, struct DLManagedTensor **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL DLPack output");
    *out = NULL;
    if (!t)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL export tensor");
    struct DLManagedTensor *dl = calloc(1, sizeof *dl);
    ExportOwner *o = calloc(1, sizeof *o);
    double *data = malloc((t->count ? t->count : 1) * sizeof(double));
    if (!dl || !o || !data) {
        free(dl);
        free(o);
        free(data);
        return hm_error(HMATH_ALLOCATION_FAILED, "DLPack allocation failed");
    }
    hmath_status s = hmath_tensor_copy_to(t, data, t->count);
    if (!s)
        s = hmath_tensor_copy(data, t->count, t->shape, t->rank, &o->tensor);
    free(data);
    if (s) {
        free(dl);
        free(o);
        return s;
    }
    fill_dlpack_view(&dl->dl_tensor, o);
    dl->manager_ctx = o;
    dl->deleter = release_legacy;
    *out = dl;
    return hm_error(HMATH_OK, "");
}
hmath_status hmath_dlpack_export_versioned(const hmath_tensor *t,
                                           struct DLManagedTensorVersioned **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL DLPack output");
    *out = NULL;
    if (!t)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL export tensor");
    struct DLManagedTensorVersioned *dl = calloc(1, sizeof *dl);
    ExportOwner *o = calloc(1, sizeof *o);
    if (!dl || !o) {
        free(dl);
        free(o);
        return hm_error(HMATH_ALLOCATION_FAILED, "DLPack allocation failed");
    }
    o->tensor = (hmath_tensor *)t;
    hmath_tensor_retain(o->tensor);
    fill_dlpack_view(&dl->dl_tensor, o);
    dl->version.major = 1;
    dl->version.minor = 0;
    dl->flags = 1;
    dl->manager_ctx = o;
    dl->deleter = release_versioned;
    *out = dl;
    return hm_error(HMATH_OK, "");
}
static void imported_legacy(void *userdata, const double *data) {
    (void)data;
    struct DLManagedTensor *t = userdata;
    if (t->deleter)
        t->deleter(t);
}
static void imported_versioned(void *userdata, const double *data) {
    (void)data;
    struct DLManagedTensorVersioned *t = userdata;
    if (t->deleter)
        t->deleter(t);
}
static hmath_status import_tensor(HMDLTensor *dl, size_t storage_elements,
                                  hmath_buffer_deleter deleter, void *userdata,
                                  hmath_tensor **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL DLPack import output");
    *out = NULL;
    if (dl->device.device_type != 1 || dl->device.device_id != 0 || dl->dtype.code != 2 ||
        dl->dtype.bits != 64 || dl->dtype.lanes != 1)
        return hm_error(HMATH_UNSUPPORTED, "DLPack needs CPU:0 native float64 lanes=1");
    if (dl->ndim < 0 || dl->ndim > 8 || (dl->ndim && !dl->shape))
        return hm_error(HMATH_SHAPE_ERROR, "invalid DLPack rank or shape");
    size_t shape[8], strides[8];
    for (int32_t i = 0; i < dl->ndim; ++i) {
        if (dl->shape[i] < 0 || (dl->strides && dl->strides[i] < 0) ||
            (uint64_t)dl->shape[i] > SIZE_MAX ||
            (dl->strides && (uint64_t)dl->strides[i] > SIZE_MAX))
            return hm_error(HMATH_UNSUPPORTED, "negative or unrepresentable DLPack metadata");
        shape[i] = (size_t)dl->shape[i];
        strides[i] = dl->strides ? (size_t)dl->strides[i] : 0;
    }
    if (dl->byte_offset > UINTPTR_MAX - (uintptr_t)dl->data || (!dl->data && dl->byte_offset))
        return hm_error(HMATH_OVERFLOW, "DLPack byte offset overflows address");
    const double *data = (const double *)((uintptr_t)dl->data + (uintptr_t)dl->byte_offset);
    return hmath_tensor_borrow(data, storage_elements, shape, dl->strides ? strides : NULL,
                               (size_t)dl->ndim, deleter, userdata, out);
}
hmath_status hmath_dlpack_import(struct DLManagedTensor *t, size_t n, hmath_tensor **out) {
    if (!t) {
        if (out)
            *out = NULL;
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL DLPack tensor");
    }
    return import_tensor(&t->dl_tensor, n, imported_legacy, t, out);
}
hmath_status hmath_dlpack_import_versioned(struct DLManagedTensorVersioned *t, size_t n,
                                           hmath_tensor **out) {
    if (out)
        *out = NULL;
    if (!t)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL DLPack tensor");
    if (t->version.major != 1)
        return hm_error(HMATH_UNSUPPORTED,
                        "unsupported DLPack major version; ownership retained by caller");
    if (t->flags & ~UINT64_C(3))
        return hm_error(HMATH_UNSUPPORTED, "unsupported DLPack flags");
    return import_tensor(&t->dl_tensor, n, imported_versioned, t, out);
}
