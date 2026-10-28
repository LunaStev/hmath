# SPDX-License-Identifier: MPL-2.0
"""Run IO and independent format checks using this Cabal build's driver."""

import argparse
import subprocess
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--builddir", type=Path, required=True)
    parser.add_argument("--require-optional", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    common = ["--builddir=" + str(args.builddir.resolve())]
    subprocess.run(
        ["cabal", "build", "exe:hmath-interchange-driver", *common],
        cwd=root,
        check=True,
    )
    driver = subprocess.check_output(
        ["cabal", "list-bin", "exe:hmath-interchange-driver", *common],
        cwd=root,
        text=True,
    ).strip()
    with tempfile.TemporaryDirectory(prefix="hmath-interchange-") as temporary:
        subprocess.run([driver, "selftest", temporary], check=True)
    differential = [
        "python3",
        str(root / "test/interchange_differential.py"),
        "--driver",
        driver,
    ]
    if args.require_optional:
        differential.append("--require-optional")
    subprocess.run(differential, check=True)


if __name__ == "__main__":
    main()
