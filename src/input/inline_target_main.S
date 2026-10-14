# Single-source RV32I driver for the minirubik solver.
#
# One source tree produces every build; assemble-time switches select:
#   RENDER    0 = CLI/measurement build (no LED code at all)
#             1 = GUI build: draw the net on the LED matrix, redraw after
#                 every quarter turn of the solver's actual output
#   PRINT     1 = print the returned solution through Ripes ecalls
#   SELFTEST  0 = solve the CUBE_STATE string inlined at assembly time
#             1 = run the built-in test table (solved, short scramble,
#                 distance-8/9/10 vectors, distance-11 report vector)
#   EXPECT_LEN  optional; when defined, the inline case must return a
#               solution of exactly this length (the host BFS distance)
#   LED_DELAY busy-wait iterations after each LED frame (RENDER=1)
#
# The RENDER=0 and RENDER=1 builds differ only in the `.if RENDER` blocks.
#
# Every case is validated inside the program: the returned path must be
# no longer than 11 moves (the HTM diameter), match the expected length
# when one is known, and -- applied move by move to an independent copy of
# the input with the source[]/twist[] corner model -- reach the solved state.
#
# Exit code (a0 of main, passed to ecall 93):
#   0 pass   1 solver_init failed   2 malformed 14-character string
#   3 solver rejected the state     4 wrong solution length
#   5 move id out of range          6 path does not reach solved
# SELFTEST adds 16*(case number) to the code of the first failing case.

.ifndef RENDER
.equ RENDER, 0
.endif
.ifndef PRINT
.equ PRINT, 1
.endif
.ifndef SELFTEST
.equ SELFTEST, 0
.endif
.ifndef LED_DELAY
.equ LED_DELAY, 2000
.endif

.section .rodata
.align 2
# Each destination d takes the cubie from source[face][d] and adds
# twist[face][d] to its orientation (same model as reference/solver.c).
vm_source:
    .byte 1,4,2,0,3,5,6     # R
    .byte 0,1,2,4,5,6,3     # B
    .byte 0,2,5,3,1,4,6     # D
vm_twist:
    .byte 1,2,0,2,1,0,0
    .byte 0,0,0,1,2,1,2
    .byte 0,0,0,0,0,0,0
face_letter:
    .ascii "RBD"
turn_suffix:
    .ascii " 2'"
.if PRINT
msg_state:  .asciz "state "
msg_moves:  .asciz ": "
msg_len:    .asciz " moves: "
msg_pass:   .asciz " PASS\n"
msg_fail:   .asciz " FAIL code "
.endif

.if SELFTEST
# Test table: 14-char state + NUL, then the expected optimal length
# (from the host BFS oracle).  Terminated by an empty string.
.align 2
test_cases:
    .asciz "12345671111111"     # solved, 0 moves
    .byte 0
    .asciz "25314672313211"     # short scramble, 1 move (R')
    .byte 1
    .asciz "74523162333332"     # LED demo state, 5 moves
    .byte 5
    .asciz "62345713133111"     # tests/solutions.txt, 8 moves
    .byte 8
    .asciz "24513763133333"     # tests/solutions.txt, 9 moves
    .byte 9
    .asciz "25416373331111"     # independent distance-10 state
    .byte 10
    .asciz "21345671111111"     # report vector, distance 11
    .byte 11
    .byte 0
.endif

.section .bss
.align 2
.globl inline_p
inline_p:          .space 7
.globl inline_o
inline_o:          .space 7
vm_tmp:            .space 14        # scratch copy for one quarter turn
.globl inline_moves
inline_moves:      .space 32
.align 2
.globl inline_move_count
inline_move_count: .space 4

.section .text
.align 2

# ---------------------------------------------------------------------------
# vm_quarter(a0 = face 0..2): apply one quarter turn to inline_p/inline_o.
# Leaf.  face*7 = (face<<3) - face, so no multiply is needed.
vm_quarter:
    la      t0, inline_p
    la      t1, vm_tmp
    li      t2, 0
1:  add     t3, t0, t2              # copy the 14 state bytes
    lbu     t4, 0(t3)
    add     t3, t1, t2
    sb      t4, 0(t3)
    addi    t2, t2, 1
    li      t3, 14
    bltu    t2, t3, 1b
    slli    t2, a0, 3
    sub     t2, t2, a0              # face*7
    la      t3, vm_source
    add     t3, t3, t2              # &source[face][0]
    la      t4, vm_twist
    add     t4, t4, t2              # &twist[face][0]
    li      t2, 0                   # d
2:  lbu     t5, 0(t3)               # q = source[face][d]
    add     t5, t1, t5
    lbu     t6, 0(t5)               # tmp.p[q]
    add     a1, t0, t2
    sb      t6, 0(a1)               # p[d]
    lbu     t6, 7(t5)               # tmp.o[q]
    lbu     a2, 0(t4)
    add     t6, t6, a2              # o + twist, at most 4
    addi    a2, t6, -3
    bltz    a2, 3f
    mv      t6, a2                  # mod 3 by one conditional subtract
3:  sb      t6, 7(a1)               # o[d]
    addi    t3, t3, 1
    addi    t4, t4, 1
    addi    t2, t2, 1
    li      a2, 7
    bltu    t2, a2, 2b
    ret

.if RENDER
# Draw the current inline_p/inline_o and wait LED_DELAY iterations.
show_state:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    la      a0, inline_p
    la      a1, inline_o
    call    led_render_state
    li      t0, LED_DELAY
    beqz    t0, 2f
1:  addi    t0, t0, -1
    bnez    t0, 1b
2:  lw      ra, 12(sp)
    addi    sp, sp, 16
    ret
.endif

.if PRINT
# print_solution: print "<n> moves: R B2 D' ..." for inline_moves.
print_solution:
    lw      a0, inline_move_count
    li      a7, 1
    ecall
    la      a0, msg_len
    li      a7, 4
    ecall
    la      t0, inline_moves
    lw      t1, inline_move_count
    add     t1, t0, t1
    la      t2, face_letter
    la      t3, turn_suffix
1:  bgeu    t0, t1, 3f
    lbu     t4, 0(t0)               # move id 0..8 (checked by caller)
    li      t5, 0                   # face = id / 3 without a divide
2:  addi    t6, t4, -3
    bltz    t6, 4f
    mv      t4, t6
    addi    t5, t5, 1
    j       2b
4:  add     t6, t2, t5
    lbu     a0, 0(t6)
    li      a7, 11
    ecall
    beqz    t4, 5f                  # quarter turn: no suffix
    add     t6, t3, t4
    lbu     a0, 0(t6)
    ecall
5:  li      a0, ' '
    ecall
    addi    t0, t0, 1
    j       1b
3:  ret
.endif

# ---------------------------------------------------------------------------
# run_case(a0 = 14-char string, a1 = expected length or -1) -> a0 = code
run_case:
    addi    sp, sp, -32
    sw      ra, 28(sp)
    sw      s0, 24(sp)
    sw      s1, 20(sp)
    sw      s2, 16(sp)
    sw      s3, 12(sp)
    sw      s4, 8(sp)
    sw      s5, 4(sp)
    mv      s1, a1
.if PRINT
    mv      s0, a0
    la      a0, msg_state
    li      a7, 4
    ecall
    mv      a0, s0
    ecall
    la      a0, msg_moves
    ecall
    mv      a0, s0
.endif
    la      a1, inline_p
    la      a2, inline_o
    call    parse_state_rv32
    li      s0, 2
    beqz    a0, 90f

.if RENDER
    call    led_render_init
    call    show_state              # the scramble before any move
.endif

    la      a0, inline_p
    la      a1, inline_o
    la      a2, inline_moves
    la      a3, inline_move_count
    call    solver_solve_rv32
    li      s0, 3
    beqz    a0, 90f

    lw      s2, inline_move_count
    li      s0, 4
    li      t0, 11
    bgtu    s2, t0, 90f             # also catches a negative count
    bltz    s1, 1f
    bne     s2, s1, 90f
1:
    li      s0, 5                   # every id must be 0..8 before use
    la      t0, inline_moves
    add     t1, t0, s2
2:  bgeu    t0, t1, 3f
    lbu     t2, 0(t0)
    li      t3, 9
    bgeu    t2, t3, 90f
    addi    t0, t0, 1
    j       2b
3:
.if PRINT
    call    print_solution
.endif

    # Apply the returned path to the independent corner model.
    li      s3, 0                   # move index
4:  bge     s3, s2, 7f
    la      t0, inline_moves
    add     t0, t0, s3
    lbu     t1, 0(t0)
    li      s4, 0                   # face
5:  addi    t2, t1, -3
    bltz    t2, 6f
    mv      t1, t2
    addi    s4, s4, 1
    j       5b
6:  addi    s5, t1, 1               # 1, 2 or 3 quarter turns
61: mv      a0, s4
    call    vm_quarter
.if RENDER
    call    show_state              # one frame per 90-degree turn
.endif
    addi    s5, s5, -1
    bnez    s5, 61b
    addi    s3, s3, 1
    j       4b
7:
    li      s0, 6                   # solved: p[i] == i and o[i] == 0
    la      t0, inline_p
    li      t1, 0
8:  add     t2, t0, t1
    lbu     t3, 0(t2)
    bne     t3, t1, 90f
    lbu     t3, 7(t2)
    bnez    t3, 90f
    addi    t1, t1, 1
    li      t2, 7
    bltu    t1, t2, 8b
    li      s0, 0
90:
.if PRINT
    bnez    s0, 91f
    la      a0, msg_pass
    li      a7, 4
    ecall
    j       92f
91: la      a0, msg_fail
    li      a7, 4
    ecall
    mv      a0, s0
    li      a7, 1
    ecall
    li      a0, '\n'
    li      a7, 11
    ecall
92:
.endif
    mv      a0, s0
    lw      s5, 4(sp)
    lw      s4, 8(sp)
    lw      s3, 12(sp)
    lw      s2, 16(sp)
    lw      s1, 20(sp)
    lw      s0, 24(sp)
    lw      ra, 28(sp)
    addi    sp, sp, 32
    ret

# ---------------------------------------------------------------------------
.globl main
.type main, @function
main:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      s0, 8(sp)
    sw      s1, 4(sp)
    call    solver_init_rv32
    bnez    a0, 1f
    li      a0, 1
    j       9f
1:
.if SELFTEST
    la      s0, test_cases
    li      s1, 16                  # 16 * case number, 1-based
2:  lbu     t0, 0(s0)
    beqz    t0, 8f                  # end of table
    mv      a0, s0
    lbu     a1, 15(s0)              # expected length after the NUL
    call    run_case
    bnez    a0, 3f
    addi    s0, s0, 16
    addi    s1, s1, 16
    j       2b
3:  add     a0, a0, s1
    j       9f
8:  li      a0, 0
.else
    la      a0, cube_state_string
.ifdef EXPECT_LEN
    li      a1, EXPECT_LEN
.else
    li      a1, -1
.endif
    call    run_case
.endif
9:
    lw      s1, 4(sp)
    lw      s0, 8(sp)
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret
.size main, .-main

.if RENDER
.include "ripes_led_exports_fast.S"
.endif
