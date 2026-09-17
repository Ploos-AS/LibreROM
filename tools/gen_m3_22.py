#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_21.py")], check=True)
src = (root / "build/generated/reset_m3_21.S").read_text(encoding="utf-8")
src = src.replace("_m3_21", "_m3_22").replace("M3.21", "M3.22")
src = src.replace("LIBREROM-M3.22-INTERIOR-HANDLE-REUSE", "LIBREROM-M3.22-INTERIOR-HOLE-SPLITTING")

# M3.20's Ptr reuse consumes the complete retained extent.  M3.22 phase A
# splits a larger inactive Ptr extent when an unused Ptr-table record exists.
# If no record is available, the qualified M3.20 behavior is retained: the
# whole extent is safely consumed rather than losing allocation metadata.
needle = '''        cmp.l LR_REC_EXTENT(%a1),%d1
        bhi.s 6f
        move.l %d4,LR_REC_LOGICAL(%a1)
        move.l #1,LR_REC_ACTIVE(%a1)
        move.l LR_REC_PTR(%a1),%a0
'''
replacement = '''        cmp.l LR_REC_EXTENT(%a1),%d1
        bhi.s 6f
        /* Exact fit needs no suffix record. */
        cmp.l LR_REC_EXTENT(%a1),%d1
        beq.s _m3_22_ptr_reuse_commit
        /* Preserve the candidate while looking for a truly unused record. */
        move.l %a1,%a4
        move.l #LR_ALLOC_TABLE,%a2
        moveq #LR_ALLOC_COUNT-1,%d6
_m3_22_ptr_split_record_scan:
        tst.l LR_REC_PTR(%a2)
        beq.s _m3_22_ptr_split_record_found
        adda.l #LR_ALLOC_REC_SIZE,%a2
        dbra %d6,_m3_22_ptr_split_record_scan
        move.l %a4,%a1
        bra.s _m3_22_ptr_reuse_commit
_m3_22_ptr_split_record_found:
        move.l %a4,%a1
        /* a2 becomes an inactive suffix record. */
        move.l LR_REC_PTR(%a1),%d2
        add.l %d1,%d2
        move.l %d2,LR_REC_PTR(%a2)
        clr.l LR_REC_LOGICAL(%a2)
        move.l LR_REC_EXTENT(%a1),%d2
        sub.l %d1,%d2
        move.l %d2,LR_REC_EXTENT(%a2)
        clr.l LR_REC_ACTIVE(%a2)
        move.l %d1,LR_REC_EXTENT(%a1)
_m3_22_ptr_reuse_commit:
        move.l %d4,LR_REC_LOGICAL(%a1)
        move.l #1,LR_REC_ACTIVE(%a1)
        move.l LR_REC_PTR(%a1),%a0
'''
if needle not in src:
    raise SystemExit("M3.22 generator: Ptr reuse baseline not found")
src = src.replace(needle, replacement, 1)

out = root / "build/generated/reset_m3_22.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
