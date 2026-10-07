.section .text
.align 2
.globl search_v5_rv32_handwritten

# Fully handwritten iterative IDA* search.
# a0=start_p, a1=start_o
# a2=pos4, a3=ori4, a4=pos3a, a5=ori3a, a6=pos3b, a7=ori3b
# ninth argument bound is at 0(caller_sp)
#
# Frame layout (fixed s3 base):
#   0..67    p_stack[33]       (uint16_t, padded)
#   68..135  o_stack[33]       (uint16_t, padded)
#   136..267 pos4[33][4]
#   268..399 ori4[33][4]
#   400..499 pos3a[33][3]      (padded)
#   500..599 ori3a[33][3]
#   600..699 pos3b[33][3]
#   700..799 ori3b[33][3]
#   800..835 next_face[33]     (padded)
#   836..871 next_turn[33]
#   872..903 path_face[32]
#   904..    saved registers
#
# s0=depth, s1=bound, s2=minimum, s3=frame base
# s4=candidate face, s5=candidate turn
# s6=np, s7=no

.equ P_STACK,       0
.equ O_STACK,       68
.equ POS4_STACK,    136
.equ ORI4_STACK,    268
.equ POS3A_STACK,   400
.equ ORI3A_STACK,   500
.equ POS3B_STACK,   600
.equ ORI3B_STACK,   700
.equ NEXT_FACE,     800
.equ NEXT_TURN,     836
.equ PATH_FACE,     872

.equ SAVE_RA,       956
.equ SAVE_S0,       952
.equ SAVE_S1,       948
.equ SAVE_S2,       944
.equ SAVE_S3,       940
.equ SAVE_S4,       936
.equ SAVE_S5,       932
.equ SAVE_S6,       928
.equ SAVE_S7,       924
.equ SAVE_S8,       920
.equ SAVE_S9,       916
.equ SAVE_S10,      912
.equ SAVE_S11,      908
.equ FRAME_SIZE,    960

search_v5_rv32_handwritten:
    # Preserve caller SP because bound is ninth argument at 0(caller_sp).
    mv      t0, sp
    addi    sp, sp, -FRAME_SIZE
    sw      ra, SAVE_RA(sp)
    sw      s0, SAVE_S0(sp)
    sw      s1, SAVE_S1(sp)
    sw      s2, SAVE_S2(sp)
    sw      s3, SAVE_S3(sp)
    sw      s4, SAVE_S4(sp)
    sw      s5, SAVE_S5(sp)
    sw      s6, SAVE_S6(sp)
    sw      s7, SAVE_S7(sp)
    sw      s8, SAVE_S8(sp)
    sw      s9, SAVE_S9(sp)
    sw      s10, SAVE_S10(sp)
    sw      s11, SAVE_S11(sp)

    mv      s3, sp
    lw      s1, 0(t0)              # bound
    li      s0, 0                  # depth
    li      s2, 33                 # minimum = NO_PATH

    sh      a0, P_STACK(s3)
    sh      a1, O_STACK(s3)

    # Copy initial 4-cubie pattern.
    lbu     t0, 0(a2)
    lbu     t1, 1(a2)
    lbu     t2, 2(a2)
    lbu     t3, 3(a2)
    sb      t0, POS4_STACK+0(s3)
    sb      t1, POS4_STACK+1(s3)
    sb      t2, POS4_STACK+2(s3)
    sb      t3, POS4_STACK+3(s3)
    lbu     t0, 0(a3)
    lbu     t1, 1(a3)
    lbu     t2, 2(a3)
    lbu     t3, 3(a3)
    sb      t0, ORI4_STACK+0(s3)
    sb      t1, ORI4_STACK+1(s3)
    sb      t2, ORI4_STACK+2(s3)
    sb      t3, ORI4_STACK+3(s3)

    # Copy initial 3a pattern.
    lbu     t0, 0(a4)
    lbu     t1, 1(a4)
    lbu     t2, 2(a4)
    sb      t0, POS3A_STACK+0(s3)
    sb      t1, POS3A_STACK+1(s3)
    sb      t2, POS3A_STACK+2(s3)
    lbu     t0, 0(a5)
    lbu     t1, 1(a5)
    lbu     t2, 2(a5)
    sb      t0, ORI3A_STACK+0(s3)
    sb      t1, ORI3A_STACK+1(s3)
    sb      t2, ORI3A_STACK+2(s3)

    # Copy initial 3b pattern.
    lbu     t0, 0(a6)
    lbu     t1, 1(a6)
    lbu     t2, 2(a6)
    sb      t0, POS3B_STACK+0(s3)
    sb      t1, POS3B_STACK+1(s3)
    sb      t2, POS3B_STACK+2(s3)
    lbu     t0, 0(a7)
    lbu     t1, 1(a7)
    lbu     t2, 2(a7)
    sb      t0, ORI3B_STACK+0(s3)
    sb      t1, ORI3B_STACK+1(s3)
    sb      t2, ORI3B_STACK+2(s3)

    j       .Lenter_node

# ----------------------------------------------------------------------
# ENTER_NODE: executed exactly once for each newly pushed node.
# ----------------------------------------------------------------------
.Lenter_node:
    # p/o
    slli    t0, s0, 1
    add     t0, s3, t0
    lhu     a0, P_STACK(t0)
    lhu     a1, O_STACK(t0)

    # 4-cubie pointers: base + 4*depth
    slli    t1, s0, 2
    add     t1, s3, t1
    addi    a2, t1, POS4_STACK
    addi    a3, t1, ORI4_STACK

    # 3-cubie pointers: base + 3*depth
    slli    t2, s0, 1
    add     t2, t2, s0
    add     t2, s3, t2
    addi    a4, t2, POS3A_STACK
    addi    a5, t2, ORI3A_STACK
    addi    a6, t2, POS3B_STACK
    addi    a7, t2, ORI3B_STACK

    call    heuristic_v5_rv32

    add     t0, s0, a0              # f = depth + h
    blt     s1, t0, .Lprune

    # Goal test. Reload p/o because heuristic clobbers caller-saved regs.
    slli    t0, s0, 1
    add     t0, s3, t0
    lhu     t1, P_STACK(t0)
    lhu     t2, O_STACK(t0)
    or      t1, t1, t2
    beqz    t1, .Lfound

    # MAX_DEPTH guard.
    li      t1, 32
    bge     s0, t1, .Lbacktrack

    # Fresh node: initialize iterator exactly once.
    add     t0, s3, s0
    sb      zero, NEXT_FACE(t0)
    sb      zero, NEXT_TURN(t0)

    j       .Lresume_node

.Lprune:
    bge     t0, s2, .Lbacktrack
    mv      s2, t0

# ----------------------------------------------------------------------
# BACKTRACK: pop one node. Parent resumes its already-advanced iterator.
# ----------------------------------------------------------------------
.Lbacktrack:
    beqz    s0, .Lreturn_min
    addi    s0, s0, -1
    j       .Lresume_node

# ----------------------------------------------------------------------
# RESUME_NODE: find the next child of the current node.
# ----------------------------------------------------------------------
.Lresume_node:
    add     t0, s3, s0
    lbu     t1, NEXT_FACE(t0)
    lbu     t2, NEXT_TURN(t0)

    li      t3, 3
    bgeu    t1, t3, .Lchildren_done

    # Skip all turns of the same face as the move that reached this node.
    beqz    s0, .Lcandidate_found
    addi    t3, s0, -1
    add     t3, s3, t3
    lbu     t3, PATH_FACE(t3)
    bne     t1, t3, .Lcandidate_found

    addi    t1, t1, 1
    sb      t1, NEXT_FACE(t0)
    sb      zero, NEXT_TURN(t0)
    j       .Lresume_node

.Lchildren_done:
    # Reset is not required for correctness because ENTER_NODE initializes
    # every newly pushed node. Keeping it omitted saves two stores.
    j       .Lbacktrack

# ----------------------------------------------------------------------
# Candidate selected. Advance parent iterator BEFORE pushing the child.
# ----------------------------------------------------------------------
.Lcandidate_found:
    mv      s4, t1                   # candidate face
    mv      s5, t2                   # candidate turn

    # path_face[depth] = face
    add     t3, s3, s0
    sb      s4, PATH_FACE(t3)

    # path[depth] = face*3 + turn
    slli    t3, s4, 1
    add     t3, t3, s4
    add     t3, t3, s5
    la      t4, path
    add     t4, t4, s0
    sb      t3, 0(t4)

    # Advance parent iterator.
    addi    t3, s5, 1
    li      t4, 3
    bltu    t3, t4, .Literator_same_face

    addi    t3, s4, 1
    sb      t3, NEXT_FACE(t0)
    sb      zero, NEXT_TURN(t0)
    j       .Lcopy_child

.Literator_same_face:
    sb      t3, NEXT_TURN(t0)

# ----------------------------------------------------------------------
# Copy parent pattern state into depth+1 working slot.
# ----------------------------------------------------------------------
.Lcopy_child:
    addi    t0, s0, 1               # child depth

    # pos4/ori4: copy four bytes each with lw/sw.
    slli    t1, s0, 2
    add     t1, s3, t1
    slli    t2, t0, 2
    add     t2, s3, t2
    lw      t3, POS4_STACK(t1)
    sw      t3, POS4_STACK(t2)
    lw      t3, ORI4_STACK(t1)
    sw      t3, ORI4_STACK(t2)

    # 3-byte arrays: explicit byte copies (no over-copy across logical arrays).
    slli    t1, s0, 1
    add     t1, t1, s0              # parent 3*depth
    add     t1, s3, t1
    slli    t2, t0, 1
    add     t2, t2, t0              # child 3*(depth+1)
    add     t2, s3, t2

    lbu     t3, POS3A_STACK+0(t1)
    lbu     t4, POS3A_STACK+1(t1)
    lbu     t5, POS3A_STACK+2(t1)
    sb      t3, POS3A_STACK+0(t2)
    sb      t4, POS3A_STACK+1(t2)
    sb      t5, POS3A_STACK+2(t2)
    lbu     t3, ORI3A_STACK+0(t1)
    lbu     t4, ORI3A_STACK+1(t1)
    lbu     t5, ORI3A_STACK+2(t1)
    sb      t3, ORI3A_STACK+0(t2)
    sb      t4, ORI3A_STACK+1(t2)
    sb      t5, ORI3A_STACK+2(t2)

    lbu     t3, POS3B_STACK+0(t1)
    lbu     t4, POS3B_STACK+1(t1)
    lbu     t5, POS3B_STACK+2(t1)
    sb      t3, POS3B_STACK+0(t2)
    sb      t4, POS3B_STACK+1(t2)
    sb      t5, POS3B_STACK+2(t2)
    lbu     t3, ORI3B_STACK+0(t1)
    lbu     t4, ORI3B_STACK+1(t1)
    lbu     t5, ORI3B_STACK+2(t1)
    sb      t3, ORI3B_STACK+0(t2)
    sb      t4, ORI3B_STACK+1(t2)
    sb      t5, ORI3B_STACK+2(t2)

    # np/no start from parent p/o.
    slli    t3, s0, 1
    add     t3, s3, t3
    lhu     s6, P_STACK(t3)
    lhu     s7, O_STACK(t3)

    # Number of quarter turns = turn + 1.
    addi    s8, s5, 1

.Lquarter_loop:
    # np = permutation[face][np]
    # row offset in bytes = face * (5040*2) = face * 10080.
    # 10080 = 8192 + 2048 - 128 +? 8192+2048-128-32 =10080.
    slli    t0, s4, 13              # face*8192
    slli    t1, s4, 11              # face*2048
    add     t0, t0, t1
    slli    t1, s4, 7               # face*128
    sub     t0, t0, t1
    slli    t1, s4, 5               # face*32
    sub     t0, t0, t1
    la      t1, permutation
    add     t0, t0, t1
    slli    t1, s6, 1
    add     t0, t0, t1
    lhu     s6, 0(t0)

    # no = orientation[face][no]
    # row offset in bytes = face * (729*2) = face * 1458
    # 1458 = 1024 + 512 - 64 - 16 + 2.
    slli    t0, s4, 10
    slli    t1, s4, 9
    add     t0, t0, t1
    slli    t1, s4, 6
    sub     t0, t0, t1
    slli    t1, s4, 4
    sub     t0, t0, t1
    slli    t1, s4, 1
    add     t0, t0, t1
    la      t1, orientation
    add     t0, t0, t1
    slli    t1, s7, 1
    add     t0, t0, t1
    lhu     s7, 0(t0)

    # Child pattern pointers.
    addi    t0, s0, 1
    slli    t1, t0, 2
    add     t1, s3, t1
    addi    a0, t1, POS4_STACK
    addi    a1, t1, ORI4_STACK
    mv      a2, s4
    call    pattern4_quarter_rv32

    addi    t0, s0, 1
    slli    t1, t0, 1
    add     t1, t1, t0
    add     t1, s3, t1
    addi    a0, t1, POS3A_STACK
    addi    a1, t1, ORI3A_STACK
    mv      a2, s4
    call    pattern3_quarter_rv32

    addi    t0, s0, 1
    slli    t1, t0, 1
    add     t1, t1, t0
    add     t1, s3, t1
    addi    a0, t1, POS3B_STACK
    addi    a1, t1, ORI3B_STACK
    mv      a2, s4
    call    pattern3_quarter_rv32

    addi    s8, s8, -1
    bnez    s8, .Lquarter_loop

    # Store child p/o and push.
    addi    t0, s0, 1
    slli    t1, t0, 1
    add     t1, s3, t1
    sh      s6, P_STACK(t1)
    sh      s7, O_STACK(t1)

    addi    s0, s0, 1
    j       .Lenter_node

.Lfound:
    la      t0, solution_length
    sw      s0, 0(t0)
    li      a0, -1
    j       .Lreturn

.Lreturn_min:
    mv      a0, s2

.Lreturn:
    lw      s11, SAVE_S11(sp)
    lw      s10, SAVE_S10(sp)
    lw      s9, SAVE_S9(sp)
    lw      s8, SAVE_S8(sp)
    lw      s7, SAVE_S7(sp)
    lw      s6, SAVE_S6(sp)
    lw      s5, SAVE_S5(sp)
    lw      s4, SAVE_S4(sp)
    lw      s3, SAVE_S3(sp)
    lw      s2, SAVE_S2(sp)
    lw      s1, SAVE_S1(sp)
    lw      s0, SAVE_S0(sp)
    lw      ra, SAVE_RA(sp)
    addi    sp, sp, FRAME_SIZE
    ret
