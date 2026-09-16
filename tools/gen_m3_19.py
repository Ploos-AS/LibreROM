#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_18.py")], check=True)
src = (root / "build/generated/reset_m3_18.S").read_text(encoding="utf-8")
src = src.replace("_m3_18", "_m3_19").replace("M3.18", "M3.19")
src = src.replace("LIBREROM-M3.19-HANDLE-TAIL-RECLAIM", "LIBREROM-M3.19-MIXED-TAIL-COALESCE")

# M3.19 closes the cross-kind gap: after either Ptr or Handle tail rewind,
# repeatedly absorb inactive predecessor records from BOTH allocation tables.
# The helper is deliberately conservative: only inactive records ending exactly
# at LR_HEAP_NEXT are reclaimed; live Ptrs/Handles never move here.
handle_scan = '''82:     move.l #LR_HANDLE_TABLE,%a2
        moveq #LR_HANDLE_COUNT-1,%d3
83:     tst.l LR_HREC_ACTIVE(%a2)
        bne.s 84f
        move.l LR_HREC_DATA(%a2),%d4
        beq.s 84f
        move.l %d4,%d6
        add.l LR_HREC_EXTENT(%a2),%d6
        cmp.l LR_HEAP_NEXT,%d6
        bne.s 84f
        move.l %d4,LR_HEAP_NEXT
        clr.l LR_HREC_DATA(%a2)
        clr.l LR_HREC_LOGICAL(%a2)
        clr.l LR_HREC_EXTENT(%a2)
        bra.s 82b
84:     adda.l #LR_HANDLE_REC_SIZE,%a2
        dbra %d3,83b
'''
mixed_scan = '''82:     moveq #0,%d7
        move.l #LR_HANDLE_TABLE,%a2
        moveq #LR_HANDLE_COUNT-1,%d3
83:     tst.l LR_HREC_ACTIVE(%a2)
        bne.w 84f
        move.l LR_HREC_DATA(%a2),%d4
        beq.w 84f
        move.l %d4,%d6
        add.l LR_HREC_EXTENT(%a2),%d6
        cmp.l LR_HEAP_NEXT,%d6
        bne.w 84f
        move.l %d4,LR_HEAP_NEXT
        clr.l LR_HREC_DATA(%a2)
        clr.l LR_HREC_LOGICAL(%a2)
        clr.l LR_HREC_EXTENT(%a2)
        moveq #1,%d7
        bra.w 87f
84:     adda.l #LR_HANDLE_REC_SIZE,%a2
        dbra %d3,83b
        move.l #LR_ALLOC_TABLE,%a2
        moveq #LR_ALLOC_COUNT-1,%d3
85:     tst.l LR_REC_ACTIVE(%a2)
        bne.w 86f
        move.l LR_REC_PTR(%a2),%d4
        beq.w 86f
        move.l %d4,%d6
        add.l LR_REC_EXTENT(%a2),%d6
        cmp.l LR_HEAP_NEXT,%d6
        bne.w 86f
        move.l %d4,LR_HEAP_NEXT
        clr.l LR_REC_PTR(%a2)
        clr.l LR_REC_LOGICAL(%a2)
        clr.l LR_REC_EXTENT(%a2)
        moveq #1,%d7
        bra.w 87f
86:     adda.l #LR_ALLOC_REC_SIZE,%a2
        dbra %d3,85b
87:     tst.l %d7
        bne.w 82b
'''
if handle_scan not in src:
    raise SystemExit("M3.19 generator: Handle predecessor scan baseline not found")
src = src.replace(handle_scan, mixed_scan, 1)

# Extend the Ptr disposal coalescer with inactive Handle predecessors too.
ptr_end = '''74:     adda.l #LR_ALLOC_REC_SIZE,%a2
        dbra %d3,73b
71:     moveq #MAC_NO_ERR,%d0
'''
ptr_end_new = '''74:     adda.l #LR_ALLOC_REC_SIZE,%a2
        dbra %d3,73b
        move.l #LR_HANDLE_TABLE,%a2
        moveq #LR_HANDLE_COUNT-1,%d3
75:     tst.l LR_HREC_ACTIVE(%a2)
        bne.w 76f
        move.l LR_HREC_DATA(%a2),%d4
        beq.w 76f
        move.l %d4,%d6
        add.l LR_HREC_EXTENT(%a2),%d6
        cmp.l LR_HEAP_NEXT,%d6
        bne.w 76f
        move.l %d4,LR_HEAP_NEXT
        clr.l LR_HREC_DATA(%a2)
        clr.l LR_HREC_LOGICAL(%a2)
        clr.l LR_HREC_EXTENT(%a2)
        bra.w 72b
76:     adda.l #LR_HANDLE_REC_SIZE,%a2
        dbra %d3,75b
71:     moveq #MAC_NO_ERR,%d0
'''
if ptr_end not in src:
    raise SystemExit("M3.19 generator: Ptr coalescing baseline not found")
src = src.replace(ptr_end, ptr_end_new, 1)

# Replace the M3.18 fixture with two cross-kind cases. First, dispose an
# interior Ptr then a tail Handle; second, dispose an interior Handle then a
# tail Ptr. Both must recover the complete 0x100-byte tail arena.
start = src.index("        move.l #0x4d333138,0x00000400")
end_marker = "        move.l #0x4f4b3138,0x00000424      /* OK18 */"
end = src.index(end_marker, start) + len(end_marker)
new_test = '''        move.l #0x4d333139,0x00000400      /* M319 */
        move.l #0x0006ff00,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_19_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l LR_TEST_OLD_DATA,%a1
        move.l #0x4b503139,(%a1)           /* KP19 */

        /* Case A: inactive Ptr predecessor + disposed tail Handle. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_19_fail
        move.l %a0,LR_TEST_PTR
        move.l #0xe0,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_19_fail
        move.l %a0,%a5
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_DISPOSE_PTR
        tst.w %d0
        bne.w _m3_19_fail
        move.l %a5,%a0
        .word MAC_TRAP_DISPOSE_HANDLE
        tst.w %d0
        bne.w _m3_19_fail
        cmpi.l #0x0007ff00,LR_HEAP_NEXT
        bne.w _m3_19_fail
        move.l #0x50483139,0x00000410      /* PH19 */

        /* Refill then free the recovered tail for the inverse case. */
        move.l #0x100,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_19_fail
        .word MAC_TRAP_DISPOSE_HANDLE
        tst.w %d0
        bne.w _m3_19_fail
        cmpi.l #0x0007ff00,LR_HEAP_NEXT
        bne.w _m3_19_fail

        /* Case B: inactive Handle predecessor + disposed tail Ptr. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_19_fail
        move.l %a0,LR_TEST_PTR
        move.l #0xe0,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_19_fail
        move.l %a0,%a5
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_DISPOSE_HANDLE
        tst.w %d0
        bne.w _m3_19_fail
        move.l %a5,%a0
        .word MAC_TRAP_DISPOSE_PTR
        tst.w %d0
        bne.w _m3_19_fail
        cmpi.l #0x0007ff00,LR_HEAP_NEXT
        bne.w _m3_19_fail
        move.l #0x48503139,0x00000414      /* HP19 */

        move.l #0x100,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_19_fail
        cmpi.l #0x0007ff00,(%a0)
        bne.w _m3_19_fail
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_19_fail
        move.l (%a0),%a1
        move.l #0x4e483139,(%a1)           /* NH19 */
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        bne.w _m3_19_fail
        cmpi.l #0x4b503139,(%a1)
        bne.w _m3_19_fail
        move.l #0x4f4b3139,0x00000424      /* OK19 */'''
src = src[:start] + new_test + src[end:]

out = root / "build/generated/reset_m3_19.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
