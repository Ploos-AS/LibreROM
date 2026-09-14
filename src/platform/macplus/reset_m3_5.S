/* LibreROM M3.5 Macintosh Plus DisposePtr compatibility slice.
 * Project-authored clean-room firmware code.
 *
 * Adds documented _DisposPtr / DisposePtr trap $A01F to the qualified _NewPtr
 * path.  The compatibility surface implemented here is deliberately small:
 *   - _NewPtr ($A11E): D0.L byte count -> A0 pointer, D0.W result
 *   - _DisposPtr ($A01F): A0 pointer -> A0=0, D0.W result
 *   - MemErr low-memory global at $0220
 *   - noErr=0, memFullErr=-108, memWZErr=-111
 *
 * LibreROM keeps eight project-owned allocation records. Disposed blocks are
 * eligible for first-fit reuse; this is not yet a complete Macintosh heap-zone
 * implementation or compactor.
 */

        .equ    MAC_TRAP_NEW_PTR,     0xa11e
        .equ    MAC_TRAP_DISPOSE_PTR, 0xa01f
        .equ    MAC_NO_ERR,           0
        .equ    MAC_MEM_FULL_ERR,    -108
        .equ    MAC_MEM_WZ_ERR,      -111
        .equ    MAC_MEM_ERR,          0x00000220
        .equ    LR_HEAP_BASE,         0x00010000
        .equ    LR_HEAP_LIMIT,        0x00080000
        .equ    LR_HEAP_NEXT,         0x00000440
        .equ    LR_ALLOC_TABLE,       0x00000460
        .equ    LR_ALLOC_COUNT,       8
        .equ    LR_ALLOC_REC_SIZE,    12

        .section .vectors,"a"
        .globl _m3_5_vectors
_m3_5_vectors:
        .long   0x00100000
        .long   _m3_5_reset

        .section .text,"ax"
        .globl _m3_5_reset
_m3_5_reset:
        move.w  #0x2700,%sr

        move.l  #0x006ffffc,%a0
        move.l  (%a0),%d3
        move.l  #0xa55aa55a,(%a0)
        move.l  (%a0),%d2
        cmpi.l  #0xa55aa55a,%d2
        bne.w   _m3_5_ram_fail_alt
        move.l  %d3,(%a0)

        move.l  #0x00600000,%a0
        move.l  #0x00100000,(%a0)+
        move.l  #_m3_5_reset,(%a0)+
        move.l  #_m3_5_default,%d0
        move.w  #253,%d1
1:
        move.l  %d0,(%a0)+
        dbra    %d1,1b
        move.l  #0x00600028,%a0
        move.l  #_m3_5_aline,(%a0)
        move.l  #0x50523335,0x00600408  /* PR35 */

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
        bne.w   _m3_5_ram_fail_low
        move.l  0x00000004,%d2
        cmpi.l  #_m3_5_reset,%d2
        bne.w   _m3_5_ram_fail_low
        move.l  0x00000028,%d2
        cmpi.l  #_m3_5_aline,%d2
        bne.w   _m3_5_ram_fail_low

        move.l  #0x000f0000,%a7
        move.l  #LR_HEAP_BASE,LR_HEAP_NEXT
        clr.w   MAC_MEM_ERR

        /* Clear allocation table. */
        move.l  #LR_ALLOC_TABLE,%a0
        moveq   #23,%d0
2:
        clr.l   (%a0)+
        dbra    %d0,2b

        move.l  #0x4d333530,0x00000400  /* M350 */

        /* Two baseline allocations. */
        move.l  #0x20,%d0
        .word   MAC_TRAP_NEW_PTR
        tst.w   %d0
        bne.w   _m3_5_service_fail
        cmpa.l  #0x00010000,%a0
        bne.w   _m3_5_service_fail
        move.l  %a0,%a1               /* save p1 */

        move.l  #0x12,%d0
        .word   MAC_TRAP_NEW_PTR
        tst.w   %d0
        bne.w   _m3_5_service_fail
        cmpa.l  #0x00010020,%a0
        bne.w   _m3_5_service_fail
        move.l  %a0,%a2               /* save p2 */
        move.l  #0x4e50354f,0x00000404 /* NP5O */

        /* Dispose p1; documented result is A0=0, D0.W=noErr, MemErr=noErr. */
        move.l  %a1,%a0
        .word   MAC_TRAP_DISPOSE_PTR
        tst.w   %d0
        bne.w   _m3_5_service_fail
        cmpa.l  #0,%a0
        bne.w   _m3_5_service_fail
        tst.w   MAC_MEM_ERR
        bne.w   _m3_5_service_fail
        move.l  #0x4450314f,0x0000040c /* DP1O */

        /* A smaller allocation must reuse the disposed first block. */
        move.l  #0x18,%d0
        .word   MAC_TRAP_NEW_PTR
        tst.w   %d0
        bne.w   _m3_5_service_fail
        cmpa.l  #0x00010000,%a0
        bne.w   _m3_5_service_fail
        cmpi.l  #0x00010032,LR_HEAP_NEXT
        bne.w   _m3_5_service_fail
        move.l  #0x52555335,0x00000410 /* RUS5 */

        /* Dispose p2, then dispose p2 again: second call must be memWZErr. */
        move.l  %a2,%a0
        .word   MAC_TRAP_DISPOSE_PTR
        tst.w   %d0
        bne.w   _m3_5_service_fail
        move.l  %a2,%a0
        .word   MAC_TRAP_DISPOSE_PTR
        cmpi.w  #MAC_MEM_WZ_ERR,%d0
        bne.w   _m3_5_service_fail
        cmpa.l  #0,%a0
        bne.w   _m3_5_service_fail
        cmpi.w  #MAC_MEM_WZ_ERR,MAC_MEM_ERR
        bne.w   _m3_5_service_fail
        move.l  #0x575a4535,0x00000414 /* WZE5 */

        move.l  #0x4f4b3335,0x00000418 /* OK35 */

_m3_5_stop:
        stop    #0x2700
        bra.w   _m3_5_stop

_m3_5_ram_fail_alt:
        move.l  #0x52414635,0x00600400
        stop    #0x2700
        bra.w   _m3_5_ram_fail_alt

_m3_5_ram_fail_low:
        move.l  #0x52414d35,0x00000400
        stop    #0x2700
        bra.w   _m3_5_ram_fail_low

_m3_5_service_fail:
        move.l  #0x53564635,0x00000418
        stop    #0x2700
        bra.w   _m3_5_service_fail

_m3_5_default:
        move.l  #0x45584335,0x0000041c /* EXC5 */
        rte

        .globl _m3_5_aline
_m3_5_aline:
        move.l  2(%a7),%a3
        move.w  (%a3),%d2
        addq.l  #2,2(%a7)
        cmpi.w  #MAC_TRAP_NEW_PTR,%d2
        beq.w   _m3_5_new_ptr
        cmpi.w  #MAC_TRAP_DISPOSE_PTR,%d2
        beq.w   _m3_5_dispose_ptr
        bra.w   _m3_5_unknown_aline

/* NewPtr: first-fit free-record reuse, otherwise bump allocation. */
_m3_5_new_ptr:
        move.l  #0x44535035,0x00000420 /* DSP5 */
        move.l  %d0,%d1
        tst.l   %d1
        beq.w   _m3_5_alloc_fail
        addq.l  #1,%d1
        andi.l  #0xfffffffe,%d1

        move.l  #LR_ALLOC_TABLE,%a1
        moveq   #LR_ALLOC_COUNT-1,%d3
_m3_5_reuse_loop:
        tst.l   8(%a1)
        bne.s   _m3_5_reuse_next
        move.l  (%a1),%d2
        beq.s   _m3_5_reuse_next
        cmp.l   4(%a1),%d1
        bhi.s   _m3_5_reuse_next
        move.l  %d1,4(%a1)
        move.l  #1,8(%a1)
        move.l  (%a1),%a0
        moveq   #MAC_NO_ERR,%d0
        clr.w   MAC_MEM_ERR
        move.l  #0x53564335,0x00000424 /* SVC5 */
        rte
_m3_5_reuse_next:
        adda.l  #LR_ALLOC_REC_SIZE,%a1
        dbra    %d3,_m3_5_reuse_loop

        /* Need a fresh record and fresh bump-space. */
        move.l  #LR_ALLOC_TABLE,%a1
        moveq   #LR_ALLOC_COUNT-1,%d3
_m3_5_slot_loop:
        move.l  (%a1),%d2
        beq.s   _m3_5_slot_found
        adda.l  #LR_ALLOC_REC_SIZE,%a1
        dbra    %d3,_m3_5_slot_loop
        bra.w   _m3_5_alloc_fail

_m3_5_slot_found:
        move.l  LR_HEAP_NEXT,%a0
        move.l  %a0,%d2
        add.l   %d1,%d2
        cmpi.l  #LR_HEAP_LIMIT,%d2
        bhi.w   _m3_5_alloc_fail
        move.l  %d2,LR_HEAP_NEXT
        move.l  %a0,(%a1)
        move.l  %d1,4(%a1)
        move.l  #1,8(%a1)
        moveq   #MAC_NO_ERR,%d0
        clr.w   MAC_MEM_ERR
        move.l  #0x53564335,0x00000424
        rte

_m3_5_alloc_fail:
        suba.l  %a0,%a0
        moveq   #MAC_MEM_FULL_ERR,%d0
        move.w  %d0,MAC_MEM_ERR
        rte

/* DisposePtr: exact active-record match is required. */
_m3_5_dispose_ptr:
        move.l  %a0,%a4
        move.l  #LR_ALLOC_TABLE,%a1
        moveq   #LR_ALLOC_COUNT-1,%d3
_m3_5_dispose_loop:
        cmpa.l  (%a1),%a4
        bne.s   _m3_5_dispose_next
        tst.l   8(%a1)
        beq.s   _m3_5_dispose_bad
        clr.l   8(%a1)
        suba.l  %a0,%a0
        moveq   #MAC_NO_ERR,%d0
        clr.w   MAC_MEM_ERR
        rte
_m3_5_dispose_next:
        adda.l  #LR_ALLOC_REC_SIZE,%a1
        dbra    %d3,_m3_5_dispose_loop
_m3_5_dispose_bad:
        suba.l  %a0,%a0
        moveq   #MAC_MEM_WZ_ERR,%d0
        move.w  %d0,MAC_MEM_ERR
        rte

_m3_5_unknown_aline:
        move.l  #0x42414435,0x00000428 /* BAD5 */
        stop    #0x2700
        bra.w   _m3_5_unknown_aline

        .section .rodata,"a"
        .balign 4
_m3_5_marker:
        .ascii  "LIBREROM-M3.5-DISPOSEPTR-COMPAT\0"
