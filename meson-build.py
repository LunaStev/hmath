# SPDX-License-Identifier: MPL-2.0

import shutil
import subprocess
import sys
from pathlib import Path


def main():
    root = Path(sys.argv[1]).resolve()
    output = Path(sys.argv[2]).resolve()

    subprocess.run(
        ["cabal", "build", "flib:hmath"],
        cwd=root,
        check=True,
    )

    candidates = list(
        (root / "dist-newstyle" / "build").glob(
            "*/ghc-*/hmath-*/f/hmath/*/build/hmath/libhmath.so"
        )
    )

    if not candidates:
        raise RuntimeError("libhmath.so not found")

    library = max(candidates, key=lambda path: path.stat().st_mtime_ns)

    output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(library, output)

    print(f"HMath shared library: {output}")


if __name__ == "__main__":
    main()
