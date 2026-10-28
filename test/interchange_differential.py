#!/usr/bin/env python3
# SPDX-License-Identifier: MPL-2.0
"""Independent NumPy/SciPy/ZIP/zlib interoperability, optional adapter tests.

Run with a compiled interchange_driver and, optionally, an environment where
h5py/pyarrow/onnx are installed. Missing optional packages are reported as SKIP;
use --require-optional to make that a failure. No fixture network access.
"""

from __future__ import annotations

import argparse
import gzip
import json
import struct
import subprocess
import sys
import tempfile
import zipfile
import zlib
from pathlib import Path

import numpy as np
from scipy.io import mmread, mmwrite
from scipy.sparse import coo_matrix


def checked(command, *, fail=False):
    result = subprocess.run(
        [str(item) for item in command], capture_output=True, text=True, check=False
    )
    if (result.returncode == 0) == fail:
        raise AssertionError(
            f"command {' '.join(map(str, command))}: {result.stdout}{result.stderr}"
        )
    return result


def exact(actual, expected):
    assert actual.shape == expected.shape, (actual.shape, expected.shape)
    assert actual.dtype.kind == expected.dtype.kind
    assert actual.dtype.itemsize == expected.dtype.itemsize
    np.testing.assert_array_equal(actual, expected)
    # Numeric equality alone misses negative zero and NaN payload differences.
    native = expected.dtype.newbyteorder("<")
    assert actual.astype(native).tobytes() == expected.astype(native).tobytes()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--driver", required=True, type=Path)
    parser.add_argument("--require-optional", action="store_true")
    args = parser.parse_args()
    driver = args.driver.resolve()
    repository = Path(__file__).resolve().parents[1]
    adapters = repository / "tools" / "interchange_adapters.py"
    checks = 0
    with tempfile.TemporaryDirectory(prefix="hmath-interchange-") as temporary:
        root = Path(temporary)
        checked([driver, "selftest", root / "io"])
        export = root / "export"
        checked([driver, "export", export])
        expected = {
            "double_be_fortran": np.array(
                [[0, 1 / 3, -0.0], [1e-300, 1e300, -7]], dtype=">f8"
            ),
            "int64": np.array(
                [-(2**63), -9007199254740993, 0, 9007199254740993, 2**63 - 1],
                dtype="i8",
            ),
            "uint64": np.array([0, 9007199254740993, 2**64 - 1], dtype=">u8"),
            "float32": np.array([0, 1 / 3, -0.0, 1e-37], dtype="f4"),
            "complex128": np.array(
                [[1 + 2j, 3 - 4j], [complex(-0.0, 0), complex(1e300, 1e-300)]],
                dtype=">c16",
            ),
            "boolean": np.array([[True, False], [False, True]]),
            "empty": np.empty((2, 0, 3)),
            "scalar": np.array(42.0),
        }
        for name, array in expected.items():
            exact(np.load(export / f"{name}.npy", allow_pickle=False), array)
            checks += 1
        for archive_name in ("stored.npz", "compressed.npz"):
            if not (export / archive_name).exists():
                continue
            with np.load(export / archive_name, allow_pickle=False) as archive:
                assert set(archive.files) == set(expected)
                for name, array in expected.items():
                    exact(archive[name], array)
                    checks += 1
        # Test every supported dtype, both endians, each NPY version, shape
        # zero/scalar/matrix, and noncontiguous source views saved by NumPy.
        dtypes = [
            "?",
            "i1",
            "u1",
            "i2",
            "u2",
            "i4",
            "u4",
            "i8",
            "u8",
            "f4",
            "f8",
            "c8",
            "c16",
        ]
        arrays = {}
        for dtype in dtypes:
            for endian in ("<", ">"):
                dt = np.dtype(dtype).newbyteorder(endian)
                data = np.arange(24).astype(dt).reshape(4, 6)
                if dt.kind == "c":
                    data = np.asarray(data + 1j * (data + 0.5), dtype=dt)
                for array in {
                    "matrix": data,
                    "fortran": np.asfortranarray(data),
                    "negative_view": data[::-1, ::-2],
                    "broadcast": np.broadcast_to(data[0, 0], (2, 3)),
                    "empty": np.empty((2, 0, 3), dtype=dt),
                    "scalar": np.asarray(data[0, 0], dtype=dt),
                }.values():
                    for version in ((1, 0), (2, 0), (3, 0)):
                        source, output = root / "python.npy", root / "haskell.npy"
                        with source.open("wb") as handle:
                            np.lib.format.write_array(
                                handle, array, version=version, allow_pickle=False
                            )
                        checked([driver, "npy", source, output])
                        exact(np.load(output, allow_pickle=False), array)
                        checks += 1
                arrays[
                    f"type_{dtype.replace('?', 'bool')}_{'le' if endian == '<' else 'be'}"
                ] = data
        # Independent ZIP writers (NumPy uses ZIP64 local headers even for
        # small arrays); extra Unicode keys and empty archives included.
        arrays["unicode_λ"] = np.arange(10)[::-1]
        for save, name in (
            (np.savez, "python_stored"),
            (np.savez_compressed, "python_deflated"),
        ):
            archive = root / f"{name}.npz"
            save(archive, **arrays)
            output = root / name
            checked([driver, "npz", archive, output])
            for key, array in arrays.items():
                exact(np.load(output / f"{key}.npy", allow_pickle=False), array)
                checks += 1
        np.savez(root / "empty.npz")
        checked([driver, "npz", root / "empty.npz", root / "empty_archive"])
        checks += 1
        for path in export.glob("*.mtx"):
            actual = np.asarray(mmread(path))
            np.testing.assert_array_equal(actual, expected[path.stem])
            checks += 1
        matrices = {
            "real": np.array([[1.5, -2, 0], [0, 5, -7.25]], dtype=np.float64),
            "integer": np.array([[2**53 + 1, -2], [3, 2**63 - 1]], dtype=np.int64),
            "complex": np.array([[2 + 0j, 1 - 3j], [1 + 3j, 0]], dtype=np.complex128),
            "symmetric": np.array([[1.0, 2], [2, 3]]),
            "skew": np.array([[0.0, -2], [2, 0]]),
        }
        for name, matrix in matrices.items():
            for sparse in (False, True):
                source, output = root / "matrix.mtx", root / "matrix.npy"
                mmwrite(source, coo_matrix(matrix) if sparse else matrix)
                checked([driver, "mm", source, output])
                exact(np.load(output, allow_pickle=False), matrix)
                checks += 1
        payload = b"numerical interchange\n" * 1024
        for wrapper, compressor, decompressor in (
            (
                "raw",
                lambda b: zlib.compress(b, wbits=-15),
                lambda b: zlib.decompress(b, wbits=-15),
            ),
            ("zlib", zlib.compress, zlib.decompress),
            ("gzip", gzip.compress, gzip.decompress),
        ):
            encoded = export / f"{wrapper}.compressed"
            if not encoded.exists():
                continue
            assert decompressor(encoded.read_bytes()) == payload
            encoded.write_bytes(compressor(payload))
            decoded = root / "uncompressed"
            checked([driver, "inflate", wrapper, encoded, decoded])
            assert decoded.read_bytes() == payload
            encoded.write_bytes(encoded.read_bytes() + b"tail")
            checked([driver, "inflate", wrapper, encoded, decoded], fail=True)
            checks += 3
        # Malformed, truncated, pickle and inconsistent archive declarations.
        np.save(root / "object.npy", np.array([{"object": True}], dtype=object))
        checked([driver, "npy", root / "object.npy", root / "bad.npy"], fail=True)
        for sample in (b"", b"\x93NUMPY\x01\x00\xff\xff", b"PK\x03\x04" + b"\0" * 100):
            (root / "bad").write_bytes(sample)
            checked([driver, "npy", root / "bad", root / "bad.npy"], fail=True)
            checked([driver, "npz", root / "bad", root / "bad_archive"], fail=True)
            checks += 2
        with zipfile.ZipFile(root / "unsafe.npz", "w") as archive:
            archive.writestr("../escape.npy", (export / "scalar.npy").read_bytes())
        checked([driver, "npz", root / "unsafe.npz", root / "unsafe"], fail=True)
        with zipfile.ZipFile(root / "crc.npz", "w") as archive:
            archive.writestr("a.npy", (export / "scalar.npy").read_bytes())
        corrupt = bytearray((root / "crc.npz").read_bytes())
        local_payload = (
            30
            + struct.unpack_from("<H", corrupt, 26)[0]
            + struct.unpack_from("<H", corrupt, 28)[0]
        )
        corrupt[local_payload + 20] ^= 1
        (root / "crc.npz").write_bytes(corrupt)
        checked([driver, "npz", root / "crc.npz", root / "corrupt"], fail=True)
        checks += 3
        availability = json.loads(checked([sys.executable, adapters, "--probe"]).stdout)
        for adapter, present in availability.items():
            if not present:
                if args.require_optional:
                    raise AssertionError(
                        f"required optional {adapter} adapter unavailable"
                    )
                print(f"SKIP optional {adapter}: dependency not installed")
                continue
            for name, array in expected.items():
                if adapter == "arrow" and array.dtype.kind in "bc":
                    continue
                source, container, output = (
                    export / f"{name}.npy",
                    root / f"{adapter}.tensor",
                    root / "adapter.npy",
                )
                checked(
                    [
                        sys.executable,
                        adapters,
                        "--format",
                        adapter,
                        "--direction",
                        "export",
                        "--input",
                        source,
                        "--output",
                        container,
                    ]
                )
                checked(
                    [
                        sys.executable,
                        adapters,
                        "--format",
                        adapter,
                        "--direction",
                        "import",
                        "--input",
                        container,
                        "--output",
                        output,
                    ]
                )
                exact(np.load(output, allow_pickle=False), array)
                checks += 1
        if availability["hdf5"]:
            import h5py

            with h5py.File(root / "external.h5", "w") as handle:
                handle["tensor"] = h5py.ExternalLink("elsewhere.h5", "/tensor")
            checked(
                [
                    sys.executable,
                    adapters,
                    "--format",
                    "hdf5",
                    "--direction",
                    "import",
                    "--input",
                    root / "external.h5",
                    "--output",
                    root / "bad.npy",
                ],
                fail=True,
            )
            checks += 1
        if availability["onnx"]:
            import onnx

            tensor = onnx.TensorProto(
                name="tensor",
                dims=[1],
                data_type=onnx.TensorProto.DOUBLE,
                data_location=onnx.TensorProto.EXTERNAL,
            )
            tensor.external_data.add(key="location", value="elsewhere.bin")
            (root / "external.onnx").write_bytes(tensor.SerializeToString())
            checked(
                [
                    sys.executable,
                    adapters,
                    "--format",
                    "onnx",
                    "--direction",
                    "import",
                    "--input",
                    root / "external.onnx",
                    "--output",
                    root / "bad.npy",
                ],
                fail=True,
            )
            checks += 1
    print(
        f"{checks} independent interchange checks passed (NumPy {np.__version__}); optional={availability}"
    )


if __name__ == "__main__":
    main()
