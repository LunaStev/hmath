# SPDX-License-Identifier: MPL-2.0
"""Integrate Haddock's rendered public declarations into the documentation site."""

import re
from collections import defaultdict
from dataclasses import dataclass, field
from html import escape, unescape
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit

VOID = {
    "area",
    "base",
    "br",
    "col",
    "embed",
    "hr",
    "img",
    "input",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr",
}


@dataclass
class Node:
    tag: str
    attrs: dict = field(default_factory=dict)
    children: list = field(default_factory=list)

    def walk(self):
        yield self
        for child in self.children:
            if isinstance(child, Node):
                yield from child.walk()

    def text(self):
        return "".join(
            child.text() if isinstance(child, Node) else child
            for child in self.children
        )


class Document(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.root = Node("document")
        self.stack = [self.root]
        self.feed(text)
        self.close()

    def handle_starttag(self, tag, attrs):
        node = Node(tag, dict(attrs))
        self.stack[-1].children.append(node)
        if tag not in VOID:
            self.stack.append(node)

    def handle_endtag(self, tag):
        for index in range(len(self.stack) - 1, 0, -1):
            if self.stack[index].tag == tag:
                del self.stack[index:]
                break

    def handle_data(self, data):
        self.stack[-1].children.append(data)


def render(node, module_pages):
    if isinstance(node, str):
        return escape(node)
    attrs = dict(node.attrs)
    if node.tag == "a":
        href = attrs.get("href", "")
        parsed = urlsplit(href)
        if not parsed.scheme and parsed.path:
            if parsed.path in module_pages:
                href = f"../{Path(parsed.path).stem}/"
                if parsed.fragment:
                    href += "#" + parsed.fragment
            else:
                href = "../../../haskell/" + href
            attrs["href"] = href
    attributes = "".join(
        f' {escape(key)}="{escape(value or "", quote=True)}"'
        for key, value in attrs.items()
    )
    opening = f"<{node.tag}{attributes}>"
    if node.tag in VOID:
        return opening
    return (
        opening
        + "".join(render(child, module_pages) for child in node.children)
        + f"</{node.tag}>"
    )


def repair_module_anchors(reference):
    """Resolve Haddock instance links that otherwise point to absent local methods."""
    pages = {path.name: path.read_text() for path in reference.glob("HMath*.html")}
    ids = {
        name: set(re.findall(r'\bid="([^"]+)"', text)) for name, text in pages.items()
    }
    owners = defaultdict(set)
    for name, anchors in ids.items():
        for anchor in anchors:
            owners[unescape(anchor)].add(name)

    def repair(name, match):
        tag = match[0]
        href = re.search(r'\bhref="#([^"]+)"', tag)
        if not href or href[1] in ids[name]:
            return tag
        anchor = unescape(href[1])
        destinations = owners[anchor]
        title = re.search(r'\btitle="([^"]+)"', tag)
        target = title[1].replace(".", "-") + ".html" if title else None
        if target not in destinations:
            target = next(iter(destinations)) if len(destinations) == 1 else None
        if target:
            return tag.replace(href[0], f'href="{target}#{href[1]}"')
        # Inherited Prelude methods have no local declaration. Keep the method
        # signature as text rather than generating a broken anchor to it.
        return tag.replace(href[0], "")

    return {
        name: re.sub(
            r"<a\b[^>]*>", lambda match, owner=name: repair(owner, match), text
        )
        for name, text in pages.items()
    }


def generate_reference(reference, docs, data, html_pages):
    """Generate one searchable Material page per public Haddock module."""
    modules = [module for module in data["inst_ifaces"] if module["visible_exports"]]
    pages = {
        module["module"].split("$")[-1].replace(".", "-") + ".html"
        for module in modules
    }
    destination = docs / "reference/haskell"
    destination.mkdir(parents=True, exist_ok=True)
    navigation = [{"Module index": "reference/haskell.md"}]
    index = [
        "\n## All public modules\n",
        "Select a module for its types, constructors, method signatures and function contracts.\n",
    ]
    for module in sorted(modules, key=lambda item: item["module"]):
        name = module["module"].split("$")[-1]
        basename = name.replace(".", "-")
        document = Document(html_pages[f"{basename}.html"])
        interface = next(
            (
                node
                for node in document.root.walk()
                if node.attrs.get("id") == "interface"
            ),
            None,
        )
        if interface is None:
            continue
        description = next(
            (
                node
                for node in document.root.walk()
                if node.attrs.get("id") == "description"
            ),
            None,
        )
        # Give each declaration a real heading for page navigation and search.
        for node in list(interface.walk()):
            if "top" not in node.attrs.get("class", "").split():
                continue
            signature = next(
                (
                    child
                    for child in node.children
                    if isinstance(child, Node)
                    and "src" in child.attrs.get("class", "").split()
                ),
                None,
            )
            if signature:
                definition = next(
                    (
                        child
                        for child in signature.walk()
                        if "def" in child.attrs.get("class", "").split()
                    ),
                    None,
                )
                if definition:
                    anchor = "api-" + definition.attrs.get(
                        "id", definition.text()
                    ).replace(":", "-")
                    node.children.insert(
                        0, Node("h2", {"id": anchor}, [definition.text()])
                    )
        content = f"# {name}\n\n"
        content += '<div class="haskell-reference">\n'
        if description:
            content += render(description, pages) + "\n"
        content += render(interface, pages) + "\n</div>\n"
        (destination / f"{basename}.md").write_text(content)
        path = f"reference/haskell/{basename}.md"
        navigation.append({name: path})
        index.append(f"- [{name}](haskell/{basename}.md)\n")
    with (docs / "reference/haskell.md").open("a") as output:
        output.write("\n".join(index))
    return navigation
