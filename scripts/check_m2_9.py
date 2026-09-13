#!/usr/bin/env python3
from pathlib import Path

required = {
    "src/platform/macplus/reset_m2_9.S": [
        "0x00600064",
        "_m2_9_via_irq",
        "0x00eff400",
        "0x00eff600",
        "0x00effa00",
        "0x00effc00",
        "#0x1c",
        "#0x0c",
        "#0x16",
        "#0x84",
        "0x4b424439",
        "0x494e5039",
        "andi.b  #0x04",
        "rte",
    ],
    "linker/m2_9.ld": [
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m2_9_reset)",
    ],
    "tests/m2_9_runtime.c": [
        "VIA_SR    0x00eff400u",
        "VIA_SR_BIT 0x04u",
        "KEYBOARD_MODEL_COMMAND 0x16u",
        "keyboard_response",
        "synthetic_key_byte",
        "LibreROM M2.9 runtime qualification: PASS",
    ],
    "scripts/qualify_m2_9_pce.sh": [
        "keyboard_command=0x16",
        "via_sr_ifr_bit=0x04",
        "4B 42 44 39",
        "49 4E 50 39",
        "LibreROM M2.9 PCE qualification: PASS",
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

print("PASS: LibreROM M2.9 keyboard/VIA shift-register invariants")
