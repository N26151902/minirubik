.section .text
.align 2
.globl pattern3_quarter_rv32_unrolled
pattern3_quarter_rv32_unrolled:
 slli t6,a2,3
 sub t6,t6,a2
 la t3,pattern_tables_anchor
 add t3,t3,t6
 addi t4,t3,24
 lbu t0,0(a0)
 add t1,t3,t0
 lbu t0,0(t1)
 sb t0,0(a0)
 lbu t1,0(a1)
 add t2,t4,t0
 lbu t2,0(t2)
 add t1,t1,t2
 li t2,3
 bltu t1,t2,1f
 addi t1,t1,-3
1: sb t1,0(a1)
 lbu t0,1(a0)
 add t1,t3,t0
 lbu t0,0(t1)
 sb t0,1(a0)
 lbu t1,1(a1)
 add t2,t4,t0
 lbu t2,0(t2)
 add t1,t1,t2
 li t2,3
 bltu t1,t2,2f
 addi t1,t1,-3
2: sb t1,1(a1)
 lbu t0,2(a0)
 add t1,t3,t0
 lbu t0,0(t1)
 sb t0,2(a0)
 lbu t1,2(a1)
 add t2,t4,t0
 lbu t2,0(t2)
 add t1,t1,t2
 li t2,3
 bltu t1,t2,3f
 addi t1,t1,-3
3: sb t1,2(a1)
 ret

.globl pattern4_quarter_rv32_unrolled
pattern4_quarter_rv32_unrolled:
 slli t6,a2,3
 sub t6,t6,a2
 la t3,pattern_tables_anchor
 add t3,t3,t6
 addi t4,t3,24
 lbu t0,0(a0)
 add t1,t3,t0
 lbu t0,0(t1)
 sb t0,0(a0)
 lbu t1,0(a1)
 add t2,t4,t0
 lbu t2,0(t2)
 add t1,t1,t2
 li t2,3
 bltu t1,t2,4f
 addi t1,t1,-3
4: sb t1,0(a1)
 lbu t0,1(a0)
 add t1,t3,t0
 lbu t0,0(t1)
 sb t0,1(a0)
 lbu t1,1(a1)
 add t2,t4,t0
 lbu t2,0(t2)
 add t1,t1,t2
 li t2,3
 bltu t1,t2,5f
 addi t1,t1,-3
5: sb t1,1(a1)
 lbu t0,2(a0)
 add t1,t3,t0
 lbu t0,0(t1)
 sb t0,2(a0)
 lbu t1,2(a1)
 add t2,t4,t0
 lbu t2,0(t2)
 add t1,t1,t2
 li t2,3
 bltu t1,t2,6f
 addi t1,t1,-3
6: sb t1,2(a1)
 lbu t0,3(a0)
 add t1,t3,t0
 lbu t0,0(t1)
 sb t0,3(a0)
 lbu t1,3(a1)
 add t2,t4,t0
 lbu t2,0(t2)
 add t1,t1,t2
 li t2,3
 bltu t1,t2,7f
 addi t1,t1,-3
7: sb t1,3(a1)
 ret
