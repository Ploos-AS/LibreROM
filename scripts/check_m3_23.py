#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_23.py")], check=True)
src = (root / "build/generated/reset_m3_23.S").read_text(encoding="utf-8")
ld = (root / "linker/m3_23.ld").read_text(encoding="utf-8")

required = [
    "_m3_23_reset",
    "_m3_23_new_ptr",
    "_m3_23_new_handle",
    "_m3_23_coalesce_ptr_hole",
    "_m3_23_coalesce_ptr_restart",
    "_m3_23_coalesce_ptr_scan",
    "_m3_23_coalesce_ptr_check_below",
    "_m3_23_coalesce_handle_hole",
    "_m3_23_coalesce_handle_restart",
    "_m3_23_coalesce_handle_check_below",
    "LIBREROM-M3.23-INTERIOR-FREE-COALESCING",
]
missing = [x for x in required if x not in src]
if missing:
    raise SystemExit("M3.23 static qualification FAIL: missing " + ", ".join(missing))

if "ENTRY(_m3_23_reset)" not in ld or "LENGTH = 128K" not in ld:
    raise SystemExit("M3.23 static qualification FAIL: linker contract")

start = src.index("_m3_23_coalesce_ptr_hole:")
end = src.index("_m3_23_done:", start)
body = src[start:end]
for token in [
    "tst.l LR_REC_ACTIVE(%a2)",
    "add.l LR_REC_EXTENT(%a1),%d0",
    "add.l LR_REC_EXTENT(%a2),%d0",
    "add.l %d1,LR_REC_EXTENT(%a1)",
    "add.l %d1,LR_REC_EXTENT(%a2)",
    "clr.l LR_REC_PTR(%a2)",
    "clr.l LR_REC_PTR(%a1)",
    "bra.w _m3_23_coalesce_ptr_restart",
]:
    if token not in body:
        raise SystemExit("M3.23 static qualification FAIL: Ptr coalescing contract: " + token)

if "LR_HEAP_NEXT" in body:
    raise SystemExit("M3.23 static qualification FAIL: interior coalescer modifies heap tail")

# M3.22 split/reuse machinery must remain present underneath M3.23.
for token in [
    "_m3_23_ptr_split_record_scan",
    "_m3_23_handle_split_record_scan",
    "_m3_23_ptr_reuse_commit",
    "_m3_23_handle_reuse_commit",
]:
    if token not in src:
        raise SystemExit("M3.23 static qualification FAIL: M3.22 regression surface missing: " + token)

hstart = src.index("_m3_23_coalesce_handle_hole:")
hend = src.index("_m3_23_done:", hstart)
hbody = src[hstart:hend]
for token in [
    "tst.l LR_HREC_ACTIVE(%a2)",
    "LR_HREC_DATA",
    "LR_HREC_EXTENT",
    "add.l %d1,LR_HREC_EXTENT(%a1)",
    "add.l %d1,LR_HREC_EXTENT(%a2)",
    "clr.l (%a3)",
    "clr.l LR_HREC_DATA(%a2)",
    "clr.l LR_HREC_DATA(%a1)",
    "clr.l LR_HREC_STATE(%a2)",
    "clr.l LR_HREC_STATE(%a1)",
]:
    if token not in hbody:
        raise SystemExit("M3.23 static qualification FAIL: Handle coalescing contract: " + token)
if "LR_HEAP_NEXT" in hbody:
    raise SystemExit("M3.23 static qualification FAIL: Handle interior coalescer modifies heap tail")

print("LibreROM M3.23 Ptr/Handle interior coalescing static qualification: PASS")
