#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_13.py")], check=True)
src = (root / "build/generated/reset_m3_13.S").read_text(encoding="utf-8")
src = src.replace("_m3_13", "_m3_14")
src = src.replace("M3.13", "M3.14")
src = src.replace("LIBREROM-M3.14-HANDLE-COMPACTION", "LIBREROM-M3.14-ADDRESS-ORDERED-COMPACTION")
src = src.replace("0x50523133", "0x50523134")
src = src.replace("0x53563133", "0x53563134")
src = src.replace("0x45583133", "0x45583134")
src = src.replace("0x42443133", "0x42443134")

start = src.index("        move.l #0x4d333133,0x00000400")
end_marker = "        move.l #0x4f4b3133,0x00000424      /* OK13 */"
end = src.index(end_marker, start) + len(end_marker)
new_test = '''        move.l #0x4d333134,0x00000400      /* M314 */

        /* Large stable lower handle leaves a small deterministic arena at the top. */
        move.l #0x0006ff40,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_14_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l LR_TEST_OLD_DATA,%a1
        move.l #0x4b503134,(%a1)           /* KP14 */

        /* A is older in the handle table than B and C. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_14_fail
        move.l %a0,LR_TEST_PTR             /* A: master slot 1 */

        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_14_fail
        move.l (%a0),%a1                   /* B: master slot 2 */
        move.l #0x42323134,(%a1)           /* B214 */

        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_14_fail
        move.l (%a0),%a1                   /* C: master slot 3 */
        move.l #0x43333134,(%a1)           /* C314 */

        /* Growing non-tail A relocates it after B/C, making record order differ
           from physical address order: B, C, A. */
        move.l LR_TEST_PTR,%a0
        move.l #0x40,%d0
        .word MAC_TRAP_SET_HANDLE_SIZE
        tst.w %d0
        bne.w _m3_14_fail
        move.l LR_TEST_PTR,%a0
        move.l (%a0),%a1
        cmpa.l #0x0007ffa0,%a1
        bne.w _m3_14_fail
        move.l #0x41313134,(%a1)           /* A114 */
        move.l #0x41543134,0x3c(%a1)       /* AT14 */
        move.l #0x4f4f3134,0x0000040c      /* OO14 */

        /* D fills the tail so the next allocation requires compaction. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_14_fail
        move.l (%a0),%a1                   /* D: master slot 4 */
        cmpa.l #0x0007ffe0,%a1
        bne.w _m3_14_fail
        move.l #0x44343134,(%a1)           /* D414 */
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_14_fail

        /* Address-ordered compaction must close A's old 0x20-byte hole without
           allowing table-order A to overwrite the lower B block. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_14_fail
        cmpa.l #LR_MASTER_BASE+20,%a0
        bne.w _m3_14_fail
        move.l (%a0),%d6
        cmpi.l #0x0007ffe0,%d6
        bne.w _m3_14_fail
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_14_fail
        move.l #0x43503134,0x00000410      /* CP14 */

        /* Physical order after compaction: B, C, A, D, new allocation. */
        cmpi.l #0x00010000,LR_MASTER_BASE
        bne.w _m3_14_fail
        cmpi.l #0x0007ff80,LR_MASTER_BASE+4
        bne.w _m3_14_fail
        cmpi.l #0x0007ff40,LR_MASTER_BASE+8
        bne.w _m3_14_fail
        cmpi.l #0x0007ff60,LR_MASTER_BASE+12
        bne.w _m3_14_fail
        cmpi.l #0x0007ffc0,LR_MASTER_BASE+16
        bne.w _m3_14_fail
        cmpi.l #0x0007ffe0,LR_MASTER_BASE+20
        bne.w _m3_14_fail
        move.l #0x4d503134,0x00000414      /* MP14 */

        /* Every moved payload must survive, including A's enlarged tail. */
        cmpi.l #0x42323134,0x0007ff40
        bne.w _m3_14_fail
        cmpi.l #0x43333134,0x0007ff60
        bne.w _m3_14_fail
        cmpi.l #0x41313134,0x0007ff80
        bne.w _m3_14_fail
        cmpi.l #0x41543134,0x0007ffbc
        bne.w _m3_14_fail
        cmpi.l #0x44343134,0x0007ffc0
        bne.w _m3_14_fail
        move.l #0x504c3134,0x00000418      /* PL14 */

        /* Stable lower handle remains untouched. */
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        bne.w _m3_14_fail
        cmpi.l #0x4b503134,(%a1)
        bne.w _m3_14_fail
        move.l #0x4b50314e,0x0000041c      /* KP1N */

        clr.w MAC_MEM_ERR
        move.l #0x4f4b3134,0x00000424      /* OK14 */'''
src = src[:start] + new_test + src[end:]

comp_start = src.index("_m3_14_compact_handles:")
comp_end = src.index("_m3_14_reclaim_purgeable_tail:", comp_start)
compactor = '''_m3_14_compact_handles:
        move.l #LR_HEAP_BASE,%d7
57:     move.l #LR_HANDLE_TABLE,%a1
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

        move.l %a4,%d0
        beq.s 67f
        move.l %a4,%a1
        move.l LR_HREC_DATA(%a1),%d2
        move.l LR_HREC_STATE(%a1),%d0
        btst #7,%d0
        bne.s 66f
        cmp.l %d7,%d2
        beq.s 65f
        move.l %d2,%a2
        move.l %d7,%a3
        move.l LR_HREC_EXTENT(%a1),%d6
        beq.s 64f
63:     move.b (%a2)+,(%a3)+
        subq.l #1,%d6
        bne.s 63b
64:     move.l %d7,LR_HREC_DATA(%a1)
        move.l LR_HREC_HANDLE(%a1),%a2
        move.l %d7,(%a2)
65:     add.l LR_HREC_EXTENT(%a1),%d7
        bra.s 57b
66:     move.l %d2,%d7
        add.l LR_HREC_EXTENT(%a1),%d7
        bra.s 57b
67:     move.l %d7,LR_HEAP_NEXT
        moveq #0,%d5
        rts

'''
src = src[:comp_start] + compactor + src[comp_end:]

out = root / "build/generated/reset_m3_14.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
