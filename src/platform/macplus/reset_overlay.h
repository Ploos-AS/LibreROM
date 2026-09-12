#ifndef LIBREROM_PLATFORM_MACPLUS_RESET_OVERLAY_H
#define LIBREROM_PLATFORM_MACPLUS_RESET_OVERLAY_H

#include "memory_map.h"

/* M2.1 architectural reset-overlay contract.
 *
 * The exact VIA-side hardware operation that removes the reset overlay is
 * intentionally not encoded here yet. M2.1 qualifies ordering and state
 * ownership first; the hardware-facing control is the next qualification gate.
 */

#define MACPLUS_LOW_MEMORY_BASE        0x00000000UL
#define MACPLUS_RESET_VECTOR_BYTES     8UL
#define MACPLUS_RESET_OVERLAY_ACTIVE   1U
#define MACPLUS_RESET_OVERLAY_INACTIVE 0U

struct macplus_reset_vectors {
    unsigned long initial_ssp;
    unsigned long initial_pc;
};

#endif
