/* LibreROM M2.3 Macintosh Plus reset path.
 *
 * Project-authored clean-room bring-up code. The reset overlay supplies the
 * first vector reads at low memory, while execution immediately continues from
 * the fixed Macintosh Plus ROM window at 0x00400000.
 */

        .section .vectors,"a"
        .globl _m2_3_vectors
_m2_3_vectors:
        .long   0x00100000      /* initial SSP: top of 1 MiB qualification RAM */
        .long   _m2_3_reset     /* canonical ROM address, not low overlay alias */

        .section .text,"ax"
        .globl _m2_3_reset
_m2_3_reset:
        move.w  #0x2700,%sr     /* supervisor, interrupts masked */

        /* VIA DDRA at canonical Mac Plus mirror $EFE600. Make A4 an output. */
        move.l  #0x00efe600,%a0
        move.b  (%a0),%d0
        ori.b   #0x10,%d0
        move.b  %d0,(%a0)

        /* VIA ORA at $EFE200. Clear A4 to remove the reset ROM overlay. */
        move.l  #0x00efe200,%a0
        move.b  (%a0),%d0
        andi.b  #0xef,%d0
        move.b  %d0,(%a0)

        /* Low memory must now be RAM. Leave an observable qualification word. */
        move.l  #0x00000100,%a0
        move.l  #0x4c524d33,(%a0)       /* ASCII "LRM3" */

        .globl _m2_3_stop
_m2_3_stop:
        stop    #0x2700
        bra.s   _m2_3_stop

        .section .rodata,"a"
        .balign 4
        .globl _m2_3_marker
_m2_3_marker:
        .ascii  "LIBREROM-M2.3-MACPLUS\0"
