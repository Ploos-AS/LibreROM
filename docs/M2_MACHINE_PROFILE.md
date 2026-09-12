# M2 machine profile — Macintosh Plus

M2 introduces the first machine-specific LibreROM target. The initial profile is the Macintosh Plus class using a Motorola 68000 CPU.

This document defines the compatibility boundary for bring-up. It is not a claim that LibreROM already implements the full machine.

## CPU and ROM

- CPU: Motorola 68000.
- ROM window: `0x400000`-`0x4fffff` in the classic early-Mac address map.
- Reset overlay: ROM is visible at address zero at reset so the CPU can fetch the initial SSP and PC vectors from ROM.
- M2 firmware image size target: 128 KiB.

## Initial RAM profile

- Qualification baseline: 1 MiB RAM.
- RAM is visible at low memory after the reset overlay is cleared.
- M2 must not assume MMU, FPU or post-68000 instructions.

## Peripheral map used for bring-up

The first profile models the classic Macintosh Plus device regions:

- NCR 5380 SCSI: `0x580000`-`0x5fffff`
- RAM mirror/alternate window: `0x600000`-`0x6fffff`
- Zilog 8530 SCC read: `0x800000`-`0x9fffff`
- Zilog 8530 SCC write: `0xa00000`-`0xbfffff`
- IWM floppy controller: `0xc00000`-`0xdfffff`
- 6522 VIA: `0xe80000`-`0xefffff`

Only the subset required by each M2 sub-milestone will be implemented.

## Display

The initial display target is the classic monochrome Macintosh framebuffer geometry:

- 512 × 342 pixels
- 1 bit per pixel

M2 does not require a full QuickDraw implementation. The immediate goal is direct framebuffer bring-up and an observable LibreROM diagnostic pattern/message.

## M2 sub-milestones

### M2.0 — profile and invariants

- Commit this machine profile.
- Add static checks for the target, ROM size and device map.
- Keep all machine-specific constants isolated under `platform/macplus`.

### M2.1 — reset overlay and RAM hand-off

- Build a 128 KiB ROM image.
- Start with ROM overlaid at address zero.
- Establish a valid supervisor stack in RAM.
- Clear/switch the overlay in the machine model and continue execution from the normal ROM mapping.
- Reach a deterministic halt/diagnostic state.

### M2.2 — exceptions

- Install a complete minimal 68000 vector table.
- Add safe default handlers for bus/address/illegal/trap/spurious exceptions.
- Record exception state for emulator qualification.

### M2.3 — VIA and video

- Add the minimum VIA behavior needed by the profile.
- Establish framebuffer location/geometry.
- Draw a project-authored LibreROM diagnostic pattern or banner without Toolbox/QuickDraw.

### M2.4 — input/timing baseline

- Minimal keyboard/mouse/timing path sufficient for later firmware work.
- Keep SCC/IWM/SCSI outside the gate unless required by the qualification harness.

## M2 exit criterion

A freely redistributable LibreROM image must boot in a reproducible Macintosh Plus-class emulator profile, perform reset-overlay/RAM bring-up, install safe exception handling, initialize the minimal VIA/video path, and render a deterministic diagnostic framebuffer without an Apple ROM.

Storage boot and Toolbox compatibility belong to later milestones.
