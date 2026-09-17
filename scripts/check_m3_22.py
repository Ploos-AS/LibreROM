#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src_path = root / "build/generated/reset_m3_22.S"
if not src_path.is_file():
    raise SystemExit("M3.22 static qualification FAIL: generated source missing")

src = src_path.read_text(encoding="utf-8")
ld = (root / "linker/m3_22.ld").read_text(encoding="utf-8")

required = [
    "_m3_22_new_ptr",
    "_m3_22_new_handle",
    "_m3_22_ptr_split_record_scan",
    "_m3_22_ptr_split_record_found",
    "_m3_22_handle_reuse_scan",
    "_m3_22_handle_split_record_scan",
    "_m3_22_handle_split_record_found",
    "LIBREROM-M3.22-INTERIOR-HOLE-SPLITTING",
    "LR_ALLOC_TABLE",
    "LR_REC_PTR",
    "LR_REC_EXTENT",
    "LR_REC_ACTIVE",
    "LR_HANDLE_TABLE",
    "LR_HREC_HANDLE",
    "LR_HREC_DATA",
    "LR_HREC_EXTENT",
    "LR_HREC_ACTIVE",
    "LR_MASTER_BASE",
]
missing = [item for item in required if item not in src]
if missing:
    raise SystemExit("M3.22 static qualification FAIL: missing " + ", ".join(missing))

if "ENTRY(_m3_22_reset)" not in ld or "LENGTH = 128K" not in ld:
    raise SystemExit("M3.22 static qualification FAIL: linker contract")

ptr_start = src.index("_m3_22_ptr_split_record_found:")
ptr_end = src.index("_m3_22_ptr_reuse_commit:", ptr_start)
ptr_split = src[ptr_start:ptr_end]
for token in ["LR_REC_PTR", "LR_REC_LOGICAL", "LR_REC_EXTENT", "LR_REC_ACTIVE", "add.l %d1", "sub.l %d1"]:
    if token not in ptr_split:
        raise SystemExit("M3.22 static qualification FAIL: incomplete Ptr split path: " + token)
if "LR_HEAP_NEXT" in ptr_split:
    raise SystemExit("M3.22 static qualification FAIL: Ptr interior split modifies heap tail")

handle_start = src.index("_m3_22_handle_split_record_found:")
handle_end = src.index("_m3_22_handle_reuse_commit:", handle_start)
handle_split = src[handle_start:handle_end]
for token in [
    "LR_HREC_HANDLE", "LR_HREC_DATA", "LR_HREC_LOGICAL", "LR_HREC_EXTENT",
    "LR_HREC_ACTIVE", "LR_HREC_STATE", "LR_MASTER_BASE", "add.l %d1", "sub.l %d1",
]:
    if token not in handle_split:
        raise SystemExit("M3.22 static qualification FAIL: incomplete Handle split path: " + token)
if "LR_HEAP_NEXT" in handle_split:
    raise SystemExit("M3.22 static qualification FAIL: Handle interior split modifies heap tail")

# The inactive Handle suffix must have a reserved master-pointer slot whose
# contents remain NULL until a later NewHandle reactivates the suffix record.
if "clr.l (%a3)" not in handle_split:
    raise SystemExit("M3.22 static qualification FAIL: Handle suffix master pointer is not cleared")

print("LibreROM M3.22 interior allocation hole splitting static qualification: PASS")
