# M3.0 — clean-room A-line dispatch foundation

M3.0 begins LibreROM's core ROM/Toolbox-service phase with a deliberately narrow mechanism: a project-owned 68000 Line-A dispatch path on the Macintosh Plus profile.

## Scope

The qualification image:

- keeps the qualified Macintosh Plus reset-overlay model,
- installs a complete RAM vector table before overlay removal,
- installs `_m3_0_aline` at 68000 vector 10 (`0x28`),
- executes the LibreROM-private synthetic opcode `0xA0F0`,
- validates the faulting opcode in the exception handler,
- advances the stacked return PC by one 68000 word,
- returns through `RTE`,
- returns the project-owned diagnostic result `LR30`, and
- records deterministic RAM markers proving dispatch and successful return.

`0xA0F0` is only a LibreROM qualification service. M3.0 does **not** claim compatibility with an Apple Toolbox trap or any specific historical ROM implementation.

## Clean-room boundary

No Apple ROM image, ROM disassembly, leaked source, System software, copied trap table, or derived proprietary fixture is used. The milestone qualifies generic Motorola 68000 Line-A exception mechanics and project-authored firmware behavior only.

## Qualification

Run:

```sh
CROSS=m68k-linux-gnu- bash scripts/qualify_m3_0.sh
```

Static qualification checks the vector-10 installation, private opcode, stacked-PC advancement, dispatcher markers, ROM layout and project marker.

Runtime qualification uses pinned Musashi commit `313ebf1bd9f4d0d93341eb5ce21fd8a119e9dbdd` and requires:

- vector 10 installed in RAM before overlay-off,
- overlay hand-off completed,
- `M300`, `PR30`, `DSP0`, and `OK30` markers present,
- no `BAD0` marker,
- execution remaining inside the M3.0 ROM window.

## Exit criterion

M3.0 passes when a real MC68000 runtime raises Line-A on the project-owned opcode, enters the LibreROM dispatcher through RAM vector 10, returns through `RTE`, and reaches post-trap firmware code with all invariants intact.

The next M3 step can build a table-driven private service dispatcher before adding any compatibility-facing trap semantics.
