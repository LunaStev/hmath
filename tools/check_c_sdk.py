# SPDX-License-Identifier: MPL-2.0
"""Exercise a relocated C SDK in an environment without GHC or Python HMath."""

import argparse
import ctypes
import json
import os
import shlex
import subprocess
import tarfile
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="hmath-sdk-relocation-") as work:
        directory = Path(work)
        with tarfile.open(args.archive) as archive:
            archive.extractall(directory, filter="data")
        prefixes = list(directory.glob("hmath-*"))
        if len(prefixes) != 1:
            raise ValueError("expected exactly one SDK prefix")
        prefix = prefixes[0].rename(directory / "relocated prefix")
        metadata = json.loads((prefix / "manifest.json").read_text())
        library = ctypes.CDLL(str(prefix / "lib/libhmath.so.1"))
        library.hmath_library_version.restype = ctypes.c_char_p
        assert library.hmath_library_version().decode() == metadata["version"]
        assert library.hmath_abi_version() == metadata["abi"]
        env = {
            k: v
            for k, v in os.environ.items()
            if k not in ("LD_LIBRARY_PATH", "HMATH_LIBRARY", "PYTHONPATH")
        }
        env["PKG_CONFIG_PATH"] = str(prefix / "lib/pkgconfig")
        flags = shlex.split(
            subprocess.check_output(
                ["pkg-config", "--cflags", "--libs", "hmath"], env=env, text=True
            )
        )
        for compiler, standard, source in [
            ("cc", "c99", "numeric_contracts.c"),
            ("c++", "c++17", "numeric_contracts.cpp"),
            ("cc", "c99", "matrix_contracts.c"),
            ("cc", "c99", "autodiff_contracts.c"),
            ("cc", "c99", "execution_smoke.c"),
            ("cc", "c99", "header_c99.c"),
            ("c++", "c++17", "header_c99.c"),
            ("cc", "c99", "foundation_contracts.c"),
            ("cc", "c11", "numeric_objects_contracts.c"),
            ("c++", "c++17", "numeric_objects_contracts.cpp"),
            ("cc", "c99", "buffer_contracts.c"),
            ("c++", "c++17", "buffer_contracts.cpp"),
            ("cc", "c99", "tensor_contracts.c"),
            ("c++", "c++17", "tensor_contracts.cpp"),
            ("cc", "c99", "deeplearning_contracts.c"),
            ("c++", "c++17", "deeplearning_contracts.cpp"),
            ("cc", "c99", "autodiff_checked_contracts.c"),
            ("c++", "c++17", "autodiff_checked_contracts.cpp"),
            ("cc", "c99", "spectral_contracts.c"),
        ]:
            target = directory / ("consumer-" + Path(source).stem + "-" + standard)
            subprocess.run(
                [
                    compiler,
                    "-Wall",
                    "-Wextra",
                    "-Werror",
                    "-std=" + standard,
                    str(ROOT / "test/native" / source),
                    *flags,
                    "-Wl,-rpath," + str(prefix / "lib"),
                    "-o",
                    str(target),
                ],
                env=env,
                check=True,
            )
            subprocess.run([str(target)], env=env, check=True)
        consumer = directory / "cmake-consumer"
        consumer.mkdir()
        (consumer / "client.c").write_bytes(
            (ROOT / "test/native/numeric_contracts.c").read_bytes()
        )
        (consumer / "CMakeLists.txt").write_text(
            "cmake_minimum_required(VERSION 3.16)\nproject(sdk_consumer C)\n"
            "find_package(HMath 1.0 CONFIG REQUIRED)\nadd_executable(client client.c)\n"
            "target_link_libraries(client PRIVATE HMath::hmath)\n"
        )
        build = directory / "cmake-build"
        subprocess.run(
            [
                "cmake",
                "-S",
                str(consumer),
                "-B",
                str(build),
                "-DHMath_DIR=" + str(prefix / "lib/cmake/HMath"),
            ],
            env=env,
            check=True,
        )
        subprocess.run(["cmake", "--build", str(build)], env=env, check=True)
        subprocess.run([str(build / "client")], env=env, check=True)
        # Loading through the SDK must resolve bundled GHC libraries there.
        if Path("/proc/self/maps").exists():
            for line in Path("/proc/self/maps").read_text().splitlines():
                if "libHS" in line or "libhmath" in line:
                    assert str(prefix) in line, line
        print(
            "Relocated C/C++ SDK: installed headers, pkg-config, runtime dependencies PASS"
        )


if __name__ == "__main__":
    main()
