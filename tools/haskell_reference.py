# SPDX-License-Identifier: MPL-2.0
"""Integrate Haddock's rendered public declarations into the documentation site."""

import re
from collections import defaultdict
from dataclasses import dataclass, field
from html import escape, unescape
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit

import markdown

# Match the reader's numerical task before exposing the module hierarchy.
AREAS = {
    "Foundations": (
        "HMath.API",
        "HMath.Basic",
        "HMath.Constants",
        "HMath.Error",
        "HMath.Numeric",
        "HMath.Scalar",
        "HMath.Trigonometry",
        "HMath.Units",
    ),
    "Algebra and number theory": (
        "HMath.Algebra",
        "HMath.Algorithms",
        "HMath.Combinatorics",
        "HMath.Complex",
        "HMath.NumberTheory",
        "HMath.Polynomial",
        "HMath.Special",
    ),
    "Linear algebra": (
        "HMath.Backend",
        "HMath.Linear",
        "HMath.Matrix",
        "HMath.Sparse",
        "HMath.Vector",
    ),
    "Calculus and differential equations": (
        "HMath.Calculus",
        "HMath.Interpolation",
        "HMath.ODE",
        "HMath.PDE",
        "HMath.Root",
    ),
    "Optimization and differentiation": ("HMath.Autodiff", "HMath.Optimization"),
    "Statistics and time series": (
        "HMath.Probability",
        "HMath.Random",
        "HMath.Statistics",
        "HMath.TimeSeries",
    ),
    "Machine learning": ("HMath.DeepLearning", "HMath.MachineLearning"),
    "Signals and transforms": ("HMath.Fourier", "HMath.Signal"),
    "Geometry and images": (
        "HMath.Geometry",
        "HMath.Image",
        "HMath.Quaternion",
        "HMath.Rotation",
    ),
    "Graphs and symbolic mathematics": (
        "HMath.DataStructure",
        "HMath.Discrete",
        "HMath.Expression",
        "HMath.Graph",
        "HMath.Symbolic",
    ),
    "Tensors and interchange": ("HMath.Interchange", "HMath.Tensor"),
}


def area_for(name):
    if name == "HMath":
        return "Foundations"
    for area, prefixes in AREAS.items():
        if any(name == prefix or name.startswith(prefix + ".") for prefix in prefixes):
            return area
    raise ValueError(f"Assign the public module {name} to a documentation area")


def plain_summary(node):
    """Use authored prose, preserving whole sentences rather than inventing text."""
    paragraph = next(
        (
            item
            for item in node.walk()
            if item.tag == "p" and "caption" not in item.attrs.get("class", "").split()
        ),
        None,
    )
    text = escape(" ".join((paragraph or node).text().split()))
    # HTML table separators must not accidentally introduce another column.
    return re.split(r"(?<=\.)\s+(?=[A-Z])", text, maxsplit=1)[0].replace("|", "&#124;")


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


def declaration_index(interface):
    """Index nested constructors, class methods and fields as well as functions."""
    parents = {
        id(child): node
        for node in interface.walk()
        for child in node.children
        if isinstance(child, Node)
    }
    declarations, seen = [], set()
    for node in interface.walk():
        target = node.attrs.get("id", "")
        if (
            "def" not in node.attrs.get("class", "").split()
            or not target.startswith(("v:", "t:"))
            or target in seen
        ):
            continue
        seen.add(target)
        owner = parents.get(id(node))
        summary = ""
        while owner and owner is not interface:
            documentation = next(
                (
                    child
                    for child in owner.children
                    if isinstance(child, Node)
                    and "doc" in child.attrs.get("class", "").split()
                ),
                None,
            )
            if documentation:
                summary = plain_summary(documentation)
                break
            owner = parents.get(id(owner))
        declarations.append(
            (node.text(), target, summary or "Declaration and type contract below.")
        )
    return declarations


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
    groups = {area: [] for area in AREAS}
    catalogs = {area: [] for area in AREAS}
    indexed = {}
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
        declarations = declaration_index(interface)
        indexed[name] = {symbol for symbol, _, _ in declarations}
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
        content += "[Module index](../haskell.md) · [Numerical conventions](../../explanation/numerical-conventions.md)\n\n"
        guides = {
            "HMath.Matrix.QR": "[Detailed QR contracts](../qr.md) · [Least-squares guide](../../guides/least-squares.md)",
            "HMath.Calculus": "[Differentiation and integration guide](../../guides/calculus.md)",
            "HMath.Statistics": "[Descriptive statistics guide](../../guides/statistics.md)",
        }
        if name in guides:
            content += guides[name] + "\n\n"
        if description:
            content += (
                '<div class="haskell-reference">\n'
                + render(description, pages)
                + "\n</div>\n\n"
            )
        if declarations:
            content += "## On this page\n\n| API | Purpose |\n| --- | --- |\n"
            for symbol, target, summary in declarations:
                label = escape(symbol).replace("|", "&#124;")
                content += f"| [{label}](#{target}) | {summary} |\n"
            content += "\n"
        content += '<div class="haskell-reference">\n'
        content += render(interface, pages) + "\n</div>\n"
        (destination / f"{basename}.md").write_text(content)
        path = f"reference/haskell/{basename}.md"
        area = area_for(name)
        groups[area].append({name: path})
        purpose = (
            plain_summary(description)
            if description
            else "Public types and operations."
        )
        catalogs[area].append((name, basename, purpose, declarations))
    for area, entries in groups.items():
        if not entries:
            continue
        navigation.append({area: entries})
        index.append(f"\n### {area}\n\n| Module | Purpose |\n| --- | --- |\n")
        for name, basename, purpose, declarations in catalogs[area]:
            index.append(f"| [{name}](haskell/{basename}.md) | {purpose} |\n")
        slug = area.lower().replace(" ", "-")
        catalog_path = destination / f"area-{slug}.md"
        catalog = f"# {area}: API index\n\nFind an operation by its purpose. Entries link to the complete signature and contract.\n\n"
        for name, basename, _, declarations in catalogs[area]:
            catalog += f"## {name}\n\n| API | Purpose |\n| --- | --- |\n"
            for symbol, target, summary in declarations:
                label = escape(symbol).replace("|", "&#124;")
                catalog += f"| [{label}]({basename}.md#{target}) | {summary} |\n"
            catalog += "\n"
        catalog_path.write_text(catalog)
        entries.insert(0, {"API by purpose": f"reference/haskell/{catalog_path.name}"})
        index.append(
            f"\n[Browse functions in this area](haskell/{catalog_path.name}).\n"
        )
    index_content = "".join(index)
    preview = Document(markdown.markdown(index_content, extensions=["tables"]))
    table_cells = {node.text() for node in preview.root.walk() if node.tag == "td"}
    if indexed.keys() - table_cells:
        raise ValueError("Haskell module index rows must render inside tables")
    with (docs / "reference/haskell.md").open("a") as output:
        output.write(index_content)
    exports = {
        symbol
        for module in modules
        for symbol in module["visible_exports"]
        if symbol.startswith("$hmath-")
    }
    missing = [
        symbol
        for symbol in exports
        if symbol.split("$")[-1] not in indexed.get(symbol.split("$")[-2], set())
    ]
    if missing:
        raise ValueError(
            f"Public symbols absent from generated API indexes: {sorted(missing)}"
        )
    print(
        f"Haskell navigation: {len(modules)} modules, {len(exports)} exported symbols indexed"
    )
    return navigation
