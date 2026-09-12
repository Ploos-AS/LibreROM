#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "m68k.h"

#define ROM_SIZE 65536u

static uint8_t rom[ROM_SIZE];

static uint8_t read8(uint32_t address)
{
    if (address < ROM_SIZE)
        return rom[address];
    return 0xff;
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
    (void)address;
    (void)value;
}

void m68k_write_memory_16(unsigned int address, unsigned int value)
{
    (void)address;
    (void)value;
}

void m68k_write_memory_32(unsigned int address, unsigned int value)
{
    (void)address;
    (void)value;
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
    if (got != sizeof(rom)) {
        fprintf(stderr, "runtime FAIL: ROM size is %zu, expected %u\n",
                got, ROM_SIZE);
        fclose(fp);
        return 1;
    }

    if (fgetc(fp) != EOF) {
        fprintf(stderr, "runtime FAIL: ROM is larger than %u bytes\n", ROM_SIZE);
        fclose(fp);
        return 1;
    }

    fclose(fp);
    return 0;
}

int main(int argc, char **argv)
{
    unsigned int pc;
    unsigned int sp;
    unsigned int sr;
    int cycles;

    if (argc != 2) {
        fprintf(stderr, "usage: %s <librom-m1.bin>\n", argv[0]);
        return 2;
    }

    if (load_rom(argv[1]))
        return 1;

    m68k_init();
    m68k_set_cpu_type(M68K_CPU_TYPE_68000);
    m68k_pulse_reset();

    sp = m68k_get_reg(NULL, M68K_REG_SP);
    pc = m68k_get_reg(NULL, M68K_REG_PC);

    if (sp != 0x00010000u || pc != 0x00000008u) {
        fprintf(stderr,
                "runtime FAIL: reset vectors SP=%08x PC=%08x, expected 00010000/00000008\n",
                sp, pc);
        return 1;
    }

    cycles = m68k_execute(64);
    pc = m68k_get_reg(NULL, M68K_REG_PC);
    sp = m68k_get_reg(NULL, M68K_REG_SP);
    sr = m68k_get_reg(NULL, M68K_REG_SR);

    printf("LibreROM M1 runtime evidence\n");
    printf("cpu=MC68000\n");
    printf("cycles=%d\n", cycles);
    printf("sp=%08x\n", sp);
    printf("pc=%08x\n", pc);
    printf("sr=%04x\n", sr & 0xffffu);

    if (sp != 0x00010000u) {
        fprintf(stderr, "runtime FAIL: SP changed unexpectedly\n");
        return 1;
    }

    if (pc != 0x00000010u) {
        fprintf(stderr,
                "runtime FAIL: PC=%08x, expected 00000010 after MOVE/STOP\n",
                pc);
        return 1;
    }

    if ((sr & 0xffffu) != 0x2700u) {
        fprintf(stderr, "runtime FAIL: SR=%04x, expected 2700\n", sr & 0xffffu);
        return 1;
    }

    puts("LibreROM M1 runtime qualification: PASS");
    return 0;
}
