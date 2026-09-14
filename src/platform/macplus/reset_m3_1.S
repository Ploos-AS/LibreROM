/* LibreROM M3.1 Macintosh Plus firmware-service table foundation.
 * Project-authored clean-room firmware code.
 *
 * Extends M3.0 from one diagnostic A-line opcode to a tiny explicit
 * LibreROM-private service ABI. These opcodes are qualification services,
 * not claims of Apple Toolbox compatibility.
 *
 * ABI:
 *   0xA0F0 LR_SVC_PING: no input, D0 = 'LR31'
 *   0xA0F1 LR_SVC_ADD:  D0,D1 input, D0 = D0 + D1
 * Dispatcher scratch: D2, A0. Other registers are preserved by these
 * two services.
 */

        .equ    LR_SVC_PING, 0xa0f0
        .equ    LR_SVC_ADD,  0xa0f1
        .equ    LR_PING_RET, 0x4c523331      /* "LR31" */

        .section .vectors,"a"
        .globl _m3_1_vectors
_m3_1_vectors:
        .long   0x00100000
        .long   _m3_1_reset

        .section .text,"ax"
        .globl _m3_1_reset
_m3_1_reset:
        move.w  #0x2700,%sr

        /* Non-destructive top-of-RAM probe through the alternate window. */
        move.l  #0x006ffffc,%a0
        move.l  (%a0),%d3
        move.l  #0xa55aa55a,(%a0)
        move.l  (%a0),%d2
        cmpi.l  #0xa55aa55a,%d2
        bne.w   _m3_1_ram_fail_alt
        move.l  %d3,(%a0)

        /* Install all 256 vectors in backing RAM before overlay removal. */
        move.l  #0x00600000,%a0
        move.l  #0x00100000,(%a0)+
        move.l  #_m3_1_reset,(%a0)+
        move.l  #_m3_1_default,%d0
        move.w  #253,%d1
1:
        move.l  %d0,(%a0)+
        dbra    %d1,1b

        /* 68000 line-1010 emulator exception: vector 10, offset 0x28. */
        move.l  #0x00600028,%a0
        move.l  #_m3_1_aline,(%a0)

        move.l  #0x00600408,%a0
        move.l  #0x50523331,(%a0)       /* "PR31" */

        .globl _m3_1_before_overlay_off
_m3_1_before_overlay_off:
        move.l  #0x00efe600,%a0
        move.b  (%a0),%d0
        ori.b   #0x10,%d0
        move.b  %d0,(%a0)

        move.l  #0x00efe200,%a0
        move.b  (%a0),%d0
        andi.b  #0xef,%d0
        move.b  %d0,(%a0)

        /* Verify low RAM vectors after overlay removal. */
        move.l  #0x00000000,%a0
        move.l  (%a0)+,%d2
        cmpi.l  #0x00100000,%d2
        bne.w   _m3_1_ram_fail_low
        move.l  (%a0),%d2
        cmpi.l  #_m3_1_reset,%d2
        bne.w   _m3_1_ram_fail_low
        move.l  0x00000028,%d2
        cmpi.l  #_m3_1_aline,%d2
        bne.w   _m3_1_ram_fail_low

        move.l  #0x000f0000,%a7
        move.l  #0x4d333130,0x00000400  /* "M310" */

        /* Service 0: no-input ping. */
        .word   LR_SVC_PING
        cmpi.l  #LR_PING_RET,%d0
        bne.w   _m3_1_service_fail
        move.l  #0x504e4731,0x00000404  /* "PNG1" */

        /* Service 1: register ABI proof, 7 + 5 -> 12. */
        moveq   #7,%d0
        moveq   #5,%d1
        .word   LR_SVC_ADD
        cmpi.l  #12,%d0
        bne.w   _m3_1_service_fail
        move.l  #0x41444431,0x0000040c  /* "ADD1" */

        move.l  #0x4f4b3331,0x00000410  /* "OK31" */

        .globl _m3_1_stop
_m3_1_stop:
        stop    #0x2700
        bra.w   _m3_1_stop

_m3_1_ram_fail_alt:
        move.l  #0x52414631,0x00600400  /* "RAF1" */
        stop    #0x2700
        bra.w   _m3_1_ram_fail_alt

_m3_1_ram_fail_low:
        move.l  #0x52414d31,0x00000400  /* "RAM1" */
        stop    #0x2700
        bra.w   _m3_1_ram_fail_low

_m3_1_service_fail:
        move.l  #0x53564631,0x00000410  /* "SVF1" */
        stop    #0x2700
        bra.w   _m3_1_service_fail

        .globl _m3_1_default
_m3_1_default:
        move.l  #0x45584331,0x00000414  /* "EXC1" */
        rte

        .globl _m3_1_aline
_m3_1_aline:
        /* Saved PC points at the offending A-line opcode on 68000. */
        move.l  2(%a7),%a0
        move.w  (%a0),%d2
        addq.l  #2,2(%a7)

        cmpi.w  #LR_SVC_PING,%d2
        beq.s   _m3_1_service_ping
        cmpi.w  #LR_SVC_ADD,%d2
        beq.s   _m3_1_service_add
        bra.s   _m3_1_unknown_aline

_m3_1_service_ping:
        move.l  #0x44535031,0x00000418  /* "DSP1" */
        move.l  #LR_PING_RET,%d0
        rte

_m3_1_service_add:
        add.l   %d1,%d0
        move.l  #0x53564331,0x0000041c  /* "SVC1" */
        rte

_m3_1_unknown_aline:
        move.l  #0x42414431,0x00000420  /* "BAD1" */
        stop    #0x2700
        bra.w   _m3_1_unknown_aline

        .section .rodata,"a"
        .balign 4
_m3_1_marker:
        .ascii  "LIBREROM-M3.1-SERVICE-TABLE\0"
