#!/usr/bin/env python3
from pathlib import Path

required = {
    "src/platform/macplus/reset_m3_4.S": [
        "MAC_TRAP_NEW_PTR,  0xa11e",
        "MAC_MEM_FULL_ERR, -108",
        "MAC_MEM_ERR,       0x00000220",
        "move.l  #0x20,%d0",
        ".word   MAC_TRAP_NEW_PTR",
        "cmpi.w  #MAC_MEM_FULL_ERR,%d0",
        "cmpi.w  #MAC_MEM_FULL_ERR,MAC_MEM_ERR",
        "LIBREROM-M3.4-NEWPTR-COMPAT",
    ],
    "linker/m3_4.ld": [
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m3_4_reset)",
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
print("PASS: LibreROM M3.4 NewPtr compatibility invariants")
