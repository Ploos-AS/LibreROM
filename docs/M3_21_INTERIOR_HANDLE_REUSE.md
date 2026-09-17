# M3.21 — Interior Handle hole reuse

M3.21 extends the retained Macintosh Plus Memory Manager baseline with deterministic reuse of disposed interior Handle extents.

## Status

**QUALIFIED — retained Macintosh Plus baseline.**

Dedicated GitHub Actions qualification passed in **M3.21 Interior Handle reuse #7** (run `35202083336`) on implementation commit `cb56ad141356b4c07301f870e4a5a3dd3099cdcb`. The same implementation also passed full CI #388, Model variants #176, and the M3.16-M3.20 regression workflows before promotion.

M3.20 qualified reuse of inactive interior Ptr extents. M3.21 applies the corresponding bounded behavior to relocatable Handle storage while preserving Handle master-pointer semantics and all existing Ptr barriers/compaction rules.

## Goal

When `DisposeHandle` releases a Handle whose data extent is not at the heap tail, retain enough allocation metadata for a later `NewHandle` to reuse that inactive extent when it fits, instead of extending `LR_HEAP_NEXT` unnecessarily.

## Qualified semantics

- `DisposeHandle` of a non-tail allocation clears the live master pointer and marks the Handle record inactive while retaining its reusable data address and extent.
- `NewHandle` searches inactive Handle records/extents before extending `LR_HEAP_NEXT`.
- A fitting inactive extent may be reactivated for a new Handle allocation.
- The newly allocated Handle receives a valid master pointer and its master pointer references the reused data address.
- A too-small inactive Handle extent is skipped.
- Live Ptr addresses never move as a consequence of interior Handle reuse.
- Live Handle payloads and master pointers not involved in the reuse remain intact.
- Existing locked-Handle, purge, compaction, tail reclamation and mixed Ptr/Handle coalescing semantics from M3.11-M3.20 remain unchanged.
- `MemErr` follows the existing `NewHandle` success/failure contract.

## Qualification fixture

The deterministic Musashi fixture constructs a bounded mixed heap containing:

1. a stable lower live Handle;
2. Handle A with a known data extent and payload;
3. a live Ptr barrier above Handle A so disposal of A cannot rewind the heap tail;
4. disposal of Handle A, verifying the heap tail remains unchanged;
5. a fitting `NewHandle` request that reuses A's old data extent without extending `LR_HEAP_NEXT`;
6. verification that the new master pointer references A's old data address;
7. an oversized `NewHandle` request proving an undersized inactive extent is not incorrectly reused;
8. payload/address checks proving the Ptr barrier and unrelated live Handle remain intact.

Qualification includes static source checks, deterministic ROM generation, pinned Musashi runtime evidence and a dedicated GitHub Actions workflow. M3.21 therefore replaces M3.20 as the retained Macintosh Plus source baseline while M3.20 remains covered by regression qualification.

## Non-goals

M3.21 does not yet add:

- arbitrary splitting of a larger inactive Handle extent;
- merging unrelated interior holes into a general free list;
- moving live Ptr allocations;
- multiple heap zones;
- grow-zone callbacks;
- full classic Macintosh zone/free-list semantics.

Those remain later Memory Manager work.
