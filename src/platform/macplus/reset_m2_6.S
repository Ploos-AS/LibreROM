/* LibreROM M2.6 Macintosh Plus ordered reset-overlay hand-off.
 * Project-authored clean-room firmware code.
 *
 * The Macintosh Plus reset overlay hides low RAM behind ROM. Backing RAM is
 * populated through its alternate 0x00600000 window before VIA A4 removes the
 * overlay. After the transition, the same RAM/vector table is visible at zero.
 */

        .section .vectors,"a"
        .globl _m2_6_vectors
_m2_6_vectors:
        .long   0x00100000
        .long   _m2_6_reset

        .section .text,"ax"
        .globl _m2_6_reset
_m2_6_reset:
        move.w  #0x2700,%sr

        /* Probe the top longword through the alternate RAM window. */
        move.l  #0x006ffffc,%a0
        move.l  (%a0),%d3
        move.l  #0xa55aa55a,(%a0)
        move.l  (%a0),%d2
        cmpi.l  #0xa55aa55a,%d2
        bne.s   _m2_6_ram_fail_alt
        move.l  %d3,(%a0)

        /*
         * Install all 256 vectors into backing RAM while ROM still owns low
         * memory. The 1 MiB RAM profile is mirrored at 0x00600000.
         */
        move.l  #0x00600000,%a0
        move.l  #0x00100000,(%a0)+
        move.l  #_m2_6_reset,(%a0)+
        move.l  #_m2_6_default,%d0
        move.w  #253,%d1
1:
        move.l  %d0,(%a0)+
        dbra    %d1,1b

        /* Persistent evidence written before the overlay transition. */
        move.l  #0x00600408,%a0
        move.l  #0x50524536,(%a0)       /* "PRE6" */

        .globl _m2_6_before_overlay_off
_m2_6_before_overlay_off:
        /* Configure VIA A4 as output. PCE-compatible canonical VIA mirror. */
        move.l  #0x00efe600,%a0
        move.b  (%a0),%d0
        ori.b   #0x10,%d0
        move.b  %d0,(%a0)

        /* Clear VIA port A bit 4: RAM becomes visible at low memory. */
        move.l  #0x00efe200,%a0
        move.b  (%a0),%d0
        andi.b  #0xef,%d0
        move.b  %d0,(%a0)

        /* Verify the preinstalled reset vector pair through the low alias. */
        move.l  #0x00000000,%a0
        move.l  (%a0)+,%d2
        cmpi.l  #0x00100000,%d2
        bne.s   _m2_6_ram_fail_low
        move.l  (%a0),%d2
        cmpi.l  #_m2_6_reset,%d2
        bne.s   _m2_6_ram_fail_low

        /* Observable post-hand-off marker; PRE6 at 0x408 must remain intact. */
        move.l  #0x00000400,%a0
        move.l  #0x4c524d36,(%a0)       /* "LRM6" */

        move.l  #0x000ff000,%a7
        trap    #0

_m2_6_ram_fail_alt:
        /* Overlay is still active here, so report through alternate RAM. */
        move.l  #0x00600400,%a0
        move.l  #0x52414636,(%a0)       /* "RAF6" */
        stop    #0x2700
        bra.s   _m2_6_ram_fail_alt

_m2_6_ram_fail_low:
        move.l  #0x00000400,%a0
        move.l  #0x52414d36,(%a0)       /* "RAM6" */
        stop    #0x2700
        bra.s   _m2_6_ram_fail_low

        .globl _m2_6_default
_m2_6_default:
        move.l  #0x00000404,%a0
        move.l  #0x45584336,(%a0)       /* "EXC6" */

        .globl _m2_6_stop
_m2_6_stop:
        stop    #0x2700
        bra.s   _m2_6_stop

        .section .rodata,"a"
        .balign 4
_m2_6_marker:
        .ascii  "LIBREROM-M2.6-MACPLUS\0"
