#ifndef CUBE_STATE
#define CUBE_STATE "21345671111111"
#endif

/* The 14-character input state, inlined at assembly time:
 * 7 permutation digits '1'..'7' followed by 7 orientation digits '1'..'3'. */
.section .rodata
.align 2
.globl cube_state_string
cube_state_string:
    .ascii CUBE_STATE
    .byte 0

.section .text
.align 2

/* a0 = 14-char string, a1 = p[7], a2 = o[7].
 * Converts to the zero-based p/o arrays used by the solver.
 * Returns a0 = 1 when all 14 characters are in range and the string is
 * exactly 14 characters long, 0 otherwise.  Duplicate cubies and the
 * orientation-sum invariant are checked later by valid_rv32. */
.globl parse_state_rv32
.type parse_state_rv32, @function
parse_state_rv32:
    lbu     t3, 14(a0)              # must be NUL: exactly 14 characters
    bnez    t3, 9f
    addi    t5, a0, 7               # end of the permutation half
1:
    lbu     t3, 0(a0)
    addi    t3, t3, -49             # '1' -> 0
    sltiu   t4, t3, 7
    beqz    t4, 9f
    sb      t3, 0(a1)
    lbu     t3, 7(a0)
    addi    t3, t3, -49
    sltiu   t4, t3, 3
    beqz    t4, 9f
    sb      t3, 0(a2)
    addi    a0, a0, 1
    addi    a1, a1, 1
    addi    a2, a2, 1
    bltu    a0, t5, 1b
    li      a0, 1
    ret
9:
    li      a0, 0
    ret
.size parse_state_rv32, .-parse_state_rv32

/* Backward-compatible wrapper: a0 = p[7], a1 = o[7]; parses CUBE_STATE. */
.globl load_inline_state_rv32
.type load_inline_state_rv32, @function
load_inline_state_rv32:
    mv      a2, a1
    mv      a1, a0
    la      a0, cube_state_string
    j       parse_state_rv32
.size load_inline_state_rv32, .-load_inline_state_rv32
