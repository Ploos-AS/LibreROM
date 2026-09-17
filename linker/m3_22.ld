OUTPUT_FORMAT("elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(_m3_22_reset)
MEMORY { ROM (rx) : ORIGIN = 0x00400000, LENGTH = 128K }
SECTIONS {
  . = ORIGIN(ROM);
  .vectors : { KEEP(*(.vectors)) } > ROM
  ASSERT(SIZEOF(.vectors) == 8, "M3.22 reset vectors must be 8 bytes")
  .text : { *(.text*) } > ROM
  .rodata : { *(.rodata*) } > ROM
  /DISCARD/ : { *(.comment*) *(.note*) }
  ASSERT(. <= ORIGIN(ROM) + LENGTH(ROM), "M3.22 ROM exceeds 128 KiB")
}
