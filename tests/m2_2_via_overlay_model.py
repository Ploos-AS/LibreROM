#!/usr/bin/env python3

ROM = bytearray([0x52, 0x4f, 0x4d, 0x21])
RAM = bytearray([0x52, 0x41, 0x4d, 0x21])
VIA_A4 = 0x10


def lowmem_read(overlay: bool, offset: int) -> int:
    return (ROM if overlay else RAM)[offset]


def main() -> int:
    via_port_a = VIA_A4
    overlay = bool(via_port_a & VIA_A4)

    assert lowmem_read(overlay, 0) == ord("R")
    assert bytes(ROM) == b"ROM!"

    # Firmware clears VIA A4 after reset-vector hand-off.
    via_port_a &= ~VIA_A4
    overlay = bool(via_port_a & VIA_A4)

    assert overlay is False
    assert bytes(RAM) == b"RAM!"
    assert lowmem_read(overlay, 1) == ord("A")

    print("LibreROM M2.2 VIA overlay model: PASS")
    print("reset_overlay=ROM")
    print("via_a4_after_disable=0")
    print("low_memory_after_disable=RAM")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
