# SPDX-License-Identifier: MPL-2.0
"""Check source-derived public API inventories against their reference entries."""

import argparse
import ast
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROTOCOLS = {"__add__", "__matmul__", "__enter__", "__exit__", "__del__"}


def python_exports(path, module):
    """Inventory definitions rather than incidental imported stdlib names."""
    tree = ast.parse(path.read_text())
    names = set()
    for node in tree.body:
        if isinstance(
            node, (ast.FunctionDef, ast.ClassDef)
        ) and not node.name.startswith("_"):
            name = f"{module}.{node.name}"
            names.add(name)
            if isinstance(node, ast.ClassDef):
                for member in node.body:
                    if isinstance(member, ast.FunctionDef) and (
                        not member.name.startswith("_") or member.name in PROTOCOLS
                    ):
                        names.add(f"{name}.{member.name}")
    return names


def check_entries(names, page, pattern):
    text = page.read_text()
    sections = re.split(r"(?=^### )", text, flags=re.MULTILINE)
    covered = {}
    for section in sections:
        match = re.match(pattern, section)
        if match:
            covered[match[1]] = section
    missing = names - covered.keys()
    if missing:
        raise ValueError(f"{page}: missing entries: {', '.join(sorted(missing))}")
    for name in sorted(names):
        section = covered[name]
        if "**Parameters:**" not in section or "**Returns:**" not in section:
            raise ValueError(f"{page}: {name} lacks parameter/return contracts")
    return len(names)


def read_haddock(interface):
    result = subprocess.run(
        ["haddock", "--show-interface", str(interface)],
        check=True,
        capture_output=True,
        text=True,
    )
    # Haddock currently writes this JSON to stderr, despite a successful exit.
    return json.loads(result.stdout.strip() or result.stderr.strip())


def check_haskell(data):
    public = {
        name
        for module in data["inst_ifaces"]
        for name in module["visible_exports"]
        if name.startswith("$hmath-") and name.rsplit("$", 1)[1][0].islower()
    }
    documented = {
        name
        for module in data["inst_ifaces"]
        for name, prose in module["doc_map"].items()
        if prose
    }
    public_types = set()
    for module in data["inst_ifaces"]:
        name = module["module"].split("$")[-1]
        source = ROOT / "src" / Path(*name.split(".")).with_suffix(".hs")
        if not source.is_file():
            continue
        declarations = re.findall(
            r"^(?:data|newtype|type|class)\s+(?:\([^\n]*?\)\s*=>\s*)?([A-Z]\w*)",
            source.read_text(),
            re.MULTILINE,
        )
        for declaration in declarations:
            symbol = module["module"] + "$" + declaration
            if symbol in module["visible_exports"]:
                public_types.add(symbol)
    missing = sorted(public - documented)
    if missing:
        labels = [".".join(name.split("$")[-2:]) for name in missing]
        raise ValueError(
            "Haskell public functions/methods/fields without prose:\n"
            + "\n".join(labels)
        )
    missing_types = sorted(public_types - documented)
    if missing_types:
        labels = [".".join(name.split("$")[-2:]) for name in missing_types]
        raise ValueError("Haskell public types without prose:\n" + "\n".join(labels))
    return len(public), len(public_types)


def check_reference(interface=None):
    python = set()
    for module in ("hmath", "hmath_cffi"):
        python |= python_exports(ROOT / "bindings/python" / f"{module}.py", module)
    counts = {
        "Python": check_entries(
            python, ROOT / "docs/reference/python.md", r"### `(hmath(?:_cffi)?\.[\w.]+)"
        )
    }
    c = set()
    for header in ("hmath.h", "hmath_dlpack.h"):
        c.update(
            re.findall(
                r"^HMATH_API\s+[\w\s*]+?\b(hmath_\w+)\s*\([^;]*\);",
                (ROOT / "include" / header).read_text(),
                re.MULTILINE,
            )
        )
    counts["C"] = check_entries(c, ROOT / "docs/reference/c.md", r"### `(hmath_\w+)`")
    wave = set(
        re.findall(
            r"^pub fun (\w+)\(",
            (ROOT / "bindings/wave/hmath.wave").read_text(),
            re.MULTILINE,
        )
    )
    counts["Wave"] = check_entries(
        wave, ROOT / "docs/reference/wave.md", r"### `(\w+)\("
    )
    if interface:
        functions, types = check_haskell(read_haddock(interface))
        counts["Haskell functions, methods and fields"] = functions
        counts["Haskell types"] = types
    print(
        "API reference coverage: "
        + "; ".join(f"{key}: {count}" for key, count in counts.items())
    )
    return counts


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--haddock-interface", type=Path)
    args = parser.parse_args()
    check_reference(args.haddock_interface)
