#!/usr/bin/env python3
from pathlib import Path

required = {
    "src/platform/macplus/reset_m3_2.S": [
        "LR_SVC_MEM_ALLOC, 0xa0f2",
        "LR_HEAP_BASE,     0x00010000",
        "LR_HEAP_LIMIT,    0x00080000",
        "LR_HEAP_NEXT,     0x00000440",
        "andi.l  #0xfffffffe,%d0",
        "cmpi.l  #LR_HEAP_LIMIT,%d1",
        "LIBREROM-M3.2-MEMORY-PRIMITIVE",
    ],
    "linker/m3_2.ld": [
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m3_2_reset)",
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
print("PASS: LibreROM M3.2 memory primitive invariants")
