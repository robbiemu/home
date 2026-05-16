from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[1]
ZIP_PROJECT = ROOT / "install/bin/zip_project"
POB = ROOT / "install/bin/git-purge-old-branches"
GIT_BUMP = ROOT / "install/bin/git-bump"
BREW_ADMIN = ROOT / "install/bin/brew-admin"
INSTALLER = ROOT / "tools/install"
OBSIDIAN_AGENT = ROOT / "install/bin/obsidian-interlink-agent"
OBSIDIAN_CRON = ROOT / "install/bin/setup-obsidian-interlink-cron"
CONFIGURE_SAFESTART = ROOT / "tools/configure-git-safestart"


def run(command: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, text=True, capture_output=True, check=False)


def git(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return run(["git", *args], repo)


def init_repo(repo: Path) -> None:
    assert git(repo, "init", "-b", "main").returncode == 0
    git(repo, "config", "user.email", "test@example.com")
    git(repo, "config", "user.name", "Test User")
    (repo / "README.md").write_text("hello\n", encoding="utf-8")
    assert git(repo, "add", "README.md").returncode == 0
    assert git(repo, "commit", "-m", "init").returncode == 0


class ZipProjectTests(unittest.TestCase):
    def test_zip_project_filters_git_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)
            (repo / "app.py").write_text("print('hi')\n", encoding="utf-8")
            (repo / "notes.txt").write_text("skip\n", encoding="utf-8")
            (repo / ".gitignore").write_text("ignored.txt\n", encoding="utf-8")
            (repo / "ignored.txt").write_text("ignored\n", encoding="utf-8")

            result = run([str(ZIP_PROJECT), "--output", "bundle.zip", "--filter", "--force"], repo)

            self.assertEqual(result.returncode, 0, result.stderr)
            with zipfile.ZipFile(repo / "bundle.zip") as archive:
                names = set(archive.namelist())
            self.assertIn("README.md", names)
            self.assertIn("app.py", names)
            self.assertNotIn("notes.txt", names)
            self.assertNotIn("ignored.txt", names)

    def test_zip_project_refuses_overwrite_without_force(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)
            (repo / "bundle.zip").write_text("exists\n", encoding="utf-8")

            result = run([str(ZIP_PROJECT), "--output", "bundle.zip"], repo)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("already exists", result.stderr)

    def test_zip_project_force_does_not_include_previous_archive(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)
            (repo / "bundle.zip").write_text("old archive\n", encoding="utf-8")

            result = run([str(ZIP_PROJECT), "--output", "bundle.zip", "--force"], repo)

            self.assertEqual(result.returncode, 0, result.stderr)
            with zipfile.ZipFile(repo / "bundle.zip") as archive:
                names = set(archive.namelist())
            self.assertNotIn("bundle.zip", names)

    def test_zip_project_supports_absolute_output_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp) / "repo"
            repo.mkdir()
            init_repo(repo)
            output = Path(tmp) / "bundle.zip"

            result = run([str(ZIP_PROJECT), "--output", str(output)], repo)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(output.exists())


class GitPurgeOldBranchesTests(unittest.TestCase):
    def make_branch_with_date(self, repo: Path, branch: str, date: str) -> None:
        assert git(repo, "checkout", "-b", branch).returncode == 0
        (repo / f"{branch}.txt").write_text(branch, encoding="utf-8")
        assert git(repo, "add", f"{branch}.txt").returncode == 0
        env = {
            "GIT_AUTHOR_DATE": date,
            "GIT_COMMITTER_DATE": date,
        }
        result = subprocess.run(
            ["git", "commit", "-m", branch],
            cwd=repo,
            env={**os.environ, **env},
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        assert git(repo, "checkout", "main").returncode == 0

    def test_lists_old_unprotected_local_branch(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)
            self.make_branch_with_date(repo, "old-topic", "2001-01-01T00:00:00Z")
            self.make_branch_with_date(repo, "fresh-topic", "2030-01-01T00:00:00Z")

            result = run([str(POB), "--older-than", "1.year.ago"], repo)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("would-delete old-topic", result.stdout)
            self.assertNotIn("fresh-topic", result.stdout)

    def test_delete_uses_safe_branch_delete(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)
            self.make_branch_with_date(repo, "old-topic", "2001-01-01T00:00:00Z")
            assert git(repo, "merge", "--no-ff", "old-topic", "-m", "merge old").returncode == 0

            result = run([str(POB), "--older-than", "1.year.ago", "--delete"], repo)

            self.assertEqual(result.returncode, 0, result.stderr)
            branches = git(repo, "branch", "--format=%(refname:short)").stdout
            self.assertNotIn("old-topic", branches)

    def test_protected_branch_is_skipped(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)

            result = run([str(POB), "--older-than", "1.second.ago", "--protected", "main"], repo)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn("main", result.stdout)


class GitBumpTests(unittest.TestCase):
    def test_dry_run_uses_current_branch_and_default_workflow(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)

            result = run([str(GIT_BUMP), "--dry-run"], repo)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.strip(), "gh workflow run bump.yml --ref main")

    def test_dry_run_preserves_old_ref_label_shape(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)

            result = run([str(GIT_BUMP), "main", "release-1", "--dry-run"], repo)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                result.stdout.strip(),
                "gh workflow run bump.yml --ref main -f label=release-1",
            )

    def test_dry_run_uses_repo_config(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)
            git(repo, "config", "bump.workflow", "release.yml")
            git(repo, "config", "bump.labelInput", "version")

            result = run([str(GIT_BUMP), "main", "1.2.3", "--dry-run"], repo)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                result.stdout.strip(),
                "gh workflow run release.yml --ref main -f version=1.2.3",
            )

    def test_json_rejects_field_inputs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)

            result = run([str(GIT_BUMP), "--json", "inputs.json", "-f", "version=1"], repo)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("--json cannot be combined", result.stderr)


class BrewAdminTests(unittest.TestCase):
    def test_help_documents_required_account_variable(self) -> None:
        result = run([str(BREW_ADMIN), "--help"], ROOT)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("BREW_ADMIN_USER", result.stdout)

    def test_requires_explicit_account(self) -> None:
        env = {
            key: value
            for key, value in os.environ.items()
            if key not in {"BREW_ADMIN", "BREW_ADMIN_USER", "BREW_ADMIN_HOME"}
        }
        result = subprocess.run(
            [str(BREW_ADMIN), "--prefix"],
            cwd=ROOT,
            env=env,
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Set BREW_ADMIN_USER", result.stderr)


class ZshTemplateTests(unittest.TestCase):
    def run_brave_switch_with_fake_keychain(
        self, search_key: str | None, inference_key: str | None
    ) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as tmp:
            fake_bin = Path(tmp) / "bin"
            fake_bin.mkdir()
            security = fake_bin / "security"
            search_result = f"printf %s\\\\n {search_key!r}" if search_key else "exit 44"
            inference_result = (
                f"printf %s\\\\n {inference_key!r}" if inference_key else "exit 44"
            )
            security.write_text(
                f"""#!/usr/bin/env bash
label=""
while (($#)); do
  case "$1" in
    -l)
      shift
      label="$1"
      ;;
  esac
  shift || true
done

case "$label" in
  "Brave Search api key")
    {search_result}
    ;;
  "Brave Search Inference api key")
    {inference_result}
    ;;
  *)
    exit 45
    ;;
esac
""",
                encoding="utf-8",
            )
            security.chmod(0o755)
            env = {
                **os.environ,
                "PATH": f"{fake_bin}:{os.environ.get('PATH', '')}",
            }

            return subprocess.run(
                [
                    "zsh",
                    "-fc",
                    (
                        "source dotfiles/zshrc.d/brave.zsh; "
                        "brave-switch; "
                        "print -r -- ${BRAVE_SEARCH_API_KEY:-}"
                    ),
                ],
                cwd=ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )

    def test_brave_switch_uses_single_standard_key(self) -> None:
        result = self.run_brave_switch_with_fake_keychain("search-only-key", None)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Set Brave standard SEARCH key.", result.stdout)
        self.assertEqual(result.stdout.strip().splitlines()[-1], "search-only-key")

    def test_brave_switch_uses_single_inference_key(self) -> None:
        result = self.run_brave_switch_with_fake_keychain(None, "inference-only-key")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Set Brave INFERENCE key.", result.stdout)
        self.assertEqual(result.stdout.strip().splitlines()[-1], "inference-only-key")


class InstallerTests(unittest.TestCase):
    def test_user_dry_run_installs_home_bin_tools(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            user_bin = Path(tmp) / "bin"

            result = run([str(INSTALLER), "--dry-run", "--user-bin", str(user_bin)], ROOT)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("install/bin/sort_mypy.py", result.stdout)
            self.assertIn(str(user_bin / "sort_mypy.py"), result.stdout)
            self.assertIn("install/bin/pr_capture.py", result.stdout)

    def test_local_dry_run_installs_git_pob_alias(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            prefix = Path(tmp) / "local"

            result = run(
                [
                    str(INSTALLER),
                    "--dry-run",
                    "--local",
                    "--only",
                    "git-purge-old-branches",
                    "--local-prefix",
                    str(prefix),
                ],
                ROOT,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("install/bin/git-purge-old-branches", result.stdout)
            self.assertIn(str(prefix / "bin/git-pob"), result.stdout)
            self.assertNotIn("brew-admin.sh", result.stdout)

    def test_dotfiles_dry_run_uses_home_and_backup(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            home.mkdir()
            (home / ".zshrc").write_text("old\n", encoding="utf-8")

            result = run([str(INSTALLER), "--dry-run", "--dotfiles", "--home", str(home)], ROOT)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("home-repo-backups", result.stdout)
            self.assertIn(str(home / ".zshrc"), result.stdout)
            self.assertIn("generate-zshrc .zshrc", result.stdout)
            self.assertIn("install -m 0644 .gitconfig", result.stdout)
            self.assertNotIn("install -m 0644 .zshrc", result.stdout)

    def test_dotfiles_dry_run_writes_explicit_machine_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            pub = Path(tmp) / "public-root"
            vault = Path(tmp) / "vault"
            pub.mkdir()
            vault.mkdir()
            env = {
                **{
                    key: value
                    for key, value in os.environ.items()
                    if key not in {"GH", "HF", "PICO_GCC_PATH", "PICO_TOOLCHAIN_PATH", "PICO_SDK_PATH"}
                },
                "PUB": str(pub),
                "OBSIDIAN_VAULT_DIR": str(vault),
            }

            result = subprocess.run(
                [str(INSTALLER), "--dry-run", "--dotfiles", "--home", str(home)],
                cwd=ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("paths.zsh", result.stdout)
            self.assertIn("export PUB=", result.stdout)
            self.assertIn(str(pub), result.stdout)
            self.assertIn("export OBSIDIAN_VAULT_DIR=", result.stdout)
            self.assertIn(str(vault), result.stdout)
            self.assertIn("export HOME_REPO_ZSH_TEMPLATES=", result.stdout)
            self.assertIn("shared-workspaces", result.stdout)
            self.assertIn("agentic-obsidian", result.stdout)

    def test_dotfiles_prompt_skips_unconfigured_zsh_sections(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            missing_pub = Path(tmp) / "missing-public"
            env = {
                "HOME": str(home),
                "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
                "PUB": str(missing_pub),
            }

            result = subprocess.run(
                [str(INSTALLER), "--dry-run", "--dotfiles", "--prompt", "--home", str(home)],
                cwd=ROOT,
                env=env,
                input="",
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Configure nvm", result.stderr)
            self.assertIn("inject zsh templates: none", result.stdout)
            self.assertNotIn("HOME_REPO_ZSH_TEMPLATES", result.stdout)

    def test_dotfiles_zsh_section_persists_requested_template(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            env = {
                "HOME": str(home),
                "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
            }

            result = subprocess.run(
                [
                    str(INSTALLER),
                    "--dry-run",
                    "--dotfiles",
                    "--home",
                    str(home),
                    "--zsh-section",
                    "nvm",
                ],
                cwd=ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("export HOME_REPO_ZSH_TEMPLATES=nvm", result.stdout)
            self.assertIn("  nvm", result.stdout)
            self.assertNotIn("python-user-bin", result.stdout)

    def test_dotfiles_install_generates_zshrc_from_requested_templates(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            env = {
                "HOME": str(home),
                "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
            }

            result = subprocess.run(
                [
                    str(INSTALLER),
                    "--dotfiles",
                    "--home",
                    str(home),
                    "--zsh-section",
                    "nvm",
                ],
                cwd=ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            generated = (home / ".zshrc").read_text(encoding="utf-8")
            self.assertIn("# --- home repo template: nvm ---", generated)
            self.assertIn('export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"', generated)
            self.assertNotIn("# --- home repo template: python-user-bin ---", generated)

    def test_dotfiles_prompt_can_set_missing_obsidian_path(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            vault = Path(tmp) / "future-vault"
            existing = {
                name: Path(tmp) / name.lower()
                for name in [
                    "PUB",
                    "GH",
                    "HF",
                    "PICO_GCC_PATH",
                    "PICO_TOOLCHAIN_PATH",
                    "PICO_SDK_PATH",
                    "ZEPHYR_SDK_INSTALL_DIR",
                    "ZEPHYR_BASE",
                ]
            }
            for path in existing.values():
                path.mkdir(parents=True)
            env = {
                key: value
                for key, value in os.environ.items()
                if key
                not in {
                    "PUB",
                    "GH",
                    "HF",
                    "PICO_GCC_PATH",
                    "PICO_TOOLCHAIN_PATH",
                    "PICO_SDK_PATH",
                    "ZEPHYR_SDK_INSTALL_DIR",
                    "ZEPHYR_BASE",
                    "OBSIDIAN_VAULT_DIR",
                    "AGENTIC_ONE_OFF_CMD",
                }
            }
            env.update({name: str(path) for name, path in existing.items()})
            env["AGENTIC_RUNTIME"] = "sh"
            env["AGENTIC_ONE_OFF_CMD"] = "cat"

            result = subprocess.run(
                [str(INSTALLER), "--dry-run", "--dotfiles", "--prompt", "--home", str(home)],
                cwd=ROOT,
                env=env,
                input=str(vault) + "\n",
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Obsidian vault directory", result.stderr)
            self.assertIn("export OBSIDIAN_VAULT_DIR=", result.stdout)
            self.assertIn(str(vault), result.stdout)

    def test_dotfiles_prompt_can_skip_dependent_workspace_directories(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            missing_pub = Path(tmp) / "missing-public"
            env = {
                key: value
                for key, value in os.environ.items()
                if key
                not in {
                    "PUB",
                    "GH",
                    "HF",
                    "PICO_GCC_PATH",
                    "PICO_TOOLCHAIN_PATH",
                    "PICO_SDK_PATH",
                    "ZEPHYR_SDK_INSTALL_DIR",
                    "ZEPHYR_BASE",
                    "ZEPHYR_TOOLCHAIN_VARIANT",
                    "AGENTIC_ONE_OFF_CMD",
                    "OBSIDIAN_VAULT_DIR",
                }
            }
            env["PUB"] = str(missing_pub)

            result = subprocess.run(
                [str(INSTALLER), "--dry-run", "--dotfiles", "--prompt", "--home", str(home)],
                cwd=ROOT,
                env=env,
                input="\nn\nn\nn\nn\n",
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Configure GitHub/Hugging Face workspace directories", result.stderr)
            self.assertNotIn("GitHub workspace directory path", result.stderr)
            self.assertNotIn("Hugging Face workspace directory path", result.stderr)
            self.assertNotIn("export GH=", result.stdout)
            self.assertNotIn("export HF=", result.stdout)


class ConfigureGitSafestartTests(unittest.TestCase):
    def test_prompts_for_missing_default_command(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)

            result = subprocess.run(
                [str(CONFIGURE_SAFESTART), "--repo", str(repo), "--prompt", "--dry-run"],
                input="make run\n\n\n",
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("safestart.command", result.stdout)
            self.assertIn("make\\ run", result.stdout)

    def test_blank_default_command_skips_configuration(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)

            result = subprocess.run(
                [str(CONFIGURE_SAFESTART), "--repo", str(repo), "--prompt", "--dry-run"],
                input="\n",
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0)
            self.assertIn("no default command configured", result.stderr)


class ObsidianInterlinkAgentTests(unittest.TestCase):
    def test_runner_skips_when_runtime_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            vault = Path(tmp) / "vault"
            vault.mkdir()
            (vault / "note.md").write_text("# Note\n", encoding="utf-8")
            env = {
                **os.environ,
                "AGENTIC_RUNTIME": "definitely-missing-agentic-runtime",
                "AGENTIC_ONE_OFF_CMD": "cat",
                "OBSIDIAN_VAULT_DIR": str(vault),
                "HOME_REPO_AGENTIC_ENV": str(Path(tmp) / "missing.env"),
            }

            result = subprocess.run(
                [str(OBSIDIAN_AGENT)],
                cwd=ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0)
            self.assertIn("runtime not found", result.stderr)

    def test_runner_dry_run_mentions_prompt_execution(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            vault = Path(tmp) / "vault"
            vault.mkdir()
            (vault / "note.md").write_text("# Note\n", encoding="utf-8")
            env = {
                **os.environ,
                "AGENTIC_RUNTIME": "sh",
                "AGENTIC_ONE_OFF_CMD": "cat",
                "OBSIDIAN_VAULT_DIR": str(vault),
                "HOME_REPO_AGENTIC_ENV": str(Path(tmp) / "missing.env"),
            }

            result = subprocess.run(
                [str(OBSIDIAN_AGENT), "--dry-run"],
                cwd=ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(str(vault), result.stdout)
            self.assertIn("bash -lc cat", result.stdout)

    def test_cron_setup_skips_when_runtime_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            vault = Path(tmp) / "vault"
            vault.mkdir()
            env_file = Path(tmp) / "agentic.env"

            result = run(
                [
                    str(OBSIDIAN_CRON),
                    "--dry-run",
                    "--runner",
                    str(OBSIDIAN_AGENT),
                    "--runtime",
                    "definitely-missing-agentic-runtime",
                    "--one-off-cmd",
                    "cat",
                    "--vault",
                    str(vault),
                    "--env-file",
                    str(env_file),
                ],
                ROOT,
            )

            self.assertEqual(result.returncode, 0)
            self.assertIn("runtime not found", result.stderr)

    def test_cron_setup_dry_run_outputs_managed_cron_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            vault = Path(tmp) / "vault"
            vault.mkdir()
            env_file = Path(tmp) / "agentic.env"
            log_file = Path(tmp) / "agent.log"

            result = run(
                [
                    str(OBSIDIAN_CRON),
                    "--dry-run",
                    "--runner",
                    str(OBSIDIAN_AGENT),
                    "--runtime",
                    "sh",
                    "--one-off-cmd",
                    "cat",
                    "--vault",
                    str(vault),
                    "--env-file",
                    str(env_file),
                    "--log-file",
                    str(log_file),
                ],
                ROOT,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("write", result.stdout)
            self.assertIn("home-repo: obsidian-interlink-agent", result.stdout)
            self.assertIn(str(OBSIDIAN_AGENT), result.stdout)

    def test_cron_setup_prompt_fills_missing_one_off_command(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            vault = Path(tmp) / "vault"
            vault.mkdir()
            env_file = Path(tmp) / "agentic.env"
            log_file = Path(tmp) / "agent.log"

            result = subprocess.run(
                [
                    str(OBSIDIAN_CRON),
                    "--dry-run",
                    "--prompt",
                    "--runner",
                    str(OBSIDIAN_AGENT),
                    "--runtime",
                    "sh",
                    "--vault",
                    str(vault),
                    "--env-file",
                    str(env_file),
                    "--log-file",
                    str(log_file),
                ],
                input="cat\n",
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("AGENTIC_ONE_OFF_CMD", result.stdout)
            self.assertIn("install cron line", result.stdout)


if __name__ == "__main__":
    unittest.main()
