/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_DLPACK_H
#define HMATH_DLPACK_H
#include "hmath.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Include the producer's official dlpack/dlpack.h to inspect these structs.
 * https://dmlc.github.io/dlpack/latest/ (DLPack ABI 1.0 layout).
 * CPU device 0, native-endian binary64, lanes=1, rank<=8 only.
 * Exported managed tensors must be destroyed once through their deleter.
 * Legacy exports COPY because that protocol cannot express readonly buffers.
 * Versioned exports retain a zero-copy readonly view (READ_ONLY flag).
 * Imports consume the managed tensor only on success. The caller guarantees
 * storage_elements readable elements AFTER byte_offset, because DLPack carries
 * no allocation size. Negative strides/devices/dtypes/unknown flags rejected.
 * Do not mutate imported storage while its HMath handle is live. */
struct DLManagedTensor;
struct DLManagedTensorVersioned;
HMATH_API hmath_status hmath_dlpack_export(const hmath_tensor *tensor,
                                           struct DLManagedTensor **out);
HMATH_API hmath_status hmath_dlpack_import(struct DLManagedTensor *tensor, size_t storage_elements,
                                           hmath_tensor **out);
HMATH_API hmath_status hmath_dlpack_export_versioned(const hmath_tensor *tensor,
                                                     struct DLManagedTensorVersioned **out);
HMATH_API hmath_status hmath_dlpack_import_versioned(struct DLManagedTensorVersioned *tensor,
                                                     size_t storage_elements, hmath_tensor **out);
#ifdef __cplusplus
}
#endif
#endif
