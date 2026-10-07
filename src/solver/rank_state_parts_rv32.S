.section .text
.align 2
.globl rank_state_parts_rv32
# a0=state, a1=perm*, a2=orient*
rank_state_parts_rv32:
 li t0,0              # p
 li t1,0              # i
1: li a3,7
 bgeu t1,a3,5f
 li t2,0              # smaller
 addi t3,t1,1         # j=i+1
 add t4,a0,t1
 lbu t5,0(t4)         # p[i]
2: li a3,7
 bgeu t3,a3,3f
 add t4,a0,t3
 lbu t6,0(t4)         # p[j]
 bgeu t6,t5,4f
 addi t2,t2,1
4: addi t3,t3,1
 j 2b
3: # p = p*(7-i)+smaller.  Since i=0..6, use a tiny
 # fixed-multiplier dispatch instead of a generic multiply/helper.
 li a3,7
 sub a3,a3,t1        # multiplier = 7-i
 li t6,1
 beq a3,t6,16f
 li t6,2
 beq a3,t6,12f
 li t6,3
 beq a3,t6,13f
 li t6,4
 beq a3,t6,14f
 li t6,5
 beq a3,t6,15f
 li t6,6
 beq a3,t6,17f
 # x7 = (p<<3)-p
 slli t3,t0,3
 sub t3,t3,t0
 j 18f
12: slli t3,t0,1     # x2
 j 18f
13: slli t3,t0,1     # x3 = 2p+p
 add t3,t3,t0
 j 18f
14: slli t3,t0,2     # x4
 j 18f
15: slli t3,t0,2     # x5 = 4p+p
 add t3,t3,t0
 j 18f
17: slli t3,t0,2     # x6 = 4p+2p
 slli t6,t0,1
 add t3,t3,t6
 j 18f
16: mv t3,t0         # x1
18: add t0,t3,t2
 addi t1,t1,1
 j 1b
5: li t1,0             # orient rank
 li t2,0              # i
9: li a3,6
 bgeu t2,a3,10f
 slli t3,t1,1         # o*2
 add t1,t3,t1         # o*3
 add t4,a0,t2
 lbu t3,7(t4)
 add t1,t1,t3
 addi t2,t2,1
 j 9b
10:
 sh t0,0(a1)
 sh t1,0(a2)
 ret
