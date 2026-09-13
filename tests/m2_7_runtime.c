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
#define MARKER_ADDR 0x00000400u
#define EXC_ADDR 0x00000404u
#define PRE_ADDR 0x00000408u
#define VID_ADDR 0x0000040cu
#define MARKER_VALUE 0x4c524d37u
#define EXC_VALUE 0x45584337u
#define PRE_VALUE 0x50524537u
#define VID_VALUE 0x56494437u
#define RAM_TOP_PROBE 0x000ffffcu
#define MAIN_FB 0x000fa700u
#define ALT_FB 0x000f2700u
#define FB_BYTES 21888u

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
            uint32_t trap0 = ram32(32u * 4u);
            vectors_ready_before_overlay_off =
                ram32(0) == RAM_SIZE &&
                reset_pc >= ROM_BASE && reset_pc < ROM_BASE + ROM_SIZE &&
                trap0 >= ROM_BASE && trap0 < ROM_BASE + ROM_SIZE &&
                ram32(PRE_ADDR) == PRE_VALUE;
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
    return ((unsigned int)read8(address) << 8) | (unsigned int)read8(address + 1);
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
        fprintf(stderr, "M2.7 runtime FAIL: ROM must be exactly %u bytes (got %zu)\n", ROM_SIZE, got);
        fclose(fp);
        return 1;
    }
    fclose(fp);
    return 0;
}

static int framebuffer_ok(uint32_t base)
{
    uint32_t i;
    for (i = 0; i < FB_BYTES; ++i) {
        uint8_t expected = (i & 1u) ? 0x55u : 0xaau;
        if (ram[base + i] != expected)
            return 0;
    }
    return 1;
}

int main(int argc, char **argv)
{
    unsigned int pc, sp, sr;
    uint32_t reset_pc, default_vector;
    int cycles;

    if (argc != 2) {
        fprintf(stderr, "usage: %s <librom-m2.7-macplus.bin>\n", argv[0]);
        return 2;
    }
    if (load_rom(argv[1]))
        return 1;

    m68k_init();
    m68k_set_cpu_type(M68K_CPU_TYPE_68000);
    m68k_pulse_reset();

    sp = m68k_get_reg(NULL, M68K_REG_SP);
    pc = m68k_get_reg(NULL, M68K_REG_PC);
    if (sp != RAM_SIZE || pc < ROM_BASE || pc >= ROM_BASE + ROM_SIZE) {
        fprintf(stderr, "M2.7 runtime FAIL: reset SP=%08x PC=%08x\n", sp, pc);
        return 1;
    }

    cycles = m68k_execute(600000);
    pc = m68k_get_reg(NULL, M68K_REG_PC);
    sr = m68k_get_reg(NULL, M68K_REG_SR);
    reset_pc = ram32(4);
    default_vector = ram32(32u * 4u);

    printf("LibreROM M2.7 runtime evidence\n");
    printf("cpu=MC68000\ncycles=%d\npc=%08x\nsr=%04x\n", cycles, pc, sr & 0xffffu);
    printf("overlay=%d via_ddra=%02x via_ora=%02x\n", overlay, via_ddra, via_ora);
    printf("vectors_ready_before_overlay_off=%d\n", vectors_ready_before_overlay_off);
    printf("ram_vector0_ssp=%08x\n", ram32(0));
    printf("ram_vector1_pc=%08x\n", reset_pc);
    printf("ram_vector32=%08x\n", default_vector);
    printf("marker=%08x exception_marker=%08x pre_marker=%08x video_marker=%08x\n",
           ram32(MARKER_ADDR), ram32(EXC_ADDR), ram32(PRE_ADDR), ram32(VID_ADDR));
    printf("main_fb=%02x%02x%02x%02x alt_fb=%02x%02x%02x%02x bytes=%u\n",
           ram[MAIN_FB], ram[MAIN_FB + 1], ram[MAIN_FB + 2], ram[MAIN_FB + 3],
           ram[ALT_FB], ram[ALT_FB + 1], ram[ALT_FB + 2], ram[ALT_FB + 3], FB_BYTES);

    if (!vectors_ready_before_overlay_off) {
        fprintf(stderr, "M2.7 runtime FAIL: vector table was not complete before overlay-off\n");
        return 1;
    }
    if (overlay || (via_ddra & OVERLAY_BIT) == 0 || (via_ora & OVERLAY_BIT) != 0) {
        fprintf(stderr, "M2.7 runtime FAIL: overlay state incorrect\n");
        return 1;
    }
    if (ram32(MARKER_ADDR) != MARKER_VALUE || ram32(EXC_ADDR) != EXC_VALUE ||
        ram32(PRE_ADDR) != PRE_VALUE || ram32(VID_ADDR) != VID_VALUE) {
        fprintf(stderr, "M2.7 runtime FAIL: qualification markers missing\n");
        return 1;
    }
    if (!framebuffer_ok(MAIN_FB) || !framebuffer_ok(ALT_FB)) {
        fprintf(stderr, "M2.7 runtime FAIL: framebuffer pattern mismatch\n");
        return 1;
    }
    if (ram32(RAM_TOP_PROBE) != 0) {
        fprintf(stderr, "M2.7 runtime FAIL: RAM probe was not restored\n");
        return 1;
    }
    if (pc < ROM_BASE || pc >= ROM_BASE + ROM_SIZE) {
        fprintf(stderr, "M2.7 runtime FAIL: execution left ROM window\n");
        return 1;
    }

    puts("LibreROM M2.7 runtime qualification: PASS");
    return 0;
}
