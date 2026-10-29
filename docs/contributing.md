# Contributing

Discuss bugs and proposed changes in
[GitHub issues](https://github.com/wavefnd/hmath/issues). Send pull requests
from a fork to `wavefnd/hmath:master`. HMath is licensed under MPL-2.0.

## Validate a change

Run the [source build and tests](guides/build.md) for numerical or native
changes. Match the existing Fourmolu, clang-format, and Python formatting
styles. Explain the behavior change and meaningful validation in the PR.

Python distribution changes must pass the installed-wheel checks without
`HMATH_LIBRARY`, `LD_LIBRARY_PATH`, or a system HMath/GHC installation.
The same wheel pipeline is required before production publication.

## Edit the documentation

Documentation source lives in `docs/`, with navigation and theme configuration
in `mkdocs.yml`. README contains only a brief project overview and quick start;
put detailed instructions here and link to the authoritative explanation.

```sh
python -m pip install -r requirements-docs.txt
python tools/build_docs.py
python -m mkdocs serve --config-file build-docs/mkdocs.generated.yml
```

To build the site together with the complete Haskell API reference, install
the Haskell toolchain and run:

```sh
python tools/build_docs.py
```

CI builds with strict validation and deploys the generated `site/` directory
to GitHub Pages after changes reach `master`. Do not commit generated HTML.
Use runnable examples with expected results; distinguish available interfaces
from future or Haskell-only features.

## Reference writing standard

Follow the [numpydoc section conventions](https://numpydoc.readthedocs.io/en/latest/format.html)
for Python reference content and [Haddock conventions](https://haskell-haddock.readthedocs.io/latest/markup.html)
for Haskell source documentation. The website uses Markdown; adopting these
content conventions does not require changing its site generator.

Each Python, C, or Wave entry needs a one-line purpose, exact signature,
`Parameters` table with one row per argument in declaration order, a `Returns`
section, and relevant `See also` links. Include types, defaults, units, shapes,
bounds, ownership, and failure conditions where they apply. Use `None.` for
an empty parameter list. Properties have no call parentheses. Explain errors
with the actual exception/status/constructor, rather than “may fail”.

Add examples for operations that need an explanation of usage. Show expected
results, resource cleanup, and meaningful failure cases. For numerical
algorithms, explain the equation, assumptions, stopping criteria, and accuracy
limitations; keep implementation history out of user instructions. A simple
getter does not need a paper citation or an artificial standalone example.

Haskell module and area indexes are generated from declarations and authored
Haddock prose, including constructors, record fields, and class methods.
The API check includes symbolic function names as well as ordinary identifiers.
Keep standalone task guides distinct from reference contracts and conceptual
explanations, following [Diátaxis](https://diataxis.fr/start-here/).

The documentation workflow checks source signatures and parameter order,
reference coverage, local file/fragment links, Python examples against the
released wheel, and complete Haskell example programs against this checkout.
Run the C/Wave example programs with the native build when changing them.
The home-page version is substituted from `pyproject.toml` during generation;
documentation changes alone do not require a package release.


## Additional Python documentation guidance

The Python reference follows [numpydoc content conventions](https://numpydoc.readthedocs.io/en/stable/format.html) adapted to the existing Markdown layout. Keep the current `Parameters`, `Returns`, and `See also` headings required by the source-derived checker. For classes and properties, preserve these sections while documenting public attributes, ownership, and access behavior in the accompanying prose; do not change the build or checking tools for a documentation-only improvement.

Document finite binary64 behavior, exact shape and rank restrictions, exception types and status codes, and the distinction between mathematical definitions and implementation-specific numerical properties. Derive claims from the actual public binding and native kernel path. Never infer Python features from Haskell-only APIs, and do not claim NumPy compatibility for operations with different semantics.

Include standalone imports in extended examples and clearly state the expected result or checked failure. The existing Python documentation checker executes all `python` fences from a Markdown file sequentially in one shared namespace; use `text` rather than `python` for irreversible runtime-shutdown demonstrations. Existing source signatures and section headings must remain stable so documentation changes pass the unchanged CI checks.
