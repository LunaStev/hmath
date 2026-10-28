# SPDX-License-Identifier: MPL-2.0
"""Execute Python examples from the documentation against an installed wheel."""

import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
for path in sorted((root / "docs").rglob("*.md")):
    namespace = {"__name__": "__main__"}
    examples = re.findall(
        r"^```python\n(.*?)^```", path.read_text(), re.MULTILINE | re.DOTALL
    )
    for example in examples:
        # These are executable examples from the checked-out project itself.
        exec(compile(example, str(path), "exec"), namespace)  # noqa: S102
    if examples:
        print(f"{path.relative_to(root)}: {len(examples)} Python examples pass")
