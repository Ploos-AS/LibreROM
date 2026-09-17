#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/gen_m3_20.py")], check=True)
src = (root / "build/generated/reset_m3_20.S").read_text(encoding="utf-8")
src = src.replace("_m3_20", "_m3_21").replace("M3.20", "M3.21")
src = src.replace("LIBREROM-M3.21-INTERIOR-PTR-REUSE", "LIBREROM-M3.21-INTERIOR-HANDLE-REUSE")

# Keep fixture state in RAM, not in address registers. NewHandle's inherited
# compaction path is allowed to use/clobber scratch address registers.
state_needle = "        .equ LR_TEST_OLD_DATA,         0x00000450\n"
state_repl = state_needle + "        .equ LR_TEST_STABLE_HANDLE,    0x00000454\n"
if state_needle not in src:
    raise SystemExit("M3.21 generator: test-state layout not found")
src = src.replace(state_needle, state_repl, 1)

# NewHandle already rounds the requested logical size into d1. Before its
# normal free-record/tail-allocation path, search the real Handle table for an
# inactive record whose retained interior extent fits. M3.18+ deliberately
# retains HREC_HANDLE/DATA/LOGICAL/EXTENT for non-tail disposed Handles.
needle = '''        andi.l #0xfffffffe,%d1
        move.l #LR_HANDLE_TABLE,%a1
        move.l #LR_MASTER_BASE,%a2
'''
reuse = '''        andi.l #0xfffffffe,%d1
        move.l #LR_HANDLE_TABLE,%a1
        moveq #LR_HANDLE_COUNT-1,%d3
_m3_21_handle_reuse_scan:
        tst.l LR_HREC_ACTIVE(%a1)
        bne.w _m3_21_handle_reuse_next
        move.l LR_HREC_DATA(%a1),%d2
        beq.w _m3_21_handle_reuse_next
        cmp.l LR_HREC_EXTENT(%a1),%d1
        bhi.w _m3_21_handle_reuse_next
        move.l LR_HREC_HANDLE(%a1),%a2
        move.l %d2,(%a2)
        move.l %d4,LR_HREC_LOGICAL(%a1)
        move.l #1,LR_HREC_ACTIVE(%a1)
        clr.l LR_HREC_STATE(%a1)
        move.l %a2,%a0
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
        rte
_m3_21_handle_reuse_next:
        adda.l #LR_HANDLE_REC_SIZE,%a1
        dbra %d3,_m3_21_handle_reuse_scan
        move.l #LR_HANDLE_TABLE,%a1
        move.l #LR_MASTER_BASE,%a2
'''
if needle not in src:
    raise SystemExit("M3.21 generator: NewHandle baseline not found")
src = src.replace(needle, reuse, 1)

start = src.index("        move.l #0x4d333230,0x00000400")
end_marker = "        move.l #0x4f4b3230,0x00000424      /* OK20 */"
end = src.index(end_marker, start) + len(end_marker)
fixture = '''        move.l #0x4d333231,0x00000400      /* M321 */
        /* Stable lower Handle. Persist its master pointer in RAM because
           later NewHandle/compaction paths may clobber address registers. */
        move.l #0x0006fe00,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_21_fail
        move.l %a0,LR_TEST_STABLE_HANDLE
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
        /* Fixed live Ptr barrier above A. Keep its address in LR_TEST_PTR:
           Handle pressure/compaction is allowed to clobber scratch registers. */
        move.l #0x40,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_21_fail
        move.l %a0,LR_TEST_PTR
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
        move.l LR_TEST_PTR,%a1
        cmpi.l #0x42323120,(%a1)
        bne.w _m3_21_fail
        move.l LR_TEST_STABLE_HANDLE,%a0
        move.l (%a0),%a1
        cmpi.l #0x4b503231,(%a1)
        bne.w _m3_21_fail
        move.l #0x4f4b3231,0x00000424      /* OK21 */
_m3_21_done:
        bra.s _m3_21_done'''
src = src[:start] + fixture + src[end:]
out = root / "build/generated/reset_m3_21.S"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src, encoding="utf-8")
print(out)
