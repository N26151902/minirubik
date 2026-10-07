#ifndef CUBE_STATE
#define CUBE_STATE "21345671111111"
#endif

.section .rodata
.align 2
.globl cube_state_string
cube_state_string:
    .ascii CUBE_STATE

.section .text
.align 2
.globl load_inline_state_rv32
.type load_inline_state_rv32, @function
/* a0 = p[7], a1 = o[7]. Return a0=1 on digit/range success, 0 on failure. */
load_inline_state_rv32:
    la      t0, cube_state_string
    li      t1, 0
1:
    li      t2, 7
    bgeu    t1, t2, 2f
    lbu     t3, 0(t0)
    addi    t3, t3, -49
    sltiu   t4, t3, 7
    beqz    t4, 9f
    sb      t3, 0(a0)
    lbu     t3, 7(t0)
    addi    t3, t3, -49
    sltiu   t4, t3, 3
    beqz    t4, 9f
    sb      t3, 0(a1)
    addi    t0, t0, 1
    addi    a0, a0, 1
    addi    a1, a1, 1
    addi    t1, t1, 1
    j       1b
2:
    li      a0, 1
    ret
9:
    li      a0, 0
    ret
.size load_inline_state_rv32, .-load_inline_state_rv32
