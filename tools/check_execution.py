# SPDX-License-Identifier: MPL-2.0
"""Validate explicit buffer execution, dtype and BLAS ABI with protocol spies."""

import argparse
import ctypes as C
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", type=Path, required=True)
    parser.add_argument("--compiler", default="cc")
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    import numpy as np
    from _hmath_native import execution as ex

    def fails(status, call, *arguments, **keywords):
        try:
            call(*arguments, **keywords)
        except hmath.HMathError as error:
            assert error.status == status, (status, error.status, str(error))
            return str(error)
        raise AssertionError("operation unexpectedly succeeded")

    with tempfile.TemporaryDirectory(prefix="hmath-execution-") as directory:
        spies = {}
        for name, flags in [
            ("lp64", []),
            ("ilp64", ["-DILP64"]),
            ("no-sgemm", ["-DNO_SGEMM"]),
        ]:
            path = Path(directory) / (name + ".so")
            subprocess.run(
                [
                    args.compiler,
                    "-std=c11",
                    "-O2",
                    "-ffp-contract=off",
                    "-shared",
                    "-fPIC",
                    *flags,
                    str(ROOT / "test/native/execution_blas_spy.c"),
                    "-o",
                    str(path),
                ],
                check=True,
            )
            spy = C.CDLL(str(path))
            spy.hm_spy_pointer.argtypes = [C.c_uint]
            spy.hm_spy_pointer.restype = C.c_size_t
            spy.hm_spy_ldc.restype = C.c_int64
            spy.hm_spy_alpha32.restype = C.c_float
            spies[name] = (path, spy)
        for dtype in [np.float32, np.float64]:
            a = np.array([[1, 2], [3, 4]], dtype=dtype)
            b = np.array([[2, 0], [1, 2]], dtype=dtype)
            for provider, path in [("reference", None), ("openblas", spies["lp64"][0])]:
                with ex.Execution(provider, library_path=path) as engine:
                    out = np.ones((2, 2), dtype=dtype)
                    assert engine.gemm(a, b, out, alpha=2, beta=3) is out
                    np.testing.assert_array_equal(
                        out, np.array([[11, 11], [23, 19]], dtype=dtype)
                    )
                    assert out.dtype == dtype
                    # Non-consecutive rows are accepted, with untouched padding.
                    ap = np.full((2, 3), np.nan, dtype=dtype)
                    ap[:, :2] = a
                    bp = np.full((2, 3), np.nan, dtype=dtype)
                    bp[:, :2] = b
                    cp = np.full((2, 3), np.nan, dtype=dtype)
                    cp[:, :2] = 0
                    engine.gemm(ap[:, :2], bp[:, :2], cp[:, :2])
                    np.testing.assert_array_equal(cp[:, :2], a @ b)
                    assert np.isnan(cp[:, 2]).all()
                    if path:
                        spy = spies["lp64"][1]
                        assert [spy.hm_spy_pointer(i) for i in range(3)] == [
                            ap.ctypes.data,
                            bp.ctypes.data,
                            cp.ctypes.data,
                        ]
                        assert spy.hm_spy_ldc() == 3
                    before = a.copy()
                    fails(1, engine.gemm, a, b, a)
                    np.testing.assert_array_equal(a, before)
                    out.fill(0)
                    out[0, 0] = np.nan
                    assert (
                        fails(11, engine.gemm, a, b, out, beta=0)
                        == "NonFiniteVectorEntry 10"
                    )
                    with np.errstate(over="ignore", invalid="ignore"):
                        huge = np.array([[np.finfo(dtype).max]], dtype=dtype)
                        twice = np.array([[2]], dtype=dtype)
                        target = np.zeros((1, 1), dtype=dtype)
                        assert (
                            fails(11, engine.gemm, huge, twice, target)
                            == "NonFiniteVectorEntry 0"
                        )
                        assert np.isinf(target[0, 0]) if path else target[0, 0] == 0
            with ex.Execution(max_elements=3) as limited:
                out = np.zeros((2, 2), dtype=dtype)
                fails(3, limited.gemm, a, b, out)
                assert not out.any()
            with ex.Execution(max_multiply_adds=7) as limited:
                fails(3, limited.gemm, a, b, out)
        path, spy = spies["lp64"]
        with ex.Execution("openblas", library_path=path) as engine:
            a = np.ones((1025, 1), dtype=np.float32)
            b = np.ones((1, 1025), dtype=np.float32)
            out = np.zeros((1025, 1025), dtype=np.float32)
            engine.gemm(a, b, out)
            assert out.size > 1048576 and np.all(out == 1)
            before32, before64 = spy.hm_spy_calls32(), spy.hm_spy_calls64()
            a = np.ones((257, 257), dtype=np.float32)
            out = np.zeros_like(a)
            engine.gemm(a, a, out)
            assert 257**3 > 16777216 and np.all(out == 257)
            assert (
                spy.hm_spy_calls32() == before32 + 1
                and spy.hm_spy_calls64() == before64
            )
            assert [spy.hm_spy_pointer(i) for i in range(3)] == [
                a.ctypes.data,
                a.ctypes.data,
                out.ctypes.data,
            ]
            # Explicit float32 scalars round at the float32 boundary.
            one = np.ones((1, 1), dtype=np.float32)
            zero = np.zeros_like(one)
            engine.gemm(one, one, zero, alpha=16777217)
            assert spy.hm_spy_alpha32() == 16777216 and zero[0, 0] == 16777216
        # SGEMM is optional at provider-open time; a missing symbol does not
        # prevent double-precision use and never causes implicit conversion.
        with ex.Execution("openblas", library_path=spies["no-sgemm"][0]) as engine:
            a = np.ones((1, 1), dtype=np.float64)
            out = np.zeros_like(a)
            engine.gemm(a, a, out)
            assert out[0, 0] == 1
            a = a.astype(np.float32)
            out = np.zeros_like(a)
            fails(10, engine.gemm, a, a, out)
            assert out[0, 0] == 0
        # Validate leading dimensions at the selected BLAS integer width.
        for name, bits in [("lp64", 32), ("ilp64", 64)]:
            with ex.Execution(
                "openblas", integer_bits=bits, library_path=spies[name][0]
            ) as engine:
                a = C.c_float(2)
                b = C.c_float(3)
                c = C.c_float(0)
                view_a = ex._View(C.addressof(a), 1, 1, 1, 1)
                view_b = ex._View(C.addressof(b), 1, 1, 1, 1)
                view_c = ex._View(C.addressof(c), 1, 1, 1, 2**31 + 1)
                call = ex._api(
                    "hmath_execution_gemm_f32",
                    C.c_int,
                    C.c_void_p,
                    C.c_void_p,
                    C.c_float,
                    C.POINTER(ex._View),
                    C.POINTER(ex._View),
                    C.c_float,
                    C.POINTER(ex._View),
                )
                status = call(
                    engine._ptr,
                    None,
                    1,
                    C.byref(view_a),
                    C.byref(view_b),
                    0,
                    C.byref(view_c),
                )
                assert status == (1 if bits == 32 else 0), status
                assert c.value == (0 if bits == 32 else 6)
                if bits == 64:
                    assert spies[name][1].hm_spy_ldc() == 2**31 + 1
        # Huge zero-element shapes are valid and must not enumerate empty rows.
        with ex.Execution() as engine:
            limit = (1 << (C.sizeof(C.c_ssize_t) * 8 - 1)) - 1
            a = ex._View(None, 0, 0, limit, limit)
            b = ex._View(None, 0, limit, 0, 0)
            out = ex._View(None, 0, 0, 0, 0)
            call = ex._api(
                "hmath_execution_gemm_f32",
                C.c_int,
                C.c_void_p,
                C.c_void_p,
                C.c_float,
                C.POINTER(ex._View),
                C.POINTER(ex._View),
                C.c_float,
                C.POINTER(ex._View),
            )
            hmath._check(
                call(engine._ptr, None, 1, C.byref(a), C.byref(b), 0, C.byref(out))
            )
        fails(
            10,
            ex.Execution,
            "openblas",
            library_path=Path(directory) / "missing.so",
        )
    hmath.shutdown()
    print(
        "Execution reference, SGEMM/DGEMM no-copy routing, FP32 scalar/storage, padded rows, LP64/ILP64, >1M elements, >16M work, zero shapes, limits, aliases and failure-output contracts passed."
    )


if __name__ == "__main__":
    main()
