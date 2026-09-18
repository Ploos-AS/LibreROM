#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_21.py")], check=True)
src = (root / "build/generated/reset_m3_21.S").read_text(encoding="utf-8")
src = src.replace("_m3_21", "_m3_22").replace("M3.21", "M3.22")
src = src.replace(
    "LIBREROM-M3.22-INTERIOR-HANDLE-REUSE",
    "LIBREROM-M3.22-INTERIOR-HOLE-SPLITTING",
)
state_symbols = (
    ".equ LR_TEST_STABLE_HANDLE,    0x00000454",
    ".equ LR_TEST_STABLE_HANDLE,    0x00000454"
    + chr(10) + "        .equ LR_TEST_BARRIER,          0x00000458"
    + chr(10) + "        .equ LR_TEST_HEAP_SNAPSHOT,    0x0000045c",
)
src = src.replace(*state_symbols)

# M3.19 widens all explicit short branches to word branches, and that widened
# source is inherited by M3.20/M3.21. Match the actual generated form here.
ptr_needle = '''        cmp.l LR_REC_EXTENT(%a1),%d1
        bhi.w 6f
        move.l %d4,LR_REC_LOGICAL(%a1)
        move.l #1,LR_REC_ACTIVE(%a1)
        move.l LR_REC_PTR(%a1),%a0
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
        rte
'''
ptr_replacement = '''        cmp.l LR_REC_EXTENT(%a1),%d1
        bhi.w 6f
        cmp.l LR_REC_EXTENT(%a1),%d1
        beq.w _m3_22_ptr_reuse_commit
        move.l %a1,%a4
        move.l #LR_ALLOC_TABLE,%a2
        moveq #LR_ALLOC_COUNT-1,%d6
_m3_22_ptr_split_record_scan:
        tst.l LR_REC_PTR(%a2)
        beq.w _m3_22_ptr_split_record_found
        adda.l #LR_ALLOC_REC_SIZE,%a2
        dbra %d6,_m3_22_ptr_split_record_scan
        move.l %a4,%a1
        bra.w _m3_22_ptr_reuse_commit
_m3_22_ptr_split_record_found:
        move.l %a4,%a1
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
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
        rte
'''
if ptr_needle not in src:
    raise SystemExit("M3.22 generator: Ptr reuse baseline not found")
src = src.replace(ptr_needle, ptr_replacement, 1)

handle_needle = '''        cmp.l LR_HREC_EXTENT(%a1),%d1
        bhi.w _m3_22_handle_reuse_next
        move.l LR_HREC_HANDLE(%a1),%a2
        move.l %d2,(%a2)
        move.l %d4,LR_HREC_LOGICAL(%a1)
        move.l #1,LR_HREC_ACTIVE(%a1)
        clr.l LR_HREC_STATE(%a1)
'''
handle_replacement = '''        cmp.l LR_HREC_EXTENT(%a1),%d1
        bhi.w _m3_22_handle_reuse_next
        cmp.l LR_HREC_EXTENT(%a1),%d1
        beq.w _m3_22_handle_reuse_commit
        move.l %a1,%a4
        move.l #LR_HANDLE_TABLE,%a5
        move.l #LR_MASTER_BASE,%a3
        moveq #LR_HANDLE_COUNT-1,%d6
_m3_22_handle_split_record_scan:
        tst.l LR_HREC_HANDLE(%a5)
        beq.w _m3_22_handle_split_record_found
        adda.l #LR_HANDLE_REC_SIZE,%a5
        addq.l #4,%a3
        dbra %d6,_m3_22_handle_split_record_scan
        move.l %a4,%a1
        bra.w _m3_22_handle_reuse_commit
_m3_22_handle_split_record_found:
        move.l %a4,%a1
        move.l %a3,LR_HREC_HANDLE(%a5)
        clr.l (%a3)
        move.l LR_HREC_DATA(%a1),%d2
        add.l %d1,%d2
        move.l %d2,LR_HREC_DATA(%a5)
        clr.l LR_HREC_LOGICAL(%a5)
        move.l LR_HREC_EXTENT(%a1),%d2
        sub.l %d1,%d2
        move.l %d2,LR_HREC_EXTENT(%a5)
        clr.l LR_HREC_ACTIVE(%a5)
        clr.l LR_HREC_STATE(%a5)
        move.l %d1,LR_HREC_EXTENT(%a1)
_m3_22_handle_reuse_commit:
        move.l LR_HREC_DATA(%a1),%d2
        move.l LR_HREC_HANDLE(%a1),%a2
        move.l %d2,(%a2)
        move.l %d4,LR_HREC_LOGICAL(%a1)
        move.l #1,LR_HREC_ACTIVE(%a1)
        clr.l LR_HREC_STATE(%a1)
'''
if handle_needle not in src:
    raise SystemExit("M3.22 generator: Handle reuse baseline not found")
src = src.replace(handle_needle, handle_replacement, 1)

start = src.index("        move.l #0x4d333231,0x00000400")
end_marker = "        move.l #0x4f4b3231,0x00000424      /* OK21 */"
end = src.index(end_marker, start) + len(end_marker)
fixture = '''        move.l #0x4d333232,0x00000400      /* M322 */
        /* Ptr: make a 0x40 interior hole with a live barrier above it. */
        move.l #0x40,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_22_fail
        move.l %a0,LR_TEST_PTR
        move.l #0x50323241,(%a0)
        move.l #0x40,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_22_fail
        move.l %a0,LR_TEST_BARRIER
        move.l #0x50323242,(%a0)
        move.l LR_HEAP_NEXT,LR_TEST_HEAP_SNAPSHOT
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_DISPOSE_PTR
        tst.w %d0
        bne.w _m3_22_fail
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_22_fail
        cmpa.l LR_TEST_PTR,%a0
        bne.w _m3_22_fail
        move.l LR_TEST_HEAP_SNAPSHOT,%d7\n        cmp.l LR_HEAP_NEXT,%d7
        bne.w _m3_22_fail
        move.l #0x50533232,0x00000404      /* PS22 */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_22_fail
        move.l LR_TEST_PTR,%a1
        adda.l #0x20,%a1
        cmpa.l %a1,%a0
        bne.w _m3_22_fail
        move.l LR_TEST_HEAP_SNAPSHOT,%d7\n        cmp.l LR_HEAP_NEXT,%d7
        bne.w _m3_22_fail
        move.l LR_TEST_BARRIER,%a5\n        cmpi.l #0x50323242,(%a5)
        bne.w _m3_22_fail
        move.l #0x50523232,0x00000408      /* PR22 */

        /* Handle: create a larger interior data extent below a Ptr barrier. */
        move.l #0x40,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_22_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l #0x40,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_22_fail
        move.l %a0,LR_TEST_BARRIER
        move.l #0x48323242,(%a0)
        move.l LR_HEAP_NEXT,LR_TEST_HEAP_SNAPSHOT
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_DISPOSE_HANDLE
        tst.w %d0
        bne.w _m3_22_fail
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_22_fail
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        bne.w _m3_22_fail
        move.l LR_TEST_HEAP_SNAPSHOT,%d7\n        cmp.l LR_HEAP_NEXT,%d7
        bne.w _m3_22_fail
        move.l #0x48533232,0x00000410      /* HS22 */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_22_fail
        move.l (%a0),%a1
        move.l LR_TEST_OLD_DATA,%a2
        adda.l #0x20,%a2
        cmpa.l %a2,%a1
        bne.w _m3_22_fail
        move.l LR_TEST_HEAP_SNAPSHOT,%d7\n        cmp.l LR_HEAP_NEXT,%d7
        bne.w _m3_22_fail
        move.l LR_TEST_BARRIER,%a5\n        cmpi.l #0x48323242,(%a5)
        bne.w _m3_22_fail
        move.l #0x48523232,0x00000414      /* HR22 */

        /* No-free-record fallback: create one interior 0x40 Ptr hole, then
           mark every otherwise never-used Ptr record as occupied metadata.
           This deterministically removes suffix-record capacity without
           consuming heap space or depending on prior fixture allocation count. */
        move.l #0x40,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_22_fail
        move.l %a0,LR_TEST_PTR
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_22_fail
        move.l LR_HEAP_NEXT,LR_TEST_HEAP_SNAPSHOT
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_DISPOSE_PTR
        tst.w %d0
        bne.w _m3_22_fail
        move.l #LR_ALLOC_TABLE,%a1
        moveq #LR_ALLOC_COUNT-1,%d6
_m3_22_fallback_occupy_records:
        tst.l LR_REC_PTR(%a1)
        bne.w _m3_22_fallback_occupy_next
        move.l #0x00f00000,LR_REC_PTR(%a1)
        clr.l LR_REC_LOGICAL(%a1)
        clr.l LR_REC_EXTENT(%a1)
        clr.l LR_REC_ACTIVE(%a1)
_m3_22_fallback_occupy_next:
        adda.l #LR_ALLOC_REC_SIZE,%a1
        dbra %d6,_m3_22_fallback_occupy_records
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_22_fail
        cmpa.l LR_TEST_PTR,%a0
        bne.w _m3_22_fail
        move.l LR_TEST_HEAP_SNAPSHOT,%d7
        cmp.l LR_HEAP_NEXT,%d7
        bne.w _m3_22_fail
        move.l #0x46423232,0x00000418      /* FB22 */
        move.l #0x4f4b3232,0x00000424      /* OK22 */
        bra.w _m3_22_done'''
src = src[:start] + fixture + src[end:]

out = root / "build/generated/reset_m3_22.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
