# M3.5 — DisposePtr compatibility slice

M3.5 extends LibreROM's first compatibility-facing Memory Manager path with the documented classic Macintosh `DisposPtr` / `DisposePtr` register trap.

## Public contract implemented

- `_NewPtr`: trap `$A11E`
  - input: `D0.L` byte count
  - output: `A0` pointer or NIL, `D0.W` result
- `_DisposPtr`: trap `$A01F`
  - input: `A0.L` pointer to a nonrelocatable block
  - output: `A0 = 0`, `D0.W` result
- low-memory `MemErr`: `$0220`
- `noErr = 0`
- `memFullErr = -108`
- `memWZErr = -111`

The trap number and register contract are taken from public Macintosh programming documentation. No Apple ROM image, disassembly, leaked source, or derived ROM data is used.

## LibreROM implementation boundary

LibreROM M3.5 uses a deliberately small project-authored allocator rather than attempting to reproduce undocumented heap internals. Eight allocation records track pointer, rounded size, and active/free state. `DisposePtr` requires an exact active record match. A successful disposal marks the record reusable; a later `NewPtr` uses first-fit reuse when the freed block is large enough. Invalid or double disposal returns `memWZErr` and stores the same error in `MemErr`.

This milestone does **not** yet claim full classic Memory Manager compatibility. In particular it does not implement heap zones, compaction, GrowZone callbacks, handles, purgeability/locking, `SetPtrSize`, or all trap variants.

## Qualification

The MC68000 Musashi qualification proves:

1. two `NewPtr` allocations succeed;
2. `DisposePtr` on the first allocation returns `noErr`, clears `A0`, and clears `MemErr`;
3. a smaller subsequent `NewPtr` reuses the disposed block without advancing `heap_next`;
4. disposing the second block succeeds;
5. disposing that same pointer again returns `memWZErr (-111)`, clears `A0`, and stores `memWZErr` in `$0220`;
6. the Mac Plus reset-overlay and A-line-vector invariants remain intact.

Run locally with:

```sh
CROSS=m68k-linux-gnu- bash scripts/qualify_m3_5.sh
```
