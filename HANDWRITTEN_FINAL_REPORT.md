# CA2026 HW1 - Handwritten RV32I Final Report

Date: 2026-10-06

## 1. Final design

The final solver uses memory-bounded iterative IDA* rather than the original full-state BFS table. The search keeps explicit per-depth stacks, so recursion is not required. Its heuristic is the maximum of five admissible lookup-table estimates: permutation distance, orientation distance, one 4-cubie pattern database, and two 3-cubie pattern databases.

The public handwritten path is:

`solver_solve_rv32 -> valid_rv32 -> solve_v5_rv32 -> rank/pattern extraction -> heuristic_v5_rv32 -> search_v5_rv32_handwritten_final`

The final search updates permutation and orientation with precomputed transition tables. Pattern-state quarter turns use handwritten unrolled RV32I helpers. Consecutive moves on the same face are pruned.

## 2. Why the design fits the constraints

The original BFS representation requires memory proportional to all 3,674,160 reachable states and is unsuitable for the 128-KiB static-memory requirement. IDA* stores only the current depth-first path and small explicit stacks. Precomputed compact heuristic tables provide enough pruning to keep the worst measured distance-11 state below the 50-million retired-instruction limit.

The hot path avoids integer multiplication, division, and remainder instructions. Constant products such as row offsets are implemented with shifts, adds, and subtracts.

## 3. Handwritten implementation

Handwritten RV32I components used by the final path:
- `valid_rv32.S`: range, duplicate-permutation and orientation-sum validation.
- `rank_state_parts_rv32.S`: permutation/orientation ranking.
- `pattern_rank_rv32.S`: 3- and 4-cubie pattern ranking.
- `pattern_extract_rv32.S`: pattern extraction from the input state.
- `pattern_quarter_rv32_unrolled.S`: unrolled 3-/4-cubie pattern transitions.
- `heuristic_v5_rv32.S`: maximum of five heuristic tables.
- `solve_v5_rv32.S`: iterative-bound orchestration.
- `search_v5_rv32_handwritten_final.S`: explicit-stack iterative IDA* search.
- `solver_solve_rv32.S`: public solver wrapper.

The compiler-derived `search_v5_rv32_o3.S` was used only as historical performance/reference material and is not linked into the final handwritten ELF.

## 4. ISA and forbidden-helper audit

Clean build options: `-march=rv32i -mabi=ilp32`.

`readelf -A` reports `rv32i2p1`. An `objdump` audit of the final ELF finds zero `mul`, `mulh`, `div`, or `rem` family instructions. An `nm` audit finds zero compiler multiply/divide/modulo helper routines such as `__mulsi3`, `__divsi3`, `__udivsi3`, `__modsi3`, or `__umodsi3`.

## 5. Static-memory result

Clean final ELF:
- `.rodata` = 120,649 B
- `.sdata` = 7 B
- `.sbss` = 4 B
- `.bss` = 4,128 B
- `.data` = 0 B

Required rubric sum (`.data + .bss + .rodata`) = 124,777 B.

Conservative sum including `.sdata + .sbss` = 124,788 B.

Limit = 128 KiB = 131,072 B.

Rubric margin = 6,295 B.

Result: PASS.

## 6. Retired-instruction result

Ripes version: v2.2.6-106-g5b8a616.
Processor: RV32_ISS.

Clean report vector:
- solution length = 11
- exit code = 0
- retired instructions = 17,137,243

Clean known worst state `14325670000000`:
- solution length = 11
- exit code = 0
- retired instructions = 48,276,932
- margin below 50,000,000 = 1,723,068

Result: PASS.

## 7. Reliable exhaustive distance-11 verification

All 2,644 distance-11 states were executed with the optimized handwritten solver using a verification startup that terminates with ecall 93. Unlike the earlier ecall 10 harness, this makes the Ripes displayed program exit code reflect the actual main return value.

- tested = 2,644 / 2,644
- failures = 0
- maximum retired instructions = 48,276,943
- worst state = 14325670000000
- margin below 50,000,000 = 1,723,057

The harness requires solver initialization and solving to succeed and requires every distance-11 case to return solution length 11. The zero-failure result is therefore reliable correctness evidence as well as a performance sweep.

Result: PASS.

## 8. Final conclusion

The final handwritten RV32I solver satisfies the two primary quantitative gates:
1. static data memory is below 128 KiB;
2. all 2,644 tested HTM-distance-11 states retire fewer than 50,000,000 instructions.

It also passes the RV32I ISA/helper audit, and the reliable ecall-93 exhaustive run reports zero failures.

## 9. GCC -O2 reference versus handwritten final

For the required compiler comparison, the pure-C final algorithm in `solver_ida_core_handwritten_work.c` was compiled with GCC 14.2.0 using `-O2 -march=rv32i -mabi=ilp32`. The report-vector input is `21345671111111` (internal permutation `{1,0,2,3,4,5,6}`, zero orientation).

| Build | .text | Retired instructions | RV32_ISS wall time |
|---|---:|---:|---:|
| GCC -O2 final C algorithm | 3,712 B | 20,568,913 | 807 ms |
| Handwritten final | 3,244 B | 17,137,243 | 695 ms |

The handwritten version reduces linked `.text` by 468 B (12.61%) and retired instructions by 3,431,670 (16.68%). The measured wall time in this run decreases by about 13.9%.

The GCC reference contains `__mulsi3`; this is acceptable as a compiler reference but is not allowed in the submitted handwritten target. The handwritten final contains no multiply/divide/remainder helper routines and no RV32M instructions.

## 10. Handwritten refinement measurements

The search implementation was refined in measurable steps on the same report vector:

| Checkpoint | Main change | .text | Retired instructions |
|---|---|---:|---:|
| CP1 | initial explicit-stack handwritten search with loop-based pattern helpers | 3,080 B | 21,950,326 |
| CP2 | unrolled 3-/4-cubie pattern update helpers | 3,244 B | 17,738,811 |
| CP3 | hoist permutation/orientation transition-row bases out of the quarter-turn loop | 3,244 B | 17,137,243 |

CP1 -> CP3 reduces retired instructions by 21.93% at a cost of 164 B of linked text. CP2 -> CP3 saves another 3.39% without increasing linked text.

## 11. Target correctness and pipeline validation

A target-side validation harness applies every move returned by the handwritten solver and independently checks the final cube state. It tests:
- solved state: expected 0 moves;
- a short scramble: expected 1 move;
- required vector `21345671111111`: expected optimal length 11.

On RV32_ISS, all three tests pass with final `a0 = 0`; the complete harness retires 17,146,505 instructions. On the RV32_5S five-stage model, the same ELF also finishes with `a0 = 0`, retiring 17,146,504 instructions in 22,026,276 cycles (CPI 1.28459). This supplies target execution evidence on both the ISA simulator and a pipelined processor model.

## 12. LED visualization

The GUI demonstration uses the handwritten RV32I renderer in `led_asm_build_fast/led_renderer_rv32_fast.S`. The renderer uses the required `LED_MATRIX_0_BASE`, `LED_MATRIX_0_WIDTH`, and `LED_MATRIX_0_HEIGHT` symbols and draws a 35x25 six-face unfolded cube net.

The selected demonstration ELF is `led_asm_build_fast/fixed_5move_d2000.elf`. It solves a five-move scramble and redraws the state from the solver-produced move sequence. The harness validates the final solved state; a Ripes RV32_ISS audit finishes with `a0 = 0` and 178,969 retired instructions.

The renderer is kept out of the performance-gate build. Its optimized facelet writer computes `35*y` using shifts and adds and writes each 4x3 facelet directly, avoiding the old per-pixel repeated-addition loop. The corrected corner-face ordering was checked against a physical sticker model.

For this LED build, `.data + .bss + .rodata = 124,912 B`, below 128 KiB by 6,160 B. Even conservatively including `.sdata + .sbss`, the total is 124,923 B.

## 13. Arbitrary inline 14-character target input

The final target has an explicit assembly-time input layer. inline_state_rv32.S contains cube_state_string and parses the canonical external format (seven permutation digits 1..7 followed by seven orientation digits 1..3) into zero-based p[7] and o[7]. build_inline_target.sh STATE provides the reproducible build entry point.

Measured RV32_ISS inputs:
- 21345671111111 (distance 11): exit code 0, 17,137,363 retired instructions.
- 25416373331111 (distance 10): exit code 0, 2,704,769 retired instructions.
- 14325671111111 (worst measured distance-11 state, canonical external form): exit code 0, 48,277,063 retired instructions, 1,722,937 below the gate.

A one-move inline state 25314672313211 was also executed on RV32_5S: exit code 0, 3,737 retired instructions and 4,902 cycles. build_inline_led.sh STATE DELAY uses the same input parser with the handwritten LED renderer. The five-move GUI demonstration is canonical state 74523162333332.
