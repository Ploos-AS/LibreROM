/* LibreROM M3.2 Macintosh Plus memory-service foundation.
 * Project-authored clean-room firmware code.
 *
 * Extends the qualified M3.1 private A-line ABI with a tiny bump allocator.
 * This is a Macintosh-relevant Memory Manager building block, but it is NOT
 * yet claimed to implement any Apple Toolbox trap or NewPtr semantics.
 *
 * ABI:
 *   0xA0F2 LR_SVC_MEM_ALLOC
 *     in:  D0 = requested byte count (>0)
 *     out: D0 = 0 on success, -1 on failure
 *          A0 = allocated pointer on success, 0 on failure
 *     allocation is rounded to an even byte count.
 *
 * Heap qualification window: 0x00010000 .. 0x0007ffff.
 */

        .equ    LR_SVC_MEM_ALLOC, 0xa0f2
        .equ    LR_HEAP_BASE,     0x00010000
        .equ    LR_HEAP_LIMIT,    0x00080000
        .equ    LR_HEAP_NEXT,     0x00000440

        .section .vectors,"a"
        .globl _m3_2_vectors
_m3_2_vectors:
        .long   0x00100000
        .long   _m3_2_reset

        .section .text,"ax"
        .globl _m3_2_reset
_m3_2_reset:
        move.w  #0x2700,%sr

        /* Non-destructive top-of-RAM probe through the alternate window. */
        move.l  #0x006ffffc,%a0
        move.l  (%a0),%d3
        move.l  #0xa55aa55a,(%a0)
        move.l  (%a0),%d2
        cmpi.l  #0xa55aa55a,%d2
        bne.w   _m3_2_ram_fail_alt
        move.l  %d3,(%a0)

        /* Install all 256 vectors in backing RAM before overlay removal. */
        move.l  #0x00600000,%a0
        move.l  #0x00100000,(%a0)+
        move.l  #_m3_2_reset,(%a0)+
        move.l  #_m3_2_default,%d0
        move.w  #253,%d1
1:
        move.l  %d0,(%a0)+
        dbra    %d1,1b

        move.l  #0x00600028,%a0
        move.l  #_m3_2_aline,(%a0)

        move.l  #0x00600408,%a0
        move.l  #0x50523332,(%a0)       /* "PR32" */

        .globl _m3_2_before_overlay_off
_m3_2_before_overlay_off:
        move.l  #0x00efe600,%a0
        move.b  (%a0),%d0
        ori.b   #0x10,%d0
        move.b  %d0,(%a0)

        move.l  #0x00efe200,%a0
        move.b  (%a0),%d0
        andi.b  #0xef,%d0
        move.b  %d0,(%a0)

        /* Verify low RAM vectors after overlay removal. */
        move.l  0x00000000,%d2
        cmpi.l  #0x00100000,%d2
        bne.w   _m3_2_ram_fail_low
        move.l  0x00000004,%d2
        cmpi.l  #_m3_2_reset,%d2
        bne.w   _m3_2_ram_fail_low
        move.l  0x00000028,%d2
        cmpi.l  #_m3_2_aline,%d2
        bne.w   _m3_2_ram_fail_low

        move.l  #0x000f0000,%a7
        move.l  #LR_HEAP_BASE,LR_HEAP_NEXT
        move.l  #0x4d333230,0x00000400  /* "M320" */

        /* Allocation 1: exact even size. */
        move.l  #0x20,%d0
        .word   LR_SVC_MEM_ALLOC
        tst.l   %d0
        bne.w   _m3_2_service_fail
        cmpa.l  #0x00010000,%a0
        bne.w   _m3_2_service_fail
        move.l  #0x41314f4b,0x00000404  /* "A1OK" */

        /* Allocation 2: odd size rounds up to 0x12. */
        move.l  #0x11,%d0
        .word   LR_SVC_MEM_ALLOC
        tst.l   %d0
        bne.w   _m3_2_service_fail
        cmpa.l  #0x00010020,%a0
        bne.w   _m3_2_service_fail
        cmpi.l  #0x00010032,LR_HEAP_NEXT
        bne.w   _m3_2_service_fail
        move.l  #0x41324f4b,0x0000040c  /* "A2OK" */

        /* Oversized allocation must fail without moving the heap top. */
        move.l  #0x00070000,%d0
        .word   LR_SVC_MEM_ALLOC
        cmpi.l  #-1,%d0
        bne.w   _m3_2_service_fail
        cmpa.l  #0,%a0
        bne.w   _m3_2_service_fail
        cmpi.l  #0x00010032,LR_HEAP_NEXT
        bne.w   _m3_2_service_fail
        move.l  #0x4f4f4d32,0x00000410  /* "OOM2" */

        move.l  #0x4f4b3332,0x00000414  /* "OK32" */

        .globl _m3_2_stop
_m3_2_stop:
        stop    #0x2700
        bra.w   _m3_2_stop

_m3_2_ram_fail_alt:
        move.l  #0x52414632,0x00600400  /* "RAF2" */
        stop    #0x2700
        bra.w   _m3_2_ram_fail_alt

_m3_2_ram_fail_low:
        move.l  #0x52414d32,0x00000400  /* "RAM2" */
        stop    #0x2700
        bra.w   _m3_2_ram_fail_low

_m3_2_service_fail:
        move.l  #0x53564632,0x00000414  /* "SVF2" */
        stop    #0x2700
        bra.w   _m3_2_service_fail

        .globl _m3_2_default
_m3_2_default:
        move.l  #0x45584332,0x00000418  /* "EXC2" */
        rte

        .globl _m3_2_aline
_m3_2_aline:
        move.l  2(%a7),%a0
        move.w  (%a0),%d2
        addq.l  #2,2(%a7)

        cmpi.w  #LR_SVC_MEM_ALLOC,%d2
        beq.s   _m3_2_service_mem_alloc
        bra.s   _m3_2_unknown_aline

_m3_2_service_mem_alloc:
        move.l  #0x44535032,0x0000041c  /* "DSP2" */
        tst.l   %d0
        beq.s   _m3_2_alloc_fail

        addq.l  #1,%d0
        andi.l  #0xfffffffe,%d0

        move.l  LR_HEAP_NEXT,%a0
        move.l  %a0,%d1
        add.l   %d0,%d1
        cmpi.l  #LR_HEAP_LIMIT,%d1
        bhi.s   _m3_2_alloc_fail

        move.l  %d1,LR_HEAP_NEXT
        moveq   #0,%d0
        move.l  #0x53564332,0x00000420  /* "SVC2" */
        rte

_m3_2_alloc_fail:
        moveq   #-1,%d0
        suba.l  %a0,%a0
        rte

_m3_2_unknown_aline:
        move.l  #0x42414432,0x00000424  /* "BAD2" */
        stop    #0x2700
        bra.w   _m3_2_unknown_aline

        .section .rodata,"a"
        .balign 4
_m3_2_marker:
        .ascii  "LIBREROM-M3.2-MEMORY-PRIMITIVE\0"
