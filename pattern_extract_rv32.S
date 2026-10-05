.section .text
.align 2
.globl pattern3_from_state_rv32
# a0=state, a1=cubies[3], a2=pos[3], a3=ori[3]
pattern3_from_state_rv32:
 li t0,0
1: li t6,3
 bgeu t0,t6,5f
 add t1,a1,t0
 lbu t2,0(t1)
 li t3,0
2: li t6,7
 bgeu t3,t6,4f
 add t4,a0,t3
 lbu t5,0(t4)
 beq t5,t2,3f
 addi t3,t3,1
 j 2b
3: add t4,a2,t0
 sb t3,0(t4)
 add t4,a0,t3
 lbu t5,7(t4)
 add t4,a3,t0
 sb t5,0(t4)
4: addi t0,t0,1
 j 1b
5: ret

.globl pattern4_from_state_rv32
# a0=state, a1=pos[4], a2=ori[4]; cubies={0,3,5,6}
pattern4_from_state_rv32:
 li t0,0
1: li t6,4
 bgeu t0,t6,5f
 beq t0,zero,6f
 li t1,1
 beq t0,t1,7f
 li t1,2
 beq t0,t1,8f
 li t2,6
 j 9f
6: li t2,0
 j 9f
7: li t2,3
 j 9f
8: li t2,5
9: li t3,0
2: li t6,7
 bgeu t3,t6,4f
 add t4,a0,t3
 lbu t5,0(t4)
 beq t5,t2,3f
 addi t3,t3,1
 j 2b
3: add t4,a1,t0
 sb t3,0(t4)
 add t4,a0,t3
 lbu t5,7(t4)
 add t4,a2,t0
 sb t5,0(t4)
4: addi t0,t0,1
 j 1b
5: ret
