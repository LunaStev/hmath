# Architecture and ownership

## From Python to Haskell

The primary Python wrapper uses ctypes to call HMath's C ABI. The C layer
validates sizes, shapes, pointers, and runtime state before calling Haskell
numerical kernels. A binary wheel includes this C library and its required
non-system shared libraries. No Python-version-specific extension module
is needed; supported Python versions use the same C ABI.

The cffi wrapper and Wave binding call the same ABI. The complete Haskell
library additionally exposes domains that have no Python wrapper yet.

## Immutable handles, shared storage

Each native tensor handle owns a reference. Copy constructors own copied
storage; borrowed tensors retain access to caller-owned storage under an
immutability contract. A contiguous reshape creates another owner of the
same storage. Closing one handle does not invalidate another retained owner.

The Python wrapper protects operations and cleanup with locks. NumPy views
retain both a native reference and any borrowed Python owner. The last
remaining owner releases the storage. Do not mutate borrowed data through
an alias while a tensor or derived view still uses it.

## Runtime lifetime

HMath owns one GHC runtime in the process. Initialization is idempotent,
and checked numerical calls reserve the runtime while executing.
Shutdown returns a busy status if calls are active and is irreversible
once it succeeds. Do not combine HMath with independently initialized
GHC libraries in the same process.

Most Python applications should use tensor context managers and let process
exit end the runtime. Per-tensor cleanup is separate from final runtime
shutdown.

## Errors and numerical limits

Checked calls report structured status codes and a thread-local message.
Finite binary64 input, rank and element bounds, and matrix multiplication
work limits keep calls bounded. Cancellation is cooperative; an already
running Haskell kernel is not asynchronously interrupted.

These contracts detect invalid inputs within the API's documented bounds.
Like other C APIs, they cannot validate arbitrary pointers or prove the
actual size of caller-provided allocations.
