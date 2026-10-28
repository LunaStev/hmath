# SPDX-License-Identifier: MPL-2.0
"""Build the documentation site and its generated Haskell API reference."""

import json
import shutil
import subprocess
import sys
from pathlib import Path

import tomllib
import yaml
from check_api_docs import check_reference, read_haddock
from haskell_reference import generate_reference, repair_module_anchors

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
interface = reference / "hmath.haddock"
check_reference(interface)
subprocess.run(
    [sys.executable, "tools/check_haskell_doc_examples.py"], cwd=root, check=True
)
staging = root / "build-docs/site-src"
if staging.exists():
    shutil.rmtree(staging)
shutil.copytree(root / "docs", staging)
version = tomllib.loads((root / "pyproject.toml").read_text())["project"]["version"]
for page in staging.rglob("*.md"):
    page.write_text(page.read_text().replace("@HMATH_VERSION@", version))
config = yaml.safe_load((root / "mkdocs.yml").read_text())
config["docs_dir"] = str(staging)
config["site_dir"] = str(root / "site")
html_pages = repair_module_anchors(reference)
navigation = generate_reference(reference, staging, read_haddock(interface), html_pages)
for section in config["nav"]:
    for item in section.get("API Reference", []):
        if "Haskell API" in item:
            item["Haskell API"] = navigation
config_path = root / "build-docs/mkdocs.generated.yml"
config_path.write_text(yaml.safe_dump(config, sort_keys=False))
subprocess.run(
    [
        sys.executable,
        "-m",
        "mkdocs",
        "build",
        "--strict",
        "--config-file",
        str(config_path),
    ],
    cwd=root,
    check=True,
)
shutil.copytree(reference, root / "site/haskell", dirs_exist_ok=True)
for name, content in html_pages.items():
    (root / "site/haskell" / name).write_text(content)
subprocess.run([sys.executable, "tools/check_docs_links.py"], cwd=root, check=True)
