.section .text
.align 2

.globl pattern3_rank_parts_rv32
# a0=pos[3], a1=ori[3], returns a0=rank (0..5669)
pattern3_rank_parts_rv32:
    lbu t0,0(a0)          # q0 = pos0
    lbu t1,1(a0)          # pos1
    lbu t2,2(a0)          # pos2
    sltu t3,t0,t1
    sub t1,t1,t3          # q1
    sltu t3,t0,t2
    sub t2,t2,t3
    lbu t4,1(a0)
    sltu t3,t4,t2         # WRONG if using adjusted t2; reload original below
    lbu t5,2(a0)
    sltu t3,t4,t5
    sub t2,t2,t3          # q2
    slli t3,t0,2
    slli t4,t0,1
    add t3,t3,t4
    add t3,t3,t1          # pr=q0*6+q1
    slli t4,t3,2
    add t3,t4,t3
    add t3,t3,t2          # pr=pr*5+q2

    lbu t0,0(a1)
    slli t2,t0,1
    add t2,t2,t0
    lbu t0,1(a1)
    add t2,t2,t0
    slli t0,t2,1
    add t2,t0,t2
    lbu t0,2(a1)
    add t2,t2,t0          # orank

    # rank = pr*27 + orank = 16+8+2+1
    slli t0,t3,4
    slli t1,t3,3
    add t0,t0,t1
    slli t1,t3,1
    add t0,t0,t1
    add t0,t0,t3
    add a0,t0,t2
    ret

.globl pattern4_rank_parts_rv32
# a0=pos[4], a1=ori[4], returns a0=rank (0..68039)
pattern4_rank_parts_rv32:
    lbu t0,0(a0)          # p0/q0
    lbu t1,1(a0)          # p1
    lbu t2,2(a0)          # p2
    lbu t3,3(a0)          # p3
    sltu t4,t0,t1
    sub t1,t1,t4          # q1
    sltu t4,t0,t2
    sub t5,t2,t4
    lbu t6,1(a0)
    sltu t4,t6,t2
    sub t5,t5,t4          # q2
    sltu t4,t0,t3
    sub t2,t3,t4
    lbu t6,1(a0)
    sltu t4,t6,t3
    sub t2,t2,t4
    lbu t6,2(a0)
    sltu t4,t6,t3
    sub t2,t2,t4          # q3

    slli t3,t0,2
    slli t4,t0,1
    add t3,t3,t4
    add t3,t3,t1          # pr=q0*6+q1
    slli t4,t3,2
    add t3,t4,t3
    add t3,t3,t5          # *5+q2
    slli t3,t3,2
    add t3,t3,t2          # *4+q3

    lbu t0,0(a1)
    slli t2,t0,1
    add t2,t2,t0
    lbu t0,1(a1)
    add t2,t2,t0
    slli t0,t2,1
    add t2,t0,t2
    lbu t0,2(a1)
    add t2,t2,t0
    slli t0,t2,1
    add t2,t0,t2
    lbu t0,3(a1)
    add t2,t2,t0          # orank

    # rank=pr*81+orank = 64+16+1
    slli t0,t3,6
    slli t1,t3,4
    add t0,t0,t1
    add t0,t0,t3
    add a0,t0,t2
    ret
