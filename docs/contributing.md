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

The complete site build requires the Haskell toolchain and generates the
Haskell API reference. It validates reference coverage, Haskell example
programs, the strict MkDocs build, and local file/fragment links. Do not commit
generated HTML. CI deploys the generated `site/` after changes reach `master`.
The home-page version is substituted from `pyproject.toml` during generation;
documentation changes alone do not require a package release.

For fast Python documentation checks without a native runtime or Haskell
compiler, run:

```sh
python -m unittest discover -s tools -p 'test_docs_checks.py'
python tools/check_api_docs.py --python-only
python tools/check_docs_examples.py --check-syntax
```

Syntax checking is not execution. To validate the current checkout, install
its wheel (GHC and Cabal are required for the native source build) and run:

```sh
python -m pip install --force-reinstall '.[numpy,cffi]'
python tools/check_docs_examples.py
```

To validate a published version, use a clean environment and install that
exact version of `hmath-python[numpy,cffi]`, then pass the same version to
`python tools/check_docs_examples.py --expected-version VERSION`. Replace
`VERSION` with a real release identifier; it is not a literal command argument.
The checker rejects an installed distribution with a different version.
The Documentation workflow normally tests a wheel built from the checkout;
its manual `python-runtime` input selects `released` for explicit published-
package validation. The tested distribution version is printed in the log.
These documentation checks do not replace the portable wheel pipeline.

## Reference writing standard

Use the [numpydoc section conventions](https://numpydoc.readthedocs.io/en/stable/format.html)
for Python reference content and [Haddock conventions](https://haskell-haddock.readthedocs.io/latest/markup.html)
for Haskell source documentation. The website uses Markdown with definition
lists; it adopts numpydoc's content conventions, not its reStructuredText
syntax. This does not require changing the site generator. Python source
docstrings, when edited, follow [PEP 257](https://peps.python.org/pep-0257/),
and examples follow [PEP 8](https://peps.python.org/pep-0008/).

### Python object kinds and sections

Every entry has a one-line purpose, an exact source signature (or the name of
an attribute without call parentheses), and a stable symbol anchor, for
example `<a id="hmath.Tensor.sum"></a>`. Preserve existing heading-derived
anchors when changing navigation. Link new references to the symbol anchor
rather than to a signature whose defaults may change.

Use the following section order, omitting optional sections when irrelevant:
`Parameters`, `Returns`, `Raises`, `Warns`, `Warnings`, `Other Parameters`,
`Attributes`, `Methods`, `See Also`, `Notes`, `References`, `Examples`.
Keep mathematical definitions, algorithms, numerical behavior, and cost
explanations under `Notes`; use lower-level headings there when needed.
Do not invent a paper reference or an error estimate for a simple accessor.

| Object | Required content | Distinction |
| --- | --- | --- |
| Function or method | `Parameters`, `Returns`, `See Also` | State `None.` for an empty parameter list and document a `None` return explicitly. |
| Class, including an exception | Constructor `Parameters`, public `Attributes`, `See Also` | Do not add a function-style `Returns` section to the class description. |
| Property or public data attribute | `Type`, `See Also` | No call parentheses, `Parameters`, or `Returns`; describe access/lifetime conditions as appropriate. |

For `Parameters`, use a table with one row per argument in declaration order.
Include type, default value and its meaning, units when applicable, valid
shapes/ranges, and conversion behavior. Keep the heading signature identical
to the source; explanatory types do not justify adding nonexistent annotations
or arguments. A constructor's `shape=None` must describe how shape is chosen.

`Returns` identifies type, meaning, shape, and whether a result is a new owned
handle, an independent copy, or a view. `Raises` names actual exception classes
and conditions, distinguishing wrapper validation, conversion, runtime
initialization, and checked native failures. Native status codes belong only
on paths where they can occur. Do not replace these conditions with "may fail"
or "constructor errors". Diagnostic text is not a string-matching guarantee.

Public data attributes are part of reference coverage even when they are not
properties: `.status` and cffi `.shape` are intentional examples. Update the
explicit attribute inventory in `tools/check_api_docs.py` when that public
surface changes; raw FFI handles and incidental imports are not automatically
promoted to public APIs. Keep classes, methods, and attributes linked.

The Python checker validates kinds, exact heading signatures, parameter order,
defaults, required/ordered sections, duplicate and unknown entries, and stable
symbol anchors. The C/Wave reference keeps its existing `Parameters`,
`Returns`, and `See also` convention and exact signature/status checks.

### Numerical and memory contracts

State the mathematical definition separately from implementation-specific
behavior. Check the actual Python-to-native-to-Haskell call path before naming
an algorithm, backend, complexity, or precision property. Distinguish arithmetic
work from input gathering, output allocation, and validation; zero-copy is not
synonymous with allocation-free or constant-time. Include empty and rank-zero
inputs where meaningful. Work budgets are not accuracy guarantees.

Preserve the distinction between Python-exposed functionality and Haskell-only
or future functionality. Do not claim NumPy, Python Array API, ISO, or WCAG
conformance merely because documentation resembles another project's pages.
A compatibility or accuracy guarantee needs its own evidence.

Document ownership for every returned handle/view, the effect of closing the
original handle, the caller's obligations for borrowed aliases, and the scope
of any synchronization. Thread safety of individual operations is not an
atomicity guarantee for arbitrary sequences or external array mutation.

### Executable examples

Reference examples explain usage; they are not an exhaustive replacement for
regression tests. Include imports, input data, observable/checked results, and
resource cleanup. Simple exact examples may use equality; general floating-
point comparisons need explicit, justified tolerances. An error example must
fail when the expected exception is not raised, and close unexpected results.

Mark a page whose Python blocks are independent with
`<!-- hmath:examples independent -->`. Each fenced `python` block then runs in
a fresh isolated interpreter, including shutdown examples. Pages without the
marker retain a shared namespace within a page for sequential tutorials, but
never share a process with another page. Keep each independent example complete;
no imports or objects may be borrowed from a preceding block. Use ordinary
`python` fences, not `text` fences to hide runnable examples from checks.

The example checker reports original Markdown line numbers, times out hung
processes, and requires completion of every block. `--check-syntax` compiles
without importing HMath; `--expected-version` verifies the installed package
before execution. Run C/Wave example programs with the native build when
changing them. Complete Haskell example programs are checked against the
checkout during the full documentation build.

### Navigation and review

Keep task guides distinct from reference contracts and conceptual explanations,
following [Diátaxis](https://diataxis.fr/start-here/). The existing
`getting-started/`, `guides/`, `explanation/`, and `reference/` structure is the
starting point; do not split files merely to imitate another library.
Haskell indexes continue to be generated from declarations and authored
Haddock prose, including constructors, record fields, and class methods.

Review heading hierarchy, tables, definition lists, rendered formulas, code
copying, keyboard navigation, zoom, and contrast in the built site. Preserve
useful existing explanations and inbound links. PRs should identify the source
version, documentation scope, checks actually executed, and any validation
that still depends on CI or a toolchain unavailable locally.
