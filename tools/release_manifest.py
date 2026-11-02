# SPDX-License-Identifier: MPL-2.0
"""Record checksums and source identity for all prepared language artifacts."""

import argparse
import hashlib
import json
import re
from pathlib import Path

from release_version import release_version
from verify_release_candidate import validate_artifacts


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--run-id", required=True, type=int)
    args = parser.parse_args()
    if not re.fullmatch(r"[0-9a-f]{40}", args.commit):
        parser.error("--commit must be an exact Git commit SHA")
    if args.run_id < 1:
        parser.error("--run-id must be a positive workflow run ID")
    version = release_version()
    paths = validate_artifacts(args.directory, version)
    records = [
        {
            "path": str(path.relative_to(args.directory)),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "bytes": path.stat().st_size,
        }
        for path in paths
    ]
    (args.directory / "release.json").write_text(
        json.dumps(
            {
                "version": version,
                "commit": args.commit,
                "candidate_run_id": args.run_id,
                "abi": 1,
                "artifacts": records,
            },
            indent=2,
        )
        + "\n"
    )
    (args.directory / "SHA256SUMS").write_text(
        "".join(record["sha256"] + "  " + record["path"] + "\n" for record in records)
        + hashlib.sha256((args.directory / "release.json").read_bytes()).hexdigest()
        + "  release.json\n"
    )


if __name__ == "__main__":
    main()
