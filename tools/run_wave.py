# SPDX-License-Identifier: MPL-2.0
"""Compile and run the official Wave smoke client against a built HMath library.

wavec 0.2.1-pre-beta or a compatible compiler is required. No compiler download
or installation is performed. The input library must match the host platform.
"""

import argparse
import os
import subprocess
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", type=Path, required=True)
    parser.add_argument("--compiler", default="wavec")
    args = parser.parse_args()
    library = args.library.resolve(strict=True)
    root = Path(__file__).resolve().parent.parent
    with tempfile.TemporaryDirectory(prefix="hmath-wave-") as temporary:
        directory = Path(temporary)
        executable = directory / ("smoke.exe" if os.name == "nt" else "smoke")
        command = [
            args.compiler,
            "build",
            str(root / "bindings/wave/smoke.wave"),
            "--emit=bin",
            "-L",
            str(library.parent),
            "--link=hmath",
            "--target-dir",
            str(directory / "objects"),
            "-o",
            str(executable),
        ]
        if os.name != "nt":
            command.extend(["-C", f"link-arg=-Wl,-rpath,{library.parent}"])
        subprocess.run(command, check=True, cwd=root, timeout=180)
        environment = os.environ.copy()
        if os.name == "nt":
            environment["PATH"] = (
                str(library.parent) + os.pathsep + environment.get("PATH", "")
            )
        subprocess.run([str(executable)], check=True, env=environment, timeout=60)
    print("Wave scalar, vector, matrix, tensor, errors and ownership checks passed")


if __name__ == "__main__":
    main()
