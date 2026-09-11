/* LibreROM M1 minimal Motorola 68000 reset image.
 *
 * This source is project-authored and intentionally machine-neutral. It does
 * not contain Apple ROM code or data.
 */

        .section .vectors,"a"
        .globl _vectors
_vectors:
        .long   0x00010000      /* initial supervisor stack pointer */
        .long   _reset          /* initial program counter */

        .section .text,"ax"
        .globl _reset
_reset:
        move.w  #0x2700,%sr     /* supervisor, interrupts masked */
1:
        stop    #0x2700         /* deterministic diagnostic stop state */
        bra.s   1b              /* resume safely if an interrupt wakes STOP */

        .section .rodata,"a"
        .balign 4
        .globl _m1_marker
_m1_marker:
        .ascii  "LIBREROM-M1\0"
