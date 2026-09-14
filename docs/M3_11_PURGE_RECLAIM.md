# M3.11 — Purge/reclaim under memory pressure

M3.11 turns the M3.10 purgeable-state bit into observable Memory Manager behavior.

## Scope

When `_NewHandle` cannot satisfy an allocation from the current bump-heap tail, LibreROM may reclaim an existing handle block only when all of these conditions hold:

- the handle is active;
- its property byte has the purgeable bit (bit 6) set;
- it is not locked (bit 7 clear);
- its data block is exactly the current heap tail.

The reclaimed handle record and master-pointer slot remain allocated, but the master pointer becomes NIL. This matches the important public behavioral distinction between disposing a handle and purging its relocatable block.

After reclaim, `_NewHandle` retries the requested allocation. If no eligible tail block exists, behavior remains `memFullErr = -108`.

## Runtime qualification

The project-authored Musashi gate proves that:

1. cumulative pointer services still execute;
2. an ordinary unpurgeable handle remains live;
3. a second, very large tail handle can be marked purgeable;
4. a following allocation that otherwise exceeds the heap limit causes the purgeable tail block to be reclaimed;
5. the purged handle's master pointer becomes NIL;
6. `_GetHandleSize` on that NIL master pointer reports `nilHandleErr = -109`;
7. the unpurgeable handle and its payload remain unchanged;
8. the new handle reuses the reclaimed tail address and `MemErr` is restored to `noErr`.

## Deliberate limits

M3.11 is not a general heap compactor. It does not move arbitrary intervening blocks, purge locked handles, implement a grow-zone callback, or automatically reconstitute a purged handle. Those are later Memory Manager slices.

The implementation remains clean-room and uses only public behavioral contracts; no Apple ROM binary, disassembly, or derived implementation material is used.
