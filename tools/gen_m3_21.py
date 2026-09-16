#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_20.py")], check=True)
src = (root / "build/generated/reset_m3_20.S").read_text(encoding="utf-8")
src = src.replace("_m3_20", "_m3_21").replace("M3.20", "M3.21")
src = src.replace("LIBREROM-M3.21-INTERIOR-PTR-REUSE", "LIBREROM-M3.21-INTERIOR-HANDLE-REUSE")
needle = '''_m3_21_new_handle:\n'''
pos = src.index(needle) + len(needle)
reuse = '''        /* M3.21: prefer a fitting inactive retained Handle extent. */
        move.l %d0,%d6
        lea LR_ALLOC_TABLE,%a1
        moveq #LR_ALLOC_RECORDS-1,%d5
_m3_21_handle_reuse_scan:
        tst.l LR_REC_ACTIVE(%a1)
        bne.s _m3_21_handle_reuse_next
        cmpi.l #LR_KIND_HANDLE,LR_REC_KIND(%a1)
        bne.s _m3_21_handle_reuse_next
        move.l LR_REC_EXTENT(%a1),%d4
        cmp.l %d6,%d4
        blo.s _m3_21_handle_reuse_next
        move.l LR_REC_HANDLE(%a1),%a0
        cmpa.l #0,%a0
        beq.s _m3_21_handle_reuse_next
        move.l LR_REC_DATA(%a1),%d4
        beq.s _m3_21_handle_reuse_next
        move.l %d4,(%a0)
        move.l %d6,LR_REC_LOGICAL(%a1)
        move.l #1,LR_REC_ACTIVE(%a1)
        clr.l LR_REC_STATE(%a1)
        clr.w LR_MEM_ERR
        moveq #0,%d0
        rts
_m3_21_handle_reuse_next:
        adda.w #LR_REC_SIZE,%a1
        dbra %d5,_m3_21_handle_reuse_scan
        move.l %d6,%d0
'''
src = src[:pos] + reuse + src[pos:]
start = src.index("        move.l #0x4d333230,0x00000400")
end_marker = "        move.l #0x4f4b3230,0x00000424      /* OK20 */"
end = src.index(end_marker, start) + len(end_marker)
fixture = '''        move.l #0x4d333231,0x00000400      /* M321 */
        /* Stable lower Handle. */
        move.l #0x0006fe00,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_21_fail
        move.l %a0,%a4
        move.l (%a0),%a1
        move.l #0x4b503231,(%a1)           /* KP21 */
        /* Handle A becomes an interior hole. */
        move.l #0x40,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_21_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l LR_TEST_OLD_DATA,%a1
        move.l #0x41323120,(%a1)           /* A21 */
        /* Fixed live Ptr barrier above A. */
        move.l #0x40,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_21_fail
        move.l %a0,%a5
        move.l #0x42323120,(%a0)           /* B21 */
        move.l LR_HEAP_NEXT,%d7
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_DISPOSE_HANDLE
        tst.w %d0
        bne.w _m3_21_fail
        cmp.l LR_HEAP_NEXT,%d7
        bne.w _m3_21_fail
        move.l #0x484f3231,0x00000410      /* HO21 */
        /* Fitting request must reuse A's retained data extent. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_21_fail
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        bne.w _m3_21_fail
        cmp.l LR_HEAP_NEXT,%d7
        bne.w _m3_21_fail
        move.l #0x52553231,(%a1)           /* RU21 */
        move.l #0x52553231,0x00000414      /* RU21 */
        /* Reused extent is active; oversized request must not alias it. */
        move.l #0x60,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_21_fail
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        beq.w _m3_21_fail
        move.l #0x534b3231,0x00000418      /* SK21 */
        cmpi.l #0x42323120,(%a5)
        bne.w _m3_21_fail
        move.l %a4,%a0
        move.l (%a0),%a1
        cmpi.l #0x4b503231,(%a1)
        bne.w _m3_21_fail
        move.l #0x4f4b3231,0x00000424      /* OK21 */'''
src = src[:start] + fixture + src[end:]
out = root / "build/generated/reset_m3_21.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
