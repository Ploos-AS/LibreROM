#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parent.parent
script = (root / "scripts/qualify_m2_5_pce.sh").read_text()
doc = (root / "docs/M2_5_PCE_QUALIFICATION.md").read_text()

required_script = [
    "notpeter/PCE.git",
    "371414f8f41ae02e9ce36004ba7b076fdd3abe63",
    "pce-macplus",
    "model = \"mac-plus\"",
    "size = 128K",
    "g b",
    "d 0x400 8",
    "4C 52 4D 34",
    "45 58 43 34",
    "LibreROM M2.5 PCE qualification: PASS",
]
required_doc = [
    "M2.5",
    "PCE/macplus",
    "independent",
    "Apple ROM",
    "LRM4",
    "EXC4",
]

missing = [s for s in required_script if s not in script]
missing += [f"doc:{s}" for s in required_doc if s not in doc]
if missing:
    raise SystemExit("FAIL: M2.5 invariants missing: " + ", ".join(missing))

print("PASS: LibreROM M2.5 PCE qualification invariants")
