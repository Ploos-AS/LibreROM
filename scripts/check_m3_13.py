#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src_path = root / 'build/generated/reset_m3_13.S'
if not src_path.is_file():
    raise SystemExit('M3.13 static qualification FAIL: generated source missing')
src = src_path.read_text()
ld = (root / 'linker/m3_13.ld').read_text()
required = [
    '_m3_13_make_room', '_m3_13_compact_handles', '_m3_13_reclaim_purgeable_tail',
    'MAC_TRAP_DISPOSE_HANDLE', 'MAC_TRAP_HLOCK', 'MAC_TRAP_HUNLOCK',
    'MAC_MEM_FULL_ERR', 'LR_HSTATE_LOCK', 'LIBREROM-M3.13-HANDLE-COMPACTION',
    '0x0006ffc0', '0x0007ffe0', '0x00010020', '0x4f4b3133'
]
missing = [x for x in required if x not in src]
if missing:
    raise SystemExit('M3.13 static qualification FAIL: missing ' + ', '.join(missing))
if 'ENTRY(_m3_13_reset)' not in ld or 'LENGTH = 128K' not in ld:
    raise SystemExit('M3.13 static qualification FAIL: linker contract')
if 'btst #7,%d0' not in src:
    raise SystemExit('M3.13 static qualification FAIL: locked-handle barrier missing')
if 'move.l %d7,LR_HREC_DATA(%a1)' not in src or 'move.l %d7,(%a2)' not in src:
    raise SystemExit('M3.13 static qualification FAIL: relocation/master update missing')
if 'move.b (%a2)+,(%a3)+' not in src:
    raise SystemExit('M3.13 static qualification FAIL: payload move loop missing')
print('LibreROM M3.13 handle-compaction static qualification: PASS')
