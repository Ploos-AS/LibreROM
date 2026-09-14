# M3.13 — Handle compaction under fragmentation

M3.13 adds the first real fragmented-heap compaction behavior to LibreROM's clean-room Memory Manager baseline.

## Scope

When `_NewHandle` cannot satisfy an allocation at the current heap tail, LibreROM now preserves the M3.11 purge-reclaim attempt and then performs a conservative forward compaction pass over live Handle blocks.

The first compaction slice:

- closes holes left by disposed Handles;
- moves unlocked live Handle data downward toward `LR_HEAP_BASE`;
- updates both the internal Handle record and public master pointer after relocation;
- copies the full allocated extent so payload bytes survive relocation;
- treats locked Handles as immovable barriers;
- leaves ordinary lower live Handles unchanged;
- retries the original `_NewHandle` request against the compacted heap tail.

## Runtime qualification

The deterministic Musashi gate proves that:

1. a stable lower Handle remains live;
2. disposing a middle Handle creates a real hole;
3. a large Handle can fill the remaining heap above the hole;
4. while that large Handle is locked, an allocation that requires compaction fails with `memFullErr` and the heap remains unchanged;
5. after `HUnlock`, the same allocation triggers compaction;
6. the large Handle moves from `0x00010040` to `0x00010020`;
7. its master pointer follows the relocated data;
8. both head and tail payload sentinels survive the overlapping downward move;
9. the new allocation occupies the recovered tail at `0x0007ffe0` and ends exactly at `LR_HEAP_LIMIT`;
10. the stable lower Handle retains both its original address and payload.

## Deliberate limits

M3.13 is the first compaction baseline, not a complete classic Macintosh heap-zone implementation. The pass currently assumes live Handle data remains in allocation/table order and does not yet solve arbitrary reordered blocks, mixed Ptr/Handle zone compaction, grow-zone callbacks, multiple heap zones, or advanced purge/compaction heuristics.

Those behaviors remain later Memory Manager work. The implementation remains clean-room and is based only on public observable behavior, with no Apple ROM code, disassembly, or derived implementation material.
