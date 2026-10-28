# SPDX-License-Identifier: MPL-2.0
"""Compile and run complete Haskell programs embedded in the reference."""

import re
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
for page in sorted((root / "docs").rglob("*.md")):
    examples = re.findall(
        r"^```haskell\n(.*?)^```", page.read_text(), re.MULTILINE | re.DOTALL
    )
    for number, source in enumerate(examples, 1):
        if not re.search(r"^main\s*(?:::|=)", source, re.MULTILINE):
            continue  # GHCi fragments are not standalone programs.
        with tempfile.TemporaryDirectory(prefix="hmath-docs-haskell-") as temporary:
            program = Path(temporary) / "Main.hs"
            program.write_text(source)
            subprocess.run(
                ["runghc", "-isrc", str(program)], cwd=root, check=True, timeout=60
            )
        print(f"{page.relative_to(root)}: Haskell example {number} passes")
