# SPDX-License-Identifier: MPL-2.0
"""Build platform wheels containing the Python-independent HMath C ABI."""

import os
import shutil
import subprocess
import sys
from pathlib import Path

from setuptools import Distribution, setup
from setuptools.command.bdist_wheel import bdist_wheel
from setuptools.command.build_py import build_py


class NativeBuild(build_py):
    def run(self):
        super().run()
        library = os.environ.get("HMATH_BUILD_LIBRARY")
        if library:
            library = Path(library).resolve(strict=True)
        else:
            if not shutil.which("ghc") or not shutil.which("cabal"):
                raise RuntimeError(
                    "Building HMath from source requires GHC and Cabal. "
                    "Use a binary wheel on supported Linux x86-64 systems."
                )
            root = Path(__file__).parent.resolve()
            work = Path(self.build_lib).resolve().parent / "hmath-native"
            library = work / "libhmath.so"
            subprocess.run(
                [
                    sys.executable,
                    str(root / "meson-build.py"),
                    str(root),
                    str(library),
                    "--builddir",
                    str(work / "cabal"),
                    "--offline",
                ],
                check=True,
            )
        destination = Path(self.build_lib) / "_hmath_native" / "libhmath.so"
        shutil.copy2(library, destination)


class NativeWheel(bdist_wheel):
    def finalize_options(self):
        super().finalize_options()
        self.root_is_pure = False

    def get_tag(self):
        # ctypes uses the C ABI: one wheel works across Python versions.
        _, _, platform = super().get_tag()
        return "py3", "none", platform


class NativeDistribution(Distribution):
    def has_ext_modules(self):
        # Install the bundled shared library into platlib, never purelib.
        return True


setup(
    distclass=NativeDistribution,
    cmdclass={"build_py": NativeBuild, "bdist_wheel": NativeWheel},
)
