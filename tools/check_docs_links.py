# SPDX-License-Identifier: MPL-2.0
"""Validate local files and fragment targets in the completed documentation site."""

import os
import re
from html import unescape
from pathlib import Path
from urllib.parse import unquote, urlsplit

import yaml

root = Path(__file__).resolve().parent.parent
site = root / "site"
base = urlsplit(yaml.safe_load((root / "mkdocs.yml").read_text())["site_url"]).path
pages = {path: path.read_text() for path in site.rglob("*.html")}
anchors = {
    path: {
        unescape(value)
        for _, value in re.findall(r"""\s(?:id|name)=(["'])(.*?)\1""", content)
    }
    for path, content in pages.items()
}
resolved = {}
failures = set()
for page, content in pages.items():
    for _, href in re.findall(r"""\shref=(["'])(.*?)\1""", content):
        href = unescape(href)
        url = urlsplit(href)
        if url.scheme or url.netloc:
            continue
        path = unquote(url.path)
        if path.startswith(base):
            target = site / path[len(base) :]
        elif path.startswith("/"):
            target = site / path.lstrip("/")
        else:
            target = page.parent / path if path else page
        target = Path(os.path.normpath(target))
        requested = target
        if requested not in resolved:
            if target.is_dir():
                target /= "index.html"
            resolved[requested] = (target, target.is_file())
        target, exists = resolved[requested]
        if not exists:
            failures.add((str(page.relative_to(site)), href, "missing file"))
        elif (
            url.fragment
            and target in anchors
            and unquote(url.fragment) not in anchors[target]
        ):
            failures.add((str(page.relative_to(site)), href, "missing anchor"))
if failures:
    examples = "\n".join(str(item) for item in sorted(failures)[:12])
    raise SystemExit(f"{len(failures)} broken documentation links:\n{examples}")
print(
    f"Documentation links: {len(pages)} HTML pages, no missing local files or anchors"
)
