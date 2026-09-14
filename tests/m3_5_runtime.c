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

#define M350_ADDR 0x00000400u
#define NP5O_ADDR 0x00000404u
#define PR35_ADDR 0x00000408u
#define DP1O_ADDR 0x0000040cu
#define RUS5_ADDR 0x00000410u
#define WZE5_ADDR 0x00000414u
#define OK35_ADDR 0x00000418u
#define DSP5_ADDR 0x00000420u
#define SVC5_ADDR 0x00000424u
#define BAD5_ADDR 0x00000428u
#define HEAP_NEXT 0x00000440u
#define MEM_ERR   0x00000220u
#define ALLOC_TABLE 0x00000460u

#define M350_VALUE 0x4d333530u
#define NP5O_VALUE 0x4e50354fu
#define PR35_VALUE 0x50523335u
#define DP1O_VALUE 0x4450314fu
#define RUS5_VALUE 0x52555335u
#define WZE5_VALUE 0x575a4535u
#define OK35_VALUE 0x4f4b3335u
#define DSP5_VALUE 0x44535035u
#define SVC5_VALUE 0x53564335u
#define BAD5_VALUE 0x42414435u

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
                ram32(PR35_ADDR) == PR35_VALUE;
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
        fprintf(stderr, "M3.5 runtime FAIL: ROM must be exactly %u bytes (got %zu)\n", ROM_SIZE, got);
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
        fprintf(stderr, "usage: %s <librom-m3.5-macplus.bin>\n", argv[0]);
        return 2;
    }
    if (load_rom(argv[1])) return 1;

    m68k_init();
    m68k_set_cpu_type(M68K_CPU_TYPE_68000);
    m68k_pulse_reset();

    while (total_cycles < 700000u && ram32(OK35_ADDR) != OK35_VALUE) {
        int ran = m68k_execute(64);
        if (ran < 0) ran = 0;
        total_cycles += (unsigned)(ran ? ran : 64);
    }

    pc = m68k_get_reg(NULL, M68K_REG_PC);
    aline_vector = ram32(10u * 4u);

    printf("LibreROM M3.5 runtime evidence\n");
    printf("cpu=MC68000\ncycles=%u\npc=%08x\n", total_cycles, pc);
    printf("overlay=%d via_ddra=%02x via_ora=%02x\n", overlay, via_ddra, via_ora);
    printf("vectors_ready_before_overlay_off=%d\n", vectors_ready_before_overlay_off);
    printf("ram_vector10_aline=%08x\n", aline_vector);
    printf("heap_next=%08x mem_err=%04x\n", ram32(HEAP_NEXT), ram16(MEM_ERR));
    printf("slot0_ptr=%08x slot0_size=%08x slot0_active=%u\n",
           ram32(ALLOC_TABLE), ram32(ALLOC_TABLE + 4), ram32(ALLOC_TABLE + 8));

    if (!vectors_ready_before_overlay_off) {
        fprintf(stderr, "M3.5 runtime FAIL: A-line vector not installed before overlay-off\n");
        return 1;
    }
    if (overlay || (via_ddra & OVERLAY_BIT) == 0 || (via_ora & OVERLAY_BIT) != 0) {
        fprintf(stderr, "M3.5 runtime FAIL: overlay state incorrect\n");
        return 1;
    }
    if (aline_vector < ROM_BASE || aline_vector >= ROM_BASE + ROM_SIZE) {
        fprintf(stderr, "M3.5 runtime FAIL: A-line vector invalid\n");
        return 1;
    }
    if (ram32(M350_ADDR) != M350_VALUE || ram32(PR35_ADDR) != PR35_VALUE ||
        ram32(NP5O_ADDR) != NP5O_VALUE || ram32(DP1O_ADDR) != DP1O_VALUE ||
        ram32(RUS5_ADDR) != RUS5_VALUE || ram32(WZE5_ADDR) != WZE5_VALUE ||
        ram32(OK35_ADDR) != OK35_VALUE || ram32(DSP5_ADDR) != DSP5_VALUE ||
        ram32(SVC5_ADDR) != SVC5_VALUE) {
        fprintf(stderr, "M3.5 runtime FAIL: qualification markers missing\n");
        return 1;
    }
    if (ram32(BAD5_ADDR) == BAD5_VALUE) {
        fprintf(stderr, "M3.5 runtime FAIL: unknown-service path reached\n");
        return 1;
    }
    if (ram32(HEAP_NEXT) != 0x00010032u) {
        fprintf(stderr, "M3.5 runtime FAIL: disposed block was not reused\n");
        return 1;
    }
    if (ram16(MEM_ERR) != (uint16_t)0xff91u) {
        fprintf(stderr, "M3.5 runtime FAIL: MemErr is not memWZErr (-111)\n");
        return 1;
    }
    if (ram32(ALLOC_TABLE) != 0x00010000u || ram32(ALLOC_TABLE + 8) != 1u) {
        fprintf(stderr, "M3.5 runtime FAIL: first allocation slot not reused and active\n");
        return 1;
    }
    if (pc < ROM_BASE || pc >= ROM_BASE + ROM_SIZE) {
        fprintf(stderr, "M3.5 runtime FAIL: execution left ROM window\n");
        return 1;
    }

    puts("LibreROM M3.5 DisposePtr runtime qualification: PASS");
    return 0;
}
