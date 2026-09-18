# M3.22 — Interior allocation hole splitting

M3.22 extends the qualified M3.21 Macintosh Plus Memory Manager baseline with bounded splitting of reusable interior allocation extents.

## Status

**QUALIFIED — dedicated M3.22 qualification passed in GitHub Actions run #14. Promoted as the retained Macintosh Plus baseline; full-CI and model-variant promotion verification follows the promotion commits.**

M3.20 introduced deterministic interior Ptr-hole reuse and M3.21 introduced corresponding Handle-hole reuse. Both deliberately reuse an entire retained extent even when the new allocation is smaller. M3.22 begins reducing that internal fragmentation by retaining the unused remainder as a reusable interior extent.

## Goal

When a `NewPtr` or `NewHandle` request fits inside a larger inactive interior extent, allocate only the rounded requested extent and preserve the remaining suffix as a deterministic reusable hole instead of consuming the complete old extent.

## Required semantics

- Existing exact-fit reuse from M3.20/M3.21 remains valid.
- A smaller request may split a larger inactive interior extent into an allocated prefix and an inactive suffix.
- The allocated object receives the requested logical size and rounded physical extent.
- The suffix begins exactly at `old_address + allocated_extent` and retains `old_extent - allocated_extent` bytes.
- A remainder is retained only when a free allocation-table record is available and the remainder is large enough to represent a useful aligned allocation.
- If a safe split cannot be represented, reuse may consume the complete inactive extent rather than corrupt metadata.
- Ptr allocations remain immovable.
- Handle allocations retain valid master-pointer semantics.
- Splitting must not change `LR_HEAP_NEXT` for a successful interior reuse.
- Live Ptr/Handle addresses, payloads and master pointers outside the reused extent remain unchanged.
- M3.11-M3.21 purge, compaction, tail reclamation, mixed coalescing and interior-reuse behavior remains regression-qualified.
- `MemErr` follows the existing allocation contract.

## Qualification fixture

The deterministic runtime fixture should exercise both allocation kinds:

1. create a stable lower live allocation;
2. create an interior allocation with a known extent;
3. create a live barrier above it;
4. dispose the interior allocation without rewinding the heap tail;
5. allocate a smaller object and verify it reuses the original address;
6. verify the retained suffix address and extent;
7. allocate a second fitting object and verify it consumes the suffix without extending `LR_HEAP_NEXT`;
8. repeat the bounded scenario for the other allocation kind;
9. verify unrelated live payloads/master pointers and the barrier remain intact;
10. verify an unsplittable/no-record case falls back safely without metadata corruption.

Qualification must include static source checks, deterministic ROM generation, pinned Musashi runtime evidence and a dedicated GitHub Actions workflow before M3.22 can replace M3.21 as the retained Macintosh Plus baseline.

## Non-goals

M3.22 does not yet add:

- arbitrary merging of unrelated interior holes into a general free list;
- best-fit or size-class allocation policy;
- moving live Ptr allocations;
- multiple heap zones;
- grow-zone callbacks;
- full classic Macintosh zone/free-list semantics.

Those remain later Memory Manager work.
