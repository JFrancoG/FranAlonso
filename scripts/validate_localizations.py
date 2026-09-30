#!/usr/bin/env python3
"""Check bilingual catalog completeness and the compiled-resource test inventory."""

import argparse
from collections import Counter
import json
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = ("es", "en")
IDENTITY_KEYS = {"CFBundleName", "CFBundleDisplayName"}
FORMAT_TOKEN = re.compile(r"%(?:\d+\$)?[-+ #0]*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|ll|[hlLzjt])?[@diuoxXfFeEgGaAcCsSp]")
UI_LITERAL = re.compile(
    r'\b(?:Text|Label|Button|TextField|SecureField|Section|navigationTitle|accessibilityLabel|'
    r'accessibilityHint|alert|confirmationDialog)\s*\(\s*"([^"\n]*)"'
)


def string_units(value):
    """Include plural/device variants and substitution formats without silently skipping them."""
    if isinstance(value, dict):
        if "stringUnit" in value:
            yield value["stringUnit"]
        for key, nested in value.items():
            if key != "stringUnit":
                yield from string_units(nested)


def validate(root):
    errors = []
    inventory = json.loads((root / "FranAlonsoTests/LocalizationInventory.json").read_text())
    tables = {}
    for path in sorted((root / "FranAlonso/Resources").rglob("*.xcstrings")):
        catalog = json.loads(path.read_text())
        keys = []
        for key, entry in catalog["strings"].items():
            location = f"{path.relative_to(root)}:{key}"
            if path.stem == "InfoPlist" and key in IDENTITY_KEYS:
                if entry.get("shouldTranslate") is not False:
                    errors.append(f"{location}: app identity must remain configured by environment")
                continue
            keys.append(key)
            units_by_language = {}
            for language in LANGUAGES:
                units = list(string_units(entry.get("localizations", {}).get(language, {})))
                units_by_language[language] = units
                if not units:
                    errors.append(f"{location}: missing {language}")
                for unit in units:
                    value = unit.get("value", "")
                    if unit.get("state") != "translated" or not value.strip() or value == key:
                        errors.append(f"{location}: incomplete {language}")
            # All current entries are flat. For variants, compare formats per leaf, preserving multiplicity.
            formats = {
                language: Counter(
                    tuple(sorted(FORMAT_TOKEN.findall(unit.get("value", "").replace("%%", ""))))
                    for unit in units
                )
                for language, units in units_by_language.items()
            }
            if all(units_by_language.values()) and formats["es"] != formats["en"]:
                errors.append(f"{location}: format placeholders differ between es and en")
        tables[path.stem] = sorted(keys)
        if sorted(inventory.get(path.stem, [])) != tables[path.stem]:
            errors.append(f"{path.stem}: update the test inventory to match catalog keys exactly")
        print(f"{path.stem}: {len(keys)} translatable entries checked in es/en")
    if set(inventory) != set(tables):
        errors.append("Test inventory tables do not match the catalogs")
    project = (root / "FranAlonso.xcodeproj/project.pbxproj").read_text()
    regions = re.search(r"knownRegions\s*=\s*\((.*?)\);", project, re.S)
    if not regions or not all(re.search(rf"\b{language}\b", regions[1]) for language in LANGUAGES):
        errors.append("Project knownRegions must declare es and en")
    for path in sorted((root / "FranAlonso").rglob("*.swift")):
        for match in UI_LITERAL.finditer(path.read_text()):
            if match[1] not in tables.get("Localizable", []):
                line = path.read_text()[:match.start()].count("\n") + 1
                errors.append(f"{path.relative_to(root)}:{line}: UI literal absent from Localizable")
    for error in errors:
        print(f"ERROR: {error}")
    print(f"{sum(map(len, tables.values()))} entries; {len(errors)} errors")
    return bool(errors)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    raise SystemExit(validate(parser.parse_args().root))
