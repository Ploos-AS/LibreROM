#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_11.py")], check=True)
src = (root / "build/generated/reset_m3_11.S").read_text(encoding="utf-8")
src = src.replace("_m3_11", "_m3_12")
src = src.replace("M3.11", "M3.12")
src = src.replace("LIBREROM-M3.12-PURGE-RECLAIM", "LIBREROM-M3.12-LOCKED-PURGE-PRESSURE")
src = src.replace("0x50523131", "0x50523132")
src = src.replace("0x53563131", "0x53563132")
src = src.replace("0x45583131", "0x45583132")
src = src.replace("0x42443131", "0x42443132")

start = src.index("        move.l #0x4d333131,0x00000400")
end_marker = "        move.l #0x4f4b3131,0x00000424      /* OK11 */"
end = src.index(end_marker, start) + len(end_marker)
new_test = '''        move.l #0x4d333132,0x00000400      /* M312 */

        /* Keep one ordinary handle alive and verify its payload survives pressure. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_12_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l LR_TEST_OLD_DATA,%a1
        move.l #0x4b503132,(%a1)           /* KP12 */

        /* Tail handle consumes the remaining heap, then becomes purgeable+locked. */
        move.l #0x0006ffe0,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_12_fail
        move.l %a0,LR_TEST_PTR
        move.l (%a0),%d6
        cmpi.l #0x00010020,%d6
        bne.w _m3_12_fail
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_HPURGE
        tst.w %d0
        bne.w _m3_12_fail
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_HLOCK
        tst.w %d0
        bne.w _m3_12_fail
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_HGETSTATE
        cmpi.b #0xc0,%d0
        bne.w _m3_12_fail
        move.l #0x4c503132,0x0000040c      /* LP12 */

        /* Locked purgeable memory must NOT be reclaimed under pressure. */
        move.l #0x40,%d0
        .word MAC_TRAP_NEW_HANDLE
        cmpi.w #MAC_MEM_FULL_ERR,%d0
        bne.w _m3_12_fail
        cmpi.w #MAC_MEM_FULL_ERR,MAC_MEM_ERR
        bne.w _m3_12_fail
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_12_fail
        move.l LR_TEST_PTR,%a0
        tst.l (%a0)
        beq.w _m3_12_fail
        move.l #0x424c3132,0x00000410      /* BL12 */

        /* Unlocking the same handle makes it reclaimable on the next request. */
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_HUNLOCK
        tst.w %d0
        bne.w _m3_12_fail
        move.l #0x40,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_12_fail
        cmpa.l #LR_MASTER_BASE+8,%a0
        bne.w _m3_12_fail
        move.l (%a0),%d6
        cmpi.l #0x00010020,%d6
        bne.w _m3_12_fail
        cmpi.l #0x00010060,LR_HEAP_NEXT
        bne.w _m3_12_fail
        move.l #0x554c3132,0x00000414      /* UL12 */

        /* Reclaimed master survives as NIL; live ordinary handle remains intact. */
        move.l LR_TEST_PTR,%a0
        tst.l (%a0)
        bne.w _m3_12_fail
        .word MAC_TRAP_GET_HANDLE_SIZE
        cmpi.w #MAC_NIL_HANDLE_ERR,%d0
        bne.w _m3_12_fail
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        bne.w _m3_12_fail
        cmpi.l #0x4b503132,(%a1)
        bne.w _m3_12_fail
        move.l #0x4b50314f,0x00000418      /* KP1O */

        clr.w MAC_MEM_ERR
        move.l #0x4f4b3132,0x00000424      /* OK12 */'''
src = src[:start] + new_test + src[end:]

out = root / "build/generated/reset_m3_12.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
