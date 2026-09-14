from pathlib import Path
s=Path('src/platform/macplus/reset_m3_9.S').read_text()
checks=['MAC_TRAP_HLOCK','0xa029','MAC_TRAP_HUNLOCK','0xa02a','MAC_TRAP_HGETSTATE','0xa069','MAC_TRAP_HSETSTATE','0xa06a','MAC_NIL_HANDLE_ERR','-109','LR_HSTATE_LOCK','LIBREROM-M3.9-HANDLE-LOCK-STATE']
missing=[x for x in checks if x not in s]
if missing: raise SystemExit('M3.9 static FAIL: '+', '.join(missing))
print('LibreROM M3.9 static qualification: PASS')
