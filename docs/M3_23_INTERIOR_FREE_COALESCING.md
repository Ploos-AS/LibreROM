# M3.23 — Interior free-extent coalescing

M3.23 extends the qualified M3.22 Macintosh Plus Memory Manager baseline with bounded coalescing of adjacent inactive interior allocation extents.

## Status

**PLANNED — implementation and qualification pending.**

M3.22 can split a larger reusable interior extent and preserve its suffix. Over time, disposal and splitting can therefore leave multiple adjacent inactive Ptr/Handle extents. M3.23 makes those adjacent holes reusable as one larger extent without introducing a general-purpose free-list allocator.

## Goal

When inactive interior extents are physically adjacent, merge them deterministically so a later allocation may reuse the combined space without moving live Ptrs or extending `LR_HEAP_NEXT`.

## Required semantics

- Preserve all M3.22 exact-fit, split, fallback and tail-reclamation behavior.
- Coalesce physically adjacent inactive extents when their end/start addresses match exactly.
- Coalescing may cross Ptr and Handle metadata kinds when both extents are inactive and safely representable.
- The merged extent begins at the lowest address and spans the exact combined physical extent.
- Retire the absorbed metadata record without leaving a duplicate reusable extent.
- Inactive Handle records must leave their master pointer nil and must not expose stale live state.
- Live Ptrs remain immovable.
- Live Handles retain valid master pointers and payload addresses unless existing qualified compaction semantics explicitly relocate them.
- Interior coalescing itself must not change `LR_HEAP_NEXT`.
- Coalescing must not cross a live Ptr/Handle barrier or merge non-adjacent holes.
- Existing M3.11–M3.22 behavior remains regression-qualified.
- `MemErr` follows the existing allocation contract.

## Qualification fixture

The deterministic runtime fixture must exercise:

1. two adjacent interior Ptr holes which individually cannot satisfy a larger request;
2. disposal/coalescing followed by a larger `NewPtr` reusing the combined extent without heap growth;
3. two adjacent interior Handle holes and a larger `NewHandle` reuse with valid master-pointer semantics;
4. at least one mixed Ptr/Handle adjacency case;
5. a live barrier proving coalescing does not cross live allocations;
6. non-adjacent holes proving no accidental merge;
7. preservation of unrelated live payloads and master pointers;
8. interaction with M3.22 split suffixes;
9. safe metadata retirement for the absorbed record;
10. unchanged `LR_HEAP_NEXT` for successful interior coalescing/reuse.

Qualification must include static source checks, deterministic ROM generation, pinned Musashi runtime evidence and a dedicated GitHub Actions workflow before M3.23 can replace M3.22 as the retained Macintosh Plus baseline.

## Non-goals

M3.23 does not yet add:

- arbitrary best-fit or size-class allocation policy;
- a general linked free list;
- moving live Ptr allocations;
- multiple heap zones;
- grow-zone callbacks;
- full classic Macintosh zone/free-list semantics.

Those remain later Memory Manager work.
