# SPDX-License-Identifier: MPL-2.0
"""Exercise publishing recovery and collision handling without remote writes."""

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))

import publish_github_release as publisher
from release_candidate import COMMIT, REPOSITORY, VERSION, Candidate, digest


class ReleasePublishing(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix="hmath-publish-test-")
        self.addCleanup(directory.cleanup)
        self.directory = Path(directory.name)
        Candidate(self.directory).receipts()
        self.calls = []
        self.releases = []
        self.resolved_target = COMMIT

    def asset(self, name):
        return {
            "name": name,
            "digest": "sha256:" + digest((self.directory / name).read_bytes()),
        }

    def existing(self, target=COMMIT, assets=(), draft=True):
        release = {
            "tag_name": "v" + VERSION,
            "target_commitish": target,
            "draft": draft,
            "prerelease": False,
            "assets": [self.asset(name) for name in assets],
        }
        self.releases.append(release)
        return release

    def gh(self, *arguments):
        self.calls.append(arguments)
        if arguments[:3] == ("api", "--paginate", "--slurp"):
            return json.dumps([self.releases])
        if arguments[0] == "api" and "/commits/" in arguments[1]:
            return self.resolved_target + "\n"
        return ""

    def run_publisher(self, stage=True, tag=None):
        argv = [
            "publisher",
            str(self.directory),
            "--repository",
            REPOSITORY,
            "--commit",
            COMMIT,
        ]
        if stage:
            argv.append("--stage-only")
        with (
            patch.object(sys, "argv", argv),
            patch.object(publisher, "gh", side_effect=self.gh),
            patch.object(publisher, "tag_target", return_value=tag),
        ):
            publisher.main()

    def writes(self):
        return [call for call in self.calls if call[0] == "release"]

    def test_stage_persists_receipt_first_and_does_not_publish(self):
        self.run_publisher()
        writes = self.writes()
        self.assertEqual(writes[0][:2], ("release", "create"))
        self.assertIn("--draft", writes[0])
        self.assertEqual(Path(writes[1][3]).name, "release.json")
        self.assertEqual(len([w for w in writes if w[1] == "upload"]), 6)
        self.assertFalse(any("--draft=false" in w for w in writes))

    def test_partial_upload_resumes_with_identical_files(self):
        self.existing(assets=["release.json", "SHA256SUMS"])
        self.run_publisher(stage=False, tag=COMMIT)
        writes = self.writes()
        self.assertEqual(len([w for w in writes if w[1] == "upload"]), 4)
        self.assertIn("--draft=false", writes[-1])
        self.assertFalse(any(w[1] == "create" for w in writes))

    def test_different_asset_is_rejected_before_all_writes(self):
        existing = self.existing(assets=["release.json", "SHA256SUMS"])
        existing["assets"][1]["digest"] = "sha256:" + "0" * 64
        with self.assertRaisesRegex(ValueError, "differs"):
            self.run_publisher()
        self.assertEqual(self.writes(), [])

    def test_unrelated_asset_or_wrong_tag_is_rejected_before_all_writes(self):
        existing = self.existing()
        existing["assets"] = [{"name": "unrelated.zip"}]
        with self.assertRaisesRegex(ValueError, "outside this candidate"):
            self.run_publisher()
        self.assertEqual(self.writes(), [])
        self.calls.clear()
        with self.assertRaisesRegex(ValueError, "another source commit"):
            self.run_publisher(tag="b" * 40)
        self.assertEqual(self.writes(), [])

    def test_moving_draft_branch_is_pinned_before_index_uploads(self):
        self.existing(target="master", assets=["release.json"])
        self.resolved_target = "b" * 40
        self.run_publisher()
        first = self.writes()[0]
        self.assertEqual(first[:2], ("release", "edit"))
        self.assertEqual(first[-2:], ("--target", COMMIT))

    def test_moving_branch_without_receipt_or_wrong_pinned_sha_is_rejected(self):
        self.existing(target="master")
        self.resolved_target = "b" * 40
        with self.assertRaisesRegex(ValueError, "another source commit"):
            self.run_publisher()
        self.assertEqual(self.writes(), [])
        self.releases.clear()
        self.existing(target="b" * 40, assets=["release.json"])
        with self.assertRaisesRegex(ValueError, "another source commit"):
            self.run_publisher()
        self.assertEqual(self.writes(), [])

    def test_backfill_does_not_replace_newer_latest_release(self):
        self.existing(assets=[p.name for p in self.directory.iterdir()])
        self.releases.append(
            {"tag_name": "v9.0.0", "draft": False, "prerelease": False}
        )
        self.run_publisher(stage=False, tag=COMMIT)
        self.assertEqual(len(self.writes()), 1)
        self.assertIn("--latest=false", self.writes()[0])

    def test_finalization_is_idempotent(self):
        self.existing(assets=[p.name for p in self.directory.iterdir()], draft=False)
        self.run_publisher(stage=False, tag=COMMIT)
        self.assertEqual(len(self.writes()), 1)
        self.assertIn("--latest=true", self.writes()[0])


if __name__ == "__main__":
    unittest.main()
