# SPDX-License-Identifier: MPL-2.0
"""Build the documentation site and its generated Haskell API reference."""

import json
import shutil
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
subprocess.run(
    [
        "cabal",
        "haddock",
        "lib:hmath",
        "--offline",
        "--haddock-html",
        "--haddock-hyperlink-source",
        "--haddock-quickjump",
        "--haddock-html-location=https://hackage.haskell.org/package/$pkg-$version/docs",
        "--haddock-option=--show=HMath.Geometry.Internal",
        "--haddock-option=--show=HMath.Image.Core",
        "--haddock-option=--show=HMath.MachineLearning.Internal",
        "--haddock-option=--show=HMath.TimeSeries.Core",
        "--builddir=build-docs/cabal",
    ],
    cwd=root,
    check=True,
)
plan = json.loads((root / "build-docs/cabal/cache/plan.json").read_text())
component = next(
    unit
    for unit in plan["install-plan"]
    if unit.get("pkg-name") == "hmath" and unit.get("component-name") == "lib"
)
reference = Path(component["dist-dir"]) / "doc/html/hmath"
if not (reference / "index.html").is_file():
    raise SystemExit(f"Haddock reference not found: {reference}")
subprocess.run(
    [sys.executable, "-m", "mkdocs", "build", "--strict"], cwd=root, check=True
)
shutil.copytree(reference, root / "site/haskell", dirs_exist_ok=True)
