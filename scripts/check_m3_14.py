#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src_path = root / 'build/generated/reset_m3_14.S'
if not src_path.is_file():
    raise SystemExit('M3.14 static qualification FAIL: generated source missing')
src = src_path.read_text()
ld = (root / 'linker/m3_14.ld').read_text()
required = [
    '_m3_14_make_room', '_m3_14_compact_handles', '_m3_14_reclaim_purgeable_tail',
    'MAC_TRAP_SET_HANDLE_SIZE', 'LIBREROM-M3.14-ADDRESS-ORDERED-COMPACTION',
    '0x0006ff40', '0x0007ffa0', '0x0007ff80', '0x0007ff40', '0x4f4b3134'
]
missing = [x for x in required if x not in src]
if missing:
    raise SystemExit('M3.14 static qualification FAIL: missing ' + ', '.join(missing))
if 'ENTRY(_m3_14_reset)' not in ld or 'LENGTH = 128K' not in ld:
    raise SystemExit('M3.14 static qualification FAIL: linker contract')
if 'move.l #LR_HEAP_LIMIT,%d4' not in src or 'cmp.l %d4,%d2' not in src:
    raise SystemExit('M3.14 static qualification FAIL: address-order selector missing')
if 'move.l %a1,%a4' not in src:
    raise SystemExit('M3.14 static qualification FAIL: selected-record tracking missing')
if 'btst #7,%d0' not in src:
    raise SystemExit('M3.14 static qualification FAIL: locked-handle barrier missing')
if 'move.l %d7,LR_HREC_DATA(%a1)' not in src or 'move.l %d7,(%a2)' not in src:
    raise SystemExit('M3.14 static qualification FAIL: relocation/master update missing')
if 'move.b (%a2)+,(%a3)+' not in src:
    raise SystemExit('M3.14 static qualification FAIL: payload move loop missing')
print('LibreROM M3.14 address-ordered handle compaction static qualification: PASS')
