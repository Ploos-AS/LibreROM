# M3.1 — LibreROM private A-line service ABI

M3.1 turns the qualified M3.0 A-line exception path into a minimal service dispatcher with an explicit register ABI.

This milestone is still **LibreROM-private qualification infrastructure**. The opcodes below are not presented as Apple ROM or Macintosh Toolbox-compatible traps.

## Services

| Opcode | Name | Inputs | Output |
| --- | --- | --- | --- |
| `0xA0F0` | `LR_SVC_PING` | none | `D0 = 0x4c523331` (`LR31`) |
| `0xA0F1` | `LR_SVC_ADD` | `D0`, `D1` | `D0 = D0 + D1` |

The dispatcher uses `D2` and `A0` as scratch registers. The two M3.1 services otherwise leave the remaining registers untouched.

## Dispatch path

1. Macintosh Plus reset/overlay bring-up installs the 68000 Line-A exception handler in RAM vector 10 (`0x28`) before disabling the reset overlay.
2. A project-owned A-line opcode raises the line-1010 exception.
3. The handler reads the offending word from the stacked PC, advances the stacked PC by two bytes, and selects the service.
4. The service returns through `RTE`.
5. Firmware-side markers prove both services returned to their callers and produced the expected result.

The qualification sequence invokes `LR_SVC_PING`, checks `LR31`, then invokes `LR_SVC_ADD` with `D0=7` and `D1=5` and requires `D0=12` after `RTE`.

## Qualification

Run:

```sh
CROSS=m68k-linux-gnu- bash scripts/qualify_m3_1.sh
```

The driver performs static invariants, builds a 128 KiB Macintosh Plus ROM, and executes it under the pinned Musashi MC68000 runtime harness.

Required evidence includes:

- RAM vector 10 points into the physical ROM window;
- overlay hand-off occurred only after vectors were installed;
- `PNG1` proves service `0xA0F0` returned correctly;
- `ADD1` proves service `0xA0F1` returned `7 + 5 = 12` correctly;
- `DSP1` and `SVC1` prove both dispatcher branches executed;
- `OK31` is the final success marker;
- `BAD1` must remain absent.

## Clean-room boundary

All M3.1 opcodes, ABI choices, markers, tests, and source are project-authored. No Apple ROM image, disassembly, leaked source, or proprietary System software is used by this qualification.
