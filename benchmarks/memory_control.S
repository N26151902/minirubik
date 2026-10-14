# Host-memory-per-guest-byte measurement, 64 KiB controlregion.
# Writes a non-zero word to every 4-byte slot of [0x10000000, 0x10000000+0x00010000).
# Run under Ripes CLI and record the host peak RSS, e.g.
#   /usr/bin/time -v Ripes --mode cli --src benchmarks/memory_control.S -t asm --proc RV32_ISS
# then slope = (RSS_large - RSS_control) / (4 MiB - 64 KiB) host bytes per guest byte.
.text
main:
    li   t0, 0x10000000
    li   t1, 0x00010000
    add  t1, t0, t1
    li   t2, 0x5a5a5a5a          # non-zero, every byte distinct from 0
loop:
    sw   t2, 0(t0)
    addi t0, t0, 4
    bltu t0, t1, loop
    li   a7, 10
    ecall
