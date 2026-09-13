#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "m68k.h"

#define ROM_BASE 0x00400000u
#define ROM_SIZE 131072u
#define RAM_SIZE (1024u * 1024u)
#define RAM_ALT_BASE 0x00600000u
#define VIA_ORA  0x00efe200u
#define VIA_DDRA 0x00efe600u
#define OVERLAY_BIT 0x10u

#define M300_ADDR 0x00000400u
#define OK30_ADDR 0x00000404u
#define PR30_ADDR 0x00000408u
#define DSP0_ADDR 0x0000040cu
#define BAD0_ADDR 0x00000410u
#define EXC0_ADDR 0x00000414u

#define M300_VALUE 0x4d333030u
#define OK30_VALUE 0x4f4b3330u
#define PR30_VALUE 0x50523330u
#define DSP0_VALUE 0x44535030u
#define BAD0_VALUE 0x42414430u

static uint8_t rom[ROM_SIZE];
static uint8_t ram[RAM_SIZE];
static uint8_t via_ora = OVERLAY_BIT;
static uint8_t via_ddra;
static int overlay = 1;
static int vectors_ready_before_overlay_off;

static uint32_t ram32(uint32_t address)
{
    return ((uint32_t)ram[address] << 24) |
           ((uint32_t)ram[address + 1] << 16) |
           ((uint32_t)ram[address + 2] << 8) |
           (uint32_t)ram[address + 3];
}

static uint8_t read8(uint32_t address)
{
    if (address == VIA_ORA)
        return via_ora;
    if (address == VIA_DDRA)
        return via_ddra;
    if (address >= ROM_BASE && address < ROM_BASE + ROM_SIZE)
        return rom[address - ROM_BASE];
    if (address >= RAM_ALT_BASE && address < RAM_ALT_BASE + RAM_SIZE)
        return ram[address - RAM_ALT_BASE];
    if (overlay && address < ROM_SIZE)
        return rom[address];
    if (!overlay && address < RAM_SIZE)
        return ram[address];
    return 0xff;
}

static void write8(uint32_t address, uint8_t value)
{
    if (address == VIA_DDRA) {
        via_ddra = value;
        return;
    }
    if (address == VIA_ORA) {
        if (overlay && (value & OVERLAY_BIT) == 0) {
            uint32_t reset_pc = ram32(4);
            uint32_t aline = ram32(10u * 4u);
            vectors_ready_before_overlay_off =
                ram32(0) == RAM_SIZE &&
                reset_pc >= ROM_BASE && reset_pc < ROM_BASE + ROM_SIZE &&
                aline >= ROM_BASE && aline < ROM_BASE + ROM_SIZE &&
                ram32(PR30_ADDR) == PR30_VALUE;
        }
        via_ora = value;
        overlay = (value & OVERLAY_BIT) != 0;
        return;
    }
    if (address >= RAM_ALT_BASE && address < RAM_ALT_BASE + RAM_SIZE) {
        ram[address - RAM_ALT_BASE] = value;
        return;
    }
    if (!overlay && address < RAM_SIZE)
        ram[address] = value;
}

unsigned int m68k_read_memory_8(unsigned int address) { return read8(address); }
unsigned int m68k_read_memory_16(unsigned int address)
{
    return ((unsigned int)read8(address) << 8) | read8(address + 1);
}
unsigned int m68k_read_memory_32(unsigned int address)
{
    return (m68k_read_memory_16(address) << 16) | m68k_read_memory_16(address + 2);
}
void m68k_write_memory_8(unsigned int address, unsigned int value)
{
    write8(address, (uint8_t)value);
}
void m68k_write_memory_16(unsigned int address, unsigned int value)
{
    write8(address, (uint8_t)(value >> 8));
    write8(address + 1, (uint8_t)value);
}
void m68k_write_memory_32(unsigned int address, unsigned int value)
{
    m68k_write_memory_16(address, value >> 16);
    m68k_write_memory_16(address + 2, value);
}

static int load_rom(const char *path)
{
    FILE *fp = fopen(path, "rb");
    size_t got;
    if (!fp) {
        perror(path);
        return 1;
    }
    got = fread(rom, 1, sizeof(rom), fp);
    if (got != sizeof(rom) || fgetc(fp) != EOF) {
        fprintf(stderr, "M3.0 runtime FAIL: ROM must be exactly %u bytes (got %zu)\n", ROM_SIZE, got);
        fclose(fp);
        return 1;
    }
    fclose(fp);
    return 0;
}

int main(int argc, char **argv)
{
    unsigned total_cycles = 0;
    unsigned pc;
    uint32_t aline_vector;

    if (argc != 2) {
        fprintf(stderr, "usage: %s <librom-m3.0-macplus.bin>\n", argv[0]);
        return 2;
    }
    if (load_rom(argv[1]))
        return 1;

    m68k_init();
    m68k_set_cpu_type(M68K_CPU_TYPE_68000);
    m68k_pulse_reset();

    while (total_cycles < 500000u && ram32(OK30_ADDR) != OK30_VALUE) {
        int ran = m68k_execute(64);
        if (ran < 0)
            ran = 0;
        total_cycles += (unsigned)(ran ? ran : 64);
    }

    pc = m68k_get_reg(NULL, M68K_REG_PC);
    aline_vector = ram32(10u * 4u);

    printf("LibreROM M3.0 runtime evidence\n");
    printf("cpu=MC68000\ncycles=%u\npc=%08x\n", total_cycles, pc);
    printf("overlay=%d via_ddra=%02x via_ora=%02x\n", overlay, via_ddra, via_ora);
    printf("vectors_ready_before_overlay_off=%d\n", vectors_ready_before_overlay_off);
    printf("ram_vector10_aline=%08x\n", aline_vector);
    printf("markers=%08x/%08x/%08x/%08x/%08x/%08x\n",
           ram32(M300_ADDR), ram32(OK30_ADDR), ram32(PR30_ADDR),
           ram32(DSP0_ADDR), ram32(BAD0_ADDR), ram32(EXC0_ADDR));

    if (!vectors_ready_before_overlay_off) {
        fprintf(stderr, "M3.0 runtime FAIL: A-line vector was not installed before overlay-off\n");
        return 1;
    }
    if (overlay || (via_ddra & OVERLAY_BIT) == 0 || (via_ora & OVERLAY_BIT) != 0) {
        fprintf(stderr, "M3.0 runtime FAIL: overlay state incorrect\n");
        return 1;
    }
    if (aline_vector < ROM_BASE || aline_vector >= ROM_BASE + ROM_SIZE) {
        fprintf(stderr, "M3.0 runtime FAIL: A-line vector invalid\n");
        return 1;
    }
    if (ram32(M300_ADDR) != M300_VALUE || ram32(PR30_ADDR) != PR30_VALUE ||
        ram32(DSP0_ADDR) != DSP0_VALUE || ram32(OK30_ADDR) != OK30_VALUE) {
        fprintf(stderr, "M3.0 runtime FAIL: dispatch markers missing\n");
        return 1;
    }
    if (ram32(BAD0_ADDR) == BAD0_VALUE) {
        fprintf(stderr, "M3.0 runtime FAIL: private diagnostic trap was rejected\n");
        return 1;
    }
    if (pc < ROM_BASE || pc >= ROM_BASE + ROM_SIZE) {
        fprintf(stderr, "M3.0 runtime FAIL: execution left ROM window\n");
        return 1;
    }

    puts("LibreROM M3.0 runtime qualification: PASS");
    return 0;
}
