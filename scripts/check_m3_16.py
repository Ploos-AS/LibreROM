#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src_path = root / 'build/generated/reset_m3_16.S'
if not src_path.is_file():
    raise SystemExit('M3.16 static qualification FAIL: generated source missing')
src = src_path.read_text()
ld = (root / 'linker/m3_16.ld').read_text()
required = [
    '_m3_16_dispose_ptr', '_m3_16_compact_handles',
    'MAC_TRAP_NEW_PTR', 'MAC_TRAP_DISPOSE_PTR',
    'LIBREROM-M3.16-PTR-TAIL-RECLAIM',
    '0x0007ff00', '0x0007ff20', '0x4f4b3136'
]
missing = [x for x in required if x not in src]
if missing:
    raise SystemExit('M3.16 static qualification FAIL: missing ' + ', '.join(missing))
if 'ENTRY(_m3_16_reset)' not in ld or 'LENGTH = 128K' not in ld:
    raise SystemExit('M3.16 static qualification FAIL: linker contract')
if 'add.l LR_REC_EXTENT(%a1),%d6' not in src:
    raise SystemExit('M3.16 static qualification FAIL: tail end calculation missing')
if 'cmp.l LR_HEAP_NEXT,%d6' not in src or 'move.l %d2,LR_HEAP_NEXT' not in src:
    raise SystemExit('M3.16 static qualification FAIL: immediate Ptr tail rewind missing')
if 'clr.l LR_REC_ACTIVE(%a1)' not in src:
    raise SystemExit('M3.16 static qualification FAIL: DisposePtr deactivation missing')
print('LibreROM M3.16 Ptr tail reclamation static qualification: PASS')
