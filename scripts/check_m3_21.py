#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src_path = root / "build/generated/reset_m3_21.S"
if not src_path.is_file():
    raise SystemExit("M3.21 static qualification FAIL: generated source missing")

src = src_path.read_text(encoding="utf-8")
ld = (root / "linker/m3_21.ld").read_text(encoding="utf-8")

required = [
    "_m3_21_new_handle",
    "_m3_21_handle_reuse_scan",
    "MAC_TRAP_NEW_HANDLE",
    "MAC_TRAP_DISPOSE_HANDLE",
    "LIBREROM-M3.21-INTERIOR-HANDLE-REUSE",
    "LR_ALLOC_TABLE",
    "LR_REC_HANDLE",
    "LR_REC_DATA",
    "LR_REC_LOGICAL",
    "LR_REC_EXTENT",
    "LR_REC_ACTIVE",
    "0x4f4b3231",
]
missing = [item for item in required if item not in src]
if missing:
    raise SystemExit("M3.21 static qualification FAIL: missing " + ", ".join(missing))

if "ENTRY(_m3_21_reset)" not in ld or "LENGTH = 128K" not in ld:
    raise SystemExit("M3.21 static qualification FAIL: linker contract")

for marker in ["0x484f3231", "0x52553231", "0x534b3231"]:
    if marker not in src:
        raise SystemExit("M3.21 static qualification FAIL: fixture marker missing " + marker)

# The reuse path must reactivate a retained Handle record and reconnect its
# master pointer to the retained data extent without touching LR_HEAP_NEXT.
reuse_start = src.index("_m3_21_handle_reuse_scan:")
reuse_end = src.index("_m3_21_handle_reuse_next:", reuse_start)
reuse = src[reuse_start:reuse_end]
for token in ["LR_REC_EXTENT", "LR_REC_HANDLE", "LR_REC_DATA", "LR_REC_LOGICAL", "LR_REC_ACTIVE", "(%a0)"]:
    if token not in reuse:
        raise SystemExit("M3.21 static qualification FAIL: incomplete Handle reuse path: " + token)
if "LR_HEAP_NEXT" in reuse:
    raise SystemExit("M3.21 static qualification FAIL: interior reuse modifies heap tail")

print("LibreROM M3.21 interior Handle reuse static qualification: PASS")
