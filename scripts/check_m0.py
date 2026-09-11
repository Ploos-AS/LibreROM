#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

required = [
    "README.md",
    "LICENSE",
    "Makefile",
    "docs/CLEAN_ROOM.md",
    "docs/ARCHITECTURE.md",
    "docs/ROADMAP.md",
    "include/.gitkeep",
    "src/.gitkeep",
    "tests/.gitkeep",
]

errors = []
for rel in required:
    if not (ROOT / rel).exists():
        errors.append(f"missing required path: {rel}")

readme = (ROOT / "README.md").read_text(encoding="utf-8")
if "clean-room" not in readme.lower():
    errors.append("README must state the clean-room requirement")
if "M0" not in readme:
    errors.append("README must state the current M0 status")

license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
if "MIT License" not in license_text or "Ploos AS" not in license_text:
    errors.append("LICENSE must be MIT and identify Ploos AS")

for forbidden in (".rom", ".bin"):
    matches = [p for p in ROOT.rglob(f"*{forbidden}") if ".git" not in p.parts and "build" not in p.parts]
    if matches:
        errors.append(f"firmware/binary fixture unexpectedly committed: {matches[0].relative_to(ROOT)}")

if errors:
    print("M0 qualification: FAIL")
    for error in errors:
        print(f" - {error}")
    sys.exit(1)

print("M0 qualification: PASS")
print(f"required paths: {len(required)}/{len(required)}")
print("clean-room policy: present")
print("license: MIT / Ploos AS")
print("proprietary ROM fixtures: none detected")
