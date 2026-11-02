# SPDX-License-Identifier: MPL-2.0
"""Independent original-Haskell oracle for Signal/Fourier/Interpolation."""

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from check_polynomial_equivalence import HASKELL, bits, close
from generate_graph_bindings import snake, split_top
from generate_numerical_bindings import normalize, spec
from generate_spectral_bindings import TYPES

ROOT = Path(__file__).resolve().parent.parent
BASE = HASKELL.split("pR=")[0].replace(
    "class E a",
    """import Prelude hiding (filter)
import qualified HMath.Signal as S
import qualified HMath.Fourier as F
import qualified HMath.Interpolation as I
import qualified HMath.Calculus as C
import Data.Char(ord)
import Foreign.Marshal.Array(newArray,peekArray)
import Foreign.Marshal.Alloc(free)
class E a""",
)
FIXTURES = r"""
right(Right x)=x
right(Left e)=error(show e)
xs=[1,2,3,4,5,6,7,8] :: [Double]
cx=[fromIntegral i :+ (negate(fromIntegral i)/2) | i<-[1..8]] :: [Complex Double]
filter=right(S.fir [0.5,0.5])
family=S.Butterworth
band=S.Lowpass 0.2
window=S.Hann
peak=S.Peak 1 2 0.3 0.4
wavelet=S.Haar
tree=right(S.dwt S.Haar 1 xs)
mother=S.MexicanHat
packet=right(S.waveletPackets S.Haar 2 xs)
extrapolation=I.Clamp
method=I.Linear
boundary=I.Natural
piecewise=right(I.piecewisePolynomial [0,1,2] [[1,2],[3,4]])
spline=right(I.bSpline 1 [0,0,1,1] [[0,0],[1,1]] [1,1])
kernel=I.Gaussian 1
rbf=right(I.fitRBF kernel 0.1 [[0],[1]] [0,1])
approximation=I.Approximation [1,2] 0 1
direction=F.Forward
algorithm=F.Automatic
plan=right(F.planFFT direction algorithm 8)
transform=F.TypeII
stft=right(F.stft [1,1,1,1] 2 xs)
gaussian=right(S.gaussianState [0] [[1]])
tolerance=C.Tolerance 1e-5 1e-5 2000
square x=x*x
identity xs=xs
model x parameters=head parameters*x
main=do
    mapM_ putStrLn [EXPRESSIONS]
    pointer<-newArray cx
    outcome<-F.fftInPlace plan pointer 8
    transformed<-peekArray 8 pointer
    putStrLn(ok outcome++":"++enc transformed)
    free pointer
"""


def encode(value, modules):
    from _hmath_native._value import Value

    if value is None:
        return "N"
    if isinstance(value, bool):
        return "B1" if value else "B0"
    if isinstance(value, int):
        return "I" + str(value)
    if isinstance(value, float):
        return "F64:" + str(bits(value, 64))
    if isinstance(value, complex):
        return "C64:" + str(bits(value.real, 64)) + ":" + str(bits(value.imag, 64))
    if isinstance(value, (list, tuple)):
        return (
            ("T[" if isinstance(value, tuple) else "L[")
            + ",".join(encode(x, modules) for x in value)
            + "]"
        )
    if isinstance(value, Value):
        if value.info[0] == 200:
            c = modules["calculus"]
            return encode(
                (
                    c.estimate_value(value),
                    c.estimate_error(value),
                    c.evaluations(value),
                ),
                modules,
            )
        return "O" + encode(list(map(ord, modules["signal"].describe(value))), modules)
    raise TypeError(type(value))


def cases(modules):
    s, f, i, c = (
        modules[n] for n in ("signal", "fourier", "interpolation", "calculus")
    )
    owners = []

    def keep(value):
        owners.append(value)
        return value

    xs = [float(k) for k in range(1, 9)]
    cx = [complex(k, -k / 2) for k in range(1, 9)]
    records = {
        "Filter": (keep(s.fir([0.5, 0.5])), "filter"),
        "FilterFamily": (keep(s.butterworth()), "family"),
        "FilterBand": (keep(s.lowpass(0.2)), "band"),
        "Window": (keep(s.hann()), "window"),
        "Peak": (keep(s.peak(1, 2, 0.3, 0.4)), "peak"),
        "Wavelet": (keep(s.haar()), "wavelet"),
        "WaveletTree": (keep(s.dwt(s.haar(), 1, xs)), "tree"),
        "MotherWavelet": (keep(s.mexican_hat()), "mother"),
        "WaveletPacket": (keep(s.wavelet_packets(s.haar(), 2, xs)), "packet"),
        "Extrapolation": (keep(i.clamp()), "extrapolation"),
        "InterpolationMethod": (keep(i.linear()), "method"),
        "SplineBoundary": (keep(i.natural()), "boundary"),
        "PiecewisePolynomial": (
            keep(i.piecewise_polynomial([0, 1, 2], [[1, 2], [3, 4]])),
            "piecewise",
        ),
        "BSpline": (
            keep(i.b_spline(1, [0, 0, 1, 1], [[0, 0], [1, 1]], [1, 1])),
            "spline",
        ),
        "RadialKernel": (keep(i.gaussian(1)), "kernel"),
        "RBF": (keep(i.fit_rbf(i.gaussian(1), 0.1, [[0], [1]], [0, 1])), "rbf"),
        "Approximation": (keep(i.approximation([1, 2], 0, 1)), "approximation"),
        "Direction": (keep(f.forward()), "direction"),
        "FFTAlgorithm": (keep(f.automatic()), "algorithm"),
        "FFTPlan": (keep(f.plan_fft(f.forward(), f.automatic(), 8)), "plan"),
        "TransformType": (keep(f.type_ii()), "transform"),
        "STFT": (keep(f.stft([1, 1, 1, 1], 2, xs)), "stft"),
        "GaussianState": (keep(s.gaussian_state([0], [[1]])), "gaussian"),
        "Tolerance": (keep(c.tolerance(1e-5, 1e-5, 2000)), "tolerance"),
    }

    def arg(type_):
        kind = type_[0]
        if kind in records:
            value, expression = records[kind]
            return value, "(" + expression + ")"
        if kind == "function":
            if type_[1:] == [["Double"], ["Double"]]:
                return lambda x: x * x, "square"
            if type_[1:] == [["list", ["Double"]], ["list", ["Double"]]]:
                return lambda x: x, "identity"
            if type_[1:] == [["Double"], ["list", ["Double"]], ["Double"]]:
                return lambda x, p: p[0] * x, "model"
            raise ValueError(type_)
        if kind == "Double":
            return 0.5, "0.5"
        if kind == "Int":
            return 4, "4"
        if kind == "ComplexDouble":
            return 1 + 0j, "(1:+0)"
        if kind == "Bool":
            return False, "False"
        if kind == "maybe":
            return None, "Nothing"
        if kind == "tuple":
            items = [arg(t) for t in type_[1:]]
            return tuple(v for v, _ in items), "(" + ",".join(e for _, e in items) + ")"
        if kind == "list":
            if type_[1] == ["Double"]:
                return xs, "xs"
            if type_[1] == ["ComplexDouble"]:
                return cx, "cx"
            if type_[1] == ["Value"]:
                return [0.0, 1.0, 2.0, 3.0], "([0,1,2,3]::[Double])"
            if type_[1] == ["Int"]:
                return [8], "[8]"
            if type_[1] == ["list", ["Double"]]:
                return [[0], [1]], "[[0],[1]]"
            item, expression = arg(type_[1])
            return [item], "[" + expression + "]"
        raise ValueError(type_)

    overrides = {}

    def put(module, name, arguments, expressions):
        overrides[(module, name)] = (arguments, expressions)

    put("signal", "dwt", [records["Wavelet"][0], 1, xs], ["wavelet", "1", "xs"])
    put(
        "signal",
        "waveletPackets",
        [records["Wavelet"][0], 2, xs],
        ["wavelet", "2", "xs"],
    )
    put(
        "signal",
        "waveletDenoise",
        [records["Wavelet"][0], 1, None, xs],
        ["wavelet", "1", "Nothing", "xs"],
    )
    put(
        "signal",
        "designIIR",
        [records["FilterFamily"][0], records["FilterBand"][0], 2, 1],
        ["family", "band", "2", "1"],
    )
    put(
        "signal",
        "kalman",
        [[[1]], [[1]], [[0.1]], [[0.2]], [1], records["GaussianState"][0]],
        ["[[1]]", "[[1]]", "[[0.1]]", "[[0.2]]", "[1]", "gaussian"],
    )
    put(
        "signal",
        "extendedKalman",
        [lambda x: x, lambda x: x, [[0.1]], [[0.2]], [1], records["GaussianState"][0]],
        ["identity", "identity", "[[0.1]]", "[[0.2]]", "[1]", "gaussian"],
    )
    put(
        "signal",
        "unscentedKalman",
        [
            0.1,
            2,
            0,
            lambda x: x,
            lambda x: x,
            [[0.1]],
            [[0.2]],
            [1],
            records["GaussianState"][0],
        ],
        [
            "0.1",
            "2",
            "0",
            "identity",
            "identity",
            "[[0.1]]",
            "[[0.2]]",
            "[1]",
            "gaussian",
        ],
    )
    points = [(0, 0), (1, 1), (2, 4), (3, 9), (4, 16)]
    hs_points = "[(0,0),(1,1),(2,4),(3,9),(4,16)]"
    for name in ("pchip", "akima", "catmullRom"):
        put("interpolation", name, [points], [hs_points])
    put(
        "interpolation",
        "interpolate",
        [records["InterpolationMethod"][0], records["Extrapolation"][0], points, 0.5],
        ["method", "extrapolation", hs_points, "0.5"],
    )
    put(
        "interpolation",
        "cubicSpline",
        [records["SplineBoundary"][0], points],
        ["boundary", hs_points],
    )
    put("interpolation", "smoothingSpline", [0.1, points], ["0.1", hs_points])
    put("interpolation", "cardinalSpline", [0.2, points], ["0.2", hs_points])
    put(
        "interpolation",
        "kochanekBartels",
        [0.1, 0.2, 0.3, points],
        ["0.1", "0.2", "0.3", hs_points],
    )
    put(
        "interpolation",
        "bSpline",
        [1, [0, 0, 1, 1], [[0, 0], [1, 1]], [1, 1]],
        ["1", "[0,0,1,1]", "[[0,0],[1,1]]", "[1,1]"],
    )
    put(
        "interpolation",
        "fitRBF",
        [records["RadialKernel"][0], 0.1, [[0], [1]], [0, 1]],
        ["kernel", "0.1", "[[0],[1]]", "[0,1]"],
    )
    put("interpolation", "evaluateRBF", [records["RBF"][0], [0.5]], ["rbf", "[0.5]"])
    put("interpolation", "polynomialFit", [2, points], ["2", hs_points])
    put(
        "interpolation",
        "chebyshevApproximate",
        [4, lambda x: x * x, 0, 1],
        ["4", "square", "0", "1"],
    )
    put(
        "interpolation",
        "remez",
        [1, 64, 1e-4, 20, lambda x: x * x, 0, 1],
        ["1", "64", "1e-4", "20", "square", "0", "1"],
    )
    put(
        "interpolation",
        "nonlinearFit",
        [20, 1e-6, lambda x, p: p[0] * x, [(1, 2), (2, 4), (3, 6)], [1]],
        ["20", "1e-6", "model", "[(1,2),(2,4),(3,6)]", "[1]"],
    )
    put("fourier", "stft", [[1, 1, 1, 1], 2, xs], ["[1,1,1,1]", "2", "xs"])
    entries = json.loads(
        (ROOT / "bindings/schema/spectral-functions.json").read_text()
    )["functions"]
    fixtures = []
    for entry in entries:
        if entry["name"] == "fftInPlace":
            continue
        module = entry["module"].removeprefix("HMath.").lower()
        normalized = split_top(normalize(entry["signature"], module), "->")
        prepared = [arg(spec(text, TYPES)) for text in normalized[:-1]]
        arguments = [v for v, _ in prepared]
        expressions = [e for _, e in prepared]
        if (module, entry["name"]) in overrides:
            arguments, expressions = overrides[(module, entry["name"])]
        q = {"signal": "S", "fourier": "F", "interpolation": "I"}[module]
        call = q + "." + entry["name"] + " " + " ".join(expressions)
        expression = (
            ("ok(" if normalized[-1].startswith("Either MathError") else "enc(")
            + call
            + ")"
        )
        fixtures.append((module, snake(entry["name"]), arguments, expression))
    return fixtures, owners, records["FFTPlan"][0], cx


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    import numpy as np

    modules = {
        n: getattr(hmath, n) for n in ("signal", "fourier", "interpolation", "calculus")
    }
    fixtures, owners, plan, cx = cases(modules)
    try:
        instances = "\n".join(
            "instance E(" + typ + ') where enc x="O"++enc(map ord(show x))'
            for _, typ, _, _ in TYPES.values()
        )
        instances += '\ninstance E S.GaussianState where enc x="O"++enc(map ord(show x))\ninstance E a=>E(C.Estimate a) where enc x=enc(C.estimateValue x,C.estimateError x,C.evaluations x)\ninstance E () where enc ()="T[]"\n'
        source = (
            BASE
            + instances
            + FIXTURES.replace(
                "EXPRESSIONS", ",\n        ".join(case[3] for case in fixtures)
            )
        )
        with tempfile.TemporaryDirectory(prefix="hmath-spectral-oracle-") as directory:
            path = Path(directory) / "Main.hs"
            path.write_text(source)
            shim = Path(directory) / "libhmath_oracle_backend.so"
            subprocess.run(
                [
                    "cc",
                    "-shared",
                    "-fPIC",
                    "-std=c11",
                    "-Iinclude",
                    "cbits/backend.c",
                    "-ldl",
                    "-lm",
                    "-o",
                    str(shim),
                ],
                cwd=ROOT,
                check=True,
                capture_output=True,
            )
            result = subprocess.run(
                [
                    "runghc",
                    "-isrc",
                    "-L" + directory,
                    "-lhmath_oracle_backend",
                    str(path),
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )
            if result.returncode:
                Path("/tmp/hmath-spectral-oracle-failed.hs").write_text(source)
                raise RuntimeError(result.stderr[-12000:])
            expected = result.stdout.splitlines()
        actual = []
        for module, name, arguments, _ in fixtures:
            try:
                output = getattr(modules[module], name)(*arguments)
            except hmath.HMathError as error:
                actual.append("E" + str(error.math_error or error))
            else:
                try:
                    actual.append(encode(output, modules))
                finally:
                    close(output)
        buffer = np.array(cx, dtype=np.complex128)
        modules["fourier"].fft_in_place(plan, buffer)
        actual.append("T[]:" + encode(buffer.tolist(), modules))
        failures = [
            (i, fixtures[i][:2] if i < len(fixtures) else "fftInPlace", a, b)
            for i, (a, b) in enumerate(zip(expected, actual))
            if a != b
        ]
        if failures or len(expected) != len(actual):
            raise AssertionError(f"Spectral mismatches: {failures[:8]}")
        print(
            f"Spectral direct Haskell equivalence: {len(actual)} cases, all153 named adapters"
        )
    finally:
        for owner in owners:
            close(owner)


if __name__ == "__main__":
    main()
