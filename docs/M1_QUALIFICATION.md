# M1 qualification

M1 introduces the first executable LibreROM image.

## Static/build gate

Run:

```sh
make clean
make check
make qualify-m1
```

Expected properties:

- assembler target is Motorola 68000,
- ROM size is exactly 65536 bytes,
- vector 0 contains SSP `0x00010000`,
- vector 1 points to `_reset` inside the image,
- reset begins by loading SR with `0x2700`,
- image contains the project-authored marker `LIBREROM-M1`,
- remaining image space is deterministically padded with `0xff`,
- SHA-256 is printed for the generated image.

## Runtime gate

M1 is not complete until the generated image is executed in a reproducible 68000 emulator profile and reaches the expected STOP diagnostic state without relying on any proprietary Apple ROM.

Record the emulator, version, command/configuration, observed state, ROM SHA-256 and result here when that qualification is performed.

### Runtime result

**PENDING** — emulator profile not yet qualified.
