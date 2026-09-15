#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_16.py")], check=True)
src = (root / "build/generated/reset_m3_16.S").read_text(encoding="utf-8")
src = src.replace("_m3_16", "_m3_17")
src = src.replace("M3.16", "M3.17")
src = src.replace("LIBREROM-M3.17-PTR-TAIL-RECLAIM", "LIBREROM-M3.17-PTR-TAIL-COALESCE")

start = src.index("        move.l #0x4d333136,0x00000400")
end_marker = "        move.l #0x4f4b3136,0x00000424      /* OK16 */"
end = src.index(end_marker, start) + len(end_marker)
new_test = '''        move.l #0x4d333137,0x00000400      /* M317 */

        /* Leave a deterministic 0x100-byte tail arena. */
        move.l #0x0006ff00,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_17_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l LR_TEST_OLD_DATA,%a1
        move.l #0x4b503137,(%a1)           /* KP17 */

        /* Two adjacent Ptrs fill the tail. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_17_fail
        cmpa.l #0x0007ff00,%a0
        bne.w _m3_17_fail
        move.l %a0,LR_TEST_PTR
        move.l #0x50313137,(%a0)           /* P117 */

        move.l #0xe0,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_17_fail
        cmpa.l #0x0007ff20,%a0
        bne.w _m3_17_fail
        move.l %a0,%a5
        move.l #0x50323137,(%a0)           /* P217 */
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_17_fail
        move.l #0x464c3137,0x0000040c      /* FL17 */

        /* Dispose the lower Ptr first: it is an inactive interior hole. */
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_DISPOSE_PTR
        tst.w %d0
        bne.w _m3_17_fail
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_17_fail
        move.l #0x48313137,0x00000410      /* H117 */

        /* Disposing the physical tail now exposes the inactive lower Ptr.
           M3.17 must walk backward and coalesce both records. */
        move.l %a5,%a0
        .word MAC_TRAP_DISPOSE_PTR
        tst.w %d0
        bne.w _m3_17_fail
        cmpi.l #0x0007ff00,LR_HEAP_NEXT
        bne.w _m3_17_fail
        move.l #0x434f3137,0x00000414      /* CO17 */

        /* The full coalesced tail is immediately reusable. */
        move.l #0x100,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_17_fail
        cmpi.l #0x0007ff00,(%a0)
        bne.w _m3_17_fail
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_17_fail
        move.l (%a0),%a1
        move.l #0x4e483137,(%a1)           /* NH17 */
        move.l #0x52453137,0x00000418      /* RE17 */

        /* Stable lower Handle remains untouched. */
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        bne.w _m3_17_fail
        cmpi.l #0x4b503137,(%a1)
        bne.w _m3_17_fail
        move.l #0x4b503137,0x0000041c      /* KP17 */

        move.l #0x4f4b3137,0x00000424      /* OK17 */'''
src = src[:start] + new_test + src[end:]

old = '''        cmp.l LR_HEAP_NEXT,%d6
        bne.s 71f
        move.l %d2,LR_HEAP_NEXT
71:     moveq #MAC_NO_ERR,%d0
'''
new = '''        cmp.l LR_HEAP_NEXT,%d6
        bne.s 71f
        move.l %d2,LR_HEAP_NEXT
        /* Coalesce any already-inactive Ptr record that now ends exactly
           at the physical heap tail. Repeat because one rewind can expose
           another inactive predecessor. */
72:     move.l #LR_ALLOC_TABLE,%a2
        moveq #LR_ALLOC_COUNT-1,%d3
73:     tst.l LR_REC_ACTIVE(%a2)
        bne.s 74f
        move.l LR_REC_PTR(%a2),%d4
        beq.s 74f
        move.l %d4,%d6
        add.l LR_REC_EXTENT(%a2),%d6
        cmp.l LR_HEAP_NEXT,%d6
        bne.s 74f
        move.l %d4,LR_HEAP_NEXT
        bra.s 72b
74:     adda.l #LR_ALLOC_REC_SIZE,%a2
        dbra %d3,73b
71:     moveq #MAC_NO_ERR,%d0
'''
if old not in src:
    raise SystemExit("M3.17 generator: M3.16 tail rewind block not found")
src = src.replace(old, new, 1)

out = root / "build/generated/reset_m3_17.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
