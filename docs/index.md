# HMath documentation

HMath is a mathematics and numerical computing library written in Haskell,
with officially maintained C, Python, and Wave interfaces.

Start with [installation](getting-started/installation.md), then follow
[your first calculation](getting-started/first-calculation.md). Use the
[Python reference](reference/python.md) to look up individual operations.

[Choose an operation](getting-started/choose-an-operation.md) to find the
right interface and function for your calculation.

## Choose an interface

| Interface | Scope | Entry point |
| --- | --- | --- |
| Python | Scalar addition; binary64 tensors, matrices, reductions, NumPy views | [Python API](reference/python.md) |
| C | Stable checked ABI, tensors, contexts, callbacks, CPU DLPack | [C ABI](reference/c.md) |
| Wave | Checked scalar and tensor operations through the C ABI | [Wave integration](guides/wave.md) |
| Haskell | Full mathematics and scientific computing modules | [Haskell modules](reference/haskell.md) |

The full Haskell API is larger than the Python and Wave APIs. A function
being available in Haskell does not imply that a Python wrapper exists.

## Find the right kind of documentation

- **Getting started** teaches an end-to-end calculation.
- **How-to guides** solve specific integration tasks.
- **Reference** describes signatures, results, constraints, and errors.
- **Explanation** describes architecture, ownership, and compatibility.

This documentation accompanies HMath @HMATH_VERSION@. Linux x86-64 is the supported
binary distribution target. See [release compatibility](explanation/releases.md)
for Python versions, ABI compatibility, and the 1.0.0 installation defect.
