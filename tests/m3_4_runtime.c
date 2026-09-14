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

#define M340_ADDR 0x00000400u
#define NP1O_ADDR 0x00000404u
#define PR34_ADDR 0x00000408u
#define NP2O_ADDR 0x0000040cu
#define MFE4_ADDR 0x00000410u
#define OK34_ADDR 0x00000414u
#define EXC4_ADDR 0x00000418u
#define DSP4_ADDR 0x0000041cu
#define SVC4_ADDR 0x00000420u
#define BAD4_ADDR 0x00000424u
#define HEAP_NEXT 0x00000440u
#define MEM_ERR   0x00000220u

#define M340_VALUE 0x4d333430u
#define NP1O_VALUE 0x4e50314fu
#define PR34_VALUE 0x50523334u
#define NP2O_VALUE 0x4e50324fu
#define MFE4_VALUE 0x4d464534u
#define OK34_VALUE 0x4f4b3334u
#define DSP4_VALUE 0x44535034u
#define SVC4_VALUE 0x53564334u
#define BAD4_VALUE 0x42414434u

static uint8_t rom[ROM_SIZE];
static uint8_t ram[RAM_SIZE];
static uint8_t via_ora = OVERLAY_BIT;
static uint8_t via_ddra;
static int overlay = 1;
static int vectors_ready_before_overlay_off;

static uint32_t ram32(uint32_t a)
{
    return ((uint32_t)ram[a] << 24) |
           ((uint32_t)ram[a + 1] << 16) |
           ((uint32_t)ram[a + 2] << 8) |
           (uint32_t)ram[a + 3];
}

static uint16_t ram16(uint32_t a)
{
    return (uint16_t)(((uint16_t)ram[a] << 8) | ram[a + 1]);
}

static uint8_t read8(uint32_t a)
{
    if (a == VIA_ORA) return via_ora;
    if (a == VIA_DDRA) return via_ddra;
    if (a >= ROM_BASE && a < ROM_BASE + ROM_SIZE) return rom[a - ROM_BASE];
    if (a >= RAM_ALT_BASE && a < RAM_ALT_BASE + RAM_SIZE) return ram[a - RAM_ALT_BASE];
    if (overlay && a < ROM_SIZE) return rom[a];
    if (!overlay && a < RAM_SIZE) return ram[a];
    return 0xff;
}

static void write8(uint32_t a, uint8_t v)
{
    if (a == VIA_DDRA) { via_ddra = v; return; }
    if (a == VIA_ORA) {
        if (overlay && (v & OVERLAY_BIT) == 0) {
            uint32_t reset_pc = ram32(4);
            uint32_t aline = ram32(10u * 4u);
            vectors_ready_before_overlay_off =
                ram32(0) == RAM_SIZE &&
                reset_pc >= ROM_BASE && reset_pc < ROM_BASE + ROM_SIZE &&
                aline >= ROM_BASE && aline < ROM_BASE + ROM_SIZE &&
                ram32(PR34_ADDR) == PR34_VALUE;
        }
        via_ora = v;
        overlay = (v & OVERLAY_BIT) != 0;
        return;
    }
    if (a >= RAM_ALT_BASE && a < RAM_ALT_BASE + RAM_SIZE) {
        ram[a - RAM_ALT_BASE] = v;
        return;
    }
    if (!overlay && a < RAM_SIZE) ram[a] = v;
}

unsigned int m68k_read_memory_8(unsigned int a) { return read8(a); }
unsigned int m68k_read_memory_16(unsigned int a)
{ return ((unsigned int)read8(a) << 8) | read8(a + 1); }
unsigned int m68k_read_memory_32(unsigned int a)
{ return (m68k_read_memory_16(a) << 16) | m68k_read_memory_16(a + 2); }
void m68k_write_memory_8(unsigned int a, unsigned int v) { write8(a, (uint8_t)v); }
void m68k_write_memory_16(unsigned int a, unsigned int v)
{ write8(a, (uint8_t)(v >> 8)); write8(a + 1, (uint8_t)v); }
void m68k_write_memory_32(unsigned int a, unsigned int v)
{ m68k_write_memory_16(a, v >> 16); m68k_write_memory_16(a + 2, v); }

static int load_rom(const char *path)
{
    FILE *fp = fopen(path, "rb");
    size_t got;
    if (!fp) { perror(path); return 1; }
    got = fread(rom, 1, sizeof(rom), fp);
    if (got != sizeof(rom) || fgetc(fp) != EOF) {
        fprintf(stderr, "M3.4 runtime FAIL: ROM must be exactly %u bytes (got %zu)\n", ROM_SIZE, got);
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
        fprintf(stderr, "usage: %s <librom-m3.4-macplus.bin>\n", argv[0]);
        return 2;
    }
    if (load_rom(argv[1])) return 1;

    m68k_init();
    m68k_set_cpu_type(M68K_CPU_TYPE_68000);
    m68k_pulse_reset();

    while (total_cycles < 500000u && ram32(OK34_ADDR) != OK34_VALUE) {
        int ran = m68k_execute(64);
        if (ran < 0) ran = 0;
        total_cycles += (unsigned)(ran ? ran : 64);
    }

    pc = m68k_get_reg(NULL, M68K_REG_PC);
    aline_vector = ram32(10u * 4u);

    printf("LibreROM M3.4 runtime evidence\n");
    printf("cpu=MC68000\ncycles=%u\npc=%08x\n", total_cycles, pc);
    printf("overlay=%d via_ddra=%02x via_ora=%02x\n", overlay, via_ddra, via_ora);
    printf("vectors_ready_before_overlay_off=%d\n", vectors_ready_before_overlay_off);
    printf("ram_vector10_aline=%08x\n", aline_vector);
    printf("heap_next=%08x mem_err=%04x\n", ram32(HEAP_NEXT), ram16(MEM_ERR));

    if (!vectors_ready_before_overlay_off) {
        fprintf(stderr, "M3.4 runtime FAIL: A-line vector not installed before overlay-off\n");
        return 1;
    }
    if (overlay || (via_ddra & OVERLAY_BIT) == 0 || (via_ora & OVERLAY_BIT) != 0) {
        fprintf(stderr, "M3.4 runtime FAIL: overlay state incorrect\n");
        return 1;
    }
    if (aline_vector < ROM_BASE || aline_vector >= ROM_BASE + ROM_SIZE) {
        fprintf(stderr, "M3.4 runtime FAIL: A-line vector invalid\n");
        return 1;
    }
    if (ram32(M340_ADDR) != M340_VALUE || ram32(PR34_ADDR) != PR34_VALUE ||
        ram32(NP1O_ADDR) != NP1O_VALUE || ram32(NP2O_ADDR) != NP2O_VALUE ||
        ram32(MFE4_ADDR) != MFE4_VALUE || ram32(OK34_ADDR) != OK34_VALUE ||
        ram32(DSP4_ADDR) != DSP4_VALUE || ram32(SVC4_ADDR) != SVC4_VALUE) {
        fprintf(stderr, "M3.4 runtime FAIL: qualification markers missing\n");
        return 1;
    }
    if (ram32(BAD4_ADDR) == BAD4_VALUE) {
        fprintf(stderr, "M3.4 runtime FAIL: unknown-service path reached\n");
        return 1;
    }
    if (ram32(HEAP_NEXT) != 0x00010032u || ram16(MEM_ERR) != 0xff94u) {
        fprintf(stderr, "M3.4 runtime FAIL: heap/MemErr state incorrect\n");
        return 1;
    }
    if (pc < ROM_BASE || pc >= ROM_BASE + ROM_SIZE) {
        fprintf(stderr, "M3.4 runtime FAIL: execution left ROM window\n");
        return 1;
    }

    puts("LibreROM M3.4 NewPtr compatibility runtime qualification: PASS");
    return 0;
}
