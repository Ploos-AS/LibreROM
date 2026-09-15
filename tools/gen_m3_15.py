#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_14.py")], check=True)
src = (root / "build/generated/reset_m3_14.S").read_text(encoding="utf-8")
src = src.replace("_m3_14", "_m3_15")
src = src.replace("M3.14", "M3.15")
src = src.replace("LIBREROM-M3.15-ADDRESS-ORDERED-COMPACTION", "LIBREROM-M3.15-MIXED-PTR-HANDLE-COMPACTION")
for a,b in [("0x50523134","0x50523135"),("0x53563134","0x53563135"),("0x45583134","0x45583135"),("0x42443134","0x42443135")]:
    src = src.replace(a,b)

start = src.index("        move.l #0x4d333134,0x00000400")
end_marker = "        move.l #0x4f4b3134,0x00000424      /* OK14 */"
end = src.index(end_marker, start) + len(end_marker)
new_test = '''        move.l #0x4d333135,0x00000400      /* M315 */

        /* Stable lower Handle leaves a compact deterministic arena. */
        move.l #0x0006ff00,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_15_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l LR_TEST_OLD_DATA,%a1
        move.l #0x4b503135,(%a1)           /* KP15 */

        /* A non-relocatable Ptr is a fixed barrier in the shared heap. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_15_fail
        cmpa.l #0x0007ff00,%a0
        bne.w _m3_15_fail
        move.l %a0,LR_TEST_PTR
        move.l #0x50543135,(%a0)           /* PT15 */

        /* A becomes a real hole between the Ptr and later Handles. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_15_fail
        move.l %a0,%a5                     /* A: master slot 1 */

        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_15_fail
        move.l (%a0),%a1                   /* B: master slot 2 */
        move.l #0x42323135,(%a1)           /* B215 */

        move.l #0xa0,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_15_fail
        move.l (%a0),%a1                   /* C: master slot 3 */
        move.l #0x43333135,(%a1)           /* C315 */
        move.l #0x43543135,0x9c(%a1)       /* CT15 */
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_15_fail

        move.l %a5,%a0
        .word MAC_TRAP_DISPOSE_HANDLE
        tst.w %d0
        bne.w _m3_15_fail
        move.l #0x484f3135,0x0000040c      /* HO15 */

        /* Pressure must compact Handles above the Ptr without moving or
           overwriting the Ptr barrier. The disposed Handle slot is reused. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_15_fail
        cmpa.l #LR_MASTER_BASE+4,%a0
        bne.w _m3_15_fail
        cmpi.l #0x0007ffe0,(%a0)
        bne.w _m3_15_fail
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_15_fail
        move.l #0x43503135,0x00000410      /* CP15 */

        /* Ptr stays fixed; B/C close the hole above it. */
        move.l LR_TEST_PTR,%a1
        cmpa.l #0x0007ff00,%a1
        bne.w _m3_15_fail
        cmpi.l #0x50543135,(%a1)
        bne.w _m3_15_fail
        cmpi.l #0x0007ff20,LR_MASTER_BASE+8
        bne.w _m3_15_fail
        cmpi.l #0x0007ff40,LR_MASTER_BASE+12
        bne.w _m3_15_fail
        cmpi.l #0x0007ffe0,LR_MASTER_BASE+4
        bne.w _m3_15_fail
        move.l #0x50423135,0x00000414      /* PB15 */

        /* Relocated Handle payloads survive around the fixed Ptr. */
        cmpi.l #0x42323135,0x0007ff20
        bne.w _m3_15_fail
        cmpi.l #0x43333135,0x0007ff40
        bne.w _m3_15_fail
        cmpi.l #0x43543135,0x0007ffdc
        bne.w _m3_15_fail
        move.l #0x504c3135,0x00000418      /* PL15 */

        /* Stable lower Handle also remains untouched. */
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        bne.w _m3_15_fail
        cmpi.l #0x4b503135,(%a1)
        bne.w _m3_15_fail
        move.l #0x4b503135,0x0000041c      /* KP15 */

        move.l #0x4f4b3135,0x00000424      /* OK15 */'''
src = src[:start] + new_test + src[end:]

comp_start = src.index("_m3_15_compact_handles:")
comp_end = src.index("_m3_15_reclaim_purgeable_tail:", comp_start)
compactor = '''_m3_15_compact_handles:
        move.l #LR_HEAP_BASE,%d7
57:     /* Select the lowest live Handle at/above the cursor. */
        move.l #LR_HANDLE_TABLE,%a1
        moveq #LR_HANDLE_COUNT-1,%d3
        suba.l %a4,%a4
        move.l #LR_HEAP_LIMIT,%d4
58:     tst.l LR_HREC_ACTIVE(%a1)
        beq.s 61f
        move.l LR_HREC_HANDLE(%a1),%a2
        tst.l (%a2)
        beq.s 61f
        move.l LR_HREC_DATA(%a1),%d2
        cmp.l %d7,%d2
        blo.s 61f
        cmp.l %d4,%d2
        bhs.s 61f
        move.l %d2,%d4
        move.l %a1,%a4
61:     adda.l #LR_HANDLE_REC_SIZE,%a1
        dbra %d3,58b

        /* Select the lowest active Ptr. Ptrs cannot relocate, so they are
           fixed barriers in the same physical heap. */
        move.l #LR_ALLOC_TABLE,%a1
        moveq #LR_ALLOC_COUNT-1,%d3
        suba.l %a5,%a5
        move.l #LR_HEAP_LIMIT,%d5
62:     tst.l LR_REC_ACTIVE(%a1)
        beq.s 63f
        move.l LR_REC_PTR(%a1),%d2
        cmp.l %d7,%d2
        blo.s 63f
        cmp.l %d5,%d2
        bhs.s 63f
        move.l %d2,%d5
        move.l %a1,%a5
63:     adda.l #LR_ALLOC_REC_SIZE,%a1
        dbra %d3,62b

        move.l %a5,%d0
        beq.s 64f
        move.l %a4,%d0
        beq.s 69f
        cmp.l %d4,%d5
        blo.s 69f
64:     move.l %a4,%d0
        beq.s 70f
        move.l %a4,%a1
        move.l LR_HREC_DATA(%a1),%d2
        move.l LR_HREC_STATE(%a1),%d0
        btst #7,%d0
        bne.s 68f
        cmp.l %d7,%d2
        beq.s 67f
        move.l %d2,%a2
        move.l %d7,%a3
        move.l LR_HREC_EXTENT(%a1),%d6
        beq.s 66f
65:     move.b (%a2)+,(%a3)+
        subq.l #1,%d6
        bne.s 65b
66:     move.l %d7,LR_HREC_DATA(%a1)
        move.l LR_HREC_HANDLE(%a1),%a2
        move.l %d7,(%a2)
67:     add.l LR_HREC_EXTENT(%a1),%d7
        bra.w 57b
68:     move.l %d2,%d7
        add.l LR_HREC_EXTENT(%a1),%d7
        bra.w 57b
69:     move.l %a5,%a1
        move.l LR_REC_PTR(%a1),%d7
        add.l LR_REC_EXTENT(%a1),%d7
        bra.w 57b
70:     move.l %d7,LR_HEAP_NEXT
        moveq #0,%d5
        rts

'''
src = src[:comp_start] + compactor + src[comp_end:]

out = root / "build/generated/reset_m3_15.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
