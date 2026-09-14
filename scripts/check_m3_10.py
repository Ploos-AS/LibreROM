#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = (root / 'src/platform/macplus/reset_m3_10.S').read_text()
ld = (root / 'linker/m3_10.ld').read_text()
required = [
    'MAC_TRAP_NEW_PTR', 'MAC_TRAP_DISPOSE_PTR', 'MAC_TRAP_SET_PTR_SIZE', 'MAC_TRAP_GET_PTR_SIZE',
    'MAC_TRAP_NEW_HANDLE', 'MAC_TRAP_DISPOSE_HANDLE', 'MAC_TRAP_SET_HANDLE_SIZE', 'MAC_TRAP_GET_HANDLE_SIZE',
    'MAC_TRAP_HLOCK', 'MAC_TRAP_HUNLOCK', 'MAC_TRAP_HPURGE', 'MAC_TRAP_HNOPURGE',
    'MAC_TRAP_HSETRBIT', 'MAC_TRAP_HCLRRBIT', 'MAC_TRAP_HGETSTATE', 'MAC_TRAP_HSETSTATE',
    'LR_HSTATE_LOCK', 'LR_HSTATE_PURGE', 'LR_HSTATE_RESOURCE',
    'LIBREROM-M3.10-CUMULATIVE-MEMORY-STATE',
]
missing = [x for x in required if x not in src]
if missing:
    raise SystemExit('M3.10 static qualification FAIL: missing ' + ', '.join(missing))
if 'ENTRY(_m3_10_reset)' not in ld or 'LENGTH = 128K' not in ld:
    raise SystemExit('M3.10 static qualification FAIL: linker contract')
if 'dbra %d7' in src:
    raise SystemExit('M3.10 static qualification FAIL: relocation copy must use full 32-bit count')
print('LibreROM M3.10 static qualification: PASS')
