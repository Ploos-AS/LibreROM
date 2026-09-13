/* LibreROM M2.8 Macintosh Plus VIA Timer 1 interrupt bring-up.
 * Project-authored clean-room firmware code.
 *
 * Extends M2.7 with a real 6522 Timer 1 -> VIA IRQ -> 68000 level-1
 * autovector path. No Apple ROM code or system software is used.
 */

        .section .vectors,"a"
        .globl _m2_8_vectors
_m2_8_vectors:
        .long   0x00100000
        .long   _m2_8_reset

        .section .text,"ax"
        .globl _m2_8_reset
_m2_8_reset:
        move.w  #0x2700,%sr

        /* Non-destructive top-of-RAM probe through the alternate window. */
        move.l  #0x006ffffc,%a0
        move.l  (%a0),%d3
        move.l  #0xa55aa55a,(%a0)
        move.l  (%a0),%d2
        cmpi.l  #0xa55aa55a,%d2
        bne.w   _m2_8_ram_fail_alt
        move.l  %d3,(%a0)

        /* Install all 256 vectors in backing RAM before overlay removal. */
        move.l  #0x00600000,%a0
        move.l  #0x00100000,(%a0)+
        move.l  #_m2_8_reset,(%a0)+
        move.l  #_m2_8_default,%d0
        move.w  #253,%d1
1:
        move.l  %d0,(%a0)+
        dbra    %d1,1b

        /* 68000 level-1 autovector is vector 25 (25 * 4 = 0x64). */
        move.l  #0x00600064,%a0
        move.l  #_m2_8_via_irq,(%a0)

        move.l  #0x00600408,%a0
        move.l  #0x50524538,(%a0)       /* "PRE8" */

        .globl _m2_8_before_overlay_off
_m2_8_before_overlay_off:
        move.l  #0x00efe600,%a0
        move.b  (%a0),%d0
        ori.b   #0x10,%d0
        move.b  %d0,(%a0)

        move.l  #0x00efe200,%a0
        move.b  (%a0),%d0
        andi.b  #0xef,%d0
        move.b  %d0,(%a0)

        /* Verify low RAM vectors after the overlay hand-off. */
        move.l  #0x00000000,%a0
        move.l  (%a0)+,%d2
        cmpi.l  #0x00100000,%d2
        bne.w   _m2_8_ram_fail_low
        move.l  (%a0),%d2
        cmpi.l  #_m2_8_reset,%d2
        bne.w   _m2_8_ram_fail_low

        move.l  #0x00000400,%a0
        move.l  #0x4c524d38,(%a0)       /* "LRM8" */

        /* Qualification stack remains below both framebuffer regions. */
        move.l  #0x000f0000,%a7
        trap    #0

        /* Preserve the M2.7 visible framebuffer diagnostic. */
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
        move.l  #0x56494438,(%a0)       /* "VID8" */

        /*
         * VIA register mirror uses one register every 0x200 bytes:
         * T1CL=EFE800, T1CH=EFEA00, ACR=EFF600, IFR=EFFA00, IER=EFFC00.
         * Timer 1 interrupt is bit 6 (0x40). IER bit 7 selects set/clear.
         */
        move.l  #0x00eff600,%a0         /* ACR: Timer 1 one-shot */
        move.b  (%a0),%d0
        andi.b  #0xbf,%d0
        move.b  %d0,(%a0)

        move.l  #0x00effa00,%a0         /* IFR: clear pending T1 */
        move.b  #0x40,(%a0)

        move.l  #0x00effc00,%a0         /* IER: enable T1 */
        move.b  #0xc0,(%a0)

        move.l  #0x00efe800,%a0         /* T1 latch/counter low */
        move.b  #0x00,(%a0)
        move.l  #0x00efea00,%a0         /* T1 high write starts timer */
        move.b  #0x02,(%a0)             /* count = 0x0200 */

        /* Supervisor mode, IPL=0: permit VIA level-1 interrupt. */
        move.w  #0x2000,%sr
_m2_8_wait_irq:
        move.l  0x00000410,%d0
        cmpi.l  #0x49525138,%d0         /* "IRQ8" */
        bne.w   _m2_8_wait_irq

        move.w  #0x2700,%sr
        move.l  #0x00effc00,%a0         /* disable T1 interrupt */
        move.b  #0x40,(%a0)

        move.l  #0x00000414,%a0
        move.l  #0x544d5238,(%a0)       /* "TMR8" */

        .globl _m2_8_stop
_m2_8_stop:
        stop    #0x2700
        bra.w   _m2_8_stop

_m2_8_ram_fail_alt:
        move.l  #0x00600400,%a0
        move.l  #0x52414638,(%a0)       /* "RAF8" */
        stop    #0x2700
        bra.w   _m2_8_ram_fail_alt

_m2_8_ram_fail_low:
        move.l  #0x00000400,%a0
        move.l  #0x52414d38,(%a0)       /* "RAM8" */
        stop    #0x2700
        bra.w   _m2_8_ram_fail_low

        .globl _m2_8_default
_m2_8_default:
        move.l  #0x00000404,%a0
        move.l  #0x45584338,(%a0)       /* "EXC8" */
        rte

        .globl _m2_8_via_irq
_m2_8_via_irq:
        /* Reading T1 counter-low acknowledges/clears Timer 1 IFR. */
        move.l  #0x00efe800,%a0
        move.b  (%a0),%d0
        move.l  #0x00000410,%a0
        move.l  #0x49525138,(%a0)       /* "IRQ8" */
        rte

        .section .rodata,"a"
        .balign 4
_m2_8_marker:
        .ascii  "LIBREROM-M2.8-MACPLUS-VIA-T1-IRQ\0"
