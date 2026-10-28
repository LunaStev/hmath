# Compatibility and releases

## Supported binary target

| Component | Supported target |
| --- | --- |
| Python wheel | Linux x86-64, glibc 2.28 or newer |
| Python runtime | Python 3.9 or newer; standard CPython 3.9–3.14 tested |
| Native external interfaces | C, Python, Wave |
| Haskell compiler CI | GHC 9.6.7 and 9.10.3 |
| C ABI | Epoch 1 |

macOS and Windows CI jobs are compilation probes. They do not establish
full runtime or Python binary support. Musl Linux and other architectures
need separate build and runtime validation before official support.

## Versioning

HMath follows semantic versioning: compatible fixes increment the patch
version, compatible features the minor version, and breaking public API
changes the major version. The C ABI epoch changes independently when its
calling or ownership contracts require it.

Version 1.0.1 repairs Python packaging: unlike 1.0.0, its Linux wheel includes
the native library and required runtime dependencies. No new numerical API
is needed for this fix, so it is a patch release.

## Publication

The release workflow reads the package version from `pyproject.toml`;
operators do not type it a second time. A common wheel pipeline builds
and tests the distributions before either TestPyPI or production PyPI
publication. Production publication is followed by a matching GitHub tag
and release containing the same distribution files. TestPyPI does not
create a GitHub release.

Published PyPI filenames cannot be replaced. Fixes to an already published
distribution require a new release. A GitHub release failure after PyPI
publication must be retried at the failed job rather than repeating the
PyPI upload.
