#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_12.py")], check=True)
src = (root / "build/generated/reset_m3_12.S").read_text(encoding="utf-8")
src = src.replace("_m3_12", "_m3_13")
src = src.replace("M3.12", "M3.13")
src = src.replace("LIBREROM-M3.13-LOCKED-PURGE-PRESSURE", "LIBREROM-M3.13-HANDLE-COMPACTION")
src = src.replace("0x50523132", "0x50523133")
src = src.replace("0x53563132", "0x53563133")
src = src.replace("0x45583132", "0x45583133")
src = src.replace("0x42443132", "0x42443133")

start = src.index("        move.l #0x4d333132,0x00000400")
end_marker = "        move.l #0x4f4b3132,0x00000424      /* OK12 */"
end = src.index(end_marker, start) + len(end_marker)
new_test = '''        move.l #0x4d333133,0x00000400      /* M313 */

        /* Stable lower handle occupies most of the heap. It is already at the
           compaction cursor, so a correct pass must leave it untouched. */
        move.l #0x0006ff80,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_13_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l LR_TEST_OLD_DATA,%a1
        move.l #0x4b503133,(%a1)           /* KP13 */

        /* Allocate and dispose a middle handle, leaving a real heap hole. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_13_fail
        move.l %a0,LR_TEST_PTR
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_DISPOSE_HANDLE
        tst.w %d0
        bne.w _m3_13_fail

        /* A small relocatable tail handle fills the heap above that hole. */
        move.l #0x60,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_13_fail
        move.l %a0,LR_TEST_PTR
        move.l (%a0),%a1
        cmpa.l #0x0007ffa0,%a1
        bne.w _m3_13_fail
        move.l #0x4d563133,(%a1)           /* MV13 */
        move.l #0x544c3133,0x0007fffc      /* TL13 */

        /* Locked relocatable blocks are immovable barriers. */
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_HLOCK
        tst.w %d0
        bne.w _m3_13_fail
        move.l #0x4c4b3133,0x0000040c      /* LK13 */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        cmpi.w #MAC_MEM_FULL_ERR,%d0
        bne.w _m3_13_fail
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_13_fail
        move.l #0x42463133,0x00000410      /* BF13 */

        /* Unlocking permits compaction into the middle hole. */
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_HUNLOCK
        tst.w %d0
        bne.w _m3_13_fail
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_13_fail
        cmpa.l #LR_MASTER_BASE+8,%a0
        bne.w _m3_13_fail
        move.l (%a0),%d6
        cmpi.l #0x0007ffe0,%d6
        bne.w _m3_13_fail
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_13_fail
        move.l #0x43503133,0x00000414      /* CP13 */

        /* The moved handle keeps its master pointer, payload and full extent. */
        move.l LR_TEST_PTR,%a0
        move.l (%a0),%a1
        cmpa.l #0x0007ff80,%a1
        bne.w _m3_13_fail
        cmpi.l #0x4d563133,(%a1)
        bne.w _m3_13_fail
        cmpi.l #0x544c3133,0x0007ffdc
        bne.w _m3_13_fail
        move.l #0x4d4f3133,0x0000041c      /* MO13 */

        /* The lower live handle must remain byte-for-byte stable. */
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        bne.w _m3_13_fail
        cmpi.l #0x4b503133,(%a1)
        bne.w _m3_13_fail
        move.l #0x4b50314f,0x00000418      /* KP1O */

        clr.w MAC_MEM_ERR
        move.l #0x4f4b3133,0x00000424      /* OK13 */'''
src = src[:start] + new_test + src[end:]

pressure_call = "        bsr.w _m3_13_reclaim_purgeable_tail"
if pressure_call not in src:
    raise SystemExit("generator contract changed: M3.12 pressure helper call not found")
src = src.replace(pressure_call, "        bsr.w _m3_13_make_room", 1)

insert_at = src.index("_m3_13_reclaim_purgeable_tail:")
helper = '''/* Pressure recovery first preserves M3.11 tail-purge behavior, then performs
   a conservative forward compaction pass over live Handle blocks. */
_m3_13_make_room:
        bsr.w _m3_13_reclaim_purgeable_tail
        tst.l %d5
        beq.s 47f
        bsr.w _m3_13_compact_handles
47:     rts

/* Compact live Handle blocks toward LR_HEAP_BASE. Locked handles are barriers.
   This first compaction slice assumes handle data remains in allocation/table order;
   later milestones can generalize ordering and mixed Ptr/Handle zones. */
_m3_13_compact_handles:
        move.l #LR_HEAP_BASE,%d7
        move.l #LR_HANDLE_TABLE,%a1
        moveq #LR_HANDLE_COUNT-1,%d3
48:     tst.l LR_HREC_ACTIVE(%a1)
        beq.s 56f
        move.l LR_HREC_HANDLE(%a1),%a2
        tst.l (%a2)
        beq.s 56f
        move.l LR_HREC_DATA(%a1),%d2
        move.l LR_HREC_STATE(%a1),%d0
        btst #7,%d0
        bne.s 55f
        cmp.l %d7,%d2
        blo.s 55f
        beq.s 54f
        move.l %d2,%a2
        move.l %d7,%a3
        move.l LR_HREC_EXTENT(%a1),%d6
        beq.s 53f
52:     move.b (%a2)+,(%a3)+
        subq.l #1,%d6
        bne.s 52b
53:     move.l %d7,LR_HREC_DATA(%a1)
        move.l LR_HREC_HANDLE(%a1),%a2
        move.l %d7,(%a2)
54:     add.l LR_HREC_EXTENT(%a1),%d7
        bra.s 56f
55:     move.l %d2,%d7
        add.l LR_HREC_EXTENT(%a1),%d7
56:     adda.l #LR_HANDLE_REC_SIZE,%a1
        dbra %d3,48b
        move.l %d7,LR_HEAP_NEXT
        moveq #0,%d5
        rts

'''
src = src[:insert_at] + helper + src[insert_at:]

out = root / "build/generated/reset_m3_13.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
