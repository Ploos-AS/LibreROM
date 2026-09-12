#!/usr/bin/env python3
from pathlib import Path

required = {
    "docs/M2_MACHINE_PROFILE.md": [
        "Macintosh Plus",
        "Motorola 68000",
        "0x400000",
        "0xe80000",
        "512 × 342",
        "M2.1",
    ],
    "src/platform/macplus/memory_map.h": [
        "MACPLUS_ROM_BASE",
        "0x00400000UL",
        "MACPLUS_ROM_SIZE",
        "0x00020000UL",
        "MACPLUS_VIA_BASE",
        "0x00e80000UL",
        "MACPLUS_FB_WIDTH",
        "512U",
        "MACPLUS_FB_HEIGHT",
        "342U",
        "MACPLUS_QUAL_RAM_BYTES",
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

print("PASS: LibreROM M2.0 Macintosh Plus profile invariants")
