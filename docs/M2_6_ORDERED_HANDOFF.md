# M2.6 — Ordered reset-overlay hand-off

M2.6 reconciles the architectural M2.1 contract with executable Macintosh Plus bring-up.

## Contract

At reset, ROM owns low memory for the MC68000 reset-vector fetch. The 1 MiB qualification RAM remains reachable through the Macintosh Plus alternate RAM window beginning at `0x00600000`.

LibreROM therefore performs the hand-off in this order:

1. execute from the fixed ROM window at `0x00400000`;
2. probe backing RAM through `0x00600000`;
3. install all 256 MC68000 vectors into backing RAM through that alternate window;
4. write the project-owned `PRE6` marker while ROM still owns low memory;
5. only then clear VIA port A bit 4 and remove the reset ROM overlay;
6. verify the preinstalled reset vectors through low memory at `0x000000`;
7. write `LRM6`, execute `TRAP #0`, and observe `EXC6` from the RAM vector table.

The canonical VIA mirror used by executable qualification is ORA `0x00efe200` and DDRA `0x00efe600`.

## Independent qualification

Musashi records whether the complete vector state and `PRE6` marker were present at the exact transition where overlay A4 changes from asserted to clear.

PCE/macplus stops at `_m2_6_before_overlay_off`, observes the backing RAM through `0x00600000`, then continues through the overlay transition and stops at `_m2_6_stop`. The final dump must show `LRM6`, `EXC6`, and preserved `PRE6` in low RAM.

No Apple ROM image or proprietary System software is used.

Run:

```sh
make CROSS=m68k-linux-gnu- qualify-m2_6
```

Exit criterion: static invariants, Musashi runtime qualification, and independent PCE/macplus qualification all pass.
