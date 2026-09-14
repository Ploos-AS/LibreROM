#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[1]
src_path = root / 'build/generated/reset_m3_12.S'
if not src_path.is_file():
    raise SystemExit('M3.12 static qualification FAIL: generated source missing')
src = src_path.read_text()
ld = (root / 'linker/m3_12.ld').read_text()
required = [
    '_m3_12_reclaim_purgeable_tail', 'MAC_TRAP_HPURGE', 'MAC_TRAP_HLOCK',
    'MAC_TRAP_HUNLOCK', 'MAC_MEM_FULL_ERR', 'MAC_NIL_HANDLE_ERR',
    'LR_HSTATE_PURGE', 'LR_HSTATE_LOCK', 'LIBREROM-M3.12-LOCKED-PURGE-PRESSURE',
    '0x0006ffe0', '0x00010060', '0x4f4b3132'
]
missing = [x for x in required if x not in src]
if missing:
    raise SystemExit('M3.12 static qualification FAIL: missing ' + ', '.join(missing))
if 'ENTRY(_m3_12_reset)' not in ld or 'LENGTH = 128K' not in ld:
    raise SystemExit('M3.12 static qualification FAIL: linker contract')
if 'andi.l #0x000000c0,%d0' not in src or 'cmpi.l #LR_HSTATE_PURGE,%d0' not in src:
    raise SystemExit('M3.12 static qualification FAIL: reclaim lock exclusion contract')
print('LibreROM M3.12 locked-purge pressure static qualification: PASS')
