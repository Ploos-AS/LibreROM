#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_17.py")], check=True)
src = (root / "build/generated/reset_m3_17.S").read_text(encoding="utf-8")
src = src.replace("_m3_17", "_m3_18")
src = src.replace("M3.17", "M3.18")
src = src.replace("LIBREROM-M3.18-PTR-TAIL-COALESCE", "LIBREROM-M3.18-HANDLE-TAIL-RECLAIM")

start = src.index("        move.l #0x4d333137,0x00000400")
end_marker = "        move.l #0x4f4b3137,0x00000424      /* OK17 */"
end = src.index(end_marker, start) + len(end_marker)
new_test = '''        move.l #0x4d333138,0x00000400      /* M318 */

        /* Leave a deterministic 0x100-byte tail arena. */
        move.l #0x0006ff00,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_18_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l LR_TEST_OLD_DATA,%a1
        move.l #0x4b503138,(%a1)           /* KP18 */

        /* Two adjacent Handles fill the tail. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_18_fail
        cmpi.l #0x0007ff00,(%a0)
        bne.w _m3_18_fail
        move.l %a0,LR_TEST_PTR

        move.l #0xe0,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_18_fail
        cmpi.l #0x0007ff20,(%a0)
        bne.w _m3_18_fail
        move.l %a0,%a5
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_18_fail
        move.l #0x464c3138,0x0000040c      /* FL18 */

        /* Dispose lower Handle first: it remains an interior hole. */
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_DISPOSE_HANDLE
        tst.w %d0
        bne.w _m3_18_fail
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_18_fail
        move.l #0x48313138,0x00000410      /* H118 */

        /* Dispose physical tail Handle. M3.18 rewinds it and then
           coalesces the already-disposed predecessor Handle. */
        move.l %a5,%a0
        .word MAC_TRAP_DISPOSE_HANDLE
        tst.w %d0
        bne.w _m3_18_fail
        cmpi.l #0x0007ff00,LR_HEAP_NEXT
        bne.w _m3_18_fail
        move.l #0x434f3138,0x00000414      /* CO18 */

        /* Full recovered tail is directly reusable. */
        move.l #0x100,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_18_fail
        cmpi.l #0x0007ff00,(%a0)
        bne.w _m3_18_fail
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_18_fail
        move.l (%a0),%a1
        move.l #0x4e483138,(%a1)           /* NH18 */
        move.l #0x52453138,0x00000418      /* RE18 */

        /* Stable lower Handle remains untouched. */
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        bne.w _m3_18_fail
        cmpi.l #0x4b503138,(%a1)
        bne.w _m3_18_fail
        move.l #0x4b503138,0x0000041c      /* KP18 */
        move.l #0x4f4b3138,0x00000424      /* OK18 */'''
src = src[:start] + new_test + src[end:]

# Extend DisposeHandle so a disposed physical-tail Handle immediately
# rewinds the heap and can expose additional inactive Handle predecessors.
old = '''_m3_18_dispose_handle:
        bsr.w _m3_18_find_handle
        tst.l %d5
        bne.s 12f
        clr.l (%a0)
        clr.l LR_HREC_DATA(%a1)
        clr.l LR_HREC_LOGICAL(%a1)
        clr.l LR_HREC_EXTENT(%a1)
        clr.l LR_HREC_ACTIVE(%a1)
        clr.l LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
12:     suba.l %a0,%a0
        rte
'''
new = '''_m3_18_dispose_handle:
        bsr.w _m3_18_find_handle
        tst.l %d5
        bne.s 12f
        move.l LR_HREC_DATA(%a1),%d2
        move.l %d2,%d6
        add.l LR_HREC_EXTENT(%a1),%d6
        clr.l (%a0)
        clr.l LR_HREC_ACTIVE(%a1)
        cmp.l LR_HEAP_NEXT,%d6
        bne.s 81f
        move.l %d2,LR_HEAP_NEXT
82:     move.l #LR_HANDLE_TABLE,%a2
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
        clr.l LR_HREC_STATE(%a2)
        bra.s 82b
84:     adda.l #LR_HANDLE_REC_SIZE,%a2
        dbra %d3,83b
81:     clr.l LR_HREC_DATA(%a1)
        clr.l LR_HREC_LOGICAL(%a1)
        clr.l LR_HREC_EXTENT(%a1)
        clr.l LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
12:     suba.l %a0,%a0
        rte
'''
if old not in src:
    raise SystemExit("M3.18 generator: DisposeHandle baseline not found")
src = src.replace(old, new, 1)

out = root / "build/generated/reset_m3_18.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
