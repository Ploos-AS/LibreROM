/* LibreROM M2.10 Macintosh Plus IWM/media-sense bring-up.
 * Project-authored clean-room firmware code.
 *
 * Extends the cumulative Mac Plus bring-up with a deterministic IWM status
 * probe. The probe selects sense bank 8 (disk inserted) and records both the
 * raw IWM status byte and a project-owned marker for present/absent media.
 */

        .section .vectors,"a"
        .globl _m2_10_vectors
_m2_10_vectors:
        .long   0x00100000
        .long   _m2_10_reset

        .section .text,"ax"
        .globl _m2_10_reset
_m2_10_reset:
        move.w  #0x2700,%sr

        /* Non-destructive top-of-RAM probe through the alternate window. */
        move.l  #0x006ffffc,%a0
        move.l  (%a0),%d3
        move.l  #0xa55aa55a,(%a0)
        move.l  (%a0),%d2
        cmpi.l  #0xa55aa55a,%d2
        bne.w   _m2_10_ram_fail_alt
        move.l  %d3,(%a0)

        /* Install all 256 vectors in backing RAM before overlay removal. */
        move.l  #0x00600000,%a0
        move.l  #0x00100000,(%a0)+
        move.l  #_m2_10_reset,(%a0)+
        move.l  #_m2_10_default,%d0
        move.w  #253,%d1
1:
        move.l  %d0,(%a0)+
        dbra    %d1,1b

        /* VIA is 68000 level 1, autovector 25. */
        move.l  #0x00600064,%a0
        move.l  #_m2_10_via_irq,(%a0)

        move.l  #0x00600408,%a0
        move.l  #0x50523130,(%a0)       /* PR10 */

        .globl _m2_10_before_overlay_off
_m2_10_before_overlay_off:
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
        bne.w   _m2_10_ram_fail_low
        move.l  (%a0),%d2
        cmpi.l  #_m2_10_reset,%d2
        bne.w   _m2_10_ram_fail_low

        move.l  #0x00000400,%a0
        move.l  #0x4c523130,(%a0)       /* LR10 */
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
        move.l  #0x56493130,(%a0)       /* VI10 */

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
_m2_10_wait_keyboard:
        move.l  0x0000041c,%d0
        cmpi.l  #0x4b423130,%d0         /* KB10 */
        bne.w   _m2_10_wait_keyboard
        move.w  #0x2700,%sr
        move.l  #0x00effc00,%a0
        move.b  #0x04,(%a0)
        move.l  #0x00000420,%a0
        move.l  #0x494e3130,(%a0)       /* IN10 */

        /*
         * IWM media sense.
         *
         * PCE models the classic Mac IWM soft-switch decode on odd byte
         * addresses with one switch every 0x200 bytes. VIA Port A bit 5
         * selects sense bank 8 when CA0..CA2 are all low. Because a 6522
         * only drives ORA bits whose DDRA bits are outputs, A5 must be made
         * an output for the duration of this probe. With Q7=0,Q6=1, reads
         * return IWM status; bit 7 is 1 for no media and 0 for inserted media
         * in sense bank 8.
         */
        move.l  #0x00efe600,%a0         /* VIA DDRA */
        move.b  (%a0),%d6               /* preserve caller-visible direction */
        move.b  %d6,%d0
        ori.b   #0x20,%d0               /* A5 = output */
        move.b  %d0,(%a0)

        move.l  #0x00efe200,%a0         /* VIA ORA: select sense bank 8 */
        move.b  (%a0),%d0
        ori.b   #0x20,%d0
        move.b  %d0,(%a0)

        move.b  0x00c00001,%d0         /* CA0 low */
        move.b  0x00c00401,%d0         /* CA1 low */
        move.b  0x00c00801,%d0         /* CA2 low */
        move.b  0x00c01c01,%d0         /* Q7 low */
        move.b  0x00c01a01,%d0         /* Q6 high + read status */

        move.l  #0x00000424,%a0
        move.b  %d0,(%a0)               /* raw IWM status */
        btst    #7,%d0
        bne.s   _m2_10_no_media

        move.l  #0x00000428,%a0
        move.l  #0x49574d50,(%a0)       /* IWMP: media present */
        bra.s   _m2_10_iwm_done

_m2_10_no_media:
        move.l  #0x00000428,%a0
        move.l  #0x49574d4e,(%a0)       /* IWMN: no media */

_m2_10_iwm_done:
        move.l  #0x0000042c,%a0
        move.l  #0x49574d30,(%a0)       /* IWM0: probe completed */

        /* Restore VIA Port A sense select and original data direction. */
        move.l  #0x00efe200,%a0
        move.b  (%a0),%d0
        andi.b  #0xdf,%d0
        move.b  %d0,(%a0)
        move.l  #0x00efe600,%a0
        move.b  %d6,(%a0)

        .globl _m2_10_stop
_m2_10_stop:
        stop    #0x2700
        bra.w   _m2_10_stop

_m2_10_ram_fail_alt:
        move.l  #0x00600400,%a0
        move.l  #0x52413130,(%a0)       /* RA10 */
        stop    #0x2700
        bra.w   _m2_10_ram_fail_alt

_m2_10_ram_fail_low:
        move.l  #0x00000400,%a0
        move.l  #0x524d3130,(%a0)       /* RM10 */
        stop    #0x2700
        bra.w   _m2_10_ram_fail_low

        .globl _m2_10_default
_m2_10_default:
        move.l  #0x00000404,%a0
        move.l  #0x45583130,(%a0)       /* EX10 */
        rte

        .globl _m2_10_via_irq
_m2_10_via_irq:
        move.l  #0x00effa00,%a0
        move.b  (%a0),%d0
        andi.b  #0x04,%d0
        beq.w   _m2_10_via_irq_done
        move.l  #0x00eff400,%a0
        move.b  (%a0),%d0
        move.l  #0x00000418,%a0
        move.b  %d0,(%a0)
        move.l  #0x0000041c,%a0
        move.l  #0x4b423130,(%a0)       /* KB10 */
_m2_10_via_irq_done:
        rte

        .section .rodata,"a"
        .balign 4
_m2_10_marker:
        .ascii  "LIBREROM-M2.10-MACPLUS-IWM-SENSE\0"
