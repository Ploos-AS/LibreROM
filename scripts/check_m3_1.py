#!/usr/bin/env python3
from pathlib import Path

required = {
    "src/platform/macplus/reset_m3_1.S": [
        "LR_SVC_PING, 0xa0f0",
        "LR_SVC_ADD,  0xa0f1",
        "0x00600028",
        "_m3_1_aline",
        "move.l  2(%a7),%a0",
        "addq.l  #2,2(%a7)",
        "cmpi.w  #LR_SVC_PING,%d2",
        "cmpi.w  #LR_SVC_ADD,%d2",
        "add.l   %d1,%d0",
        "LIBREROM-M3.1-SERVICE-TABLE",
    ],
    "linker/m3_1.ld": [
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m3_1_reset)",
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

print("PASS: LibreROM M3.1 private service ABI invariants")
