#!/usr/bin/env python3
"""Sort mypy-style diagnostic blocks by path and line number."""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from typing import Iterable


HEADER_RE = re.compile(r"^(?P<path>[^:\n]+):(?P<line>\d+):")


@dataclass(frozen=True)
class Block:
    lines: list[str]
    sort_key: tuple[str, int] | None


def split_blocks(lines: Iterable[str]) -> list[Block]:
    """Group diagnostic output into header-led blocks.

    Mypy and several Python tools emit diagnostics as:

        path/to/file.py:123: error: ...
            additional context

    Non-diagnostic prelude lines are preserved before sorted diagnostics.
    """
    blocks: list[Block] = []
    current_lines: list[str] = []
    current_key: tuple[str, int] | None = None

    def flush() -> None:
        nonlocal current_lines, current_key
        if current_lines:
            blocks.append(Block(current_lines, current_key))
            current_lines = []
            current_key = None

    for raw_line in lines:
        line = raw_line.rstrip("\n")
        match = HEADER_RE.match(line)
        if match:
            flush()
            current_lines = [line]
            current_key = (match.group("path"), int(match.group("line")))
        elif current_lines:
            current_lines.append(line)
        elif line:
            current_lines = [line]
            current_key = None

    flush()
    return blocks


def sort_blocks(blocks: Iterable[Block]) -> list[Block]:
    prelude: list[Block] = []
    diagnostics: list[Block] = []

    for block in blocks:
        if block.sort_key is None:
            prelude.append(block)
        else:
            diagnostics.append(block)

    return prelude + sorted(diagnostics, key=lambda block: block.sort_key)


def format_blocks(blocks: Iterable[Block]) -> str:
    lines: list[str] = []
    for block in blocks:
        lines.extend(block.lines)
    return "\n".join(lines)


def sort_output(text: str) -> str:
    sorted_text = format_blocks(sort_blocks(split_blocks(text.splitlines())))
    return f"{sorted_text}\n" if sorted_text else ""


def main() -> int:
    sys.stdout.write(sort_output(sys.stdin.read()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
