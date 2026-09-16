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
    "LR_HANDLE_TABLE",
    "LR_HANDLE_COUNT",
    "LR_HANDLE_REC_SIZE",
    "LR_HREC_HANDLE",
    "LR_HREC_DATA",
    "LR_HREC_LOGICAL",
    "LR_HREC_EXTENT",
    "LR_HREC_ACTIVE",
    "LR_HREC_STATE",
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

# The reuse path must use the dedicated Handle table, reactivate a retained
# record, reconnect its master pointer to retained data, and return from the
# A-line trap without modifying the physical heap tail.
reuse_start = src.index("_m3_21_handle_reuse_scan:")
reuse_end = src.index("_m3_21_handle_reuse_next:", reuse_start)
reuse = src[reuse_start:reuse_end]
for token in [
    "LR_HREC_EXTENT",
    "LR_HREC_HANDLE",
    "LR_HREC_DATA",
    "LR_HREC_LOGICAL",
    "LR_HREC_ACTIVE",
    "LR_HREC_STATE",
    "(%a2)",
    "rte",
]:
    if token not in reuse:
        raise SystemExit("M3.21 static qualification FAIL: incomplete Handle reuse path: " + token)
if "LR_HEAP_NEXT" in reuse:
    raise SystemExit("M3.21 static qualification FAIL: interior reuse modifies heap tail")

# Guard against the incorrect mixed Ptr/Handle-record model used by the first
# M3.21 draft. Handles have their own 24-byte HREC table.
for bad in ["LR_ALLOC_RECORDS", "LR_KIND_HANDLE", "LR_REC_KIND", "LR_REC_HANDLE", "LR_REC_DATA", "LR_REC_STATE", "LR_REC_SIZE"]:
    if bad in reuse:
        raise SystemExit("M3.21 static qualification FAIL: obsolete Handle layout token: " + bad)

print("LibreROM M3.21 interior Handle reuse static qualification: PASS")
