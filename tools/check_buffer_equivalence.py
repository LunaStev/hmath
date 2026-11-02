# SPDX-License-Identifier: MPL-2.0
"""Compare original Buffer operations, concrete Storable instances and scoped contracts."""

import argparse
import gc
import math
import os
import struct
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
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
    from _hmath_native import _value as V
    from _hmath_native import buffer_values as b

    cases = []
    owners = []

    def own(value):
        owners.append(value)
        return value

    def case(label, expression, call):
        cases.append((label, expression, call))

    def list_of(encoder, values):
        return "[" + ",".join(encoder(x) for x in values) + "]"

    huge = 10**150 + 7
    integer_box = own(b.Boxed([huge, -huge, 0]))
    integer_hs = f"B.lazyBoxed [{huge},-{huge},0::Integer]"
    case(
        "lazyBoxed",
        "pure(Right(list show(B.boxedValues(" + integer_hs + "))))",
        lambda: list_of(str, integer_box.values),
    )
    case(
        "strictBoxed",
        f"pure(Right(list show(B.boxedValues(B.strictBoxed [{huge},-{huge},0::Integer]))))",
        lambda: list_of(str, own(b.strict_boxed([huge, -huge, 0])).values),
    )
    case(
        "boxedLength",
        f"pure(Right(show(B.boxedLength({integer_hs}))))",
        lambda: str(b.boxed_length(integer_box)),
    )
    case(
        "mapStrict",
        f"pure(Right(list show(B.boxedValues(B.mapStrict(+1)({integer_hs})))))",
        lambda: list_of(str, own(b.map_strict(lambda x: x + 1, integer_box)).values),
    )
    case(
        "emptyBoxed",
        "pure(Right(list show(B.boxedValues(B.lazyBoxed []::B.Boxed Integer))))",
        lambda: list_of(str, own(b.lazy_boxed([])).values),
    )
    rationals = [Fraction(huge, 7), Fraction(-5, 17)]
    rational_box = own(b.strict_boxed(rationals))
    rat = lambda x: str(x.numerator) + "/" + str(x.denominator)
    case(
        "boxedRational",
        f"pure(Right(list rational(B.boxedValues(B.strictBoxed [{huge}%7,(-5)%17]))))",
        lambda: list_of(rat, rational_box.values),
    )
    case(
        "mapRational",
        f"pure(Right(list rational(B.boxedValues(B.mapStrict(*2)(B.strictBoxed [{huge}%7,(-5)%17])))))",
        lambda: list_of(rat, own(b.map_strict(lambda x: x * 2, rational_box)).values),
    )
    doubles = [0.0, -0.0, math.inf, -math.inf, math.nan, 1e-300]
    double_hs = "[0,castWord64ToDouble 9223372036854775808,1/0,-1/0,0/0,1e-300]"
    unboxed = own(b.unboxed_double(doubles))
    case(
        "unboxedDouble",
        f"pure(Right(list fp64(B.unboxedValues(B.unboxedDouble(opaque {double_hs})))))",
        lambda: list_of(bits, unboxed.values),
    )
    case(
        "unboxedToBoxed",
        f"pure(Right(list fp64(B.boxedValues(B.unboxedToBoxed(B.unboxedDouble(opaque {double_hs}))))))",
        lambda: list_of(bits, own(b.unboxed_to_boxed(unboxed)).values),
    )
    double_box = own(b.Boxed(doubles))
    case(
        "boxedToUnboxed",
        f"pure(Right(list fp64(B.unboxedValues(B.boxedToUnboxed(B.lazyBoxed(opaque {double_hs}))))))",
        lambda: list_of(bits, own(b.boxed_to_unboxed(double_box)).values),
    )

    def st_copy():
        def action(region):
            before = region.read(0)
            b.write_st_buffer(region, 1, 9)
            frozen = own(b.freeze_st_buffer(region))
            other = own(b.thaw_st_buffer(region, integer_box))
            other.write(0, 12)
            second = own(other.freeze())
            return (
                str(before)
                + ";"
                + list_of(str, frozen.values)
                + ";"
                + list_of(str, second.values)
            )

        return b.run_st_buffer(integer_box, action)

    case(
        "ST read/write/freeze/thaw",
        f'pure(Right(B.runSTBuffer ({integer_hs}) $ \\s -> do before <- B.readSTBuffer s 0;_ <- B.writeSTBuffer s 1 9;frozen <- B.freezeSTBuffer s;other <- B.thawSTBuffer({integer_hs});_ <- B.writeSTBuffer other 0 12;second <- B.freezeSTBuffer other;pure(show(right before)++";"++list show(B.boxedValues frozen)++";"++list show(B.boxedValues second)) ))',
        st_copy,
    )
    for index in (-1, 3):
        case(
            "ST read invalid " + str(index),
            f"pure(B.runSTBuffer({integer_hs})(\\s -> fmap(fmap show)(B.readSTBuffer s ({index}))))",
            lambda index=index: str(
                b.run_st_buffer(integer_box, lambda region: region.read(index))
            ),
        )
        case(
            "ST write invalid " + str(index),
            f"pure(B.runSTBuffer({integer_hs})(\\s -> fmap(fmap show)(B.writeSTBuffer s ({index}) 1)))",
            lambda index=index: str(
                b.run_st_buffer(integer_box, lambda region: region.write(index, 1))
            ),
        )
    case(
        "ST frozen independence",
        f"pure(Right(B.runSTBuffer({integer_hs}) $ \\s -> do f <- B.freezeSTBuffer s;_ <- B.writeSTBuffer s 0 13;pure(list show(B.boxedValues f))))",
        lambda: b.run_st_buffer(
            integer_box, lambda region: _st_frozen(region, own, list_of)
        ),
    )

    storage = [
        (
            "float64",
            "Double",
            "castWord64ToDouble 9223372036854775808",
            "1.25",
            -0.0,
            1.25,
            "fp64",
            bits,
        ),
        (
            "float32",
            "Float",
            "castWord32ToFloat 2147483648",
            "1.25",
            -0.0,
            1.25,
            "fp32",
            lambda x: bits(x, 32),
        ),
        (
            "complex128",
            "Complex Double",
            "(0.25:+castWord64ToDouble 9223372036854775808)",
            "((-2):+1.5)",
            complex(0.25, -0.0),
            complex(-2, 1.5),
            "(cx fp64)",
            lambda x: bits(x.real) + "," + bits(x.imag),
        ),
        (
            "complex64",
            "Complex Float",
            "(0.25:+castWord32ToFloat 2147483648)",
            "((-2):+1.5)",
            complex(0.25, -0.0),
            complex(-2, 1.5),
            "(cx fp32)",
            lambda x: bits(x.real, 32) + "," + bits(x.imag, 32),
        ),
    ]
    for dtype, typ, low, high in [
        ("int8", "Int8", -128, 127),
        ("int16", "Int16", -32768, 32767),
        ("int32", "Int32", -(2**31), 2**31 - 1),
        ("int64", "Int64", -(2**63), 2**63 - 1),
        ("uint8", "Word8", 0, 255),
        ("uint16", "Word16", 0, 65535),
        ("uint32", "Word32", 0, 2**32 - 1),
        ("uint64", "Word64", 0, 2**64 - 1),
        ("intp", "Int", -(2**63), 2**63 - 1),
        ("uintp", "Word", 0, 2**64 - 1),
    ]:
        storage.append((dtype, typ, str(low), str(high), low, high, "show", str))
    storage.extend(
        [
            ("bool", "Bool", "False", "True", False, True, "show", lambda x: str(x)),
            (
                "char",
                "Char",
                "'\\xD800'",
                "'\\xAC00'",
                "\ud800",
                "가",
                "(show . ord)",
                lambda x: str(ord(x)),
            ),
        ]
    )
    for dtype, typ, hs_initial, hs_changed, initial, changed, enc, encode in storage:
        io = own(b.new_io_buffer(3, initial, dtype=dtype))
        typed_initial = "(opaque (" + hs_initial + ")::" + typ + ")"
        typed_changed = "(" + hs_changed + "::" + typ + ")"
        code = {"bool": 16, "char": 17}.get(dtype, V.DTYPES.get(dtype))
        hs_setup = "do io <- checked(B.newIOBuffer 3 " + typed_initial + ");"

        def check_storage(io=io, changed=changed, encode=encode):
            b.write_io_buffer(io, 1, changed)
            frozen = own(b.freeze_io_buffer(io))
            return (
                encode(b.read_io_buffer(io, 1))
                + ";"
                + list_of(encode, frozen.values)
                + ";"
                + ",".join(str(x) for x in io.layout)
            )

        case(
            dtype + " new/write/read/freeze/layout",
            hs_setup
            + "_ <- checked(B.writeIOBuffer io 1 "
            + typed_changed
            + ");x <- checked(B.readIOBuffer io 1);f <- B.freezeIOBuffer io;pure(Right("
            + enc
            + ' x++";"++list '
            + enc
            + '(B.boxedValues f)++";"++intercalate ","(map show['
            + str(code)
            + ",sizeOf(undefined::"
            + typ
            + "),alignment(undefined::"
            + typ
            + "),B.ioBufferLength io])))",
            check_storage,
        )

        def check_thaw(initial=initial, changed=changed, dtype=dtype, encode=encode):
            source = own(b.Boxed([initial, changed], dtype=dtype))
            copy = own(b.thaw_io_buffer(source))
            copy.write(0, changed)
            frozen = own(copy.freeze())
            return list_of(encode, source.values) + ";" + list_of(encode, frozen.values)

        case(
            dtype + " thaw copy",
            "do original <- pure(B.lazyBoxed["
            + typed_initial
            + ","
            + typed_changed
            + "]); io <- checked(B.thawIOBuffer original);_ <- checked(B.writeIOBuffer io 0 "
            + typed_changed
            + ");f <- B.freezeIOBuffer io;pure(Right(list "
            + enc
            + '(B.boxedValues original)++";"++list '
            + enc
            + "(B.boxedValues f)))",
            check_thaw,
        )

        def check_pointer(initial=initial, changed=changed, dtype=dtype, encode=encode):
            io = own(b.IOBuffer(2, initial, dtype=dtype))

            def callback(pointer, count):
                first = pointer.read(0)
                pointer.write(1, changed)
                return encode(first) + "," + str(count)

            result = b.with_io_buffer(io, callback)
            return result + ";" + list_of(encode, own(io.freeze()).values)

        case(
            dtype + " withIOBuffer",
            "do io <- checked(B.newIOBuffer 2 "
            + typed_initial
            + ");r <- B.withIOBuffer io(\\p n -> do x <- peekElemOff p 0;pokeElemOff p 1 "
            + typed_changed
            + ";pure("
            + enc
            + ' x++","++show n));f <- B.freezeIOBuffer io;pure(Right(r++";"++list '
            + enc
            + "(B.boxedValues f)))",
            check_pointer,
        )
        for index in (-1, 3):
            case(
                dtype + " bad read " + str(index),
                hs_setup
                + "fmap(fmap("
                + enc
                + "))(B.readIOBuffer io ("
                + str(index)
                + "))",
                lambda io=io, index=index, encode=encode: encode(io.read(index)),
            )
            case(
                dtype + " bad write " + str(index),
                hs_setup
                + "fmap(fmap show)(B.writeIOBuffer io ("
                + str(index)
                + ") "
                + typed_changed
                + ")",
                lambda io=io, index=index, changed=changed: str(
                    io.write(index, changed)
                ),
            )
        case(
            dtype + " negative allocation",
            "fmap(fmap(show . B.ioBufferLength))(B.newIOBuffer (-1) "
            + typed_initial
            + ")",
            lambda dtype=dtype, initial=initial: str(
                len(own(b.new_io_buffer(-1, initial, dtype=dtype)))
            ),
        )
    case(
        "allocation byte overflow",
        "fmap(fmap(show . B.ioBufferLength))(B.newIOBuffer maxBound (0::Double))",
        lambda: str(len(own(b.IOBuffer(sys.maxsize, 0.0)))),
    )

    lines = [
        "module Main where",
        "import qualified HMath.API.Buffer as B",
        "import HMath.Error",
        "import Foreign.Storable",
        "import Data.Int",
        "import Data.Word",
        "import Data.Complex",
        "import Data.Ratio",
        "import Data.Char(ord)",
        "import Data.List(intercalate)",
        "import GHC.Float",
        "opaque :: a -> a",
        "opaque x=x",
        "{-# NOINLINE opaque #-}",
        'list e xs="["++intercalate ","(map e xs)++"]"',
        'fp64 x=if isNaN x then "nan" else show(castDoubleToWord64 x)',
        'fp32 x=if isNaN x then "nan" else show(castFloatToWord32 x)',
        'cx e x=e(realPart x)++","++e(imagPart x)',
        'rational x=show(numerator x)++"/"++show(denominator x)',
        "right(Right x)=x",
        "right(Left e)=error(show e)",
        "checked action=action >>= either (fail . show) pure",
        "emit :: IO(Either MathError String) -> IO ()",
        'emit action=action >>= either (putStrLn . ("ERR:"++) . show) (putStrLn . ("OK:"++))',
        "main=do",
    ]
    for _, expression, _ in cases:
        lines.append("  emit(" + expression + ")")
    with tempfile.TemporaryDirectory(prefix="hmath-buffer-oracle-") as directory:
        path = Path(directory)
        (path / "Main.hs").write_text("\n".join(lines) + "\n")
        subprocess.run(
            [
                "ghc",
                "-O0",
                "-isrc",
                "-outputdir",
                directory,
                "-stubdir",
                directory,
                str(path / "Main.hs"),
                "-o",
                str(path / "oracle"),
            ],
            cwd=ROOT,
            check=True,
            stdout=subprocess.DEVNULL,
        )
        expected = subprocess.check_output(
            [str(path / "oracle")], text=True
        ).splitlines()
    assert len(expected) == len(cases)
    for (label, _, call), wanted in zip(cases, expected):
        try:
            actual = "OK:" + call()
        except hmath.HMathError as error:
            assert error.math_error is not None, (label, error)
            actual = "ERR:" + str(error.math_error)
        assert actual == wanted, (label, actual, wanted)

    _scope_contracts(b, own, hmath)
    _io_contracts(b, own, hmath)
    for owner in reversed(owners):
        owner.close()
    gc.collect()
    print(
        f"Buffer: {len(expected)} direct Haskell cases; ST/Ptr expiry, callback exceptions, reentry, exact generic values, every standard Storable instance and concurrent IO contracts passed."
    )


def _st_frozen(region, own, list_of):
    frozen = own(region.freeze())
    region.write(0, 13)
    return list_of(str, frozen.values)


def _scope_contracts(b, own, hmath):
    retained = []
    source = own(b.Boxed([1, 2]))

    def region_action(region):
        retained.append(region)
        with ThreadPoolExecutor(max_workers=1) as pool:
            future = pool.submit(region.read, 0)
            try:
                future.result(timeout=5)
            except hmath.HMathError as error:
                assert "another thread" in str(error)
            else:
                raise AssertionError("cross-thread ST operation succeeded")
        return region.freeze()

    frozen = own(b.run_st_buffer(source, region_action))
    assert frozen.values == [1, 2]
    region = retained[0]
    assert not region.active
    for action in (
        lambda: region.read(0),
        lambda: region.write(0, 3),
        region.freeze,
        lambda: region.thaw(source),
    ):
        try:
            action()
        except hmath.HMathError as error:
            assert "scope has ended" in str(error)
        else:
            raise AssertionError("ST scope escaped")
    region.close()
    sentinel = ValueError("original callback failure")

    def fail(region):
        retained.append(region)
        raise sentinel

    try:
        b.run_st_buffer(source, fail)
    except ValueError as error:
        assert error is sentinel
    else:
        raise AssertionError("ST callback exception lost")
    assert not retained[-1].active
    retained[-1].close()
    try:
        b.map_strict(lambda _: (_ for _ in ()).throw(sentinel), source)
    except ValueError as error:
        assert error is sentinel
    else:
        raise AssertionError("mapStrict callback exception lost")


def _io_contracts(b, own, hmath):
    retained = []
    io = own(b.IOBuffer(16, 0, dtype="int64"))
    sentinel = LookupError("original pointer callback failure")

    def borrow(pointer, count):
        assert count == 16 and pointer.active and pointer.address > 0
        retained.append(pointer)
        pointer.write(0, 7)
        assert len(io) == 16
        for action in (
            lambda: io.read(0),
            lambda: io.write(0, 1),
            io.freeze,
            lambda: io.with_pointer(lambda *_: None),
        ):
            try:
                action()
            except hmath.HMathError as error:
                assert "cannot reenter" in str(error)
            else:
                raise AssertionError("borrowed IO buffer reentry succeeded")
        with ThreadPoolExecutor(max_workers=1) as pool:
            future = pool.submit(pointer.read, 0)
            try:
                future.result(timeout=5)
            except hmath.HMathError as error:
                assert "another thread" in str(error)
            else:
                raise AssertionError("cross-thread pointer operation succeeded")
        raise sentinel

    try:
        io.with_pointer(borrow)
    except LookupError as error:
        assert error is sentinel
    else:
        raise AssertionError("pointer callback exception lost")
    assert io.read(0) == 7
    pointer = retained[0]
    assert not pointer.active
    for action in (
        lambda: pointer.read(0),
        lambda: pointer.write(0, 1),
        lambda: pointer.address,
        lambda: pointer.layout,
    ):
        try:
            action()
        except hmath.HMathError as error:
            assert "scope has ended" in str(error)
        else:
            raise AssertionError("borrowed pointer escaped")
    pointer.close()
    with ThreadPoolExecutor(max_workers=4) as pool:
        list(pool.map(lambda index: io.write(index, index * 3), range(16)))
        assert list(pool.map(io.read, range(16))) == [index * 3 for index in range(16)]
    frozen = own(io.freeze())
    copy = own(b.thaw_io_buffer(frozen))
    io.close()
    assert copy.read(7) == 21
    copy.write(7, 99)
    assert frozen.values[7] == 21
    # Common Bool/Text Values carry dtype=-1; their Storable storage witnesses
    # remain actual Bool/Char rather than numeric coefficient type codes.
    from _hmath_native import _value as V

    for dtype, initial in (("bool", True), ("char", "\0")):
        value = own(V.encode(initial))
        storage = own(b.new_io_buffer(1, value, dtype=dtype))
        storage.write(0, value)
        assert storage.read(0) == initial
        source = own(b.Boxed([value], dtype=dtype))
        copied = own(b.thaw_io_buffer(source))
        assert copied.read(0) == initial
    empty = own(b.Boxed([]))
    empty_io = own(b.thaw_io_buffer(empty, dtype="float32"))
    assert len(empty_io) == 0 and empty_io.dtype == "float32"
    for value in (10**100, Fraction(1, 3)):
        try:
            b.new_io_buffer(
                1, value, dtype="integer" if isinstance(value, int) else "rational"
            )
        except hmath.HMathError as error:
            assert "Storable" in str(error)
        else:
            raise AssertionError("invented Storable instance")


if __name__ == "__main__":
    main()
