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

static uint8_t rom[ROM_SIZE], ram[RAM_SIZE];
static uint8_t via_ora = OVERLAY_BIT, via_ddra;
static int overlay = 1;

static uint32_t r32(uint32_t a){return ((uint32_t)ram[a]<<24)|((uint32_t)ram[a+1]<<16)|((uint32_t)ram[a+2]<<8)|ram[a+3];}
static uint16_t r16(uint32_t a){return (uint16_t)(((uint16_t)ram[a]<<8)|ram[a+1]);}
static uint8_t rd8(uint32_t a){
    if(a==VIA_ORA) return via_ora;
    if(a==VIA_DDRA) return via_ddra;
    if(a>=ROM_BASE && a<ROM_BASE+ROM_SIZE) return rom[a-ROM_BASE];
    if(a>=RAM_ALT_BASE && a<RAM_ALT_BASE+RAM_SIZE) return ram[a-RAM_ALT_BASE];
    if(overlay && a<ROM_SIZE) return rom[a];
    if(!overlay && a<RAM_SIZE) return ram[a];
    return 0xff;
}
static void wr8(uint32_t a,uint8_t v){
    if(a==VIA_DDRA){via_ddra=v;return;}
    if(a==VIA_ORA){via_ora=v;overlay=(v&OVERLAY_BIT)!=0;return;}
    if(a>=RAM_ALT_BASE && a<RAM_ALT_BASE+RAM_SIZE){ram[a-RAM_ALT_BASE]=v;return;}
    if(!overlay && a<RAM_SIZE) ram[a]=v;
}
unsigned int m68k_read_memory_8(unsigned int a){return rd8(a);}
unsigned int m68k_read_memory_16(unsigned int a){return ((unsigned)rd8(a)<<8)|rd8(a+1);}
unsigned int m68k_read_memory_32(unsigned int a){return (m68k_read_memory_16(a)<<16)|m68k_read_memory_16(a+2);}
void m68k_write_memory_8(unsigned int a,unsigned int v){wr8(a,(uint8_t)v);}
void m68k_write_memory_16(unsigned int a,unsigned int v){wr8(a,(uint8_t)(v>>8));wr8(a+1,(uint8_t)v);}
void m68k_write_memory_32(unsigned int a,unsigned int v){m68k_write_memory_16(a,v>>16);m68k_write_memory_16(a+2,v);}

static int load(const char *p){FILE *f=fopen(p,"rb");size_t n;if(!f){perror(p);return 1;}n=fread(rom,1,sizeof rom,f);fclose(f);if(n!=sizeof rom){fprintf(stderr,"M3.7 FAIL: ROM size %zu\n",n);return 1;}return 0;}

int main(int argc,char **argv){
    unsigned cycles=0,pc;
    if(argc!=2) return 2;
    if(load(argv[1])) return 1;
    m68k_init();m68k_set_cpu_type(M68K_CPU_TYPE_68000);m68k_pulse_reset();
    while(cycles<600000u && r32(0x41c)!=0x4f4b3337u){int n=m68k_execute(64);cycles+=(unsigned)(n>0?n:64);}
    pc=m68k_get_reg(NULL,M68K_REG_PC);
    printf("LibreROM M3.7 runtime evidence\ncycles=%u\npc=%08x\noverlay=%d\n",cycles,pc,overlay);
    printf("heap_next=%08x mem_err=%04x master0=%08x\n",r32(0x440),r16(0x220),r32(0x7000));
    printf("handle0=%08x data0=%08x logical0=%08x extent0=%08x active0=%08x\n",r32(0x500),r32(0x504),r32(0x508),r32(0x50c),r32(0x510));
    if(overlay || (via_ddra&OVERLAY_BIT)==0 || (via_ora&OVERLAY_BIT)!=0) return 1;
    if(r32(0x400)!=0x4d333730u || r32(0x404)!=0x4e48374fu || r32(0x40c)!=0x4d50374fu ||
       r32(0x410)!=0x4448374fu || r32(0x414)!=0x575a3737u || r32(0x418)!=0x5248374fu ||
       r32(0x41c)!=0x4f4b3337u) return 1;
    if(r32(0x440)!=0x00010032u || r16(0x220)!=0u) return 1;
    if(r32(0x7000)!=0x00010022u) return 1;
    if(r32(0x500)!=0x00007000u || r32(0x504)!=0x00010022u || r32(0x508)!=0x10u || r32(0x50c)!=0x10u || r32(0x510)!=1u) return 1;
    if(pc<ROM_BASE || pc>=ROM_BASE+ROM_SIZE) return 1;
    puts("LibreROM M3.7 NewHandle/DisposeHandle runtime qualification: PASS");
    return 0;
}
