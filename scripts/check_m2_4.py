#!/usr/bin/env python3
from pathlib import Path

required = {
    "src/platform/macplus/reset_m2_4.S": [
        "0x000ffffc",
        "0xa55aa55a",
        "move.w  #253,%d1",
        "trap    #0",
        "0x4c524d34",
        "0x45584334",
    ],
    "linker/m2_4.ld": [
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m2_4_reset)",
    ],
    "tests/m2_4_runtime.c": [
        "ram_vector32",
        "ram_top_probe_restored",
        "LibreROM M2.4 runtime qualification: PASS",
    ],
    "scripts/qualify_m2_4_runtime.sh": [
        "MUSASHI_COMMIT=313ebf1bd9f4d0d93341eb5ce21fd8a119e9dbdd",
        "m68kcpu.o",
        "m68kops.o",
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

print("PASS: LibreROM M2.4 RAM/vector runtime invariants")
