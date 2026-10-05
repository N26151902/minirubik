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
- NOTE: the figures in this subsection were from the pre-helper-fix build and are retained only as historical evidence.
- Superseded worst retired instructions: 44,568,672
- Superseded margin below limit: 5,431,328
- Result at that stage: PASS

Superseded report-vector measurement before the no-helper fix:
- exit code: 0
- retired instructions: 15,820,192
- cycles: 15,820,192
- CPI: 1; IPC: 1

Use the authoritative final no-helper measurements below for submission.

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

## Target gates and pipeline evidence (2026-10-03)

`target_gates.elf` validates the returned path inside the RV32I target program for solved, one-move, and the required distance-11 report vector.
- RV32_ISS: exit 0; 15,825,702 retired instructions; 15,825,702 cycles.
- RV32_5S: exit 0; 15,825,701 retired instructions; 18,437,979 cycles; CPI 1.1650655; IPC 0.8583208; model execution time 38.148 s.
- T5: PASS for the known target-harness cases because each returned path is applied and checked to reach solved.
- T6: PASS for `21345671111111`; the solver returns the known optimal distance 11 and the path is validated on target.
- T7: partially evidenced: the known harness cases pass on RV32_ISS and RV32_5S; the grader-provided state is not yet known and therefore cannot be claimed.

## LED progress (2026-10-04)

- 35x25 MMIO layout and six-color unfolded-net renderer work in Ripes.
- Golden animation-only reference is preserved as `led_demo_animation_only_GOLDEN_DO_NOT_TOUCH.elf`.
- Actual-solver 3-move build is preserved as `led_demo_live_from_golden_fixed.elf`; the GUI displayed its initial scrambled cube and continued executing the live solver.
- A faster GUI evidence build, `led_demo_live_1move_actual_solver.elf`, uses an actual one-move solver result and is currently awaiting final visual confirmation.
- Do not claim the final LED requirement PASS until the actual-solver GUI animation has been visually confirmed and evidence captured.
- The current renderer is C compiled to RV32I; strict handwritten-assembly renderer/integration remains a submission gap if the assignment requires the renderer itself to be handwritten.


## 2026-10-05 handwritten RV32I core integration checkpoint

Implemented and verified handwritten RV32I helpers: valid, rank_state_parts, pattern3/4 ranking, pattern extraction, pattern quarter update, heuristic_v5, solve_v5 orchestration, and solver_solve public wrapper.

Current search_v5_rv32_o3.S is an audited/transplanted O3 RV32I hot-loop scaffold adapted to call the handwritten heuristic and use exported table/path symbols. It is functionally verified against the C search on legal generated states, but because its instruction scheduling originated from compiler output it must not be described as fully handwritten until manually rewritten/audited to the course's handwritten standard.

Measured integrated RV32_ISS gates:
- distance-11 report vector {1,0,2,3,4,5,6}, all-zero orientation: PASS, 11 moves, 16,318,025 retired instructions.
- previous worst-case state 14325670000000: PASS, 11 moves, 45,975,038 retired instructions (< 50,000,000).
- final O3-integrated sections: .text 4,084 B; .rodata 120,649 B; .sdata 7 B; .sbss 4 B; .bss 4,128 B.
- static memory gate (.rodata+.sdata+.sbss+.bss) = 124,788 B, leaving 6,284 B below 128 KiB.
- no __mulsi3/__div/__mod/__udiv/__umod symbols in the GC-linked final integration ELF.

Do not claim the full 2,644 distance-11 exhaustive suite has been rerun on this new assembly integration yet.


## Authoritative handwritten RV32I final (2026-10-06)

This section supersedes the 2026-10-05 O3-scaffold checkpoint for the Phase-1 handwritten solver.

### Final integration
- Public entry: `solver_solve_rv32`
- Orchestration: `solve_v5_rv32`
- Final search: `search_v5_rv32_handwritten_final`
- Hot pattern updates: `pattern3_quarter_rv32_unrolled` and `pattern4_quarter_rv32_unrolled`
- `solve_v5_rv32.S` now calls the handwritten final search directly.
- `search_v5_rv32_o3.S` is retained only as a historical performance/reference implementation and is not linked into the final handwritten ELF.

### Clean-build ISA and symbol audit
The final ELF was rebuilt from repository sources with `-march=rv32i -mabi=ilp32`.
- ELF RISC-V attribute: `rv32i2p1`
- forbidden M-extension instructions found by objdump: 0
- forbidden multiply/divide/modulo helper symbols found by nm: 0
- final search symbol present: `search_v5_rv32_handwritten_final`
- compiler-derived `search_v5_rv32_o3` is absent from the linked final ELF.

### Static-memory gate
Clean final worst-case ELF sections:
- `.rodata`: 120,649 B
- `.sdata`: 23 B
- `.sbss`: 4 B
- `.bss`: 4,128 B
- `.data`: 0 B
- required static sum: 124,804 B
- limit: 131,072 B
- margin: 6,268 B
- result: PASS

### Ripes RV32_ISS performance
Clean-build report vector, internal p={1,0,2,3,4,5,6}, all-zero orientation:
- solution length: 11
- exit code: 0
- retired instructions: 17,137,243

Clean-build known worst state `14325670000000`:
- solution length: 11
- exit code: 0
- retired instructions: 48,276,932
- margin below 50,000,000: 1,723,068
- result: PASS

### Exhaustive distance-11 verification
The optimized handwritten search was tested on all 2,644 states in `distance11_states.txt`.
Evidence: `handwritten_inline_exhaustive_results.tsv` and `handwritten_inline_exhaustive_progress.txt`.
- states: 2,644 / 2,644
- failures: 0
- nonzero exit codes: 0
- maximum retired instructions in the exhaustive harness: 48,276,943
- worst state: `14325670000000`
- margin below 50,000,000: 1,723,057
- result: PASS

The exhaustive harness has 11 more retired instructions than the standalone clean worst-case harness; both identify the same worst state and both pass the 50M limit.

### Handwritten-status note
The final search control flow was independently handwritten as an iterative IDA* implementation. The earlier compiler-derived `search_v5_rv32_o3.S` must not be described as the submitted handwritten search.
