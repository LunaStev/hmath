# SPDX-License-Identifier: MPL-2.0
"""Exercise installed C99/C11 clients and package discovery in a disposable prefix."""

import argparse
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def run(command, **kwargs):
    subprocess.run(command, check=True, **kwargs)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("builddir", type=Path)
    a = p.parse_args()
    root = Path(__file__).resolve().parent.parent
    build = a.builddir.resolve()
    with tempfile.TemporaryDirectory(prefix="hmath-install-") as temporary:
        stage = Path(temporary) / "stage"
        run(["meson", "install", "-C", str(build), "--destdir", str(stage)])
        pcs = list(stage.rglob("hmath.pc"))
        if len(pcs) != 1:
            raise RuntimeError("expected exactly one installed hmath.pc")
        pc = pcs[0]
        env = os.environ.copy()
        env["PKG_CONFIG_PATH"] = str(pc.parent)
        flags = shlex.split(
            subprocess.check_output(
                ["pkg-config", "--cflags", "--libs", "hmath"], env=env, text=True
            )
        )
        libdir = Path(
            subprocess.check_output(
                ["pkg-config", "--variable=libdir", "hmath"], env=env, text=True
            ).strip()
        )
        env["LD_LIBRARY_PATH"] = (
            str(libdir) + os.pathsep + env.get("LD_LIBRARY_PATH", "")
        )
        env["DYLD_LIBRARY_PATH"] = (
            str(libdir) + os.pathsep + env.get("DYLD_LIBRARY_PATH", "")
        )
        for compiler, standard in [("cc", "c99"), ("cc", "c11")]:
            target = Path(temporary) / ("client-" + standard)
            source = root / "test/install/client.c"
            run(
                [
                    compiler,
                    "-Wall",
                    "-Wextra",
                    "-Werror",
                    "-std=" + standard,
                    str(source),
                    *flags,
                    "-o",
                    str(target),
                ],
                env=env,
            )
            run([str(target)], env=env)
        config = next(stage.rglob("HMathConfig.cmake"))
        cmake_build = Path(temporary) / "cmake"
        run(
            [
                "cmake",
                "-S",
                str(root / "test/install"),
                "-B",
                str(cmake_build),
                "-DHMath_DIR=" + str(config.parent),
            ]
        )
        run(["cmake", "--build", str(cmake_build)])
        run([str(cmake_build / "client")], env=env)
        # Exercise language clients against the staged installation, rather than
        # accidentally resolving the uninstalled copy in the build directory.
        library = libdir / "libhmath.so"
        env["HMATH_LIBRARY"] = str(library)
        env["PYTHONPATH"] = str(root / "bindings/python")
        run(
            [
                sys.executable,
                "-c",
                (
                    "import hmath; assert hmath.add(2, 3) == 5; "
                    "t = hmath.Tensor([1, 2, 3]); assert t.dot(t) == 14; t.close()"
                ),
            ],
            env=env,
            cwd=temporary,
        )
        wavec = shutil.which("wavec")
        if wavec:
            run(
                [
                    sys.executable,
                    str(root / "tools/run_wave.py"),
                    "--library",
                    str(library),
                    "--compiler",
                    wavec,
                ],
                env=env,
            )
        run(
            ["ninja", "-C", str(build), "uninstall"],
            env={**os.environ, "DESTDIR": str(stage)},
        )
        remaining = [x for x in stage.rglob("*") if x.is_file() or x.is_symlink()]
        if remaining:
            raise RuntimeError("uninstall left files: " + repr(remaining))
    print("Installed C99/C11 clients, pkg-config, CMake and uninstall: PASS")


if __name__ == "__main__":
    main()
