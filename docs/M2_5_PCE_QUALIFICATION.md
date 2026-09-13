# LibreROM M2.5 — independent PCE/macplus qualification

M2.5 moves Macintosh Plus bring-up beyond LibreROM's project-owned Musashi hardware harness and executes the M2.4 ROM in the independently developed PCE/macplus machine model.

The qualification is intentionally self-contained and clean-room safe:

- no Apple ROM is downloaded, stored, or executed;
- no proprietary System software or disk image is used;
- the only ROM supplied to PCE is the LibreROM M2.4 128 KiB image built from this repository;
- PCE is pinned to commit `371414f8f41ae02e9ce36004ba7b076fdd3abe63` for reproducibility.

## Contract

PCE is configured as a Macintosh Plus with an MC68000 and 1 MiB RAM. The LibreROM image is mapped at `$00400000` with a 128 KiB ROM block.

The PCE monitor starts from reset and uses its Mac-specific `g e` command to run until CPU exception `$20`, which is decimal exception 32 and therefore the 68000 `TRAP #0` vector. This avoids depending on an address breakpoint at the following `STOP` instruction.

After PCE reports the trap exception, the monitor executes exactly two handler instructions. Those instructions write LibreROM's exception marker and stop immediately before `_m2_4_stop`. The monitor then dumps eight bytes at `$00000400`.

M2.5 passes only when the independent machine model reports both project-owned markers:

- `$00000400`: `4C 52 4D 34` (`LRM4`) — RAM/vector bring-up completed.
- `$00000404`: `45 58 43 34` (`EXC4`) — `TRAP #0` dispatched through the RAM vector table into LibreROM's exception handler.

This therefore covers reset execution, Mac Plus ROM mapping/overlay hand-off, RAM writes, exception-vector installation, and an actual 68000 trap path under PCE's machine model.

## Qualification

Run:

```sh
make CROSS=m68k-linux-gnu- qualify-m2_5
```

Evidence is written under `build/m2_5-pce/`, including the generated PCE configuration and monitor transcript.
