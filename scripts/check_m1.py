#!/usr/bin/env python3
from pathlib import Path

required = {
    "src/arch/m68k/reset.S": ["_vectors", "_reset", "LIBREROM-M1", "stop"],
    "linker/m1.ld": ["OUTPUT_ARCH(m68k)", "LENGTH = 64K", "ASSERT"],
    "scripts/pad_rom.py": ["0xff", "target"],
}

failed = False
for name, markers in required.items():
    p = Path(name)
    if not p.is_file():
        print(f"FAIL: missing {name}")
        failed = True
        continue
    text = p.read_text()
    for marker in markers:
        if marker not in text:
            print(f"FAIL: {name}: missing marker {marker!r}")
            failed = True

if failed:
    raise SystemExit(1)
print("PASS: LibreROM M1 static invariants")
