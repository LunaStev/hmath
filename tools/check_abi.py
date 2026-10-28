# SPDX-License-Identifier: MPL-2.0
"""Check the public Linux symbol contract and SONAME without starting the RTS."""

import argparse
import re
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("library", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    expected = {
        line
        for line in (root / "test/abi-symbols.txt").read_text().splitlines()
        if line and not line.startswith("#")
    }
    dynamic = subprocess.check_output(["readelf", "-d", str(args.library)], text=True)
    if not re.search(r"\(SONAME\).*\[libhmath\.so\.1\]", dynamic):
        raise RuntimeError("C ABI epoch 1 requires SONAME libhmath.so.1")
    output = subprocess.check_output(
        ["nm", "-D", "--defined-only", str(args.library)], text=True
    )
    actual = {line.split()[-1] for line in output.splitlines() if line.split()}
    missing = expected - actual
    unexpected = {symbol for symbol in actual if symbol.startswith("hmath_")} - expected
    if missing or unexpected:
        raise RuntimeError(
            f"ABI symbol mismatch: missing={sorted(missing)}, unexpected={sorted(unexpected)}"
        )
    print(f"C ABI epoch 1: {len(expected)} public symbols and SONAME verified")


if __name__ == "__main__":
    main()
