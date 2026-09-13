#!/usr/bin/env python3
from pathlib import Path

required = {
    "src/platform/macplus/reset_m2_6.S": [
        "0x00600000",
        "0x006ffffc",
        "0x50524536",
        "_m2_6_before_overlay_off",
        "0x00efe600",
        "0x00efe200",
        "trap    #0",
        "0x4c524d36",
        "0x45584336",
    ],
    "linker/m2_6.ld": [
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m2_6_reset)",
    ],
    "tests/m2_6_runtime.c": [
        "RAM_ALT_BASE 0x00600000u",
        "vectors_ready_before_overlay_off",
        "PRE_VALUE 0x50524536u",
        "LibreROM M2.6 runtime qualification: PASS",
    ],
    "scripts/qualify_m2_6_pce.sh": [
        "_m2_6_before_overlay_off",
        "d 600000 8",
        "d 600400 12",
        "00600400.*50 52 45 36",
        "d 400 12",
        "LibreROM M2.6 PCE qualification: PASS",
    ],
}

failed = False
for name, markers in required.items():
    path = Path(name)
    if not path.is_file():
        print(f"FAIL: missing {name}")
        failed = True
        continue
    text = path.read_text(encoding="utf-8")
    for marker in markers:
        if marker not in text:
            print(f"FAIL: {name}: missing marker {marker!r}")
            failed = True

if failed:
    raise SystemExit(1)

print("PASS: LibreROM M2.6 ordered reset-overlay hand-off invariants")
