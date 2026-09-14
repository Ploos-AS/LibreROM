# M3.4 — `_NewPtr` compatibility slice

M3.4 is LibreROM's first Memory Manager milestone that intentionally implements a documented Macintosh software-facing trap contract rather than a LibreROM-private qualification ABI.

## Public compatibility contract

The implementation is based on publicly available Macintosh programming documentation and clean-room behavioral facts:

- `_NewPtr` uses A-line trap word `$A11E`.
- The requested logical size is supplied in `D0.L`.
- The returned nonrelocatable pointer is supplied in `A0`, or `NIL` on failure.
- The Memory Manager result code is returned in `D0.W`.
- `noErr` is `0`.
- `memFullErr` is `-108` (`$FF94`).
- The low-memory `MemErr` word is at `$0220` and reflects the last Memory Manager result.

A historical Inside Macintosh erratum is important here: some editions incorrectly stated that the requested NewPtr size arrived in `A0`; the correction specifies `D0`.

## LibreROM implementation

M3.4 dispatches the actual `$A11E` trap through the already-qualified 68000 A-line exception path.

For qualification it uses the existing simple heap window:

- base: `$00010000`
- limit: `$00080000`
- allocation granularity: even-byte alignment

On success:

- `A0` receives the allocated address;
- `D0.W = 0`;
- `MemErr = 0`.

On insufficient space:

- `A0 = NIL`;
- `D0.W = -108` (`memFullErr`);
- `MemErr = -108`;
- the heap top is unchanged.

## Explicit non-goals

M3.4 does **not** yet claim full classic Macintosh Memory Manager compatibility. In particular, it does not yet implement:

- real heap-zone structures or `TheZone`;
- heap compaction or relocatable blocks;
- grow-zone callbacks or purge behavior;
- `_NewPtr` `SYS` or `CLEAR` modifiers;
- `DisposPtr`;
- historical block headers or all low-memory globals.

The claim is deliberately narrow: LibreROM now implements the documented base `_NewPtr` register/result/error contract on the qualified Macintosh Plus profile.

## Qualification

Run:

```sh
CROSS=m68k-linux-gnu- bash scripts/qualify_m3_4.sh
```

The qualification verifies:

1. real `$A11E` dispatch through vector 10;
2. successful pointer allocation;
3. even-byte alignment;
4. `D0.W = noErr` and `MemErr = noErr` on success;
5. `A0 = NIL`, `D0.W = memFullErr`, and `MemErr = memFullErr` on OOM;
6. failed allocation does not move the heap top;
7. overlay/vector invariants inherited from the earlier Macintosh Plus bring-up.

## Clean-room provenance

No Apple ROM image, disassembly, leaked source, or copied ROM implementation was used. The trap word and calling convention are documented public API facts. Implementation code is project-authored.
