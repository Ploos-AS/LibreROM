#!/usr/bin/env python3
from dataclasses import dataclass

ROM_BASE = 0x00400000
ROM_SIZE = 0x00020000
RAM_SIZE = 1024 * 1024
LOW_BASE = 0x00000000

ROM_SSP = 0x00010000
ROM_PC = 0x00400008


@dataclass
class MacPlusOverlayModel:
    overlay_active: bool = True

    def __post_init__(self) -> None:
        self.rom = bytearray([0xFF] * ROM_SIZE)
        self.ram = bytearray([0x00] * RAM_SIZE)
        self.rom[0:4] = ROM_SSP.to_bytes(4, "big")
        self.rom[4:8] = ROM_PC.to_bytes(4, "big")

    def read_low_u32(self, address: int) -> int:
        assert LOW_BASE <= address <= 4
        backing = self.rom if self.overlay_active else self.ram
        return int.from_bytes(backing[address:address + 4], "big")

    def copy_reset_vectors_to_ram(self) -> None:
        self.ram[0:8] = self.rom[0:8]

    def disable_overlay(self) -> None:
        self.overlay_active = False


def main() -> int:
    m = MacPlusOverlayModel()

    assert m.overlay_active
    assert m.read_low_u32(0) == ROM_SSP
    assert m.read_low_u32(4) == ROM_PC

    m.copy_reset_vectors_to_ram()
    assert m.ram[0:8] == m.rom[0:8]

    m.disable_overlay()
    assert not m.overlay_active
    assert m.read_low_u32(0) == ROM_SSP
    assert m.read_low_u32(4) == ROM_PC

    print("PASS: LibreROM M2.1 reset overlay and RAM hand-off model")
    print(f"ROM_BASE=0x{ROM_BASE:08x}")
    print(f"ROM_SSP=0x{ROM_SSP:08x}")
    print(f"ROM_PC=0x{ROM_PC:08x}")
    print("POST_OVERLAY_LOW_MEMORY=RAM")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
