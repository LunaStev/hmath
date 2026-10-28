# Troubleshooting

## `libhmath.so: cannot open shared object file`

The 1.0.0 Python distribution omitted the native library. Upgrade to 1.0.1
or newer using your application's interpreter:

```sh
pip install --upgrade hmath-python
```

In PyCharm, use the interpreter selected in the project's Python interpreter
settings. Installing into a different terminal environment does not update
the project's virtual environment.

If an old developer override is set, remove it before importing:

```sh
unset HMATH_LIBRARY
python -c "from hmath import add; print(add(2, 3))"
```

Do not use an arbitrary system library to mask an incomplete wheel. Report
failures of the fixed wheel with your Python version, Linux distribution,
CPU architecture, pip output, and complete traceback.

## `No matching distribution found`

Upgrade pip and check that the environment is Linux x86-64 with glibc 2.28
or newer. Current wheels do not cover Alpine/musl, ARM, macOS, or Windows.
See [compatibility](../explanation/releases.md).

## `HMathError`

This means native code loaded and rejected an operation. Inspect `.status`
and the exception message. Common causes are incompatible shapes, non-finite
values, an oversized tensor, or a matrix multiplication exceeding its work
budget. The [reference](../reference/python.md) lists limits and errors.

## `Tensor is closed`

Do not use a tensor after leaving its `with` block or calling `.close()`.
Keep computations inside the owner block, or create an independent result
before closing it.

## `HMath runtime was permanently shut down`

Final runtime shutdown is irreversible. Call `shutdown()` only as the process
owner after all numerical work has finished. Ordinary applications can rely
on process exit and should not call it after each calculation.
