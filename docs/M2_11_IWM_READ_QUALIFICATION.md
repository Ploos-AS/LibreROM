# M2.11 — IWM raw floppy read qualification

M2.11 extends the Macintosh Plus clean-room bring-up from media sensing to an actual raw floppy data path.

## Scope

The firmware keeps the cumulative reset, RAM/vector, framebuffer, VIA interrupt, keyboard and M2.10 media-sense coverage. With inserted project-owned media it then:

1. selects side/head 0,
2. turns drive 1 motor on through the IWM drive-control latch,
3. asserts IWM `ENABLE`,
4. selects `Q6=0,Q7=0` data-read mode,
5. polls the IWM data register with a bounded timeout,
6. captures sixteen GCR bytes whose high bit is set into RAM at `0x00000430`,
7. writes `DAT1` at `0x00000440` only after all sixteen bytes were captured,
8. disables the drive again before stopping.

`RDF1` marks a bounded read timeout. `NOD1` marks an unexpected no-media path.

## Independent PCE qualification

CI builds the pinned PCE Macintosh Plus model at commit `371414f8f41ae02e9ce36004ba7b076fdd3abe63` and creates a project-owned 400 KiB single-sided Macintosh PSI image using PCE's own `psi` utility. PCE converts that sector image into the emulated GCR track stream consumed by the IWM model.

Qualification requires:

- the existing media-present marker `IWMP`,
- completion marker `IWM1`,
- raw-read success marker `DAT1`,
- absence of `RDF1`,
- a 16-byte capture buffer at `0x00000430`.

The firmware writes `DAT1` only after receiving sixteen IWM data bytes with bit 7 set, so the marker cannot be reached merely from the M2.10 media-sense path.

## Clean-room rule

No Apple ROM image, Apple System software, disassembly, leaked source, or Apple-derived binary fixture is used. The ROM is LibreROM project code and the floppy fixture is generated during CI from project-owned test data structures.

Sector decoding and a boot-block loader are intentionally outside this milestone; M2.11 establishes the raw IWM/GCR read primitive they can build on.
