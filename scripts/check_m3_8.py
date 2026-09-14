#!/usr/bin/env python3
from pathlib import Path

checks = {
    "src/platform/macplus/reset_m3_8.S": (
        "MAC_TRAP_SET_HANDLE_SIZE, 0xa024",
        "MAC_TRAP_GET_HANDLE_SIZE, 0xa025",
        "LIBREROM-M3.8-HANDLE-SIZING-RELOCATION",
        "LR_MASTER_BASE",
        "LR_HREC_LOGICAL",
        "LR_HREC_EXTENT",
    ),
    "linker/m3_8.ld": (
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m3_8_reset)",
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
print("PASS: LibreROM M3.8 handle-size/relocation invariants")
