# SPDX-License-Identifier: MPL-2.0

"""Verify that the actual examples reject a deliberately wrong ABI result."""

import argparse
import os
from pathlib import Path
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--c-client", required=True, type=Path)
    parser.add_argument("--python-example", required=True, type=Path)
    parser.add_argument("--library", required=True, type=Path)
    parser.add_argument("--diagnostic", required=True)
    args = parser.parse_args()

    env = dict(os.environ, HMATH_LIBRARY=str(args.library.resolve()))
    commands = [
        ("C", [str(args.c_client.resolve())]),
        ("Python", [sys.executable, str(args.python_example.resolve())]),
        ("Python -O", [sys.executable, "-O", str(args.python_example.resolve())]),
    ]
    failures = 0
    for name, command in commands:
        try:
            result = subprocess.run(
                command, env=env, capture_output=True, text=True,
                errors="replace", timeout=5, check=False,
            )
        except subprocess.TimeoutExpired:
            print(f"FAIL: {name} did not reject the faulty result in time", file=sys.stderr)
            failures += 1
            continue

        # Status 1 and a numerical diagnostic distinguish an assertion failure
        # from a loader error, signal, or an unrelated program failure.
        if (
            result.returncode != 1
            or args.diagnostic not in result.stderr
            or result.stderr.count("HMATH_TEST_SHUTDOWN\n") != 1
        ):
            print(
                f"FAIL: {name}: expected a numerical failure and one shutdown, "
                f"exit={result.returncode}\n{result.stdout}{result.stderr}",
                file=sys.stderr,
            )
            failures += 1
        else:
            print(f"PASS: {name} rejected {args.diagnostic} and shut down")

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
