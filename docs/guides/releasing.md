# Prepare and publish a release

Release preparation uses one source commit for the C SDK, Python wheel/source
distribution, and Haskell Cabal source package. The version is read from
`pyproject.toml` and checked against Cabal, Meson, and the native version query;
the workflow does not ask for a second version value.

## Preparation

Run **Prepare HMath release** from GitHub Actions. This workflow publishes no
packages. It requires the public Haskell API inventory to have no pending
bindings, then runs the full compatibility checks and builds all distributions.
An inventory match is a necessary check; review the documented concrete type
specializations and numerical contracts as well. Arbitrary user-defined Haskell
typeclass instances are not implied by a concrete C/Python binding.

The `release-candidate` artifact contains:

| Artifact | Purpose |
| --- | --- |
| `hmath_python-VERSION-*.whl` | Self-contained Python installation |
| `hmath_python-VERSION.tar.gz` | Python source distribution |
| `hmath-VERSION-linux-x86_64.tar.gz` | Relocatable C/C++ SDK with headers, shared library, bundled runtime dependencies, CMake and pkg-config metadata |
| `hmath-VERSION.tar.gz` | Cabal source package for Haskell |
| `release.json` | Exact source commit, version and artifact checksums |
| `SHA256SUMS` | Download integrity checks |

The C SDK is built from the repaired wheel's exact native library, rather than
another compilation. CI relocates the SDK and compiles C/C++ consumers without
a system GHC installation. The Haskell check extracts and builds the actual
Cabal source archive. Python checks install the actual wheel on each supported
Python version.

## Publishing configuration

Keep PyPI Trusted Publishing configured for the repository's existing `pypi`
environment and publish workflow. Configure TestPyPI separately for the
`testpypi` environment if using that index.

For Haskell, create an individual Hackage account with upload permission and an
API token, then store the token as `HACKAGE_TOKEN` in the GitHub `pypi`
environment. Do not commit credentials. The account must be a maintainer of an
existing `hmath` package, or have permission to create the new package.
See [Hackage uploading and maintainer rules](https://hackage.haskell.org/upload).

## Publication

After reviewing the prepared changes, run **Publish HMath release** on upstream
`master`. Publication consumes an existing successful preparation, without rebuilding.
Leave the optional candidate run ID blank to resume the staged candidate or select
the most recent successful preparation for this exact commit. Select `testpypi` to publish only the Python test package, or `pypi`
for Hackage, PyPI, and the GitHub release containing all language artifacts.
Production publication first checks existing version hashes and Hackage
configuration before writing package indexes. Hackage publication precedes
PyPI so an unavailable Hackage account does not leave only Python published.

If a publication step fails, use **Re-run failed jobs** or dispatch publication
again. The staged release records its original candidate run ID, so publication
reuses those exact artifacts. Do not rebuild packages to resume an upload. Existing package files are accepted
only when their hashes match the prepared artifacts; different bytes require a
new version. GitHub asset uploads resume through a draft release, verify existing
assets, and publish the release after all uploads finish. Separate package
indexes cannot be updated as one atomic transaction.
