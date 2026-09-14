#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[1]
gen = (root / 'tools/gen_m3_11.py').read_text()
ld = (root / 'linker/m3_11.ld').read_text()
required = [
    '_m3_11_reclaim_purgeable_tail', 'LR_HSTATE_PURGE', 'LR_HSTATE_LOCK',
    'clr.l (%a2)', 'LR_HEAP_NEXT', 'LIBREROM-M3.11-PURGE-RECLAIM',
    '0x0006ffb0', '0x00010070', 'MAC_NIL_HANDLE_ERR'
]
missing = [x for x in required if x not in gen]
if missing:
    raise SystemExit('M3.11 static qualification FAIL: missing ' + ', '.join(missing))
if 'ENTRY(_m3_11_reset)' not in ld or 'LENGTH = 128K' not in ld:
    raise SystemExit('M3.11 static qualification FAIL: linker contract')
print('LibreROM M3.11 purge-reclaim static qualification: PASS')
