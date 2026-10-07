.section .text
.align 2
.globl heuristic_v5_rv32
# a0=p,a1=o,a2=pos4,a3=ori4,a4=pos3a,a5=ori3a,a6=pos3b,a7=ori3b
heuristic_v5_rv32:
 addi sp,sp,-32
 sw ra,28(sp); sw s0,24(sp); sw s1,20(sp); sw s2,16(sp); sw s3,12(sp); sw s4,8(sp)
 mv s1,a4
 mv s2,a5
 mv s3,a6
 mv s4,a7
 la t0,perm_dist
 add t0,t0,a0
 lbu s0,0(t0)
 la t0,ori_dist
 add t0,t0,a1
 lbu t1,0(t0)
 bgeu s0,t1,1f
 mv s0,t1
1:
 mv a0,a2
 mv a1,a3
 call pattern4_rank_parts_rv32
 la t0,pattern_dist
 add t0,t0,a0
 lbu t1,0(t0)
 bgeu s0,t1,2f
 mv s0,t1
2:
 mv a0,s1
 mv a1,s2
 call pattern3_rank_parts_rv32
 la t0,pattern3a_dist
 add t0,t0,a0
 lbu t1,0(t0)
 bgeu s0,t1,3f
 mv s0,t1
3:
 mv a0,s3
 mv a1,s4
 call pattern3_rank_parts_rv32
 la t0,pattern3b_dist
 add t0,t0,a0
 lbu t1,0(t0)
 bgeu s0,t1,4f
 mv s0,t1
4:
 mv a0,s0
 lw s4,8(sp); lw s3,12(sp); lw s2,16(sp); lw s1,20(sp); lw s0,24(sp); lw ra,28(sp)
 addi sp,sp,32
 ret
