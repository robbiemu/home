from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("sort_mypy", ROOT / "install/bin/sort_mypy.py")
sort_mypy = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = sort_mypy
SPEC.loader.exec_module(sort_mypy)


class SortMypyTests(unittest.TestCase):
    def test_sorts_diagnostic_blocks_by_path_and_line(self) -> None:
        text = "\n".join(
            [
                "b.py:20: error: later",
                "    context b",
                "a.py:10: error: earlier",
                "    context a",
                "",
            ]
        )

        self.assertEqual(
            sort_mypy.sort_output(text),
            "\n".join(
                [
                    "a.py:10: error: earlier",
                    "    context a",
                    "b.py:20: error: later",
                    "    context b",
                    "",
                ]
            ),
        )

    def test_preserves_non_diagnostic_prelude(self) -> None:
        text = "\n".join(
            [
                "mypy output follows",
                "z.py:3: error: z",
                "a.py:1: error: a",
                "",
            ]
        )

        self.assertEqual(
            sort_mypy.sort_output(text),
            "\n".join(
                [
                    "mypy output follows",
                    "a.py:1: error: a",
                    "z.py:3: error: z",
                    "",
                ]
            ),
        )


if __name__ == "__main__":
    unittest.main()
