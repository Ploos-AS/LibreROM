#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[1]
src_path = root / 'build/generated/reset_m3_20.S'
if not src_path.is_file(): raise SystemExit('M3.20 static qualification FAIL: generated source missing')
src = src_path.read_text()
ld = (root / 'linker/m3_20.ld').read_text()
required = ['_m3_20_dispose_ptr','MAC_TRAP_NEW_PTR','MAC_TRAP_DISPOSE_PTR','LIBREROM-M3.20-INTERIOR-PTR-REUSE','LR_ALLOC_TABLE','LR_REC_PTR','LR_REC_EXTENT','LR_REC_ACTIVE','0x4f4b3230']
missing=[x for x in required if x not in src]
if missing: raise SystemExit('M3.20 static qualification FAIL: missing '+', '.join(missing))
if 'ENTRY(_m3_20_reset)' not in ld or 'LENGTH = 128K' not in ld: raise SystemExit('M3.20 static qualification FAIL: linker contract')
for x in ['0x484f3230','0x52553230','0x534b3230']:
    if x not in src: raise SystemExit('M3.20 static qualification FAIL: fixture marker missing '+x)
print('LibreROM M3.20 interior Ptr reuse static qualification: PASS')
