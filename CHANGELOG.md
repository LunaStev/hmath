# Changelog

## 1.0.0 — Unreleased

- Add checked native tensors, ownership and cancellation contracts, and CPU DLPack exchange.
- Establish C, Python, and Wave as the officially maintained external interfaces.
- Add configurable BLAS/LAPACK providers and pure reference operations.
- Add Haskell shape, algebra, buffer, and convergence interfaces and typed array interchange.
- Add integrated validation, benchmarks, native installation checks, and build metadata.

The first release covers the implemented Haskell numerical modules and the
C, Python, and Wave interfaces on Linux x86-64. Python distributions contain
bindings and require a separately installed HMath shared library.

Package versions follow SemVer: compatible fixes increment the patch, compatible
features increment the minor, and breaking public API changes increment the major.
C ABI epoch 1 is reported independently and identifies the calling and ownership
conventions. Existing legacy C symbols remain available. GPU execution,
distributed computation, additional platforms, and unchecked goals in the roadmap
remain future development; they are not prerequisites for this release.
