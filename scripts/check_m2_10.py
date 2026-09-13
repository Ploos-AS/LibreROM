#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parent.parent
src = (root / "src/platform/macplus/reset_m2_10.S").read_text()
linker = (root / "linker/m2_10.ld").read_text()
pce = (root / "scripts/qualify_m2_10_pce.sh").read_text()
doc = (root / "docs/M2_10_IWM_QUALIFICATION.md").read_text()

required_src = [
    "LIBREROM-M2.10-MACPLUS-IWM-SENSE",
    "0x00c00001",
    "0x00c00401",
    "0x00c00801",
    "0x00c01c01",
    "0x00c01a01",
    "0x49574d50",
    "0x49574d4e",
    "0x49574d30",
    "btst    #7",
]
required_linker = ["ENTRY(_m2_10_reset)", "LENGTH = 128K"]
required_pce = [
    "notpeter/PCE.git",
    "371414f8f41ae02e9ce36004ba7b076fdd3abe63",
    "inserted     = 0",
    "inserted     = 1",
    "test-disk.img",
    "49 57 4D 4E",
    "49 57 4D 50",
    "49 57 4D 30",
    "LibreROM M2.10 PCE qualification: PASS",
]
required_doc = ["M2.10", "IWM", "media", "PCE", "Apple ROM", "IWMN", "IWMP"]

missing = [f"src:{x}" for x in required_src if x not in src]
missing += [f"linker:{x}" for x in required_linker if x not in linker]
missing += [f"pce:{x}" for x in required_pce if x not in pce]
missing += [f"doc:{x}" for x in required_doc if x not in doc]
if missing:
    raise SystemExit("FAIL: M2.10 invariants missing: " + ", ".join(missing))

print("PASS: LibreROM M2.10 IWM/media-sense invariants")
