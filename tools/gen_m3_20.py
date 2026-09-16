#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_19.py")], check=True)
src = (root / "build/generated/reset_m3_19.S").read_text(encoding="utf-8")
src = src.replace("_m3_19", "_m3_20").replace("M3.19", "M3.20")
src = src.replace("LIBREROM-M3.20-MIXED-TAIL-COALESCE", "LIBREROM-M3.20-INTERIOR-PTR-REUSE")

start = src.index("        move.l #0x4d333139,0x00000400")
end_marker = "        move.l #0x4f4b3139,0x00000424      /* OK19 */"
end = src.index(end_marker, start) + len(end_marker)
new_test = '''        move.l #0x4d333230,0x00000400      /* M320 */
        move.l #0x0006fe80,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_20_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l LR_TEST_OLD_DATA,%a1
        move.l #0x4b503230,(%a1)           /* KP20 */

        /* Create Ptr A as a genuine interior allocation. */
        move.l #0x40,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_20_fail
        move.l %a0,LR_TEST_PTR
        move.l #0x41323020,(%a0)           /* A20 */

        /* Live Ptr barrier above A keeps A away from the heap tail. */
        move.l #0x40,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_20_fail
        move.l %a0,%a5
        move.l #0x42323020,(%a0)           /* B20 */
        move.l LR_HEAP_NEXT,%d7

        /* Dispose interior A: heap tail must not rewind. */
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_DISPOSE_PTR
        tst.w %d0
        bne.w _m3_20_fail
        cmp.l LR_HEAP_NEXT,%d7
        bne.w _m3_20_fail
        move.l #0x484f3230,0x00000410      /* HO20 */

        /* A fitting NewPtr must reactivate A at exactly the same address. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_20_fail
        cmpa.l LR_TEST_PTR,%a0
        bne.w _m3_20_fail
        cmp.l LR_HEAP_NEXT,%d7
        bne.w _m3_20_fail
        move.l #0x52553230,(%a0)           /* RU20 */
        move.l #0x52553230,0x00000414      /* RU20 */

        /* Reused extent is live now; an oversized request must not alias it. */
        move.l #0x60,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_20_fail
        cmpa.l LR_TEST_PTR,%a0
        beq.w _m3_20_fail
        move.l #0x534b3230,0x00000418      /* SK20 */

        /* Existing live allocations and stable Handle remain untouched. */
        cmpi.l #0x42323020,(%a5)
        bne.w _m3_20_fail
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        bne.w _m3_20_fail
        cmpi.l #0x4b503230,(%a1)
        bne.w _m3_20_fail
        move.l #0x4f4b3230,0x00000424      /* OK20 */'''
src = src[:start] + new_test + src[end:]

out = root / "build/generated/reset_m3_20.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
