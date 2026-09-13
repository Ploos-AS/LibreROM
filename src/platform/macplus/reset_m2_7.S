/* LibreROM M2.7 Macintosh Plus framebuffer diagnostic.
 * Project-authored clean-room firmware code.
 *
 * Extends the ordered M2.6 reset-overlay hand-off with a deterministic
 * 512x342 1bpp diagnostic pattern in both documented Mac Plus screen buffers.
 */

        .section .vectors,"a"
        .globl _m2_7_vectors
_m2_7_vectors:
        .long   0x00100000
        .long   _m2_7_reset

        .section .text,"ax"
        .globl _m2_7_reset
_m2_7_reset:
        move.w  #0x2700,%sr

        /* Non-destructive top-of-RAM probe through the alternate window. */
        move.l  #0x006ffffc,%a0
        move.l  (%a0),%d3
        move.l  #0xa55aa55a,(%a0)
        move.l  (%a0),%d2
        cmpi.l  #0xa55aa55a,%d2
        bne.w   _m2_7_ram_fail_alt
        move.l  %d3,(%a0)

        /* Install all 256 vectors in backing RAM before overlay removal. */
        move.l  #0x00600000,%a0
        move.l  #0x00100000,(%a0)+
        move.l  #_m2_7_reset,(%a0)+
        move.l  #_m2_7_default,%d0
        move.w  #253,%d1
1:
        move.l  %d0,(%a0)+
        dbra    %d1,1b

        move.l  #0x00600408,%a0
        move.l  #0x50524537,(%a0)       /* "PRE7" */

        .globl _m2_7_before_overlay_off
_m2_7_before_overlay_off:
        move.l  #0x00efe600,%a0
        move.b  (%a0),%d0
        ori.b   #0x10,%d0
        move.b  %d0,(%a0)

        move.l  #0x00efe200,%a0
        move.b  (%a0),%d0
        andi.b  #0xef,%d0
        move.b  %d0,(%a0)

        /* Verify low RAM vectors after the overlay hand-off. */
        move.l  #0x00000000,%a0
        move.l  (%a0)+,%d2
        cmpi.l  #0x00100000,%d2
        bne.w   _m2_7_ram_fail_low
        move.l  (%a0),%d2
        cmpi.l  #_m2_7_reset,%d2
        bne.w   _m2_7_ram_fail_low

        move.l  #0x00000400,%a0
        move.l  #0x4c524d37,(%a0)       /* "LRM7" */

        /* Keep the qualification stack below both framebuffer regions. */
        move.l  #0x000f0000,%a7
        trap    #0

        /*
         * Mac Plus 1 MiB video buffers:
         *   main = RAM end - 0x5900 = 0x000fa700
         *   alt  = RAM end - 0xd900 = 0x000f2700
         * Visible 512x342x1bpp payload = 21888 bytes = 10944 words.
         * 0xaa55 produces an unmistakable project-authored stripe pattern.
         */
        move.w  #0xaa55,%d0
        move.w  #10943,%d1
        move.l  #0x000fa700,%a0
2:
        move.w  %d0,(%a0)+
        dbra    %d1,2b

        move.w  #10943,%d1
        move.l  #0x000f2700,%a0
3:
        move.w  %d0,(%a0)+
        dbra    %d1,3b

        move.l  #0x0000040c,%a0
        move.l  #0x56494437,(%a0)       /* "VID7" */

        .globl _m2_7_stop
_m2_7_stop:
        stop    #0x2700
        bra.w   _m2_7_stop

_m2_7_ram_fail_alt:
        move.l  #0x00600400,%a0
        move.l  #0x52414637,(%a0)       /* "RAF7" */
        stop    #0x2700
        bra.w   _m2_7_ram_fail_alt

_m2_7_ram_fail_low:
        move.l  #0x00000400,%a0
        move.l  #0x52414d37,(%a0)       /* "RAM7" */
        stop    #0x2700
        bra.w   _m2_7_ram_fail_low

        .globl _m2_7_default
_m2_7_default:
        move.l  #0x00000404,%a0
        move.l  #0x45584337,(%a0)       /* "EXC7" */
        rte

        .section .rodata,"a"
        .balign 4
_m2_7_marker:
        .ascii  "LIBREROM-M2.7-MACPLUS-VIDEO\0"
