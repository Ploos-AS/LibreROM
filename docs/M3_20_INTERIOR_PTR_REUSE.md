# M3.20 — Interior Ptr hole reuse

M3.20 extends the Macintosh Plus Memory Manager baseline beyond tail-only Ptr reclamation.

## Status

**QUALIFIED — GitHub Actions / pinned Musashi runtime.**

The M3.20 implementation passed the full CI regression on commit `86c7b19cc6e87b1de219b121598456b82337070f` (CI run #371). The unrelated Model variants packaging mismatch exposed by that push was subsequently corrected, and the full regression remained green on the corrected retained-baseline integration.

M3.20 is therefore the retained Macintosh Plus Memory Manager baseline.

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

The deterministic Musashi runtime fixture verifies a bounded mixed heap containing:

1. a stable lower Handle;
2. an interior Ptr allocation A;
3. live allocations above A so A is not at the heap tail;
4. disposal of A while it is interior;
5. a fitting `NewPtr` request that reuses A's original address without extending `LR_HEAP_NEXT`;
6. payload checks proving live allocations remain intact;
7. a request larger than the available interior hole proving an undersized extent is skipped rather than incorrectly reused.

## Non-goals

M3.20 does not yet add:

- arbitrary splitting of a larger free Ptr extent;
- merging of unrelated interior holes;
- relocation of live Ptr allocations;
- multiple heap zones;
- grow-zone callbacks;
- full classic Macintosh zone/free-list semantics.

Those remain later Memory Manager work.
