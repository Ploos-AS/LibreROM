# LibreROM M2.10 — Macintosh Plus IWM media-sense bring-up

M2.10 extends the clean-room Macintosh Plus bring-up with the first direct floppy-controller interaction through the IWM soft-switch interface.

The milestone remains self-contained:

- no Apple ROM is downloaded, stored, or executed;
- no proprietary System software or disk image is used;
- the only inserted medium in qualification is a project-owned deterministic 400 KiB test image;
- the independent PCE/macplus machine model is pinned to commit `371414f8f41ae02e9ce36004ba7b076fdd3abe63`.

## Contract

The firmware preserves the earlier reset-overlay, RAM/vector, framebuffer, VIA and keyboard bring-up paths, then probes IWM drive 1.

PCE's Mac Plus IWM model decodes soft switches on odd byte addresses, one switch every `$200` bytes. M2.10 explicitly drives CA0, CA1 and CA2 low, drives Q7 low and reads status after driving Q6 high. VIA Port A bit 5 selects sense bank 8, the disk-inserted sense.

The raw status byte is stored at `$00000424`. The firmware then records one of two project-owned markers at `$00000428`:

- `IWMN` — no media detected;
- `IWMP` — media present.

`IWM0` at `$0000042c` records that the IWM probe completed.

## Independent qualification

The PCE qualification runs the same ROM twice:

1. drive 1 configured with `inserted = 0`; expected marker: `IWMN`;
2. drive 1 configured with `inserted = 1` and the project-owned `test-disk.img`; expected marker: `IWMP`.

This proves that LibreROM can access the IWM status path and distinguish an empty drive from an inserted floppy in an independent full-machine emulator.

Run:

```sh
make CROSS=m68k-linux-gnu- qualify-m2_10
```

Evidence is written under `build/m2_10-pce/`.
