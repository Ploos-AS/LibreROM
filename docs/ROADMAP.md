# LibreROM roadmap

LibreROM is developed in two deliberate phases:

1. **Macintosh first** — implement and qualify a free clean-room ROM/runtime across a broad set of classic 68k Macintosh models.
2. **Alternative 68k hosts later** — after the Macintosh compatibility foundation converges, explore native execution of compatible Macintosh 68k software on other Motorola 68k platforms such as Amiga and Atari.

The alternative-host work is therefore a later portability/compatibility track, not a shortcut around Macintosh hardware and Toolbox compatibility.

## Macintosh coverage policy

LibreROM is not limited to one representative machine per CPU generation. The Macintosh phase aims to cover a substantial part of the 68k Macintosh family while preserving every qualified model as an independent build target.

Coverage priorities are:

1. establish the early compact-Mac baseline;
2. cover the important Macintosh II and 68030 transition machines;
3. pursue **near-comprehensive coverage of the high-performance 68030 and 68040 desktop/workstation models** where clean-room documentation and emulator qualification are practical;
4. cover representative LC/Performa and portable systems sufficiently to exercise their distinct platform behavior;
5. converge the retained variants into one shared LibreROM Macintosh platform family without collapsing model-specific behavior.

The high-performance track is intentionally broader than a representative sample. Machines such as SE/30, IIci, IIfx and the major Quadra systems are first-class targets, and additional high-end models should be added rather than omitted merely because another machine shares the same CPU generation.

## Permanent per-model variant policy

LibreROM keeps distinct, buildable ROM variants for the Macintosh models it qualifies, following the same preservation principle as LibreTOS. A newer Macintosh target does **not** replace an older one.

Each supported Mac model must retain a dedicated machine profile, model-specific ROM artifact, documented compatibility boundary and regression qualification. Generic Toolbox/runtime code may be shared, while hardware-visible differences remain in model backends. Long-term releases therefore contain a family of LibreROM images rather than one universal ROM.

The current Macintosh Plus work becomes the first retained model variant. As Macintosh 128K/512K, SE, Classic, II-family, SE/30, LC, Centris and Quadra targets are introduced, their variants remain available and are tested alongside later machines.

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

Goal: establish a qualified baseline for early compact Macintosh systems while preserving each qualified model as a separate LibreROM variant.

Primary targets:

- Macintosh 128K
- Macintosh 512K / 512Ke
- Macintosh Plus
- Macintosh SE
- Macintosh Classic
- Macintosh Classic II where its 68030 platform behavior fits the transition into later milestones

Planned scope:

- dedicated machine profile and ROM artifact for every qualified model
- 68000 execution for the early machines
- low-memory/global environment required by compatible software
- VIA/input/timer behavior
- framebuffer/QuickDraw path
- floppy/SCSI progression as required by machine profile
- ROM/Toolbox trap compatibility matrix
- reproducible emulator qualification
- cross-model regression so adding one compact Mac does not regress previously qualified variants

Compatibility claims remain machine-profile-specific.

## M6 — Macintosh II and 68030 performance family

Goal: expand LibreROM into modular/color Macintosh systems and establish a broad 68020/68030 desktop baseline, with especially strong coverage of performance-oriented machines.

Primary targets include:

- Macintosh II
- Macintosh IIx
- Macintosh IIcx
- Macintosh IIci
- Macintosh IIsi
- Macintosh IIfx
- Macintosh SE/30

Additional II-family 68k models should be added when they expose distinct hardware behavior and can be qualified cleanly.

Planned scope:

- dedicated retained variant for each qualified model
- 68020/68030 execution profiles
- 68881/68882/FPU-aware qualification where relevant
- MMU/cache behavior where relevant
- Slot Manager / NuBus-facing behavior
- color QuickDraw progression
- broader memory-management behavior
- machine-specific interrupt, video and storage support
- high-performance timing/controller differences where software-visible
- regression against every retained compact-Mac baseline

The IIfx, IIci and SE/30 are not interchangeable representatives; each is intended to remain an explicit supported target.

## M7 — High-performance 68040 Macintosh expansion

Goal: build broad coverage of the 68040 desktop/workstation generation, with a policy of attempting all important high-performance models rather than selecting only one representative Quadra.

Priority high-performance targets include:

- Quadra 700
- Quadra 900
- Quadra 950
- Quadra 610
- Quadra 650
- Quadra 800
- Quadra 840AV
- Centris 610
- Centris 650
- other 68k Quadra/Centris models where hardware differences warrant a retained variant

Planned scope:

- dedicated retained variant for each qualified model
- 68040-specific startup and exception behavior
- MMU/cache/FPU-aware qualification
- machine-specific memory controllers and interrupt plumbing
- NuBus/PDS-facing behavior where applicable
- additional video/storage/platform controllers
- broader Toolbox, Color QuickDraw and ROM service coverage
- AV-specific research for models such as Quadra 840AV without making unsupported compatibility claims
- regression across all earlier retained machine profiles

For this high-performance group, the default policy is **include unless there is a concrete clean-room, documentation or emulator limitation**, rather than selecting a small representative subset.

## M7B — LC, Performa and portable breadth

Goal: add enough lower-cost desktop and portable coverage to exercise materially different 68k Macintosh platform designs without requiring every marketing variant to become a separate target when hardware is effectively identical.

Candidate groups include:

- concrete Macintosh LC models
- selected Performa variants where hardware differs materially from an already-supported LC/desktop model
- Macintosh Portable
- representative 68k PowerBook models

Planned scope:

- split family names into concrete machine profiles before qualification
- prioritize hardware-distinct variants over rebadged configurations
- qualify portable power-management/input/storage differences where practical
- preserve every model once promoted to qualified status

## M8 — Macintosh 68k family convergence

Goal: turn individual machine ports into one coherent LibreROM Macintosh platform family **without collapsing the preserved model variants**.

Exit criteria:

- shared machine/profile schema
- separately buildable ROM artifact for every retained qualified Macintosh model
- broad 68000, 68020, 68030 and 68040 profile coverage
- near-comprehensive retained coverage of qualified high-performance 68030/68040 targets
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

**early compact Macintosh → broad Macintosh II/68030 coverage → high-performance 68040 coverage → LC/Performa/portable breadth → Macintosh family convergence → portable LibreROM runtime → Amiga → Atari.**

Throughout that progression, every qualified Macintosh model remains a preserved LibreROM build target.

Milestone boundaries may be refined as hardware research and compatibility testing progress.
