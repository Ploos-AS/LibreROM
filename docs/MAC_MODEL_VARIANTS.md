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
- `librerom-macse30.bin`
- `librerom-maclc.bin`
- `librerom-quadra.bin` only as a temporary family-level development name; qualified Quadra targets should ultimately use concrete model names.

Milestone/debug ROMs may continue to use milestone suffixes during development, but a model becomes a retained target only when it has a canonical machine profile and stable model-specific artifact name.

## Initial model matrix

| Model | CPU baseline | Track | Status |
| --- | --- | --- | --- |
| Macintosh 128K | 68000 | M5 compact Mac | planned |
| Macintosh 512K | 68000 | M5 compact Mac | planned |
| Macintosh Plus | 68000 | M2-M5 | active baseline |
| Macintosh SE | 68000 | M5 compact Mac | planned |
| Macintosh Classic | 68000 | M5 compact Mac | planned |
| Macintosh II | 68020 | M6 | planned |
| Macintosh IIx | 68030 | M6 | planned |
| Macintosh IIcx | 68030 | M6 | planned |
| Macintosh IIci | 68030 | M6 | planned convergence target |
| Macintosh SE/30 | 68030 | M7 | planned |
| Macintosh LC family | 68020/68030 depending on model | M7 | planned; split into concrete models before qualification |
| Quadra family | 68040 | M7 | planned; split into concrete models before qualification |

The matrix is intentionally expandable. Additional classic 68k Macintosh models may be added as documentation quality, emulator support and clean-room feasibility permit.

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
  macse30/
  ...
```

Common code is shared only when the observable Macintosh behavior is common. Machine backends own the differences.

## CI and release rule

Once a model reaches qualified status, later work must not silently drop it. A release should either:

1. build and qualify that model variant, or
2. explicitly document why that model is temporarily excluded.

Long-term releases should therefore contain a family of LibreROM images rather than one universal `LibreROM.bin`.

This policy applies independently of later M9-M12 Amiga/Atari portability work. Macintosh model variants remain preserved even after LibreROM gains non-Macintosh hosts.
