.section .text
.align 2
.globl valid_rv32
valid_rv32:
 li t0,0
 li t1,0
1: li t6,7
 bgeu t0,t6,5f
 add t4,a0,t0
 lbu t2,0(t4)
 lbu t3,7(t4)
 li t6,7
 bgeu t2,t6,9f
 li t6,3
 bgeu t3,t6,9f
 li t4,0
2: bgeu t4,t0,3f
 add t5,a0,t4
 lbu t5,0(t5)
 beq t5,t2,9f
 addi t4,t4,1
 j 2b
3: add t1,t1,t3
 addi t0,t0,1
 j 1b
5: li t6,12
 bltu t1,t6,6f
 addi t1,t1,-12
6: li t6,6
 bltu t1,t6,7f
 addi t1,t1,-6
7: li t6,3
 bltu t1,t6,8f
 addi t1,t1,-3
8: seqz a0,t1
 ret
9: li a0,0
 ret
