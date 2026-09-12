# M2.1 — Reset overlay and RAM hand-off

LibreROM M2.1 defines the first machine-specific reset transition for the Macintosh Plus profile.

## Goal

At reset, the Macintosh-class memory map presents ROM at address zero so the Motorola 68000 can fetch the initial supervisor stack pointer and reset PC. After early bring-up, RAM must become visible at address zero and own the exception vector table.

M2.1 deliberately separates two concerns:

1. the **architectural hand-off contract** (qualified here), and
2. the exact hardware write that disables the Macintosh Plus overlay (qualified in the next hardware-facing step).

This avoids claiming hardware compatibility before the VIA-side overlay control has been independently qualified.

## Qualified state transition

The M2.1 model requires:

- reset state: low memory reads resolve to ROM;
- ROM vector 0 supplies SSP;
- ROM vector 1 supplies reset PC;
- firmware copies the initial vector pair into physical RAM at address `0x000000`;
- overlay transition occurs only after the RAM vector pair is valid;
- post-transition state: low memory reads resolve to RAM;
- the copied RAM vectors remain identical to the ROM reset vectors.

## Macintosh Plus profile

- CPU: Motorola 68000
- qualification RAM: 1 MiB
- physical ROM window: `0x00400000` with a 128 KiB LibreROM target
- reset alias: ROM is presented at low memory while overlay is active
- post-overlay low memory: RAM

The public Macintosh hardware model used for the machine profile exposes `0x000000–0x3fffff` as RAM/ROM depending on overlay state and a fixed ROM window beginning at `0x400000`.

## M2.1 qualification

Run:

```sh
make qualify-m2_1
```

The host-side model verifies the reset fetch, RAM vector copy, overlay transition ordering, and post-transition RAM ownership of address zero. It uses only project-authored data and does not depend on any Apple ROM image.

## Exit criterion

M2.1 passes when the repository checks and overlay model both pass in CI.

A PASS here means the reset-overlay **contract and hand-off sequencing** are qualified. It does **not** yet mean the exact Macintosh Plus VIA overlay-control write is qualified on an emulator or physical machine.
