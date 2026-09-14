        .equ MAC_TRAP_NEW_PTR,      0xa11e
        .equ MAC_TRAP_DISPOSE_PTR,  0xa01f
        .equ MAC_TRAP_SET_PTR_SIZE, 0xa020
        .equ MAC_TRAP_GET_PTR_SIZE, 0xa021
        .equ MAC_NO_ERR,            0
        .equ MAC_MEM_FULL_ERR,     -108
        .equ MAC_MEM_WZ_ERR,       -111
        .equ MAC_MEM_ERR,           0x00000220
        .equ LR_HEAP_BASE,          0x00010000
        .equ LR_HEAP_LIMIT,         0x00080000
        .equ LR_HEAP_NEXT,          0x00000440
        .equ LR_TEST_P1,            0x00000448
        .equ LR_ALLOC_TABLE,        0x00000480
        .equ LR_ALLOC_COUNT,        8
        .equ LR_ALLOC_REC_SIZE,     16
        .equ LR_REC_PTR,            0
        .equ LR_REC_LOGICAL,        4
        .equ LR_REC_EXTENT,         8
        .equ LR_REC_ACTIVE,         12

        .section .vectors,"a"
_m3_6_vectors:
        .long 0x00100000
        .long _m3_6_reset

        .section .text,"ax"
        .globl _m3_6_reset
_m3_6_reset:
        move.w #0x2700,%sr
        move.l #0x00600000,%a0
        move.l #0x00100000,(%a0)+
        move.l #_m3_6_reset,(%a0)+
        move.l #_m3_6_default,%d0
        move.w #253,%d1
1:      move.l %d0,(%a0)+
        dbra %d1,1b
        move.l #_m3_6_aline,0x00600028
        move.l #0x50523336,0x00600408

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

        move.l #0x4d333630,0x400

        move.l #0x21,%d0
        .word MAC_TRAP_NEW_PTR
        tst.w %d0
        bne _m3_6_fail
        move.l %a0,LR_TEST_P1
        cmpi.l #0x00010022,LR_HEAP_NEXT
        bne _m3_6_fail
        move.l #0x4e50364f,0x404

        move.l LR_TEST_P1,%a0
        .word MAC_TRAP_GET_PTR_SIZE
        cmpi.l #0x21,%d0
        bne _m3_6_fail
        move.l #0x4750364f,0x40c

        move.l LR_TEST_P1,%a0
        move.l #0x10,%d0
        .word MAC_TRAP_SET_PTR_SIZE
        tst.w %d0
        bne _m3_6_fail
        move.l LR_TEST_P1,%a0
        .word MAC_TRAP_GET_PTR_SIZE
        cmpi.l #0x10,%d0
        bne _m3_6_fail
        move.l #0x53503653,0x410

        move.l LR_TEST_P1,%a0
        move.l #0x31,%d0
        .word MAC_TRAP_SET_PTR_SIZE
        tst.w %d0
        bne _m3_6_fail
        cmpi.l #0x00010032,LR_HEAP_NEXT
        bne _m3_6_fail
        move.l LR_TEST_P1,%a0
        .word MAC_TRAP_GET_PTR_SIZE
        cmpi.l #0x31,%d0
        bne _m3_6_fail
        move.l #0x53503647,0x414

        move.l LR_TEST_P1,%a0
        move.l #0x80000,%d0
        .word MAC_TRAP_SET_PTR_SIZE
        cmpi.w #MAC_MEM_FULL_ERR,%d0
        bne _m3_6_fail
        cmpi.w #MAC_MEM_FULL_ERR,MAC_MEM_ERR
        bne _m3_6_fail
        move.l #0x4d463636,0x418

        move.l LR_TEST_P1,%a0
        .word MAC_TRAP_DISPOSE_PTR
        tst.w %d0
        bne _m3_6_fail
        move.l LR_TEST_P1,%a0
        move.l #8,%d0
        .word MAC_TRAP_SET_PTR_SIZE
        cmpi.w #MAC_MEM_WZ_ERR,%d0
        bne _m3_6_fail
        cmpi.w #MAC_MEM_WZ_ERR,MAC_MEM_ERR
        bne _m3_6_fail
        move.l #0x575a3636,0x41c

        move.l #0x4f4b3336,0x420
_m3_6_stop:
        stop #0x2700
        bra _m3_6_stop

_m3_6_fail:
        move.l #0x53564636,0x420
        stop #0x2700
        bra _m3_6_fail

_m3_6_default:
        move.l #0x45584336,0x424
        rte

_m3_6_aline:
        move.l 2(%a7),%a3
        move.w (%a3),%d2
        addq.l #2,2(%a7)
        cmpi.w #MAC_TRAP_NEW_PTR,%d2
        beq _m3_6_new_ptr
        cmpi.w #MAC_TRAP_DISPOSE_PTR,%d2
        beq _m3_6_dispose_ptr
        cmpi.w #MAC_TRAP_SET_PTR_SIZE,%d2
        beq _m3_6_set_ptr_size
        cmpi.w #MAC_TRAP_GET_PTR_SIZE,%d2
        beq _m3_6_get_ptr_size
        move.l #0x42414436,0x430
        stop #0x2700
        bra _m3_6_aline

_m3_6_new_ptr:
        move.l %d0,%d4
        tst.l %d4
        beq _m3_6_alloc_fail
        move.l %d4,%d1
        addq.l #1,%d1
        andi.l #0xfffffffe,%d1

        move.l #LR_ALLOC_TABLE,%a1
        moveq #LR_ALLOC_COUNT-1,%d3
3:      tst.l LR_REC_ACTIVE(%a1)
        bne 4f
        tst.l LR_REC_PTR(%a1)
        beq 4f
        cmp.l LR_REC_EXTENT(%a1),%d1
        bhi 4f
        move.l %d4,LR_REC_LOGICAL(%a1)
        move.l #1,LR_REC_ACTIVE(%a1)
        move.l LR_REC_PTR(%a1),%a0
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
        rte
4:      adda.l #LR_ALLOC_REC_SIZE,%a1
        dbra %d3,3b

        move.l #LR_ALLOC_TABLE,%a1
        moveq #LR_ALLOC_COUNT-1,%d3
5:      tst.l LR_REC_PTR(%a1)
        beq 6f
        adda.l #LR_ALLOC_REC_SIZE,%a1
        dbra %d3,5b
        bra _m3_6_alloc_fail
6:      move.l LR_HEAP_NEXT,%a0
        move.l %a0,%d2
        add.l %d1,%d2
        cmpi.l #LR_HEAP_LIMIT,%d2
        bhi _m3_6_alloc_fail
        move.l %d2,LR_HEAP_NEXT
        move.l %a0,LR_REC_PTR(%a1)
        move.l %d4,LR_REC_LOGICAL(%a1)
        move.l %d1,LR_REC_EXTENT(%a1)
        move.l #1,LR_REC_ACTIVE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
        rte

_m3_6_alloc_fail:
        suba.l %a0,%a0
        moveq #MAC_MEM_FULL_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte

_m3_6_find_active:
        move.l %a0,%a4
        move.l #LR_ALLOC_TABLE,%a1
        moveq #LR_ALLOC_COUNT-1,%d3
7:      cmpa.l LR_REC_PTR(%a1),%a4
        bne 8f
        tst.l LR_REC_ACTIVE(%a1)
        beq 9f
        moveq #0,%d5
        rts
8:      adda.l #LR_ALLOC_REC_SIZE,%a1
        dbra %d3,7b
9:      moveq #-1,%d5
        moveq #MAC_MEM_WZ_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rts

_m3_6_dispose_ptr:
        bsr _m3_6_find_active
        tst.l %d5
        bne 10f
        clr.l LR_REC_ACTIVE(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
10:     suba.l %a0,%a0
        rte

_m3_6_get_ptr_size:
        bsr _m3_6_find_active
        tst.l %d5
        bne 11f
        move.l LR_REC_LOGICAL(%a1),%d0
        clr.w MAC_MEM_ERR
11:     rte

_m3_6_set_ptr_size:
        move.l %d0,%d4
        move.l %d4,%d1
        addq.l #1,%d1
        andi.l #0xfffffffe,%d1
        bsr _m3_6_find_active
        tst.l %d5
        bne 15f
        cmp.l LR_REC_EXTENT(%a1),%d1
        bls 14f
        move.l LR_REC_PTR(%a1),%d2
        add.l LR_REC_EXTENT(%a1),%d2
        cmp.l LR_HEAP_NEXT,%d2
        bne 13f
        move.l LR_REC_PTR(%a1),%d2
        add.l %d1,%d2
        cmpi.l #LR_HEAP_LIMIT,%d2
        bhi 13f
        move.l %d2,LR_HEAP_NEXT
        move.l %d1,LR_REC_EXTENT(%a1)
        bra 14f
13:     moveq #MAC_MEM_FULL_ERR,%d0
        move.w %d0,MAC_MEM_ERR
        rte
14:     move.l %d4,LR_REC_LOGICAL(%a1)
        moveq #MAC_NO_ERR,%d0
        clr.w MAC_MEM_ERR
15:     rte

        .section .rodata,"a"
        .balign 4
        .ascii "LIBREROM-M3.6-PTRSIZE-COMPAT\0"
