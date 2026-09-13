#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "m68k.h"

#define ROM_BASE 0x00400000u
#define ROM_SIZE 131072u
#define RAM_SIZE (1024u * 1024u)
#define RAM_ALT_BASE 0x00600000u

#define VIA_ORA   0x00efe200u
#define VIA_DDRA  0x00efe600u
#define VIA_SR    0x00eff400u
#define VIA_ACR   0x00eff600u
#define VIA_IFR   0x00effa00u
#define VIA_IER   0x00effc00u
#define OVERLAY_BIT 0x10u
#define VIA_SR_BIT 0x04u
#define KEYBOARD_MODEL_COMMAND 0x16u

#define MARKER_ADDR 0x00000400u
#define EXC_ADDR    0x00000404u
#define PRE_ADDR    0x00000408u
#define VID_ADDR    0x0000040cu
#define KBYTE_ADDR  0x00000418u
#define KBD_ADDR    0x0000041cu
#define INP_ADDR    0x00000420u
#define MARKER_VALUE 0x4c524d39u
#define EXC_VALUE    0x45584339u
#define PRE_VALUE    0x50524539u
#define VID_VALUE    0x56494439u
#define KBD_VALUE    0x4b424439u
#define INP_VALUE    0x494e5039u

#define RAM_TOP_PROBE 0x000ffffcu
#define MAIN_FB 0x000fa700u
#define ALT_FB  0x000f2700u
#define FB_BYTES 21888u

static uint8_t rom[ROM_SIZE];
static uint8_t ram[RAM_SIZE];
static uint8_t via_ora = OVERLAY_BIT;
static uint8_t via_ddra;
static uint8_t via_sr;
static uint8_t via_acr;
static uint8_t via_ifr;
static uint8_t via_ier;
static int overlay = 1;
static int irq_asserted;
static int vectors_ready_before_overlay_off;
static int keyboard_pending;
static int keyboard_response;
static const uint8_t synthetic_key_byte = 0x01u;
static unsigned keyboard_delay;

static uint32_t ram32(uint32_t address)
{
    return ((uint32_t)ram[address] << 24) |
           ((uint32_t)ram[address + 1] << 16) |
           ((uint32_t)ram[address + 2] << 8) |
           (uint32_t)ram[address + 3];
}

static void via_update_irq(void)
{
    irq_asserted = ((via_ifr & via_ier & 0x7fu) != 0);
    if (irq_asserted) via_ifr |= 0x80u;
    else via_ifr &= 0x7fu;
}

static uint8_t read8(uint32_t address)
{
    if (address == VIA_ORA) return via_ora;
    if (address == VIA_DDRA) return via_ddra;
    if (address == VIA_SR) {
        via_ifr &= (uint8_t)~VIA_SR_BIT;
        via_update_irq();
        return via_sr;
    }
    if (address == VIA_ACR) return via_acr;
    if (address == VIA_IFR) return via_ifr;
    if (address == VIA_IER) return (uint8_t)(0x80u | via_ier);
    if (address >= ROM_BASE && address < ROM_BASE + ROM_SIZE) return rom[address - ROM_BASE];
    if (address >= RAM_ALT_BASE && address < RAM_ALT_BASE + RAM_SIZE) return ram[address - RAM_ALT_BASE];
    if (overlay && address < ROM_SIZE) return rom[address];
    if (!overlay && address < RAM_SIZE) return ram[address];
    return 0xff;
}

static void write8(uint32_t address, uint8_t value)
{
    if (address == VIA_DDRA) { via_ddra = value; return; }
    if (address == VIA_ORA) {
        if (overlay && (value & OVERLAY_BIT) == 0) {
            uint32_t reset_pc = ram32(4);
            uint32_t irq1 = ram32(25u * 4u);
            uint32_t trap0 = ram32(32u * 4u);
            vectors_ready_before_overlay_off =
                ram32(0) == RAM_SIZE &&
                reset_pc >= ROM_BASE && reset_pc < ROM_BASE + ROM_SIZE &&
                irq1 >= ROM_BASE && irq1 < ROM_BASE + ROM_SIZE &&
                trap0 >= ROM_BASE && trap0 < ROM_BASE + ROM_SIZE &&
                ram32(PRE_ADDR) == PRE_VALUE;
        }
        via_ora = value;
        overlay = (value & OVERLAY_BIT) != 0;
        return;
    }
    if (address == VIA_ACR) { via_acr = value; return; }
    if (address == VIA_IFR) {
        via_ifr &= (uint8_t)~(value & 0x7fu);
        via_update_irq();
        return;
    }
    if (address == VIA_IER) {
        if (value & 0x80u) via_ier |= (value & 0x7fu);
        else via_ier &= (uint8_t)~(value & 0x7fu);
        via_update_irq();
        return;
    }
    if (address == VIA_SR) {
        via_sr = value;
        via_ifr &= (uint8_t)~VIA_SR_BIT;
        via_update_irq();
        if ((via_acr & 0x1cu) == 0x1cu && value == KEYBOARD_MODEL_COMMAND) {
            keyboard_pending = 1;
            keyboard_delay = 256u;
        }
        return;
    }
    if (address >= RAM_ALT_BASE && address < RAM_ALT_BASE + RAM_SIZE) {
        ram[address - RAM_ALT_BASE] = value;
        return;
    }
    if (!overlay && address < RAM_SIZE) ram[address] = value;
}

unsigned int m68k_read_memory_8(unsigned int address) { return read8(address); }
unsigned int m68k_read_memory_16(unsigned int address) { return ((unsigned)read8(address) << 8) | read8(address + 1); }
unsigned int m68k_read_memory_32(unsigned int address) { return (m68k_read_memory_16(address) << 16) | m68k_read_memory_16(address + 2); }
void m68k_write_memory_8(unsigned int address, unsigned int value) { write8(address, (uint8_t)value); }
void m68k_write_memory_16(unsigned int address, unsigned int value) { write8(address, (uint8_t)(value >> 8)); write8(address + 1, (uint8_t)value); }
void m68k_write_memory_32(unsigned int address, unsigned int value) { m68k_write_memory_16(address, value >> 16); m68k_write_memory_16(address + 2, value); }

static void keyboard_tick(unsigned cycles)
{
    if (!keyboard_pending || (via_acr & 0x1cu) != 0x0cu) return;
    if (cycles < keyboard_delay) { keyboard_delay -= cycles; return; }
    keyboard_pending = 0;
    keyboard_response = 1;
    /* Model 0 response is 0x01. The same receive path accepts key bytes; keep
       a named synthetic key byte in the harness as the minimal input fixture. */
    via_sr = synthetic_key_byte;
    via_ifr |= VIA_SR_BIT;
    via_update_irq();
}

static int load_rom(const char *path)
{
    FILE *fp = fopen(path, "rb");
    size_t got;
    if (!fp) { perror(path); return 1; }
    got = fread(rom, 1, sizeof(rom), fp);
    if (got != sizeof(rom) || fgetc(fp) != EOF) {
        fprintf(stderr, "M2.9 runtime FAIL: ROM must be exactly %u bytes (got %zu)\n", ROM_SIZE, got);
        fclose(fp); return 1;
    }
    fclose(fp); return 0;
}

static int framebuffer_ok(uint32_t base)
{
    uint32_t i;
    for (i = 0; i < FB_BYTES; ++i) {
        uint8_t expected = (i & 1u) ? 0x55u : 0xaau;
        if (ram[base + i] != expected) return 0;
    }
    return 1;
}

int main(int argc, char **argv)
{
    unsigned total_cycles = 0, pc, sp, sr;
    if (argc != 2) { fprintf(stderr, "usage: %s <librom-m2.9-macplus.bin>\n", argv[0]); return 2; }
    if (load_rom(argv[1])) return 1;

    m68k_init();
    m68k_set_cpu_type(M68K_CPU_TYPE_68000);
    m68k_pulse_reset();
    sp = m68k_get_reg(NULL, M68K_REG_SP);
    pc = m68k_get_reg(NULL, M68K_REG_PC);
    if (sp != RAM_SIZE || pc < ROM_BASE || pc >= ROM_BASE + ROM_SIZE) return 1;

    while (total_cycles < 900000u && ram32(INP_ADDR) != INP_VALUE) {
        int ran = m68k_execute(64);
        if (ran < 0) ran = 0;
        total_cycles += (unsigned)ran;
        keyboard_tick((unsigned)(ran ? ran : 64));
        m68k_set_irq(irq_asserted ? 1u : 0u);
    }

    pc = m68k_get_reg(NULL, M68K_REG_PC);
    sr = m68k_get_reg(NULL, M68K_REG_SR);
    printf("LibreROM M2.9 runtime evidence\n");
    printf("cpu=MC68000\ncycles=%u\npc=%08x\nsr=%04x\n", total_cycles, pc, sr & 0xffffu);
    printf("overlay=%d via_acr=%02x via_ifr=%02x via_ier=%02x irq=%d\n", overlay, via_acr, via_ifr, via_ier, irq_asserted);
    printf("vectors_ready_before_overlay_off=%d\n", vectors_ready_before_overlay_off);
    printf("keyboard_response=%d received_byte=%02x synthetic_key_byte=%02x\n", keyboard_response, ram[KBYTE_ADDR], synthetic_key_byte);
    printf("markers=%08x/%08x/%08x/%08x/%08x/%08x\n",
           ram32(MARKER_ADDR), ram32(EXC_ADDR), ram32(PRE_ADDR), ram32(VID_ADDR), ram32(KBD_ADDR), ram32(INP_ADDR));

    if (!vectors_ready_before_overlay_off || overlay) return 1;
    if (!keyboard_response || ram[KBYTE_ADDR] != synthetic_key_byte) return 1;
    if (ram32(KBD_ADDR) != KBD_VALUE || ram32(INP_ADDR) != INP_VALUE) return 1;
    if ((via_ifr & VIA_SR_BIT) != 0 || (via_ier & VIA_SR_BIT) != 0 || irq_asserted) return 1;
    if (ram32(MARKER_ADDR) != MARKER_VALUE || ram32(EXC_ADDR) != EXC_VALUE || ram32(PRE_ADDR) != PRE_VALUE || ram32(VID_ADDR) != VID_VALUE) return 1;
    if (!framebuffer_ok(MAIN_FB) || !framebuffer_ok(ALT_FB)) return 1;
    if (ram32(RAM_TOP_PROBE) != 0) return 1;
    if (pc < ROM_BASE || pc >= ROM_BASE + ROM_SIZE) return 1;

    puts("LibreROM M2.9 runtime qualification: PASS");
    return 0;
}
