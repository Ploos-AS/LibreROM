#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src_path = root / 'build/generated/reset_m3_15.S'
if not src_path.is_file():
    raise SystemExit('M3.15 static qualification FAIL: generated source missing')
src = src_path.read_text()
ld = (root / 'linker/m3_15.ld').read_text()
required = [
    '_m3_15_make_room', '_m3_15_compact_handles', '_m3_15_reclaim_purgeable_tail',
    'MAC_TRAP_NEW_PTR', 'MAC_TRAP_DISPOSE_HANDLE', 'LR_ALLOC_TABLE',
    'LIBREROM-M3.15-MIXED-PTR-HANDLE-COMPACTION',
    '0x0006ff00', '0x0007ff00', '0x0007ff20', '0x0007ff40', '0x4f4b3135'
]
missing = [x for x in required if x not in src]
if missing:
    raise SystemExit('M3.15 static qualification FAIL: missing ' + ', '.join(missing))
if 'ENTRY(_m3_15_reset)' not in ld or 'LENGTH = 128K' not in ld:
    raise SystemExit('M3.15 static qualification FAIL: linker contract')
if 'tst.l LR_REC_ACTIVE(%a1)' not in src or 'move.l LR_REC_PTR(%a1),%d7' not in src:
    raise SystemExit('M3.15 static qualification FAIL: Ptr barrier scan missing')
if 'add.l LR_REC_EXTENT(%a1),%d7' not in src:
    raise SystemExit('M3.15 static qualification FAIL: Ptr barrier extent missing')
if 'move.l %d7,LR_HREC_DATA(%a1)' not in src or 'move.l %d7,(%a2)' not in src:
    raise SystemExit('M3.15 static qualification FAIL: Handle relocation/master update missing')
if 'move.b (%a2)+,(%a3)+' not in src:
    raise SystemExit('M3.15 static qualification FAIL: Handle payload move loop missing')
print('LibreROM M3.15 mixed Ptr/Handle compaction static qualification: PASS')
