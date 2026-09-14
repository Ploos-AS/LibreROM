#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = (root / "src/platform/macplus/reset_m3_10.S").read_text(encoding="utf-8")
src = src.replace("_m3_10", "_m3_11")
src = src.replace("M3.10", "M3.11")
src = src.replace("LIBREROM-M3.11-CUMULATIVE-MEMORY-STATE", "LIBREROM-M3.11-PURGE-RECLAIM")
src = src.replace("0x50523130", "0x50523131")
src = src.replace("0x53563130", "0x53563131")
src = src.replace("0x45583130", "0x45583131")
src = src.replace("0x42443130", "0x42443131")

start = src.index("        move.l #0x4d333130,0x00000400")
end_marker = "        move.l #0x4f4b3130,0x00000424      /* OK10 */"
end = src.index(end_marker, start) + len(end_marker)
new_test = '''        move.l #0x4d333131,0x00000400      /* M311 */

        move.l #0x10,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_11_fail
        move.l %a0,LR_TEST_PTR
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_DISPOSE_PTR
        tst.w %d0
        bne.w _m3_11_fail
        move.l #0x50543131,0x00000404      /* PT11 */

        /* Keep one ordinary unpurgeable handle alive. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_11_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l LR_TEST_OLD_DATA,%a1
        move.l #0x4b503131,(%a1)           /* KP11 payload */

        /* Allocate a large tail handle, then mark it purgeable. */
        move.l #0x0006ffb0,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_11_fail
        move.l %a0,LR_TEST_PTR
        move.l (%a0),%d6
        cmpi.l #0x00010030,%d6
        bne.w _m3_11_fail
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_HPURGE
        tst.w %d0
        bne.w _m3_11_fail
        move.l #0x50553131,0x0000040c      /* PU11 */

        /* Allocation succeeds only by reclaiming that purgeable tail block. */
        move.l #0x40,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_11_fail
        cmpa.l #LR_MASTER_BASE+8,%a0
        bne.w _m3_11_fail
        move.l (%a0),%d6
        cmpi.l #0x00010030,%d6
        bne.w _m3_11_fail
        cmpi.l #0x00010070,LR_HEAP_NEXT
        bne.w _m3_11_fail
        move.l #0x52433131,0x00000410      /* RC11 */

        /* Purged handle survives as a NIL master pointer. */
        move.l LR_TEST_PTR,%a0
        tst.l (%a0)
        bne.w _m3_11_fail
        .word MAC_TRAP_GET_HANDLE_SIZE
        cmpi.w #MAC_NIL_HANDLE_ERR,%d0
        bne.w _m3_11_fail
        move.l #0x4e493131,0x00000414      /* NI11 */

        /* Unpurgeable handle and data remain intact. */
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        bne.w _m3_11_fail
        cmpi.l #0x4b503131,(%a1)
        bne.w _m3_11_fail
        move.l #0x4b50314f,0x00000418      /* KP1O */

        clr.w MAC_MEM_ERR
        move.l #0x4f4b3131,0x00000424      /* OK11 */'''
src = src[:start] + new_test + src[end:]

old = '''        move.l LR_HEAP_NEXT,%d2
        move.l %d2,%d6
        add.l %d1,%d6
        cmpi.l #LR_HEAP_LIMIT,%d6
        bhi.w _m3_11_handle_alloc_fail
        move.l %d6,LR_HEAP_NEXT'''
new = '''        move.l LR_HEAP_NEXT,%d2
        move.l %d2,%d6
        add.l %d1,%d6
        cmpi.l #LR_HEAP_LIMIT,%d6
        bls.s 41f
        move.l %a1,%a5
        move.l %a2,%a6
        bsr.w _m3_11_reclaim_purgeable_tail
        move.l %a5,%a1
        move.l %a6,%a2
        tst.l %d5
        bne.w _m3_11_handle_alloc_fail
        move.l LR_HEAP_NEXT,%d2
        move.l %d2,%d6
        add.l %d1,%d6
        cmpi.l #LR_HEAP_LIMIT,%d6
        bhi.w _m3_11_handle_alloc_fail
41:     move.l %d6,LR_HEAP_NEXT'''
if old not in src:
    raise SystemExit("generator contract changed: NewHandle capacity block not found")
src = src.replace(old, new, 1)

insert_at = src.index("_m3_11_handle_alloc_fail:")
helper = '''/* Reclaim only an unlocked purgeable block exactly at the heap tail.
   The handle record/master slot survives; the master pointer becomes NIL. */
_m3_11_reclaim_purgeable_tail:
        move.l #LR_HANDLE_TABLE,%a1
        moveq #LR_HANDLE_COUNT-1,%d3
42:     tst.l LR_HREC_ACTIVE(%a1)
        beq.s 46f
        move.l LR_HREC_STATE(%a1),%d0
        andi.l #0x000000c0,%d0
        cmpi.l #LR_HSTATE_PURGE,%d0
        bne.s 46f
        move.l LR_HREC_HANDLE(%a1),%a2
        tst.l (%a2)
        beq.s 46f
        move.l LR_HREC_DATA(%a1),%d0
        move.l %d0,%d6
        add.l LR_HREC_EXTENT(%a1),%d6
        cmp.l LR_HEAP_NEXT,%d6
        bne.s 46f
        move.l %d0,LR_HEAP_NEXT
        clr.l (%a2)
        clr.l LR_HREC_DATA(%a1)
        clr.l LR_HREC_LOGICAL(%a1)
        clr.l LR_HREC_EXTENT(%a1)
        moveq #0,%d5
        rts
46:     adda.l #LR_HANDLE_REC_SIZE,%a1
        dbra %d3,42b
        moveq #-1,%d5
        rts

'''
src = src[:insert_at] + helper + src[insert_at:]

out = root / "build/generated/reset_m3_11.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
