# M3.14 — Address-ordered Handle compaction

M3.14 removes the M3.13 requirement that Handle-table order also be physical heap order.

## Scope

The compactor now repeatedly selects the lowest-address live Handle at or above the current compaction cursor. This makes relocation independent of master-pointer/record order while preserving the M3.13 locked-handle barrier semantics.

The M3.14 pass:

- scans all live Handle records for the next lowest physical data address;
- moves unlocked blocks downward toward the compaction cursor;
- updates both `LR_HREC_DATA` and the public master pointer after relocation;
- treats locked Handles as fixed barriers and advances the cursor past them;
- never lets an earlier table record overwrite a lower-address block that has not yet been moved;
- preserves the M3.11 purge-first pressure path before compaction;
- retries the original `_NewHandle` request against the compacted heap tail.

## Runtime qualification

The Musashi gate constructs a deliberately reordered heap through public Memory Manager traps:

1. allocate one large stable lower Handle;
2. allocate A, B and C as small Handles in record order;
3. grow non-tail A with `_SetHandleSize`, forcing A to relocate after B and C;
4. allocate D to fill the heap exactly to `LR_HEAP_LIMIT`;
5. request another Handle so pressure recovery must compact;
6. verify physical post-compaction order B, C, A, D despite record order A, B, C, D;
7. verify every master pointer follows its moved block;
8. verify payload markers for B, C, both ends of enlarged A, and D survive;
9. verify the large lower Handle remains unchanged;
10. verify the new allocation occupies the recovered tail and the heap again ends exactly at `LR_HEAP_LIMIT`.

## Deliberate limits

M3.14 still compacts Handle blocks only. Mixed Ptr/Handle zone compaction, multiple heap zones, grow-zone callbacks, sophisticated purge policy and full classic Macintosh heap semantics remain later work.

The implementation remains clean-room and is based only on public observable behavior, with no Apple ROM code, disassembly, or derived implementation material.
