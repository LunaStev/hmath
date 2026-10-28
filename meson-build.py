# SPDX-License-Identifier: MPL-2.0
"""Build the exact Cabal component selected by this Meson configuration."""

import argparse
import json
import os
import re
import shutil
import subprocess
from pathlib import Path


def cabal_arguments(args):
    optimization = {"debug": "0", "debugoptimized": "2", "release": "2", "minsize": "1"}
    flags = [
        f"--builddir={args.builddir}",
        f"--enable-optimization={optimization[args.buildtype]}",
    ]
    flags += [
        "--enable-debug-info=2"
        if args.buildtype != "release"
        else "--disable-debug-info"
    ]
    flags += [
        "-finterchange-zlib" if args.compression == "enabled" else "-f-interchange-zlib"
    ]
    flags += [
        "-fnative-backend" if args.native_backend == "enabled" else "-f-native-backend"
    ]
    if args.werror:
        flags += ["--ghc-options=-Wall -Werror"]
    if args.offline:
        flags += ["--offline"]
    if args.ghc:
        flags += [f"--with-compiler={args.ghc}"]
    return flags


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("outputs", nargs="*", type=Path)
    parser.add_argument("--builddir", required=True, type=Path)
    parser.add_argument(
        "--buildtype",
        choices=["debug", "debugoptimized", "release", "minsize"],
        default="release",
    )
    parser.add_argument(
        "--compression", choices=["enabled", "disabled"], default="enabled"
    )
    parser.add_argument(
        "--native-backend", choices=["enabled", "disabled"], default="enabled"
    )
    parser.add_argument("--cabal", default="cabal")
    parser.add_argument("--ghc", default="")
    parser.add_argument("--werror", action="store_true")
    parser.add_argument("--offline", action="store_true")
    parser.add_argument("--test", action="store_true")
    args = parser.parse_args()
    root = args.root.resolve()
    args.builddir = args.builddir.resolve()
    common = cabal_arguments(args)
    if args.test:
        subprocess.run(
            [args.cabal, "test", "hmath-tests", *common, "--test-show-details=direct"],
            cwd=root,
            check=True,
        )
        return
    if not args.outputs:
        parser.error("at least one output is required")
    subprocess.run([args.cabal, "build", "flib:hmath", *common], cwd=root, check=True)
    # list-bin identifies this build plan's component, never the newest glob match.
    raw = subprocess.check_output(
        [args.cabal, "list-bin", "flib:hmath", *common], cwd=root, text=True
    )
    library = Path(raw.strip())
    if not library.exists() and library.name.endswith(".so"):
        # Cabal list-bin can name the unversioned symlink before installation.
        # Derive the one exact libtool filename from the declared ABI tuple.
        match = re.search(
            r"^\s*lib-version-info:\s*(\d+):(\d+):(\d+)\s*$",
            (root / "hmath.cabal").read_text(),
            re.MULTILINE,
        )
        if match:
            current, revision, age = map(int, match.groups())
            library = library.with_name(
                library.name + f".{current - age}.{age}.{revision}"
            )
    library = library.resolve(strict=True)
    for output in args.outputs:
        output = output.resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(library, output)
    metadata = {
        "schema": 1,
        "library": library.name,
        "buildtype": args.buildtype,
        "compiler": subprocess.check_output(
            [args.ghc or "ghc", "--numeric-version"], text=True
        ).strip(),
        "cabal_arguments": common,
        "compression": args.compression,
        "source_date_epoch": os.environ.get("SOURCE_DATE_EPOCH"),
    }
    (args.builddir.parent / "hmath-build.json").write_text(
        json.dumps(metadata, indent=2) + "\n"
    )
    print("HMath shared library:", library)


if __name__ == "__main__":
    main()
