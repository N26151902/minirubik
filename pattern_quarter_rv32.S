.section .rodata
.align 2
.Ldest:
.byte 3,0,2,4,1,5,6
.byte 0,1,2,6,3,4,5
.byte 0,4,1,3,5,2,6
.Ltwist:
.byte 1,2,0,2,1,0,0
.byte 0,0,0,1,2,1,2
.byte 0,0,0,0,0,0,0

.section .text
.align 2
.globl pattern3_quarter_rv32
# a0=pos, a1=ori, a2=face
pattern3_quarter_rv32:
 li t0,0
 li t5,7
 slli t6,a2,3
 sub t6,t6,a2          # face*7
 la t3,.Ldest
 add t3,t3,t6
 la t4,.Ltwist
 add t4,t4,t6
1: li t6,3
 bgeu t0,t6,3f
 add t1,a0,t0
 lbu t2,0(t1)
 add t5,t3,t2
 lbu t2,0(t5)          # d
 sb t2,0(t1)
 add t1,a1,t0
 lbu t5,0(t1)
 add t2,t4,t2
 lbu t2,0(t2)
 add t5,t5,t2
 li t2,3
 bltu t5,t2,2f
 addi t5,t5,-3
2: sb t5,0(t1)
 addi t0,t0,1
 j 1b
3: ret

.globl pattern4_quarter_rv32
# a0=pos, a1=ori, a2=face
pattern4_quarter_rv32:
 li t0,0
 slli t6,a2,3
 sub t6,t6,a2
 la t3,.Ldest
 add t3,t3,t6
 la t4,.Ltwist
 add t4,t4,t6
1: li t6,4
 bgeu t0,t6,3f
 add t1,a0,t0
 lbu t2,0(t1)
 add t5,t3,t2
 lbu t2,0(t5)
 sb t2,0(t1)
 add t1,a1,t0
 lbu t5,0(t1)
 add t2,t4,t2
 lbu t2,0(t2)
 add t5,t5,t2
 li t2,3
 bltu t5,t2,2f
 addi t5,t5,-3
2: sb t5,0(t1)
 addi t0,t0,1
 j 1b
3: ret

# Layout used by the iterative search hot loop: destination at +0,
# twist at +24, matching the audited C reference layout.
.section .rodata
.align 3
.globl pattern_tables_anchor
pattern_tables_anchor:
.byte 3,0,2,4,1,5,6, 0,1,2,6,3,4,5, 0,4,1,3,5,2,6
.zero 3
.byte 1,2,0,2,1,0,0, 0,0,0,1,2,1,2, 0,0,0,0,0,0,0

.align 3
.globl o3_pattern_anchor
o3_pattern_anchor:
.zero 732
.byte 3,0,2,4,1,5,6, 0,1,2,6,3,4,5, 0,4,1,3,5,2,6
.zero 3
.byte 1,2,0,2,1,0,0, 0,0,0,1,2,1,2, 0,0,0,0,0,0,0
