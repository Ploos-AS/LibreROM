/* LibreROM M2.4 Macintosh Plus RAM/vector bring-up.
 * Project-authored clean-room firmware code.
 */

        .section .vectors,"a"
        .globl _m2_4_vectors
_m2_4_vectors:
        .long   0x00100000
        .long   _m2_4_reset

        .section .text,"ax"
        .globl _m2_4_reset
_m2_4_reset:
        move.w  #0x2700,%sr

        /* Configure VIA A4 as output and remove reset ROM overlay. */
        move.l  #0x00e80600,%a0
        move.b  (%a0),%d0
        ori.b   #0x10,%d0
        move.b  %d0,(%a0)

        move.l  #0x00e80200,%a0
        move.b  (%a0),%d0
        andi.b  #0xef,%d0
        move.b  %d0,(%a0)

        /* Non-destructive probe of the top longword in the 1 MiB profile. */
        move.l  #0x000ffffc,%a0
        move.l  (%a0),%d3
        move.l  #0xa55aa55a,(%a0)
        move.l  (%a0),%d2
        cmpi.l  #0xa55aa55a,%d2
        bne.s   _m2_4_ram_fail
        move.l  %d3,(%a0)

        /* Install a complete 256-entry 68000 vector table in RAM. */
        move.l  #0x00000000,%a0
        move.l  #0x00100000,(%a0)+
        move.l  #_m2_4_reset,(%a0)+
        move.l  #_m2_4_default,%d0
        move.w  #253,%d1
1:
        move.l  %d0,(%a0)+
        dbra    %d1,1b

        /* Observable bring-up marker outside the vector table. */
        move.l  #0x00000400,%a0
        move.l  #0x4c524d34,(%a0)       /* "LRM4" */

        /* Prove vectors are active from RAM: TRAP #0 uses vector 32. */
        trap    #0

_m2_4_ram_fail:
        move.l  #0x00000400,%a0
        move.l  #0x52414d46,(%a0)       /* "RAMF" */
        stop    #0x2700
        bra.s   _m2_4_ram_fail

        .globl _m2_4_default
_m2_4_default:
        move.l  #0x00000404,%a0
        move.l  #0x45584334,(%a0)       /* "EXC4" */
_m2_4_stop:
        stop    #0x2700
        bra.s   _m2_4_stop

        .section .rodata,"a"
        .balign 4
_m2_4_marker:
        .ascii  "LIBREROM-M2.4-MACPLUS\0"
