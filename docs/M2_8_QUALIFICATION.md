# M2.8 — VIA Timer 1 interrupt bring-up

M2.8 extends the Macintosh Plus machine bring-up path with a project-authored VIA Timer 1 interrupt test.

## Scope

The firmware preserves the qualified M2.6 reset-overlay hand-off and M2.7 framebuffer diagnostic, then proves a real interrupt path:

1. RAM vector table is installed before overlay removal.
2. 68000 level-1 autovector (vector 25, offset `0x64`) points to `_m2_8_via_irq`.
3. VIA Timer 1 is configured through the canonical PCE-compatible Mac Plus VIA mirror:
   - `T1CL = 0x00EFE800`
   - `T1CH = 0x00EFEA00`
   - `ACR  = 0x00EFF600`
   - `IFR  = 0x00EFFA00`
   - `IER  = 0x00EFFC00`
4. Timer 1 uses IFR/IER bit `0x40`.
5. Firmware enables Timer 1 IRQ, starts a `0x0200` one-shot count, and lowers the 68000 interrupt mask to IPL 0.
6. The VIA asserts Macintosh Plus CPU interrupt level 1.
7. The handler reads T1 counter-low to acknowledge Timer 1, writes the `IRQ8` evidence marker, and returns with `RTE`.
8. Firmware masks interrupts, disables Timer 1 IER, writes `TMR8`, and stops.

## Evidence markers

- `LRM8` — low-RAM hand-off complete.
- `EXC8` — inherited TRAP #0 exception test passed.
- `PRE8` — backing RAM populated before overlay removal.
- `VID8` — framebuffer regression path completed.
- `IRQ8` — VIA Timer 1 level-1 handler executed.
- `TMR8` — firmware observed the interrupt and completed timer shutdown.

## Independent references

The implementation contract was derived from independent emulator behavior rather than Apple ROM code. PCE's 6522 model uses Timer 1 IFR/IER bit `0x40`, asserts IRQ when an enabled IFR source is active, and clears Timer 1 IFR when T1 counter-low is read. PCE's Macintosh Plus machine wiring routes VIA IRQ to 68000 interrupt level 1.

No Apple ROM image, disassembly, leaked source, or proprietary System software is used by M2.8 qualification.

## Qualification

`make CROSS=m68k-linux-gnu- qualify-m2_8` performs:

- static invariant checks;
- a pinned Musashi 68000 runtime qualification with a project-authored VIA Timer 1 model;
- an independent pinned PCE Macintosh Plus runtime qualification using PCE's own 6522 and interrupt wiring.

M2.8 is complete only when both runtime paths report PASS.
