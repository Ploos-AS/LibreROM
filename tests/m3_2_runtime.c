#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "m68k.h"

#define ROM_BASE 0x00400000u
#define ROM_SIZE 131072u
#define RAM_SIZE (1024u * 1024u)
#define RAM_ALT_BASE 0x00600000u
#define VIA_ORA 0x00efe200u
#define VIA_DDRA 0x00efe600u
#define OVERLAY_BIT 0x10u
#define PR32_ADDR 0x408u
#define OK32_ADDR 0x414u
#define HEAP_NEXT 0x440u
#define BAD2_ADDR 0x424u

static uint8_t rom[ROM_SIZE], ram[RAM_SIZE];
static uint8_t via_ora = OVERLAY_BIT, via_ddra;
static int overlay = 1, vectors_ready;

static uint32_t r32(uint32_t a) {
    return ((uint32_t)ram[a] << 24) | ((uint32_t)ram[a+1] << 16) |
           ((uint32_t)ram[a+2] << 8) | ram[a+3];
}
static uint8_t r8(uint32_t a) {
    if (a == VIA_ORA) return via_ora;
    if (a == VIA_DDRA) return via_ddra;
    if (a >= ROM_BASE && a < ROM_BASE + ROM_SIZE) return rom[a-ROM_BASE];
    if (a >= RAM_ALT_BASE && a < RAM_ALT_BASE + RAM_SIZE) return ram[a-RAM_ALT_BASE];
    if (overlay && a < ROM_SIZE) return rom[a];
    if (!overlay && a < RAM_SIZE) return ram[a];
    return 0xff;
}
static void w8(uint32_t a, uint8_t v) {
    if (a == VIA_DDRA) { via_ddra = v; return; }
    if (a == VIA_ORA) {
        if (overlay && !(v & OVERLAY_BIT))
            vectors_ready = r32(0) == RAM_SIZE &&
                            r32(4) >= ROM_BASE && r32(4) < ROM_BASE + ROM_SIZE &&
                            r32(40) >= ROM_BASE && r32(40) < ROM_BASE + ROM_SIZE &&
                            r32(PR32_ADDR) == 0x50523332u;
        via_ora = v; overlay = (v & OVERLAY_BIT) != 0; return;
    }
    if (a >= RAM_ALT_BASE && a < RAM_ALT_BASE + RAM_SIZE) { ram[a-RAM_ALT_BASE] = v; return; }
    if (!overlay && a < RAM_SIZE) ram[a] = v;
}
unsigned int m68k_read_memory_8(unsigned int a){return r8(a);}
unsigned int m68k_read_memory_16(unsigned int a){return ((unsigned)r8(a)<<8)|r8(a+1);}
unsigned int m68k_read_memory_32(unsigned int a){return (m68k_read_memory_16(a)<<16)|m68k_read_memory_16(a+2);}
void m68k_write_memory_8(unsigned int a,unsigned int v){w8(a,(uint8_t)v);}
void m68k_write_memory_16(unsigned int a,unsigned int v){w8(a,(uint8_t)(v>>8));w8(a+1,(uint8_t)v);}
void m68k_write_memory_32(unsigned int a,unsigned int v){m68k_write_memory_16(a,v>>16);m68k_write_memory_16(a+2,v);}

static int load(const char *p){FILE *f=fopen(p,"rb");size_t n;if(!f){perror(p);return 1;}n=fread(rom,1,sizeof rom,f);if(n!=sizeof rom||fgetc(f)!=EOF){fprintf(stderr,"M3.2 runtime FAIL: ROM size\n");fclose(f);return 1;}fclose(f);return 0;}

int main(int argc,char **argv){
    unsigned cycles=0,pc;
    if(argc!=2) return 2;
    if(load(argv[1])) return 1;
    m68k_init(); m68k_set_cpu_type(M68K_CPU_TYPE_68000); m68k_pulse_reset();
    while(cycles<500000u && r32(OK32_ADDR)!=0x4f4b3332u){int n=m68k_execute(64);cycles+=(unsigned)(n>0?n:64);}
    pc=m68k_get_reg(NULL,M68K_REG_PC);
    printf("LibreROM M3.2 runtime evidence\ncycles=%u\npc=%08x\nheap_next=%08x\n",cycles,pc,r32(HEAP_NEXT));
    printf("markers=%08x/%08x/%08x/%08x/%08x/%08x/%08x\n",r32(0x400),r32(0x404),r32(0x408),r32(0x40c),r32(0x410),r32(0x414),r32(0x420));
    if(!vectors_ready || overlay || !(via_ddra&OVERLAY_BIT) || (via_ora&OVERLAY_BIT)) return 1;
    if(r32(0x400)!=0x4d333230u || r32(0x404)!=0x41314f4bu || r32(0x408)!=0x50523332u ||
       r32(0x40c)!=0x41324f4bu || r32(0x410)!=0x4f4f4d32u || r32(0x414)!=0x4f4b3332u ||
       r32(0x41c)!=0x44535032u || r32(0x420)!=0x53564332u || r32(BAD2_ADDR)==0x42414432u) return 1;
    if(r32(HEAP_NEXT)!=0x00010032u) return 1;
    if(pc<ROM_BASE || pc>=ROM_BASE+ROM_SIZE) return 1;
    puts("LibreROM M3.2 memory primitive runtime qualification: PASS");
    return 0;
}
