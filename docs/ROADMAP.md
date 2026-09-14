# LibreROM roadmap

LibreROM is developed in two deliberate phases:

1. **Macintosh first** — implement and qualify a free clean-room ROM/runtime across representative classic 68k Macintosh families.
2. **Alternative 68k hosts later** — after the Macintosh compatibility foundation converges, explore native execution of compatible Macintosh 68k software on other Motorola 68k platforms such as Amiga and Atari.

The alternative-host work is therefore a later portability/compatibility track, not a shortcut around Macintosh hardware and Toolbox compatibility.

## Permanent per-model variant policy

LibreROM keeps distinct, buildable ROM variants for the Macintosh models it qualifies, following the same preservation principle as LibreTOS. A newer Macintosh target does **not** replace an older one.

Each supported Mac model must retain a dedicated machine profile, model-specific ROM artifact, documented compatibility boundary and regression qualification. Generic Toolbox/runtime code may be shared, while hardware-visible differences remain in model backends. Long-term releases therefore contain a family of LibreROM images rather than one universal ROM.

The current Macintosh Plus work becomes the first retained model variant. As Macintosh 128K/512K, SE, Classic, II-family, SE/30, LC and Quadra targets are introduced, their variants remain available and are tested alongside later machines.

See `docs/MAC_MODEL_VARIANTS.md` for the model matrix, naming policy and source-layout direction.

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

The first concrete machine profile should remain conservative and 68000-based. The Macintosh Plus baseline established here is retained as its own LibreROM variant when later machine profiles are added.

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

Goal: establish a qualified baseline for early 68000 compact Macintosh systems while preserving each qualified model as a separate LibreROM variant.

Representative targets:

- Macintosh 128K
- Macintosh 512K
- Macintosh Plus
- Macintosh SE
- Macintosh Classic-class systems where architecture overlaps sufficiently

Planned scope:

- dedicated machine profile and ROM artifact for every qualified model
- 68000 execution
- low-memory/global environment required by compatible software
- VIA/input/timer behavior
- framebuffer/QuickDraw path
- floppy/SCSI progression as required by machine profile
- ROM/Toolbox trap compatibility matrix
- reproducible emulator qualification
- cross-model regression so adding one compact Mac does not regress previously qualified variants

Compatibility claims remain machine-profile-specific.

## M6 — Macintosh II family

Goal: expand LibreROM into modular/color 68k Macintosh systems without replacing the compact-Mac ROM variants.

Representative targets:

- Macintosh II
- Macintosh IIx
- Macintosh IIcx
- Macintosh IIci as a major 68030 convergence target

Planned scope:

- dedicated retained variant for each qualified II-family model
- 68020/68030 execution profiles
- Slot Manager / expansion-facing behavior where required
- color QuickDraw progression
- broader memory-management behavior
- machine-specific interrupt, video and storage support
- regression against every retained compact-Mac baseline

## M7 — 68030/68040 Macintosh expansion

Goal: broaden compatibility toward later classic 68k Macintosh hardware while keeping earlier model ROMs buildable and qualified.

Representative targets may include:

- later II-family systems
- SE/30
- concrete LC models
- concrete Quadra 68040 models

Planned scope:

- dedicated retained variant for each qualified model
- 68030/68040-specific startup and exception behavior
- MMU/cache/FPU-aware qualification where relevant
- additional video/storage/platform controllers
- broader Toolbox and ROM service coverage
- regression across all earlier retained machine profiles

Family names such as `LC` or `Quadra` may be used during research, but qualification must ultimately identify concrete machine models. Exact machine ordering may be refined according to documentation quality and clean-room feasibility.

## M8 — Macintosh 68k family convergence

Goal: turn individual machine ports into one coherent LibreROM Macintosh platform family **without collapsing the preserved model variants**.

Exit criteria:

- shared machine/profile schema
- separately buildable ROM artifact for every retained qualified Macintosh model
- representative 68000, 68020/68030 and 68040 profiles
- common ROM/Toolbox behavioral regression suite
- documented A-trap coverage matrix
- QuickDraw compatibility baseline
- documented low-memory/global compatibility assumptions
- documented storage/input/video qualification boundaries
- CI matrix covering retained model variants
- no regression or silent removal of earlier qualified profiles when later machine support lands

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
- preserve all qualified Macintosh model profiles as first-class backends
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

Throughout that progression, every qualified Macintosh model remains a preserved LibreROM build target.

Milestone boundaries may be refined as hardware research and compatibility testing progress.
