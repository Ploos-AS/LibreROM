#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "m68k.h"

#define ROM_BASE 0x00400000u
#define ROM_SIZE 131072u
#define RAM_SIZE (1024u * 1024u)
#define VIA_ORA  0x00e80200u
#define VIA_DDRA 0x00e80600u
#define OVERLAY_BIT 0x10u
#define SIGNATURE_ADDR 0x00000100u
#define SIGNATURE_VALUE 0x4c524d33u

static uint8_t rom[ROM_SIZE];
static uint8_t ram[RAM_SIZE];
static uint8_t via_ora = OVERLAY_BIT;
static uint8_t via_ddra;
static int overlay = 1;

static uint8_t read8(uint32_t address)
{
    if (address == VIA_ORA)
        return via_ora;
    if (address == VIA_DDRA)
        return via_ddra;

    if (address >= ROM_BASE && address < ROM_BASE + ROM_SIZE)
        return rom[address - ROM_BASE];

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
        via_ora = value;
        overlay = (value & OVERLAY_BIT) != 0;
        return;
    }

    if (!overlay && address < RAM_SIZE)
        ram[address] = value;
}

unsigned int m68k_read_memory_8(unsigned int address)
{
    return read8(address);
}

unsigned int m68k_read_memory_16(unsigned int address)
{
    return ((unsigned int)read8(address) << 8) |
           (unsigned int)read8(address + 1);
}

unsigned int m68k_read_memory_32(unsigned int address)
{
    return (m68k_read_memory_16(address) << 16) |
           m68k_read_memory_16(address + 2);
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
        fprintf(stderr, "M2.3 runtime FAIL: ROM must be exactly %u bytes (got %zu)\n",
                ROM_SIZE, got);
        fclose(fp);
        return 1;
    }

    fclose(fp);
    return 0;
}

static uint32_t ram32(uint32_t address)
{
    return ((uint32_t)ram[address] << 24) |
           ((uint32_t)ram[address + 1] << 16) |
           ((uint32_t)ram[address + 2] << 8) |
           (uint32_t)ram[address + 3];
}

int main(int argc, char **argv)
{
    unsigned int sp;
    unsigned int pc;
    unsigned int sr;
    int cycles;

    if (argc != 2) {
        fprintf(stderr, "usage: %s <librom-m2.3-macplus.bin>\n", argv[0]);
        return 2;
    }

    if (load_rom(argv[1]))
        return 1;

    m68k_init();
    m68k_set_cpu_type(M68K_CPU_TYPE_68000);
    m68k_pulse_reset();

    sp = m68k_get_reg(NULL, M68K_REG_SP);
    pc = m68k_get_reg(NULL, M68K_REG_PC);

    if (sp != 0x00100000u || pc < ROM_BASE || pc >= ROM_BASE + ROM_SIZE) {
        fprintf(stderr, "M2.3 runtime FAIL: reset SP=%08x PC=%08x\n", sp, pc);
        return 1;
    }

    cycles = m68k_execute(512);
    pc = m68k_get_reg(NULL, M68K_REG_PC);
    sr = m68k_get_reg(NULL, M68K_REG_SR);

    printf("LibreROM M2.3 runtime evidence\n");
    printf("cpu=MC68000\n");
    printf("cycles=%d\n", cycles);
    printf("pc=%08x\n", pc);
    printf("sr=%04x\n", sr & 0xffffu);
    printf("via_ddra=%02x\n", via_ddra);
    printf("via_ora=%02x\n", via_ora);
    printf("overlay=%d\n", overlay);
    printf("low_ram_signature=%08x\n", ram32(SIGNATURE_ADDR));

    if ((via_ddra & OVERLAY_BIT) == 0) {
        fprintf(stderr, "M2.3 runtime FAIL: VIA A4 not configured as output\n");
        return 1;
    }
    if (via_ora & OVERLAY_BIT) {
        fprintf(stderr, "M2.3 runtime FAIL: VIA A4 still asserted\n");
        return 1;
    }
    if (overlay) {
        fprintf(stderr, "M2.3 runtime FAIL: low-memory ROM overlay still active\n");
        return 1;
    }
    if (ram32(SIGNATURE_ADDR) != SIGNATURE_VALUE) {
        fprintf(stderr, "M2.3 runtime FAIL: low-memory RAM signature missing\n");
        return 1;
    }
    if (pc < ROM_BASE || pc >= ROM_BASE + ROM_SIZE) {
        fprintf(stderr, "M2.3 runtime FAIL: execution left canonical ROM window\n");
        return 1;
    }
    if ((sr & 0x2700u) != 0x2700u) {
        fprintf(stderr, "M2.3 runtime FAIL: unexpected SR=%04x\n", sr & 0xffffu);
        return 1;
    }

    puts("LibreROM M2.3 runtime qualification: PASS");
    return 0;
}
