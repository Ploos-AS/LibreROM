# M3.2 — Memory primitive

M3.2 adds the first Macintosh-relevant firmware primitive on top of the qualified LibreROM A-line service infrastructure.

This milestone does **not** claim compatibility with Apple's Memory Manager or any specific Toolbox trap. The service is intentionally LibreROM-private so its behavior can be qualified independently before compatibility aliases are introduced.

## Private service

`0xA0F2` — `LR_SVC_MEM_ALLOC`

Input:

- `D0`: requested byte count, greater than zero.

Output:

- success: `D0 = 0`, `A0 = allocated address`;
- failure: `D0 = -1`, `A0 = 0`.

Allocation sizes are rounded up to an even byte count. The qualification heap starts at `0x00010000`, ends before `0x00080000`, and keeps its next-free pointer at `0x00000440`.

## Qualification

The project-authored ROM performs three calls:

1. allocate `0x20` bytes and require pointer `0x00010000`;
2. allocate `0x11` bytes and require even rounding, returning `0x00010020` and advancing the heap top to `0x00010032`;
3. request an oversized `0x00070000` allocation and require deterministic failure with the heap top unchanged.

The Musashi MC68000 runtime also verifies the Mac Plus reset-overlay hand-off, RAM vector 10 installation, service markers, final heap state, and absence of the unknown-service marker.

Exit criterion: `scripts/qualify_m3_2.sh` prints `LibreROM M3.2 memory primitive runtime qualification: PASS` and writes `build/m3_2-runtime/runtime.txt`.
