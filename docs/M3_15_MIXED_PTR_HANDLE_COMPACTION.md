# M3.15 — Mixed Ptr/Handle heap compaction

M3.15 extends M3.14 address-ordered Handle compaction to a heap that also contains live non-relocatable Ptr allocations.

## Scope

Classic-style Ptr values are directly held by callers and therefore cannot be transparently relocated. M3.15 treats every active Ptr allocation as a fixed physical barrier while continuing to compact unlocked Handles in address order around those barriers.

The pressure pass now:

- scans live Handle records and active Ptr records in the shared heap;
- selects the lowest physical allocation at or above the compaction cursor;
- relocates unlocked Handles downward and updates their master pointers;
- treats locked Handles as fixed barriers;
- treats active Ptr allocations as fixed barriers and advances the cursor past their extent;
- ignores disposed/inactive Ptr records;
- preserves the M3.11 purge-first path before compaction;
- retries the original `_NewHandle` request after compaction.

## Runtime qualification

The deterministic Musashi fixture:

1. allocates a large stable lower Handle;
2. allocates a 0x20-byte Ptr immediately above it and writes a payload marker;
3. allocates Handle A, Handle B, and a larger Handle C;
4. fills the heap exactly to `LR_HEAP_LIMIT`;
5. disposes A, creating a real hole above the live Ptr;
6. requests another Handle under pressure;
7. verifies the Ptr remains at exactly `0x0007ff00` with its payload intact;
8. verifies B and C compact downward above the Ptr barrier;
9. verifies their master pointers and payload markers follow the relocated blocks;
10. verifies the disposed Handle slot is reused by the successful pressure allocation at the recovered heap tail;
11. verifies the stable lower Handle remains unchanged.

## Deliberate limits

M3.15 does not move Ptr allocations and does not yet implement Ptr-tail reclamation, multiple heap zones, grow-zone callbacks, sophisticated purge policy, or complete classic Macintosh zone semantics. Those remain later milestones.

The implementation remains clean-room and is based on public observable behavior only; no Apple ROM code, disassembly, or derived implementation material is used.
