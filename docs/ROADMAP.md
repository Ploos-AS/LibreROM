# LibreROM roadmap

## M0 — Foundation

- Define project scope and clean-room rules.
- Establish MIT licensing and Ploos AS copyright.
- Establish source/build/test repository structure.
- Define initial 68k ROM architecture and qualification strategy.

Exit criterion: `make check` validates repository invariants and the project contains no proprietary ROM material.

## M1 — Minimal 68k ROM image

- Introduce m68k cross-toolchain support.
- Produce a deterministic ROM binary with vector table and reset entry.
- Establish linker script, ROM layout, size checks and checksums.
- Add emulator-friendly diagnostic output or observable halt state.

Exit criterion: generated ROM boots to a known diagnostic state in the selected emulator profile.

## M2 — Machine bring-up

- RAM discovery/basic initialization.
- Minimal exception handling.
- Basic VIA/video/input bring-up for the first selected Macintosh-class target.
- Reproducible emulator qualification.

## M3 — Firmware services

- Implement the minimum set of firmware/trap-facing services needed by the first software boot target.
- Add behavioral conformance tests.

## M4 — Boot path

- Storage/device discovery required for boot.
- Load and transfer control to a compatible operating-system environment or project-authored diagnostic payload.

## Later

- Additional 68000-class machines.
- 68020/68030 and later 68k Macintosh-class machines.
- Broader Toolbox/ROM compatibility where clean-room implementation is practical.
- Hardware qualification in addition to emulators.

Milestone boundaries may be refined as hardware research and compatibility testing progress.
