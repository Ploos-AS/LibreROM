/* LibreROM M2.9 Macintosh Plus keyboard/VIA shift-register bring-up.
 * Project-authored clean-room firmware code.
 *
 * Extends machine bring-up with a deterministic keyboard model query over the
 * 6522 shift register. No Apple ROM code or system software is used.
 */

        .section .vectors,"a"
        .globl _m2_9_vectors
_m2_9_vectors:
        .long   0x00100000
        .long   _m2_9_reset

        .section .text,"ax"
        .globl _m2_9_reset
_m2_9_reset:
        move.w  #0x2700,%sr

        /* Non-destructive top-of-RAM probe through the alternate window. */
        move.l  #0x006ffffc,%a0
        move.l  (%a0),%d3
        move.l  #0xa55aa55a,(%a0)
        move.l  (%a0),%d2
        cmpi.l  #0xa55aa55a,%d2
        bne.w   _m2_9_ram_fail_alt
        move.l  %d3,(%a0)

        /* Install all 256 vectors in backing RAM before overlay removal. */
        move.l  #0x00600000,%a0
        move.l  #0x00100000,(%a0)+
        move.l  #_m2_9_reset,(%a0)+
        move.l  #_m2_9_default,%d0
        move.w  #253,%d1
1:
        move.l  %d0,(%a0)+
        dbra    %d1,1b

        /* VIA is 68000 level 1, autovector 25. */
        move.l  #0x00600064,%a0
        move.l  #_m2_9_via_irq,(%a0)

        move.l  #0x00600408,%a0
        move.l  #0x50524539,(%a0)       /* PRE9 */

        .globl _m2_9_before_overlay_off
_m2_9_before_overlay_off:
        move.l  #0x00efe600,%a0
        move.b  (%a0),%d0
        ori.b   #0x10,%d0
        move.b  %d0,(%a0)

        move.l  #0x00efe200,%a0
        move.b  (%a0),%d0
        andi.b  #0xef,%d0
        move.b  %d0,(%a0)

        move.l  #0x00000000,%a0
        move.l  (%a0)+,%d2
        cmpi.l  #0x00100000,%d2
        bne.w   _m2_9_ram_fail_low
        move.l  (%a0),%d2
        cmpi.l  #_m2_9_reset,%d2
        bne.w   _m2_9_ram_fail_low

        move.l  #0x00000400,%a0
        move.l  #0x4c524d39,(%a0)       /* LRM9 */
        move.l  #0x000f0000,%a7
        trap    #0

        /* Preserve framebuffer bring-up regression from M2.7/M2.8. */
        move.w  #0xaa55,%d0
        move.w  #10943,%d1
        move.l  #0x000fa700,%a0
2:
        move.w  %d0,(%a0)+
        dbra    %d1,2b
        move.w  #10943,%d1
        move.l  #0x000f2700,%a0
3:
        move.w  %d0,(%a0)+
        dbra    %d1,3b
        move.l  #0x0000040c,%a0
        move.l  #0x56494439,(%a0)       /* VID9 */

        /*
         * Mac Plus keyboard path:
         *   CB1 = keyboard clock, CB2 = keyboard data, SR = data ready.
         * PCE's independent model uses ACR mode 0x1c for shift-out and 0x0c
         * for shift-in with external clock. SR is register 10 at EFF400.
         * Keyboard command 0x16 requests the model number.
         */
        move.l  #0x00effc00,%a0         /* disable all VIA IRQ sources */
        move.b  #0x7f,(%a0)
        move.l  #0x00effa00,%a0         /* clear pending SR flag */
        move.b  #0x04,(%a0)

        move.l  #0x00eff600,%a0         /* ACR: shift out ext clock */
        move.b  (%a0),%d0
        andi.b  #0xe3,%d0
        ori.b   #0x1c,%d0
        move.b  %d0,(%a0)

        move.l  #0x00eff400,%a0         /* SR: keyboard model query */
        move.b  #0x16,(%a0)

        move.l  #0x00eff600,%a0         /* ACR: shift in ext clock */
        move.b  (%a0),%d0
        andi.b  #0xe3,%d0
        ori.b   #0x0c,%d0
        move.b  %d0,(%a0)

        move.l  #0x00effc00,%a0         /* enable SR interrupt */
        move.b  #0x84,(%a0)

        move.w  #0x2000,%sr
_m2_9_wait_keyboard:
        move.l  0x0000041c,%d0
        cmpi.l  #0x4b424439,%d0         /* KBD9 */
        bne.w   _m2_9_wait_keyboard

        move.w  #0x2700,%sr
        move.l  #0x00effc00,%a0         /* disable SR IRQ */
        move.b  #0x04,(%a0)
        move.l  #0x00000420,%a0
        move.l  #0x494e5039,(%a0)       /* INP9 */

        .globl _m2_9_stop
_m2_9_stop:
        stop    #0x2700
        bra.w   _m2_9_stop

_m2_9_ram_fail_alt:
        move.l  #0x00600400,%a0
        move.l  #0x52414639,(%a0)       /* RAF9 */
        stop    #0x2700
        bra.w   _m2_9_ram_fail_alt

_m2_9_ram_fail_low:
        move.l  #0x00000400,%a0
        move.l  #0x52414d39,(%a0)       /* RAM9 */
        stop    #0x2700
        bra.w   _m2_9_ram_fail_low

        .globl _m2_9_default
_m2_9_default:
        move.l  #0x00000404,%a0
        move.l  #0x45584339,(%a0)       /* EXC9 */
        rte

        .globl _m2_9_via_irq
_m2_9_via_irq:
        move.l  #0x00effa00,%a0         /* IFR */
        move.b  (%a0),%d0
        andi.b  #0x04,%d0               /* SR source? */
        beq.w   _m2_9_via_irq_done
        move.l  #0x00eff400,%a0         /* reading SR clears SR IFR */
        move.b  (%a0),%d0
        move.l  #0x00000418,%a0
        move.b  %d0,(%a0)               /* captured keyboard response */
        move.l  #0x0000041c,%a0
        move.l  #0x4b424439,(%a0)       /* KBD9 */
_m2_9_via_irq_done:
        rte

        .section .rodata,"a"
        .balign 4
_m2_9_marker:
        .ascii  "LIBREROM-M2.9-MACPLUS-KEYBOARD-SR\0"
