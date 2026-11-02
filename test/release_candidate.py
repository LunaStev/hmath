# SPDX-License-Identifier: MPL-2.0
"""Real candidate-format parsing and mocked read-only preparation-run selection."""

import base64
import hashlib
import io
import json
import os
import subprocess
import sys
import tarfile
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import select_release_candidate as selector
import verify_release_candidate as verifier

VERSION = "1.2.3"
COMMIT = "a" * 40
REPOSITORY = "wavefnd/hmath"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def tar(path, prefix, files, links=None):
    with tarfile.open(path, "w:gz") as archive:
        for name, data in files.items():
            item = tarfile.TarInfo(prefix + "/" + name)
            item.size = len(data)
            archive.addfile(item, io.BytesIO(data))
        for name, target in (links or {}).items():
            item = tarfile.TarInfo(prefix + "/" + name)
            item.type = tarfile.SYMTYPE
            item.linkname = target
            archive.addfile(item)


class Candidate:
    def __init__(self, directory):
        self.directory = Path(directory)
        self.wheel_name = f"hmath_python-{VERSION}-py3-none-manylinux_2_28_x86_64.whl"
        self.native = bytearray(64)
        self.native[:6] = b"\x7fELF\x02\x01"
        self.native[16:20] = b"\x03\x00>\x00"
        self.native = bytes(self.native)
        self.libraries = {"hmath_python.libs/libHSfixture.so": b"fixture dependency"}
        self.metadata = f"Metadata-Version: 2.4\nName: hmath-python\nVersion: {VERSION}\n\n".encode()
        self.wheel_metadata = b"Wheel-Version: 1.0\nRoot-Is-Purelib: false\nTag: py3-none-manylinux_2_28_x86_64\n\n"
        self.project = f'[project]\nname="hmath-python"\nversion="{VERSION}"\n'.encode()
        self.cabal = f"cabal-version: 3.0\nname: hmath\nversion: {VERSION}\n".encode()
        self.sdk_native = self.native
        self.sdk_libraries = self.libraries.copy()
        self.python_prefix = f"hmath_python-{VERSION}"
        self.cabal_prefix = f"hmath-{VERSION}"
        self.write()

    def write(self):
        wheel = self.directory / self.wheel_name
        with zipfile.ZipFile(wheel, "w") as archive:
            dist = f"hmath_python-{VERSION}.dist-info/"
            archive.writestr(dist + "METADATA", self.metadata)
            archive.writestr(dist + "WHEEL", self.wheel_metadata)
            archive.writestr("_hmath_native/libhmath.so", self.native)
            for name, data in self.libraries.items():
                archive.writestr(name, data)
        tar(
            self.directory / f"hmath_python-{VERSION}.tar.gz",
            self.python_prefix,
            {"pyproject.toml": self.project, "PKG-INFO": self.metadata},
        )
        tar(
            self.directory / f"hmath-{VERSION}.tar.gz",
            self.cabal_prefix,
            {"hmath.cabal": self.cabal},
        )
        sdk = {
            "manifest.json": json.dumps(
                {
                    "version": VERSION,
                    "abi": 1,
                    "platform": "linux-x86_64",
                    "wheel": self.wheel_name,
                    "wheel_sha256": digest(wheel.read_bytes()),
                }
            ).encode(),
            "lib/libhmath.so.1": self.sdk_native,
            "include/hmath.h": b"fixture header",
            "lib/pkgconfig/hmath.pc": b"fixture pkg-config",
            "lib/cmake/HMath/HMathConfig.cmake": b"fixture CMake config",
            "lib/cmake/HMath/HMathConfigVersion.cmake": b"fixture CMake version",
            "share/licenses/hmath/LICENSE": b"MPL-2.0",
            **self.sdk_libraries,
        }
        tar(
            self.directory / f"hmath-{VERSION}-linux-x86_64.tar.gz",
            f"hmath-{VERSION}-linux-x86_64",
            sdk,
            {"lib/libhmath.so": "libhmath.so.1"},
        )

    def receipts(self):
        paths = verifier.validate_artifacts(self.directory, VERSION)
        records = [
            {
                "path": p.name,
                "sha256": digest(p.read_bytes()),
                "bytes": p.stat().st_size,
            }
            for p in paths
        ]
        manifest = {
            "version": VERSION,
            "commit": COMMIT,
            "abi": 1,
            "candidate_run_id": "123",
            "artifacts": records,
        }
        (self.directory / "release.json").write_text(json.dumps(manifest))
        (self.directory / "SHA256SUMS").write_text(
            "".join(item["sha256"] + "  " + item["path"] + "\n" for item in records)
            + digest((self.directory / "release.json").read_bytes())
            + "  release.json\n"
        )
        return manifest


class CandidateValidation(unittest.TestCase):
    def setUp(self):
        self.work = tempfile.TemporaryDirectory(prefix="candidate-parser-test-")
        self.addCleanup(self.work.cleanup)
        self.fixture = Candidate(self.work.name)
        self.directory = Path(self.work.name)

    def verify(self):
        return verifier.verify_candidate(self.directory, COMMIT)

    def test_complete_candidate_and_idempotent_artifact_validation(self):
        self.fixture.receipts()
        self.assertEqual(len(verifier.validate_artifacts(self.directory, VERSION)), 4)
        self.assertEqual(self.verify()["candidate_run_id"], "123")

    def test_selected_old_candidate_version_is_independent_of_controller(self):
        self.fixture.receipts()
        self.assertEqual(
            verifier.verify_candidate(self.directory, COMMIT)["version"], VERSION
        )
        self.assertEqual(
            verifier.verify_candidate(self.directory, COMMIT, VERSION)["version"],
            VERSION,
        )
        with self.assertRaisesRegex(ValueError, "selected preparation run"):
            verifier.verify_candidate(self.directory, COMMIT, "9.9.9")

    def test_reject_extra_stale_and_nonflat_files(self):
        for name in [
            "notes.txt",
            "hmath_python-9.9.9.tar.gz",
            "hmath-1.2.3.tar.gz.bak",
        ]:
            with self.subTest(name=name):
                path = self.directory / name
                path.write_bytes(b"extra")
                with self.assertRaises(ValueError):
                    verifier.validate_artifacts(self.directory, VERSION)
                path.unlink()
        path = self.directory / "nested"
        path.mkdir()
        with self.assertRaises(ValueError):
            verifier.validate_artifacts(self.directory, VERSION)

    def test_reject_wheel_metadata_version_and_platform_disagreement(self):
        for mutation in ["name", "version", "tag", "purelib", "elf"]:
            with self.subTest(mutation=mutation):
                candidate = Candidate(self.directory)
                if mutation == "name":
                    candidate.metadata = candidate.metadata.replace(
                        b"hmath-python", b"other"
                    )
                if mutation == "version":
                    candidate.metadata = candidate.metadata.replace(
                        VERSION.encode(), b"9.9.9"
                    )
                if mutation == "tag":
                    candidate.wheel_metadata = candidate.wheel_metadata.replace(
                        b"x86_64", b"aarch64"
                    )
                if mutation == "purelib":
                    candidate.wheel_metadata = candidate.wheel_metadata.replace(
                        b"false", b"true"
                    )
                if mutation == "elf":
                    candidate.native = b"not a shared library"
                    candidate.sdk_native = candidate.native
                candidate.write()
                with self.assertRaises(ValueError):
                    verifier.validate_artifacts(self.directory, VERSION)

    def test_reject_source_package_version_prefix_and_name(self):
        for mutation in [
            "python-version",
            "python-prefix",
            "cabal-version",
            "cabal-prefix",
        ]:
            with self.subTest(mutation=mutation):
                candidate = Candidate(self.directory)
                if mutation == "python-version":
                    candidate.project = candidate.project.replace(
                        VERSION.encode(), b"9.9.9"
                    )
                if mutation == "python-prefix":
                    candidate.python_prefix = "hmath_python-9.9.9"
                if mutation == "cabal-version":
                    candidate.cabal = candidate.cabal.replace(
                        VERSION.encode(), b"9.9.9"
                    )
                if mutation == "cabal-prefix":
                    candidate.cabal_prefix = "hmath-9.9.9"
                candidate.write()
                with self.assertRaises(ValueError):
                    verifier.validate_artifacts(self.directory, VERSION)

    def test_sdk_must_use_exact_wheel_native_and_dependencies(self):
        self.fixture.sdk_native = self.fixture.native + b"different build"
        self.fixture.write()
        with self.assertRaisesRegex(ValueError, "native library differs"):
            verifier.validate_artifacts(self.directory, VERSION)
        self.fixture.sdk_native = self.fixture.native
        self.fixture.sdk_libraries = {
            "hmath_python.libs/libHSfixture.so": b"different runtime"
        }
        self.fixture.write()
        with self.assertRaisesRegex(ValueError, "dependencies differ"):
            verifier.validate_artifacts(self.directory, VERSION)

    def test_receipts_source_identity_and_complete_checksum_coverage(self):
        for mutation in [
            "commit",
            "version",
            "run-id",
            "missing-record",
            "duplicate-record",
            "size",
            "checksum",
            "extra-record",
        ]:
            with self.subTest(mutation=mutation):
                manifest = self.fixture.receipts()
                if mutation == "commit":
                    manifest["commit"] = "b" * 40
                if mutation == "version":
                    manifest["version"] = "9.9.9"
                if mutation == "run-id":
                    manifest["candidate_run_id"] = ""
                if mutation == "missing-record":
                    manifest["artifacts"].pop()
                if mutation == "duplicate-record":
                    manifest["artifacts"].append(manifest["artifacts"][0])
                if mutation == "size":
                    manifest["artifacts"][0]["bytes"] += 1
                if mutation == "checksum":
                    manifest["artifacts"][0]["sha256"] = "0" * 64
                if mutation == "extra-record":
                    manifest["artifacts"].append(
                        {"path": "release.json", "bytes": 1, "sha256": "0" * 64}
                    )
                (self.directory / "release.json").write_text(json.dumps(manifest))
                with self.assertRaises((ValueError, TypeError)):
                    self.verify()
        self.fixture.receipts()
        (self.directory / "SHA256SUMS").write_text("0" * 64 + "  extra\n")
        with self.assertRaisesRegex(ValueError, "SHA256SUMS"):
            self.verify()

    def test_receipt_extra_file_and_symlink_are_rejected(self):
        self.fixture.receipts()
        (self.directory / "surprise.txt").write_bytes(b"unmanifested")
        with self.assertRaises(ValueError):
            self.verify()
        (self.directory / "surprise.txt").unlink()
        original = self.directory / self.fixture.wheel_name
        source = self.directory / "actual"
        original.rename(source)
        original.symlink_to(source)
        with self.assertRaises(ValueError):
            self.verify()

    def test_duplicate_and_traversal_tar_members_are_rejected(self):
        path = self.directory / f"hmath-{VERSION}.tar.gz"
        with tarfile.open(path, "w:gz") as archive:
            for name in [
                f"hmath-{VERSION}/hmath.cabal",
                f"hmath-{VERSION}/../hmath.cabal",
            ]:
                item = tarfile.TarInfo(name)
                item.size = len(self.fixture.cabal)
                archive.addfile(item, io.BytesIO(self.fixture.cabal))
        with self.assertRaisesRegex(ValueError, "unsafe artifact member"):
            verifier.validate_artifacts(self.directory, VERSION)


def run_metadata(run_id=123, **changes):
    return {
        "id": run_id,
        "repository": {"full_name": REPOSITORY},
        "path": selector.WORKFLOW,
        "head_sha": COMMIT,
        "head_branch": "master",
        "event": "workflow_dispatch",
        "status": "completed",
        "conclusion": "success",
        "created_at": f"2026-11-{run_id % 20 + 1:02d}T00:00:00Z",
        **changes,
    }


def source_metadata(version=VERSION):
    source = '[project]\nname="hmath-python"\nversion="' + version + '"\n'
    return {
        "type": "file",
        "encoding": "base64",
        "content": base64.b64encode(source.encode()).decode(),
    }


class CandidateSelection(unittest.TestCase):
    def setUp(self):
        self.version = patch.object(selector, "release_version", return_value=VERSION)
        self.version.start()
        self.addCleanup(self.version.stop)

    def test_explicit_run_is_checked_without_release_or_latest_queries(self):
        with patch.object(
            selector, "gh_read", side_effect=[run_metadata(), source_metadata()]
        ) as read:
            self.assertEqual(
                selector.select_candidate(REPOSITORY, COMMIT, "123"),
                {
                    "version": VERSION,
                    "candidate_run_id": "123",
                    "candidate_sha": COMMIT,
                },
            )
            self.assertEqual(
                read.call_args_list[0].args, (f"repos/{REPOSITORY}/actions/runs/123",)
            )
            self.assertEqual(
                read.call_args_list[1].args,
                (f"repos/{REPOSITORY}/contents/pyproject.toml?ref={COMMIT}",),
            )

    def test_cli_emits_immutable_source_sha_and_version_without_reentry(self):
        with tempfile.TemporaryDirectory(prefix="candidate-output-") as directory:
            output = Path(directory) / "output"
            with (
                patch.object(
                    selector, "gh_read", side_effect=[run_metadata(), source_metadata()]
                ),
                patch.object(
                    sys,
                    "argv",
                    [
                        "select_release_candidate.py",
                        "--repository",
                        REPOSITORY,
                        "--commit",
                        COMMIT,
                        "--run-id",
                        "123",
                    ],
                ),
                patch.dict(os.environ, {"GITHUB_OUTPUT": str(output)}),
                patch.object(sys, "stdout", new=io.StringIO()),
            ):
                selector.main()
            self.assertEqual(
                output.read_text(),
                "candidate_run_id=123\ncandidate_sha="
                + COMMIT
                + "\nversion="
                + VERSION
                + "\n",
            )

    def test_reject_invalid_source_repository_workflow_event_status_and_branch(self):
        for changed in [
            {"head_sha": "malformed"},
            {"repository": {"full_name": "other/repo"}},
            {"path": ".github/workflows/publish-python.yml"},
            {"head_branch": "feature"},
            {"event": "push"},
            {"conclusion": "failure"},
            {"status": "in_progress"},
        ]:
            with (
                self.subTest(changed=changed),
                patch.object(selector, "gh_read", return_value=run_metadata(**changed)),
                self.assertRaises(ValueError),
            ):
                selector.select_candidate(REPOSITORY, COMMIT, "123")

    def test_explicit_old_source_survives_new_controller_commit_and_version(self):
        with patch.object(
            selector, "gh_read", side_effect=[run_metadata(), source_metadata("1.0.0")]
        ):
            selected = selector.select_candidate(REPOSITORY, "c" * 40, "123")
        self.assertEqual(
            selected,
            {"version": "1.0.0", "candidate_run_id": "123", "candidate_sha": COMMIT},
        )

    def test_existing_draft_receipt_wins_after_controller_workflow_fix(self):
        receipt = json.dumps(
            {"version": VERSION, "commit": COMMIT, "candidate_run_id": "123"}
        )

        def read(path, **_):
            if "/releases?" in path:
                return [
                    [
                        {
                            "tag_name": "v" + VERSION,
                            "draft": True,
                            "target_commitish": "master",
                            "assets": [{"name": "release.json", "id": 9}],
                        }
                    ]
                ]
            if "/releases/assets/9" in path:
                return receipt
            if path.endswith("/runs/123"):
                return run_metadata()
            if "/contents/pyproject.toml?ref=" + COMMIT in path:
                return source_metadata()
            raise AssertionError("must not select/rebuild a newer candidate: " + path)

        with patch.object(selector, "gh_read", side_effect=read):
            selected = selector.select_candidate(REPOSITORY, "c" * 40)
        self.assertEqual(selected["candidate_sha"], COMMIT)
        self.assertEqual(selected["candidate_run_id"], "123")

    def test_existing_receipt_run_must_match_its_recorded_source(self):
        release = [
            [{"tag_name": "v" + VERSION, "assets": [{"name": "release.json", "id": 9}]}]
        ]
        receipt = json.dumps(
            {"version": VERSION, "commit": "b" * 40, "candidate_run_id": "123"}
        )
        with (
            patch.object(
                selector, "gh_read", side_effect=[release, receipt, run_metadata()]
            ),
            self.assertRaisesRegex(ValueError, "head_sha"),
        ):
            selector.select_candidate(REPOSITORY, "c" * 40)

    def test_invalid_existing_receipt_does_not_fall_back(self):
        release = [
            [{"tag_name": "v" + VERSION, "assets": [{"name": "release.json", "id": 9}]}]
        ]
        receipt = json.dumps(
            {"version": "9.9.9", "commit": COMMIT, "candidate_run_id": "123"}
        )
        with (
            patch.object(selector, "gh_read", side_effect=[release, receipt]),
            self.assertRaisesRegex(ValueError, "another version"),
        ):
            selector.select_candidate(REPOSITORY, COMMIT)

    def test_receipt_version_must_match_immutable_source_project(self):
        release = [
            [{"tag_name": "v" + VERSION, "assets": [{"name": "release.json", "id": 9}]}]
        ]
        receipt = json.dumps(
            {"version": VERSION, "commit": COMMIT, "candidate_run_id": "123"}
        )
        with (
            patch.object(
                selector,
                "gh_read",
                side_effect=[
                    release,
                    receipt,
                    run_metadata(),
                    source_metadata("9.9.9"),
                ],
            ),
            self.assertRaisesRegex(ValueError, "receipt version"),
        ):
            selector.select_candidate(REPOSITORY, COMMIT)

    def test_latest_successful_dispatch_at_exact_commit_is_selected(self):
        older = run_metadata(122, created_at="2026-11-01T00:00:00Z")
        newer = run_metadata(123, created_at="2026-11-02T00:00:00Z")
        other = run_metadata(999, head_sha="b" * 40, created_at="2026-11-03T00:00:00Z")
        with patch.object(
            selector,
            "gh_read",
            side_effect=[
                [],
                [{"workflow_runs": [older, other, newer]}],
                newer,
                source_metadata(),
            ],
        ):
            selected = selector.select_candidate(REPOSITORY, COMMIT)
        self.assertEqual(selected["candidate_run_id"], "123")
        self.assertEqual(selected["candidate_sha"], COMMIT)

    def test_no_receipt_does_not_silently_select_an_unrelated_old_source(self):
        with (
            patch.object(
                selector,
                "gh_read",
                side_effect=[[], [{"workflow_runs": [run_metadata()]}]],
            ),
            self.assertRaisesRegex(ValueError, "no successful Prepare"),
        ):
            selector.select_candidate(REPOSITORY, "c" * 40)

    def test_read_errors_are_not_treated_as_an_absent_release(self):
        error = subprocess.CompletedProcess([], 1, "", "gh: Forbidden (HTTP 403)")
        with (
            patch.object(selector.subprocess, "run", return_value=error),
            self.assertRaises(RuntimeError),
        ):
            selector.gh_read("repos/wavefnd/hmath/releases", missing=True)
        absent = subprocess.CompletedProcess([], 1, "", "gh: Not Found (HTTP 404)")
        with patch.object(selector.subprocess, "run", return_value=absent):
            self.assertIsNone(
                selector.gh_read("repos/wavefnd/hmath/releases", missing=True)
            )


if __name__ == "__main__":
    unittest.main()
