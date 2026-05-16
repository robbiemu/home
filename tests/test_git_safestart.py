from __future__ import annotations

from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "install/bin/git-safestart"
CO_SCRIPT = ROOT / "install/bin/git-co"


def run(command: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, text=True, capture_output=True, check=False)


class GitSafestartTests(unittest.TestCase):
    def test_dry_run_uses_local_config(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            self.assertEqual(run(["git", "init", "-b", "main"], repo).returncode, 0)
            run(["git", "config", "user.email", "test@example.com"], repo)
            run(["git", "config", "user.name", "Test User"], repo)
            (repo / "README.md").write_text("test\n", encoding="utf-8")
            self.assertEqual(run(["git", "add", "README.md"], repo).returncode, 0)
            self.assertEqual(run(["git", "commit", "-m", "init"], repo).returncode, 0)
            self.assertEqual(
                run(["git", "config", "--local", "safestart.command", "make serve"], repo).returncode,
                0,
            )
            self.assertEqual(
                run(["git", "config", "--local", "safestart.safeBranchPattern", "safe/{branch}"], repo).returncode,
                0,
            )
            self.assertEqual(
                run(["git", "config", "--local", "--add", "safestart.submodule", "common"], repo).returncode,
                0,
            )

            result = run([str(SCRIPT), "--branch", "main", "--dry-run"], repo)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("+ git checkout main", result.stdout)
            self.assertIn("+ git submodule update --init --recursive", result.stdout)
            self.assertIn("+ git -C common checkout safe/main", result.stdout)
            self.assertIn("+ bash -lc make\\ serve", result.stdout)

    def test_requires_git_repo(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result = run([str(SCRIPT), "--dry-run"], Path(tmp))

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("run inside a git repository", result.stderr)

    def test_dry_run_without_submodules_is_valid(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            self.assertEqual(run(["git", "init", "-b", "main"], repo).returncode, 0)
            run(["git", "config", "user.email", "test@example.com"], repo)
            run(["git", "config", "user.name", "Test User"], repo)
            (repo / "README.md").write_text("test\n", encoding="utf-8")
            self.assertEqual(run(["git", "add", "README.md"], repo).returncode, 0)
            self.assertEqual(run(["git", "commit", "-m", "init"], repo).returncode, 0)

            result = run([str(SCRIPT), "--dry-run", "--no-run"], repo)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("+ git submodule update --init --recursive", result.stdout)

    def test_git_co_wraps_safestart_without_running_command(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            self.assertEqual(run(["git", "init", "-b", "main"], repo).returncode, 0)
            run(["git", "config", "user.email", "test@example.com"], repo)
            run(["git", "config", "user.name", "Test User"], repo)
            (repo / "README.md").write_text("test\n", encoding="utf-8")
            self.assertEqual(run(["git", "add", "README.md"], repo).returncode, 0)
            self.assertEqual(run(["git", "commit", "-m", "init"], repo).returncode, 0)
            run(["git", "config", "--local", "safestart.command", "make serve"], repo)
            run(["git", "config", "--local", "--add", "safestart.submodule", "common"], repo)

            result = run([str(CO_SCRIPT), "main", "--dry-run"], repo)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("+ git checkout main", result.stdout)
            self.assertIn("+ git -C common checkout main", result.stdout)
            self.assertNotIn("bash -lc", result.stdout)


if __name__ == "__main__":
    unittest.main()
