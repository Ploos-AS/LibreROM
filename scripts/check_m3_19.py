#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[1]
src_path = root / 'build/generated/reset_m3_19.S'
if not src_path.is_file(): raise SystemExit('M3.19 static qualification FAIL: generated source missing')
src = src_path.read_text()
ld = (root / 'linker/m3_19.ld').read_text()
required = ['_m3_19_dispose_handle','MAC_TRAP_DISPOSE_PTR','MAC_TRAP_DISPOSE_HANDLE','LIBREROM-M3.19-MIXED-TAIL-COALESCE','LR_HANDLE_TABLE','LR_ALLOC_TABLE','LR_HREC_ACTIVE','LR_REC_ACTIVE','0x4f4b3139']
missing=[x for x in required if x not in src]
if missing: raise SystemExit('M3.19 static qualification FAIL: missing '+', '.join(missing))
if 'ENTRY(_m3_19_reset)' not in ld or 'LENGTH = 128K' not in ld: raise SystemExit('M3.19 static qualification FAIL: linker contract')
for x in ['add.l LR_HREC_EXTENT(%a2),%d6','add.l LR_REC_EXTENT(%a2),%d6','move.l %d4,LR_HEAP_NEXT']:
    if x not in src: raise SystemExit('M3.19 static qualification FAIL: mixed predecessor logic missing '+x)
print('LibreROM M3.19 mixed Ptr/Handle tail coalescing static qualification: PASS')
