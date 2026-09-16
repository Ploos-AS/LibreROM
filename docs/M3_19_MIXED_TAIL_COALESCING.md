# M3.19 mixed Ptr/Handle tail coalescing

M3.19 closes the cross-kind tail-reclamation gap left by M3.17 and M3.18.

## Qualified behavior

When disposal rewinds the heap tail, LibreROM now repeatedly scans inactive allocation metadata across both allocation kinds:

- a disposed tail Handle can absorb an immediately preceding inactive Ptr;
- a disposed tail Ptr can absorb an immediately preceding inactive Handle;
- the scan restarts after every absorption, so alternating inactive Ptr/Handle chains can collapse to the first live allocation barrier;
- reclaimed metadata is cleared only after the corresponding block has actually been absorbed into the free tail.

The disposal path does not relocate live Ptrs or live Handles. Interior holes that are not exposed to the heap tail remain available to the existing pressure/compaction mechanisms.

## Regression fixture

The deterministic M3.19 runtime qualification covers both cross-kind directions:

1. Ptr below Handle: dispose the lower Ptr first, then dispose the tail Handle and require the tail to coalesce across the inactive Ptr.
2. Handle below Ptr: dispose the lower Handle first, then dispose the tail Ptr and require the tail to coalesce across the inactive Handle.
3. Reallocate the recovered tail and verify the stable lower Handle remains intact.

The expected recovered tail boundary is `0x0007ff00` before the final refill.

## Implementation note

During qualification, a generated numeric-label collision caused the Handle-below-Ptr case to follow the wrong inherited M3.18 branch. M3.19 uses non-conflicting local labels for its mixed scans. The final dedicated GitHub Actions qualification passes both directions.

## Deliberate limits

M3.19 is still a compact single-zone Memory Manager baseline. It does not yet implement arbitrary free-list allocation, multiple heap zones, grow-zone callbacks, or complete classic Macintosh Memory Manager semantics.

## Status

**M3.19 dedicated CI qualification: PASS.**

M3.19 is included in the normal full regression before development proceeds to M3.20.
