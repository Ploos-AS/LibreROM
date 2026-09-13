OUTPUT_FORMAT("elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(_m2_6_reset)

MEMORY
{
    ROM (rx) : ORIGIN = 0x00400000, LENGTH = 128K
}

SECTIONS
{
    . = ORIGIN(ROM);

    .vectors :
    {
        KEEP(*(.vectors))
    } > ROM

    ASSERT(SIZEOF(.vectors) == 8, "M2.6 reset vector pair must be 8 bytes")

    .text :
    {
        *(.text*)
    } > ROM

    .rodata :
    {
        *(.rodata*)
    } > ROM

    /DISCARD/ :
    {
        *(.comment*)
        *(.note*)
    }

    _m2_6_rom_used_end = .;
    ASSERT(_m2_6_rom_used_end <= ORIGIN(ROM) + LENGTH(ROM), "LibreROM M2.6 exceeds 128 KiB ROM")
}
