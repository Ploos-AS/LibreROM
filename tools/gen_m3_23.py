#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_22.py")], check=True)
src = (root / "build/generated/reset_m3_22.S").read_text(encoding="utf-8")
src = src.replace("_m3_22", "_m3_23").replace("M3.22", "M3.23")
src = src.replace(
    "LIBREROM-M3.23-INTERIOR-HOLE-SPLITTING",
    "LIBREROM-M3.23-INTERIOR-FREE-COALESCING",
)

# M3.23 starts by adding a bounded coalescing primitive for inactive Ptr
# extents. It is deliberately invoked after DisposePtr's existing tail
# reclamation path has decided that the disposed extent remains interior.
# Hook the coalescer immediately after DisposePtr marks its matched record
# inactive. Match the stable instruction pair rather than later tail-reclaim
# details, which evolved across M3.16-M3.22.
needle = """        clr.l LR_REC_ACTIVE(%a1)
"""
replacement = """        clr.l LR_REC_ACTIVE(%a1)
        bsr.w _m3_23_coalesce_ptr_hole
"""
matches = src.count(needle)
if matches < 1:
    raise SystemExit("M3.23 generator: DisposePtr inactive transition not found")
# The first occurrence belongs to DisposePtr in the inherited service code;
# later occurrences are split-suffix/fallback metadata initialization.
src = src.replace(needle, replacement, 1)

# DisposeHandle retains metadata for interior holes. Hook a bounded Handle
# coalescer after the first inherited active-state clear in DisposeHandle.
handle_anchor = """        clr.l LR_HREC_ACTIVE(%a1)
"""
if handle_anchor not in src:
    raise SystemExit("M3.23 generator: DisposeHandle inactive transition not found")
src = src.replace(handle_anchor, handle_anchor + "        bsr.w _m3_23_coalesce_handle_hole" + chr(10) + "        bsr.w _m3_23_coalesce_mixed_from_handle" + chr(10), 1)

insert_at = src.index("_m3_23_done:")
helper = """_m3_23_coalesce_ptr_hole:
        /* a1 = newly inactive Ptr record. Merge adjacent inactive Ptr
           records in either direction; restart after every merge so chains
           converge deterministically. */
        movem.l %d0-%d3/%a0-%a3,-(%sp)
_m3_23_coalesce_ptr_restart:
        move.l #LR_ALLOC_TABLE,%a2
        moveq #LR_ALLOC_COUNT-1,%d3
_m3_23_coalesce_ptr_scan:
        cmpa.l %a1,%a2
        beq.w _m3_23_coalesce_ptr_next
        tst.l LR_REC_PTR(%a2)
        beq.w _m3_23_coalesce_ptr_next
        tst.l LR_REC_ACTIVE(%a2)
        bne.w _m3_23_coalesce_ptr_next

        /* Candidate immediately above current hole. */
        move.l LR_REC_PTR(%a1),%d0
        add.l LR_REC_EXTENT(%a1),%d0
        cmp.l LR_REC_PTR(%a2),%d0
        bne.w _m3_23_coalesce_ptr_check_below
        move.l LR_REC_EXTENT(%a2),%d1
        add.l %d1,LR_REC_EXTENT(%a1)
        clr.l LR_REC_PTR(%a2)
        clr.l LR_REC_LOGICAL(%a2)
        clr.l LR_REC_EXTENT(%a2)
        clr.l LR_REC_ACTIVE(%a2)
        bra.w _m3_23_coalesce_ptr_restart

_m3_23_coalesce_ptr_check_below:
        /* Candidate immediately below current hole: keep the lower record
           and retire the current record, then continue from the survivor. */
        move.l LR_REC_PTR(%a2),%d0
        add.l LR_REC_EXTENT(%a2),%d0
        cmp.l LR_REC_PTR(%a1),%d0
        bne.w _m3_23_coalesce_ptr_next
        move.l LR_REC_EXTENT(%a1),%d1
        add.l %d1,LR_REC_EXTENT(%a2)
        clr.l LR_REC_PTR(%a1)
        clr.l LR_REC_LOGICAL(%a1)
        clr.l LR_REC_EXTENT(%a1)
        clr.l LR_REC_ACTIVE(%a1)
        move.l %a2,%a1
        bra.w _m3_23_coalesce_ptr_restart

_m3_23_coalesce_ptr_next:
        adda.l #LR_ALLOC_REC_SIZE,%a2
        dbra %d3,_m3_23_coalesce_ptr_scan
        movem.l (%sp)+,%d0-%d3/%a0-%a3
        rts

"""
mixed_helper = """_m3_23_coalesce_mixed_from_ptr:
        /* a1 = inactive Ptr record. Merge one adjacent inactive Handle extent
           into the Ptr record, retire the Handle data extent, then return. */
        movem.l %d0-%d3/%a0-%a3,-(%sp)
        move.l #LR_HANDLE_TABLE,%a2
        moveq #LR_HANDLE_COUNT-1,%d3
_m3_23_mixed_ptr_scan:
        tst.l LR_HREC_HANDLE(%a2)
        beq.w _m3_23_mixed_ptr_next
        tst.l LR_HREC_ACTIVE(%a2)
        bne.w _m3_23_mixed_ptr_next
        move.l LR_HREC_DATA(%a2),%d2
        beq.w _m3_23_mixed_ptr_next
        move.l LR_REC_PTR(%a1),%d0
        add.l LR_REC_EXTENT(%a1),%d0
        cmp.l LR_HREC_DATA(%a2),%d0
        beq.w _m3_23_mixed_ptr_absorb_handle
        move.l LR_HREC_DATA(%a2),%d0
        add.l LR_HREC_EXTENT(%a2),%d0
        cmp.l LR_REC_PTR(%a1),%d0
        bne.w _m3_23_mixed_ptr_next
        move.l LR_HREC_DATA(%a2),LR_REC_PTR(%a1)
_m3_23_mixed_ptr_absorb_handle:
        move.l LR_HREC_EXTENT(%a2),%d1
        add.l %d1,LR_REC_EXTENT(%a1)
        move.l LR_HREC_HANDLE(%a2),%a3
        clr.l (%a3)
        clr.l LR_HREC_DATA(%a2)
        clr.l LR_HREC_LOGICAL(%a2)
        clr.l LR_HREC_EXTENT(%a2)
        clr.l LR_HREC_ACTIVE(%a2)
        clr.l LR_HREC_STATE(%a2)
        bra.w _m3_23_mixed_ptr_done
_m3_23_mixed_ptr_next:
        adda.l #LR_HANDLE_REC_SIZE,%a2
        dbra %d3,_m3_23_mixed_ptr_scan
_m3_23_mixed_ptr_done:
        movem.l (%sp)+,%d0-%d3/%a0-%a3
        rts

_m3_23_coalesce_mixed_from_handle:
        /* a1 = inactive Handle record. Prefer the Ptr record as survivor so
           mixed free space remains directly reusable by NewPtr. */
        movem.l %d0-%d3/%a0-%a3,-(%sp)
        move.l #LR_ALLOC_TABLE,%a2
        moveq #LR_ALLOC_COUNT-1,%d3
_m3_23_mixed_handle_scan:
        tst.l LR_REC_PTR(%a2)
        beq.w _m3_23_mixed_handle_next
        tst.l LR_REC_ACTIVE(%a2)
        bne.w _m3_23_mixed_handle_next
        move.l LR_REC_PTR(%a2),%d0
        add.l LR_REC_EXTENT(%a2),%d0
        cmp.l LR_HREC_DATA(%a1),%d0
        beq.w _m3_23_mixed_handle_absorb
        move.l LR_HREC_DATA(%a1),%d0
        add.l LR_HREC_EXTENT(%a1),%d0
        cmp.l LR_REC_PTR(%a2),%d0
        bne.w _m3_23_mixed_handle_next
        move.l LR_HREC_DATA(%a1),LR_REC_PTR(%a2)
_m3_23_mixed_handle_absorb:
        move.l LR_HREC_EXTENT(%a1),%d1
        add.l %d1,LR_REC_EXTENT(%a2)
        move.l LR_HREC_HANDLE(%a1),%a3
        clr.l (%a3)
        clr.l LR_HREC_DATA(%a1)
        clr.l LR_HREC_LOGICAL(%a1)
        clr.l LR_HREC_EXTENT(%a1)
        clr.l LR_HREC_ACTIVE(%a1)
        clr.l LR_HREC_STATE(%a1)
        bra.w _m3_23_mixed_handle_done
_m3_23_mixed_handle_next:
        adda.l #LR_ALLOC_REC_SIZE,%a2
        dbra %d3,_m3_23_mixed_handle_scan
_m3_23_mixed_handle_done:
        movem.l (%sp)+,%d0-%d3/%a0-%a3
        rts

"""
handle_helper = """_m3_23_coalesce_handle_hole:
        /* a1 = newly inactive Handle record. Coalesce adjacent inactive
           Handle data extents; the lower-address record survives. */
        movem.l %d0-%d3/%a0-%a3,-(%sp)
_m3_23_coalesce_handle_restart:
        move.l #LR_HANDLE_TABLE,%a2
        moveq #LR_HANDLE_COUNT-1,%d3
_m3_23_coalesce_handle_scan:
        cmpa.l %a1,%a2
        beq.w _m3_23_coalesce_handle_next
        tst.l LR_HREC_HANDLE(%a2)
        beq.w _m3_23_coalesce_handle_next
        tst.l LR_HREC_ACTIVE(%a2)
        bne.w _m3_23_coalesce_handle_next
        move.l LR_HREC_DATA(%a2),%d2
        beq.w _m3_23_coalesce_handle_next

        move.l LR_HREC_DATA(%a1),%d0
        add.l LR_HREC_EXTENT(%a1),%d0
        cmp.l LR_HREC_DATA(%a2),%d0
        bne.w _m3_23_coalesce_handle_check_below
        move.l LR_HREC_EXTENT(%a2),%d1
        add.l %d1,LR_HREC_EXTENT(%a1)
        move.l LR_HREC_HANDLE(%a2),%a3
        clr.l (%a3)
        clr.l LR_HREC_DATA(%a2)
        clr.l LR_HREC_LOGICAL(%a2)
        clr.l LR_HREC_EXTENT(%a2)
        clr.l LR_HREC_ACTIVE(%a2)
        clr.l LR_HREC_STATE(%a2)
        bra.w _m3_23_coalesce_handle_restart

_m3_23_coalesce_handle_check_below:
        move.l LR_HREC_DATA(%a2),%d0
        add.l LR_HREC_EXTENT(%a2),%d0
        cmp.l LR_HREC_DATA(%a1),%d0
        bne.w _m3_23_coalesce_handle_next
        move.l LR_HREC_EXTENT(%a1),%d1
        add.l %d1,LR_HREC_EXTENT(%a2)
        move.l LR_HREC_HANDLE(%a1),%a3
        clr.l (%a3)
        clr.l LR_HREC_DATA(%a1)
        clr.l LR_HREC_LOGICAL(%a1)
        clr.l LR_HREC_EXTENT(%a1)
        clr.l LR_HREC_ACTIVE(%a1)
        clr.l LR_HREC_STATE(%a1)
        move.l %a2,%a1
        bra.w _m3_23_coalesce_handle_restart

_m3_23_coalesce_handle_next:
        adda.l #LR_HANDLE_REC_SIZE,%a2
        dbra %d3,_m3_23_coalesce_handle_scan
        movem.l (%sp)+,%d0-%d3/%a0-%a3
        rts

"""
src = src[:insert_at] + helper + handle_helper + mixed_helper + src[insert_at:]

out = root / "build/generated/reset_m3_23.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
