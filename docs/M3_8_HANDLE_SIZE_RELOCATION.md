# LibreROM M3.8 — Handle sizing and relocation

M3.8 extends the qualified Macintosh Plus clean-room Memory Manager baseline with documented handle-size operations and the first explicit relocatable-block behavior.

## Compatibility surface

- `_SetHandleSize` trap `$A024`
- `_GetHandleSize` trap `$A025`
- handles remain stable master-pointer addresses
- `GetHandleSize` returns the logical size of an active handle
- shrinking updates the logical size without moving the data block
- growth may relocate the data block when it cannot grow in place
- relocation preserves existing data bytes and updates the master pointer while leaving the handle address unchanged
- invalid or disposed handles report `memWZErr = -111` through D0/MemErr
- allocation failure reports `memFullErr = -108`

Public Macintosh Memory Manager documentation describes handles as references to relocatable blocks and documents `GetHandleSize`/`SetHandleSize` as the logical-size operations. LibreROM implements this behavior independently; no Apple ROM, disassembly, leaked source, or proprietary System software is used.

## Qualification

The project-authored diagnostic creates an odd-sized handle, writes two data markers, allocates a blocking pointer immediately after it, then grows the handle. Because in-place extension is impossible, the firmware must allocate a new data extent, copy the existing bytes, update the master pointer, and retain the original handle address. A later shrink must preserve the new data address. Disposal is followed by an invalid `GetHandleSize` check requiring `memWZErr`.

Runtime qualification uses pinned Musashi solely as an independent 68000 execution engine and records the ROM hash and runtime evidence.

## Non-goals

M3.8 does not yet claim full classic heap compaction, purgeable handles, lock state, resource handles, grow-zone callbacks, zone semantics, or compatibility with arbitrary Macintosh applications.
