# M2.1 — Reset overlay and RAM hand-off

LibreROM M2.1 defines the first machine-specific reset-overlay transition for the Macintosh Plus profile.

## Goal

At reset, the Macintosh-class memory map presents ROM at address zero so the Motorola 68000 can fetch the initial supervisor stack pointer and reset PC. After early bring-up, RAM must become visible at address zero and own the exception vector table.

M2.1 deliberately separates two concerns:

1. the **architectural hand-off contract** (qualified here), and
2. the exact hardware write that disables the Macintosh Plus overlay (qualified in later hardware-facing steps).

This avoids claiming hardware compatibility before the VIA-side overlay control has been independently qualified.

## Qualified state transition

The M2.1 model requires:

- reset state: low memory reads resolve to ROM;
- ROM vector 0 supplies SSP;
- ROM vector 1 supplies reset PC;
- firmware populates the backing RAM vector table before removing the overlay;
- overlay transition occurs only after the RAM vector state is valid;
- post-transition state: low memory reads resolve to RAM;
- the RAM reset vectors remain identical to the ROM reset vectors.

## M2.6 reconciliation

M2.6 makes the previously abstract pre-overlay RAM write executable for the Macintosh Plus profile. While ROM owns address zero, the 1 MiB backing RAM is accessed through its alternate window beginning at `0x00600000`. LibreROM installs the complete 256-entry vector table through that window, writes a `PRE6` continuity marker, and only then clears VIA port A bit 4. The same backing RAM then becomes visible at `0x000000`.

This resolves the sequencing ambiguity in the earlier M2.3/M2.4 executable paths without changing the architectural intent of M2.1.

## Macintosh Plus profile

- CPU: Motorola 68000
- qualification RAM: 1 MiB
- physical ROM window: `0x00400000` with a 128 KiB LibreROM target
- alternate backing-RAM window used before overlay removal: `0x00600000`
- reset alias: ROM is presented at low memory while overlay is active
- post-overlay low memory: RAM

The public Macintosh hardware models used for the machine profile expose the reset ROM overlay, fixed ROM window, and alternate RAM mapping needed for this hand-off.

## M2.1 qualification

Run:

```sh
make qualify-m2_1
```

The host-side model verifies the reset fetch, RAM vector state, overlay transition ordering, and post-transition RAM ownership of address zero. It uses only project-authored data and does not depend on any Apple ROM image.

The executable reconciliation is qualified separately with:

```sh
make CROSS=m68k-linux-gnu- qualify-m2_6
```

## Exit criterion

M2.1 passes when the repository checks and overlay model both pass in CI. M2.6 closes the executable sequencing gap by proving pre-overlay vector installation in both the project runtime model and independent PCE/macplus qualification.
