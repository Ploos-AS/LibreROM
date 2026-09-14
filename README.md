# LibreROM

LibreROM is a clean-room, open-source firmware/ROM project for classic Motorola 68000-family Macintosh-compatible systems and emulators.

The long-term goal is to provide a freely redistributable ROM implementation that can boot and support compatible system software without distributing Apple ROM code.

> **Status:** M1 implementation baseline — minimal 68000 ROM source, deterministic layout and static qualification are present. Emulator runtime qualification is the remaining M1 gate.

## Principles

- Clean-room implementation only.
- No Apple ROM images, disassemblies, leaked source, copied constants/tables, or derived binary material in this repository.
- Publicly documented hardware interfaces and independently developed compatibility tests are preferred sources.
- Start small: bring-up infrastructure first, then incrementally implement firmware services.
- Target real 68k hardware semantics where practical, while keeping emulator-based qualification reproducible.
- Implement and qualify representative Macintosh 68k families before alternative 68k-host ports.

## Current M1 ROM

The first executable image is deliberately machine-neutral. It contains:

- a 68000 reset vector pair,
- an initial stack pointer assumption,
- a reset entry point,
- an interrupt-masked diagnostic stop loop,
- a deterministic `LIBREROM-M1` marker,
- a fixed 64 KiB ROM image layout.

This is **not yet a Macintosh-compatible ROM**. It is a bring-up image used to qualify the toolchain, image format, reset path and emulator harness before machine-specific hardware support is added.

## Platform roadmap

LibreROM is **Macintosh first**. The intended progression is:

**early compact Macintosh → Macintosh II family → later 68030/68040 Macs → Macintosh 68k family convergence.**

After that foundation is qualified, LibreROM will explore a portable runtime capable of hosting Macintosh 68k software semantics on other compatible 68k machines.

Future alternative hosts include:

- classic Amiga,
- Atari ST/STE/TT/Falcon-class systems,
- virtual/emulated 68k machines.

The key idea is to execute suitable Macintosh 68k application instructions natively when the host CPU is compatible, while LibreROM provides Toolbox/A-trap, QuickDraw, Memory Manager, Resource Manager, Event Manager and related Macintosh-facing services. Direct Macintosh hardware dependencies may still require compatibility shims or machine emulation.

On Amiga, future backends may accelerate appropriate QuickDraw operations with the Blitter and later make use of other chipset capabilities without changing Macintosh-visible semantics.

See [`docs/ALTERNATIVE_68K_HOSTS.md`](docs/ALTERNATIVE_68K_HOSTS.md) for the architectural direction and compatibility classes.

## Repository layout

```text
docs/               Design, clean-room policy, qualification and roadmap
src/arch/m68k/       68000 reset/vector source
linker/               ROM linker layout
scripts/              Build and qualification helpers
tests/                Host-side tests
build/                Generated artifacts (ignored)
```

## Build

A GNU-style m68k ELF cross-toolchain is expected. Override `CROSS` if your prefix differs.

```sh
make
make check
```

Default tools are:

```text
m68k-elf-as
m68k-elf-ld
m68k-elf-objcopy
```

The generated image is `build/librom-m1.bin` and must be exactly 65536 bytes.

## Qualification

`make check` validates the M0 repository invariants plus M1 source/layout invariants. `make qualify-m1` builds the image and verifies its reset vectors, first opcodes, diagnostic marker, size and SHA-256 metadata.

Runtime qualification in a selected emulator profile remains required before M1 is declared complete.

## Clean-room policy

Read [`docs/CLEAN_ROOM.md`](docs/CLEAN_ROOM.md) before contributing firmware behavior or compatibility data.

Do not submit copyrighted Apple ROM content or code derived from reverse engineering material whose redistribution or use is not clearly lawful for this project.

## Roadmap

See [`docs/ROADMAP.md`](docs/ROADMAP.md).

## License

MIT. See [`LICENSE`](LICENSE).

Copyright © 2026 Ploos AS.
