/* LibreROM M3.0 Macintosh Plus firmware-service foundation.
 * Project-authored clean-room firmware code.
 *
 * Establishes a minimal 68000 A-line dispatcher using vector 10. The only
 * service implemented here is a LibreROM-private diagnostic opcode used to
 * qualify the dispatch mechanism; it is not presented as an Apple-compatible
 * OS or Toolbox trap.
 */

        .equ    LR_DIAG_TRAP, 0xa0f0
        .equ    LR_DIAG_RET,  0x4c523330      /* "LR30" */

        .section .vectors,"a"
        .globl _m3_0_vectors
_m3_0_vectors:
        .long   0x00100000
        .long   _m3_0_reset

        .section .text,"ax"
        .globl _m3_0_reset
_m3_0_reset:
        move.w  #0x2700,%sr

        /* Non-destructive top-of-RAM probe through the alternate window. */
        move.l  #0x006ffffc,%a0
        move.l  (%a0),%d3
        move.l  #0xa55aa55a,(%a0)
        move.l  (%a0),%d2
        cmpi.l  #0xa55aa55a,%d2
        bne.w   _m3_0_ram_fail_alt
        move.l  %d3,(%a0)

        /* Install all 256 vectors in backing RAM before overlay removal. */
        move.l  #0x00600000,%a0
        move.l  #0x00100000,(%a0)+
        move.l  #_m3_0_reset,(%a0)+
        move.l  #_m3_0_default,%d0
        move.w  #253,%d1
1:
        move.l  %d0,(%a0)+
        dbra    %d1,1b

        /* 68000 line-1010 emulator exception: vector 10, offset 0x28. */
        move.l  #0x00600028,%a0
        move.l  #_m3_0_aline,(%a0)

        move.l  #0x00600408,%a0
        move.l  #0x50523330,(%a0)       /* "PR30" */

        .globl _m3_0_before_overlay_off
_m3_0_before_overlay_off:
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
        bne.w   _m3_0_ram_fail_low
        move.l  (%a0),%d2
        cmpi.l  #_m3_0_reset,%d2
        bne.w   _m3_0_ram_fail_low
        move.l  0x00000028,%d2
        cmpi.l  #_m3_0_aline,%d2
        bne.w   _m3_0_ram_fail_low

        move.l  #0x000f0000,%a7
        move.l  #0x4d333030,0x00000400  /* "M300" */

        /* LibreROM-private qualification service. */
        .word   LR_DIAG_TRAP

        cmpi.l  #LR_DIAG_RET,%d0
        bne.w   _m3_0_service_fail
        move.l  #0x4f4b3330,0x00000404  /* "OK30" */

        .globl _m3_0_stop
_m3_0_stop:
        stop    #0x2700
        bra.w   _m3_0_stop

_m3_0_ram_fail_alt:
        move.l  #0x52414630,0x00600400  /* "RAF0" */
        stop    #0x2700
        bra.w   _m3_0_ram_fail_alt

_m3_0_ram_fail_low:
        move.l  #0x52414d30,0x00000400  /* "RAM0" */
        stop    #0x2700
        bra.w   _m3_0_ram_fail_low

_m3_0_service_fail:
        move.l  #0x53564630,0x00000404  /* "SVF0" */
        stop    #0x2700
        bra.w   _m3_0_service_fail

        .globl _m3_0_default
_m3_0_default:
        move.l  #0x45584330,0x00000414  /* "EXC0" */
        rte

        .globl _m3_0_aline
_m3_0_aline:
        /*
         * Normal 68000 exception frame begins with saved SR then saved PC.
         * For an A-line exception the saved PC addresses the offending word.
         * Validate the private diagnostic trap and advance stacked PC by 2.
         */
        move.l  2(%a7),%a0
        move.w  (%a0),%d0
        cmpi.w  #LR_DIAG_TRAP,%d0
        bne.w   _m3_0_unknown_aline
        addq.l  #2,2(%a7)
        move.l  #0x44535030,0x0000040c  /* "DSP0" */
        move.l  #LR_DIAG_RET,%d0
        rte

_m3_0_unknown_aline:
        move.l  #0x42414430,0x00000410  /* "BAD0" */
        stop    #0x2700
        bra.w   _m3_0_unknown_aline

        .section .rodata,"a"
        .balign 4
_m3_0_marker:
        .ascii  "LIBREROM-M3.0-ALINE-DISPATCH\0"
