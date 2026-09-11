# LibreROM

LibreROM is a clean-room, open-source firmware/ROM project for classic Motorola 68000-family Macintosh-compatible systems and emulators.

The long-term goal is to provide a freely redistributable ROM implementation that can boot and support compatible system software without distributing Apple ROM code.

> **Status:** M0 — project foundation. LibreROM is not yet a usable Macintosh ROM.

## Principles

- Clean-room implementation only.
- No Apple ROM images, disassemblies, leaked source, copied constants/tables, or derived binary material in this repository.
- Publicly documented hardware interfaces and independently developed compatibility tests are preferred sources.
- Start small: bring-up infrastructure first, then incrementally implement firmware services.
- Target real 68k hardware semantics where practical, while keeping emulator-based qualification reproducible.

## Initial scope

M0 establishes the engineering and legal foundation for LibreROM. The first technical target is a minimal 68000-compatible ROM image with deterministic layout, reset/vector handling, diagnostic bring-up, and emulator-testable behavior.

Likely early machine targets will be simple 68000-era Macintosh-class configurations before later 68020/68030/68040 systems are considered.

## Repository layout

```text
docs/       Design, clean-room policy and roadmap
include/    Public project headers
src/        Firmware source
scripts/    Build and qualification helpers
tests/      Host-side tests
```

## Build

M0 contains a host-side qualification target and a placeholder ROM build target. A cross-toolchain will be introduced when the first executable 68k firmware code lands.

```sh
make check
make
```

## Clean-room policy

Read [`docs/CLEAN_ROOM.md`](docs/CLEAN_ROOM.md) before contributing firmware behavior or compatibility data.

Do not submit copyrighted Apple ROM content or code derived from reverse engineering material whose redistribution or use is not clearly lawful for this project.

## Roadmap

See [`docs/ROADMAP.md`](docs/ROADMAP.md).

## License

MIT. See [`LICENSE`](LICENSE).

Copyright © 2026 Ploos AS.
