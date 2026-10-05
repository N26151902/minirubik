.section .text
.align 2
.globl solver_init_rv32
solver_init_rv32:
 li a0,1
 ret

.globl solver_solve_rv32
# a0=p[7],a1=o[7],a2=moves[32],a3=move_count*
solver_solve_rv32:
 beq a0,zero,9f
 beq a1,zero,9f
 beq a2,zero,9f
 beq a3,zero,9f
 addi sp,sp,-48
 sw ra,44(sp); sw s0,40(sp); sw s1,36(sp)
 mv s0,a2
 mv s1,a3
 # state at sp+16: p[0..6], o[0..6]
 li t0,0
1: li t1,7
 bgeu t0,t1,2f
 add t2,a0,t0
 lbu t3,0(t2)
 add t2,sp,t0
 sb t3,16(t2)
 add t2,a1,t0
 lbu t3,0(t2)
 add t2,sp,t0
 sb t3,23(t2)
 addi t0,t0,1
 j 1b
2: addi a0,sp,16
 call valid_rv32
 beq a0,zero,8f
 addi a0,sp,16
 call solve_v5_rv32
 beq a0,zero,8f
 la t0,solution_length
 lw t1,0(t0)
 li t2,0
 la t3,path
3: bge t2,t1,4f
 add t4,t3,t2
 lbu t5,0(t4)
 add t4,s0,t2
 sb t5,0(t4)
 addi t2,t2,1
 j 3b
4: sw t1,0(s1)
 li a0,1
 j 7f
8: li a0,0
7: lw s1,36(sp); lw s0,40(sp); lw ra,44(sp)
 addi sp,sp,48
 ret
9: li a0,0
 ret
