        .equ MAC_TRAP_NEW_HANDLE,      0xa122
        .equ MAC_TRAP_DISPOSE_HANDLE,  0xa023
        .equ MAC_TRAP_SET_HANDLE_SIZE, 0xa024
        .equ MAC_TRAP_GET_HANDLE_SIZE, 0xa025
        .equ MAC_TRAP_HLOCK,           0xa029
        .equ MAC_TRAP_HUNLOCK,         0xa02a
        .equ MAC_TRAP_HGETSTATE,       0xa069
        .equ MAC_TRAP_HSETSTATE,       0xa06a
        .equ MAC_NO_ERR,               0
        .equ MAC_MEM_FULL_ERR,        -108
        .equ MAC_NIL_HANDLE_ERR,      -109
        .equ MAC_MEM_WZ_ERR,          -111
        .equ MAC_MEM_ERR,              0x00000220
        .equ LR_HEAP_BASE,             0x00010000
        .equ LR_HEAP_LIMIT,            0x00080000
        .equ LR_HEAP_NEXT,             0x00000440
        .equ LR_TEST_HANDLE,           0x00000448
        .equ LR_TEST_OLD_DATA,         0x0000044c
        .equ LR_MASTER_BASE,           0x00007000
        .equ LR_HANDLE_TABLE,          0x00000500
        .equ LR_HANDLE_COUNT,          8
        .equ LR_HANDLE_REC_SIZE,       24
        .equ LR_HREC_HANDLE,           0
        .equ LR_HREC_DATA,             4
        .equ LR_HREC_LOGICAL,          8
        .equ LR_HREC_EXTENT,           12
        .equ LR_HREC_ACTIVE,           16
        .equ LR_HREC_STATE,            20
        .equ LR_HSTATE_LOCK,           0x80

        .section .vectors,"a"
        .long 0x00100000
        .long _m3_9_reset
        .section .text,"ax"
        .globl _m3_9_reset
_m3_9_reset:
        move.w #0x2700,%sr
        move.l #0x00600000,%a0
        move.l #0x00100000,(%a0)+
        move.l #_m3_9_reset,(%a0)+
        move.l #_m3_9_default,%d0
        move.w #253,%d1
1:      move.l %d0,(%a0)+
        dbra %d1,1b
        move.l #_m3_9_aline,0x00600028
        move.l #0x50523339,0x00600408
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
        move.l #LR_HANDLE_TABLE,%a0
        moveq #47,%d0
2:      clr.l (%a0)+
        dbra %d0,2b
        move.l #LR_MASTER_BASE,%a0
        moveq #7,%d0
3:      clr.l (%a0)+
        dbra %d0,3b
        move.l #0x4d333930,0x400              /* M390 */

        /* Two handles ensure h1 cannot grow in place. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_9_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l (%a0),%a1
        move.l #0x48393941,(%a1)              /* H99A */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_9_fail

        /* HLock sets bit 7 and HGetState reports it. */
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HLOCK
        tst.w %d0
        bne.w _m3_9_fail
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HGETSTATE
        cmpi.b #LR_HSTATE_LOCK,%d0
        bne.w _m3_9_fail
        move.l #0x4c4b394f,0x404              /* LK9O */

        /* Locked non-tail handle cannot relocate to satisfy growth. */
        move.l LR_TEST_HANDLE,%a0
        move.l #0x40,%d0
        .word MAC_TRAP_SET_HANDLE_SIZE
        cmpi.w #MAC_MEM_FULL_ERR,%d0
        bne.w _m3_9_fail
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%d1
        cmp.l LR_TEST_OLD_DATA,%d1
        bne.w _m3_9_fail
        move.l #0x4c46394f,0x40c              /* LF9O */

        /* Unlock clears state; relocation can then proceed. */
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HUNLOCK
        tst.w %d0
        bne.w _m3_9_fail
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HGETSTATE
        tst.b %d0
        bne.w _m3_9_fail
        move.l LR_TEST_HANDLE,%a0
        move.l #0x40,%d0
        .word MAC_TRAP_SET_HANDLE_SIZE
        tst.w %d0
        bne.w _m3_9_fail
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        beq.w _m3_9_fail
        cmpi.l #0x48393941,(%a1)
        bne.w _m3_9_fail
        move.l #0x554c394f,0x410              /* UL9O */

        /* HSetState restores lock bit, then HGetState returns it. */
        move.l LR_TEST_HANDLE,%a0
        moveq #LR_HSTATE_LOCK,%d0
        .word MAC_TRAP_HSETSTATE
        tst.w %d0
        bne.w _m3_9_fail
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HGETSTATE
        cmpi.b #LR_HSTATE_LOCK,%d0
        bne.w _m3_9_fail
        move.l #0x5354394f,0x414              /* ST9O */

        /* Empty master pointer reports nilHandleErr. */
        move.l LR_TEST_HANDLE,%a0
        clr.l (%a0)
        .word MAC_TRAP_HLOCK
        cmpi.w #MAC_NIL_HANDLE_ERR,%d0
        bne.w _m3_9_fail
        cmpi.w #MAC_NIL_HANDLE_ERR,MAC_MEM_ERR
        bne.w _m3_9_fail
        move.l #0x4e49394f,0x418              /* NI9O */

        move.l #0x4f4b3339,0x41c              /* OK39 */
_m3_9_stop:
        stop #0x2700
        bra.w _m3_9_stop
_m3_9_fail:
        move.l #0x53564639,0x41c
        stop #0x2700
        bra.w _m3_9_fail
_m3_9_default:
        move.l #0x45584339,0x424
        rte

_m3_9_aline:
        move.l 2(%a7),%a3
        move.w (%a3),%d2
        addq.l #2,2(%a7)
        cmpi.w #MAC_TRAP_NEW_HANDLE,%d2
        beq.w _m3_9_new_handle
        cmpi.w #MAC_TRAP_DISPOSE_HANDLE,%d2
        beq.w _m3_9_dispose_handle
        cmpi.w #MAC_TRAP_SET_HANDLE_SIZE,%d2
        beq.w _m3_9_set_handle_size
        cmpi.w #MAC_TRAP_GET_HANDLE_SIZE,%d2
        beq.w _m3_9_get_handle_size
        cmpi.w #MAC_TRAP_HLOCK,%d2
        beq.w _m3_9_hlock
        cmpi.w #MAC_TRAP_HUNLOCK,%d2
        beq.w _m3_9_hunlock
        cmpi.w #MAC_TRAP_HGETSTATE,%d2
        beq.w _m3_9_hgetstate
        cmpi.w #MAC_TRAP_HSETSTATE,%d2
        beq.w _m3_9_hsetstate
        move.l #0x42414439,0x428
        stop #0x2700
        bra.w _m3_9_aline

_m3_9_new_handle:
        move.l %d0,%d4
        tst.l %d4
        beq.w _m3_9_alloc_fail
        move.l %d4,%d1
        addq.l #1,%d1
        andi.l #0xfffffffe,%d1
        move.l #LR_HANDLE_TABLE,%a1
        move.l #LR_MASTER_BASE,%a2
        moveq #LR_HANDLE_COUNT-1,%d3
4:      tst.l LR_HREC_ACTIVE(%a1)
        beq.s 5f
        adda.l #LR_HANDLE_REC_SIZE,%a1
        adda.l #4,%a2
        dbra %d3,4b
        bra.w _m3_9_alloc_fail
5:      move.l LR_HEAP_NEXT,%d2
        move.l %d2,%d6
        add.l %d1,%d6
        cmpi.l #LR_HEAP_LIMIT,%d6
        bhi.w _m3_9_alloc_fail
        move.l %d6,LR_HEAP_NEXT
        move.l %a2,LR_HREC_HANDLE(%a1)
        move.l %d2,LR_HREC_DATA(%a1)
        move.l %d4,LR_HREC_LOGICAL(%a1)
        move.l %d1,LR_HREC_EXTENT(%a1)
        move.l #1,LR_HREC_ACTIVE(%a1)
        clr.l LR_HREC_STATE(%a1)
        move.l %d2,(%a2)
        move.l %a2,%a0
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
        rte
_m3_9_alloc_fail:
        suba.l %a0,%a0
        moveq #MAC_MEM_FULL_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte

_m3_9_find_handle:
        move.l %a0,%a4
        move.l #LR_HANDLE_TABLE,%a1
        moveq #LR_HANDLE_COUNT-1,%d3
6:      cmpa.l LR_HREC_HANDLE(%a1),%a4
        bne.s 8f
        tst.l LR_HREC_ACTIVE(%a1)
        beq.s 9f
        tst.l (%a4)
        beq.s 7f
        moveq #0,%d5
        rts
7:      moveq #-1,%d5
        moveq #MAC_NIL_HANDLE_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rts
8:      adda.l #LR_HANDLE_REC_SIZE,%a1
        dbra %d3,6b
9:      moveq #-1,%d5
        moveq #MAC_MEM_WZ_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rts

_m3_9_dispose_handle:
        bsr.w _m3_9_find_handle
        tst.l %d5
        bne.s 10f
        move.l LR_HREC_HANDLE(%a1),%a2
        clr.l (%a2)
        clr.l LR_HREC_ACTIVE(%a1)
        clr.l LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
10:     rte
_m3_9_get_handle_size:
        bsr.w _m3_9_find_handle
        tst.l %d5
        bne.s 11f
        move.l LR_HREC_LOGICAL(%a1),%d0
        clr.w MAC_MEM_ERR
11:     rte

_m3_9_set_handle_size:
        move.l %d0,%d4
        move.l %d4,%d1
        addq.l #1,%d1
        andi.l #0xfffffffe,%d1
        bsr.w _m3_9_find_handle
        tst.l %d5
        bne.w 18f
        cmp.l LR_HREC_EXTENT(%a1),%d1
        bls.s 17f
        move.l LR_HREC_DATA(%a1),%d2
        add.l LR_HREC_EXTENT(%a1),%d2
        cmp.l LR_HEAP_NEXT,%d2
        beq.s 12f
        move.l LR_HREC_STATE(%a1),%d6
        btst #7,%d6
        bne.s 16f
        bra.s 13f
12:     move.l LR_HREC_DATA(%a1),%d2
        add.l %d1,%d2
        cmpi.l #LR_HEAP_LIMIT,%d2
        bhi.s 16f
        move.l %d2,LR_HEAP_NEXT
        move.l %d1,LR_HREC_EXTENT(%a1)
        bra.s 17f
13:     move.l LR_HEAP_NEXT,%d2
        move.l %d2,%d6
        add.l %d1,%d6
        cmpi.l #LR_HEAP_LIMIT,%d6
        bhi.s 16f
        move.l LR_HREC_DATA(%a1),%a2
        move.l %d2,%a3
        move.l LR_HREC_LOGICAL(%a1),%d7
        beq.s 15f
        subq.l #1,%d7
14:     move.b (%a2)+,(%a3)+
        dbra %d7,14b
15:     move.l %d6,LR_HEAP_NEXT
        move.l %d2,LR_HREC_DATA(%a1)
        move.l %d1,LR_HREC_EXTENT(%a1)
        move.l LR_HREC_HANDLE(%a1),%a2
        move.l %d2,(%a2)
        bra.s 17f
16:     moveq #MAC_MEM_FULL_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte
17:     move.l %d4,LR_HREC_LOGICAL(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
18:     rte

_m3_9_hlock:
        bsr.w _m3_9_find_handle
        tst.l %d5
        bne.s 19f
        ori.l #LR_HSTATE_LOCK,LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
19:     rte
_m3_9_hunlock:
        bsr.w _m3_9_find_handle
        tst.l %d5
        bne.s 20f
        andi.l #0xffffff7f,LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
20:     rte
_m3_9_hgetstate:
        bsr.w _m3_9_find_handle
        tst.l %d5
        bne.s 21f
        moveq #0,%d0
        move.b LR_HREC_STATE+3(%a1),%d0
        clr.w MAC_MEM_ERR
21:     rte
_m3_9_hsetstate:
        move.b %d0,%d4
        bsr.w _m3_9_find_handle
        tst.l %d5
        bne.s 22f
        moveq #0,%d6
        move.b %d4,%d6
        move.l %d6,LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
22:     rte

        .section .rodata,"a"
        .balign 4
        .ascii "LIBREROM-M3.9-HANDLE-LOCK-STATE\0"
