# M3.17 — Inactive Ptr tail coalescing

M3.17 extends the cumulative Memory Manager baseline so `_DisposePtr` can recover a chain of already-disposed Ptr records when disposal of the current physical tail exposes them.

## Scope

M3.16 immediately rewound `LR_HEAP_NEXT` when the Ptr being disposed was itself the physical tail, but intentionally did not scan backward through earlier inactive Ptr records. M3.17 closes that gap conservatively.

After a tail rewind, LibreROM scans the Ptr allocation table for an inactive record whose retained `ptr + extent` equals the new `LR_HEAP_NEXT`. If found, the heap cursor rewinds to that record's start and the scan restarts. This repeats until no inactive predecessor ends at the current tail.

Live Ptrs remain non-relocatable and are never moved. Interior inactive Ptr holes remain available to the existing record-reuse logic and mixed Ptr/Handle compaction behavior.

## Runtime qualification

The deterministic 68000/Musashi fixture:

1. allocates a stable lower Handle leaving a 0x100-byte tail arena;
2. allocates adjacent 0x20 and 0xe0 Ptrs, filling the heap exactly;
3. disposes the lower Ptr first and verifies the heap cursor does not move because it is an interior hole;
4. disposes the upper tail Ptr and verifies the initial rewind exposes the inactive lower Ptr;
5. verifies backward coalescing continues to `0x7ff00`, recovering the complete 0x100-byte arena;
6. allocates a 0x100-byte Handle directly into the recovered tail and verifies payload, heap cursor, MemErr, and the stable lower Handle.

## Deliberate limits

M3.17 does not relocate live Ptrs, coalesce arbitrary interior holes into a free-list structure, implement multiple heap zones, grow-zone callbacks, full purge policy, or complete classic Macintosh zone semantics. Those remain later milestones.

The implementation remains clean-room and uses public observable behavior only; no Apple ROM code, disassembly, or derived implementation material is used.
