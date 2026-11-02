# SPDX-License-Identifier: MPL-2.0
"""Compare typed Numeric/Constants bindings with the original Haskell modules.

The independent oracle imports only HMath.Numeric and HMath.Constants. Floating
values compare by IEEE bits; exact values, precision, flags and metadata compare
without Double or text-evaluation conversions.
"""

import argparse
import gc
import math
import os
import struct
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def bits(value, width=64):
    if math.isnan(value):
        return "nan"
    return str(
        struct.unpack(
            "!Q" if width == 64 else "!I",
            struct.pack("!d" if width == 64 else "!f", value),
        )[0]
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", type=Path, required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import numeric_types as n
    from _hmath_native._value import Value

    def encode(kind, value):
        if kind.startswith("r:"):
            child = value.rounded_value
            try:
                return (
                    encode(kind[2:], child)
                    + "!"
                    + ",".join(str(int(x)) for x in value.numerical_exceptions)
                )
            finally:
                child.close()
        if (
            isinstance(value, n.NumericValue)
            and value.info[0] == 1
            and value.info[1] < 20
        ):
            value = value.value
        if kind == "d":
            return bits(value)
        if kind == "f":
            return bits(value, 32)
        if kind in ("i", "enum"):
            return str(int(value))
        if kind == "bool":
            return str(value)
        if kind == "q":
            return str(value.numerator) + "/" + str(value.denominator)
        if kind == "text":
            return ",".join(str(ord(c)) for c in value)
        if kind == "half":
            return str(n.float16_bits(value))
        if kind == "bhalf":
            return str(n.bfloat16_bits(value))
        if kind == "big":
            return (
                str(n.big_precision(value)) + ":" + encode("q", n.big_rational(value))
            )
        if kind == "fixed":
            return str(n.fixed_scale(value)) + ":" + str(n.fixed_coefficient(value))
        if kind == "decimal":
            return encode("q", n.decimal_rational(value))
        if kind == "interval":
            return ",".join(bits(x) for x in n.interval_bounds(value))
        if kind.startswith("dual:"):
            a, b = value.primal, value.tangent
            try:
                return encode(kind[5:], a) + ";" + encode(kind[5:], b)
            finally:
                a.close()
                b.close()
        if kind.startswith("quat:"):
            children = value.components
            try:
                return ";".join(encode(kind[5:], c) for c in children)
            finally:
                for child in children:
                    child.close()
        if kind.startswith("dq:"):
            children = value.components
            try:
                return "/".join(encode("quat:" + kind[3:], c) for c in children)
            finally:
                for child in children:
                    child.close()
        if kind.startswith("triple:"):
            return ",".join(encode(kind[7:], x) for x in value)
        if kind.startswith("frexp:"):
            return encode(kind[6:], value[0]) + ":" + str(value[1])
        if kind == "constant":
            return "|".join(
                encode(k, f(value))
                for k, f in [
                    ("text", n.constant_name),
                    ("q", n.constant_value),
                    ("q", n.standard_uncertainty),
                    ("q", n.approximation_bound),
                    ("text", n.constant_unit),
                    ("text", n.constant_source),
                ]
            )
        if kind == "constants":
            return "~".join(encode("constant", x) for x in value)
        if kind.startswith("limits:"):
            scalar = kind[7:]
            values = [
                (scalar, f(value))
                for f in (
                    n.minimum_normal,
                    n.minimum_subnormal,
                    n.maximum_finite,
                    n.machine_epsilon,
                )
            ]
            values += [
                ("i", f(value))
                for f in (n.significand_digits, n.minimum_exponent, n.maximum_exponent)
            ]
            return ";".join(encode(k, x) for k, x in values)
        if kind == "ints":
            return ",".join(str(x) for x in value)
        raise AssertionError(kind)

    cases = []

    def case(label, expression, kind, call, hs_encoder=None):
        cases.append(
            (
                label,
                expression,
                kind,
                call,
                hs_encoder
                or {
                    "d": "d",
                    "f": "f",
                    "i": "show",
                    "q": "q",
                    "bool": "show",
                    "enum": "ieee",
                    "text": "text",
                    "half": "show . N.float16Bits",
                    "bhalf": "show . N.bfloat16Bits",
                    "big": "big",
                    "fixed": "fixed",
                    "decimal": "q . N.decimalRational",
                    "interval": "interval",
                    "constant": "constant",
                    "constants": 'intercalate "~" . map constant',
                    "ints": 'intercalate "," . map show',
                }.get(kind),
            )
        )

    mode_names = ["NearestEven", "TowardZero", "TowardPositive", "TowardNegative"]
    edge_values = [
        0.0,
        -0.0,
        1.1,
        -1.1,
        65504.0,
        65520.0,
        1e-40,
        -1e-40,
        math.inf,
        -math.inf,
        math.nan,
    ]
    hs_values = [
        "0",
        "castWord64ToDouble 9223372036854775808",
        "1.1",
        "-1.1",
        "65504",
        "65520",
        "1e-40",
        "-1e-40",
        "1/0",
        "-1/0",
        "0/0",
    ]
    for mode, mode_name in enumerate(mode_names):
        for index, (value, hsvalue) in enumerate(zip(edge_values, hs_values)):
            for name, hsname, kind in [
                ("float16", "float16", "half"),
                ("bfloat16", "bfloat16", "bhalf"),
            ]:
                case(
                    f"{name}-{mode}-{index}",
                    f"N.{hsname} N.{mode_name} (opaque ({hsvalue}) :: Double)",
                    "r:" + kind,
                    lambda name=name, mode=mode, value=value: getattr(n, name)(
                        mode, value
                    ),
                    f"rounded ({'show . N.float16Bits' if kind == 'half' else 'show . N.bfloat16Bits'})",
                )
        for value in [
            Fraction(-7, 2),
            Fraction(-1, 2),
            Fraction(1, 2),
            Fraction(7, 2),
            Fraction(10**100 + 1, 3),
        ]:
            case(
                f"round-{mode}-{value}",
                f"N.roundRational N.{mode_name} ({value.numerator}%{value.denominator})",
                "i",
                lambda mode=mode, value=value: n.round_rational(mode, value),
            )
    for width, dtype, haskell in [(64, "float64", "Double"), (32, "float32", "Float")]:
        for index, (value, hsvalue) in enumerate(zip(edge_values, hs_values)):
            if width == 32 and index == 1:
                hsvalue = "castWord32ToFloat 2147483648"
            case(
                f"class-{width}-{index}",
                f"N.classify (opaque ({hsvalue}) :: {haskell})",
                "enum",
                lambda value=value, dtype=dtype: n.classify(n.number(value, dtype)),
            )
            if math.isfinite(value):
                case(
                    f"frexp-{width}-{index}",
                    f"N.frexp (opaque ({hsvalue}) :: {haskell})",
                    "frexp:" + ("d" if width == 64 else "f"),
                    lambda value=value, dtype=dtype: n.frexp(n.number(value, dtype)),
                    f"pair {'d' if width == 64 else 'f'} show",
                )
        case(
            f"limits-{width}",
            f"N.numericLimits (0 :: {haskell})",
            "limits:" + ("d" if width == 64 else "f"),
            lambda dtype=dtype: n.numeric_limits(n.number(0, dtype)),
            f"limits {'d' if width == 64 else 'f'}",
        )
    for factory, hsname in [
        ("float16_limits", "float16Limits"),
        ("bfloat16_limits", "bfloat16Limits"),
    ]:
        case(
            factory,
            "N." + hsname,
            "limits:d",
            lambda factory=factory: getattr(n, factory)(),
            "limits d",
        )
    bounded = [
        ("int8", "Int8"),
        ("int16", "Int16"),
        ("int32", "Int32"),
        ("int64", "Int64"),
        ("uint8", "Word8"),
        ("uint16", "Word16"),
        ("uint32", "Word32"),
        ("uint64", "Word64"),
        ("intp", "Int"),
        ("uintp", "Word"),
    ]
    for dtype, hs in bounded:
        case(
            "integer-limits-" + dtype,
            f"let (a,b)=N.integerLimits (0::{hs}) in [a,b]",
            "ints",
            lambda dtype=dtype: n.integer_limits(n.number(0, dtype)),
        )
        for source in [-(10**100), -1, 0, 1, 10**100]:
            case(
                f"saturate-{dtype}-{source}",
                f"toInteger (N.saturatingCast ({source}::Integer) :: {hs})",
                "i",
                lambda dtype=dtype, source=source: n.saturating_cast(source, dtype),
            )
        case(
            "safe-cast-" + dtype,
            f"toInteger (right (N.safeIntegralCast (1::Integer)) :: {hs})",
            "i",
            lambda dtype=dtype: n.safe_integral_cast(1, dtype),
        )
        case(
            "real-cast-" + dtype,
            f"toInteger (right (N.realToIntegral N.NearestEven (1.5::Double)) :: {hs})",
            "i",
            lambda dtype=dtype: n.real_to_integral(0, 1.5, dtype),
        )
    for factory, hs_factory, kind in [
        ("big_float", "bigFloat", "big"),
        ("fixed", "fixed", "fixed"),
        ("decimal", "decimal", "decimal"),
    ]:
        precisions = [2, 53, 200] if kind == "big" else [0, 4, 40]
        for precision in precisions:
            for mode, mode_name in enumerate(mode_names):
                expression = f"right (N.{hs_factory} {precision} N.{mode_name} (1%3))"
                case(
                    f"{factory}-{precision}-{mode}",
                    expression,
                    "r:" + kind,
                    lambda factory=factory, precision=precision, mode=mode: getattr(
                        n, factory
                    )(precision, mode, Fraction(1, 3)),
                    "rounded "
                    + {
                        "big": "big",
                        "fixed": "fixed",
                        "decimal": "(q . N.decimalRational)",
                    }[kind],
                )
    owners = []

    def own(value):
        owners.append(value)
        return value

    big_a = own(n.big_float(200, 0, Fraction(1, 3)).rounded_value)
    big_b = own(n.big_float(80, 0, Fraction(7, 5)).rounded_value)
    for py, hs in [
        ("big_add", "bigAdd"),
        ("big_subtract", "bigSubtract"),
        ("big_multiply", "bigMultiply"),
        ("big_divide", "bigDivide"),
    ]:
        case(
            py,
            f"right (N.{hs} bigA bigB)",
            "big",
            lambda py=py: getattr(n, py)(big_a, big_b),
        )
    for py, hs in [
        ("big_sqrt", "bigSqrt"),
        ("big_exp", "bigExp"),
        ("big_log", "bigLog"),
    ]:
        case(py, f"right (N.{hs} bigB)", "big", lambda py=py: getattr(n, py)(big_b))
    case(
        "extended",
        "right (N.extended (1%7))",
        "big",
        lambda: n.extended(Fraction(1, 7)),
    )
    case("big-to-double", "N.bigToDouble bigA", "d", lambda: n.big_to_double(big_a))
    for py, hs in [("mixed_add", "mixedAdd"), ("mixed_multiply", "mixedMultiply")]:
        case(
            py,
            f"right (N.{hs} bigA 1.1)",
            "big",
            lambda py=py: getattr(n, py)(big_a, 1.1),
        )
    for prefix, kind, encoder in [
        ("fixed", "fixed", "fixed"),
        ("decimal", "decimal", "(q . N.decimalRational)"),
    ]:
        a = own(getattr(n, prefix)(4, 0, Fraction(1, 3)).rounded_value)
        b = own(getattr(n, prefix)(2, 0, Fraction(7, 5)).rounded_value)
        for py, hs in [("add", "Add"), ("multiply", "Multiply"), ("divide", "Divide")]:
            mode_arg = "N.TowardNegative " if py != "add" else ""
            fn = prefix + "_" + py
            case(
                fn,
                f"right (N.{prefix}{hs} {mode_arg}{prefix}A {prefix}B)",
                "r:" + kind,
                lambda fn=fn, py=py, a=a, b=b: getattr(n, fn)(
                    *([] if py == "add" else [3]), a, b
                ),
                "rounded " + encoder,
            )
    a = own(n.interval(-1, 2))
    b = own(n.interval(3, 4))
    for py, hs in [
        ("interval_add", "intervalAdd"),
        ("interval_subtract", "intervalSubtract"),
        ("interval_multiply", "intervalMultiply"),
        ("interval_divide", "intervalDivide"),
    ]:
        case(
            py,
            f"right (N.{hs} intervalA intervalB)",
            "interval",
            lambda py=py: getattr(n, py)(a, b),
        )
    case(
        "interval-contains",
        "N.intervalContains intervalA 0",
        "bool",
        lambda: n.interval_contains(a, 0),
    )
    for dtype, hs, enc, value in [
        ("integer", "Integer", "i", 10**100),
        ("rational", "Rational", "q", Fraction(1, 3)),
        ("float32", "Float", "f", -2.0),
        ("float64", "Double", "d", -2.0),
    ]:
        hsvalue = (
            f"{value.numerator}%{value.denominator}"
            if isinstance(value, Fraction)
            else repr(value)
        )
        x = own(n.number(value, dtype))
        case(
            "dual-" + dtype,
            f"N.Dual ({hsvalue}::{hs}) 3",
            "dual:" + enc,
            lambda x=x: n.dual(x, n.literal_integer(x, 3, boxed=True)),
            f"dual {enc if enc in ('d', 'f') else 'show' if enc == 'i' else 'q'}",
        )
        case(
            "derivative-" + dtype,
            f"N.derivative (\\x -> x*x*x+2*x) ({hsvalue}::{hs})",
            enc,
            lambda x=x: n.derivative(lambda y: y**3 + 2 * y, x),
        )
    nested = own(n.dual(2.0, 1.0))
    case(
        "nested-derivative",
        "N.derivative (\\x -> x*x*x) (N.Dual 2 1::N.Dual Double)",
        "dual:d",
        lambda: n.derivative(lambda x: x**3, nested),
        "dual d",
    )
    case(
        "floating-derivative",
        "N.derivative (\\x -> sin x * exp x) (0.25::Double)",
        "d",
        lambda: n.derivative(lambda x: x.sin() * x.exp(), 0.25),
    )
    for dtype, hs, enc in [
        ("float64", "Double", "d"),
        ("float32", "Float", "f"),
        ("integer", "Integer", "i"),
        ("rational", "Rational", "q"),
    ]:
        parts = [own(n.number(v, dtype)) for v in [1, 2, 3, 4]]
        quat = own(n.quaternion(*parts))
        encoder = enc if enc in ("d", "f") else "show" if enc == "i" else "q"
        case(
            "quat-" + dtype,
            f"N.Quaternion 1 2 3 4::N.Quaternion {hs}",
            "quat:" + enc,
            lambda quat=quat: quat.clone().decode(),
            "quat " + encoder,
        )
        case(
            "quat-conjugate-" + dtype,
            f"N.quaternionConjugate (N.Quaternion 1 2 3 4::N.Quaternion {hs})",
            "quat:" + enc,
            lambda quat=quat: n.quaternion_conjugate(quat),
            "quat " + encoder,
        )
        if enc not in ("d", "f"):
            continue
        case(
            "quat-norm-" + dtype,
            f"N.quaternionNorm (N.Quaternion 1 2 3 4::N.Quaternion {hs})",
            enc,
            lambda quat=quat: n.quaternion_norm(quat),
        )
        case(
            "quat-inverse-" + dtype,
            f"right (N.quaternionInverse (N.Quaternion 1 2 3 4::N.Quaternion {hs}))",
            "quat:" + enc,
            lambda quat=quat: n.quaternion_inverse(quat),
            "quat " + encoder,
        )
    quat = own(n.quaternion(1.0, 0.0, 0.0, 0.0))
    dq = own(n.rigid_transform(quat, 1.0, 2.0, 3.0))
    case(
        "rotation",
        "right (N.rotateVector identity (2,3,4))",
        "triple:d",
        lambda: n.rotate_vector(quat, 2.0, 3.0, 4.0),
        "triple d",
    )
    case(
        "rigid-transform",
        "right (N.rigidTransform identity (1,2,3))",
        "dq:d",
        lambda: n.rigid_transform(quat, 1.0, 2.0, 3.0),
        "dq d",
    )
    case(
        "dq-inverse",
        "right (N.dualQuaternionInverse transform)",
        "dq:d",
        lambda: n.dual_quaternion_inverse(dq),
        "dq d",
    )
    case(
        "dq-multiply",
        "N.dualQuaternionMultiply transform transform",
        "dq:d",
        lambda: n.dual_quaternion_multiply(dq, dq),
        "dq d",
    )
    case(
        "transform-point",
        "right (N.transformPoint transform (2,3,4))",
        "triple:d",
        lambda: n.transform_point(dq, 2.0, 3.0, 4.0),
        "triple d",
    )
    for py, hs in [
        ("speed_of_light", "speedOfLight"),
        ("planck_constant", "planckConstant"),
        ("elementary_charge", "elementaryCharge"),
        ("boltzmann_constant", "boltzmannConstant"),
        ("avogadro_constant", "avogadroConstant"),
        ("gravitational_constant", "gravitationalConstant"),
        ("electron_mass", "electronMass"),
        ("astronomical_unit", "astronomicalUnit"),
    ]:
        case(py, "K." + hs, "constant", lambda py=py: getattr(n, py)())
    case(
        "math-constants",
        "K.mathematicalConstants",
        "constants",
        n.mathematical_constants,
    )
    case("physical-constants", "K.physicalConstants", "constants", n.physical_constants)
    c = own(
        n.constant(
            "name\x00λ\ud800",
            Fraction(10**100 + 1, 7),
            Fraction(-1, 3),
            Fraction(1, 11),
            "m\x00s",
            "source\udfff",
        )
    )
    case(
        "custom-constant",
        'K.Constant (map toEnum [110,97,109,101,0,955,55296]) ((10^100+1)%7) (-1%3) (1%11) "m\\0s" ("source"++[toEnum 57343])',
        "constant",
        lambda: c.clone().decode(),
    )
    case(
        "constant-as-rational",
        "K.constantAs K.speedOfLight::Rational",
        "q",
        lambda: n.constant_as(n.speed_of_light(), "rational"),
    )
    case(
        "constant-as-dual",
        "K.constantAs K.speedOfLight::N.Dual Double",
        "dual:d",
        lambda: n.constant_as_like(n.speed_of_light(), nested),
        "dual d",
    )
    for bit in [
        0,
        1,
        2,
        0x3C00,
        0x7BFF,
        0x7C00,
        0x7C01,
        0x7FFF,
        0x8000,
        0x8001,
        0xFC00,
        0xFFFF,
    ]:
        case(
            f"half-bits-{bit}",
            f"N.fromFloat16 (N.float16FromBits {bit})",
            "d",
            lambda bit=bit: n.from_float16(n.float16_from_bits(bit)),
        )
        case(
            f"bhalf-bits-{bit}",
            f"N.fromBFloat16 (N.bfloat16FromBits {bit})",
            "d",
            lambda bit=bit: n.from_bfloat16(n.bfloat16_from_bits(bit)),
        )
    lines = [
        "{-# LANGUAGE ScopedTypeVariables #-}",
        "import qualified HMath.Numeric as N",
        "import qualified HMath.Constants as K",
        "import Data.Ratio",
        "import Data.Int",
        "import Data.Word",
        "import Data.List (intercalate)",
        "import GHC.Float",
        "import System.Environment (getArgs)",
        "{-# NOINLINE opaque #-}",
        "opaque :: a -> a",
        "opaque x=x",
        'd x=if isNaN x then "nan" else show (castDoubleToWord64 x)',
        'f x=if isNaN x then "nan" else show (castFloatToWord32 x)',
        'q x=show (numerator x)++"/"++show (denominator x)',
        'text=intercalate "," . map (show . fromEnum)',
        "right (Right x)=x",
        "right (Left e)=error (show e)",
        "flag x=case x of {N.InvalidOperation->0;N.DivisionByZero->1;N.NumericOverflow->2;N.NumericUnderflow->3;N.Inexact->4}",
        "ieee x=show (case x of {N.NotANumber->0;N.PositiveInfinity->1;N.NegativeInfinity->2;N.PositiveZero->3;N.NegativeZero->4;N.Subnormal->5;N.Normal->6} :: Int)",
        'rounded encode x=encode (N.roundedValue x)++"!"++intercalate "," (map (show . flag) (N.numericalExceptions x))',
        'big x=show (N.bigPrecision x)++":"++q (N.bigRational x)',
        'fixed x=show (N.fixedScale x)++":"++show (N.fixedCoefficient x)',
        'interval x=let (a,b)=N.intervalBounds x in d a++","++d b',
        'pair a b (x,y)=a x++":"++b y',
        'dual e (N.Dual a b)=e a++";"++e b',
        'quat e (N.Quaternion a b c z)=intercalate ";" [e a,e b,e c,e z]',
        'dq e (N.DualQuaternion a b)=quat e a++"/"++quat e b',
        'triple e (a,b,c)=intercalate "," [e a,e b,e c]',
        'limits e x=intercalate ";" [e (N.minimumNormal x),e (N.minimumSubnormal x),e (N.maximumFinite x),e (N.machineEpsilon x),show (N.significandDigits x),show (N.minimumExponent x),show (N.maximumExponent x)]',
        'constant x=intercalate "|" [text (K.constantName x),q (K.constantValue x),q (K.standardUncertainty x),q (K.approximationBound x),text (K.constantUnit x),text (K.constantSource x)]',
        "bigA=N.roundedValue (right (N.bigFloat 200 N.NearestEven (1%3)))",
        "bigB=N.roundedValue (right (N.bigFloat 80 N.NearestEven (7%5)))",
        "fixedA=N.roundedValue (right (N.fixed 4 N.NearestEven (1%3)))",
        "fixedB=N.roundedValue (right (N.fixed 2 N.NearestEven (7%5)))",
        "decimalA=N.roundedValue (right (N.decimal 4 N.NearestEven (1%3)))",
        "decimalB=N.roundedValue (right (N.decimal 2 N.NearestEven (7%5)))",
        "intervalA=right (N.interval (-1) 2)",
        "intervalB=right (N.interval 3 4)",
        "identity=N.Quaternion 1 0 0 0::N.Quaternion Double",
        "transform=right (N.rigidTransform identity (1,2,3))",
        "main=do",
    ]
    for index, (_, expression, _, _, encoder) in enumerate(cases):
        if encoder is None:
            raise AssertionError(cases[index][:3])
        lines.append(
            f'  putStrLn (show ({index}::Int)++"\\t"++({encoder}) ({expression}))'
        )
    with tempfile.TemporaryDirectory(prefix="hmath-numeric-types-oracle-") as temporary:
        path = Path(temporary)
        source = path / "Main.hs"
        source.write_text("\n".join(lines) + "\n")
        subprocess.run(
            [
                "ghc",
                "-O0",
                "-isrc",
                "-outputdir",
                temporary,
                str(source),
                "-o",
                str(path / "oracle"),
            ],
            cwd=ROOT,
            check=True,
            stdout=subprocess.DEVNULL,
        )
        oracle = subprocess.check_output([str(path / "oracle")], text=True).splitlines()
    assert len(oracle) == len(cases)
    for index, line in enumerate(oracle):
        expected_index, expected = line.split("\t", 1)
        assert int(expected_index) == index
        label, _, kind, call, _ = cases[index]
        value = call()
        try:
            actual = encode(kind, value)
            assert actual == expected, (label, actual, expected)
        finally:
            if isinstance(value, Value):
                value.close()
            elif isinstance(value, (list, tuple)):
                for child in value:
                    if isinstance(child, Value):
                        child.close()
    # Lifetime/representation contracts independent of numerical oracle cases.
    flags = [
        n.NumericException.INEXACT,
        n.NumericException.INVALID_OPERATION,
        n.NumericException.INEXACT,
    ]
    record = n.rounded(n.number(Fraction(1, 3), "rational"), flags)
    child = record.rounded_value
    record.close()
    assert child.value == Fraction(1, 3)
    child.close()
    assert n.numerical_exceptions(n.rounded(None, flags)) == flags
    assert n.rounded_value(n.rounded([1, Fraction(1, 3)], flags)) == [1, Fraction(1, 3)]
    for function in [lambda x: x**2, lambda x: x * x]:
        assert n.derivative(function, -2.0) == -4.0
    assert n.derivative(lambda x: x * 3, 2.0) == 3.0
    captured = n.number(3.0)
    assert n.derivative(lambda x: x * captured.value, captured) == 3.0
    captured.close()

    def failing(_):
        raise LookupError("callback failure")

    try:
        n.derivative(failing, 2.0)
        raise AssertionError("callback exception swallowed")
    except LookupError as error:
        assert str(error) == "callback failure"
    for call in [
        lambda: n.safe_integral_cast(256, "uint8"),
        lambda: n.interval(2, 1),
        lambda: n.interval_divide(a, n.interval(-1, 1)),
        lambda: n.big_float(0, 0, Fraction(1, 3)),
    ]:
        try:
            call()
            raise AssertionError("original MathError accepted")
        except hmath.HMathError as error:
            assert error.status == 11
    for owner in owners:
        owner.close()
    owners.clear()
    cases.clear()
    gc.collect()
    print(
        f"Numeric types: {len(oracle)} independent Haskell cases plus callback, exact-data and ownership contracts passed."
    )


if __name__ == "__main__":
    main()
