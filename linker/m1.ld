OUTPUT_FORMAT("elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(_reset)

MEMORY
{
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
    . = ORIGIN(ROM);

    .vectors :
    {
        KEEP(*(.vectors))
    } > ROM

    ASSERT(SIZEOF(.vectors) == 8, "M1 vector table must contain exactly SSP and reset PC")

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

    _rom_used_end = .;
    ASSERT(_rom_used_end <= ORIGIN(ROM) + LENGTH(ROM), "LibreROM M1 exceeds 64 KiB ROM")
}
