#!/usr/bin/env python3
from pathlib import Path

required = {
    "src/platform/macplus/reset_m3_3.S": [
        "LR_SVC_NEW_PTR,    0xa0f3",
        "LR_SVC_MEM_STATUS, 0xa0f4",
        "LR_HEAP_NEXT,      0x00000440",
        "LR_MEM_LAST_ERR,   0x00000444",
        "andi.l  #0xfffffffe,%d1",
        "cmpi.l  #LR_HEAP_LIMIT,%d2",
        "move.l  LR_MEM_LAST_ERR,%d0",
        "LIBREROM-M3.3-POINTER-STATUS",
    ],
    "linker/m3_3.ld": [
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m3_3_reset)",
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
print("PASS: LibreROM M3.3 pointer/status invariants")
