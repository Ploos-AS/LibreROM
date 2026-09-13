#!/usr/bin/env python3
from pathlib import Path

required = {
    "src/platform/macplus/reset_m2_8.S": [
        "0x00600064",
        "_m2_8_via_irq",
        "0x00efe800",
        "0x00efea00",
        "0x00eff600",
        "0x00effa00",
        "0x00effc00",
        "#0xc0",
        "#0x2000",
        "0x49525138",
        "0x544d5238",
        "move.b  (%a0),%d0",
        "rte",
    ],
    "linker/m2_8.ld": [
        "ORIGIN = 0x00400000",
        "LENGTH = 128K",
        "ENTRY(_m2_8_reset)",
    ],
    "tests/m2_8_runtime.c": [
        "VIA_T1CL  0x00efe800u",
        "VIA_IFR   0x00effa00u",
        "VIA_IER   0x00effc00u",
        "VIA_T1_BIT 0x40u",
        "ram_vector25_irq1",
        "timer_expired",
        "LibreROM M2.8 runtime qualification: PASS",
    ],
    "scripts/qualify_m2_8_pce.sh": [
        "cpu_interrupt_level=1",
        "via_timer1_ifr_bit=0x40",
        "49 52 51 38",
        "54 4D 52 38",
        "LibreROM M2.8 PCE qualification: PASS",
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

print("PASS: LibreROM M2.8 VIA Timer 1 interrupt invariants")
