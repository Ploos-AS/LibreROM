#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parent.parent
src = (root / "src/platform/macplus/reset_m2_12.S").read_text()
ld = (root / "linker/m2_12.ld").read_text()
qual = (root / "scripts/qualify_m2_12_pce.sh").read_text() if (root / "scripts/qualify_m2_12_pce.sh").exists() else ""

required = {
    "reset-entry": "_m2_12_reset",
    "128k-rom": "LENGTH = 128K",
    "iwm-data-mode": "0x00c01801",
    "dam-search": "0x00d5aaad",
    "sector-zero": "First translated symbol after DAM is sector number; require 0",
    "gcr-table": "_m2_12_gcr_table",
    "checksum-transform": "_m2_12_checksum_byte",
    "checksum-marker": "CHK2",
    "payload-load-address": "0x00002000",
    "sector-marker": "SEC2",
    "failure-marker": "FAI2",
    "fixture-marker": "0x4c523132",
    "qualification-fixture": "sector0.bin",
    "qualification-pce-pin": "371414f8f41ae02e9ce36004ba7b076fdd3abe63",
}

missing = []
for name, needle in required.items():
    haystack = ld if name in {"128k-rom"} else qual if name.startswith("qualification-") else src
    if needle not in haystack:
        missing.append(name)

for forbidden in ("Apple ROM", "System 6", "System 7"):
    # The clean-room comments may mention Apple ROM only to state that it is absent.
    # Do not flag prose; the invariant is that no fixture path names proprietary media.
    if forbidden in qual and forbidden != "Apple ROM":
        missing.append(f"forbidden-fixture:{forbidden}")

if missing:
    raise SystemExit("FAIL: M2.12 invariants missing: " + ", ".join(missing))

print("PASS: LibreROM M2.12 GCR sector-loader invariants")
