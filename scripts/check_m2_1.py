#!/usr/bin/env python3
from pathlib import Path

required = {
    "docs/M2_1_RESET_OVERLAY.md": [
        "reset-overlay",
        "RAM",
        "0x00400000",
        "make qualify-m2_1",
    ],
    "src/platform/macplus/reset_overlay.h": [
        "MACPLUS_LOW_MEMORY_BASE",
        "MACPLUS_RESET_VECTOR_BYTES",
        "MACPLUS_RESET_OVERLAY_ACTIVE",
        "MACPLUS_RESET_OVERLAY_INACTIVE",
    ],
    "tests/m2_1_overlay_model.py": [
        "MacPlusOverlayModel",
        "copy_reset_vectors_to_ram",
        "disable_overlay",
        "POST_OVERLAY_LOW_MEMORY=RAM",
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

print("PASS: LibreROM M2.1 reset overlay invariants")
