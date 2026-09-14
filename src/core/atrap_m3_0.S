/* LibreROM M3.0 clean-room A-trap dispatch foundation.
 *
 * This deliberately uses a project-owned synthetic A-line opcode (0xA000)
 * and project-owned RAM markers. No Apple ROM implementation, trap table,
 * System software, or derived proprietary material is used.
 */

        .section .vectors,"a"
        .globl _m3_0_vectors
_m3_0_vectors:
        .long   0x00020000
        .long   _m3_0_reset

        /* Vectors 2..9 use the project-owned default handler. */
        .rept   8
        .long   _m3_0_default
        .endr

        /* Vector 10: 68000 Line-A emulator exception. */
        .long   _m3_0_line_a

        .section .text,"ax"
        .globl _m3_0_reset
_m3_0_reset:
        move.w  #0x2700,%sr
        move.l  #0x00010000,%a0
        clr.l   (%a0)
        clr.l   4(%a0)

        /* Project-owned synthetic A-trap used only for qualification. */
        .word   0xa000

        /* Reaching this proves the handler returned through RTE. */
        move.l  #0x504f5354,4(%a0)      /* POST */

        .globl _m3_0_stop
_m3_0_stop:
        stop    #0x2700
        bra.s   _m3_0_stop

        .globl _m3_0_line_a
_m3_0_line_a:
        /* Preserve A0 while recording that Line-A dispatch occurred. */
        move.l  %a0,-(%sp)
        move.l  #0x00010000,%a0
        move.l  #0x41545233,(%a0)       /* ATR3 */

        /* A 68000 Line-A exception stacks SR then the faulting PC.
         * With saved A0 above, the stacked PC is at 6(SP). Advance over
         * the one-word synthetic trap before returning.
         */
        addq.l  #2,6(%sp)
        move.l  (%sp)+,%a0
        rte

_m3_0_default:
        stop    #0x2700
        bra.s   _m3_0_default
