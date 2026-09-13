#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parent.parent
src = (root / "src/platform/macplus/reset_m2_11.S").read_text()
linker = (root / "linker/m2_11.ld").read_text()
pce = (root / "scripts/qualify_m2_11_pce.sh").read_text()
doc = (root / "docs/M2_11_IWM_READ_QUALIFICATION.md").read_text()

required_src = [
    "LIBREROM-M2.11-MACPLUS-IWM-READ",
    "0x00c00601",
    "0x00c00e01",
    "0x00c01201",
    "0x00c01801",
    "0x00c01c01",
    "0x44415431",
    "0x52444631",
    "moveq   #15,%d4",
    "btst    #7,%d0",
]
required_linker = ["ENTRY(_m2_11_reset)", "LENGTH = 128K"]
required_pce = [
    "notpeter/PCE.git",
    "371414f8f41ae02e9ce36004ba7b076fdd3abe63",
    "test-disk.psi",
    "-N mac 400",
    'inserted     = 1',
    "00000430",
    "44 41 54 31",
    "LibreROM M2.11 PCE qualification: PASS",
]
required_doc = ["M2.11", "IWM", "GCR", "PCE", "Apple ROM", "DAT1"]

missing = [f"src:{x}" for x in required_src if x not in src]
missing += [f"linker:{x}" for x in required_linker if x not in linker]
missing += [f"pce:{x}" for x in required_pce if x not in pce]
missing += [f"doc:{x}" for x in required_doc if x not in doc]
if missing:
    raise SystemExit("FAIL: M2.11 invariants missing: " + ", ".join(missing))

print("PASS: LibreROM M2.11 raw IWM read invariants")
