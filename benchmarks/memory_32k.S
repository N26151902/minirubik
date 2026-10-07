.text
main:
    li t0, 0x10000000
    li t1, 0x10008000

write_loop:
    sw zero, 0(t0)
    addi t0, t0, 4
    bltu t0, t1, write_loop

done:
    li a7, 10
    ecall
