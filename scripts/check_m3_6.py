#!/usr/bin/env python3
from pathlib import Path

checks = {
    "src/platform/macplus/reset_m3_6.S": (
        "MAC_TRAP_SET_PTR_SIZE, 0xa020",
        "MAC_TRAP_GET_PTR_SIZE, 0xa021",
        "MAC_MEM_WZ_ERR",
        "-111",
        "MAC_MEM_FULL_ERR",
        "-108",
        "LIBREROM-M3.6-PTRSIZE-COMPAT",
    ),
    "linker/m3_6.ld": (
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m3_6_reset)",
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
print("PASS: LibreROM M3.6 pointer-size compatibility invariants")
