.section .bss
.align 2
.globl inline_p
inline_p:        .space 7
.globl inline_o
inline_o:        .space 7
.globl inline_moves
inline_moves:    .space 32
.align 2
.globl inline_move_count
inline_move_count: .space 4

.section .text
.align 2
.globl main
.type main, @function
main:
    addi sp, sp, -16
    sw   ra, 12(sp)

    call solver_init_rv32
    beqz a0, 8f

    la   a0, inline_p
    la   a1, inline_o
    call load_inline_state_rv32
    beqz a0, 7f

    la   a0, inline_p
    la   a1, inline_o
    la   a2, inline_moves
    la   a3, inline_move_count
    call solver_solve_rv32
    beqz a0, 6f

    li   a0, 0
    j    9f
6:  li   a0, 3
    j    9f
7:  li   a0, 2
    j    9f
8:  li   a0, 1
9:
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret
.size main, .-main
