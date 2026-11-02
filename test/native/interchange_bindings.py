# SPDX-License-Identifier: MPL-2.0
"""Independent formats, exact typed scalars, streams, scoped IO and callbacks."""

import gc
import io
import struct
import sys
import tempfile
import weakref
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath
from _hmath_native import _value as wire
from _hmath_native import interchange as i
from _hmath_native import matrix_advanced
from _hmath_native._expression_error import ErrorKind, ExprError, SourcePos
from _hmath_native._interchange_error import InterchangeError, InterchangeErrorKind
from _hmath_native._linear_base import _callback
from _hmath_native._math_error import MathError, MathErrorKind

DTYPES = [
    ("bool", "?", [True, False, False, True]),
    ("int8", "b", [-128, -1, 0, 127]),
    ("uint8", "B", [0, 1, 128, 255]),
    ("int16", "h", [-32768, -1, 0, 32767]),
    ("uint16", "H", [0, 1, 32768, 65535]),
    ("int32", "i", [-(2**31), -1, 0, 2**31 - 1]),
    ("uint32", "I", [0, 1, 2**31, 2**32 - 1]),
    ("int64", "q", [-(2**63), -(2**53) - 1, 2**53 + 1, 2**63 - 1]),
    ("uint64", "Q", [0, 1, 2**53 + 1, 2**64 - 1]),
    ("float32", "f", [0.0, 1 / 3, -0.0, 1.0]),
    ("float64", "d", [0.0, 1 / 3, -0.0, 1.0]),
    ("complex64", "ff", [1 + 2j, 3 - 4j, 0j, 1j]),
    ("complex128", "dd", [1 + 2j, 3 - 4j, 0j, 1j]),
]
with (
    tempfile.TemporaryDirectory(prefix="hmath-interchange-contract-") as directory,
    i.default_limits() as limits,
    i.little_endian() as little,
    i.big_endian() as big,
    i.c_order() as corder,
    i.f_order() as forder,
):
    root = Path(directory)
    for dtype, format_code, values in DTYPES:
        for endian, prefix in [(little, "<"), (big, ">")]:
            flat = (
                [part for value in values for part in (value.real, value.imag)]
                if format_code in ("ff", "dd")
                else values
            )
            expected = struct.pack(prefix + format_code * 4, *flat)
            with (
                i.from_values(limits, endian, [2, 2], values, dtype=dtype) as array,
                i.raw_encode(limits, endian, corder, array) as raw,
                i.encode_binary(limits, array) as encoded,
                i.decode_binary(limits, encoded) as decoded,
            ):
                assert bytes(raw) == expected and decoded == array
                with i.to_matrix(decoded) as matrix:
                    assert matrix.shape == (2, 2)
                    with i.from_matrix(limits, endian, matrix) as roundtrip:
                        assert roundtrip == array
                with (
                    i.to_tensor(decoded) as tensor,
                    i.from_tensor(limits, endian, tensor) as roundtrip,
                ):
                    assert roundtrip == array
                with i.encode_npy(limits, forder, array) as npy:
                    assert bytes(npy).startswith(b"\x93NUMPY")
                    with (
                        i.decode_npy(limits, npy) as npy_array,
                        i.raw_encode(limits, endian, corder, npy_array) as back,
                    ):
                        assert bytes(back) == expected
                # NaN payloads and negative zero are compared as raw bytes,
                # not merely by Python's numerical equality.
                path = root / (
                    dtype + prefix.replace("<", "l").replace(">", "b") + ".raw"
                )
                path.write_bytes(expected)
                with (
                    i.element_type(dtype=dtype) as element,
                    i.raw_spec(element, endian, corder, [2, 2]) as spec,
                ):
                    escaped = []

                    def mapped(
                        mapping, escaped=escaped, dtype=dtype, expected=expected
                    ):
                        escaped.append(wire.decode(mapping.clone()))
                        return (
                            mapping.shape,
                            mapping.at([1, 0], dtype=dtype, boxed=True),
                            mapping.read_bytes(0, len(expected)),
                        )

                    shape, scalar, copied = i.with_mapped_array(
                        limits, spec, path, mapped
                    )
                    assert shape == [2, 2] and bytes(copied) == expected
                    with (
                        i.put_element(endian, scalar, dtype=dtype) as put,
                        i.put_bytes(put) as element_bytes,
                    ):
                        width = len(expected) // 4
                        assert bytes(element_bytes) == expected[2 * width : 3 * width]
                    if isinstance(scalar, wire.Value):
                        scalar.close()
                    copied.close()
                    assert escaped[0].shape == [2, 2]  # original safe metadata query
                    for read in [
                        lambda escaped=escaped: escaped[0].read_bytes(0, 1),
                        lambda escaped=escaped, dtype=dtype: escaped[0].at(
                            [0, 0], dtype=dtype
                        ),
                    ]:
                        try:
                            read()
                        except hmath.HMathError as error:
                            assert error.interchange_error == InterchangeError(
                                InterchangeErrorKind.INVALID_DATA, "mapping is closed"
                            )
                        else:
                            raise AssertionError("retired mapping permitted a read")
                    escaped[0].close()
    # Raw and binary retain noncanonical IEEE payloads and signed zeros.
    special = bytes.fromhex("010000000000f87f0000000000000080")
    with (
        i.f64() as dtype,
        i.raw_decode(limits, dtype, little, corder, [2], special) as array,
        i.encode_binary(limits, array) as encoded,
        i.decode_binary(limits, encoded) as decoded,
        i.raw_encode(limits, little, corder, decoded) as raw,
    ):
        assert bytes(raw) == special
    with i.Bytes(b"a\0b") as owner:
        view = owner.view()
    gc.collect()
    assert view.readonly and view.tobytes() == b"a\0b"
    del view
    gc.collect()

    with (
        i.from_values(limits, little, [2, 2], [1.0, 2.0, 3.0, 4.0]) as array,
        i.raw_encode(limits, little, corder, array) as raw,
        i.f64() as dtype,
        i.raw_spec(dtype, little, corder, [2, 2]) as spec,
    ):
        data_path = root / "source.raw"
        data_path.write_bytes(bytes(raw))
        binary_path = root / "array.hmath"
        i.write_array_file(
            limits,
            lambda budget, value: i.encode_binary(budget, value),
            binary_path,
            array,
        )
        with i.read_array_file(
            limits, lambda data: i.decode_binary(limits, data), binary_path
        ) as restored:
            assert restored == array
        seen = []
        with i.open_handle(data_path, "rb") as handle:
            i.read_raw_chunks(
                limits,
                spec,
                2,
                handle,
                lambda value: seen.append(i.to_values(value)) or True,
            )
            assert handle.tell() == len(bytes(raw))
        assert seen == [[1.0, 2.0], [3.0, 4.0]]
        with i.open_handle(data_path, "rb") as handle:
            stopped = []
            i.read_raw_chunks(
                limits,
                spec,
                2,
                handle,
                lambda value: stopped.append(i.to_values(value)) or False,
            )
            assert handle.tell() == 16 and stopped == [[1.0, 2.0]]
        output = root / "produced.raw"
        chunks = [bytes(raw)[:16], bytes(raw)[16:]]
        calls = []

        def produce(maximum):
            calls.append(maximum)
            return chunks.pop(0) if chunks else None

        with i.open_handle(output, "wb") as handle:
            i.write_raw_chunks(limits, spec, 2, handle, produce)
        assert calls == [16, 16, 0] and output.read_bytes() == bytes(raw)
        # Checked consumer Left stops after its already-read first chunk.
        message = "callback\0α🙂\ud800"
        domain_errors = [
            MathError(MathErrorKind.NON_CONVERGENCE, (7,), message),
            ExprError(ErrorKind.TYPE_MISMATCH, SourcePos(19, 3, 5), message),
            InterchangeError(InterchangeErrorKind.INVALID_DATA, message),
        ]
        for failure in domain_errors:

            def bad(_value, failure=failure):
                raise failure

            with i.open_handle(data_path, "rb") as handle:
                try:
                    i.read_raw_chunks(limits, spec, 2, handle, bad)
                except hmath.HMathError as error:
                    payload = (
                        error.math_error
                        or error.expression_error
                        or error.interchange_error
                    )
                    assert vars(payload) == vars(failure) and handle.tell() == 16
                else:
                    raise AssertionError("callback error fields were discarded")

        class BadMessage(Exception):
            def __str__(self):
                raise RuntimeError("formatter failure")

        unexpected = BadMessage()

        def bad_mapping(_mapping):
            raise unexpected

        try:
            i.with_mapped_array(limits, spec, data_path, bad_mapping)
        except BadMessage as error:
            assert error is unexpected
        else:
            raise AssertionError("unexpected mapping callback failure was swallowed")
        # Binary encoder validation precedes opening/truncating an output file.
        keep = root / "keep.hmath"
        keep.write_bytes(b"keep")

        def rejected(_budget, _array):
            raise InterchangeError(InterchangeErrorKind.UNSUPPORTED, "encoder rejected")

        try:
            i.write_array_file(limits, rejected, keep, array)
        except hmath.HMathError as error:
            assert error.interchange_error.kind == InterchangeErrorKind.UNSUPPORTED
        else:
            raise AssertionError("encoder rejection was swallowed")
        assert keep.read_bytes() == b"keep"
        with (
            i.encode_npz(limits, False, [("array", array)]) as archive,
            zipfile.ZipFile(io.BytesIO(bytes(archive))) as zipped,
        ):
            assert zipped.namelist() == ["array.npy"] and zipped.read(
                "array.npy"
            ).startswith(b"\x93NUMPY")

        # A generic mapping result can contain a freshly-created callback.
        # Its userdata survives mapping retirement and is released with the owner.
        class Userdata:
            pass

        references = []

        def return_callback(_mapping):
            userdata = Userdata()
            references.append(weakref.ref(userdata))

            def operation(row, column):
                assert userdata is not None
                return float(row + column)

            return _callback(operation, ["a"], "float64")

        function = i.with_mapped_array(limits, spec, data_path, return_callback)
        gc.collect()
        assert references[0]() is not None
        with matrix_advanced.generate_matrix(1, 2, function) as matrix:
            assert matrix.to_list() == [0.0, 1.0]
        function.close()
        gc.collect()
        assert references[0]() is None
    for decode, data, kind in [
        (
            lambda data: i.decode_binary(limits, data),
            b"bad",
            InterchangeErrorKind.INVALID_DATA,
        ),
        (
            lambda data: i.decode_npy(limits, data),
            b"bad",
            InterchangeErrorKind.INVALID_DATA,
        ),
        (
            lambda data: i.decode_text(limits, data),
            b"bad",
            InterchangeErrorKind.UNSUPPORTED,
        ),
    ]:
        try:
            decode(data)
        except hmath.HMathError as error:
            assert error.status == 13 and error.interchange_error.kind == kind
        else:
            raise AssertionError("malformed input unexpectedly succeeded")
print(
    "Interchange13Element/endian/IEEEbits/MatrixTensor/NPYZIP/Bytesviews/streamorder/mmap-retirement/callback11-12-13/lifetime contracts passed"
)
