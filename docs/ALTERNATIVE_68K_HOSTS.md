# LibreROM alternative 68k hosts

## Status

**Future architecture track — implementation is intentionally deferred until the Macintosh 68k family has converged through M8.**

LibreROM is a Macintosh-compatible clean-room ROM/runtime project first. Alternative 68k hosts are a later portability experiment built on top of a qualified Macintosh software-facing environment.

## Core idea

Classic Macintosh, Amiga and Atari systems all use Motorola 68k-family processors. When a Macintosh application depends primarily on Macintosh OS/Toolbox services rather than direct Macintosh hardware access, its application instructions may be able to execute directly on another compatible 68k CPU.

LibreROM would provide the Macintosh-facing environment while a host-specific backend drives the actual machine.

Conceptually:

```text
Macintosh 68k application
          |
   native 68k execution
          |
        LibreROM
  Toolbox / QuickDraw
 Memory / Resource / Event
 Window / Menu / File etc.
          |
    platform backend
          |
 Macintosh / Amiga / Atari
```

This is not full Macintosh hardware emulation and does not imply that every classic Macintosh application can run unchanged on every 68k host.

## Why this differs from ordinary emulation

A conventional Macintosh emulator reproduces the Macintosh CPU and hardware environment, commonly relying on an Apple ROM image or a compatible replacement ROM.

For an alternative native host, LibreROM instead aims to:

- execute application 68k instructions directly when CPU-compatible,
- implement Macintosh Toolbox/A-trap semantics in clean-room code,
- translate graphics, input, timers, filesystem and other machine services to the host,
- emulate only behaviors that cannot reasonably be translated.

The expected payoff is a thinner runtime for well-behaved applications and a clean separation between Macintosh semantics and physical Macintosh hardware.

## Prerequisite: Macintosh compatibility first

Before alternative hosts are implemented, LibreROM must understand the environment it is reproducing.

The Macintosh-first work therefore establishes:

- reset/startup behavior,
- low-memory/global conventions,
- A-trap dispatch,
- Memory Manager behavior,
- Resource Manager behavior,
- Event Manager behavior,
- QuickDraw,
- Window/Menu/Dialog-facing services as needed,
- filesystem and device-facing services,
- machine-profile and compatibility regression infrastructure.

Only after those layers are tested on Macintosh-class targets should they be abstracted onto another machine.

## Amiga host

### Objective

Run compatible classic Macintosh 68k applications on classic Amiga hardware without requiring Apple ROM code and without emulating a 68k CPU that the host already provides.

### Candidate host progression

- 68000 OCS/ECS baseline
- 68020/68030 accelerated Amigas
- AGA later
- optional RTG later

### Backend responsibilities

The Amiga backend would provide adapters for:

- memory discovery/allocation,
- exception and interrupt handling,
- CIA timers,
- keyboard and mouse,
- storage/filesystem,
- display surfaces,
- audio where Macintosh APIs require it,
- timekeeping.

### QuickDraw on Amiga

QuickDraw is a particularly attractive translation boundary. LibreROM can preserve Macintosh drawing semantics while implementing raster operations on Amiga hardware.

Potential acceleration includes:

- Blitter-backed BitBlt/copy operations,
- fills and masks,
- planar framebuffer operations,
- carefully selected Copper use for display setup,
- later AGA/RTG backends.

Acceleration must preserve QuickDraw-visible semantics. Host-specific features are optimizations, not replacements for Macintosh behavior.

## Atari host

### Objective

Run compatible Macintosh 68k applications through LibreROM on Atari 68k systems using a host backend rather than Apple ROM code.

Candidate hosts may eventually include:

- ST/STE,
- Mega-class systems,
- TT030,
- Falcon030.

The backend would adapt Macintosh services to Atari video, input, timers, storage and interrupt facilities.

LibreROM and LibreTOS remain separate layers of compatibility:

```text
LibreROM -> Macintosh software semantics
LibreTOS -> Atari TOS software semantics
```

They may share low-level Ploos AS tooling or machine knowledge, but neither should depend on the other's application ABI.

## Native execution constraints

Native execution is possible only when the host processor implements the instructions expected by the guest application.

Examples:

- a 68000 Macintosh application is a good candidate for a 68000 Amiga or ST,
- a 68020 application requires a 68020-or-newer host or CPU emulation,
- a 68030/68040 program may rely on CPU/MMU/FPU behavior absent from an earlier host.

LibreROM must therefore record both the Macintosh software requirement and the host CPU capability in qualification profiles.

## Macintosh A-traps

A major compatibility mechanism is the Macintosh A-line trap model.

LibreROM can own the relevant exception/trap dispatch environment and implement supported Toolbox calls itself. This is one reason API-driven classic Mac software is an interesting candidate for native cross-machine execution: application code can remain 68k while calls into the Macintosh environment are redirected to LibreROM.

The project must not derive implementations from proprietary Apple ROM code. Trap behavior should be implemented from permissible public documentation, independent testing and clean-room specifications according to `CLEAN_ROOM.md`.

## Low-memory globals and memory map

Classic Macintosh software may depend on conventional low-memory globals and memory-layout assumptions.

Alternative hosts therefore need a Macintosh-compatible logical runtime environment even though the underlying machine differs.

Where assumptions can be reproduced safely, LibreROM may provide them. Where an application directly depends on incompatible physical hardware mappings, the compatibility level drops and additional emulation may be necessary.

A baseline 68000 host has no MMU capable of transparently remapping arbitrary hardware accesses. This is an important architectural limit: direct hardware dependencies cannot generally be intercepted merely because both machines use 68k CPUs.

## Compatibility classes

### L0 — Toolbox-clean applications

Applications using supported documented Toolbox/OS services with no relevant hardware assumptions.

Expected path: native application execution.

### L1 — normal GUI applications

Applications relying on QuickDraw, Events, Windows, Menus, Resources and File Manager behavior within LibreROM's qualified surface.

Expected path: native execution plus translated host services.

### L2 — low-memory/runtime assumptions

Applications using conventional Macintosh low-memory globals or machine state that LibreROM can safely reproduce.

Expected path: native execution with compatibility environment.

### L3 — selected ROM/hardware dependencies

Software with narrowly scoped machine assumptions that can be shimmed or translated.

Expected path: hybrid native execution plus compatibility shims.

### L4 — hardware-coupled software

Software directly dependent on Macintosh hardware addresses, timing or undocumented ROM implementation behavior.

Expected path: partial or full Macintosh hardware emulation.

### L5 — specialized late-68k environments

Software requiring particular MMU/FPU/accelerator or machine-specific facilities beyond the current host abstraction.

Expected path: later research.

## Host extensions

LibreROM may eventually expose optional host capabilities to software specifically written for LibreROM, but these must not alter the behavior expected by ordinary Macintosh applications.

Possible Amiga capability groups include:

```text
LIBREROM_HOST_AMIGA
LIBREROM_AMIGA_BLITTER
LIBREROM_AMIGA_COPPER
LIBREROM_AMIGA_SPRITES
LIBREROM_AMIGA_PAULA
LIBREROM_AMIGA_AGA
```

Equivalent Atari capabilities may be defined later.

The exact API/ABI remains intentionally unspecified until the portable runtime architecture exists.

## Qualification strategy

Alternative-host claims must remain evidence-based.

A host profile should record at least:

- host machine class,
- CPU generation,
- RAM assumptions,
- display backend,
- LibreROM build identity,
- implemented Toolbox surface,
- tested application requirements,
- whether execution was native, shimmed or emulated.

Regression tests should reuse the Macintosh-side Toolbox tests wherever possible so that the same software-visible behavior is checked across backends.

## Demonstration targets

Incremental demonstrations should avoid jumping immediately to complicated commercial applications.

Suggested progression:

1. LibreROM-authored A-trap/Toolbox diagnostic application.
2. Simple QuickDraw/event-loop application.
3. Resource-based GUI application.
4. Cleanly behaving real-world classic Macintosh application.
5. Historically interesting applications such as MacPaint or MacWrite if their compatibility requirements and lawful test setup permit it.

A long-term showcase would be a classic Macintosh GUI application running as native 68k code on an Amiga with QuickDraw operations accelerated by Amiga hardware, while no Apple ROM image is present.

## Non-goals for the first alternative host

The first implementation does not need to:

- reproduce every Macintosh hardware register,
- run arbitrary copy-protected or hardware-banging software,
- support every System version,
- emulate a 68040 on a 68000,
- expose host custom chips directly to ordinary Macintosh software,
- replace full Macintosh emulators for programs that genuinely require full machine emulation.

The first goal is narrower and testable: **prove that Macintosh 68k application code can execute natively on another 68k machine while LibreROM supplies the Macintosh software environment.**
