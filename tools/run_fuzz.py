# SPDX-License-Identifier: MPL-2.0
"""Instrument the actual C metadata/DLPack implementation with libFuzzer, ASan and UBSan."""

import argparse
import subprocess
import tempfile
from pathlib import Path


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--runs", type=int, default=10000)
    p.add_argument("--output", type=Path)
    a = p.parse_args()
    if not 1 <= a.runs <= 10000000:
        p.error("runs outside [1, 10000000]")
    root = Path(__file__).resolve().parent.parent
    with tempfile.TemporaryDirectory(prefix="hmath-fuzz-") as temporary:
        directory = Path(temporary)
        binary = directory / "fuzz-native"
        corpus = directory / "corpus"
        corpus.mkdir()
        # Include scalar, empty, vector, noncontiguous, invalid extent and NaN seeds.
        for index, seed in enumerate(
            [
                bytes(18),
                bytes([1, 1, 1] + [0] * 15),
                bytes([2, 4, 2, 2] + [0] * 6 + [2, 1] + [0] * 6),
                bytes([8] * 18),
                bytes([255] * 128),
            ]
        ):
            (corpus / str(index)).write_bytes(seed)
        subprocess.run(
            [
                "clang",
                "-std=c11",
                "-g",
                "-O1",
                "-fno-omit-frame-pointer",
                "-fsanitize=fuzzer,address,undefined",
                "-Iinclude",
                "-Icbits",
                "test/fuzz_native.c",
                "cbits/native.c",
                "cbits/native_dlpack.c",
                "-lm",
                "-o",
                str(binary),
            ],
            cwd=root,
            check=True,
        )
        artifacts = (
            a.output.parent if a.output else Path(tempfile.gettempdir())
        ) / "hmath-fuzz-artifacts"
        artifacts.mkdir(parents=True, exist_ok=True)
        command = [
            str(binary),
            str(corpus),
            "-runs=" + str(a.runs),
            "-seed=20261028",
            "-max_len=530",
            "-timeout=5",
            "-artifact_prefix=" + str(artifacts.resolve()) + "/",
        ]
        if a.output:
            a.output.parent.mkdir(parents=True, exist_ok=True)
            with a.output.open("w") as stream:
                subprocess.run(
                    command, check=True, stdout=stream, stderr=subprocess.STDOUT
                )
        else:
            subprocess.run(command, check=True)
    print("Instrumented metadata/DLPack fuzzing: PASS (" + str(a.runs) + " runs)")


if __name__ == "__main__":
    main()
