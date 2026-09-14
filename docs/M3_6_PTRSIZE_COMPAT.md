# LibreROM M3.6 — GetPtrSize / SetPtrSize compatibility

M3.6 extends the clean-room Macintosh Plus Memory Manager slice with documented pointer sizing operations while preserving M3.4 `_NewPtr` and M3.5 `_DisposPtr` behavior.

## Compatibility surface

- `_SetPtrSize` trap `$A020`
  - `A0.L`: pointer to a nonrelocatable block
  - `D0.L`: requested new logical size
  - `D0.W`: result code
- `_GetPtrSize` trap `$A021`
  - `A0.L`: pointer to a nonrelocatable block
  - `D0.L`: logical block size on success; error code on the qualified invalid/free-block path
- `MemErr` at low-memory address `$0220`
- `noErr = 0`, `memFullErr = -108`, `memWZErr = -111`

The trap words and register contracts are taken from public historical Macintosh documentation. No Apple ROM image, disassembly, leaked source, derived table, or proprietary System software is used.

## LibreROM allocation model

M3.6 upgrades the project-owned allocation records to keep:

1. block pointer,
2. requested logical size,
3. even-byte physical extent,
4. active/free state.

This distinction lets an odd-sized `NewPtr` request retain its logical size for `GetPtrSize` while keeping the physical allocator 68000-friendly.

`SetPtrSize` currently supports:

- shrinking the logical size;
- growing within an already reserved physical extent;
- extending a block in place when it is the current bump-heap tail and space remains;
- `memFullErr` when the requested growth cannot be satisfied;
- `memWZErr` for a disposed or invalid pointer.

This is deliberately not yet a complete Macintosh heap-zone implementation. It does not compact the heap, move nonrelocatable blocks, invoke grow-zone procedures, or reproduce undocumented block headers.

## Qualification

The project-authored Musashi runtime test checks:

- `NewPtr(0x21)` produces logical size `0x21` with physical extent `0x22`;
- `GetPtrSize` returns `0x21`, not the rounded physical extent;
- shrink to `0x10` succeeds;
- tail growth to `0x31` succeeds and extends the bump pointer to `0x10032`;
- oversized growth returns `memFullErr` without corrupting the block;
- after `DisposePtr`, `SetPtrSize` returns `memWZErr` and updates `MemErr`.

The runtime remains a clean-room qualification harness and does not constitute a claim of full Apple Memory Manager compatibility.
