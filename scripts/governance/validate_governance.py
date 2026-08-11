#!/usr/bin/env python3
"""Validate the lightweight governance structure without modifying the repository."""

from __future__ import annotations

import json
from pathlib import Path
import re
import sys
import tomllib


ROOT = Path(__file__).resolve().parents[2]
REQUIRED = (
    "AGENTS.md",
    "docs/specs/01_constitution.md",
    "docs/DEVELOPMENT_GUIDE.md",
    "docs/PULL_REQUEST_CHECKLIST.md",
    "docs/Progress.md",
    "docs/progress/phases-00-06.md",
    "docs/progress/phase-07.md",
    "docs/ADRs/0022-native-ios-wcag22-accessibility.md",
    "docs/accessibility/WCAG22_AA_IOS.md",
    "docs/standards/swift-code-policy.md",
    "docs/governance/rule-ownership.md",
    "docs/governance/hook-policy.md",
    ".codex/config.toml",
    ".codex/hooks.json",
)
SKILLS = (
    "franalonso-start-subphase",
    "franalonso-finish-subphase",
    "ios-accessibility-implementation",
    "franalonso-review-ios-standards",
    "franalonso-review-accessibility",
)
CRITERIA = (
    "1.1.1", "1.2.1", "1.2.2", "1.2.3", "1.2.4", "1.2.5", "1.3.1", "1.3.2", "1.3.3", "1.3.4",
    "1.3.5", "1.4.1", "1.4.2", "1.4.3", "1.4.4", "1.4.5", "1.4.10", "1.4.11", "1.4.12",
    "1.4.13", "2.1.1", "2.1.2", "2.1.4", "2.2.1", "2.2.2", "2.3.1", "2.4.1", "2.4.2", "2.4.3",
    "2.4.4", "2.4.5", "2.4.6", "2.4.7", "2.4.11", "2.5.1", "2.5.2", "2.5.3", "2.5.4", "2.5.7",
    "2.5.8", "3.1.1", "3.1.2", "3.2.1", "3.2.2", "3.2.3", "3.2.4", "3.2.6", "3.3.1", "3.3.2",
    "3.3.3", "3.3.4", "3.3.7", "3.3.8", "4.1.2", "4.1.3",
)
LINK = re.compile(r"\[[^\]]+\]\(([^)]+)\)")


def fail(message: str, failures: list[str]) -> None:
    failures.append(message)


def validate_links(path: Path, failures: list[str]) -> None:
    text = path.read_text()
    for target in LINK.findall(text):
        clean = target.strip("<>").split("#", 1)[0]
        if not clean or "://" in clean or clean.startswith("mailto:"):
            continue
        if not (path.parent / clean).resolve().exists():
            fail(f"Broken link in {path.relative_to(ROOT)}: {target}", failures)


def main() -> int:
    failures: list[str] = []
    for relative in REQUIRED:
        if not (ROOT / relative).is_file():
            fail(f"Missing required file: {relative}", failures)

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1

    for relative, budget in (("AGENTS.md", 8192), ("docs/Progress.md", 8192)):
        size = (ROOT / relative).stat().st_size
        if size > budget:
            fail(f"{relative} exceeds {budget} bytes: {size}", failures)

    for name in SKILLS:
        skill = ROOT / ".agents/skills" / name / "SKILL.md"
        metadata = skill.parent / "agents/openai.yaml"
        if not skill.is_file() or not metadata.is_file():
            fail(f"Incomplete repository skill: {name}", failures)

    matrix = (ROOT / "docs/accessibility/WCAG22_AA_IOS.md").read_text()
    for criterion in CRITERIA:
        if f"| {criterion} " not in matrix:
            fail(f"Accessibility matrix missing criterion {criterion}", failures)

    adr = (ROOT / "docs/ADRs/0022-native-ios-wcag22-accessibility.md").read_text()
    index = (ROOT / "docs/ADRs/README.md").read_text()
    adr_row = (
        "| [0022](0022-native-ios-wcag22-accessibility.md) | "
        "Objetivo de accesibilidad nativa basado en WCAG 2.2 A/AA | Aceptado |"
    )
    if "## Estado\n\nAceptado" not in adr or adr_row not in index:
        fail("ADR 0022 acceptance is inconsistent between the ADR and its index", failures)

    try:
        tomllib.loads((ROOT / ".codex/config.toml").read_text())
        json.loads((ROOT / ".codex/hooks.json").read_text())
    except (tomllib.TOMLDecodeError, json.JSONDecodeError) as error:
        fail(f"Invalid Codex configuration: {error}", failures)

    documents = [ROOT / "AGENTS.md", *(ROOT / "docs").rglob("*.md")]
    for document in documents:
        validate_links(document, failures)

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("Governance validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
