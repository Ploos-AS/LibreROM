# LibreROM roadmap

LibreROM is developed in two deliberate phases:

1. **Macintosh first** — implement and qualify a free clean-room ROM/runtime across representative classic 68k Macintosh families.
2. **Alternative 68k hosts later** — after the Macintosh compatibility foundation converges, explore native execution of compatible Macintosh 68k software on other Motorola 68k platforms such as Amiga and Atari.

The alternative-host work is therefore a later portability/compatibility track, not a shortcut around Macintosh hardware and Toolbox compatibility.

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

## M2 — First Macintosh machine bring-up

- RAM discovery/basic initialization.
- Minimal exception handling.
- Basic VIA/video/input bring-up for the first selected Macintosh-class target.
- Reproducible emulator qualification.

The first concrete machine profile should remain conservative and 68000-based.

## M3 — Core ROM and Toolbox services

- Implement the minimum set of ROM/trap-facing services needed by the first software boot target.
- Establish clean-room A-trap dispatch infrastructure.
- Begin behavioral coverage for core managers such as memory, events, resources and QuickDraw where required by the selected target.
- Add behavioral conformance tests.

## M4 — Macintosh boot path

- Storage/device discovery required for boot.
- Load and transfer control to a compatible operating-system environment or project-authored diagnostic payload.
- Define the first reproducible Macintosh software boot profile.

## M5 — Early compact Macintosh family

Goal: establish a qualified baseline for early 68000 compact Macintosh systems.

Representative targets:

- Macintosh 128K / 512K class where practical
- Macintosh Plus
- Macintosh SE
- Macintosh Classic-class systems where architecture overlaps sufficiently

Planned scope:

- 68000 execution
- low-memory/global environment required by compatible software
- VIA/input/timer behavior
- framebuffer/QuickDraw path
- floppy/SCSI progression as required by machine profile
- ROM/Toolbox trap compatibility matrix
- reproducible emulator qualification

Compatibility claims remain machine-profile-specific.

## M6 — Macintosh II family

Goal: expand LibreROM into modular/color 68k Macintosh systems.

Representative targets:

- Macintosh II
- Macintosh IIx / IIcx-class systems as appropriate
- Macintosh IIci as a major 68030 convergence target

Planned scope:

- 68020/68030 execution profiles
- Slot Manager / expansion-facing behavior where required
- color QuickDraw progression
- broader memory-management behavior
- machine-specific interrupt, video and storage support
- regression against the compact-Mac baseline

## M7 — 68030/68040 Macintosh expansion

Goal: broaden compatibility toward later classic 68k Macintosh hardware.

Representative targets may include:

- later II-family systems
- SE/30
- LC-class systems
- Quadra-class 68040 systems

Planned scope:

- 68030/68040-specific startup and exception behavior
- MMU/cache/FPU-aware qualification where relevant
- additional video/storage/platform controllers
- broader Toolbox and ROM service coverage
- regression across earlier machine profiles

Exact machine ordering may be refined according to documentation quality and clean-room feasibility.

## M8 — Macintosh 68k family convergence

Goal: turn individual machine ports into one coherent LibreROM Macintosh platform family.

Exit criteria:

- shared machine/profile schema
- representative 68000, 68020/68030 and 68040 profiles
- common ROM/Toolbox behavioral regression suite
- documented A-trap coverage matrix
- QuickDraw compatibility baseline
- documented low-memory/global compatibility assumptions
- documented storage/input/video qualification boundaries
- no regression of earlier qualified profiles when later machine support lands

**Gate:** M8 is the planned prerequisite for beginning alternative 68k-host implementations.

## M9 — Portable LibreROM runtime architecture

Goal: separate Macintosh software-facing semantics from concrete Macintosh hardware sufficiently to permit additional 68k machine backends.

Conceptual layering:

```text
Macintosh 68k application/runtime
            |
       Toolbox traps
 QuickDraw / Memory / Resource
 Event / Window / Menu / File
            |
          LibreROM
            |
       platform backend
            |
 Macintosh / Amiga / Atari / VM
```

Planned work:

- isolate CPU-generic 68k runtime code
- isolate Toolbox/ROM service implementations
- define machine backend interfaces
- preserve Macintosh behavior at the software-facing boundary
- define capability discovery for non-Macintosh backends

This milestone does not by itself claim that arbitrary Macintosh software can run on arbitrary 68k hardware.

## M10 — Amiga native host

Goal: execute suitable classic Macintosh 68k software directly on compatible Amiga CPUs using LibreROM services instead of Apple ROM code or 68k CPU emulation.

Initial direction:

- 68000/68020/68030 native execution according to host CPU
- Amiga startup/platform backend
- Amiga memory and interrupt adaptation
- keyboard/mouse/timer/storage adaptation
- QuickDraw rendering backed by Amiga graphics hardware
- Blitter acceleration where semantically safe
- later OCS/ECS/AGA capability profiles

A major demonstration target is a simple classic Macintosh application such as a clean-room test application, and eventually real compatible software, running through LibreROM on an Amiga without an Apple ROM image.

See `docs/ALTERNATIVE_68K_HOSTS.md`.

## M11 — Atari native host

Goal: provide the same LibreROM software-facing environment on suitable Atari 68k hardware.

Initial direction:

- ST/STE/TT/Falcon host profiles as practical
- native 68k application execution where CPU requirements match
- Atari input/timer/storage adaptation
- QuickDraw backend mapped to Atari video facilities
- later acceleration through platform-specific facilities where useful

The Atari backend should reuse platform knowledge from the wider Ploos AS Atari ecosystem but remain architecturally separate from LibreTOS: LibreROM implements Macintosh semantics, while LibreTOS implements TOS semantics.

## M12 — Alternative-host Macintosh compatibility

Goal: move beyond simple API-level demonstrations and define explicit compatibility classes for Macintosh software running on non-Macintosh 68k hardware.

Proposed classes:

- **L0** — applications using well-defined Toolbox services only
- **L1** — ordinary QuickDraw/Event/Window/Menu/File/Resource usage
- **L2** — applications with documented low-memory/global assumptions that LibreROM can reproduce
- **L3** — applications depending on selected Macintosh ROM internals or hardware behavior that can be shimmed
- **L4** — software tightly coupled to Macintosh hardware, timing or undocumented ROM behavior and therefore requiring hybrid emulation
- **L5** — accelerator/FPU/MMU/specialized-machine-dependent software requiring later research

The baseline principle is the same throughout: **execute 68k application instructions natively whenever the host CPU can do so, and emulate only the machine behavior that actually requires emulation.**

## Long-term direction

LibreROM remains a Macintosh-compatible clean-room firmware/runtime project first.

The later alternative-host work explores a broader idea: whether classic Macintosh software can be decoupled from Apple ROM binaries and from a specific Macintosh motherboard while preserving the Toolbox programming model.

The intended ordering is:

**early compact Macintosh → Macintosh II family → later 68030/68040 Macs → Macintosh family convergence → portable LibreROM runtime → Amiga → Atari.**

Milestone boundaries may be refined as hardware research and compatibility testing progress.
