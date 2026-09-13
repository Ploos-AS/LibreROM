#ifndef LIBREROM_PLATFORM_MACPLUS_VIA_OVERLAY_H
#define LIBREROM_PLATFORM_MACPLUS_VIA_OVERLAY_H

#include "memory_map.h"

/* Early compact Macintosh machines use VIA port A bit 4 to control
 * the low-memory ROM overlay. 1 = ROM visible at $000000, 0 = RAM visible.
 *
 * The Macintosh Plus decodes the VIA throughout the $E80000-$EFFFFF window,
 * with one VIA register every 0x200 bytes. Use the final 8 KiB mirror at
 * $EFE000 because it is accepted by independent emulators including PCE,
 * while remaining inside the documented hardware decode window.
 */
#define MACPLUS_VIA_CANONICAL_BASE    0x00efe000UL
#define MACPLUS_VIA_REG_STRIDE        0x00000200UL
#define MACPLUS_VIA_ORA_REG           1UL
#define MACPLUS_VIA_DDRA_REG          3UL
#define MACPLUS_VIA_ORA_ADDR          (MACPLUS_VIA_CANONICAL_BASE + (MACPLUS_VIA_ORA_REG * MACPLUS_VIA_REG_STRIDE))
#define MACPLUS_VIA_DDRA_ADDR         (MACPLUS_VIA_CANONICAL_BASE + (MACPLUS_VIA_DDRA_REG * MACPLUS_VIA_REG_STRIDE))
#define MACPLUS_VIA_OVERLAY_BIT       0x10U

static inline unsigned char macplus_overlay_enabled(unsigned char via_port_a)
{
    return (via_port_a & MACPLUS_VIA_OVERLAY_BIT) ? 1U : 0U;
}

static inline unsigned char macplus_overlay_disable_value(unsigned char via_port_a)
{
    return (unsigned char)(via_port_a & (unsigned char)~MACPLUS_VIA_OVERLAY_BIT);
}

#endif
