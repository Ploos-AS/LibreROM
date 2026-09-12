#ifndef LIBREROM_PLATFORM_MACPLUS_MEMORY_MAP_H
#define LIBREROM_PLATFORM_MACPLUS_MEMORY_MAP_H

/* LibreROM Macintosh Plus M2 machine profile.
 * Project-authored constants derived from public hardware documentation and
 * independently implemented emulator models. No Apple ROM material is used.
 */

#define MACPLUS_ROM_BASE          0x00400000UL
#define MACPLUS_ROM_SIZE          0x00020000UL /* 128 KiB target */
#define MACPLUS_SCSI_BASE         0x00580000UL
#define MACPLUS_SCSI_END          0x005fffffUL
#define MACPLUS_RAM_ALT_BASE      0x00600000UL
#define MACPLUS_RAM_ALT_END       0x006fffffUL
#define MACPLUS_SCC_READ_BASE     0x00800000UL
#define MACPLUS_SCC_READ_END      0x009fffffUL
#define MACPLUS_SCC_WRITE_BASE    0x00a00000UL
#define MACPLUS_SCC_WRITE_END     0x00bfffffUL
#define MACPLUS_IWM_BASE          0x00c00000UL
#define MACPLUS_IWM_END           0x00dfffffUL
#define MACPLUS_VIA_BASE          0x00e80000UL
#define MACPLUS_VIA_END           0x00efffffUL

#define MACPLUS_FB_WIDTH          512U
#define MACPLUS_FB_HEIGHT         342U
#define MACPLUS_FB_BPP            1U
#define MACPLUS_QUAL_RAM_BYTES    (1024UL * 1024UL)

#endif
