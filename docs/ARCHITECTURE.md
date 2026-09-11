# Architecture

LibreROM is structured as a small firmware project rather than an operating system. The ROM owns early reset, hardware bring-up and firmware compatibility services; higher-level system software remains outside the ROM image.

## Initial execution model

The first executable target is Motorola 68000 compatible. Code must not assume an MMU, FPU, caches, or instructions introduced after the 68000 unless a later target explicitly enables them.

The M1 image will contain, at minimum:

1. Initial vector table.
2. Reset entry point.
3. Explicit stack/RAM assumptions suitable for the first emulator profile.
4. Deterministic diagnostic/terminal state for qualification.
5. Link-time assertions for ROM boundaries.

## Portability boundaries

Machine-specific hardware belongs behind narrow interfaces so that future Macintosh-class targets do not require rewriting generic firmware code.

Proposed layers:

- `arch/m68k`: CPU reset, vectors and exception primitives.
- `platform/<machine>`: memory map and hardware initialization.
- `firmware`: generic boot and service logic.
- `diagnostics`: test/bring-up paths.

## Qualification

Host-side checks validate repository layout and generated metadata. Runtime qualification will use a reproducible emulator profile with only freely redistributable test payloads and configuration committed to this repository.

No proprietary Macintosh ROM is a build or test dependency.
