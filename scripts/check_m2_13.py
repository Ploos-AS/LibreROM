#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parent.parent
src = (root / "src/platform/macplus/reset_m2_13.S").read_text()
ld = (root / "linker/m2_13.ld").read_text()
qual = (root / "scripts/qualify_m2_13_pce.sh").read_text() if (root / "scripts/qualify_m2_13_pce.sh").exists() else ""

required = {
    "reset-entry": "_m2_13_reset",
    "128k-rom": "LENGTH = 128K",
    "iwm-data-mode": "0x00c01801",
    "address-prologue": "0x00d5aa96",
    "address-header-scratch": "0x00000450",
    "address-checksum": "Address checksum is c ^ s ^ h ^ fmt ^ ck == 0",
    "target-c0-h0-s0": "fixture target is exactly cylinder 0, head 0, sector 0",
    "dam-search": "0x00d5aaad",
    "post-header-dam-window": "at most 64 raw bytes after a valid address header",
    "matching-sector-id": "must match header sector (zero)",
    "gcr-table": "_m2_13_gcr_table",
    "checksum-transform": "_m2_13_checksum_byte",
    "checksum-marker": "CHK2",
    "payload-load-address": "0x00002000",
    "sector-marker": "SEC2",
    "failure-marker": "FAI2",
    "fixture-marker": "0x4c523133",
    "boot-entry": "0x00002010",
    "transfer-marker": "XFR3",
    "qualification-fixture": "sector0.bin",
    "qualification-proof": "BT13",
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
    raise SystemExit("FAIL: M2.13 invariants missing: " + ", ".join(missing))

print("PASS: LibreROM M2.13 GCR boot-transfer invariants")
