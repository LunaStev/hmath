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
python -m mkdocs serve
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
