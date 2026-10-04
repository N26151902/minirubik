## Stage 1 - Baseline Characterization

### Version

Upstream baseline:
231796cc48868f4ea276f652139b6bebbad0cd02

Working commit:
c7a2d675a94304dc54b94a49cda3053f0ae47ff9

The working commit only adds development notes on top of the
upstream baseline.

### Correctness

- Reachable states: 3,674,160
- HTM diameter: 11
- `./solver --self-test`: PASS

### Windows x86-64 Host

Compiler:
- MinGW GCC 16.1.0
- Optimization: `-O3`

Runtime (`--self-test`, 5 runs):
- Average: 0.18048542 s
- Minimum: 0.16491500 s
- Maximum: 0.21233120 s

Binary:
- File size: 95,467 bytes (93.23 KiB)
- `.text`: 48,168 bytes
- `.data`: 304 bytes
- `.bss`: 2,960 bytes
- section total: 51,432 bytes

Observed peak working set:
- 22,081,536 bytes
- 21.06 MiB

### Ubuntu x86-64 Host

Compiler:
- GCC 15.2.0
- Optimization: `-O3`

Binary:
- ELF 64-bit LSB PIE
- x86-64
- dynamically linked
- File size: 25,040 bytes
- `.text`: 13,422 bytes
- `.data`: 760 bytes
- `.bss`: 48 bytes
- section total: 14,230 bytes

Runtime (`--self-test`, 5 runs):
- 0.20 s
- 0.20 s
- 0.20 s
- 0.19 s
- 0.20 s
- Average: 0.198 s

Maximum RSS:
- 19,316 KiB
- approximately 18.86 MiB

### Major Baseline Data Structures

`toward_solved[]`:
- 3,674,160 bytes
- approximately 3.50 MiB

`queue[]`:
- 14,696,640 bytes
- approximately 14.02 MiB

Combined major heap allocation:
- 18,370,800 bytes
- approximately 17.52 MiB

Transition lookup arrays:
- 34,614 bytes
- approximately 33.80 KiB

### RISC-V Toolchain

Compiler:
- riscv64-unknown-elf-gcc 14.2.0

Verified options:
- `-march=rv32i`
- `-mabi=ilp32`

Minimal test result:
- ELF format: `elf32-littleriscv`
- Architecture: `riscv:rv32`

The original `solver.c` cannot currently be directly compiled
with the installed bare-metal toolchain because the compilation
stops at `#include <stdio.h>`: the required C library headers are
not available in the current bare-metal environment.# CA2026 HW1 Development Notes

## Environment

- Repository: minirubik
- Branch: main
- Git remote origin: my fork
- Git remote upstream: sysprog21/minirubik

## Final RV32I Constraint Verification (2026-10-03)

Current optimized core: `solver_ida_core_v5.c`.
Ripes target: `Ripes-v2.2.6-106-g5b8a616`, processor `RV32_ISS`.

### Static-memory limit

For `exhaustive.elf`:
- `.data`: 0 B
- `.bss`: 4,128 B
- `.rodata`: 119,820 B
- Required sum: 123,948 B
- Limit: 128 KiB = 131,072 B
- Margin: 7,124 B
- Result: PASS

### Retired-instruction limit

All 2,644 HTM-distance-11 states were executed in Ripes RV32_ISS.
The complete measurements are stored in `exhaustive_results.tsv`.
- states tested: 2,644
- execution failures: 0
- states at or above 50,000,000 retired instructions: 0
- worst state: `14325670000000`
- worst retired instructions: 44,568,672
- margin below limit: 5,431,328
- Result: PASS

Report vector `21345671111111` rerun:
- exit code: 0
- retired instructions: 15,820,192
- cycles: 15,820,192
- CPI: 1; IPC: 1

## Correctness Gates H1-H4 (2026-10-03)

Host verifier: `verify_host_gates.c`; full log: `host_gates.log`.
- H1 PASS: all 3,674,160 states checked; max heuristic 8; admissibility violations 0.
- H2 PASS: solved entries are 0. Maxima: permutation 7, orientation 6, PDB4 8, PDB3a 7, PDB3b 7.
- H3 PASS: final search checked against exact BFS distance for all 3,674,160 states; mismatches 0. CPU 153.476 s; wall 2:35.04.
- H4 N/A for the final design: heuristic/PDB distances are unpacked uint8_t arrays, so there is no packed accessor to compare.

## RV32I helper-routine audit and fix (2026-10-03)

A stricter symbol audit found that the earlier measured ELF linked libgcc `__udivsi3` / `__umodsi3`.
Although it contained no M-extension opcodes, this violates the assignment rule forbidding compiler-generated multiply/divide helpers.
Backups were preserved as `solver_ida_core_v5_pre_no_libgcc.c`, `exhaustive_pre_no_libgcc.elf`, and matching pre-fix result files.

The final core was restructured to keep permutation and orientation ranks separate and to validate the orientation sum without modulo.
The rebuilt core has no undefined symbols and the linked no-helper ELF contains none of:
`__mulsi3`, `__divsi3`, `__udivsi3`, `__modsi3`, `__umodsi3`.

No-helper report vector `21345671111111`:
- Ripes RV32_ISS exit code: 0
- retired instructions: 15,820,031
- static `.data + .bss + .rodata`: 123,948 B
- result: PASS

T5/T6 target harness validates returned paths inside the RV32I program.
On RV32_ISS, solved + one-move scramble + report distance-11 vector all pass; program exit code 0.
A fresh exhaustive 2,644-state run of the no-helper build is in progress; do not use the old exhaustive result as final evidence for this revised core.

## Authoritative final exhaustive result (2026-10-03)

Fresh exhaustive run of the final no-helper core is complete and supersedes earlier pre-fix measurements:
- distance-11 states: 2,644 / 2,644
- failures: 0
- states >= 50,000,000 retired instructions: 0
- worst state: 14325670000000
- worst retired instructions: 44,568,523
- margin: 5,431,477
- static required sum: .data 0 + .bss 4,128 + .rodata 119,820 = 123,948 B
- static margin below 128 KiB: 7,124 B
- separate vector 21345671111111: 15,820,031 retired instructions, exit code 0
- final exhaustive performance result: PASS

LED progress:
- 35x25 MMIO layout works in Ripes.
- Full-matrix clear is removed from per-move redraw and startup; initial cube is drawn immediately.
- led_demo_live_optimized.elf uses live solver output on the 3-move demo, applies each returned move, redraws, and validates solved state.
- RV32_5S CLI live demo: exit 0, 3,297 retired instructions, 4,412 cycles.
- GUI live-output animation still needs explicit visual confirmation.
