/* Minimal RV32I instruction-count simulator used to cross-check Ripes --iret.
 * Loads an ELF, runs RV32I only (rejects M), supports Ripes ecalls 1/4/10/11/93.
 * Build: cc -O2 -o rv32i_iss tools/rv32i_iss.c   Run: ./rv32i_iss prog.elf */
#include <elf.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define MEMSZ (1u << 20)
static uint8_t mem[MEMSZ];
static uint32_t led[35 * 25];
static int led_writes;
static uint8_t *addr(uint32_t a, int n)
{
    if (a + n <= MEMSZ) return &mem[a];
    if (a >= 0xf0000000u && a + n <= 0xf0000000u + sizeof led) { led_writes++; return (uint8_t *) led + (a - 0xf0000000u); }
    fprintf(stderr, "bad access %08x\n", a); exit(99);
}
int main(int argc, char **argv)
{
    FILE *f = fopen(argv[1], "rb");
    fseek(f, 0, SEEK_END); long sz = ftell(f); rewind(f);
    uint8_t *buf = malloc(sz); fread(buf, 1, sz, f);
    Elf32_Ehdr *eh = (Elf32_Ehdr *) buf;
    for (int i = 0; i < eh->e_phnum; i++) {
        Elf32_Phdr *ph = (Elf32_Phdr *) (buf + eh->e_phoff + i * eh->e_phentsize);
        if (ph->p_type != PT_LOAD) continue;
        memcpy(&mem[ph->p_vaddr], buf + ph->p_offset, ph->p_filesz);
    }
    uint32_t x[32] = {0}, pc = eh->e_entry; unsigned long long n = 0;
    x[2] = MEMSZ - 16;
    for (;;) {
        uint32_t in; memcpy(&in, addr(pc, 4), 4); n++;
        uint32_t op = in & 0x7f, rd = (in >> 7) & 31, f3 = (in >> 12) & 7, r1 = (in >> 15) & 31, r2 = (in >> 20) & 31, f7 = in >> 25;
        int32_t ii = (int32_t) in >> 20;
        int32_t si = ((int32_t) in >> 25 << 5) | rd;
        int32_t bi = (((int32_t) in >> 31) << 12) | (((in >> 7) & 1) << 11) | (((in >> 25) & 63) << 5) | (((in >> 8) & 15) << 1);
        int32_t ji = (((int32_t) in >> 31) << 20) | (in & 0xff000) | (((in >> 20) & 1) << 11) | (((in >> 21) & 0x3ff) << 1);
        uint32_t a = x[r1], b = x[r2], r = 0, npc = pc + 4; int w = 1;
        switch (op) {
        case 0x37: r = in & 0xfffff000; break;
        case 0x17: r = pc + (in & 0xfffff000); break;
        case 0x6f: r = pc + 4; npc = pc + ji; break;
        case 0x67: r = pc + 4; npc = (a + ii) & ~1u; break;
        case 0x63: w = 0; {
            int t = 0;
            switch (f3) { case 0: t = a == b; break; case 1: t = a != b; break; case 4: t = (int32_t) a < (int32_t) b; break;
            case 5: t = (int32_t) a >= (int32_t) b; break; case 6: t = a < b; break; case 7: t = a >= b; break; default: goto bad; }
            if (t) npc = pc + bi; } break;
        case 0x03: { uint32_t ea = a + ii; uint8_t *p = addr(ea, f3 & 3 ? (f3 & 3) * 2 : 1);
            switch (f3) { case 0: r = (int8_t) p[0]; break; case 1: { int16_t h; memcpy(&h, p, 2); r = h; } break;
            case 2: memcpy(&r, p, 4); break; case 4: r = p[0]; break; case 5: { uint16_t h; memcpy(&h, p, 2); r = h; } break; default: goto bad; } } break;
        case 0x23: w = 0; { uint32_t ea = a + si; int len = f3 == 0 ? 1 : f3 == 1 ? 2 : 4; memcpy(addr(ea, len), &b, len); } break;
        case 0x13: case 0x33: {
            uint32_t c = op == 0x13 ? (uint32_t) ii : b;
            if (op == 0x33 && f7 == 1) goto bad; /* M extension */
            switch (f3) {
            case 0: r = (op == 0x33 && f7 == 0x20) ? a - c : a + c; break;
            case 1: r = a << (c & 31); break;
            case 2: r = (int32_t) a < (int32_t) c; break;
            case 3: r = a < c; break;
            case 4: r = a ^ c; break;
            case 5: r = (in >> 30) & 1 ? (uint32_t) ((int32_t) a >> (c & 31)) : a >> (c & 31); break;
            case 6: r = a | c; break;
            case 7: r = a & c; break; } } break;
        case 0x0f: w = 0; break;
        case 0x73: w = 0;
            switch (x[17]) {
            case 1: printf("%d", (int32_t) x[10]); break;
            case 4: printf("%s", (char *) addr(x[10], 1)); break;
            case 11: putchar((int) x[10]); break;
            case 10: printf("\n[exit] retired=%llu a0=%d leds=%d\n", n, (int32_t) x[10], led_writes); return 0;
            case 93: printf("\n[exit93] retired=%llu code=%d leds=%d\n", n, (int32_t) x[10], led_writes); return (int) x[10];
            default: goto bad; }
            break;
        default: bad: fprintf(stderr, "bad insn %08x at %08x\n", in, pc); return 98;
        }
        if (w && rd) x[rd] = r;
        pc = npc;
    }
}
