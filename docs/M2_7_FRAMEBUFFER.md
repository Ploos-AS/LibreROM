# M2.7 — Macintosh Plus framebuffer diagnostic

M2.7 extends the qualified M2.6 reset-overlay hand-off with a deterministic
project-authored 512×342 monochrome framebuffer diagnostic.

## Clean-room basis

The implementation uses independently documented/emulated Macintosh Plus
hardware behavior only. It contains no Apple ROM code, disassembly, tables, or
binary material.

For the 1 MiB Mac Plus qualification profile, the framebuffer locations are:

- main screen buffer: RAM end - `0x5900` = `0x000FA700`
- alternate screen buffer: RAM end - `0xD900` = `0x000F2700`
- visible payload: 512 × 342 × 1 bit = 21,888 bytes

The firmware writes both buffers so qualification does not depend on the
current VIA screen-buffer-select state. Each buffer is filled with repeating
`0xAA55`, producing a visible one-pixel stripe diagnostic.

## Runtime sequence

1. Perform the non-destructive M2.6-style RAM probe.
2. Install all 256 vectors in backing RAM through the `0x00600000` alias.
3. Write `PRE7` before overlay removal.
4. Disable the reset ROM overlay through VIA A4.
5. Verify the RAM reset vectors through low memory.
6. Write `LRM7` and exercise TRAP #0, which records `EXC7` and returns.
7. Move the qualification stack to `0x000F0000`, below both framebuffer areas.
8. Fill the main and alternate 21,888-byte framebuffers with `0xAA55`.
9. Write the `VID7` completion marker and stop in ROM.

## Qualification

`make CROSS=m68k-linux-gnu- qualify-m2_7` performs:

- static M2.7 invariant checks;
- Musashi MC68000 execution with full framebuffer-byte verification;
- independent PCE Mac Plus execution with pre-overlay vector evidence,
  continuity markers, and memory dumps from both framebuffer bases.

No Apple ROM or proprietary System Software is used by CI.

A local graphical emulator run may additionally be used to visually inspect
the stripe pattern, but the CI verdict is based on deterministic guest memory
state rather than screenshots.
