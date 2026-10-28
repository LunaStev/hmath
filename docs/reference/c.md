# C ABI reference

The ABI epoch is **1**, independent of the package version. Query it with
`hmath_abi_version()` and compare it with `HMATH_ABI_VERSION`.

| Area | Public API |
| --- | --- |
| Version and diagnostics | `hmath_abi_version`, `hmath_library_version`, `hmath_build_info`, `hmath_backend_version`, `hmath_last_error_code`, `hmath_last_error_message`, `hmath_status_string` |
| Runtime | `hmath_init`, `hmath_runtime_shutdown`, legacy `hmath_shutdown` |
| Contexts | `hmath_context_create`, `retain`, `release`, `cancel`, `reset` |
| Construction | `hmath_tensor_copy`, `hmath_tensor_borrow`, `hmath_vector_copy`, `hmath_matrix_copy` |
| Lifetime | `hmath_tensor_retain`, `hmath_tensor_release` |
| Inspection and storage | `hmath_tensor_rank`, `count`, `metadata`, `copy_to`, `data`, `reshape` |
| Allocation | `hmath_buffer_alloc`, `hmath_buffer_free` |
| Checked kernels | `hmath_scalar_add`, `hmath_tensor_sum`, `dot`, `add`, `matmul`, `map`, `hmath_batch_sum` |
| Legacy kernels | `hmath_add_f64`, `hmath_factorial`, `hmath_mean_f64`, `hmath_dot_f64` |

Names abbreviated in the table retain the family prefix. The declarations
below are included directly from the public header, so signatures and
ownership comments have a single source of truth.

## Public declarations and contracts

```c
--8<-- "include/hmath.h"
```

## CPU DLPack exchange

DLPack exchange is available through the separate public header below. Read
its ownership-transfer and deleter contracts before exporting or importing
an array. Only supported CPU tensor layouts are accepted.

```c
--8<-- "include/hmath_dlpack.h"
```

## Native backend providers

The native backend header defines provider selection, integer-width contracts,
and the BLAS/LAPACK bridge. It is an internal adapter contract used by Haskell's
backend integration, separate from the public ABI-1 tensor API above.

```c
--8<-- "include/hmath_backend.h"
```
