OUTPUT_FORMAT("elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(_m2_13_reset)

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
  ASSERT(SIZEOF(.vectors) == 8, "M2.13 reset vector table must be exactly 8 bytes")

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

  ASSERT(. <= ORIGIN(ROM) + LENGTH(ROM), "M2.13 ROM exceeds 128 KiB")
}
