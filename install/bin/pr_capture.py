#!/usr/bin/env python3
"""Capture GitHub pull request context into a Markdown file."""

from __future__ import annotations

import argparse
from datetime import datetime
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any


APP_VERSION = "1.8"
HEADING_MARKER_FORMAT = "§ {text}"
SECTIONS = [
    "overview",
    "description",
    "linked_issues",
    "files",
    "reviews",
    "comments",
    "commits",
]


def create_heading(level: int, text: str) -> str:
    return f"{'#' * level} {HEADING_MARKER_FORMAT.format(text=text)}"


def run_command(command: list[str], check: bool = True) -> str:
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            check=False,
            encoding="utf-8",
            text=True,
        )
    except FileNotFoundError:
        raise SystemExit(
            f"Error: command '{command[0]}' was not found. Install GitHub CLI first."
        )

    if check and result.returncode != 0:
        stderr = result.stderr.strip()
        raise SystemExit(
            "Error: command failed "
            f"(exit {result.returncode}): {' '.join(command)}"
            + (f"\n{stderr}" if stderr else "")
        )

    return result.stdout.strip()


def require_gh_auth() -> None:
    if shutil.which("gh") is None:
        raise SystemExit("Error: GitHub CLI 'gh' is required.")
    run_command(["gh", "auth", "status"])


def parse_repo(repo: str) -> tuple[str, str]:
    parts = repo.split("/")
    if len(parts) != 2 or not all(parts):
        raise SystemExit("Error: --repo must use OWNER/REPO format.")
    return parts[0], parts[1]


def parse_iso_date(date_str: str | None, fmt: str = "%Y-%m-%d") -> str:
    if not date_str:
        return "N/A"
    normalized = date_str[:-1] + "+00:00" if date_str.endswith("Z") else date_str
    return datetime.fromisoformat(normalized).strftime(fmt)


def fetch_pr_data(repo: str, pr_number: int) -> dict[str, Any]:
    owner, repo_name = parse_repo(repo)
    graphql_query = """
    query($owner: String!, $repo: String!, $pr: Int!) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $pr) {
          title
          body
          author { login }
          assignees(first: 10) { nodes { login } }
          labels(first: 20) { nodes { name } }
          milestone { title }
          createdAt
          updatedAt
          mergedAt
          closedAt
          state
          baseRefName
          headRefName
          reviewRequests(first: 10) { nodes { requestedReviewer { ... on User { login } } } }
          comments(first: 100) {
            nodes {
              author { login }
              createdAt
              body
            }
          }
          reviews(first: 50) {
            nodes {
              author { login }
              state
              body
              comments(first: 50) {
                nodes {
                  path
                  position
                  originalPosition
                  diffHunk
                  body
                }
              }
            }
          }
          commits(first: 100) {
            nodes {
              commit {
                oid
                messageHeadline
              }
            }
          }
        }
      }
    }
    """
    response_json = run_command(
        [
            "gh",
            "api",
            "graphql",
            "-f",
            f"owner={owner}",
            "-f",
            f"repo={repo_name}",
            "-F",
            f"pr={pr_number}",
            "--raw-field",
            f"query={graphql_query}",
        ]
    )
    data = json.loads(response_json)
    pr_data = data.get("data", {}).get("repository", {}).get("pullRequest")
    if not pr_data:
        raise SystemExit(f"Error: PR #{pr_number} was not found in {repo}.")
    pr_data["number"] = pr_number
    return pr_data


def fetch_pr_files(repo: str, pr_number: int) -> list[str]:
    files = run_command(["gh", "pr", "diff", str(pr_number), "--repo", repo, "--name-only"])
    return files.splitlines() if files else []


def fetch_pr_diff(repo: str, pr_number: int) -> str:
    return run_command(["gh", "pr", "diff", str(pr_number), "--repo", repo])


def fetch_linked_issues_data(
    repo: str, pr_body: str | None, debug: bool = False
) -> list[dict[str, Any]]:
    body = pr_body or ""
    issue_numbers = {
        *re.findall(r"#(\d+)", body),
        *re.findall(rf"https?://github\.com/{re.escape(repo)}/issues/(\d+)", body),
    }
    if debug:
        print(f"[DEBUG] linked issue numbers: {sorted(issue_numbers, key=int)}")

    issues_data: list[dict[str, Any]] = []
    for number in sorted(issue_numbers, key=int):
        issue_json = run_command(
            [
                "gh",
                "issue",
                "view",
                number,
                "--repo",
                repo,
                "--json",
                "title,state,body",
            ],
            check=False,
        )
        if not issue_json:
            continue
        try:
            issue = json.loads(issue_json)
        except json.JSONDecodeError:
            print(f"Warning: could not parse JSON for issue #{number}", file=sys.stderr)
            continue
        issue["number"] = number
        issues_data.append(issue)
    return issues_data


def format_overview(data: dict[str, Any], **_: Any) -> str:
    author = (data.get("author") or {}).get("login", "ghost")
    lines = [
        f"# PR #{data.get('number', 'N/A')}: {data.get('title', 'N/A')}",
        "",
        create_heading(2, "Overview"),
        f"- **Author:** @{author}",
        f"- **Status:** {data.get('state', 'N/A').lower()}",
        f"- **Created:** {parse_iso_date(data.get('createdAt'))}",
    ]
    if data.get("mergedAt"):
        lines.append(f"- **Merged:** {parse_iso_date(data.get('mergedAt'))}")
    lines.append(
        f"- **Base:** {data.get('baseRefName', 'N/A')} <- "
        f"**Head:** {data.get('headRefName', 'N/A')}"
    )
    return "\n".join(lines)


def format_description(data: dict[str, Any], **_: Any) -> str:
    body = data.get("body")
    if not body or not body.strip():
        return f"{create_heading(2, 'Description')}\n\n_No description provided._"
    return f"{create_heading(2, 'Description')}\n\n{body}"


def format_linked_issues(
    issues_data: list[dict[str, Any]], include_body: bool = True, **_: Any
) -> str:
    if not issues_data:
        return ""
    lines = [create_heading(2, "Linked Issues")]
    for issue in issues_data:
        lines.append(
            f"- **#{issue['number']}: {issue.get('title', 'N/A')}** "
            f"({issue.get('state', 'N/A')})"
        )
        body = issue.get("body")
        if include_body and body and body.strip():
            lines.append("\n".join(f"  {line}" for line in body.splitlines()))
        lines.append("")
    return "\n".join(lines).rstrip()


def format_files(files_list: list[str], **_: Any) -> str:
    if not files_list:
        return ""
    return "\n".join(
        [create_heading(2, f"Files Changed ({len(files_list)} files)")]
        + [f"- `{file}`" for file in files_list]
    )


def format_diff_snippet(diff_hunk: str, position: int, context_lines: int = 2) -> str:
    lines = diff_hunk.split("\n")
    if not lines:
        return ""

    match = re.search(r"\+([0-9]+)", lines[0])
    if not match:
        return "\n".join(lines[: context_lines * 2 + 1])

    current_file_line = int(match.group(1)) - 1
    target_hunk_index = -1
    for index, line in enumerate(lines[1:], 1):
        if line.startswith("+") or line.startswith(" "):
            current_file_line += 1
        if current_file_line == position:
            target_hunk_index = index
            break

    if target_hunk_index == -1:
        return "(Could not locate the specific line in the diff hunk)\n" + "\n".join(
            lines[:5]
        )

    start = max(1, target_hunk_index - context_lines)
    end = min(len(lines), target_hunk_index + context_lines + 1)
    snippet_lines = lines[start:end]
    if start > 1:
        snippet_lines.insert(0, "...")
    if end < len(lines):
        snippet_lines.append("...")
    return "\n".join(snippet_lines)


def format_reviews(data: dict[str, Any], **_: Any) -> str:
    reviews = [
        review
        for review in data.get("reviews", {}).get("nodes", [])
        if review.get("comments", {}).get("nodes")
    ]
    if not reviews:
        return ""

    lines = [create_heading(2, "Code Review Comments")]
    for review in reviews:
        state = review.get("state", "COMMENTED").replace("_", " ").title()
        author = (review.get("author") or {}).get("login", "ghost")
        lines.append(create_heading(3, f"Review by @{author} ({state})"))
        if review.get("body"):
            lines.append(f"> {review['body']}\n")

        for comment in review["comments"]["nodes"]:
            position = comment.get("position") or comment.get("originalPosition")
            diff_hunk = comment.get("diffHunk", "")
            if position and diff_hunk.strip():
                lines.append(f"**File:** `{comment['path']}:{position}`")
                lines.append("**Context:**")
                lines.append(f"```diff\n{format_diff_snippet(diff_hunk, position)}\n```")
            else:
                lines.append(f"**File:** `{comment['path']}` (File-level comment)")
            lines.append(f"**Comment:** {comment['body']}\n")
        lines.append("")

    return "\n".join(lines).rstrip()


def format_comments(data: dict[str, Any], **_: Any) -> str:
    comments = data.get("comments", {}).get("nodes", [])
    if not comments:
        return ""
    lines = [create_heading(2, "General Comments")]
    for comment in comments:
        author = (comment.get("author") or {}).get("login", "ghost")
        timestamp = parse_iso_date(comment["createdAt"], "%Y-%m-%d %H:%M")
        lines.append(create_heading(3, f"@{author} - {timestamp}"))
        lines.append(f"{comment['body']}\n")
    return "\n".join(lines).rstrip()


def format_commits(data: dict[str, Any], **_: Any) -> str:
    commits = data.get("commits", {}).get("nodes", [])
    if not commits:
        return ""
    lines = [create_heading(2, f"Commits ({len(commits)} commits)")]
    for node in commits:
        commit = node.get("commit", {})
        lines.append(
            f"- `{commit.get('oid', '-------')[:7]}`: "
            f"{commit.get('messageHeadline', 'No commit message')}"
        )
    return "\n".join(lines)


def format_diff(diff_text: str, **_: Any) -> str:
    if not diff_text:
        return ""
    return f"{create_heading(2, 'PR Diff')}\n\n```diff\n{diff_text}\n```"


FORMATTERS = {
    "overview": format_overview,
    "description": format_description,
    "linked_issues": format_linked_issues,
    "files": format_files,
    "reviews": format_reviews,
    "comments": format_comments,
    "commits": format_commits,
}


def build_markdown(
    pr_data: dict[str, Any],
    files_list: list[str],
    linked_issues_data: list[dict[str, Any]],
    ordered_sections: list[str],
    enabled_sections: set[str],
    include_linked_issue_body: bool,
    diff_text: str | None = None,
) -> str:
    all_data = {
        "data": pr_data,
        "files_list": files_list,
        "issues_data": linked_issues_data,
        "include_body": include_linked_issue_body,
    }
    parts: list[str] = []
    for section in ordered_sections:
        if section not in enabled_sections:
            continue
        formatter = FORMATTERS[section]
        if section == "linked_issues":
            part = formatter(
                issues_data=linked_issues_data,
                include_body=include_linked_issue_body,
            )
        else:
            part = formatter(**all_data)
        if part:
            parts.append(part)

    if diff_text:
        parts.append(format_diff(diff_text))
    return "\n\n".join(parts)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Capture GitHub PR context as Markdown.",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument("--repo", required=True, help="Repository in OWNER/REPO format.")
    parser.add_argument("--pr", dest="pr_number", required=True, type=int)
    parser.add_argument("--output", help="Output path. Defaults to pr-{number}-summary.md.")
    parser.add_argument(
        "--order",
        default=",".join(SECTIONS),
        help=f"Comma-separated section order. Available: {', '.join(SECTIONS)}",
    )
    parser.add_argument("--debug", action="store_true")
    parser.add_argument("--include-diff", action="store_true")
    parser.add_argument(
        "--linked-issues-title-only",
        action="store_true",
        help="Show linked issue titles without issue bodies.",
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {APP_VERSION}")
    for section in SECTIONS:
        parser.add_argument(
            f"--no-{section.replace('_', '-')}",
            dest=section,
            action="store_false",
            default=True,
            help=f"Disable the '{section.replace('_', ' ')}' section.",
        )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    ordered_sections = [section.strip() for section in args.order.split(",") if section.strip()]
    invalid_sections = [section for section in ordered_sections if section not in SECTIONS]
    if invalid_sections:
        raise SystemExit(
            "Error: invalid section(s): "
            f"{', '.join(invalid_sections)}. Available: {', '.join(SECTIONS)}"
        )

    require_gh_auth()
    pr_data = fetch_pr_data(args.repo, args.pr_number)
    files_list = fetch_pr_files(args.repo, args.pr_number)
    linked_issues = fetch_linked_issues_data(args.repo, pr_data.get("body"), args.debug)
    diff_text = fetch_pr_diff(args.repo, args.pr_number) if args.include_diff else None

    enabled_sections = {
        section for section in SECTIONS if getattr(args, section)
    }
    markdown = build_markdown(
        pr_data=pr_data,
        files_list=files_list,
        linked_issues_data=linked_issues,
        ordered_sections=ordered_sections,
        enabled_sections=enabled_sections,
        include_linked_issue_body=not args.linked_issues_title_only,
        diff_text=diff_text,
    )

    output_path = Path(args.output or f"pr-{args.pr_number}-summary.md")
    output_path.write_text(markdown, encoding="utf-8")
    print(f"Saved PR summary to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
