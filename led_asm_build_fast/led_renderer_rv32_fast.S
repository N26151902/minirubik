# MiniRubik 35x25 LED Matrix renderer - fast handwritten RV32I version.
# Same ABI as led_renderer_rv32.S:
#   led_render_init()                 clear the whole matrix
#   led_render_state(a0=p[7], a1=o[7]) draw the unfolded net
#   led_render_step(a0=step, a1=total) hook (no-op)
# Requires LED_MATRIX_0_BASE / _WIDTH / _HEIGHT (exported by Ripes, or by
# ripes_led_exports.S for a GNU build).
#
# Speed-ups vs. the original renderer:
#  * y*WIDTH is computed once per facelet with shifts/adds (y*35 = 32y+2y+y)
#    instead of a repeated-addition loop executed for every pixel.
#  * Pixels are written through a running pointer; a 4x3 facelet is 12 sw
#    with no per-pixel call, bounds check or stack traffic.
#  * The clear loop writes 5 words per iteration with a single pointer.

.section .rodata
.align 2
led_face_rgb:
.word 0x00ffffff,0x00ff0000,0x0000ff00,0x00ffff00,0x00ff8000,0x000000ff
led_corner_faces:
.byte 0,2,1, 3,1,2, 3,2,4, 0,1,5, 3,5,1, 3,4,5, 0,5,4, 0,4,2
led_face_x:      .byte 9,18,9,9,0,27
led_face_y:      .byte 0,7,7,14,7,7
led_face_corner:
.byte 6,3,7,0, 0,3,1,4, 7,0,2,1, 2,1,5,4, 6,7,5,2, 3,6,4,5

.equ LED_ROW_BYTES, LED_MATRIX_0_WIDTH*4
.equ LED_TOTAL_BYTES, LED_MATRIX_0_WIDTH*LED_MATRIX_0_HEIGHT*4

.section .text
.align 2
.globl led_render_init
.globl led_render_state
.globl led_render_step

led_render_init:
    li      t0, LED_MATRIX_0_BASE
    li      t1, LED_TOTAL_BYTES          # 3500 = 175 * 20
    add     t1, t0, t1
1:  sw      zero, 0(t0)
    sw      zero, 4(t0)
    sw      zero, 8(t0)
    sw      zero, 12(t0)
    sw      zero, 16(t0)
    addi    t0, t0, 20
    bltu    t0, t1, 1b
    ret

# a0 = p, a1 = o. Leaf function: uses only caller-saved registers.
led_render_state:
    la      a2, led_face_corner          # a2 -> current (face,quadrant) entry
    la      a3, led_face_x
    la      a4, led_face_y
    la      a5, led_corner_faces
    li      a6, 0                        # face
.Lface:
    li      a7, 0                        # quadrant 0..3
.Lquad:
    # ---- sticker colour index -> t2 -----------------------------------
    lbu     t0, 0(a2)                    # position
    li      t1, 7
    beq     t0, t1, .Lfixed
    add     t1, a0, t0
    lbu     t1, 0(t1)                    # cubie
    add     t2, a1, t0
    lbu     t2, 0(t2)                    # orientation
    j       .Lslot
.Lfixed:
    li      t1, 7
    li      t2, 0
.Lslot:
    slli    t3, t0, 1
    add     t3, t3, t0
    add     t3, a5, t3                   # &corner_faces[pos*3]
    lbu     t4, 0(t3)
    li      t5, 0
    beq     t4, a6, .Lfound
    lbu     t4, 1(t3)
    li      t5, 1
    beq     t4, a6, .Lfound
    lbu     t4, 2(t3)
    li      t5, 2
    beq     t4, a6, .Lfound
    mv      t2, a6                       # fallback: face's own colour
    j       .Lhave_color
.Lfound:
    addi    t5, t5, 3
    sub     t5, t5, t2                   # (slot - ori) mod 3, in 1..5
    li      t4, 3
    bltu    t5, t4, 2f
    addi    t5, t5, -3
2:  slli    t3, t1, 1
    add     t3, t3, t1
    add     t3, t3, t5
    add     t3, a5, t3
    lbu     t2, 0(t3)
.Lhave_color:
    la      t3, led_face_rgb
    slli    t2, t2, 2
    add     t3, t3, t2
    lw      t6, 0(t3)                    # rgb
    # ---- facelet origin (x,y) ------------------------------------------
    add     t3, a3, a6
    lbu     t0, 0(t3)                    # face x
    andi    t1, a7, 1
    slli    t1, t1, 2
    add     t0, t0, t1                   # x += 4*(q&1)
    add     t3, a4, a6
    lbu     t1, 0(t3)                    # face y
    srli    t2, a7, 1
    slli    t3, t2, 1
    add     t2, t2, t3
    add     t1, t1, t2                   # y += 3*(q>>1)
    # ---- pointer = BASE + 4*(y*35 + x) -----------------------------------
    slli    t2, t1, 5
    slli    t3, t1, 1
    add     t2, t2, t3
    add     t2, t2, t1                   # y*35
    add     t2, t2, t0
    slli    t2, t2, 2
    li      t3, LED_MATRIX_0_BASE
    add     t2, t2, t3
    # ---- 4x3 facelet: 12 stores ------------------------------------------
    sw      t6, 0(t2)
    sw      t6, 4(t2)
    sw      t6, 8(t2)
    sw      t6, 12(t2)
    sw      t6, LED_ROW_BYTES+0(t2)
    sw      t6, LED_ROW_BYTES+4(t2)
    sw      t6, LED_ROW_BYTES+8(t2)
    sw      t6, LED_ROW_BYTES+12(t2)
    sw      t6, 2*LED_ROW_BYTES+0(t2)
    sw      t6, 2*LED_ROW_BYTES+4(t2)
    sw      t6, 2*LED_ROW_BYTES+8(t2)
    sw      t6, 2*LED_ROW_BYTES+12(t2)
    # ---- next quadrant / face --------------------------------------------
    addi    a2, a2, 1
    addi    a7, a7, 1
    li      t0, 4
    bltu    a7, t0, .Lquad
    addi    a6, a6, 1
    li      t0, 6
    bltu    a6, t0, .Lface
    ret

led_render_step:
    ret
