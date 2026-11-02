# Buffer execution

The execution API provides an explicit route for CPU matrix products on caller
buffers. Include `hmath_execution.h` in C/C++; in Python use
`from hmath import execution`. It supports binary32 and binary64 and row-major
matrices with consecutive columns and optional padding between rows.

This API is separate from the original dense matrix and tensor interfaces.
It does not change their arithmetic, limits, finite checks or failure behavior.
It is not a claim that the complete `HMath.Backend` API has been bound.

## Provider and resource selection

`hmath_execution_create(options, &out)` constructs an immutable execution handle.
A NULL options pointer selects the reference implementation with no artificial
resource caps. Python uses `execution.Execution(...)`.

| Option | Meaning | Default |
| --- | --- | --- |
| `provider` | `REFERENCE`, `OPENBLAS`, `BLIS`, `MKL`, or `ACCELERATE`; Python also accepts lowercase names | `REFERENCE` |
| `integer_bits` | BLAS integer ABI: 32 for LP64 or 64 for ILP64; zero selects LP64 in C | 32 |
| `library_path` | Optional explicit provider library path; incompatible ABIs are rejected | NULL / None |
| `max_elements` | Maximum logical element count of each A, B and C view | 0, no artificial cap |
| `max_multiply_adds` | Maximum m×n×k work count per call | 0, no artificial cap |

A requested provider never silently falls back when unavailable. The reference
path does not require OpenBLAS or another BLAS installation. Single-precision
SGEMM is an optional provider capability: if missing, FP32 execution returns
`HMATH_UNSUPPORTED`; double-precision DGEMM can remain available. No conversion to
FP64 is used as a fallback. Existing `HMATH_BACKEND` provider policy also applies.

Checked dimension products, byte spans, pointer ranges and allocation failures
remain active when resource policies are zero. Provider calls must also fit the
selected LP64/ILP64 integer ABI, including all leading dimensions. These caps
are policies for logical sizes/work, not a guarantee of a fixed process heap
budget. The reference Haskell implementation needs temporary lists/matrices;
provider execution passes buffers directly without numeric staging allocations.
The legacy tensor limits of 1,048,576 elements and 16,777,216 multiply-adds do
not apply to this new API.

Execution handles own provider library references. C callers use
`hmath_execution_retain/release`; NULL retain/release is a no-op. Python callers
use `close()` or a `with` block. A handle alone does not pin the Haskell runtime,
but each numerical call reserves it until execution finishes. Each concurrent
caller must hold a live handle reference and use an independent output buffer.
Provider interface-layer settings must not be changed concurrently by external
code; this is particularly relevant to MKL's process-wide integer ABI.

## Views and GEMM

`hmath_execution_view` describes a readable input; `hmath_execution_output`
describes a writable output. Both contain:

| Field | Contract |
| --- | --- |
| `data` | Pointer aligned for the selected float32/float64 type |
| `storage_count` | Readable/writable backing count in elements |
| `rows`, `columns` | Logical dimensions |
| `leading_dimension` | Distance between row starts in elements, at least `columns` for a nonempty matrix |

Columns must be consecutive. Negative strides, column-strided layouts and
transposition are not supported by this entry point. Empty shapes preserve their
metadata and need no data pointer. For a nonempty view, the reachable span is
`(rows - 1) * leading_dimension + columns`; it is checked against the backing
count without overflowing. The caller guarantees that the actual allocation
matches the described span. Arbitrary addresses and allocations cannot be
validated by a C library.

```c
hmath_status hmath_execution_gemm_f32(
    hmath_execution *execution, hmath_context *context,
    float alpha, const hmath_execution_view *a,
    const hmath_execution_view *b, float beta,
    const hmath_execution_output *c);

hmath_status hmath_execution_gemm_f64(
    hmath_execution *execution, hmath_context *context,
    double alpha, const hmath_execution_view *a,
    const hmath_execution_view *b, double beta,
    const hmath_execution_output *c);
```

Both compute **C := αAB + βC**. A has shape m×k, B has shape k×n, and C must have
shape m×n. A and B may overlap each other; the complete reachable output span,
including padding between rows, must not overlap either input span. Padding is
preserved. Inputs and metadata are borrowed for the synchronous call and must
remain live and unchanged, including through aliases.

Runtime initialization is required. A NULL context disables cancellation;
cancellation is checked before and after execution. An in-flight BLAS call is
not interrupted.

The reference path uses the existing Haskell `Matrix.multiplyChecked`,
`scaleMatrix` and `addMatrixChecked` at the selected `Float`/`Double` precision.
Optimized providers execute SGEMM/DGEMM on the supplied pointers and may use a
different reduction or FMA order. Numerical results can therefore differ in their
last bits across providers; selecting an optimized provider is explicit.

## Finite values and output on failure

The finite-input policy matches the existing checked Haskell `Backend.gemm`:
α, β and every logical A/B/C element must be finite, **including initial C when
β = 0**. Padding values are not numerical inputs. `NonFiniteVectorEntry i` is
reported through `HMATH_MATH_ERROR` / Python `HMathError(status=11)`, with indices
in `[alpha,beta] ++ logical(A) ++ logical(B) ++ logical(C)`. Output errors index
logical C. Shape, byte-span, alias, resource-limit and provider errors are
binding-level status codes.

Validation errors preserve C. Once a kernel starts, numeric failure or
cancellation may leave C modified. Direct-output execution is not transactional.
The reference path calculates and checks its result before copying to C; an
optimized provider writes C directly and a later finite check may fail. A
post-kernel cancellation can also report failure after C has been written.

## Python buffers

`Execution.gemm(a, b, out, *, alpha=1, beta=0)` borrows NumPy arrays and returns
the same `out` object. Arrays must have the same native-endian float32/float64
dtype, aligned storage, consecutive columns and nonnegative row strides.
`out` must be writable. Padded rows are accepted without copying. Unsupported
layouts and mixed dtypes are rejected rather than silently converted.

`Execution.matmul(a, b)` is a convenience method that allocates a zeroed output
of the input dtype, then executes GEMM. Use `gemm` with a reusable output to avoid
that allocation. NumPy is an optional Python dependency; the C execution API does
not depend on NumPy.

```python
import numpy as np
from hmath import execution

with execution.Execution("reference") as engine:
    a = np.array([[1, 2], [3, 4]], dtype=np.float32)
    b = np.array([[2, 0], [1, 2]], dtype=np.float32)
    out = np.zeros((2, 2), dtype=np.float32)
    assert engine.gemm(a, b, out) is out
    assert out.dtype == np.float32
    assert out.tolist() == [[4.0, 4.0], [10.0, 8.0]]
```

See also: [dense matrix contracts](matrix-bindings.md),
[numerical conventions](../explanation/numerical-conventions.md),
[C runtime and errors](c.md).
