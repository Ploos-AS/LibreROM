/* LibreROM M3.3 Macintosh Plus pointer-allocation foundation.
 * Project-authored clean-room firmware code.
 *
 * Builds on the qualified M3.2 bump allocator with a pointer-oriented
 * service and a separate last-memory-status query. These are LibreROM-private
 * qualification semantics, not claims of Apple Toolbox trap compatibility.
 *
 * ABI:
 *   0xA0F3 LR_SVC_NEW_PTR
 *     in:  D0 = requested byte count (>0)
 *     out: A0 = allocated pointer, or 0 on failure
 *          D0 is preserved
 *   0xA0F4 LR_SVC_MEM_STATUS
 *     out: D0 = 0 after the last successful allocation, -1 after failure
 *
 * Heap qualification window: 0x00010000 .. 0x0007ffff.
 */

        .equ    LR_SVC_NEW_PTR,    0xa0f3
        .equ    LR_SVC_MEM_STATUS, 0xa0f4
        .equ    LR_HEAP_BASE,      0x00010000
        .equ    LR_HEAP_LIMIT,     0x00080000
        .equ    LR_HEAP_NEXT,      0x00000440
        .equ    LR_MEM_LAST_ERR,   0x00000444

        .section .vectors,"a"
        .globl _m3_3_vectors
_m3_3_vectors:
        .long   0x00100000
        .long   _m3_3_reset

        .section .text,"ax"
        .globl _m3_3_reset
_m3_3_reset:
        move.w  #0x2700,%sr

        move.l  #0x006ffffc,%a0
        move.l  (%a0),%d3
        move.l  #0xa55aa55a,(%a0)
        move.l  (%a0),%d2
        cmpi.l  #0xa55aa55a,%d2
        bne.w   _m3_3_ram_fail_alt
        move.l  %d3,(%a0)

        move.l  #0x00600000,%a0
        move.l  #0x00100000,(%a0)+
        move.l  #_m3_3_reset,(%a0)+
        move.l  #_m3_3_default,%d0
        move.w  #253,%d1
1:
        move.l  %d0,(%a0)+
        dbra    %d1,1b

        move.l  #0x00600028,%a0
        move.l  #_m3_3_aline,(%a0)
        move.l  #0x50523333,0x00600408  /* "PR33" */

        move.l  #0x00efe600,%a0
        move.b  (%a0),%d0
        ori.b   #0x10,%d0
        move.b  %d0,(%a0)
        move.l  #0x00efe200,%a0
        move.b  (%a0),%d0
        andi.b  #0xef,%d0
        move.b  %d0,(%a0)

        move.l  0x00000000,%d2
        cmpi.l  #0x00100000,%d2
        bne.w   _m3_3_ram_fail_low
        move.l  0x00000004,%d2
        cmpi.l  #_m3_3_reset,%d2
        bne.w   _m3_3_ram_fail_low
        move.l  0x00000028,%d2
        cmpi.l  #_m3_3_aline,%d2
        bne.w   _m3_3_ram_fail_low

        move.l  #0x000f0000,%a7
        move.l  #LR_HEAP_BASE,LR_HEAP_NEXT
        clr.l   LR_MEM_LAST_ERR
        move.l  #0x4d333330,0x00000400  /* "M330" */

        /* Successful pointer allocation. */
        move.l  #0x20,%d0
        .word   LR_SVC_NEW_PTR
        cmpi.l  #0x20,%d0
        bne.w   _m3_3_service_fail
        cmpa.l  #0x00010000,%a0
        bne.w   _m3_3_service_fail
        .word   LR_SVC_MEM_STATUS
        tst.l   %d0
        bne.w   _m3_3_service_fail
        move.l  #0x50314f4b,0x00000404  /* "P1OK" */

        /* Odd request must remain word-aligned. */
        move.l  #0x11,%d0
        .word   LR_SVC_NEW_PTR
        cmpa.l  #0x00010020,%a0
        bne.w   _m3_3_service_fail
        cmpi.l  #0x00010032,LR_HEAP_NEXT
        bne.w   _m3_3_service_fail
        move.l  #0x50324f4b,0x0000040c  /* "P2OK" */

        /* Failure returns NULL, preserves heap top, and records status. */
        move.l  #0x00070000,%d0
        .word   LR_SVC_NEW_PTR
        cmpa.l  #0,%a0
        bne.w   _m3_3_service_fail
        cmpi.l  #0x00010032,LR_HEAP_NEXT
        bne.w   _m3_3_service_fail
        .word   LR_SVC_MEM_STATUS
        cmpi.l  #-1,%d0
        bne.w   _m3_3_service_fail
        move.l  #0x45525233,0x00000410  /* "ERR3" */

        move.l  #0x4f4b3333,0x00000414  /* "OK33" */

        .globl _m3_3_stop
_m3_3_stop:
        stop    #0x2700
        bra.w   _m3_3_stop

_m3_3_ram_fail_alt:
        move.l  #0x52414633,0x00600400
        stop    #0x2700
        bra.w   _m3_3_ram_fail_alt

_m3_3_ram_fail_low:
        move.l  #0x52414d33,0x00000400
        stop    #0x2700
        bra.w   _m3_3_ram_fail_low

_m3_3_service_fail:
        move.l  #0x53564633,0x00000414
        stop    #0x2700
        bra.w   _m3_3_service_fail

        .globl _m3_3_default
_m3_3_default:
        move.l  #0x45584333,0x00000418
        rte

        .globl _m3_3_aline
_m3_3_aline:
        move.l  2(%a7),%a0
        move.w  (%a0),%d2
        addq.l  #2,2(%a7)
        cmpi.w  #LR_SVC_NEW_PTR,%d2
        beq.s   _m3_3_service_new_ptr
        cmpi.w  #LR_SVC_MEM_STATUS,%d2
        beq.s   _m3_3_service_mem_status
        bra.s   _m3_3_unknown_aline

_m3_3_service_new_ptr:
        move.l  #0x44535033,0x0000041c  /* "DSP3" */
        move.l  %d0,%d1
        tst.l   %d1
        beq.s   _m3_3_alloc_fail
        addq.l  #1,%d1
        andi.l  #0xfffffffe,%d1
        move.l  LR_HEAP_NEXT,%a0
        move.l  %a0,%d2
        add.l   %d1,%d2
        cmpi.l  #LR_HEAP_LIMIT,%d2
        bhi.s   _m3_3_alloc_fail
        move.l  %d2,LR_HEAP_NEXT
        clr.l   LR_MEM_LAST_ERR
        move.l  #0x53564333,0x00000420  /* "SVC3" */
        rte

_m3_3_alloc_fail:
        suba.l  %a0,%a0
        move.l  #-1,LR_MEM_LAST_ERR
        rte

_m3_3_service_mem_status:
        move.l  LR_MEM_LAST_ERR,%d0
        rte

_m3_3_unknown_aline:
        move.l  #0x42414433,0x00000424
        stop    #0x2700
        bra.w   _m3_3_unknown_aline

        .section .rodata,"a"
        .balign 4
_m3_3_marker:
        .ascii  "LIBREROM-M3.3-POINTER-STATUS\0"
