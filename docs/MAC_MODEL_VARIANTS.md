# LibreROM Macintosh model variants

LibreROM follows the same preservation principle used by LibreTOS: support for a new machine does not replace an older target. Each qualified Macintosh model keeps its own explicit build/profile and remains part of regression testing.

## Policy

For every Macintosh model promoted to a supported LibreROM target:

- keep a dedicated machine profile in the repository;
- produce a separately named ROM artifact for that model;
- preserve model-specific startup, memory map, interrupt, video, storage and peripheral behavior;
- share generic Toolbox/runtime code where behavior is genuinely common;
- do not collapse different machines into one generic ROM when hardware-visible behavior differs;
- keep previously qualified model variants buildable when later models are added;
- run regression qualification for every retained supported model in CI as practical;
- publish compatibility claims per model, not only per CPU family.

This means Macintosh Plus remains a first-class target after Macintosh SE support lands; SE remains first-class after IIci support lands; and so on.

LibreROM has an explicit **high-performance coverage rule**: for important 68030 and 68040 Macintosh desktop/workstation models, the default is to add and retain the concrete model rather than treat one machine as representative of an entire family. A high-end model may be deferred when clean-room documentation, emulator support or qualification evidence is insufficient, but it should not be omitted merely because a similar CPU appears in another supported Mac.

## Naming

Canonical artifact names should identify the concrete machine, for example:

- `librerom-mac128k.bin`
- `librerom-mac512k.bin`
- `librerom-macplus.bin`
- `librerom-macse.bin`
- `librerom-macclassic.bin`
- `librerom-macii.bin`
- `librerom-maciix.bin`
- `librerom-maciicx.bin`
- `librerom-maciici.bin`
- `librerom-maciisi.bin`
- `librerom-maciifx.bin`
- `librerom-macse30.bin`
- `librerom-quadra700.bin`
- `librerom-quadra900.bin`
- `librerom-quadra950.bin`
- `librerom-quadra610.bin`
- `librerom-quadra650.bin`
- `librerom-quadra800.bin`
- `librerom-quadra840av.bin`
- `librerom-centris610.bin`
- `librerom-centris650.bin`

Family-level artifact names such as `librerom-quadra.bin` or `librerom-maclc.bin` are acceptable only as temporary development names. Qualified targets use concrete model names.

Milestone/debug ROMs may continue to use milestone suffixes during development, but a model becomes a retained target only when it has a canonical machine profile and stable model-specific artifact name.

## Model matrix

| Model | CPU baseline | Track | Coverage policy | Status |
| --- | --- | --- | --- | --- |
| Macintosh 128K | 68000 | M5 compact Mac | primary | planned |
| Macintosh 512K / 512Ke | 68000 | M5 compact Mac | primary | planned |
| Macintosh Plus | 68000 | M2-M5 | primary | active baseline |
| Macintosh SE | 68000 | M5 compact Mac | primary | planned |
| Macintosh Classic | 68000 | M5 compact Mac | primary | planned |
| Macintosh Classic II | 68030 | M5/M6 transition | useful distinct target | planned |
| Macintosh II | 68020 | M6 | primary | planned |
| Macintosh IIx | 68030 | M6 | primary | planned |
| Macintosh IIcx | 68030 | M6 | primary | planned |
| Macintosh IIci | 68030 | M6 | high-performance priority | planned |
| Macintosh IIsi | 68030 | M6 | primary | planned |
| Macintosh IIfx | 68030 | M6 | high-performance priority | planned |
| Macintosh SE/30 | 68030 | M6 | high-performance priority | planned |
| Quadra 700 | 68040 | M7 | high-performance priority | planned |
| Quadra 900 | 68040 | M7 | high-performance priority | planned |
| Quadra 950 | 68040 | M7 | high-performance priority | planned |
| Quadra 610 | 68040 | M7 | high-performance priority | planned |
| Quadra 650 | 68040 | M7 | high-performance priority | planned |
| Quadra 800 | 68040 | M7 | high-performance priority | planned |
| Quadra 840AV | 68040 | M7 | high-performance priority / AV-specialized | planned |
| Centris 610 | 68LC040 | M7 | high-performance-family breadth | planned |
| Centris 650 | 68040/68LC040 variants | M7 | high-performance-family breadth | planned |
| Other 68k Quadra/Centris models | 68040/68LC040 | M7 | include when materially distinct and qualifiable | planned research |
| Macintosh LC models | 68020/68030/68040 depending on model | M7B | concrete hardware-distinct subset | planned research |
| Performa 68k models | varies | M7B | avoid duplicate rebadges unless hardware differs | planned research |
| Macintosh Portable | 68000 | M7B | portable architecture target | planned |
| 68k PowerBook models | 68030/68040 depending on model | M7B | representative hardware-distinct subset | planned research |

The matrix is intentionally expandable. For high-performance 68030/68040 systems it should tend toward broad or near-comprehensive coverage. For large rebadged consumer families such as Performa, distinct hardware platforms matter more than marketing model count.

## Source layout direction

Machine-specific code should converge toward a layout such as:

```text
src/platform/mac/
  common/
  mac128k/
  mac512k/
  macplus/
  macse/
  macclassic/
  macii/
  maciix/
  maciicx/
  maciici/
  maciisi/
  maciifx/
  macse30/
  quadra700/
  quadra900/
  quadra950/
  quadra610/
  quadra650/
  quadra800/
  quadra840av/
  centris610/
  centris650/
  ...
```

Common code is shared only when the observable Macintosh behavior is common. Machine backends own the differences.

## Qualification tiers

A model can progress through explicit support tiers:

1. **researched** — machine map and clean-room source set identified;
2. **buildable** — dedicated profile and ROM artifact exist;
3. **runtime-qualified** — deterministic emulator qualification passes;
4. **retained** — model is part of normal regression and release policy.

No model should be advertised as supported merely because it can share a generated image with another profile.

## CI and release rule

Once a model reaches qualified status, later work must not silently drop it. A release should either:

1. build and qualify that model variant, or
2. explicitly document why that model is temporarily excluded.

Long-term releases should therefore contain a family of LibreROM images rather than one universal `LibreROM.bin`.

For the high-performance 68030/68040 group, CI should eventually use a model matrix so IIfx, IIci, SE/30 and the retained Quadra/Centris variants remain independently visible rather than collapsing to a single family job.

This policy applies independently of later M9-M12 Amiga/Atari portability work. Macintosh model variants remain preserved even after LibreROM gains non-Macintosh hosts.
