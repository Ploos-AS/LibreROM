#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_15.py")], check=True)
src = (root / "build/generated/reset_m3_15.S").read_text(encoding="utf-8")
src = src.replace("_m3_15", "_m3_16")
src = src.replace("M3.15", "M3.16")
src = src.replace("LIBREROM-M3.16-MIXED-PTR-HANDLE-COMPACTION", "LIBREROM-M3.16-PTR-TAIL-RECLAIM")

start = src.index("        move.l #0x4d333135,0x00000400")
end_marker = "        move.l #0x4f4b3135,0x00000424      /* OK15 */"
end = src.index(end_marker, start) + len(end_marker)
new_test = '''        move.l #0x4d333136,0x00000400      /* M316 */

        /* Leave a small deterministic tail arena above a stable Handle. */
        move.l #0x0006ff00,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_16_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l LR_TEST_OLD_DATA,%a1
        move.l #0x4b503136,(%a1)           /* KP16 */

        /* Two adjacent Ptrs fill the heap exactly. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_16_fail
        cmpa.l #0x0007ff00,%a0
        bne.w _m3_16_fail
        move.l %a0,LR_TEST_PTR
        move.l #0x50313136,(%a0)           /* P116 */

        move.l #0xe0,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_16_fail
        cmpa.l #0x0007ff20,%a0
        bne.w _m3_16_fail
        move.l %a0,%a5
        move.l #0x50323136,(%a0)           /* P216 */
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_16_fail
        move.l #0x464c3136,0x0000040c      /* FL16 */

        /* Disposing the physical tail Ptr immediately rewinds heap_next. */
        move.l %a5,%a0
        .word MAC_TRAP_DISPOSE_PTR
        tst.w %d0
        bne.w _m3_16_fail
        cmpi.l #0x0007ff20,LR_HEAP_NEXT
        bne.w _m3_16_fail
        move.l #0x52323136,0x00000410      /* R216 */

        /* The newly exposed tail Ptr can be reclaimed as well. */
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_DISPOSE_PTR
        tst.w %d0
        bne.w _m3_16_fail
        cmpi.l #0x0007ff00,LR_HEAP_NEXT
        bne.w _m3_16_fail
        move.l #0x52313136,0x00000414      /* R116 */

        /* Recovered tail space is immediately usable without compaction. */
        move.l #0x100,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_16_fail
        cmpi.l #0x0007ff00,(%a0)
        bne.w _m3_16_fail
        cmpi.l #LR_HEAP_LIMIT,LR_HEAP_NEXT
        bne.w _m3_16_fail
        move.l (%a0),%a1
        move.l #0x4e483136,(%a1)           /* NH16 */
        move.l #0x52453136,0x00000418      /* RE16 */

        /* Stable lower Handle remains untouched. */
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        bne.w _m3_16_fail
        cmpi.l #0x4b503136,(%a1)
        bne.w _m3_16_fail
        move.l #0x4b503136,0x0000041c      /* KP16 */

        move.l #0x4f4b3136,0x00000424      /* OK16 */'''
src = src[:start] + new_test + src[end:]

old = '''_m3_16_dispose_ptr:
        bsr.w _m3_16_find_ptr
        tst.l %d5
        bne.s 12f
        clr.l LR_REC_ACTIVE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
12:     suba.l %a0,%a0
        rte
'''
new = '''_m3_16_dispose_ptr:
        bsr.w _m3_16_find_ptr
        tst.l %d5
        bne.s 12f
        move.l LR_REC_PTR(%a1),%d2
        move.l %d2,%d6
        add.l LR_REC_EXTENT(%a1),%d6
        clr.l LR_REC_ACTIVE(%a1)
        cmp.l LR_HEAP_NEXT,%d6
        bne.s 71f
        move.l %d2,LR_HEAP_NEXT
71:     moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
12:     suba.l %a0,%a0
        rte
'''
if old not in src:
    raise SystemExit("M3.16 generator: DisposePtr baseline not found")
src = src.replace(old, new, 1)

out = root / "build/generated/reset_m3_16.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
