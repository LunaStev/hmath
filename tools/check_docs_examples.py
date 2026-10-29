# SPDX-License-Identifier: MPL-2.0
"""Check documentation Python examples against an installed distribution.

Pages marked ``<!-- hmath:examples independent -->`` run each Python block in
its own interpreter. Other pages retain a shared namespace within that page,
so sequential tutorials continue to work. Every page has its own process.
"""

import argparse
import importlib.metadata
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
COMPLETE = "__HMATH_DOC_EXAMPLES_COMPLETED__"
INDEPENDENT = "<!-- hmath:examples independent -->"
FENCE = re.compile(r"^```python[ \t]*\n(.*?)^```[ \t]*$", re.MULTILINE | re.DOTALL)
WORKER = """
import json
import sys

payload = json.load(sys.stdin)
namespace = {"__name__": "__main__"}
for line, source in payload["examples"]:
    code = "\\n" * (line - 1) + source
    exec(compile(code, payload["path"], "exec"), namespace)
sys.stdout.write("\\n__HMATH_DOC_EXAMPLES_COMPLETED__\\n")
"""


def read_examples(path):
    """Return (first source line, source) pairs and the page isolation mode."""
    text = path.read_text(encoding="utf-8")
    examples = [
        (text.count("\n", 0, match.start(1)) + 1, match[1])
        for match in FENCE.finditer(text)
    ]
    openings = len(re.findall(r"^```python[ \t]*$", text, re.MULTILINE))
    if openings != len(examples):
        raise ValueError(f"{path}: unclosed Python code fence")
    independent = bool(
        re.search(r"^" + re.escape(INDEPENDENT) + r"[ \t]*$", text, re.MULTILINE)
    )
    return examples, independent


def check_page(path, *, syntax_only=False, timeout=60):
    """Check a page, preserving source line numbers in failure diagnostics."""
    examples, independent = read_examples(path)
    for line, source in examples:
        compile("\n" * (line - 1) + source, str(path), "exec")
    if syntax_only or not examples:
        return len(examples)
    groups = [[example] for example in examples] if independent else [examples]
    for group in groups:
        payload = {"path": str(path), "examples": group}
        label = f"{path}:{group[0][0]}"
        try:
            result = subprocess.run(
                [sys.executable, "-I", "-c", WORKER],
                input=json.dumps(payload),
                text=True,
                capture_output=True,
                timeout=timeout,
                check=False,
            )
        except subprocess.TimeoutExpired as error:
            raise RuntimeError(f"{label}: example exceeded {timeout}s") from error
        if result.returncode or not result.stdout.rstrip().endswith(COMPLETE):
            raise RuntimeError(
                f"{label}: example failed (exit {result.returncode})\n"
                f"{result.stdout}{result.stderr}"
            )
    return len(examples)


def check_installed_version(expected):
    """Reject version drift before running any documentation examples."""
    actual = importlib.metadata.version("hmath-python")
    if actual != expected:
        raise ValueError(f"Expected hmath-python {expected}, found {actual}")
    print(f"Documentation runtime: hmath-python {actual}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path)
    parser.add_argument("--check-syntax", action="store_true")
    parser.add_argument("--expected-version")
    parser.add_argument("--timeout", type=float, default=60)
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    if args.expected_version and args.check_syntax:
        parser.error("--expected-version requires execution, not --check-syntax")
    if args.expected_version:
        check_installed_version(args.expected_version)
    paths = args.paths or sorted((ROOT / "docs").rglob("*.md"))
    total = 0
    for path in paths:
        count = check_page(path, syntax_only=args.check_syntax, timeout=args.timeout)
        total += count
        if count:
            mode = "syntax checked" if args.check_syntax else "executed"
            print(f"{path}: {count} Python examples {mode}")
    if not total:
        raise SystemExit("No Python examples found in the selected paths")
    print(f"Python documentation examples: {total}")


if __name__ == "__main__":
    main()
