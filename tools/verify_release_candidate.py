# SPDX-License-Identifier: MPL-2.0
"""Validate the complete, immutable C/Python/Haskell release candidate.

Artifact validation is usable before receipt creation. Candidate verification
also checks its source/run identity, manifest and SHA256SUMS. No network or
publication operation is performed by this module.
"""

import argparse
import hashlib
import json
import re
import tarfile
import zipfile
from email.parser import BytesParser
from pathlib import Path, PurePosixPath

import tomllib

_VERSION = r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)"
_PLATFORM = r"manylinux_(?:2_\d+|2014)_x86_64"
_RECEIPTS = {"release.json", "SHA256SUMS"}


def _version(value):
    if not isinstance(value, str) or not re.fullmatch(_VERSION, value):
        raise ValueError("release version must be canonical major.minor.patch")
    return value


def _sha(value):
    if not isinstance(value, str) or not re.fullmatch(r"[0-9a-f]{40}", value):
        raise ValueError("source identity must be an exact lowercase Git commit SHA")
    return value


def _run_id(value):
    if type(value) not in (int, str) or not re.fullmatch(r"[1-9]\d*", str(value)):
        raise ValueError("candidate_run_id must be a positive decimal workflow run ID")
    return str(value)


def _hash(data):
    return hashlib.sha256(data).hexdigest()


def _json(data):
    def pairs(items):
        result = {}
        for key, value in items:
            if key in result:
                raise ValueError(f"duplicate JSON field: {key}")
            result[key] = value
        return result

    return json.loads(data, object_pairs_hook=pairs)


def _member_path(name):
    # PurePosixPath normalizes '.' and empty components; inspect the original
    # spelling too so normalization cannot hide traversal/duplicate members.
    path = PurePosixPath(name)
    if (
        path.is_absolute()
        or "\\" in name
        or any(p in ("", ".", "..") for p in name.rstrip("/").split("/"))
    ):
        raise ValueError(f"unsafe artifact member path: {name}")
    return path


def _tar(path, prefix, *, sdk=False):
    files, links = {}, {}
    seen = set()
    with tarfile.open(path, "r:gz") as archive:
        for member in archive:
            name = str(_member_path(member.name))
            if name in seen:
                raise ValueError(f"duplicate tar member: {name}")
            seen.add(name)
            parts = PurePosixPath(name).parts
            if not parts or parts[0] != prefix:
                raise ValueError(
                    f"archive prefix differs from filename/version: {name}"
                )
            relative = str(PurePosixPath(*parts[1:]))
            if member.isdir():
                continue
            if (
                member.issym()
                and sdk
                and relative == "lib/libhmath.so"
                and member.linkname == "libhmath.so.1"
            ):
                links[relative] = member.linkname
                continue
            if not member.isfile() or len(parts) < 2:
                raise ValueError(f"unsupported artifact member type: {name}")
            stream = archive.extractfile(member)
            if stream is None:
                raise ValueError(f"unreadable artifact member: {name}")
            files[relative] = stream.read()
    return files, links


def _metadata(data, package, version):
    metadata = BytesParser().parsebytes(data)
    for field, expected in (("Name", package), ("Version", version)):
        values = metadata.get_all(field, [])
        if len(values) != 1 or values[0] != expected:
            raise ValueError(f"package {field} differs from the candidate: {values}")
    return metadata


def _elf(data):
    if (
        len(data) < 64
        or data[:6] != b"\x7fELF\x02\x01"
        or int.from_bytes(data[16:18], "little") != 3
        or int.from_bytes(data[18:20], "little") != 62
    ):
        raise ValueError(
            "native payload must be an ELF64 little-endian x86-64 shared library"
        )


def _wheel(path, version):
    pattern = rf"hmath_python-{re.escape(version)}-py3-none-({_PLATFORM}(?:\.{_PLATFORM})*)\.whl"
    match = re.fullmatch(pattern, path.name)
    if not match:
        raise ValueError("unexpected wheel filename/version/platform")
    platforms = match[1].split(".")
    if len(set(platforms)) != len(platforms):
        raise ValueError("duplicate wheel platform tag")
    files = {}
    with zipfile.ZipFile(path) as archive:
        seen = set()
        for item in archive.infolist():
            name = str(_member_path(item.filename))
            if name in seen:
                raise ValueError(f"duplicate wheel member: {name}")
            seen.add(name)
            if item.is_dir():
                continue
            files[name] = archive.read(item)
    dist = f"hmath_python-{version}.dist-info/"
    metadata_names = [name for name in files if name.endswith(".dist-info/METADATA")]
    if metadata_names != [dist + "METADATA"]:
        raise ValueError("wheel must contain exactly its own name/version METADATA")
    _metadata(files[dist + "METADATA"], "hmath-python", version)
    if dist + "WHEEL" not in files:
        raise ValueError("wheel has no WHEEL metadata")
    metadata = BytesParser().parsebytes(files[dist + "WHEEL"])
    if metadata.get_all("Wheel-Version") != ["1.0"] or metadata.get_all(
        "Root-Is-Purelib"
    ) != ["false"]:
        raise ValueError(
            "wheel must declare the supported non-pure Wheel-Version 1.0 format"
        )
    tags = metadata.get_all("Tag", [])
    if len(tags) != len(platforms) or set(tags) != {
        "py3-none-" + platform for platform in platforms
    }:
        raise ValueError("WHEEL tags differ from the filename")
    native = files.get("_hmath_native/libhmath.so")
    if native is None:
        raise ValueError("wheel is missing the bundled HMath native library")
    _elf(native)
    libraries = {
        name: value
        for name, value in files.items()
        if name.startswith("hmath_python.libs/")
    }
    if not libraries or any(len(PurePosixPath(name).parts) != 2 for name in libraries):
        raise ValueError("wheel must include its repaired auditwheel dependencies")
    return native, libraries


def _python_source(path, version):
    files, _ = _tar(path, f"hmath_python-{version}")
    if "pyproject.toml" not in files or "PKG-INFO" not in files:
        raise ValueError("Python source archive lacks pyproject.toml/PKG-INFO")
    project = tomllib.loads(files["pyproject.toml"].decode())["project"]
    if project.get("name") != "hmath-python" or project.get("version") != version:
        raise ValueError(
            "Python source project name/version differs from the candidate"
        )
    _metadata(files["PKG-INFO"], "hmath-python", version)


def _haskell_source(path, version):
    files, _ = _tar(path, f"hmath-{version}")
    if "hmath.cabal" not in files:
        raise ValueError("Haskell archive lacks hmath.cabal")
    text = files["hmath.cabal"].decode()
    for field, expected in (("name", "hmath"), ("version", version)):
        values = re.findall(
            rf"^{field}:\s*([^\r\n]+)", text, re.MULTILINE | re.IGNORECASE
        )
        if len(values) != 1 or values[0].split("--", 1)[0].strip() != expected:
            raise ValueError(f"Haskell source {field} differs from the candidate")


def _sdk(path, version, wheel, native, libraries):
    files, links = _tar(path, f"hmath-{version}-linux-x86_64", sdk=True)
    if links != {"lib/libhmath.so": "libhmath.so.1"}:
        raise ValueError("SDK must contain its relative libhmath.so SONAME alias")
    if "manifest.json" not in files:
        raise ValueError("SDK lacks its manifest")
    metadata = _json(files["manifest.json"])
    expected = {
        "version": version,
        "abi": 1,
        "platform": "linux-x86_64",
        "wheel": wheel.name,
        "wheel_sha256": _hash(wheel.read_bytes()),
    }
    if type(metadata.get("abi")) is not int or any(
        metadata.get(key) != value for key, value in expected.items()
    ):
        raise ValueError(
            "SDK version/platform/ABI/wheel identity differs from the candidate"
        )
    if files.get("lib/libhmath.so.1") != native:
        raise ValueError("SDK native library differs from the exact candidate wheel")
    sdk_libraries = {
        name: value
        for name, value in files.items()
        if name.startswith("hmath_python.libs/")
    }
    if sdk_libraries != libraries:
        raise ValueError(
            "SDK bundled dependencies differ from the exact candidate wheel"
        )
    for name in (
        "include/hmath.h",
        "lib/pkgconfig/hmath.pc",
        "lib/cmake/HMath/HMathConfig.cmake",
        "lib/cmake/HMath/HMathConfigVersion.cmake",
        "share/licenses/hmath/LICENSE",
    ):
        if name not in files:
            raise ValueError(f"SDK lacks required installed file: {name}")


def validate_artifacts(directory, version):
    """Validate flat, exact current-version artifacts; return their sorted Paths.

    Existing receipt filenames are allowed for idempotent receipt generation,
    but are only trusted after verify_candidate validates them.
    """
    directory = Path(directory)
    version = _version(version)
    if not directory.is_dir():
        raise ValueError("candidate directory does not exist")
    paths = []
    for path in directory.iterdir():
        if path.is_symlink() or not path.is_file():
            raise ValueError("candidate must contain flat regular files only")
        if path.name not in _RECEIPTS:
            paths.append(path)
    wheels = [path for path in paths if path.suffix == ".whl"]
    if len(wheels) != 1:
        raise ValueError(
            "candidate must contain exactly one repaired Linux x86-64 wheel"
        )
    wheel = wheels[0]
    expected = {
        wheel.name,
        f"hmath_python-{version}.tar.gz",
        f"hmath-{version}.tar.gz",
        f"hmath-{version}-linux-x86_64.tar.gz",
    }
    if {path.name for path in paths} != expected:
        raise ValueError("candidate has missing, unexpected or other-version artifacts")
    native, libraries = _wheel(wheel, version)
    _python_source(directory / f"hmath_python-{version}.tar.gz", version)
    _haskell_source(directory / f"hmath-{version}.tar.gz", version)
    _sdk(
        directory / f"hmath-{version}-linux-x86_64.tar.gz",
        version,
        wheel,
        native,
        libraries,
    )
    return sorted(paths)


def verify_candidate(directory, commit, version=None):
    """Verify exact artifact bytes and receipt/source/run identity; return manifest."""
    directory = Path(directory)
    _sha(commit)
    for receipt in _RECEIPTS:
        if not (directory / receipt).is_file() or (directory / receipt).is_symlink():
            raise ValueError(f"candidate lacks a regular {receipt} receipt")
    manifest = _json((directory / "release.json").read_bytes())
    manifest_version = _version(manifest.get("version"))
    if version is not None and manifest_version != _version(version):
        raise ValueError("candidate version differs from the selected preparation run")
    version = manifest_version
    if (
        manifest.get("commit") != commit
        or type(manifest.get("abi")) is not int
        or manifest.get("abi") != 1
    ):
        raise ValueError(
            "candidate source commit/ABI differs from the selected preparation"
        )
    _run_id(manifest.get("candidate_run_id"))
    paths = validate_artifacts(directory, version)
    expected = {path.name: path for path in paths}
    records = manifest.get("artifacts")
    if not isinstance(records, list):
        raise TypeError("manifest artifacts must be a list")
    declared = {}
    for record in records:
        if not isinstance(record, dict) or set(record) != {"path", "sha256", "bytes"}:
            raise ValueError("invalid artifact receipt record")
        name, digest, count = record["path"], record["sha256"], record["bytes"]
        if not isinstance(name, str) or name not in expected or name in declared:
            raise ValueError("manifest has unexpected/duplicate artifact paths")
        if (
            not isinstance(digest, str)
            or not re.fullmatch(r"[0-9a-f]{64}", digest)
            or type(count) is not int
            or count < 0
        ):
            raise ValueError("invalid artifact digest/byte count")
        if count != expected[name].stat().st_size or digest != _hash(
            expected[name].read_bytes()
        ):
            raise ValueError(f"candidate artifact checksum/size mismatch: {name}")
        declared[name] = digest
    if set(declared) != set(expected):
        raise ValueError("manifest does not list exactly the allowed artifacts")
    checksums = {}
    for line in (directory / "SHA256SUMS").read_text().splitlines():
        match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
        if not match or match[2] in checksums:
            raise ValueError("invalid/duplicate SHA256SUMS entry")
        checksums[match[2]] = match[1]
    expected_checksums = {
        **declared,
        "release.json": _hash((directory / "release.json").read_bytes()),
    }
    if checksums != expected_checksums:
        raise ValueError("SHA256SUMS differs from the manifest")
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--version")
    parser.add_argument("--run-id")
    args = parser.parse_args()
    manifest = verify_candidate(args.directory, args.commit, args.version)
    if args.run_id is not None and _run_id(manifest["candidate_run_id"]) != _run_id(
        args.run_id
    ):
        raise ValueError("candidate receipt belongs to another preparation run")
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
