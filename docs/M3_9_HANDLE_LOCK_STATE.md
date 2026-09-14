# M3.9 — Handle lock/state compatibility

M3.9 extends the clean-room Macintosh Plus Memory Manager slice with documented handle state operations.

Implemented traps:
- `_HLock` `$A029`
- `_HUnlock` `$A02A`
- `_HGetState` `$A069`
- `_HSetState` `$A06A`

The lock flag is bit 7 (`0x80`). `HGetState` returns the state byte in D0.B. `HSetState` consumes the state byte in D0.B and returns an OSErr in D0.W. `HLock` and `HUnlock` take the handle in A0 and return an OSErr in D0.W.

Qualification proves that a locked non-tail relocatable block cannot be moved by `SetHandleSize`, while unlocking permits relocation with handle identity preserved and data copied. An empty master pointer returns `nilHandleErr = -109`; a free handle remains `memWZErr = -111`.

This remains a clean-room compatibility implementation and does not claim full historical Memory Manager zone/compaction behavior.
