# SPDX-License-Identifier: MPL-2.0
"""Audit public Haskell symbols and concrete C/Python specializations.

Missing bindings remain visible; an implemented specialization does not mean
all instances of a polymorphic Haskell function have been exposed.
"""

import argparse
import ast
import json
import re
from pathlib import Path

from check_api_docs import read_haddock
from generate_numeric_bindings import namespace, prefix
from numeric_specializations import binding_variants

ROOT = Path(__file__).resolve().parent.parent


def python_members(module, seen=None):
    """Inspect declarations without importing a native library during preflight."""
    seen = set() if seen is None else seen
    if module in seen:
        return set()
    seen.add(module)
    path = ROOT / "bindings/python/_hmath_native" / (module + ".py")
    if not path.is_file():
        return set()
    names = set()
    for node in ast.parse(path.read_text()).body:
        if isinstance(node, ast.Assign):
            names.update(t.id for t in node.targets if isinstance(t, ast.Name))
        elif isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name):
            names.add(node.target.id)
        elif isinstance(node, (ast.FunctionDef, ast.ClassDef)):
            names.add(node.name)
            if isinstance(node, ast.ClassDef):
                for member in node.body:
                    if isinstance(member, ast.FunctionDef):
                        names.add(node.name + "." + member.name)
                    elif isinstance(member, ast.Assign):
                        names.update(
                            node.name + "." + t.id
                            for t in member.targets
                            if isinstance(t, ast.Name)
                        )
                    elif isinstance(member, ast.AnnAssign) and isinstance(
                        member.target, ast.Name
                    ):
                        names.add(node.name + "." + member.target.id)
        elif isinstance(node, ast.ImportFrom) and node.level == 1 and node.module:
            imported = python_members(node.module, seen)
            for alias in node.names:
                if alias.name == "*":
                    names.update(imported)
                else:
                    target = alias.asname or alias.name
                    names.add(target)
                    names.update(
                        target + item[len(alias.name) :]
                        for item in imported
                        if item.startswith(alias.name + ".")
                    )
    return names


def validate_targets(bound):
    headers = "\n".join(p.read_text() for p in (ROOT / "include").glob("hmath*.h"))
    c_names = set(re.findall(r"\b(?:hmath_\w+|HMATH_\w+)\b", headers))
    python_cache = {}
    public_modules = {}
    for node in ast.parse((ROOT / "bindings/python/hmath.py").read_text()).body:
        if isinstance(node, ast.ImportFrom) and node.module == "_hmath_native":
            public_modules.update(
                (alias.asname or alias.name, alias.name) for alias in node.names
            )
    for symbol, item in bound.items():
        if (
            not item.get("c")
            or not item.get("python")
            or not item.get("specializations")
        ):
            raise ValueError(f"Incomplete binding mapping: {symbol}")
        if not set(item["c"]) <= c_names:
            raise ValueError(f"Unknown C binding declaration: {symbol}")
        for target in [item["python"], *item.get("python_aliases", [])]:
            parts = target.split(".", 2)
            if len(parts) != 3 or parts[0] != "hmath":
                raise ValueError(f"Invalid Python binding path: {symbol}")
            if parts[1] not in python_cache:
                module = public_modules.get(parts[1], parts[1])
                python_cache[parts[1]] = python_members(module)
            if parts[2] not in python_cache[parts[1]]:
                raise ValueError(
                    f"Unknown Python binding declaration: {symbol}: {target}"
                )


def object_bindings(bound, known, directory):
    """Merge only explicitly declared extensions of an existing schema file."""
    mappings = {
        p.name: json.loads(p.read_text()) for p in directory.glob("*objects.json")
    }
    loaded = {"numeric.json"}
    owners = {symbol: "numeric.json" for symbol in bound}
    while mappings:
        progress = False
        for name, mapping in list(mappings.items()):
            parent = mapping.get("extends")
            if parent and parent not in loaded:
                continue
            seen = set()
            for item in mapping["bindings"]:
                symbol = item["symbol"]
                if symbol not in known or symbol in seen:
                    raise ValueError(f"Unknown or duplicate object binding: {symbol}")
                seen.add(symbol)
                target = {key: value for key, value in item.items() if key != "symbol"}
                if parent:
                    if symbol not in bound or owners.get(symbol) != parent:
                        raise ValueError(
                            f"Extension {name} has no base binding in {parent}: {symbol}"
                        )
                    base = bound[symbol]
                    for field in ("c", "specializations"):
                        base[field] = list(dict.fromkeys(base[field] + target[field]))
                    if target["python"] != base["python"]:
                        aliases = base.setdefault("python_aliases", [])
                        if target["python"] not in aliases:
                            aliases.append(target["python"])
                else:
                    if symbol in bound:
                        raise ValueError(
                            f"Duplicate object binding without declared extension: {symbol}"
                        )
                    bound[symbol] = target
                    owners[symbol] = name
            loaded.add(name)
            del mappings[name]
            progress = True
        if not progress:
            raise ValueError(
                "Missing or cyclic object schema extensions: "
                + ", ".join(sorted(mappings))
            )


def additional_specializations(bound, directory):
    """Validate additive instance paths without counting another source symbol."""
    for path in directory.glob("*-specializations.json"):
        seen = set()
        for item in json.loads(path.read_text())["additional_specializations"]:
            symbol = item["symbol"]
            if symbol not in bound or symbol in seen:
                raise ValueError(f"Unknown or duplicate specialization: {symbol}")
            seen.add(symbol)
            base = bound[symbol]
            if item["additional_c"] in base["c"] or not item["instances"]:
                raise ValueError(f"Invalid additional specialization: {symbol}")
            base["c"].append(item["additional_c"])
            base["specializations"].append(item["instances"])
            target = "hmath." + item["python"].removeprefix("hmath.")
            if target != base["python"]:
                aliases = base.setdefault("python_aliases", [])
                if target not in aliases:
                    aliases.append(target)


def inventory(interface):
    # Haddock builds private pages to resolve links. Those helpers are not public
    # unless an exposed module actually re-exports them. Keep their canonical
    # defining names when they are re-exported, rather than dropping Internal.*.
    stanza = re.search(
        r"^library\s*\n.*?^\s+exposed-modules:(.*?)^\s+other-modules:",
        (ROOT / "hmath.cabal").read_text(),
        re.MULTILINE | re.DOTALL,
    )
    if not stanza:
        raise ValueError("cannot find the library's exposed module declarations")
    exposed = set(re.findall(r"\bHMath(?:\.\w+)*\b", stanza[1]))
    symbols = {}
    for module in read_haddock(interface)["inst_ifaces"]:
        if module["module"].split("$")[-1] not in exposed:
            continue
        for symbol in module["visible_exports"]:
            if not symbol.startswith("$hmath-"):
                continue
            _, _, defining_module, name = symbol.split("$", 3)
            key = defining_module + "." + name
            item = symbols.setdefault(
                key,
                {
                    "symbol": key,
                    "kind": "type-or-constructor"
                    if name[0].isupper() or name.startswith(":")
                    else "function-or-field",
                    "exported_from": [],
                },
            )
            item["exported_from"].append(module["module"].split("$")[-1])
    return sorted(symbols.values(), key=lambda item: item["symbol"])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--interface", type=Path)
    parser.add_argument("--update-inventory", action="store_true")
    parser.add_argument("--report", type=Path)
    parser.add_argument(
        "--require-complete",
        action="store_true",
        help="Fail release preparation while public symbols remain unmapped",
    )
    args = parser.parse_args()
    if args.require_complete and not args.interface:
        parser.error("--require-complete requires a freshly built --interface")
    path = ROOT / "bindings/schema/public-api.json"
    declared = json.loads(path.read_text())
    if args.interface:
        actual = inventory(args.interface)
        if args.update_inventory:
            declared["symbols"] = actual
            path.write_text(json.dumps(declared, indent=2) + "\n")
        elif actual != declared["symbols"]:
            parser.exit(1, "Haskell public inventory changed; audit and update it.\n")
    elif args.update_inventory:
        parser.error("--update-inventory requires --interface")
    known = {entry["symbol"] for entry in declared["symbols"]}
    bound = {}
    functions = json.loads((ROOT / "bindings/schema/numeric.json").read_text())[
        "functions"
    ]
    for function in functions:
        symbol = function["module"] + "." + function["name"]
        if symbol not in known or symbol in bound:
            raise ValueError(f"Unknown or duplicate binding: {symbol}")
        variants = binding_variants(function)
        bound[symbol] = {
            "specializations": [v["dtype"] or "exact" for v in variants],
            "c": [prefix(function) + v["suffix"] for v in variants],
            "python": "hmath." + namespace(function) + "." + function["python"],
        }
    object_bindings(bound, known, ROOT / "bindings/schema")
    additional_specializations(bound, ROOT / "bindings/schema")
    validate_targets(bound)
    report = {
        entry["symbol"]: bound.get(entry["symbol"], {"status": "pending"})
        for entry in declared["symbols"]
    }
    if args.report:
        args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(
        f"{len(known)} public symbols: {len(bound)} with explicit bindings/specializations; "
        f"{len(known) - len(bound)} pending."
    )
    if args.require_complete and known - bound.keys():
        parser.exit(
            1, "Release preparation blocked: public API bindings remain pending.\n"
        )


if __name__ == "__main__":
    main()
