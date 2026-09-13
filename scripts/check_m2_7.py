#!/usr/bin/env python3
from pathlib import Path

required = {
    "src/platform/macplus/reset_m2_7.S": [
        "0x000fa700",
        "0x000f2700",
        "#10943",
        "#0xaa55",
        "0x56494437",
        "0x000f0000",
        "_m2_7_before_overlay_off",
        "trap    #0",
    ],
    "linker/m2_7.ld": [
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m2_7_reset)",
    ],
    "tests/m2_7_runtime.c": [
        "MAIN_FB 0x000fa700u",
        "ALT_FB 0x000f2700u",
        "FB_BYTES 21888u",
        "VID_VALUE 0x56494437u",
        "LibreROM M2.7 runtime qualification: PASS",
    ],
    "scripts/qualify_m2_7_pce.sh": [
        "d FA700 10",
        "d F2700 10",
        "VID7",
        "LibreROM M2.7 PCE qualification: PASS",
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

print("PASS: LibreROM M2.7 framebuffer diagnostic invariants")
