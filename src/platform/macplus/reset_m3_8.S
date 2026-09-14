        .equ MAC_TRAP_NEW_PTR,         0xa11e
        .equ MAC_TRAP_DISPOSE_PTR,     0xa01f
        .equ MAC_TRAP_NEW_HANDLE,      0xa122
        .equ MAC_TRAP_DISPOSE_HANDLE,  0xa023
        .equ MAC_TRAP_SET_HANDLE_SIZE, 0xa024
        .equ MAC_TRAP_GET_HANDLE_SIZE, 0xa025
        .equ MAC_NO_ERR,               0
        .equ MAC_MEM_FULL_ERR,        -108
        .equ MAC_MEM_WZ_ERR,          -111
        .equ MAC_MEM_ERR,              0x00000220

        .equ LR_HEAP_BASE,             0x00010000
        .equ LR_HEAP_LIMIT,            0x00080000
        .equ LR_HEAP_NEXT,             0x00000440
        .equ LR_TEST_HANDLE,           0x00000448
        .equ LR_TEST_OLD_DATA,         0x0000044c
        .equ LR_TEST_BLOCKER,          0x00000450

        .equ LR_ALLOC_TABLE,           0x00000480
        .equ LR_ALLOC_COUNT,           8
        .equ LR_ALLOC_REC_SIZE,        16
        .equ LR_REC_PTR,               0
        .equ LR_REC_LOGICAL,           4
        .equ LR_REC_EXTENT,            8
        .equ LR_REC_ACTIVE,            12

        .equ LR_MASTER_BASE,           0x00007000
        .equ LR_HANDLE_TABLE,          0x00000500
        .equ LR_HANDLE_COUNT,          8
        .equ LR_HANDLE_REC_SIZE,       20
        .equ LR_HREC_HANDLE,           0
        .equ LR_HREC_DATA,             4
        .equ LR_HREC_LOGICAL,          8
        .equ LR_HREC_EXTENT,           12
        .equ LR_HREC_ACTIVE,           16

        .section .vectors,"a"
        .long 0x00100000
        .long _m3_8_reset

        .section .text,"ax"
        .globl _m3_8_reset
_m3_8_reset:
        move.w #0x2700,%sr
        move.l #0x00600000,%a0
        move.l #0x00100000,(%a0)+
        move.l #_m3_8_reset,(%a0)+
        move.l #_m3_8_default,%d0
        move.w #253,%d1
1:      move.l %d0,(%a0)+
        dbra %d1,1b
        move.l #_m3_8_aline,0x00600028
        move.l #0x50523338,0x00600408      /* PR38 */

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

        move.l #0x4d333830,0x00000400      /* M380 */

        /* Create a handle with an odd logical size. */
        move.l #0x21,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_8_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        move.l (%a0),%a1
        move.l #0x48443841,(%a1)           /* HD8A */
        move.l #0x48443842,4(%a1)          /* HD8B */
        move.l #0x4e48384f,0x00000404      /* NH8O */

        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_GET_HANDLE_SIZE
        cmpi.l #0x21,%d0
        bne.w _m3_8_fail
        move.l #0x4748384f,0x0000040c      /* GH8O */

        /* Place a pointer after the handle so growth cannot be in-place. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_8_fail
        move.l %a0,LR_TEST_BLOCKER
        move.l #0x424c4b38,(%a0)           /* BLK8 */

        /* Grow: handle must stay stable while the data block relocates. */
        move.l LR_TEST_HANDLE,%a0
        move.l #0x31,%d0
        .word MAC_TRAP_SET_HANDLE_SIZE
        tst.w %d0
        bne.w _m3_8_fail
        move.l LR_TEST_HANDLE,%a0
        cmpa.l #LR_MASTER_BASE,%a0
        bne.w _m3_8_fail
        move.l (%a0),%a1
        cmpa.l LR_TEST_OLD_DATA,%a1
        beq.w _m3_8_fail
        cmpi.l #0x48443841,(%a1)
        bne.w _m3_8_fail
        cmpi.l #0x48443842,4(%a1)
        bne.w _m3_8_fail
        move.l #0x524c384f,0x00000410      /* RL8O */

        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_GET_HANDLE_SIZE
        cmpi.l #0x31,%d0
        bne.w _m3_8_fail
        move.l #0x4752384f,0x00000414      /* GR8O */

        /* Shrink is logical-only; handle and data address remain valid. */
        move.l LR_TEST_HANDLE,%a0
        move.l (%a0),%d6
        move.l #0x10,%d0
        .word MAC_TRAP_SET_HANDLE_SIZE
        tst.w %d0
        bne.w _m3_8_fail
        move.l LR_TEST_HANDLE,%a0
        cmp.l (%a0),%d6
        bne.w _m3_8_fail
        .word MAC_TRAP_GET_HANDLE_SIZE
        cmpi.l #0x10,%d0
        bne.w _m3_8_fail
        move.l #0x5348384f,0x00000418      /* SH8O */

        /* Disposed handles reject size queries deterministically. */
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_DISPOSE_HANDLE
        tst.w %d0
        bne.w _m3_8_fail
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_GET_HANDLE_SIZE
        cmpi.w #MAC_MEM_WZ_ERR,%d0
        bne.w _m3_8_fail
        cmpi.w #MAC_MEM_WZ_ERR,MAC_MEM_ERR
        bne.w _m3_8_fail
        move.l #0x575a3838,0x0000041c      /* WZ88 */

        move.l #0x4f4b3338,0x00000420      /* OK38 */
_m3_8_stop:
        stop #0x2700
        bra.w _m3_8_stop

_m3_8_fail:
        move.l #0x53564638,0x00000420      /* SVF8 */
        stop #0x2700
        bra.w _m3_8_fail

_m3_8_default:
        move.l #0x45584338,0x00000424      /* EXC8 */
        rte

_m3_8_aline:
        move.l 2(%a7),%a3
        move.w (%a3),%d2
        addq.l #2,2(%a7)
        cmpi.w #MAC_TRAP_NEW_PTR,%d2
        beq.w _m3_8_new_ptr
        cmpi.w #MAC_TRAP_DISPOSE_PTR,%d2
        beq.w _m3_8_dispose_ptr
        cmpi.w #MAC_TRAP_NEW_HANDLE,%d2
        beq.w _m3_8_new_handle
        cmpi.w #MAC_TRAP_DISPOSE_HANDLE,%d2
        beq.w _m3_8_dispose_handle
        cmpi.w #MAC_TRAP_SET_HANDLE_SIZE,%d2
        beq.w _m3_8_set_handle_size
        cmpi.w #MAC_TRAP_GET_HANDLE_SIZE,%d2
        beq.w _m3_8_get_handle_size
        move.l #0x42414438,0x00000428      /* BAD8 */
        stop #0x2700
        bra.w _m3_8_aline

_m3_8_new_ptr:
        move.l %d0,%d4
        tst.l %d4
        beq.w _m3_8_ptr_fail
        move.l %d4,%d1
        addq.l #1,%d1
        andi.l #0xfffffffe,%d1
        move.l #LR_ALLOC_TABLE,%a1
        moveq #LR_ALLOC_COUNT-1,%d3
5:      tst.l LR_REC_PTR(%a1)
        beq.s 6f
        adda.l #LR_ALLOC_REC_SIZE,%a1
        dbra %d3,5b
        bra.w _m3_8_ptr_fail
6:      move.l LR_HEAP_NEXT,%a0
        move.l %a0,%d2
        add.l %d1,%d2
        cmpi.l #LR_HEAP_LIMIT,%d2
        bhi.w _m3_8_ptr_fail
        move.l %d2,LR_HEAP_NEXT
        move.l %a0,LR_REC_PTR(%a1)
        move.l %d4,LR_REC_LOGICAL(%a1)
        move.l %d1,LR_REC_EXTENT(%a1)
        move.l #1,LR_REC_ACTIVE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
        rte
_m3_8_ptr_fail:
        suba.l %a0,%a0
        moveq #MAC_MEM_FULL_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte

_m3_8_dispose_ptr:
        move.l %a0,%a4
        move.l #LR_ALLOC_TABLE,%a1
        moveq #LR_ALLOC_COUNT-1,%d3
7:      cmpa.l LR_REC_PTR(%a1),%a4
        bne.s 8f
        tst.l LR_REC_ACTIVE(%a1)
        beq.s 9f
        clr.l LR_REC_ACTIVE(%a1)
        suba.l %a0,%a0
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
        rte
8:      adda.l #LR_ALLOC_REC_SIZE,%a1
        dbra %d3,7b
9:      suba.l %a0,%a0
        moveq #MAC_MEM_WZ_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte

_m3_8_new_handle:
        move.l %d0,%d4
        tst.l %d4
        beq.w _m3_8_handle_fail
        move.l %d4,%d1
        addq.l #1,%d1
        andi.l #0xfffffffe,%d1
        move.l #LR_HANDLE_TABLE,%a1
        move.l #LR_MASTER_BASE,%a2
        moveq #LR_HANDLE_COUNT-1,%d3
10:     tst.l LR_HREC_ACTIVE(%a1)
        beq.s 11f
        adda.l #LR_HANDLE_REC_SIZE,%a1
        adda.l #4,%a2
        dbra %d3,10b
        bra.w _m3_8_handle_fail
11:     move.l LR_HEAP_NEXT,%d2
        move.l %d2,%d6
        add.l %d1,%d6
        cmpi.l #LR_HEAP_LIMIT,%d6
        bhi.w _m3_8_handle_fail
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
_m3_8_handle_fail:
        suba.l %a0,%a0
        moveq #MAC_MEM_FULL_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte

_m3_8_find_handle:
        move.l %a0,%a4
        move.l #LR_HANDLE_TABLE,%a1
        moveq #LR_HANDLE_COUNT-1,%d3
12:     cmpa.l LR_HREC_HANDLE(%a1),%a4
        bne.s 13f
        tst.l LR_HREC_ACTIVE(%a1)
        beq.s 14f
        moveq #0,%d5
        rts
13:     adda.l #LR_HANDLE_REC_SIZE,%a1
        dbra %d3,12b
14:     moveq #-1,%d5
        moveq #MAC_MEM_WZ_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rts

_m3_8_dispose_handle:
        bsr.w _m3_8_find_handle
        tst.l %d5
        bne.s 15f
        move.l LR_HREC_HANDLE(%a1),%a2
        clr.l (%a2)
        clr.l LR_HREC_ACTIVE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
15:     rte

_m3_8_get_handle_size:
        bsr.w _m3_8_find_handle
        tst.l %d5
        bne.s 16f
        move.l LR_HREC_LOGICAL(%a1),%d0
        clr.w MAC_MEM_ERR
16:     rte

_m3_8_set_handle_size:
        move.l %d0,%d4
        move.l %d4,%d1
        addq.l #1,%d1
        andi.l #0xfffffffe,%d1
        bsr.w _m3_8_find_handle
        tst.l %d5
        bne.w 22f
        cmp.l LR_HREC_EXTENT(%a1),%d1
        bls.s 21f

        /* Grow in place only if this block is at heap top. */
        move.l LR_HREC_DATA(%a1),%d2
        add.l LR_HREC_EXTENT(%a1),%d2
        cmp.l LR_HEAP_NEXT,%d2
        bne.s 17f
        move.l LR_HREC_DATA(%a1),%d2
        add.l %d1,%d2
        cmpi.l #LR_HEAP_LIMIT,%d2
        bhi.s 20f
        move.l %d2,LR_HEAP_NEXT
        move.l %d1,LR_HREC_EXTENT(%a1)
        bra.s 21f

        /* Relocate on growth: copy old logical bytes and retarget master ptr. */
17:     move.l LR_HEAP_NEXT,%d2
        move.l %d2,%d6
        add.l %d1,%d6
        cmpi.l #LR_HEAP_LIMIT,%d6
        bhi.s 20f
        move.l LR_HREC_DATA(%a1),%a2
        move.l %d2,%a3
        move.l LR_HREC_LOGICAL(%a1),%d7
        beq.s 19f
        subq.l #1,%d7
18:     move.b (%a2)+,(%a3)+
        dbra %d7,18b
19:     move.l %d6,LR_HEAP_NEXT
        move.l %d2,LR_HREC_DATA(%a1)
        move.l %d1,LR_HREC_EXTENT(%a1)
        move.l LR_HREC_HANDLE(%a1),%a2
        move.l %d2,(%a2)
        bra.s 21f
20:     moveq #MAC_MEM_FULL_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte
21:     move.l %d4,LR_HREC_LOGICAL(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
22:     rte

        .section .rodata,"a"
        .balign 4
        .ascii "LIBREROM-M3.8-HANDLE-SIZING-RELOCATION\0"
