#!/usr/bin/env python3
from pathlib import Path

required = {
    "src/platform/macplus/reset_m3_0.S": [
        "0x00600028",
        "_m3_0_aline",
        "LR_DIAG_TRAP, 0xa0f0",
        "move.l  2(%a7),%a0",
        "addq.l  #2,2(%a7)",
        "0x44535030",
        "0x4f4b3330",
        "LIBREROM-M3.0-ALINE-DISPATCH",
    ],
    "linker/m3_0.ld": [
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m3_0_reset)",
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

print("PASS: LibreROM M3.0 A-line dispatch invariants")
