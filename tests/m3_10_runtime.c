#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "m68k.h"
#define ROM_BASE 0x00400000u
#define ROM_SIZE 131072u
#define RAM_SIZE (1024u*1024u)
#define RAM_ALT_BASE 0x00600000u
#define VIA_ORA 0x00efe200u
#define VIA_DDRA 0x00efe600u
#define OVERLAY_BIT 0x10u
static uint8_t rom[ROM_SIZE],ram[RAM_SIZE]; static uint8_t via_ora=OVERLAY_BIT,via_ddra; static int overlay=1;
static uint8_t rd8(uint32_t a){if(a==VIA_ORA)return via_ora;if(a==VIA_DDRA)return via_ddra;if(a>=ROM_BASE&&a<ROM_BASE+ROM_SIZE)return rom[a-ROM_BASE];if(a>=RAM_ALT_BASE&&a<RAM_ALT_BASE+RAM_SIZE)return ram[a-RAM_ALT_BASE];if(overlay&&a<ROM_SIZE)return rom[a];if(!overlay&&a<RAM_SIZE)return ram[a];return 0xff;}
static void wr8(uint32_t a,uint8_t v){if(a==VIA_DDRA){via_ddra=v;return;}if(a==VIA_ORA){via_ora=v;overlay=(v&OVERLAY_BIT)!=0;return;}if(a>=RAM_ALT_BASE&&a<RAM_ALT_BASE+RAM_SIZE){ram[a-RAM_ALT_BASE]=v;return;}if(!overlay&&a<RAM_SIZE)ram[a]=v;}
unsigned int m68k_read_memory_8(unsigned int a){return rd8(a);} unsigned int m68k_read_memory_16(unsigned int a){return ((unsigned)rd8(a)<<8)|rd8(a+1);} unsigned int m68k_read_memory_32(unsigned int a){return (m68k_read_memory_16(a)<<16)|m68k_read_memory_16(a+2);} void m68k_write_memory_8(unsigned int a,unsigned int v){wr8(a,(uint8_t)v);} void m68k_write_memory_16(unsigned int a,unsigned int v){wr8(a,v>>8);wr8(a+1,v);} void m68k_write_memory_32(unsigned int a,unsigned int v){m68k_write_memory_16(a,v>>16);m68k_write_memory_16(a+2,v);}
static uint32_t r32(uint32_t a){return ((uint32_t)ram[a]<<24)|((uint32_t)ram[a+1]<<16)|((uint32_t)ram[a+2]<<8)|ram[a+3];}
static uint16_t r16(uint32_t a){return (uint16_t)(((uint16_t)ram[a]<<8)|ram[a+1]);}
int main(int argc,char**argv){if(argc!=2)return 2;FILE*f=fopen(argv[1],"rb");if(!f)return 1;size_t n=fread(rom,1,sizeof rom,f);fclose(f);if(n!=sizeof rom)return 1;m68k_init();m68k_set_cpu_type(M68K_CPU_TYPE_68000);m68k_pulse_reset();unsigned cycles=0;while(cycles<600000u&&r32(0x424)!=0x4f4b3130u){int x=m68k_execute(64);cycles+=(unsigned)(x>0?x:64);}printf("LibreROM M3.10 runtime evidence\ncycles=%u\noverlay=%d\nmem_err=%04x\n",cycles,overlay,r16(0x220));if(overlay)return 1;if(r32(0x400)!=0x4d333130u||r32(0x404)!=0x5054314fu||r32(0x40c)!=0x5055314fu||r32(0x410)!=0x5253314fu||r32(0x414)!=0x4c4b314fu||r32(0x418)!=0x434c314fu||r32(0x41c)!=0x5354314fu||r32(0x420)!=0x4e49314fu||r32(0x424)!=0x4f4b3130u)return 1;if(r16(0x220)!=(uint16_t)0xff93u)return 1;puts("LibreROM M3.10 cumulative memory/state runtime qualification: PASS");return 0;}
