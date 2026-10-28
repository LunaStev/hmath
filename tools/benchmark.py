# SPDX-License-Identifier: MPL-2.0
"""Reproducible native/NumPy/SciPy/PyTorch measurements; never a correctness substitute."""

import argparse
import concurrent.futures
import csv
import ctypes as C
import hashlib
import html
import json
import math
import os
import platform
import statistics
import subprocess
import sys
import time
from pathlib import Path

THREAD_VARIABLES = (
    "OMP_NUM_THREADS",
    "OPENBLAS_NUM_THREADS",
    "MKL_NUM_THREADS",
    "BLIS_NUM_THREADS",
)
COMPARABLE_METADATA = (
    "machine",
    "system",
    "cpu",
    "ghc",
    "threads",
    "dtype",
    "backend",
    "build_info",
)


def parse_arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", required=True, type=Path)
    parser.add_argument("--native", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument("--threads", type=int, default=1)
    parser.add_argument("--compare", type=Path)
    parser.add_argument("--regression", type=float, default=0.2)
    parser.add_argument("--external", choices=["none", "numpy", "all"], default="numpy")
    args = parser.parse_args()
    if (
        not 1 <= args.iterations <= 1000000
        or not 1 <= args.threads <= 64
        or not 0 < args.regression <= 10
    ):
        parser.error("invalid iteration/thread/regression bounds")
    return args


def command_version(command):
    try:
        lines = subprocess.check_output(
            command, text=True, stderr=subprocess.STDOUT
        ).splitlines()
        return lines[0] if lines else None
    except (OSError, subprocess.CalledProcessError):
        return None


def sample(name, operation, validate, iterations, repeats=7):
    """Validate once, warm up, then retain every repeated-batch observation."""
    validate(operation())
    for _ in range(3):
        operation()
    measurements = []
    for _ in range(repeats):
        start = time.perf_counter_ns()
        for _ in range(iterations):
            result = operation()
        measurements.append((time.perf_counter_ns() - start) / 1e9 / iterations)
        validate(result)
    return {
        "name": name,
        "seconds": measurements,
        "median_seconds": statistics.median(measurements),
    }


def load_library(path):
    lib = C.CDLL(str(path))
    lib.hmath_init.restype = C.c_int
    lib.hmath_abi_version.restype = C.c_uint32
    lib.hmath_build_info.restype = C.c_char_p
    lib.hmath_backend_version.restype = C.c_char_p
    lib.hmath_library_version.restype = C.c_char_p
    lib.hmath_shutdown.restype = None
    lib.hmath_dot_f64.argtypes = [
        C.POINTER(C.c_double),
        C.POINTER(C.c_double),
        C.c_size_t,
    ]
    lib.hmath_dot_f64.restype = C.c_double
    if lib.hmath_abi_version() != 1:
        raise RuntimeError("unsupported HMath ABI")
    if lib.hmath_init() != 0:
        raise RuntimeError("HMath initialization failed")
    return lib


def build_metadata(args, library, lib):
    metadata = {
        "machine": platform.machine(),
        "system": platform.system(),
        "release": platform.release(),
        "cpu": platform.processor(),
        "python": platform.python_version(),
        "ghc": command_version(["ghc", "--numeric-version"]),
        "c_compiler": command_version(["cc", "--version"]),
        "library_version": lib.hmath_library_version().decode(),
        "library_sha256": hashlib.sha256(library.read_bytes()).hexdigest(),
        "build_info": lib.hmath_build_info().decode(),
        "backend": lib.hmath_backend_version().decode(),
        "threads": args.threads,
        "iterations": args.iterations,
        "dtype": "float64",
        "method": "monotonic wall clock; 3 warmups; 7 repeated batches; inputs allocated outside timed calls",
    }
    cpuinfo = Path("/proc/cpuinfo")
    if cpuinfo.exists():
        metadata["cpu"] = next(
            (
                line.split(":", 1)[1].strip()
                for line in cpuinfo.read_text().splitlines()
                if line.startswith("model name")
            ),
            metadata["cpu"],
        )
    # Meson installs the compiler/options record beside the versioned library.
    # Preserve it verbatim as evidence; do not infer flags from the current shell.
    manifest = library.parent / "hmath-build.json"
    if manifest.is_file():
        metadata["build_manifest"] = json.loads(manifest.read_text())
    return metadata


def native_cases(args):
    result = json.loads(
        subprocess.check_output(
            [str(args.native.resolve()), str(args.iterations)], text=True
        )
    )
    for case in result["cases"]:
        case["median_seconds"] = statistics.median(case["seconds"])
        case["source"] = (
            "C client; includes status validation overhead for checked calls"
        )
    return result["cases"]


def check_dot(value):
    value = float(value)
    if not math.isfinite(value) or abs(value - 1024) > 1e-10:
        raise RuntimeError("dot product reference mismatch")


def ctypes_cases(args, lib):
    data = (C.c_double * 1024)(*([1.0] * 1024))

    def dot():
        return lib.hmath_dot_f64(data, data, 1024)

    results = [sample("ctypes-dot-1024", dot, check_dot, args.iterations)]
    with concurrent.futures.ThreadPoolExecutor(args.threads) as pool:

        def parallel():
            return list(pool.map(lambda _: dot(), range(args.threads)))

        def check_parallel(values):
            if len(values) != args.threads:
                raise RuntimeError("thread result mismatch")
            for value in values:
                check_dot(value)

        results.append(
            sample(
                "ctypes-thread-batch-dot-1024",
                parallel,
                check_parallel,
                args.iterations,
            )
        )
    return results


def external_cases(args, metadata):
    if args.external == "none":
        return [], []
    import numpy as np

    metadata["numpy"] = np.__version__
    vector = np.ones(1024, dtype=np.float64)
    cases = [
        sample(
            "numpy-dot-1024",
            lambda: np.dot(vector, vector),
            check_dot,
            args.iterations,
        )
    ]
    skipped = []
    if args.external != "all":
        return cases, skipped
    try:
        import scipy
        from scipy.linalg.blas import ddot

        metadata["scipy"] = scipy.__version__
        cases.append(
            sample(
                "scipy-blas-dot-1024",
                lambda: ddot(vector, vector),
                check_dot,
                args.iterations,
            )
        )
    except ImportError:
        skipped.append("SciPy unavailable")
    try:
        import torch

        torch.set_num_threads(args.threads)
        metadata["torch"] = torch.__version__
        tensor = torch.ones(1024, dtype=torch.float64)
        cases.append(
            sample(
                "torch-cpu-dot-1024",
                lambda: torch.dot(tensor, tensor).item(),
                check_dot,
                args.iterations,
            )
        )
    except ImportError:
        skipped.append("PyTorch unavailable")
    return cases, skipped


def compare_baseline(report, path, threshold):
    baseline = json.loads(path.read_text())
    for key in COMPARABLE_METADATA:
        if baseline["metadata"].get(key) != report["metadata"].get(key):
            raise RuntimeError("incomparable baseline configuration: " + key)
    old_cases = {case["name"]: case for case in baseline["cases"]}
    regressions = []
    for case in report["cases"]:
        previous = old_cases.get(case["name"])
        if previous is None:
            continue
        ratio = case["median_seconds"] / previous["median_seconds"]
        case["baseline_ratio"] = ratio
        # Require a practical slowdown and nonoverlapping interquartile ranges.
        before = statistics.quantiles(previous["seconds"], n=4)
        after = statistics.quantiles(case["seconds"], n=4)
        if ratio > 1 + threshold and after[0] > before[2]:
            regressions.append(case["name"])
    return regressions


def median_chart(cases):
    """An inline, dependency-free SVG using a shared linear microsecond scale."""
    left, chart_width, row_height = 365, 490, 30
    height = 65 + row_height * len(cases)
    maximum = max((case["median_seconds"] * 1e6 for case in cases), default=1)
    maximum = max(maximum, 1e-9)
    elements = [
        f'<svg viewBox="0 0 1000 {height}" role="img" aria-labelledby="median-title median-description">',
        '<title id="median-title">Median time per operation</title>',
        '<desc id="median-description">Horizontal bars share a linear microsecond scale. Lower values are faster; workloads and call overhead differ.</desc>',
    ]
    for tick in range(5):
        x = left + chart_width * tick / 4
        elements.extend(
            [
                f'<line x1="{x}" y1="28" x2="{x}" y2="{height - 24}" stroke="#e5e7eb"/>',
                f'<text x="{x}" y="18" text-anchor="middle" fill="#555">{maximum * tick / 4:.3g}</text>',
            ]
        )
    for index, case in enumerate(cases):
        y = 38 + index * row_height
        microseconds = case["median_seconds"] * 1e6
        width = chart_width * microseconds / maximum
        label = html.escape(case["name"])
        elements.extend(
            [
                f'<text x="8" y="{y + 14}" fill="#111">{label}</text>',
                f'<rect x="{left}" y="{y}" width="{width:.3f}" height="20" rx="3" fill="#2563eb"><title>{label}: {microseconds:.6g} µs</title></rect>',
                f'<text x="{left + width + 8:.3f}" y="{y + 14}" fill="#111">{microseconds:.3g} µs</text>',
            ]
        )
    elements.append("</svg>")
    return "\n".join(elements)


def write_report(report, output):
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n")
    with output.with_suffix(".csv").open("w", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(["case", "sample", "seconds", "median_seconds"])
        for case in report["cases"]:
            for index, value in enumerate(case["seconds"]):
                writer.writerow([case["name"], index, value, case["median_seconds"]])
    rows = "".join(
        f"<tr><td>{html.escape(case['name'])}</td><td>{case['median_seconds'] * 1e6:.3f}</td></tr>"
        for case in report["cases"]
    )
    output.with_suffix(".html").write_text(
        '<!doctype html><meta charset="utf-8"><title>HMath benchmark</title>'
        "<style>body{font:15px system-ui;margin:2rem auto;max-width:1100px;padding:0 1rem}"
        "svg{width:100%;height:auto;font:12px ui-monospace,monospace}"
        "table{border-collapse:collapse}td,th{padding:.4rem 1rem;border-bottom:1px solid #ddd;text-align:left}"
        "pre{white-space:pre-wrap;overflow-wrap:anywhere}</style>"
        "<h1>HMath benchmark</h1>"
        "<p>Median microseconds per operation; compare only equivalent workloads and call overhead. Lower is faster.</p>"
        + median_chart(report["cases"])
        + "<table><tr><th>Case</th><th>µs</th></tr>"
        + rows
        + "</table><h2>Build and measurement metadata</h2><pre>"
        + html.escape(json.dumps(report["metadata"], indent=2))
        + "</pre>"
    )


def main():
    args = parse_arguments()
    # Thread policy is set before loading either native or Python numerical code.
    for variable in THREAD_VARIABLES:
        os.environ[variable] = str(args.threads)
    library = args.library.resolve(strict=True)
    lib = load_library(library)
    try:
        metadata = build_metadata(args, library, lib)
        cases = native_cases(args) + ctypes_cases(args, lib)
        external, skipped = external_cases(args, metadata)
        cases.extend(external)
    finally:
        lib.hmath_shutdown()
    report = {"schema": 1, "metadata": metadata, "cases": cases, "skipped": skipped}
    regressions = []
    if args.compare:
        regressions = compare_baseline(report, args.compare, args.regression)
        report["regressions"] = regressions
    write_report(report, args.output)
    print(
        json.dumps(
            {"cases": len(cases), "skipped": skipped, "regressions": regressions}
        )
    )
    if regressions:
        sys.exit(1)


if __name__ == "__main__":
    main()
