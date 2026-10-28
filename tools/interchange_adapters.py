#!/usr/bin/env python3
# SPDX-License-Identifier: MPL-2.0
"""Optional, explicitly selected NPY <-> HDF5/Arrow IPC tensor/ONNX TensorProto.

The base library never imports these dependencies. `--probe` reports each
adapter's availability; selecting an absent dependency fails. Only fixed-width
numeric tensors are accepted. HDF5 uses one dataset named `tensor`; ONNX uses a
standalone TensorProto (not a graph/model). No external data/link is followed.
Primary API contracts: docs.h5py.org/high/dataset.html,
arrow.apache.org/docs/python/generated/pyarrow.ipc.write_tensor.html,
onnx.ai/onnx/api/numpy_helper.html.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path

MODULES = {"hdf5": "h5py", "arrow": "pyarrow", "onnx": "onnx"}
DTYPES = {"b1", "i1", "u1", "i2", "u2", "i4", "u4", "i8", "u8", "f4", "f8", "c8", "c16"}


def check_shape_dtype(shape, dtype, limit):
    if len(shape) > 16 or dtype.kind + str(dtype.itemsize) not in DTYPES:
        raise ValueError("unsupported rank or fixed-width numeric dtype")
    size = 1
    for dimension in shape:
        if not isinstance(dimension, int) or dimension < 0:
            raise ValueError("invalid shape")
        size *= dimension
    if size > 8 * 1024 * 1024 or size * dtype.itemsize > limit:
        raise ValueError("tensor exceeds element/byte limit")


def run(args):
    import numpy as np

    source, destination = Path(args.input), Path(args.output)
    if source.resolve() == destination.resolve():
        raise ValueError("input and output paths must differ")
    if args.max_bytes < 0 or source.stat().st_size > args.max_bytes:
        raise ValueError("input exceeds byte limit")
    if importlib.util.find_spec(MODULES[args.format]) is None:
        raise RuntimeError(f"optional dependency {MODULES[args.format]} is unavailable")
    if args.direction == "export":
        array = np.load(
            source, mmap_mode="r", allow_pickle=False, max_header_size=65536
        )
        check_shape_dtype(array.shape, array.dtype, args.max_bytes)
        if args.format == "hdf5":
            import h5py

            with h5py.File(destination, "w") as handle:
                handle.create_dataset("tensor", data=array)
        elif args.format == "arrow":
            import pyarrow as pa

            # Arrow tensor IPC does not currently represent boolean/complex.
            if array.dtype.kind in "bc":
                raise ValueError(
                    "Arrow tensor IPC supports integer and real dtypes here"
                )
            native = np.asarray(array, dtype=array.dtype.newbyteorder("="), order="C")
            with pa.OSFile(str(destination), "wb") as sink:
                pa.ipc.write_tensor(pa.Tensor.from_numpy(native), sink)
        else:
            from onnx import numpy_helper

            native = np.asarray(array, dtype=array.dtype.newbyteorder("="), order="C")
            destination.write_bytes(
                numpy_helper.from_array(native, name="tensor").SerializeToString()
            )
    else:
        if args.format == "hdf5":
            import h5py

            with h5py.File(source, "r") as handle:
                link = handle.get("tensor", getlink=True)
                if not isinstance(link, h5py.HardLink):
                    raise TypeError(
                        "only a local hard-linked tensor dataset is supported"
                    )
                dataset = handle["tensor"]
                if (
                    not isinstance(dataset, h5py.Dataset)
                    or dataset.is_virtual
                    or dataset.external
                ):
                    raise ValueError("external/virtual/non-dataset HDF5 object")
                check_shape_dtype(dataset.shape, dataset.dtype, args.max_bytes)
                array = dataset[()]
        elif args.format == "arrow":
            import pyarrow as pa

            # Copy before closing the mapping, so output owns its storage.
            with pa.memory_map(str(source), "r") as mapped:
                tensor = pa.ipc.read_tensor(mapped)
                array_view = tensor.to_numpy()
                check_shape_dtype(array_view.shape, array_view.dtype, args.max_bytes)
                array = np.array(array_view, copy=True)
        else:
            import onnx
            from onnx import numpy_helper

            tensor = onnx.TensorProto()
            tensor.ParseFromString(source.read_bytes())
            if (
                tensor.data_location == onnx.TensorProto.EXTERNAL
                or tensor.external_data
            ):
                raise ValueError("external ONNX tensor data is disabled")
            dtype = np.dtype(onnx.helper.tensor_dtype_to_np_dtype(tensor.data_type))
            check_shape_dtype(tuple(tensor.dims), dtype, args.max_bytes)
            array = numpy_helper.to_array(tensor)
        check_shape_dtype(array.shape, array.dtype, args.max_bytes)
        with destination.open("wb") as output:
            np.save(output, array, allow_pickle=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--probe", action="store_true")
    parser.add_argument("--format", choices=MODULES)
    parser.add_argument("--direction", choices=("import", "export"))
    parser.add_argument("--input")
    parser.add_argument("--output")
    parser.add_argument("--max-bytes", type=int, default=128 * 1024 * 1024)
    args = parser.parse_args()
    if args.probe:
        print(
            json.dumps(
                {
                    name: importlib.util.find_spec(module) is not None
                    for name, module in MODULES.items()
                },
                sort_keys=True,
            )
        )
        return 0
    if not all((args.format, args.direction, args.input, args.output)):
        parser.error("--format, --direction, --input and --output are required")
    try:
        run(args)
    except (OSError, ValueError, TypeError, RuntimeError, ImportError) as error:
        print(f"interchange adapter: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
