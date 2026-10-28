# Changelog

## 1.0.1

- Bundle the native HMath library and required runtime dependencies in the Linux x86-64 Python wheel, fixing import failures after a normal pip installation.
- Validate the same release wheel in clean CPython 3.9–3.14 environments without a system HMath library, GHC, or native-library environment overrides.
- Add a searchable documentation site with installation, guides, language references, and generated Haskell API documentation.
- Cache Haskell builds and dependencies; run differential validation once rather than repeating it across the compiler/build-type matrix.

## 1.0.0

- Add checked native tensors, ownership and cancellation contracts, and CPU DLPack exchange.
- Establish C, Python, and Wave as the officially maintained external interfaces.
- Add configurable BLAS/LAPACK providers and pure reference operations.
- Add Haskell shape, algebra, buffer, and convergence interfaces and typed array interchange.
- Add integrated validation, benchmarks, native installation checks, and build metadata.

The first release covers the implemented Haskell numerical modules and the
C, Python, and Wave interfaces on Linux x86-64. Python distributions in 1.0.0
contain only bindings and require a separately installed HMath shared library.
Upgrade to 1.0.1 or newer for a self-contained Linux x86-64 Python wheel.

Package versions follow SemVer: compatible fixes increment the patch, compatible
features increment the minor, and breaking public API changes increment the major.
C ABI epoch 1 is reported independently and identifies the calling and ownership
conventions. Existing legacy C symbols remain available. GPU execution,
distributed computation, additional platforms, and unchecked goals in the roadmap
remain future development; they are not prerequisites for this release.
