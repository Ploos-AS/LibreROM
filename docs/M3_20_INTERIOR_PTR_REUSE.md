# M3.20 — Interior Ptr hole reuse

M3.20 extends the Macintosh Plus Memory Manager baseline beyond tail-only Ptr reclamation.

## Goal

Reuse a disposed interior Ptr allocation for a later `NewPtr` when the retained inactive allocation record has an extent large enough for the requested block.

This is deliberately narrower than a general free-list allocator. It builds on the allocation-record reuse already present in the cumulative Memory Manager while giving it an explicit fragmentation qualification.

## Required semantics

- `DisposePtr` of a non-tail allocation leaves an inactive allocation record with its address and extent retained.
- `NewPtr` searches inactive Ptr records before extending `LR_HEAP_NEXT`.
- A fitting inactive Ptr extent may be reactivated at the same address; raw Ptr values are never relocated.
- Reuse must not disturb live Handle master pointers or live Ptr payloads.
- A hole that is too small for the request must be skipped.
- Tail reclamation/coalescing from M3.16-M3.19 remains unchanged.
- Handle compaction from M3.13-M3.15 remains unchanged.

## Qualification fixture

The runtime qualification should create a bounded mixed heap with:

1. a stable lower Handle;
2. an interior Ptr allocation A;
3. a live barrier allocation above A;
4. disposal of A while it is not at the heap tail;
5. a `NewPtr` request that fits A and must reuse A's original address without changing `LR_HEAP_NEXT`;
6. payload checks proving the live barrier and stable Handle remain intact;
7. a second request larger than the available hole proving the allocator does not incorrectly reuse an undersized extent.

The test must be deterministic on the pinned Musashi runtime used by the M3 qualification suite.

## Non-goals

M3.20 does not yet add:

- arbitrary splitting of a larger free Ptr extent;
- merging of unrelated interior holes;
- relocation of live Ptr allocations;
- multiple heap zones;
- grow-zone callbacks;
- full classic Macintosh zone/free-list semantics.

Those remain later Memory Manager work.
