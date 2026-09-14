        .equ MAC_TRAP_NEW_PTR,         0xa11e
        .equ MAC_TRAP_DISPOSE_PTR,     0xa01f
        .equ MAC_TRAP_SET_PTR_SIZE,    0xa020
        .equ MAC_TRAP_GET_PTR_SIZE,    0xa021
        .equ MAC_TRAP_NEW_HANDLE,      0xa122
        .equ MAC_TRAP_DISPOSE_HANDLE,  0xa023
        .equ MAC_TRAP_SET_HANDLE_SIZE, 0xa024
        .equ MAC_TRAP_GET_HANDLE_SIZE, 0xa025
        .equ MAC_TRAP_HLOCK,           0xa029
        .equ MAC_TRAP_HUNLOCK,         0xa02a
        .equ MAC_TRAP_HPURGE,          0xa049
        .equ MAC_TRAP_HNOPURGE,        0xa04a
        .equ MAC_TRAP_HSETRBIT,        0xa067
        .equ MAC_TRAP_HCLRRBIT,        0xa068
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
        .equ LR_TEST_PTR,              0x00000448
        .equ LR_TEST_HANDLE,           0x0000044c
        .equ LR_TEST_OLD_DATA,         0x00000450

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
        .equ LR_HANDLE_REC_SIZE,       24
        .equ LR_HREC_HANDLE,           0
        .equ LR_HREC_DATA,             4
        .equ LR_HREC_LOGICAL,          8
        .equ LR_HREC_EXTENT,           12
        .equ LR_HREC_ACTIVE,           16
        .equ LR_HREC_STATE,            20
        .equ LR_HSTATE_LOCK,           0x80
        .equ LR_HSTATE_PURGE,          0x40
        .equ LR_HSTATE_RESOURCE,       0x20

        .section .vectors,"a"
        .long 0x00100000
        .long _m3_10_reset

        .section .text,"ax"
        .globl _m3_10_reset
_m3_10_reset:
        move.w #0x2700,%sr
        move.l #0x00600000,%a0
        move.l #0x00100000,(%a0)+
        move.l #_m3_10_reset,(%a0)+
        move.l #_m3_10_default,%d0
        move.w #253,%d1
1:      move.l %d0,(%a0)+
        dbra %d1,1b
        move.l #_m3_10_aline,0x00600028
        move.l #0x50523130,0x00600408      /* PR10 */

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
        moveq #47,%d0
3:      clr.l (%a0)+
        dbra %d0,3b
        move.l #LR_MASTER_BASE,%a0
        moveq #7,%d0
4:      clr.l (%a0)+
        dbra %d0,4b

        move.l #0x4d333130,0x00000400      /* M310 */

        /* Cumulative pointer services must remain present in current ROM. */
        move.l #0x21,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne.w _m3_10_fail
        move.l %a0,LR_TEST_PTR
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_GET_PTR_SIZE
        cmpi.l #0x21,%d0
        bne.w _m3_10_fail
        move.l LR_TEST_PTR,%a0
        move.l #0x10,%d0
        .word MAC_TRAP_SET_PTR_SIZE
        tst.w %d0
        bne.w _m3_10_fail
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_GET_PTR_SIZE
        cmpi.l #0x10,%d0
        bne.w _m3_10_fail
        move.l LR_TEST_PTR,%a0
        .word MAC_TRAP_DISPOSE_PTR
        tst.w %d0
        bne.w _m3_10_fail
        move.l #0x5054314f,0x00000404      /* PT1O */

        /* New handle starts unlocked, unpurgeable and non-resource. */
        move.l #0x20,%d0
        .word MAC_TRAP_NEW_HANDLE
        tst.w %d0
        bne.w _m3_10_fail
        move.l %a0,LR_TEST_HANDLE
        move.l (%a0),LR_TEST_OLD_DATA
        .word MAC_TRAP_HGETSTATE
        tst.b %d0
        bne.w _m3_10_fail

        /* Purge bit is bit 6. */
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HPURGE
        tst.w %d0
        bne.w _m3_10_fail
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HGETSTATE
        cmpi.b #LR_HSTATE_PURGE,%d0
        bne.w _m3_10_fail
        move.l #0x5055314f,0x0000040c      /* PU1O */

        /* Resource bit is bit 5 and composes with purge state. */
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HSETRBIT
        tst.w %d0
        bne.w _m3_10_fail
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HGETSTATE
        cmpi.b #0x60,%d0
        bne.w _m3_10_fail
        move.l #0x5253314f,0x00000410      /* RS1O */

        /* Lock composes with both bits. */
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HLOCK
        tst.w %d0
        bne.w _m3_10_fail
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HGETSTATE
        cmpi.b #0xe0,%d0
        bne.w _m3_10_fail
        move.l #0x4c4b314f,0x00000414      /* LK1O */

        /* Clear purge/resource independently, retaining lock. */
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HNOPURGE
        tst.w %d0
        bne.w _m3_10_fail
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HCLRRBIT
        tst.w %d0
        bne.w _m3_10_fail
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HGETSTATE
        cmpi.b #LR_HSTATE_LOCK,%d0
        bne.w _m3_10_fail
        move.l #0x434c314f,0x00000418      /* CL1O */

        /* HSetState restores all three documented property bits together. */
        move.l LR_TEST_HANDLE,%a0
        move.l #0x60,%d0
        .word MAC_TRAP_HSETSTATE
        tst.w %d0
        bne.w _m3_10_fail
        move.l LR_TEST_HANDLE,%a0
        .word MAC_TRAP_HGETSTATE
        cmpi.b #0x60,%d0
        bne.w _m3_10_fail
        move.l #0x5354314f,0x0000041c      /* ST1O */

        /* Empty handle still reports nilHandleErr. */
        move.l LR_TEST_HANDLE,%a0
        clr.l (%a0)
        .word MAC_TRAP_HPURGE
        cmpi.w #MAC_NIL_HANDLE_ERR,%d0
        bne.w _m3_10_fail
        cmpi.w #MAC_NIL_HANDLE_ERR,MAC_MEM_ERR
        bne.w _m3_10_fail
        move.l #0x4e49314f,0x00000420      /* NI1O */

        move.l #0x4f4b3130,0x00000424      /* OK10 */
_m3_10_stop:
        stop #0x2700
        bra.w _m3_10_stop

_m3_10_fail:
        move.l #0x53563130,0x00000424      /* SV10 */
        stop #0x2700
        bra.w _m3_10_fail

_m3_10_default:
        move.l #0x45583130,0x00000428      /* EX10 */
        rte

_m3_10_aline:
        move.l 2(%a7),%a3
        move.w (%a3),%d2
        addq.l #2,2(%a7)
        cmpi.w #MAC_TRAP_NEW_PTR,%d2
        beq.w _m3_10_new_ptr
        cmpi.w #MAC_TRAP_DISPOSE_PTR,%d2
        beq.w _m3_10_dispose_ptr
        cmpi.w #MAC_TRAP_SET_PTR_SIZE,%d2
        beq.w _m3_10_set_ptr_size
        cmpi.w #MAC_TRAP_GET_PTR_SIZE,%d2
        beq.w _m3_10_get_ptr_size
        cmpi.w #MAC_TRAP_NEW_HANDLE,%d2
        beq.w _m3_10_new_handle
        cmpi.w #MAC_TRAP_DISPOSE_HANDLE,%d2
        beq.w _m3_10_dispose_handle
        cmpi.w #MAC_TRAP_SET_HANDLE_SIZE,%d2
        beq.w _m3_10_set_handle_size
        cmpi.w #MAC_TRAP_GET_HANDLE_SIZE,%d2
        beq.w _m3_10_get_handle_size
        cmpi.w #MAC_TRAP_HLOCK,%d2
        beq.w _m3_10_hlock
        cmpi.w #MAC_TRAP_HUNLOCK,%d2
        beq.w _m3_10_hunlock
        cmpi.w #MAC_TRAP_HPURGE,%d2
        beq.w _m3_10_hpurge
        cmpi.w #MAC_TRAP_HNOPURGE,%d2
        beq.w _m3_10_hnopurge
        cmpi.w #MAC_TRAP_HSETRBIT,%d2
        beq.w _m3_10_hsetrbit
        cmpi.w #MAC_TRAP_HCLRRBIT,%d2
        beq.w _m3_10_hclrrbit
        cmpi.w #MAC_TRAP_HGETSTATE,%d2
        beq.w _m3_10_hgetstate
        cmpi.w #MAC_TRAP_HSETSTATE,%d2
        beq.w _m3_10_hsetstate
        move.l #0x42443130,0x0000042c      /* BD10 */
        stop #0x2700
        bra.w _m3_10_aline

/* ---- Cumulative pointer services from M3.6/M3.7 ---- */
_m3_10_new_ptr:
        move.l %d0,%d4
        tst.l %d4
        beq.w _m3_10_ptr_alloc_fail
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
        bra.w _m3_10_ptr_alloc_fail
8:      move.l LR_HEAP_NEXT,%a0
        move.l %a0,%d2
        add.l %d1,%d2
        cmpi.l #LR_HEAP_LIMIT,%d2
        bhi.w _m3_10_ptr_alloc_fail
        move.l %d2,LR_HEAP_NEXT
        move.l %a0,LR_REC_PTR(%a1)
        move.l %d4,LR_REC_LOGICAL(%a1)
        move.l %d1,LR_REC_EXTENT(%a1)
        move.l #1,LR_REC_ACTIVE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
        rte
_m3_10_ptr_alloc_fail:
        suba.l %a0,%a0
        moveq #MAC_MEM_FULL_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte

_m3_10_find_ptr:
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

_m3_10_dispose_ptr:
        bsr.w _m3_10_find_ptr
        tst.l %d5
        bne.s 12f
        clr.l LR_REC_ACTIVE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
12:     suba.l %a0,%a0
        rte

_m3_10_get_ptr_size:
        bsr.w _m3_10_find_ptr
        tst.l %d5
        bne.s 13f
        move.l LR_REC_LOGICAL(%a1),%d0
        clr.w MAC_MEM_ERR
13:     rte

_m3_10_set_ptr_size:
        move.l %d0,%d4
        move.l %d4,%d1
        addq.l #1,%d1
        andi.l #0xfffffffe,%d1
        bsr.w _m3_10_find_ptr
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

/* ---- Handle allocation/sizing/state ---- */
_m3_10_new_handle:
        move.l %d0,%d4
        tst.l %d4
        beq.w _m3_10_handle_alloc_fail
        move.l %d4,%d1
        addq.l #1,%d1
        andi.l #0xfffffffe,%d1
        move.l #LR_HANDLE_TABLE,%a1
        move.l #LR_MASTER_BASE,%a2
        moveq #LR_HANDLE_COUNT-1,%d3
18:     tst.l LR_HREC_ACTIVE(%a1)
        beq.s 19f
        adda.l #LR_HANDLE_REC_SIZE,%a1
        adda.l #4,%a2
        dbra %d3,18b
        bra.w _m3_10_handle_alloc_fail
19:     move.l LR_HEAP_NEXT,%d2
        move.l %d2,%d6
        add.l %d1,%d6
        cmpi.l #LR_HEAP_LIMIT,%d6
        bhi.w _m3_10_handle_alloc_fail
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
_m3_10_handle_alloc_fail:
        suba.l %a0,%a0
        moveq #MAC_MEM_FULL_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte

_m3_10_find_handle:
        move.l %a0,%a4
        move.l #LR_HANDLE_TABLE,%a1
        moveq #LR_HANDLE_COUNT-1,%d3
20:     cmpa.l LR_HREC_HANDLE(%a1),%a4
        bne.s 22f
        tst.l LR_HREC_ACTIVE(%a1)
        beq.s 23f
        tst.l (%a4)
        beq.s 21f
        moveq #0,%d5
        rts
21:     moveq #-1,%d5
        moveq #MAC_NIL_HANDLE_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rts
22:     adda.l #LR_HANDLE_REC_SIZE,%a1
        dbra %d3,20b
23:     moveq #-1,%d5
        moveq #MAC_MEM_WZ_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rts

_m3_10_dispose_handle:
        bsr.w _m3_10_find_handle
        tst.l %d5
        bne.s 24f
        move.l LR_HREC_HANDLE(%a1),%a2
        clr.l (%a2)
        clr.l LR_HREC_ACTIVE(%a1)
        clr.l LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
24:     rte

_m3_10_get_handle_size:
        bsr.w _m3_10_find_handle
        tst.l %d5
        bne.s 25f
        move.l LR_HREC_LOGICAL(%a1),%d0
        clr.w MAC_MEM_ERR
25:     rte

_m3_10_set_handle_size:
        move.l %d0,%d4
        move.l %d4,%d1
        addq.l #1,%d1
        andi.l #0xfffffffe,%d1
        bsr.w _m3_10_find_handle
        tst.l %d5
        bne.w 32f
        cmp.l LR_HREC_EXTENT(%a1),%d1
        bls.s 31f
        move.l LR_HREC_DATA(%a1),%d2
        add.l LR_HREC_EXTENT(%a1),%d2
        cmp.l LR_HEAP_NEXT,%d2
        beq.s 26f
        move.l LR_HREC_STATE(%a1),%d6
        btst #7,%d6
        bne.s 30f
        bra.s 27f
26:     move.l LR_HREC_DATA(%a1),%d2
        add.l %d1,%d2
        cmpi.l #LR_HEAP_LIMIT,%d2
        bhi.s 30f
        move.l %d2,LR_HEAP_NEXT
        move.l %d1,LR_HREC_EXTENT(%a1)
        bra.s 31f
27:     move.l LR_HEAP_NEXT,%d2
        move.l %d2,%d6
        add.l %d1,%d6
        cmpi.l #LR_HEAP_LIMIT,%d6
        bhi.s 30f
        move.l LR_HREC_DATA(%a1),%a2
        move.l %d2,%a3
        move.l LR_HREC_LOGICAL(%a1),%d7
        beq.s 29f
28:     move.b (%a2)+,(%a3)+
        subq.l #1,%d7
        bne.s 28b
29:     move.l %d6,LR_HEAP_NEXT
        move.l %d2,LR_HREC_DATA(%a1)
        move.l %d1,LR_HREC_EXTENT(%a1)
        move.l LR_HREC_HANDLE(%a1),%a2
        move.l %d2,(%a2)
        bra.s 31f
30:     moveq #MAC_MEM_FULL_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte
31:     move.l %d4,LR_HREC_LOGICAL(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
32:     rte

_m3_10_hlock:
        bsr.w _m3_10_find_handle
        tst.l %d5
        bne.s 33f
        ori.l #LR_HSTATE_LOCK,LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
33:     rte
_m3_10_hunlock:
        bsr.w _m3_10_find_handle
        tst.l %d5
        bne.s 34f
        andi.l #0xffffff7f,LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
34:     rte
_m3_10_hpurge:
        bsr.w _m3_10_find_handle
        tst.l %d5
        bne.s 35f
        ori.l #LR_HSTATE_PURGE,LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
35:     rte
_m3_10_hnopurge:
        bsr.w _m3_10_find_handle
        tst.l %d5
        bne.s 36f
        andi.l #0xffffffbf,LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
36:     rte
_m3_10_hsetrbit:
        bsr.w _m3_10_find_handle
        tst.l %d5
        bne.s 37f
        ori.l #LR_HSTATE_RESOURCE,LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
37:     rte
_m3_10_hclrrbit:
        bsr.w _m3_10_find_handle
        tst.l %d5
        bne.s 38f
        andi.l #0xffffffdf,LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
38:     rte
_m3_10_hgetstate:
        bsr.w _m3_10_find_handle
        tst.l %d5
        bne.s 39f
        moveq #0,%d0
        move.b LR_HREC_STATE+3(%a1),%d0
        clr.w MAC_MEM_ERR
39:     rte
_m3_10_hsetstate:
        move.b %d0,%d4
        bsr.w _m3_10_find_handle
        tst.l %d5
        bne.s 40f
        moveq #0,%d6
        move.b %d4,%d6
        andi.l #0x000000e0,%d6
        move.l %d6,LR_HREC_STATE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
40:     rte

        .section .rodata,"a"
        .balign 4
        .ascii "LIBREROM-M3.10-CUMULATIVE-MEMORY-STATE\0"
