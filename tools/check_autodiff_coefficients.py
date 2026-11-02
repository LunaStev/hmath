# SPDX-License-Identifier: MPL-2.0
"""Original forward-mode instances over every supported concrete coefficient type."""

import argparse
import os
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

from check_tensor_equivalence import SOURCE as TENSOR_SOURCE
from check_tensor_equivalence import close, encode

ROOT = Path(__file__).resolve().parent.parent
SOURCE = TENSOR_SOURCE.split("checked=")[0]
SOURCE = SOURCE.replace(
    "class Enc a",
    "import qualified HMath.Autodiff as A\nimport qualified HMath.Numeric as N\nclass Enc a",
)
for name in ["Int16", "Int32", "Int64", "Word8", "Word16", "Word32", "Word"]:
    SOURCE += "instance Enc " + name + ' where enc x="I"++show x\n'
SOURCE += r"""
instance Enc a=>Enc(A.Dual a) where enc x="AD["++enc(A.primal x)++","++enc(A.tangent x)++"]"
instance Enc a=>Enc(N.Dual a) where enc x="ND["++enc(N.primal x)++","++enc(N.tangent x)++"]"
instance Enc a=>Enc(N.Quaternion a) where enc(N.Quaternion a b c d)="Q["++intercalate ","(map enc[a,b,c,d])++"]"
main=sequence_(map(putStrLn)[CASES])
"""


def cases(ad, numeric):
    owned = []

    def keep(value):
        owned.append(value)
        return value

    selected = []

    def add(name, hs, call, code=None):
        selected.append((name, "enc(" + hs + ")", call, code))

    definitions = [
        ("float64", "Double", "1.0000001", 1.0000001, 0),
        ("float32", "Float", "1.0000001", 1.0000001, 1),
        ("integer", "Integer", "10^100", 10**100, 2),
        ("rational", "Rational", "2%3", Fraction(2, 3), 3),
        ("complex128", "Complex Double", "1.2:+0.3", 1.2 + 0.3j, 4),
        ("complex64", "Complex Float", "1.2:+0.3", 1.2 + 0.3j, 5),
        ("int8", "Int8", "120", 120, 6),
        ("int16", "Int16", "30000", 30000, 7),
        ("int32", "Int32", "2000000000", 2000000000, 8),
        ("int64", "Int64", "8000000000000000000", 8 * 10**18, 9),
        ("uint8", "Word8", "250", 250, 10),
        ("uint16", "Word16", "60000", 60000, 11),
        ("uint32", "Word32", "4000000000", 4000000000, 12),
        ("uint64", "Word64", "16000000000000000000", 16 * 10**18, 13),
        ("intp", "Int", "123", 123, 14),
        ("uintp", "Word", "321", 321, 15),
    ]
    for dtype, hs, point, value, code in definitions:
        add(
            "Num " + dtype,
            r"A.forward(\x->x*x*x+2*x)(" + point + "::" + hs + ")",
            lambda dtype=dtype, value=value: ad.forward(
                lambda x: x * x * x + 2 * x, value, dtype=dtype
            ),
            code,
        )
        add(
            "nested " + dtype,
            r"A.forward(\x->x*x*x)(A.Dual(" + point + "::" + hs + ")1)",
            lambda dtype=dtype, value=value: ad.forward(
                lambda x: x * x * x, keep(ad.Dual(value, 1, dtype=dtype))
            ),
            code,
        )
        if code in (0, 1, 3, 4, 5):
            add(
                "Fractional " + dtype,
                "A.forward recip(" + point + "::" + hs + ")",
                lambda dtype=dtype, value=value: ad.forward(
                    lambda x: 1 / x, value, dtype=dtype
                ),
                code,
            )
        if code in (0, 1, 4, 5):
            add(
                "Floating " + dtype,
                "A.forward(\\x->sin x+exp x)(" + point + "::" + hs + ")",
                lambda dtype=dtype, value=value: ad.forward(
                    lambda x: ad.sin(x) + ad.exp(x), value, dtype=dtype
                ),
                code,
            )
    for dtype, hs, point, value, code in definitions:
        primal = keep(numeric.number(value, dtype))
        tangent = keep(numeric.number(1, dtype))
        leaf = keep(numeric.dual(primal, tangent, boxed=True))
        add(
            "Numeric.Dual Num " + dtype,
            r"A.forward(\x->x*x*x+2*x)(N.Dual(" + point + "::" + hs + ")1)",
            lambda leaf=leaf: ad.forward(lambda x: x * x * x + 2 * x, leaf),
            code,
        )
        if code in (0, 1, 3, 4, 5):
            add(
                "Numeric.Dual Fractional " + dtype,
                "A.forward recip(N.Dual(" + point + "::" + hs + ")1)",
                lambda leaf=leaf: ad.forward(lambda x: 1 / x, leaf),
                code,
            )
        if code in (0, 1, 4, 5):
            add(
                "Numeric.Dual Floating " + dtype,
                "A.forward exp(N.Dual(" + point + "::" + hs + ")1)",
                lambda leaf=leaf: ad.forward(ad.exp, leaf),
                code,
            )
    with numeric.number(1.0000001, "float32") as p, numeric.number(1, "float32") as one:
        first = keep(numeric.dual(p, one, boxed=True))
        second = keep(numeric.dual(first, first, boxed=True))
    add(
        "nested Numeric.Dual",
        r"A.forward(\x->x*x*x)(N.Dual(N.Dual(1.0000001::Float)1)(N.Dual 1.0000001 1))",
        lambda: ad.forward(lambda x: x * x * x, second),
        1,
    )
    for dtype, hs, code in [("float64", "Double", 0), ("float32", "Float", 1)]:
        parts = [keep(numeric.number(v, dtype)) for v in [1.2, 0.3, 0.4, 0.5]]
        leaf = keep(numeric.quaternion(*parts, boxed=True))
        add(
            "Quaternion Num " + dtype,
            r"A.forward(\x->x*x*x+2*x)(N.Quaternion(1.2::" + hs + ")0.3 0.4 0.5)",
            lambda leaf=leaf: ad.forward(lambda x: x * x * x + 2 * x, leaf),
            code,
        )
    return selected, owned


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", required=True, type=Path)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    from _hmath_native import _tensor_core as tensor
    from _hmath_native import autodiff as ad
    from _hmath_native import numeric_types as numeric
    from _hmath_native._numeric_types_runtime import NumericValue

    def enc(value, code):
        if isinstance(value, ad.Dual):
            parts = (value.primal, value.tangent)
            try:
                return "AD[" + ",".join(enc(x, code) for x in parts) + "]"
            finally:
                close(parts)
        if isinstance(value, NumericValue):
            kind, dtype, _ = value.info
            if kind == 1 and dtype == 20:
                parts = (value.primal, value.tangent)
                try:
                    return "ND[" + ",".join(enc(x, code) for x in parts) + "]"
                finally:
                    close(parts)
            if kind == 1 and dtype == 21:
                parts = value.components
                try:
                    return "Q[" + ",".join(enc(x, code) for x in parts) + "]"
                finally:
                    close(parts)
            return encode(value.value, tensor, code)
        if isinstance(value, (tuple, list)):
            return (
                ("T[" if isinstance(value, tuple) else "L[")
                + ",".join(enc(x, code) for x in value)
                + "]"
            )
        return encode(value, tensor, code)

    selected, owned = cases(ad, numeric)
    try:
        with tempfile.TemporaryDirectory(prefix="hmath-ad-coefficients-") as temporary:
            path = Path(temporary)
            source = path / "Main.hs"
            source.write_text(
                SOURCE.replace("CASES", ",\n  ".join(hs for _, hs, _, _ in selected))
            )
            subprocess.run(
                [
                    "ghc",
                    "-XHaskell2010",
                    "-O1",
                    "-i" + str(ROOT / "src"),
                    "-outputdir",
                    temporary,
                    str(source),
                    "-o",
                    str(path / "oracle"),
                ],
                check=True,
                stdout=subprocess.DEVNULL,
            )
            expected = subprocess.check_output(
                [str(path / "oracle")], text=True
            ).splitlines()
        for (name, _, call, code), reference in zip(selected, expected, strict=True):
            value = call()
            try:
                actual = enc(value, code)
            finally:
                close(value)
            if actual != reference:
                raise AssertionError(f"{name}: native {actual}, original {reference}")
        print(
            f"AD coefficient equivalence: {len(selected)} original typed forward sequences match exact values/IEEE bits and nested original Dual/Quaternion components."
        )
    finally:
        close(owned)


if __name__ == "__main__":
    main()
