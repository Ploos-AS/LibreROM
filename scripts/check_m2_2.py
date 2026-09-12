#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

required = {
    "src/platform/macplus/via_overlay.h": [
        "MACPLUS_VIA_OVERLAY_BIT",
        "0x10U",
        "MACPLUS_VIA_ORA_ADDR",
        "MACPLUS_VIA_DDRA_ADDR",
        "macplus_overlay_disable_value",
    ],
    "tests/m2_2_via_overlay_model.py": [
        "VIA_A4 = 0x10",
        "reset_overlay=ROM",
        "low_memory_after_disable=RAM",
    ],
}

failed = False
for name, markers in required.items():
    p = Path(name)
    if not p.is_file():
        print(f"FAIL: missing {name}")
        failed = True
        continue
    text = p.read_text(encoding="utf-8")
    for marker in markers:
        if marker not in text:
            print(f"FAIL: {name}: missing marker {marker!r}")
            failed = True

if failed:
    raise SystemExit(1)

subprocess.run([sys.executable, "tests/m2_2_via_overlay_model.py"], check=True)
print("PASS: LibreROM M2.2 VIA overlay qualification")
