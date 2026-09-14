#!/usr/bin/env python3
from pathlib import Path

checks = {
    "src/platform/macplus/reset_m3_5.S": (
        "MAC_TRAP_NEW_PTR,     0xa11e",
        "MAC_TRAP_DISPOSE_PTR, 0xa01f",
        "MAC_MEM_WZ_ERR,      -111",
        "MAC_MEM_ERR,          0x00000220",
        "LR_ALLOC_TABLE,       0x00000460",
        "LR_ALLOC_COUNT,       8",
        "LIBREROM-M3.5-DISPOSEPTR-COMPAT",
    ),
    "linker/m3_5.ld": (
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m3_5_reset)",
    ),
}

bad = False
for filename, markers in checks.items():
    path = Path(filename)
    if not path.is_file():
        print("FAIL: missing", filename)
        bad = True
        continue
    text = path.read_text(encoding="utf-8")
    for marker in markers:
        if marker not in text:
            print("FAIL:", filename, "missing", repr(marker))
            bad = True

if bad:
    raise SystemExit(1)
print("PASS: LibreROM M3.5 DisposePtr compatibility invariants")
