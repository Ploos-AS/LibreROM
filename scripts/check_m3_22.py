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

# The Handle split setup maps a never-used Handle record to its corresponding
# master-pointer slot before the split-record-found label. Validate setup and
# mutation separately so the checker follows the actual control-flow layout.
handle_scan_start = src.index("_m3_22_handle_split_record_scan:")
handle_found = src.index("_m3_22_handle_split_record_found:", handle_scan_start)
handle_commit = src.index("_m3_22_handle_reuse_commit:", handle_found)
handle_setup = src[handle_scan_start:handle_found]
handle_split = src[handle_found:handle_commit]

for token in ["LR_HREC_HANDLE", "LR_HANDLE_REC_SIZE", "addq.l #4,%a3"]:
    if token not in handle_setup:
        raise SystemExit("M3.22 static qualification FAIL: incomplete Handle split setup: " + token)

# LR_MASTER_BASE is loaded immediately before entering the scan, so include
# that prelude in the structural check rather than incorrectly requiring the
# symbolic constant inside the record-found block itself.
handle_prelude_start = src.rfind("move.l #LR_HANDLE_TABLE", 0, handle_scan_start)
if handle_prelude_start < 0:
    raise SystemExit("M3.22 static qualification FAIL: Handle split prelude missing")
handle_prelude = src[handle_prelude_start:handle_scan_start]
for token in ["LR_HANDLE_TABLE", "LR_MASTER_BASE", "LR_HANDLE_COUNT"]:
    if token not in handle_prelude:
        raise SystemExit("M3.22 static qualification FAIL: incomplete Handle split prelude: " + token)

for token in [
    "LR_HREC_HANDLE", "LR_HREC_DATA", "LR_HREC_LOGICAL", "LR_HREC_EXTENT",
    "LR_HREC_ACTIVE", "LR_HREC_STATE", "add.l %d1", "sub.l %d1",
]:
    if token not in handle_split:
        raise SystemExit("M3.22 static qualification FAIL: incomplete Handle split path: " + token)
if "LR_HEAP_NEXT" in handle_prelude + handle_setup + handle_split:
    raise SystemExit("M3.22 static qualification FAIL: Handle interior split modifies heap tail")

# The inactive Handle suffix must have a reserved master-pointer slot whose
# contents remain NULL until a later NewHandle reactivates the suffix record.
if "clr.l (%a3)" not in handle_split:
    raise SystemExit("M3.22 static qualification FAIL: Handle suffix master pointer is not cleared")

print("LibreROM M3.22 interior allocation hole splitting static qualification: PASS")
