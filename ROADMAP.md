# HMath development roadmap

[Roadmap issue](https://github.com/wavefnd/hmath/issues/1) · [Planning milestone](https://github.com/wavefnd/hmath/milestone/1)

## Status and scope

HMath is preparing its first 1.0.0 release. This roadmap preserves the complete maintainer-provided development checklist: **47 functional areas and 944 individual requirements**. Each area links to an English tracking issue containing its checklist, historical baseline, and completion criteria.

The agreed 1.0.0 scope is the implemented Haskell numerical modules and the C ABI 1, Python, and Wave interfaces on **Linux x86-64**. It includes the reference CPU implementations, tested optional OpenBLAS/LAPACKE integration, numerical interchange, and local build/install validation. GPU execution, explicit SIMD acceleration, distributed execution, additional platforms, and other unfinished checklist goals remain later work. The original checklist is a long-term backlog, not a promise that every item ships in 1.0.0.

Official external language support is limited to **C, Python, and Wave**. Haskell remains the implementation and native API. The counts below preserve the original checklist; the earlier requests for other maintained bindings are superseded by this scope decision in [#45](https://github.com/wavefnd/hmath/issues/45).

## Suggested work order

1. Correct the confirmed matrix, RTS lifecycle, and FFI test defects below.
2. Agree numerical types and precision, shapes and layouts, error handling, ownership, threading, and API/ABI contracts.
3. Harden scalar, vector, matrix, and statistics foundations together with meaningful Haskell/C/Python regression tests.
4. Add selected numerical algorithms, arrays, interoperability, and language bindings in reviewable increments.
5. Add optional acceleration and advanced domains after their reference behavior and tests exist.
6. Validate the agreed first-release scope and publish 1.0.0 after review. Continue with compatible fixes in 1.0.x, compatible features in 1.x, and breaking public API changes in 2.0.0 or later.

## Prototype correctness work

- [#2](https://github.com/wavefnd/hmath/issues/2) — Preserve matrix shape and values across zero-dimension operations
- [#3](https://github.com/wavefnd/hmath/issues/3) — Reject unsupported GHC RTS reinitialization without terminating the host
- [#4](https://github.com/wavefnd/hmath/issues/4) — Make C and Python FFI tests fail on incorrect numerical results

These are focused starting tasks. They do not replace the broader functional-area requirements.

## Complete feature backlog

| Area | Development goal | Requirements | Priority | Issue |
| --- | --- | ---: | --- | --- |
| 1 | Implement core arithmetic, elementary functions, and scalar numerical utilities | 40 | high | [#5](https://github.com/wavefnd/hmath/issues/5) |
| 2 | Provide mathematical constants, unit conversions, and dimensional safety | 16 | medium | [#6](https://github.com/wavefnd/hmath/issues/6) |
| 3 | Define numerical types, precision controls, and floating-point semantics | 18 | high | [#7](https://github.com/wavefnd/hmath/issues/7) |
| 4 | Implement trigonometric, hyperbolic, and angular operations | 12 | medium | [#8](https://github.com/wavefnd/hmath/issues/8) |
| 5 | Implement number-theoretic algorithms and arithmetic functions | 21 | medium | [#9](https://github.com/wavefnd/hmath/issues/9) |
| 6 | Implement polynomial operations and algebraic abstractions | 16 | medium | [#10](https://github.com/wavefnd/hmath/issues/10) |
| 7 | Extend vector and matrix operations with explicit shape contracts | 22 | high | [#11](https://github.com/wavefnd/hmath/issues/11) |
| 8 | Implement matrix factorizations and linear-system solvers | 20 | medium | [#12](https://github.com/wavefnd/hmath/issues/12) |
| 9 | Implement sparse matrix representations and numerical operations | 12 | medium | [#13](https://github.com/wavefnd/hmath/issues/13) |
| 10 | Implement tensors and multidimensional array semantics | 25 | high | [#14](https://github.com/wavefnd/hmath/issues/14) |
| 11 | Implement numerical differentiation and integration | 19 | medium | [#15](https://github.com/wavefnd/hmath/issues/15) |
| 12 | Implement ODE solvers and dynamical-system analysis | 15 | medium | [#16](https://github.com/wavefnd/hmath/issues/16) |
| 13 | Implement PDE grids, discretization operators, and solvers | 13 | low | [#17](https://github.com/wavefnd/hmath/issues/17) |
| 14 | Implement automatic differentiation and differentiable operations | 18 | medium | [#18](https://github.com/wavefnd/hmath/issues/18) |
| 15 | Implement local, constrained, and global optimization algorithms | 24 | medium | [#19](https://github.com/wavefnd/hmath/issues/19) |
| 16 | Implement scalar and multivariate root-finding algorithms | 11 | medium | [#20](https://github.com/wavefnd/hmath/issues/20) |
| 17 | Expand descriptive statistics and statistical inference | 27 | medium | [#21](https://github.com/wavefnd/hmath/issues/21) |
| 18 | Add probability distributions and probabilistic inference | 22 | medium | [#22](https://github.com/wavefnd/hmath/issues/22) |
| 19 | Implement reproducible random number generation and sampling | 19 | medium | [#23](https://github.com/wavefnd/hmath/issues/23) |
| 20 | Build deep learning numerical primitives | 28 | low | [#24](https://github.com/wavefnd/hmath/issues/24) |
| 21 | Implement machine learning estimators and preprocessing | 23 | low | [#25](https://github.com/wavefnd/hmath/issues/25) |
| 22 | Add Fourier transforms and spectral analysis | 18 | medium | [#26](https://github.com/wavefnd/hmath/issues/26) |
| 23 | Implement digital signal processing and wavelets | 22 | medium | [#27](https://github.com/wavefnd/hmath/issues/27) |
| 24 | Develop interpolation, approximation, and curve APIs | 18 | medium | [#28](https://github.com/wavefnd/hmath/issues/28) |
| 25 | Implement special functions with numerical error contracts | 25 | medium | [#29](https://github.com/wavefnd/hmath/issues/29) |
| 26 | Add complex arithmetic, quaternions, and rotation groups | 15 | medium | [#30](https://github.com/wavefnd/hmath/issues/30) |
| 27 | Create computational geometry and spatial query APIs | 27 | low | [#31](https://github.com/wavefnd/hmath/issues/31) |
| 28 | Implement combinatorics and discrete mathematics | 22 | medium | [#32](https://github.com/wavefnd/hmath/issues/32) |
| 29 | Implement graph representations and algorithms | 26 | low | [#33](https://github.com/wavefnd/hmath/issues/33) |
| 30 | Build symbolic expression manipulation and evaluation | 25 | low | [#34](https://github.com/wavefnd/hmath/issues/34) |
| 31 | Implement time series analysis and forecasting | 19 | low | [#35](https://github.com/wavefnd/hmath/issues/35) |
| 32 | Implement numerical image processing operations | 20 | low | [#36](https://github.com/wavefnd/hmath/issues/36) |
| 33 | Implement numerical algorithms and data structures | 21 | medium | [#37](https://github.com/wavefnd/hmath/issues/37) |
| 34 | Implement a bounded numerical expression evaluator | 14 | medium | [#38](https://github.com/wavefnd/hmath/issues/38) |
| 35 | Add CPU backends and hardware-aware numerical optimization | 18 | low | [#39](https://github.com/wavefnd/hmath/issues/39) |
| 36 | Integrate configurable BLAS and LAPACK backends | 15 | low | [#40](https://github.com/wavefnd/hmath/issues/40) |
| 37 | Implement GPU numerical backends and device execution | 19 | low | [#41](https://github.com/wavefnd/hmath/issues/41) |
| 38 | Implement parallel, streaming, and distributed numerical execution | 15 | low | [#42](https://github.com/wavefnd/hmath/issues/42) |
| 39 | Define and harden the Haskell API and numerical type contracts | 19 | high | [#43](https://github.com/wavefnd/hmath/issues/43) |
| 40 | Specify and harden the native C ABI and FFI lifecycle | 21 | high | [#44](https://github.com/wavefnd/hmath/issues/44) |
| 41 | Provide language bindings with consistent errors and resource cleanup | 19 | medium | [#45](https://github.com/wavefnd/hmath/issues/45) |
| 42 | Add versioned numerical serialization and array interchange | 16 | medium | [#46](https://github.com/wavefnd/hmath/issues/46) |
| 43 | Harden builds, packaging, installation, and release artifacts | 28 | high | [#47](https://github.com/wavefnd/hmath/issues/47) |
| 44 | Establish numerical, FFI, and cross-platform validation | 25 | high | [#48](https://github.com/wavefnd/hmath/issues/48) |
| 45 | Build reproducible numerical and interoperability benchmarks | 16 | medium | [#49](https://github.com/wavefnd/hmath/issues/49) |
| 46 | Document numerical contracts, native integration, and practical examples | 19 | medium | [#50](https://github.com/wavefnd/hmath/issues/50) |
| 47 | Define and satisfy the HMath 1.0.0 release gates | 21 | high | [#51](https://github.com/wavefnd/hmath/issues/51) |

## Working through the backlog

Choose a bounded implementation task from a tracking issue and link any smaller issue or pull request back to it. Define input domains, numerical accuracy, errors, shapes, ownership, and relevant tests before treating that task as complete. Reuse shared primitives across overlapping areas such as FFTs, spatial indexes, Kalman filters, and combinatorics.

Close a feature tracking issue only when its agreed scope and completion criteria are satisfied. Record any explicitly deferred goal rather than silently dropping it. API/ABI freeze and release publication remain future work under [the release-gate issue](https://github.com/wavefnd/hmath/issues/51).

## Reference documentation

- [NumPy routines](https://numpy.org/doc/stable/reference/routines.html)
- [SciPy API reference](https://docs.scipy.org/doc/scipy/reference/index.html)
- [GNU Scientific Library manual](https://www.gnu.org/software/gsl/doc/html/)
- [PyTorch documentation](https://docs.pytorch.org/docs/stable/index.html)

These are the source checklist's reference links, not additional runtime dependencies.

