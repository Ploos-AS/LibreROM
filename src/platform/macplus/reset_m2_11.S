/* LibreROM M2.11 Macintosh Plus IWM/media-sense bring-up.
 * Project-authored clean-room firmware code.
 *
 * Extends the cumulative Mac Plus bring-up with a deterministic IWM status
 * probe. The probe selects sense bank 8 (disk inserted) and records both the
 * raw IWM status byte and a project-owned marker for present/absent media.
 */

        .section .vectors,"a"
        .globl _m2_11_vectors
_m2_11_vectors:
        .long   0x00100000
        .long   _m2_11_reset

        .section .text,"ax"
        .globl _m2_11_reset
_m2_11_reset:
        move.w  #0x2700,%sr

        /* Non-destructive top-of-RAM probe through the alternate window. */
        move.l  #0x006ffffc,%a0
        move.l  (%a0),%d3
        move.l  #0xa55aa55a,(%a0)
        move.l  (%a0),%d2
        cmpi.l  #0xa55aa55a,%d2
        bne.w   _m2_11_ram_fail_alt
        move.l  %d3,(%a0)

        /* Install all 256 vectors in backing RAM before overlay removal. */
        move.l  #0x00600000,%a0
        move.l  #0x00100000,(%a0)+
        move.l  #_m2_11_reset,(%a0)+
        move.l  #_m2_11_default,%d0
        move.w  #253,%d1
1:
        move.l  %d0,(%a0)+
        dbra    %d1,1b

        /* VIA is 68000 level 1, autovector 25. */
        move.l  #0x00600064,%a0
        move.l  #_m2_11_via_irq,(%a0)

        move.l  #0x00600408,%a0
        move.l  #0x50523131,(%a0)       /* PR11 */

        .globl _m2_11_before_overlay_off
_m2_11_before_overlay_off:
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
        bne.w   _m2_11_ram_fail_low
        move.l  (%a0),%d2
        cmpi.l  #_m2_11_reset,%d2
        bne.w   _m2_11_ram_fail_low

        move.l  #0x00000400,%a0
        move.l  #0x4c523131,(%a0)       /* LR11 */
        move.l  #0x000f0000,%a7
        trap    #0

        /* Preserve framebuffer bring-up regression. */
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
        move.l  #0x56493131,(%a0)       /* VI11 */

        /* Preserve the M2.9 keyboard model query regression. */
        move.l  #0x00effc00,%a0
        move.b  #0x7f,(%a0)
        move.l  #0x00effa00,%a0
        move.b  #0x04,(%a0)
        move.l  #0x00eff600,%a0
        move.b  (%a0),%d0
        andi.b  #0xe3,%d0
        ori.b   #0x1c,%d0
        move.b  %d0,(%a0)
        move.l  #0x00eff400,%a0
        move.b  #0x16,(%a0)
        move.l  #0x00eff600,%a0
        move.b  (%a0),%d0
        andi.b  #0xe3,%d0
        ori.b   #0x0c,%d0
        move.b  %d0,(%a0)
        move.l  #0x00effc00,%a0
        move.b  #0x84,(%a0)
        move.w  #0x2000,%sr
_m2_11_wait_keyboard:
        move.l  0x0000041c,%d0
        cmpi.l  #0x4b423131,%d0         /* KB11 */
        bne.w   _m2_11_wait_keyboard
        move.w  #0x2700,%sr
        move.l  #0x00effc00,%a0
        move.b  #0x04,(%a0)
        move.l  #0x00000420,%a0
        move.l  #0x494e3131,(%a0)       /* IN11 */

        /* IWM media sense bank 8. */
        move.l  #0x00efe600,%a0         /* VIA DDRA */
        move.b  (%a0),%d6
        move.b  %d6,%d0
        ori.b   #0x20,%d0
        move.b  %d0,(%a0)

        move.l  #0x00efe200,%a0
        move.b  (%a0),%d0
        andi.b  #0xdf,%d0
        move.b  %d0,(%a0)
        ori.b   #0x20,%d0
        move.b  %d0,(%a0)

        move.b  0x00c00001,%d0
        move.b  0x00c00401,%d0
        move.b  0x00c00801,%d0
        move.b  0x00c01c01,%d0
        move.b  0x00c01a01,%d0

        move.l  #0x00000424,%a0
        move.b  %d0,(%a0)
        btst    #7,%d0
        bne.w   _m2_11_no_media

        move.l  #0x00000428,%a0
        move.l  #0x49574d50,(%a0)       /* IWMP */

        /* M2.11 raw data path: motor on, ENABLE=1, Q6=Q7=0. */
        move.l  #0x00efe200,%a0
        move.b  (%a0),%d0
        andi.b  #0xdf,%d0               /* head 0 */
        move.b  %d0,(%a0)

        move.b  0x00c00001,%d0         /* CA0 low */
        move.b  0x00c00601,%d0         /* CA1 high: control reg 2 */
        move.b  0x00c00801,%d0         /* CA2 low: motor on */
        move.b  0x00c00e01,%d0         /* LSTRB high */
        move.b  0x00c00c01,%d0         /* LSTRB low */
        move.b  0x00c01201,%d0         /* ENABLE high */
        move.b  0x00c01801,%d0         /* Q6 low */
        move.b  0x00c01c01,%d0         /* Q7 low */

        move.l  #0x00000430,%a1
        moveq   #15,%d4                 /* capture 16 GCR bytes */
        move.l  #0x00040000,%d5
_m2_11_read_poll:
        move.b  0x00c01801,%d0
        btst    #7,%d0
        beq.s   _m2_11_read_wait
        move.b  %d0,(%a1)+
        dbra    %d4,_m2_11_read_poll
        bra.s   _m2_11_read_ok
_m2_11_read_wait:
        subq.l  #1,%d5
        bne.s   _m2_11_read_poll
        bra.s   _m2_11_read_fail

_m2_11_read_ok:
        move.l  #0x00000440,%a0
        move.l  #0x44415431,(%a0)       /* DAT1 */
        bra.s   _m2_11_read_done

_m2_11_read_fail:
        move.l  #0x00000440,%a0
        move.l  #0x52444631,(%a0)       /* RDF1 */

_m2_11_read_done:
        move.l  #0x0000042c,%a0
        move.l  #0x49574d31,(%a0)       /* IWM1 */

        /* Stop drive and restore VIA direction. */
        move.b  0x00c01001,%d0         /* ENABLE low */
        move.b  0x00c00001,%d0
        move.b  0x00c00601,%d0
        move.b  0x00c00a01,%d0         /* CA2 high: motor off */
        move.b  0x00c00e01,%d0
        move.b  0x00c00c01,%d0
        move.l  #0x00efe600,%a0
        move.b  %d6,(%a0)
        bra.w   _m2_11_stop

_m2_11_no_media:
        move.l  #0x00000428,%a0
        move.l  #0x49574d4e,(%a0)       /* IWMN */
        move.l  #0x00000440,%a0
        move.l  #0x4e4f4431,(%a0)       /* NOD1 */
        move.l  #0x0000042c,%a0
        move.l  #0x49574d31,(%a0)       /* IWM1 */
        move.l  #0x00efe200,%a0
        move.b  (%a0),%d0
        andi.b  #0xdf,%d0
        move.b  %d0,(%a0)
        move.l  #0x00efe600,%a0
        move.b  %d6,(%a0)

        .globl _m2_11_stop
_m2_11_stop:
        stop    #0x2700
        bra.w   _m2_11_stop

_m2_11_ram_fail_alt:
        move.l  #0x00600400,%a0
        move.l  #0x52413131,(%a0)       /* RA11 */
        stop    #0x2700
        bra.w   _m2_11_ram_fail_alt

_m2_11_ram_fail_low:
        move.l  #0x00000400,%a0
        move.l  #0x524d3131,(%a0)       /* RM11 */
        stop    #0x2700
        bra.w   _m2_11_ram_fail_low

        .globl _m2_11_default
_m2_11_default:
        move.l  #0x00000404,%a0
        move.l  #0x45583131,(%a0)       /* EX11 */
        rte

        .globl _m2_11_via_irq
_m2_11_via_irq:
        move.l  #0x00effa00,%a0
        move.b  (%a0),%d0
        andi.b  #0x04,%d0
        beq.w   _m2_11_via_irq_done
        move.l  #0x00eff400,%a0
        move.b  (%a0),%d0
        move.l  #0x00000418,%a0
        move.b  %d0,(%a0)
        move.l  #0x0000041c,%a0
        move.l  #0x4b423131,(%a0)       /* KB11 */
_m2_11_via_irq_done:
        rte

        .section .rodata,"a"
        .balign 4
_m2_11_marker:
        .ascii  "LIBREROM-M2.11-MACPLUS-IWM-READ\0"
