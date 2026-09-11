#!/usr/bin/env python3
from pathlib import Path
import hashlib
import struct
import sys

EXPECTED_SIZE = 65536
EXPECTED_SSP = 0x00010000
MARKER = b"LIBREROM-M1\0"


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: qualify_m1.py ROM", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    data = path.read_bytes()
    failures = []

    if len(data) != EXPECTED_SIZE:
        failures.append(f"size={len(data)}, expected={EXPECTED_SIZE}")

    if len(data) >= 8:
        ssp, pc = struct.unpack(">II", data[:8])
        if ssp != EXPECTED_SSP:
            failures.append(f"SSP=0x{ssp:08x}, expected=0x{EXPECTED_SSP:08x}")
        if not (8 <= pc < EXPECTED_SIZE):
            failures.append(f"reset PC=0x{pc:08x} outside ROM payload")
        elif data[pc:pc+4] != bytes.fromhex("46fc2700"):
            failures.append("reset entry does not begin with MOVE.W #$2700,SR")
    else:
        failures.append("image too short for reset vectors")

    if MARKER not in data:
        failures.append("diagnostic marker missing")

    digest = hashlib.sha256(data).hexdigest()
    print(f"ROM: {path}")
    print(f"size: {len(data)}")
    print(f"sha256: {digest}")

    if failures:
        for failure in failures:
            print(f"FAIL: {failure}")
        return 1

    print("PASS: LibreROM M1 image structure")
    print("NOTE: emulator runtime qualification is still required for M1 completion")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
