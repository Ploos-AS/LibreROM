#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src_path = root / 'build/generated/reset_m3_18.S'
if not src_path.is_file():
    raise SystemExit('M3.18 static qualification FAIL: generated source missing')
src = src_path.read_text()
ld = (root / 'linker/m3_18.ld').read_text()
required = [
    '_m3_18_dispose_handle', '_m3_18_compact_handles',
    'MAC_TRAP_NEW_HANDLE', 'MAC_TRAP_DISPOSE_HANDLE',
    'LIBREROM-M3.18-HANDLE-TAIL-RECLAIM',
    'LR_HANDLE_TABLE', 'LR_HREC_ACTIVE', 'LR_HREC_EXTENT',
    '0x0007ff00', '0x0007ff20', '0x4f4b3138'
]
missing = [x for x in required if x not in src]
if missing:
    raise SystemExit('M3.18 static qualification FAIL: missing ' + ', '.join(missing))
if 'ENTRY(_m3_18_reset)' not in ld or 'LENGTH = 128K' not in ld:
    raise SystemExit('M3.18 static qualification FAIL: linker contract')
if 'move.l #LR_HANDLE_TABLE,%a2' not in src:
    raise SystemExit('M3.18 static qualification FAIL: inactive Handle scan missing')
if 'tst.l LR_HREC_ACTIVE(%a2)' not in src:
    raise SystemExit('M3.18 static qualification FAIL: inactive-record filter missing')
if 'add.l LR_HREC_EXTENT(%a2),%d6' not in src:
    raise SystemExit('M3.18 static qualification FAIL: predecessor end calculation missing')
if 'cmp.l LR_HEAP_NEXT,%d6' not in src or 'move.l %d4,LR_HEAP_NEXT' not in src:
    raise SystemExit('M3.18 static qualification FAIL: backward Handle tail coalescing missing')
if 'bra.s 82b' not in src:
    raise SystemExit('M3.18 static qualification FAIL: repeated coalescing loop missing')
print('LibreROM M3.18 disposed Handle tail reclamation static qualification: PASS')
