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
# Intentional public data attributes, not raw FFI pointers or imported names.
PYTHON_ATTRIBUTES = {
    "hmath.HMathError.status",
    "hmath_cffi.HMathError.status",
    "hmath_cffi.Tensor.shape",
}
PYTHON_SECTIONS = (
    "Parameters", "Type", "Returns", "Raises", "Warns", "Warnings",
    "Other Parameters", "Attributes", "Methods", "See Also", "Notes",
    "References", "Examples",
)


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


def python_kinds():
    """Classify public objects without importing the native runtime."""
    kinds = {}
    for module in ("hmath", "hmath_cffi"):
        path = ROOT / "bindings/python" / f"{module}.py"
        public = python_exports(path, module)
        tree = ast.parse(path.read_text())
        for node in tree.body:
            name = f"{module}.{getattr(node, 'name', '')}"
            if name not in public:
                continue
            kinds[name] = "class" if isinstance(node, ast.ClassDef) else "callable"
            if not isinstance(node, ast.ClassDef):
                continue
            for member in node.body:
                member_name = f"{name}.{getattr(member, 'name', '')}"
                if member_name in public:
                    property_ = any(
                        isinstance(item, ast.Name) and item.id == "property"
                        for item in member.decorator_list
                    )
                    kinds[member_name] = "attribute" if property_ else "callable"
            assigned = {
                item.attr
                for item in ast.walk(node)
                if isinstance(item, ast.Attribute)
                and isinstance(item.value, ast.Name)
                and item.value.id == "self"
                and isinstance(item.ctx, ast.Store)
            }
            for attribute in PYTHON_ATTRIBUTES:
                owner, field = attribute.rsplit(".", 1)
                if owner == name:
                    if field not in assigned:
                        raise ValueError(
                            f"{path}: documented attribute {attribute} is absent"
                        )
                    kinds[attribute] = "attribute"
    if not PYTHON_ATTRIBUTES <= kinds.keys():
        raise ValueError("A documented Python attribute owner is absent")
    return kinds


def check_entries(
    names, page, pattern, parameters, signatures, defaults=None, kinds=None
):
    text = page.read_text()
    sections = re.split(r"(?=^### )", text, flags=re.MULTILINE)
    covered = {}
    for section in sections:
        match = re.match(pattern, section)
        if match:
            if kinds and match[1] in covered:
                raise ValueError(f"{page}: duplicate entry: {match[1]}")
            covered[match[1]] = section
    missing = names - covered.keys()
    if missing:
        raise ValueError(f"{page}: missing entries: {', '.join(sorted(missing))}")
    if kinds and covered.keys() - names:
        unknown = sorted(covered.keys() - names)
        raise ValueError(f"{page}: unknown Python entries: {unknown}")
    for name in sorted(names):
        section = re.split(r"^## ", covered[name], maxsplit=1, flags=re.MULTILINE)[0]
        kind = kinds.get(name, "callable") if kinds else "legacy"
        required = {
            "legacy": ("Parameters", "Returns", "See also"),
            "callable": ("Parameters", "Returns", "See Also"),
            "class": ("Parameters", "Attributes", "See Also"),
            "attribute": ("Type", "See Also"),
        }[kind]
        for title in required:
            if not re.search(rf"^#### {title}\n\n\S", section, re.MULTILINE):
                raise ValueError(f"{page}: {name} lacks a nonempty {title} section")
        if kinds:
            titles = re.findall(r"^#### (.+)$", section, re.MULTILINE)
            if len(titles) != len(set(titles)):
                raise ValueError(f"{page}: {name} has duplicate sections")
            unknown = set(titles) - set(PYTHON_SECTIONS)
            if unknown:
                raise ValueError(
                    f"{page}: {name} has unknown sections: {sorted(unknown)}"
                )
            order = [PYTHON_SECTIONS.index(title) for title in titles]
            if order != sorted(order):
                raise ValueError(f"{page}: {name} sections are out of order")
            if kind in ("class", "attribute") and "Returns" in titles:
                raise ValueError(f"{page}: {name} is not a callable result entry")
            if kind == "attribute" and "Parameters" in titles:
                raise ValueError(f"{page}: {name} is an attribute, not a call")
            if f'<a id="{name}"></a>' not in section:
                raise ValueError(f"{page}: {name} lacks its stable symbol anchor")
            heading = re.match(r"### `([^`]+)`", section)[1]
            if re.sub(r"\s+", "", signatures[name]) != re.sub(r"\s+", "", heading):
                raise ValueError(f"{page}: {name} signature differs from source")
        if kind == "attribute":
            continue
        parameter_section = section.split("#### Parameters\n", 1)[1].split("#### ", 1)[
            0
        ]
        rows = re.findall(
            r"^\| `([^`]+)` \| `([^`]+)` \| (.+) \|$", parameter_section, re.MULTILINE
        )
        if [row[0] for row in rows] != parameters[name]:
            raise ValueError(
                f"{page}: {name} parameter names/order differ from source: "
                f"{parameters[name]}"
            )
        if not parameters[name] and parameter_section.strip() != "None.":
            raise ValueError(f"{page}: {name} must explicitly state no parameters")
        for parameter, value in (defaults or {}).get(name, {}).items():
            declared_type = next(row[1] for row in rows if row[0] == parameter)
            if not re.search(
                r"\bdefault\s+" + re.escape(value) + r"(?:;|$)", declared_type
            ):
                raise ValueError(
                    f"{page}: {name}.{parameter} must document default {value}"
                )
        if not kinds:
            compact = re.sub(r"\s+", "", section)
            if re.sub(r"\s+", "", signatures[name]) not in compact:
                raise ValueError(f"{page}: {name} signature differs from source")
    return len(names)


def python_signatures():
    """Validate documentation against AST without importing the native library."""
    parameters, signatures, defaults = {}, {}, {}
    for module in ("hmath", "hmath_cffi"):
        tree = ast.parse((ROOT / "bindings/python" / f"{module}.py").read_text())

        def record(node, name):
            args = node.args
            parameters[name] = [
                arg.arg
                for arg in args.posonlyargs + args.args + args.kwonlyargs
                if arg.arg not in ("self", "cls")
            ]
            if args.vararg:
                parameters[name].append(args.vararg.arg)
            if args.kwarg:
                parameters[name].append(args.kwarg.arg)
            signature = ast.unparse(args)
            signature = re.sub(r"^(?:self|cls)(?:,\s*)?", "", signature)
            property_ = any(
                isinstance(item, ast.Name) and item.id == "property"
                for item in node.decorator_list
            )
            signatures[name] = name if property_ else f"{name}({signature})"
            positional = args.posonlyargs + args.args
            defaults[name] = (
                {
                    arg.arg: ast.unparse(value)
                    for arg, value in zip(
                        positional[-len(args.defaults) :], args.defaults
                    )
                }
                if args.defaults else {}
            )
            defaults[name].update(
                {
                    arg.arg: ast.unparse(value)
                    for arg, value in zip(args.kwonlyargs, args.kw_defaults)
                    if value is not None
                }
            )

        for node in tree.body:
            if isinstance(node, ast.FunctionDef):
                record(node, f"{module}.{node.name}")
            elif isinstance(node, ast.ClassDef):
                for member in node.body:
                    if isinstance(member, ast.FunctionDef):
                        name = f"{module}.{node.name}"
                        record(
                            member,
                            name
                            if member.name == "__init__"
                            else name + "." + member.name,
                        )
    for name in PYTHON_ATTRIBUTES:
        parameters[name], signatures[name], defaults[name] = [], name, {}
    return parameters, signatures, defaults


def read_haddock(interface):
    result = subprocess.run(
        ["haddock", "--show-interface", str(interface)],
        check=True, capture_output=True, text=True,
    )
    # Haddock currently writes this JSON to stderr, despite a successful exit.
    return json.loads(result.stdout.strip() or result.stderr.strip())


def check_haskell(data):
    public = {
        name
        for module in data["inst_ifaces"]
        for name in module["visible_exports"]
        if name.startswith("$hmath-")
        and not name.rsplit("$", 1)[1][0].isupper()
        and not name.rsplit("$", 1)[1].startswith(":")
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
            source.read_text(), re.MULTILINE,
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


def check_reference(interface=None, *, python_only=False):
    kinds = python_kinds()
    counts = {
        "Python": check_entries(
            set(kinds), ROOT / "docs/reference/python.md",
            r"### `(hmath(?:_cffi)?\.[\w.]+)",
            *python_signatures(), kinds=kinds,
        )
    }
    if python_only:
        print(f"Python API reference coverage: {counts['Python']} entries")
        return counts
    c = set()
    c_parameters, c_signatures = {}, {}
    for header in ("hmath.h", "hmath_dlpack.h"):
        c.update(
            re.findall(
                r"^HMATH_API\s+[\w\s*]+?\b(hmath_\w+)\s*\([^;]*\);",
                (ROOT / "include" / header).read_text(), re.MULTILINE,
            )
        )
        for match in re.finditer(
            r"^HMATH_API\s+([\w\s*]+?)\b(hmath_\w+)\s*\(([^;]*)\);",
            (ROOT / "include" / header).read_text(), re.MULTILINE,
        ):
            c_signatures[match[2]] = f"{match[1]}{match[2]}({match[3]})"
            c_parameters[match[2]] = [
                re.search(r"(\w+)\s*$", arg)[1]
                for arg in match[3].split(",") if arg.strip() != "void"
            ]
    counts["C"] = check_entries(
        c, ROOT / "docs/reference/c.md", r"### `(hmath_\w+)`",
        c_parameters, c_signatures,
    )
    header = (ROOT / "include/hmath.h").read_text()
    table = (ROOT / "docs/reference/c.md").read_text()
    for status, value in re.findall(
        r"\b(HMATH_(?:OK|[A-Z_]+))\s*=\s*(\d+)", header.split("} hmath_status;")[0]
    ):
        if f"| {value} | `{status}` |" not in table:
            raise ValueError(f"C status table does not match {status} = {value}")
    wave = set(
        re.findall(
            r"^pub fun (\w+)\(",
            (ROOT / "bindings/wave/hmath.wave").read_text(), re.MULTILINE,
        )
    )
    counts["Wave"] = check_entries(
        wave, ROOT / "docs/reference/wave.md", r"### `(\w+)\(",
        {
            match[1]: re.findall(r"(\w+)\s*:", match[2])
            for match in re.finditer(
                r"^pub fun (\w+)\((.*?)\)",
                (ROOT / "bindings/wave/hmath.wave").read_text(),
                re.MULTILINE | re.DOTALL,
            )
        },
        {
            match[1]: match[0].removeprefix("pub fun ").strip()
            for match in re.finditer(
                r"^pub fun (\w+)\([^)]*\)(?:\s*->\s*[^\s{]+)?",
                (ROOT / "bindings/wave/hmath.wave").read_text(), re.MULTILINE,
            )
        },
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
    parser.add_argument("--python-only", action="store_true")
    args = parser.parse_args()
    if args.python_only and args.haddock_interface:
        parser.error("--python-only cannot be combined with --haddock-interface")
    check_reference(args.haddock_interface, python_only=args.python_only)
