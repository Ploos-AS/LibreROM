# M3.3 — Pointer allocation and memory status

M3.3 advances LibreROM's clean-room Memory Manager foundation from the M3.2 raw bump-allocation primitive to a pointer-oriented calling model with separate error/status reporting.

## Private qualification ABI

These services are LibreROM-private and are **not yet claims of Apple Toolbox trap compatibility**.

- `0xA0F3` — `LR_SVC_NEW_PTR`
  - input: `D0` requested byte count (`> 0`)
  - output: `A0` allocated pointer, or `0` on failure
  - `D0` is preserved
  - allocation size is rounded up to an even byte count
- `0xA0F4` — `LR_SVC_MEM_STATUS`
  - output: `D0 = 0` after the most recent successful allocation
  - output: `D0 = -1` after allocation failure

Qualification heap window remains `0x00010000..0x0007ffff`. Internal state is kept at project-owned low-memory locations `0x00000440` (`heap_next`) and `0x00000444` (`last_error`). These addresses are qualification state only and do not claim Macintosh low-memory-global compatibility.

## Runtime qualification

The Musashi MC68000 runtime proves:

1. reset overlay hand-off and A-line vector installation still work;
2. a 32-byte pointer allocation returns `0x00010000`;
3. `MEM_STATUS` reports success;
4. an odd 17-byte allocation returns `0x00010020` and advances the heap to `0x00010032`;
5. an oversized allocation returns `NULL`;
6. failed allocation leaves `heap_next` unchanged;
7. `MEM_STATUS` reports failure after OOM;
8. the unknown A-line path is not reached.

Run:

```sh
CROSS=m68k-linux-gnu- bash scripts/qualify_m3_3.sh
```

## Clean-room boundary

M3.3 defines project-authored behavior only. A later milestone may map documented Macintosh Memory Manager trap semantics onto this infrastructure once the exact compatibility contract and behavioral tests are defined from permissible public documentation and independent observations.
