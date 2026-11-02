# SPDX-License-Identifier: MPL-2.0
"""Read the project version once and reject inconsistent release metadata."""

import re
from pathlib import Path

import tomllib

ROOT = Path(__file__).resolve().parent.parent


def release_version():
    version = tomllib.loads((ROOT / "pyproject.toml").read_text())["project"]["version"]
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise ValueError("release version must have major.minor.patch components")
    checks = {
        "hmath.cabal": r"^version:\s*([\d.]+)\s*$",
        "meson.build": r"project\('hmath', 'c', version: '([^']+)'",
        "cbits/native.c": r'hmath_library_version\(void\)\s*\{\s*return "([^\"]+)";',
    }
    for name, pattern in checks.items():
        match = re.search(pattern, (ROOT / name).read_text(), re.MULTILINE)
        if not match or match[1] != version:
            raise ValueError(f"{name}: version differs from pyproject.toml ({version})")
    return version


if __name__ == "__main__":
    print(release_version())
