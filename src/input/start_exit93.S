.section .bss
.align 4
stack_bottom:
    .space 4096
stack_top:

.section .text
.globl _start
_start:
    la sp, stack_top
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop
    call main
    li a7, 93
    ecall
1:
    j 1b
