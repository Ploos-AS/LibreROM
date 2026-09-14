        .equ MAC_TRAP_NEW_PTR,        0xa11e
        .equ MAC_TRAP_DISPOSE_PTR,    0xa01f
        .equ MAC_TRAP_SET_PTR_SIZE,   0xa020
        .equ MAC_TRAP_GET_PTR_SIZE,   0xa021
        .equ MAC_TRAP_NEW_HANDLE,     0xa122
        .equ MAC_TRAP_DISPOSE_HANDLE, 0xa023
        .equ MAC_NO_ERR,              0
        .equ MAC_MEM_FULL_ERR,       -108
        .equ MAC_MEM_WZ_ERR,         -111
        .equ MAC_MEM_ERR,             0x00000220

        .equ LR_HEAP_BASE,            0x00010000
        .equ LR_HEAP_LIMIT,           0x00080000
        .equ LR_HEAP_NEXT,            0x00000440
        .equ LR_TEST_HANDLE,          0x00000448
        .equ LR_TEST_DATA,            0x0000044c

        .equ LR_ALLOC_TABLE,          0x00000480
        .equ LR_ALLOC_COUNT,          8
        .equ LR_ALLOC_REC_SIZE,       16
        .equ LR_REC_PTR,              0
        .equ LR_REC_LOGICAL,          4
        .equ LR_REC_EXTENT,           8
        .equ LR_REC_ACTIVE,           12

        .equ LR_MASTER_BASE,          0x00007000
        .equ LR_HANDLE_TABLE,         0x00000500
        .equ LR_HANDLE_COUNT,         8
        .equ LR_HANDLE_REC_SIZE,      20
        .equ LR_HREC_HANDLE,          0
        .equ LR_HREC_DATA,            4
        .equ LR_HREC_LOGICAL,         8
        .equ LR_HREC_EXTENT,          12
        .equ LR_HREC_ACTIVE,          16

        .section .vectors,"a"
_m3_7_vectors:
        .long 0x00100000
        .long _m3_7_reset

        .section .text,"ax"
        .globl _m3_7_reset
_m3_7_reset:
        move.w #0x2700,%sr

        /* Install complete RAM vectors, including Line-A. */
        move.l #0x00600000,%a0
        move.l #0x00100000,(%a0)+
        move.l #_m3_7_reset,(%a0)+
        move.l #_m3_7_default,%d0
        move.w #253,%d1
1:      move.l %d0,(%a0)+
        dbra %d1,1b
        move.l #_m3_7_aline,0x00600028
        move.l #0x50523337,0x00600408      /* PR37 */

        /* Disable Macintosh Plus reset overlay through VIA A4. */
        move.l #0x00efe600,%a0
        move.b (%a0),%d0
        ori.b #0x10,%d0
        move.b %d0,(%a0)
        move.l #0x00efe200,%a0
        move.b (%a0),%d0
        andi.b #0xef,%d0
        move.b %d0,(%a0)

        move.l #0x000f0000,%a7
        move.l #LR_HEAP_BASE,LR_HEAP_NEXT
        clr.w MAC_MEM_ERR

        move.l #LR_ALLOC_TABLE,%a0
        moveq #31,%d0
2:      clr.l (%a0)+
        dbra %d0,2b

        move.l #LR_HANDLE_TABLE,%a0
        moveq #39,%d0
3:      clr.l (%a0)+
        dbra %d0,3b
        move.l #LR_MASTER_BASE,%a0
        moveq #7,%d0
4:      clr.l (%a0)+
        dbra %d0,4b

        move.l #0x4d333730,0x00000400      /* M370 */

        /* NewHandle(0x21): handle must reference a separately allocated block. */
        move.l #0x21,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_7_fail
        cmpa.l #LR_MASTER_BASE,%a0
        bne.w _m3_7_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),%d1
        cmpi.l #LR_HEAP_BASE,%d1
        bne.w _m3_7_fail
        move.l %d1,LR_TEST_DATA
        cmpi.l #0x00010022,LR_HEAP_NEXT
        bne.w _m3_7_fail
        move.l #0x4e48374f,0x00000404      /* NH7O */

        /* Master pointer is writable RAM and dereferences to the data block. */
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%a1
        move.l #0x484e4437,(%a1)           /* HND7 */
        cmpi.l #0x484e4437,(%a1)
        bne.w _m3_7_fail
        move.l #0x4d50374f,0x0000040c      /* MP7O */

        /* DisposeHandle clears the master pointer and succeeds. */
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_DISPOSE_HANDLE
        tst.w %d0
        bne.w _m3_7_fail
        move.l LR_TEST_HANDLE,%a0
        tst.l (%a0)
        bne.w _m3_7_fail
        tst.w MAC_MEM_ERR
        bne.w _m3_7_fail
        move.l #0x4448374f,0x00000410      /* DH7O */

        /* Repeating DisposeHandle on the freed handle must report memWZErr. */
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_DISPOSE_HANDLE
        cmpi.w #MAC_MEM_WZ_ERR,%d0
        bne.w _m3_7_fail
        cmpi.w #MAC_MEM_WZ_ERR,MAC_MEM_ERR
        bne.w _m3_7_fail
        move.l #0x575a3737,0x00000414      /* WZ77 */

        /* NewHandle reuses the free master pointer while allocating fresh data. */
        move.l #0x10,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_7_fail
        cmpa.l #LR_MASTER_BASE,%a0
        bne.w _m3_7_fail
        move.l (%a0),%d1
        cmpi.l #0x00010022,%d1
        bne.w _m3_7_fail
        cmpi.l #0x00010032,LR_HEAP_NEXT
        bne.w _m3_7_fail
        move.l #0x5248374f,0x00000418      /* RH7O */

        move.l #0x4f4b3337,0x0000041c      /* OK37 */
_m3_7_stop:
        stop #0x2700
        bra.w _m3_7_stop

_m3_7_fail:
        move.l #0x53564637,0x0000041c      /* SVF7 */
        stop #0x2700
        bra.w _m3_7_fail

_m3_7_default:
        move.l #0x45584337,0x00000424      /* EXC7 */
        rte

/* Line-A dispatcher. M3.7 keeps all M3.6 pointer services cumulative. */
_m3_7_aline:
        move.l 2(%a7),%a3
        move.w (%a3),%d2
        addq.l #2,2(%a7)
        cmpi.w #MAC_TRAP_NEW_PTR,%d2
        beq.w _m3_7_new_ptr
        cmpi.w #MAC_TRAP_DISPOSE_PTR,%d2
        beq.w _m3_7_dispose_ptr
        cmpi.w #MAC_TRAP_SET_PTR_SIZE,%d2
        beq.w _m3_7_set_ptr_size
        cmpi.w #MAC_TRAP_GET_PTR_SIZE,%d2
        beq.w _m3_7_get_ptr_size
        cmpi.w #MAC_TRAP_NEW_HANDLE,%d2
        beq.w _m3_7_new_handle
        cmpi.w #MAC_TRAP_DISPOSE_HANDLE,%d2
        beq.w _m3_7_dispose_handle
        move.l #0x42414437,0x00000428      /* BAD7 */
        stop #0x2700
        bra.w _m3_7_aline

/* ---- M3.6 pointer services retained ---- */
_m3_7_new_ptr:
        move.l %d0,%d4
        tst.l %d4
        beq.w _m3_7_ptr_alloc_fail
        move.l %d4,%d1
        addq.l #1,%d1
        andi.l #0xfffffffe,%d1

        move.l #LR_ALLOC_TABLE,%a1
        moveq #LR_ALLOC_COUNT-1,%d3
5:      tst.l LR_REC_ACTIVE(%a1)
        bne.s 6f
        tst.l LR_REC_PTR(%a1)
        beq.s 6f
        cmp.l LR_REC_EXTENT(%a1),%d1
        bhi.s 6f
        move.l %d4,LR_REC_LOGICAL(%a1)
        move.l #1,LR_REC_ACTIVE(%a1)
        move.l LR_REC_PTR(%a1),%a0
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
        rte
6:      adda.l #LR_ALLOC_REC_SIZE,%a1
        dbra %d3,5b

        move.l #LR_ALLOC_TABLE,%a1
        moveq #LR_ALLOC_COUNT-1,%d3
7:      tst.l LR_REC_PTR(%a1)
        beq.s 8f
        adda.l #LR_ALLOC_REC_SIZE,%a1
        dbra %d3,7b
        bra.w _m3_7_ptr_alloc_fail
8:      move.l LR_HEAP_NEXT,%a0
        move.l %a0,%d2
        add.l %d1,%d2
        cmpi.l #LR_HEAP_LIMIT,%d2
        bhi.w _m3_7_ptr_alloc_fail
        move.l %d2,LR_HEAP_NEXT
        move.l %a0,LR_REC_PTR(%a1)
        move.l %d4,LR_REC_LOGICAL(%a1)
        move.l %d1,LR_REC_EXTENT(%a1)
        move.l #1,LR_REC_ACTIVE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
        rte

_m3_7_ptr_alloc_fail:
        suba.l %a0,%a0
        moveq #MAC_MEM_FULL_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte

_m3_7_find_ptr:
        move.l %a0,%a4
        move.l #LR_ALLOC_TABLE,%a1
        moveq #LR_ALLOC_COUNT-1,%d3
9:      cmpa.l LR_REC_PTR(%a1),%a4
        bne.s 10f
        tst.l LR_REC_ACTIVE(%a1)
        beq.s 11f
        moveq #0,%d5
        rts
10:     adda.l #LR_ALLOC_REC_SIZE,%a1
        dbra %d3,9b
11:     moveq #-1,%d5
        moveq #MAC_MEM_WZ_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rts

_m3_7_dispose_ptr:
        bsr.w _m3_7_find_ptr
        tst.l %d5
        bne.s 12f
        clr.l LR_REC_ACTIVE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
12:     suba.l %a0,%a0
        rte

_m3_7_get_ptr_size:
        bsr.w _m3_7_find_ptr
        tst.l %d5
        bne.s 13f
        move.l LR_REC_LOGICAL(%a1),%d0
        clr.w MAC_MEM_ERR
13:     rte

_m3_7_set_ptr_size:
        move.l %d0,%d4
        move.l %d4,%d1
        addq.l #1,%d1
        andi.l #0xfffffffe,%d1
        bsr.w _m3_7_find_ptr
        tst.l %d5
        bne.s 17f
        cmp.l LR_REC_EXTENT(%a1),%d1
        bls.s 16f
        move.l LR_REC_PTR(%a1),%d2
        add.l LR_REC_EXTENT(%a1),%d2
        cmp.l LR_HEAP_NEXT,%d2
        bne.s 15f
        move.l LR_REC_PTR(%a1),%d2
        add.l %d1,%d2
        cmpi.l #LR_HEAP_LIMIT,%d2
        bhi.s 15f
        move.l %d2,LR_HEAP_NEXT
        move.l %d1,LR_REC_EXTENT(%a1)
        bra.s 16f
15:     moveq #MAC_MEM_FULL_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte
16:     move.l %d4,LR_REC_LOGICAL(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
17:     rte

/* ---- M3.7 relocatable-block baseline ---- */
_m3_7_new_handle:
        move.l %d0,%d4
        tst.l %d4
        beq.w _m3_7_handle_alloc_fail
        move.l %d4,%d1
        addq.l #1,%d1
        andi.l #0xfffffffe,%d1

        /* Find a free handle record; its master pointer slot is stable. */
        move.l #LR_HANDLE_TABLE,%a1
        move.l #LR_MASTER_BASE,%a2
        moveq #LR_HANDLE_COUNT-1,%d3
18:     tst.l LR_HREC_ACTIVE(%a1)
        beq.s 19f
        adda.l #LR_HANDLE_REC_SIZE,%a1
        adda.l #4,%a2
        dbra %d3,18b
        bra.w _m3_7_handle_alloc_fail

19:     move.l LR_HEAP_NEXT,%d2
        move.l %d2,%d6
        add.l %d1,%d6
        cmpi.l #LR_HEAP_LIMIT,%d6
        bhi.w _m3_7_handle_alloc_fail

        move.l %d6,LR_HEAP_NEXT
        move.l %a2,LR_HREC_HANDLE(%a1)
        move.l %d2,LR_HREC_DATA(%a1)
        move.l %d4,LR_HREC_LOGICAL(%a1)
        move.l %d1,LR_HREC_EXTENT(%a1)
        move.l #1,LR_HREC_ACTIVE(%a1)
        move.l %d2,(%a2)
        move.l %a2,%a0
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
        rte

_m3_7_handle_alloc_fail:
        suba.l %a0,%a0
        moveq #MAC_MEM_FULL_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte

_m3_7_find_handle:
        move.l %a0,%a4
        move.l #LR_HANDLE_TABLE,%a1
        moveq #LR_HANDLE_COUNT-1,%d3
20:     cmpa.l LR_HREC_HANDLE(%a1),%a4
        bne.s 21f
        tst.l LR_HREC_ACTIVE(%a1)
        beq.s 22f
        moveq #0,%d5
        rts
21:     adda.l #LR_HANDLE_REC_SIZE,%a1
        dbra %d3,20b
22:     moveq #-1,%d5
        moveq #MAC_MEM_WZ_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rts

_m3_7_dispose_handle:
        bsr.w _m3_7_find_handle
        tst.l %d5
        bne.s 23f
        move.l LR_HREC_HANDLE(%a1),%a2
        clr.l (%a2)
        clr.l LR_HREC_ACTIVE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
23:     rte

        .section .rodata,"a"
        .balign 4
        .ascii "LIBREROM-M3.7-HANDLE-BASELINE\0"
