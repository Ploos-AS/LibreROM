# M2.9 — Macintosh Plus keyboard/VIA bring-up

M2.9 closes the input portion of the initial Macintosh Plus machine bring-up without using Apple ROM code or Apple system software.

## Clean-room basis

Independent emulator models agree that the pre-ADB Macintosh keyboard is connected through the 6522 VIA: CB1 carries keyboard clock, CB2 keyboard data, and the VIA shift-register interrupt indicates a completed byte. PCE additionally models the keyboard protocol as a shift-register peripheral.

For qualification LibreROM sends keyboard command `0x16` (model-number query) through the VIA shift register. This gives a deterministic keyboard-to-VIA response even in headless CI and avoids dependence on host GUI key injection.

## VIA contract

Canonical PCE VIA mirror:

- SR: `0x00EFF400` (register 10)
- ACR: `0x00EFF600` (register 11)
- IFR: `0x00EFFA00` (register 13)
- IER: `0x00EFFC00` (register 14)
- SR interrupt bit: `0x04`
- CPU interrupt: 68000 level 1 / autovector 25

The qualification uses ACR shift mode `0x1c` for output and `0x0c` for input, matching the pinned independent PCE 6522 model.

## Firmware sequence

1. Preserve the ordered reset-overlay hand-off and complete RAM vector table.
2. Preserve framebuffer diagnostics from M2.7/M2.8.
3. Disable unrelated VIA interrupt enables.
4. Put the VIA shift register in external-clock output mode.
5. Write keyboard model query `0x16` to SR.
6. Switch SR to external-clock input mode.
7. Enable only the SR interrupt source and lower CPU IPL.
8. Level-1 handler verifies the SR source, reads SR to acknowledge it, records the received byte, and writes `KBD9`.
9. Main code disables the SR interrupt and writes `INP9` before stopping.

## Qualification

Musashi models the same VIA SR/IRQ contract and supplies a deterministic keyboard response byte through the receive path. PCE independently proves the actual keyboard model, VIA shift-register transport, level-1 interrupt delivery, acknowledgement, and final markers.

M2.9 PASS requires both runtimes, inherited overlay/vector/framebuffer regressions, and CI to succeed.
