.text
main:
    li t0, 10000000

loop:
    addi t0, t0, -1
    bnez t0, loop

done:
    li a7, 10
    ecall
