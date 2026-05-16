from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("pr_capture", ROOT / "install/bin/pr_capture.py")
pr_capture = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = pr_capture
SPEC.loader.exec_module(pr_capture)


class PrCaptureTests(unittest.TestCase):
    def test_parse_repo_accepts_owner_repo(self) -> None:
        self.assertEqual(pr_capture.parse_repo("owner/repo"), ("owner", "repo"))

    def test_parse_repo_rejects_invalid_format(self) -> None:
        with self.assertRaises(SystemExit):
            pr_capture.parse_repo("owner/repo/extra")

    def test_parse_iso_date_handles_github_zulu_time(self) -> None:
        self.assertEqual(pr_capture.parse_iso_date("2026-05-15T17:10:00Z"), "2026-05-15")

    def test_format_linked_issues_can_hide_issue_bodies(self) -> None:
        output = pr_capture.format_linked_issues(
            [{"number": "2", "title": "Bug", "state": "OPEN", "body": "secret-ish details"}],
            include_body=False,
        )
        self.assertIn("#2: Bug", output)
        self.assertNotIn("secret-ish details", output)

    def test_format_diff_snippet_keeps_nearby_context(self) -> None:
        hunk = "\n".join(
            [
                "@@ -1,4 +1,4 @@",
                " line one",
                "-old two",
                "+new two",
                " line three",
                " line four",
            ]
        )
        output = pr_capture.format_diff_snippet(hunk, 2, context_lines=1)
        self.assertIn("+new two", output)
        self.assertIn(" line three", output)

    def test_build_markdown_honors_disabled_sections(self) -> None:
        markdown = pr_capture.build_markdown(
            pr_data={
                "number": 7,
                "title": "Test",
                "author": {"login": "alice"},
                "state": "OPEN",
                "createdAt": "2026-05-15T17:10:00Z",
                "baseRefName": "main",
                "headRefName": "feature",
            },
            files_list=["a.py"],
            linked_issues_data=[],
            ordered_sections=["overview", "files"],
            enabled_sections={"overview"},
            include_linked_issue_body=True,
        )
        self.assertIn("PR #7", markdown)
        self.assertNotIn("Files Changed", markdown)


if __name__ == "__main__":
    unittest.main()
