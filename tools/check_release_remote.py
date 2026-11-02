# SPDX-License-Identifier: MPL-2.0
"""Refuse immutable-version collisions before uploading either package.

Retries may skip an existing file only after its SHA-256 matches the prepared
artifact. Network/authentication failures are errors, never treated as absence.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import urlopen

from release_version import release_version
from verify_release_candidate import verify_candidate


def fetch(url):
    try:
        with urlopen(url, timeout=30) as response:
            return response.read()
    except HTTPError as error:
        if error.code == 404:
            return None
        raise


def python_status(files, body):
    remote = (
        {
            entry["filename"]: entry["digests"]["sha256"]
            for entry in json.loads(body)["urls"]
        }
        if body
        else {}
    )
    matches = 0
    for path in files:
        if path.name in remote:
            if remote[path.name] != hashlib.sha256(path.read_bytes()).hexdigest():
                raise ValueError(
                    f"published Python file differs: {path.name}; choose a new version"
                )
            matches += 1
    if remote and not matches:
        raise ValueError(
            "published version cannot be identified as this prepared release"
        )
    return matches == len(files)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--python", type=Path, required=True)
    parser.add_argument("--native", type=Path, required=True)
    parser.add_argument("--index", choices=["pypi", "testpypi"], default="pypi")
    parser.add_argument("--commit", help="Original source SHA of a verified candidate")
    args = parser.parse_args()
    version = (
        verify_candidate(args.python, args.commit)["version"]
        if args.commit
        else release_version()
    )
    files = sorted(args.python.glob("*.whl")) + sorted(
        args.python.glob("hmath_python-*.tar.gz")
    )
    if not files:
        raise ValueError("missing Python distributions")
    host = "pypi.org" if args.index == "pypi" else "test.pypi.org"
    python_complete = python_status(
        files, fetch(f"https://{host}/pypi/hmath-python/{version}/json")
    )
    haskell_complete = False
    if args.index == "pypi":
        source = args.native / f"hmath-{version}.tar.gz"
        if not source.is_file():
            raise ValueError("missing Haskell source distribution")
        remote = fetch(
            f"https://hackage.haskell.org/package/hmath-{version}/hmath-{version}.tar.gz"
        )
        if remote is not None:
            if (
                hashlib.sha256(remote).digest()
                != hashlib.sha256(source.read_bytes()).digest()
            ):
                raise ValueError(
                    "published Haskell source differs; choose a new version"
                )
            haskell_complete = True
    values = {"python_complete": python_complete, "haskell_complete": haskell_complete}
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a") as output:
            for name, value in values.items():
                print(f"{name}={str(value).lower()}", file=output)
    print(json.dumps(values))


if __name__ == "__main__":
    main()
