#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import sys
import unittest


HOOK_DIRECTORY = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location("pre_tool_use_policy", HOOK_DIRECTORY / "pre_tool_use_policy.py")
assert SPEC and SPEC.loader
POLICY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(POLICY)


class PreToolUsePolicyTests(unittest.TestCase):
    def test_fixtures(self) -> None:
        repository_root = HOOK_DIRECTORY.parents[1]
        cases = json.loads((HOOK_DIRECTORY / "fixtures/pre_tool_use_cases.json").read_text())
        for case in cases:
            with self.subTest(case=case["name"]):
                violation = POLICY.violation_for(case["command"], repository_root)
                self.assertEqual(violation is not None, case["violation"])

    def test_outside_repository_is_ignored(self) -> None:
        repository_root = HOOK_DIRECTORY.parents[1]
        payload = {
            "hook_event_name": "PreToolUse",
            "tool_name": "Bash",
            "cwd": "/tmp",
            "tool_input": {"command": "xcodebuild test"},
        }
        self.assertIsNone(POLICY.inspect_payload(payload, repository_root))

    def test_non_bash_is_ignored(self) -> None:
        repository_root = HOOK_DIRECTORY.parents[1]
        payload = {
            "hook_event_name": "PreToolUse",
            "tool_name": "apply_patch",
            "cwd": str(repository_root),
            "tool_input": {"command": "xcodebuild test"},
        }
        self.assertIsNone(POLICY.inspect_payload(payload, repository_root))


if __name__ == "__main__":
    unittest.main()
