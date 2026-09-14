# M3.10 — Cumulative Memory Manager state baseline

M3.10 makes the current Macintosh Plus LibreROM image cumulative again and extends handle state support.

## Compatibility surface retained

Pointer traps retained from M3.6/M3.7:

- `_NewPtr` `$A11E`
- `_DisposPtr` `$A01F`
- `_SetPtrSize` `$A020`
- `_GetPtrSize` `$A021`

Handle traps retained from M3.7–M3.9:

- `_NewHandle` `$A122`
- `_DisposHandle` `$A023`
- `_SetHandleSize` `$A024`
- `_GetHandleSize` `$A025`
- `_HLock` `$A029`
- `_HUnlock` `$A02A`
- `_HGetState` `$A069`
- `_HSetState` `$A06A`

M3.10 adds:

- `_HPurge` `$A049`
- `_HNoPurge` `$A04A`
- `_HSetRBit` `$A067`
- `_HClrRBit` `$A068`

## Handle property byte

Public historical documentation defines the currently-used bits as:

- bit 7: locked
- bit 6: purgeable
- bit 5: resource
- bits 0–4: reserved

LibreROM stores this property byte independently of the master pointer address so the implementation remains compatible with a future 32-bit-clean representation.

## Error behavior

- `noErr = 0`
- `memFullErr = -108`
- `nilHandleErr = -109`
- `memWZErr = -111`
- low-memory `MemErr` remains at `$0220`.

## Runtime qualification

The M3.10 runtime gate proves:

1. the latest ROM still implements the four pointer traps;
2. pointer logical sizing and disposal still work;
3. a new handle starts with property byte zero;
4. `HPurge` sets bit 6;
5. `HSetRBit` sets bit 5 without disturbing bit 6;
6. `HLock` composes with the purge/resource flags;
7. `HNoPurge` and `HClrRBit` clear their respective bits independently;
8. `HSetState` restores the documented state bits;
9. an empty master pointer returns `nilHandleErr`.

M3.10 also replaces the old 16-bit `DBRA` relocation-copy count with a full 32-bit decrement loop.

## Non-goals

M3.10 marks blocks purgeable but does not yet reclaim purgeable blocks under memory pressure. Actual purge/compaction policy is a later milestone.
