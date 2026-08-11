#!/usr/bin/env python3
"""Advises or blocks a small set of deterministic shell-policy violations."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import shlex
import sys
from typing import Any


ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=.*$")


def split_commands(command: str) -> list[str]:
    """Split common shell command separators without evaluating shell syntax."""
    commands: list[str] = []
    current: list[str] = []
    quote: str | None = None
    escaped = False

    for character in command:
        if escaped:
            current.append(character)
            escaped = False
            continue
        if character == "\\" and quote != "'":
            current.append(character)
            escaped = True
            continue
        if quote:
            current.append(character)
            if character == quote:
                quote = None
            continue
        if character in {"'", '"'}:
            quote = character
            current.append(character)
            continue
        if character in {";", "\n", "&", "|"}:
            candidate = "".join(current).strip()
            if candidate:
                commands.append(candidate)
            current = []
            continue
        current.append(character)

    candidate = "".join(current).strip()
    if candidate:
        commands.append(candidate)
    return commands


def command_tokens(segment: str) -> list[str]:
    try:
        tokens = shlex.split(segment, posix=True)
    except ValueError:
        return []

    while tokens and ASSIGNMENT.match(tokens[0]):
        tokens.pop(0)
    if tokens and Path(tokens[0]).name == "sudo":
        tokens.pop(0)
        while tokens and tokens[0].startswith("-"):
            tokens.pop(0)
    if tokens and Path(tokens[0]).name == "env":
        tokens.pop(0)
        while tokens and (tokens[0].startswith("-") or ASSIGNMENT.match(tokens[0])):
            tokens.pop(0)
    return tokens


def violation_for(command: str, repository_root: Path) -> str | None:
    for segment in split_commands(command):
        tokens = command_tokens(segment)
        if not tokens:
            continue

        executable = Path(tokens[0]).name
        arguments = tokens[1:]
        if executable == "xcodebuild":
            return "Use Xcode MCP; repository policy forbids xcodebuild."

        if executable == "git" and arguments:
            subcommand = next((item for item in arguments if not item.startswith("-")), None)
            if subcommand == "reset" and "--hard" in arguments:
                return "git reset --hard is destructive and requires an explicit, separate decision."
            if subcommand == "clean":
                options = "".join(item.lstrip("-") for item in arguments if item.startswith("-"))
                if "f" in options and ("d" in options or "x" in options):
                    return "Forced recursive git clean is destructive and not permitted by the repository workflow."
            if subcommand == "checkout" and "--" in arguments:
                return "git checkout -- can discard local work and requires explicit target verification."
            if subcommand == "restore" and any(not item.startswith("-") and item != "restore" for item in arguments):
                return "git restore can discard local work and requires explicit target verification."

        if executable == "rm":
            options = "".join(item.lstrip("-") for item in arguments if item.startswith("-"))
            targets = [item for item in arguments if not item.startswith("-")]
            broad_targets = {"/", "~", "$HOME", "${HOME}", str(repository_root)}
            if "r" in options and "f" in options and broad_targets.intersection(targets):
                return "Recursive forced deletion of a broad literal target is prohibited."
    return None


def inspect_payload(payload: Any, repository_root: Path) -> str | None:
    if not isinstance(payload, dict) or payload.get("hook_event_name") != "PreToolUse":
        return None
    if payload.get("tool_name") != "Bash":
        return None
    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict) or not isinstance(tool_input.get("command"), str):
        return None

    try:
        cwd = Path(str(payload.get("cwd", ""))).resolve()
        cwd.relative_to(repository_root)
    except (OSError, ValueError):
        return None
    return violation_for(tool_input["command"], repository_root)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=("audit", "enforce"), default="audit")
    arguments = parser.parse_args()
    repository_root = Path(__file__).resolve().parents[2]

    try:
        payload = json.load(sys.stdin)
        violation = inspect_payload(payload, repository_root)
    except Exception:
        return 0

    if not violation:
        return 0
    if arguments.mode == "enforce":
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": violation,
            }
        }
    else:
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "additionalContext": f"Audit-only repository policy warning: {violation}",
            }
        }
    json.dump(output, sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
