# SPDX-License-Identifier: MPL-2.0
"""Select a previously verified Prepare run; never rebuild on publication retry.

Only read-only GitHub REST requests are used. An existing release receipt wins
so a retry keeps the exact immutable artifacts already staged/published.
"""

import argparse
import base64
import json
import os
import re
import subprocess

import tomllib
from release_version import release_version
from verify_release_candidate import _json, _run_id, _sha, _version

WORKFLOW = ".github/workflows/prepare-release.yml"


def gh_read(path, *, paginate=False, raw=False, missing=False):
    arguments = ["gh", "api", "--method", "GET"]
    if paginate:
        arguments += ["--paginate", "--slurp"]
    if raw:
        arguments += ["--header", "Accept: application/octet-stream"]
    result = subprocess.run(
        [*arguments, path], capture_output=True, text=True, check=False
    )
    if result.returncode:
        if missing and re.search(r"\bHTTP 404\b", result.stderr):
            return None
        raise RuntimeError(f"GitHub read failed for {path}: {result.stderr.strip()}")
    return result.stdout if raw else _json(result.stdout)


def validate_run(run, repository, commit, run_id):
    """Validate the authoritative workflow-run metadata before artifact download."""
    expected = _run_id(run_id)
    if not isinstance(run, dict) or _run_id(run.get("id")) != expected:
        raise ValueError("GitHub returned a different workflow run")
    repository_info = run.get("repository")
    actual_repository = (
        repository_info.get("full_name", "")
        if isinstance(repository_info, dict)
        else ""
    )
    if (
        not isinstance(actual_repository, str)
        or actual_repository.casefold() != repository.casefold()
    ):
        raise ValueError("candidate workflow belongs to another repository")
    actual_sha = _sha(run.get("head_sha"))
    if commit is not None and actual_sha != commit:
        raise ValueError(
            "candidate workflow head_sha differs from the recorded preparation source"
        )
    checks = {
        "path": WORKFLOW,
        "head_branch": "master",
        "event": "workflow_dispatch",
        "status": "completed",
        "conclusion": "success",
    }
    for field, expected_value in checks.items():
        if run.get(field) != expected_value:
            raise ValueError(
                f"candidate workflow {field} differs from the required preparation run"
            )
    return expected


def _receipt_run(repository, version):
    # Listing also covers drafts whose tag has not yet been created.
    pages = gh_read(f"repos/{repository}/releases?per_page=100", paginate=True)
    if not isinstance(pages, list) or any(not isinstance(page, list) for page in pages):
        raise ValueError("invalid GitHub release listing")
    matches = [
        release
        for page in pages
        for release in page
        if release.get("tag_name") == "v" + version
    ]
    if len(matches) > 1:
        raise ValueError("multiple release/draft records claim this version")
    if not matches:
        return None
    assets = [
        asset
        for asset in matches[0].get("assets", [])
        if asset.get("name") == "release.json"
    ]
    if len(assets) > 1:
        raise ValueError("multiple release receipts claim this version")
    if not assets:
        return None
    asset = assets[0]
    asset_id = _run_id(asset.get("id"))
    body = gh_read(f"repos/{repository}/releases/assets/{asset_id}", raw=True)
    if not isinstance(body, str):
        raise TypeError("release receipt is unreadable")
    receipt = _json(body)
    if not isinstance(receipt, dict) or receipt.get("version") != version:
        raise ValueError("existing release receipt belongs to another version")
    # Its source may precede this controller workflow, but the authoritative run
    # must still match the recorded SHA. Never substitute newly rebuilt bytes.
    return {
        "candidate_run_id": _run_id(receipt.get("candidate_run_id")),
        "candidate_sha": _sha(receipt.get("commit")),
        "version": _version(version),
    }


def source_version(repository, commit):
    """Read immutable source metadata, independently of the controller checkout."""
    metadata = gh_read(f"repos/{repository}/contents/pyproject.toml?ref={commit}")
    if (
        not isinstance(metadata, dict)
        or metadata.get("encoding") != "base64"
        or not isinstance(metadata.get("content"), str)
    ):
        raise ValueError(
            "candidate source pyproject.toml is not a readable base64 file"
        )
    data = base64.b64decode("".join(metadata["content"].split()), validate=True)
    project = tomllib.loads(data.decode()).get("project", {})
    if not isinstance(project, dict) or project.get("name") != "hmath-python":
        raise ValueError("candidate source does not describe hmath-python")
    return _version(project.get("version"))


def select_candidate(repository, commit, run_id=None):
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        raise ValueError("--repository must be owner/repository")
    _sha(commit)
    receipt = None
    expected_sha = None
    if run_id is not None and run_id != "":
        chosen = _run_id(run_id)
    else:
        receipt = _receipt_run(repository, release_version())
        chosen = receipt["candidate_run_id"] if receipt else None
        expected_sha = receipt["candidate_sha"] if receipt else commit
    if chosen is None:
        pages = gh_read(
            f"repos/{repository}/actions/workflows/prepare-release.yml/runs?branch=master&event=workflow_dispatch&status=success&per_page=100",
            paginate=True,
        )
        if not isinstance(pages, list) or any(
            not isinstance(page, dict)
            or not isinstance(page.get("workflow_runs"), list)
            for page in pages
        ):
            raise ValueError("invalid GitHub preparation-run listing")
        runs = [
            run
            for page in pages
            for run in page["workflow_runs"]
            if run.get("head_sha") == commit
        ]
        if not runs:
            raise ValueError(
                "no successful Prepare HMath release dispatch exists for this exact commit on master"
            )
        runs.sort(
            key=lambda run: (run.get("created_at", ""), int(_run_id(run.get("id")))),
            reverse=True,
        )
        chosen = _run_id(runs[0]["id"])
    run = gh_read(f"repos/{repository}/actions/runs/{chosen}")
    validate_run(run, repository, expected_sha, chosen)
    candidate_sha = _sha(run["head_sha"])
    version = source_version(repository, candidate_sha)
    if receipt and version != receipt["version"]:
        raise ValueError(
            "staged release receipt version differs from its preparation source"
        )
    return {
        "candidate_run_id": chosen,
        "candidate_sha": candidate_sha,
        "version": version,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--run-id")
    args = parser.parse_args()
    selected = select_candidate(args.repository, args.commit, args.run_id)
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a") as output:
            for name, value in selected.items():
                print(f"{name}={value}", file=output)
    print(json.dumps(selected))


if __name__ == "__main__":
    main()
