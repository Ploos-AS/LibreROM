#!/usr/bin/env python3
from pathlib import Path

required = {
    "src/platform/macplus/reset_m2_3.S": [
        "0x00100000",
        "0x00efe600",
        "0x00efe200",
        "0x4c524d33",
        "LIBREROM-M2.3-MACPLUS",
    ],
    "linker/m2_3.ld": [
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m2_3_reset)",
    ],
    "tests/m2_3_runtime.c": [
        "ROM_BASE 0x00400000u",
        "VIA_ORA  0x00efe200u",
        "VIA_DDRA 0x00efe600u",
        "SIGNATURE_VALUE 0x4c524d33u",
        "LibreROM M2.3 runtime qualification: PASS",
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

print("PASS: LibreROM M2.3 ROM/VIA runtime invariants")
