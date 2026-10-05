.section .text
.align 2
.globl solve_v5_rv32
# a0=state*
solve_v5_rv32:
 addi sp,sp,-80
 sw ra,76(sp); sw s0,72(sp); sw s1,68(sp); sw s2,64(sp); sw s3,60(sp)
 mv s0,a0
 # po at 8,10
 addi a1,sp,8
 addi a2,sp,10
 call rank_state_parts_rv32
 lhu s1,8(sp)
 lhu s2,10(sp)
 # pos4 12, ori4 16
 mv a0,s0
 addi a1,sp,12
 addi a2,sp,16
 call pattern4_from_state_rv32
 # pos3a 20 ori3a 24
 mv a0,s0
 la a1,pattern3a_cubies
 addi a2,sp,20
 addi a3,sp,24
 call pattern3_from_state_rv32
 # pos3b 28 ori3b 32
 mv a0,s0
 la a1,pattern3b_cubies
 addi a2,sp,28
 addi a3,sp,32
 call pattern3_from_state_rv32
 # initial heuristic
 mv a0,s1; mv a1,s2
 addi a2,sp,12; addi a3,sp,16
 addi a4,sp,20; addi a5,sp,24
 addi a6,sp,28; addi a7,sp,32
 call heuristic_v5_rv32
 mv s3,a0
 la t0,solution_length
 sw zero,0(t0)
1: li t0,32
 bgt s3,t0,4f
 # ninth arg bound at caller stack slot 0
 sw s3,0(sp)
 mv a0,s1; mv a1,s2
 addi a2,sp,12; addi a3,sp,16
 addi a4,sp,20; addi a5,sp,24
 addi a6,sp,28; addi a7,sp,32
 call search_v5_rv32_handwritten_final
 li t0,-1
 beq a0,t0,3f
 ble a0,s3,4f
 mv s3,a0
 j 1b
3: li a0,1
 j 5f
4: li a0,0
5: lw s3,60(sp); lw s2,64(sp); lw s1,68(sp); lw s0,72(sp); lw ra,76(sp)
 addi sp,sp,80
 ret
