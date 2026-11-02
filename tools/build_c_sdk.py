# SPDX-License-Identifier: MPL-2.0
"""Package the repaired wheel's exact native library as a relocatable C SDK.

Keep auditwheel's library directory and relative RPATH layout intact. No
second native build or system GHC installation is needed by C consumers.
"""

import argparse
import gzip
import hashlib
import json
import re
import shutil
import subprocess
import tarfile
import tempfile
import zipfile
from email.parser import Parser
from pathlib import Path, PurePosixPath

import tomllib

ROOT = Path(__file__).resolve().parent.parent


def package(wheel, output, epoch):
    version = tomllib.loads((ROOT / "pyproject.toml").read_text())["project"]["version"]
    name = f"hmath-{version}-linux-x86_64"
    with tempfile.TemporaryDirectory(prefix="hmath-sdk-") as work:
        prefix = Path(work) / name
        (prefix / "lib").mkdir(parents=True)
        with zipfile.ZipFile(wheel) as archive:
            metadata_names = [
                n for n in archive.namelist() if n.endswith(".dist-info/METADATA")
            ]
            if len(metadata_names) != 1:
                raise ValueError("expected exactly one wheel METADATA")
            metadata = Parser().parsestr(archive.read(metadata_names[0]).decode())
            if metadata["Name"] != "hmath-python" or metadata["Version"] != version:
                raise ValueError("wheel name/version differs from this source checkout")
            wheel_metadata = archive.read(
                metadata_names[0].removesuffix("METADATA") + "WHEEL"
            ).decode()
            if not re.search(
                r"^Tag: py3-none-manylinux_[\w.]*x86_64$", wheel_metadata, re.MULTILINE
            ):
                raise ValueError("the C SDK requires a repaired Linux x86-64 wheel")
            libraries = [
                n
                for n in archive.namelist()
                if n.startswith("hmath_python.libs/") and not n.endswith("/")
            ]
            if not libraries:
                raise ValueError("wheel has no bundled auditwheel dependencies")
            native = prefix / "lib/libhmath.so.1"
            native.write_bytes(archive.read("_hmath_native/libhmath.so"))
            for entry in libraries:
                parts = PurePosixPath(entry).parts
                if len(parts) != 2 or parts[1] in (".", ".."):
                    raise ValueError("unexpected bundled library path")
                destination = prefix / entry
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(archive.read(entry))
            for entry in archive.namelist():
                if entry.startswith("_hmath_native/licenses/") and not entry.endswith(
                    "/"
                ):
                    destination = (
                        prefix / "share/licenses/hmath" / PurePosixPath(entry).name
                    )
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    destination.write_bytes(archive.read(entry))
        # A SONAME alias is necessary for executables linked with -lhmath.
        (prefix / "lib/libhmath.so").symlink_to("libhmath.so.1")
        rpath = subprocess.check_output(["readelf", "-d", str(native)], text=True)
        if "$ORIGIN/../hmath_python.libs" not in rpath:
            raise ValueError(
                "unexpected auditwheel RPATH; SDK relocation would be unsafe"
            )
        subprocess.run(
            ["python3", str(ROOT / "tools/check_abi.py"), str(native)], check=True
        )
        (prefix / "include").mkdir()
        # Internal provider adapter headers are intentionally not installed.
        for header in sorted((ROOT / "include").glob("hmath*.h")):
            if header.name != "hmath_backend.h":
                shutil.copy2(header, prefix / "include" / header.name)
        licenses = prefix / "share/licenses/hmath"
        licenses.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / "LICENSE", licenses / "LICENSE")
        variables = {
            "VERSION": version,
            "LIBDIR": "lib",
            "INCLUDEDIR": "include",
            "LIBRARY": "libhmath.so.1",
            "CMAKE_PREFIX_RELATIVE": "../../..",
            "PC_PREFIX_RELATIVE": "../..",
        }
        for source, destination in [
            ("meson/hmath.pc.in", "lib/pkgconfig/hmath.pc"),
            ("meson/cmake/HMathConfig.cmake.in", "lib/cmake/HMath/HMathConfig.cmake"),
            (
                "meson/cmake/HMathConfigVersion.cmake.in",
                "lib/cmake/HMath/HMathConfigVersion.cmake",
            ),
        ]:
            text = (ROOT / source).read_text()
            for key, value in variables.items():
                text = text.replace("@" + key + "@", value)
            target = prefix / destination
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text)
        (prefix / "manifest.json").write_text(
            json.dumps(
                {
                    "version": version,
                    "abi": 1,
                    "platform": "linux-x86_64",
                    "wheel": wheel.name,
                    "wheel_sha256": hashlib.sha256(wheel.read_bytes()).hexdigest(),
                },
                indent=2,
            )
            + "\n"
        )
        output.mkdir(parents=True, exist_ok=True)
        target = output / (name + ".tar.gz")
        with (
            target.open("wb") as file,
            gzip.GzipFile(
                fileobj=file, mode="wb", filename="", mtime=epoch
            ) as compressed,
            tarfile.open(fileobj=compressed, mode="w") as archive,
        ):
            for path in sorted(prefix.rglob("*")):
                info = archive.gettarinfo(
                    str(path), str(path.relative_to(prefix.parent))
                )
                info.uid = info.gid = 0
                info.uname = info.gname = ""
                info.mtime = epoch
                if info.isfile():
                    info.mode = 0o644
                    with path.open("rb") as content:
                        archive.addfile(info, content)
                else:
                    info.mode = 0o755
                    archive.addfile(info)
        return target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("wheel", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--epoch", type=int, required=True)
    args = parser.parse_args()
    print(package(args.wheel, args.output, args.epoch))


if __name__ == "__main__":
    main()
