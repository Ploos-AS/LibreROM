OUTPUT_FORMAT("elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(_m3_0_reset)

/* M3.0 is a deliberately machine-neutral core-service qualification ROM.
 * Platform integration remains covered by the cumulative M2 Mac Plus path.
 */
MEMORY
{
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
    .vectors 0x00000000 :
    {
        KEEP(*(.vectors))
    } > ROM

    .text :
    {
        *(.text*)
        *(.rodata*)
    } > ROM

    /DISCARD/ :
    {
        *(.comment*)
        *(.note*)
    }

    ASSERT(. <= ORIGIN(ROM) + LENGTH(ROM), "M3.0 ROM exceeds 64 KiB")
}
