# SPDX-License-Identifier: MPL-2.0
"""Stage a verified immutable candidate, then publish it after index uploads."""

import argparse
import hashlib
import json
import re
import subprocess
import tempfile
from pathlib import Path

from verify_release_candidate import verify_candidate


def gh(*arguments):
    return subprocess.check_output(["gh", *arguments], text=True)


def tag_target(repository, tag):
    result = subprocess.run(
        ["gh", "api", f"repos/{repository}/commits/{tag}", "--jq", ".sha"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode:
        if "(HTTP 404)" in result.stderr or "(HTTP 422)" in result.stderr:
            return None
        raise RuntimeError(result.stderr)
    return result.stdout.strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--stage-only", action="store_true")
    args = parser.parse_args()
    manifest = verify_candidate(args.directory, args.commit)
    version = manifest["version"]
    paths = [args.directory / "release.json", args.directory / "SHA256SUMS"]
    paths += [args.directory / item["path"] for item in manifest["artifacts"]]
    tag = "v" + version
    target = tag_target(args.repository, tag)
    if target is not None and target != args.commit:
        raise ValueError("existing tag points to another source commit")
    pages = json.loads(
        gh(
            "api",
            "--paginate",
            "--slurp",
            f"repos/{args.repository}/releases?per_page=100",
        )
    )
    existing = next((r for page in pages for r in page if r["tag_name"] == tag), None)
    assets = {}
    draft_target = None
    if existing:
        if existing["draft"]:
            draft_target = gh(
                "api",
                f"repos/{args.repository}/commits/{existing['target_commitish']}",
                "--jq",
                ".sha",
            ).strip()
        assets = {a["name"]: a for a in existing["assets"]}
        if set(assets) - {p.name for p in paths}:
            raise ValueError("existing release contains assets outside this candidate")
    # Validate every existing asset before creating/updating anything.
    missing = []
    for path in paths:
        expected = hashlib.sha256(path.read_bytes()).hexdigest()
        if path.name not in assets:
            missing.append(path)
            continue
        digest = assets[path.name].get("digest")
        if not digest:
            with tempfile.TemporaryDirectory(
                prefix="hmath-release-asset-"
            ) as directory:
                gh(
                    "release",
                    "download",
                    tag,
                    "--repo",
                    args.repository,
                    "--pattern",
                    path.name,
                    "--dir",
                    directory,
                )
                digest = (
                    "sha256:"
                    + hashlib.sha256(
                        (Path(directory) / path.name).read_bytes()
                    ).hexdigest()
                )
        if digest != "sha256:" + expected:
            raise ValueError(f"existing GitHub release asset differs: {path.name}")
    # A moving branch can advance after staging. Only an already validated
    # receipt permits recovery of that original immutable candidate.
    if (
        draft_target is not None
        and draft_target != args.commit
        and (
            "release.json" not in assets
            or re.fullmatch(r"[0-9a-fA-F]{40}", existing["target_commitish"])
        )
    ):
        raise ValueError("existing draft targets another source commit")
    if not existing:
        gh(
            "release",
            "create",
            tag,
            "--repo",
            args.repository,
            "--target",
            args.commit,
            "--title",
            "HMath " + version,
            "--generate-notes",
            "--draft",
        )
    elif existing["draft"] and existing["target_commitish"] != args.commit:
        gh(
            "release",
            "edit",
            tag,
            "--repo",
            args.repository,
            "--target",
            args.commit,
        )
    # Persist candidate_run_id first, so a later dispatch selects this same run.
    for path in missing:
        gh("release", "upload", tag, str(path), "--repo", args.repository)
    if not args.stage_only:
        stable = []
        for page in pages:
            for release in page:
                match = re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", release["tag_name"])
                if match and not release["draft"] and not release["prerelease"]:
                    stable.append(tuple(map(int, match.groups())))
        newest = not stable or tuple(map(int, version.split("."))) >= max(stable)
        gh(
            "release",
            "edit",
            tag,
            "--repo",
            args.repository,
            "--draft=false",
            "--latest=" + str(newest).lower(),
        )


if __name__ == "__main__":
    main()
