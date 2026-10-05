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
- `.sdata` = 23 B
- `.sbss` = 4 B
- `.bss` = 4,128 B
- `.data` = 0 B

Required static sum = 124,804 B.

Limit = 128 KiB = 131,072 B.

Margin = 6,268 B.

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

## 7. Exhaustive distance-11 verification

All 2,644 states in the distance-11 test set were executed with the optimized handwritten solver.
- passed = 2,644 / 2,644
- failures = 0
- nonzero exit codes = 0
- maximum retired instructions = 48,276,943
- worst state = `14325670000000`
- margin below 50,000,000 = 1,723,057

The exhaustive harness retires 11 more instructions than the standalone worst-state harness because the harness code differs slightly. Both measurements identify the same worst state.

Result: PASS.

## 8. Final conclusion

The final handwritten RV32I solver satisfies the two primary quantitative gates:
1. static data memory is below 128 KiB;
2. all 2,644 tested HTM-distance-11 states retire fewer than 50,000,000 instructions.

It also passes the RV32I ISA/helper audit and the exhaustive run reports zero failures.
