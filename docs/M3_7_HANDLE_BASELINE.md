# LibreROM M3.7 — NewHandle / DisposeHandle baseline

M3.7 introduces the first relocatable-block compatibility slice for the retained Macintosh Plus LibreROM variant.

## Clean-room compatibility surface

The milestone implements:

- `_NewHandle` trap `$A122`
  - input: `D0.L` requested logical size
  - success: `A0.L` points to a master pointer, `D0.W = noErr`
  - failure: `A0 = NIL`, `D0.W = memFullErr`
- `_DisposHandle` / `DisposeHandle` trap `$A023`
  - input: `A0.L` handle
  - result: `D0.W = noErr` or `memWZErr`
- low-memory `MemErr` at `$0220`
- stable project-owned master-pointer slots in RAM
- separate logical size and rounded physical extent for relocatable data blocks
- master-pointer reuse after disposal

M3.7 retains the M3.6 pointer traps (`NewPtr`, `DisposePtr`, `GetPtrSize`, `SetPtrSize`) in the cumulative A-line dispatcher.

## Qualification model

The project-authored runtime:

1. allocates an odd-sized handle block;
2. verifies that the returned handle points to a RAM master pointer;
3. verifies that dereferencing the handle yields the allocated data block;
4. writes through the master pointer to prove usable indirection;
5. disposes the handle and verifies that the master pointer is cleared;
6. repeats disposal and requires `memWZErr`;
7. allocates another handle and requires reuse of the freed master-pointer slot while allocating fresh data.

No Apple ROM image, System software, disassembly, copied tables, or derived binary material is used.

## Deliberate non-goals

This milestone does not yet implement heap compaction, relocation of live handles, purgeability, lock state, `GetHandleSize`, `SetHandleSize`, `HLock`, `HUnlock`, Resource Manager semantics, or full Macintosh zone structures. These remain later M3 compatibility slices.
