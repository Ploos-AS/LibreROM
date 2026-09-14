#!/usr/bin/env python3
from pathlib import Path

checks = {
    "src/platform/macplus/reset_m3_7.S": (
        "MAC_TRAP_NEW_HANDLE,     0xa122",
        "MAC_TRAP_DISPOSE_HANDLE, 0xa023",
        "MAC_TRAP_GET_PTR_SIZE,   0xa021",
        "MAC_TRAP_SET_PTR_SIZE,   0xa020",
        "MAC_MEM_WZ_ERR",
        "MAC_MEM_FULL_ERR",
        "LR_MASTER_BASE",
        "LR_HANDLE_TABLE",
        "LIBREROM-M3.7-HANDLE-BASELINE",
    ),
    "linker/m3_7.ld": (
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m3_7_reset)",
    ),
}

bad = False
for filename, markers in checks.items():
    p = Path(filename)
    if not p.is_file():
        print("FAIL: missing", filename)
        bad = True
        continue
    text = p.read_text(encoding="utf-8")
    for marker in markers:
        if marker not in text:
            print("FAIL:", filename, "missing", repr(marker))
            bad = True
if bad:
    raise SystemExit(1)
print("PASS: LibreROM M3.7 handle baseline invariants")
