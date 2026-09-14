/* LibreROM M3.4 Macintosh Plus NewPtr compatibility slice.
 * Project-authored clean-room firmware code.
 *
 * First compatibility-facing Memory Manager service. Public Inside Macintosh
 * documentation defines _NewPtr as trap $A11E with requested size in D0.L,
 * pointer result in A0, and result code in D0.W. The documented failure code
 * for insufficient heap space is memFullErr (-108). MemErr lives at low-memory
 * address $0220 and is updated to the same result.
 *
 * Scope boundary: this milestone implements the base _NewPtr trap only against
 * LibreROM's single simple qualification heap. It does not yet implement heap
 * zones, compaction, grow-zone callbacks, SYS/CLEAR trap modifiers, disposal,
 * or full historical Memory Manager internals.
 */

        .equ    MAC_TRAP_NEW_PTR,  0xa11e
        .equ    MAC_NO_ERR,        0
        .equ    MAC_MEM_FULL_ERR, -108
        .equ    MAC_MEM_ERR,       0x00000220
        .equ    LR_HEAP_BASE,      0x00010000
        .equ    LR_HEAP_LIMIT,     0x00080000
        .equ    LR_HEAP_NEXT,      0x00000440

        .section .vectors,"a"
        .globl _m3_4_vectors
_m3_4_vectors:
        .long   0x00100000
        .long   _m3_4_reset

        .section .text,"ax"
        .globl _m3_4_reset
_m3_4_reset:
        move.w  #0x2700,%sr

        move.l  #0x006ffffc,%a0
        move.l  (%a0),%d3
        move.l  #0xa55aa55a,(%a0)
        move.l  (%a0),%d2
        cmpi.l  #0xa55aa55a,%d2
        bne.w   _m3_4_ram_fail_alt
        move.l  %d3,(%a0)

        /* Install vectors in backing RAM while reset overlay is active. */
        move.l  #0x00600000,%a0
        move.l  #0x00100000,(%a0)+
        move.l  #_m3_4_reset,(%a0)+
        move.l  #_m3_4_default,%d0
        move.w  #253,%d1
1:
        move.l  %d0,(%a0)+
        dbra    %d1,1b
        move.l  #0x00600028,%a0
        move.l  #_m3_4_aline,(%a0)
        move.l  #0x50523334,0x00600408  /* "PR34" */

        /* Disable Macintosh Plus ROM overlay through VIA Port A bit 4. */
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
        bne.w   _m3_4_ram_fail_low
        move.l  0x00000004,%d2
        cmpi.l  #_m3_4_reset,%d2
        bne.w   _m3_4_ram_fail_low
        move.l  0x00000028,%d2
        cmpi.l  #_m3_4_aline,%d2
        bne.w   _m3_4_ram_fail_low

        move.l  #0x000f0000,%a7
        move.l  #LR_HEAP_BASE,LR_HEAP_NEXT
        clr.w   MAC_MEM_ERR
        move.l  #0x4d333430,0x00000400  /* "M340" */

        /* Documented NewPtr success contract: D0.L input, A0 result, D0.W=noErr. */
        move.l  #0x20,%d0
        .word   MAC_TRAP_NEW_PTR
        tst.w   %d0
        bne.w   _m3_4_service_fail
        cmpa.l  #0x00010000,%a0
        bne.w   _m3_4_service_fail
        tst.w   MAC_MEM_ERR
        bne.w   _m3_4_service_fail
        move.l  #0x4e50314f,0x00000404  /* "NP1O" */

        /* Word-aligned second allocation. */
        move.l  #0x11,%d0
        .word   MAC_TRAP_NEW_PTR
        tst.w   %d0
        bne.w   _m3_4_service_fail
        cmpa.l  #0x00010020,%a0
        bne.w   _m3_4_service_fail
        cmpi.l  #0x00010032,LR_HEAP_NEXT
        bne.w   _m3_4_service_fail
        move.l  #0x4e50324f,0x0000040c  /* "NP2O" */

        /* Oversized request: NIL + memFullErr, heap top unchanged, MemErr updated. */
        move.l  #0x00070000,%d0
        .word   MAC_TRAP_NEW_PTR
        cmpi.w  #MAC_MEM_FULL_ERR,%d0
        bne.w   _m3_4_service_fail
        cmpa.l  #0,%a0
        bne.w   _m3_4_service_fail
        cmpi.w  #MAC_MEM_FULL_ERR,MAC_MEM_ERR
        bne.w   _m3_4_service_fail
        cmpi.l  #0x00010032,LR_HEAP_NEXT
        bne.w   _m3_4_service_fail
        move.l  #0x4d464534,0x00000410  /* "MFE4" */

        move.l  #0x4f4b3334,0x00000414  /* "OK34" */

        .globl _m3_4_stop
_m3_4_stop:
        stop    #0x2700
        bra.w   _m3_4_stop

_m3_4_ram_fail_alt:
        move.l  #0x52414634,0x00600400
        stop    #0x2700
        bra.w   _m3_4_ram_fail_alt

_m3_4_ram_fail_low:
        move.l  #0x52414d34,0x00000400
        stop    #0x2700
        bra.w   _m3_4_ram_fail_low

_m3_4_service_fail:
        move.l  #0x53564634,0x00000414
        stop    #0x2700
        bra.w   _m3_4_service_fail

        .globl _m3_4_default
_m3_4_default:
        move.l  #0x45584334,0x00000418
        rte

        .globl _m3_4_aline
_m3_4_aline:
        move.l  2(%a7),%a0
        move.w  (%a0),%d2
        addq.l  #2,2(%a7)
        cmpi.w  #MAC_TRAP_NEW_PTR,%d2
        beq.s   _m3_4_new_ptr
        bra.s   _m3_4_unknown_aline

_m3_4_new_ptr:
        move.l  #0x44535034,0x0000041c  /* "DSP4" */
        move.l  %d0,%d1
        tst.l   %d1
        beq.s   _m3_4_alloc_fail
        addq.l  #1,%d1
        andi.l  #0xfffffffe,%d1
        move.l  LR_HEAP_NEXT,%a0
        move.l  %a0,%d2
        add.l   %d1,%d2
        cmpi.l  #LR_HEAP_LIMIT,%d2
        bhi.s   _m3_4_alloc_fail
        move.l  %d2,LR_HEAP_NEXT
        moveq   #MAC_NO_ERR,%d0
        clr.w   MAC_MEM_ERR
        move.l  #0x53564334,0x00000420  /* "SVC4" */
        rte

_m3_4_alloc_fail:
        suba.l  %a0,%a0
        moveq   #MAC_MEM_FULL_ERR,%d0
        move.w  %d0,MAC_MEM_ERR
        rte

_m3_4_unknown_aline:
        move.l  #0x42414434,0x00000424
        stop    #0x2700
        bra.w   _m3_4_unknown_aline

        .section .rodata,"a"
        .balign 4
_m3_4_marker:
        .ascii  "LIBREROM-M3.4-NEWPTR-COMPAT\0"
