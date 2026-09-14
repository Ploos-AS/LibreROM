# M3.12 — Locked purgeable memory under pressure

M3.12 hardens the Macintosh Plus Memory Manager path introduced through M3.11.

## Goal

Prove that purgeable memory is reclaimed only when it is eligible for purge. A handle carrying both the purgeable and locked state bits must survive allocation pressure unchanged. After `HUnlock`, the same tail allocation must become reclaimable and permit the pending allocation to succeed.

## Runtime contract

The M3.12 ROM performs this deterministic sequence:

1. Allocate a small ordinary handle and write a sentinel payload.
2. Allocate a tail handle large enough to consume the remaining modeled heap.
3. Mark the tail handle purgeable with `HPurge` and locked with `HLock`.
4. Attempt another `NewHandle` allocation. It must fail with `memFullErr`, leave `LR_HEAP_NEXT` unchanged at the heap limit, and preserve the locked handle master pointer.
5. Unlock the tail handle with `HUnlock`.
6. Retry the same allocation. The allocator must reclaim the now-unlocked purgeable tail block, clear its master pointer to NIL, and satisfy the new allocation from the reclaimed address.
7. Verify the original ordinary handle and payload remain intact.

## Qualification

Run:

```sh
CROSS=m68k-linux-gnu- bash scripts/qualify_m3_12.sh
```

Qualification uses the pinned Musashi 68000 core already used by the M3.x runtime gates and records machine-readable evidence in:

```text
build/m3_12-runtime/runtime.txt
```

Expected terminal result:

```text
LibreROM M3.12 locked-purge pressure runtime qualification: PASS
```

## Scope

M3.12 deliberately does not claim general heap compaction. Reclaim remains limited to an eligible purgeable block at the heap tail. General fragmentation/compaction is a later milestone.
