# CA2026 Homework 1 — Memory-Bounded Optimal Mini-Rubik Solver on RV32I

## Overview

This work implements an optimal solver for the fixed-corner 2x2x2 Mini-Rubik cube under the RV32I constraints of CA2026 Homework 1.

The final implementation replaces the original full-state BFS solver with a memory-bounded iterative IDA* solver using five admissible lookup-table heuristics. The search, the input parser, the result validation and the LED renderer are handwritten RV32I assembly.

| Requirement | Final result |
|---|---:|
| `.data + .bss + .rodata <= 128 KiB` (solver build) | **123,949 B** |
| Distance-11 states `< 50,000,000` retired instructions | **max 48,282,220** (whole program, including in-program validation) |
| Distance-11 states checked on the target | **2,644 / 2,644 passed** |
| Required vector `21345671111111` | **17,137,243** instructions (solver call) |
| Required vector optimal distance | **11** |

Only RV32I instructions are used. There are no M-extension instructions and no compiler arithmetic helpers in the target.

Measurement conventions used throughout this note:

- Retired instructions = Ripes `--iret`, processor `RV32_ISS`, Ripes `v2.2.6-106-g5b8a616`, renderer compiled out (`RENDER=0`), same input for every compared step.
- Code size = bytes of linked `.text`, renderer compiled out.
- Static data = `.data + .bss + .rodata` from `riscv64-unknown-elf-size -A`; `.sdata + .sbss` (11 B) are reported separately.
- Toolchain: GCC 14.2.0, `-march=rv32i -mabi=ilp32`.

Repository: https://github.com/N26151902/minirubik

---

# Stage 1 — Baseline Characterization

## 1. State Space

For the fixed-corner 2x2x2 cube, seven movable corner cubies remain. Their permutation contributes

$$
7! = 5040
$$

configurations. Each corner has three orientations, but the orientation of the last corner is determined by the corner-twist invariant

$$
\sum_{i=0}^{6} o_i \equiv 0 \pmod{3}.
$$

Only six orientations are independent, giving $3^6 = 729$, and

$$
7! \times 3^6 = 5040 \times 729 = 3{,}674{,}160
$$

reachable states. The constraint is a modulo-3 invariant, not a parity: it rules out every state with a single twisted corner (sum $\equiv 1$ or $2$), which no sequence of face turns can produce.

The move group is the fixed-corner stabilizer

$$
\langle R, B, D \rangle
$$

with nine half-turn-metric (HTM) generators $R, R^2, R', B, B^2, B', D, D^2, D'$. The state space is the Cayley graph of this group with those generators. An exhaustive BFS from the identity reaches all 3,674,160 vertices; it finds 2,644 states at depth 11 (so a depth-11 state exists) and an empty frontier at depth 12 (so none is deeper). The HTM diameter is therefore 11.

## 2. Why the Original BFS Representation Is Unsuitable

| Allocation | Storage | Bytes |
| :--- | :--- | ---: |
| One move toward solved per state | heap | 3,674,160 |
| BFS queue of 32-bit ranks | heap | 14,696,640 |
| Factored quarter-turn transitions | automatic | 34,614 |
| Peak | | 18,405,414 |

The BFS queue alone is 79.8% of the peak. Building the table performs 66,134,880 transition updates, on the order of $10^9$ instructions.

`report.md` section 7 recommends keeping the full table because it is the verification artifact. That is sound on a hosted machine, where 18 MB and a second of CPU are free. It does not survive the move to Ripes: the table is 140 times the 128 KiB budget, each guest byte costs tens of host bytes (section 3), and $10^9$ instructions take minutes on `RV32_ISS` and hours on the pipelined models (section 4). Even packed at 4 bits per state, the full table is 1,794 KiB, fourteen times the budget. The table remains useful, but only as a host-side oracle.

## 3. Host Bytes per Guest Byte

VSRTL stores guest memory in `std::unordered_map<VSRTL_VT_U, uint8_t>`: one hash node per written guest byte, so a 32-bit store creates four nodes.

My first measurement wrote 32 KiB and 64 KiB and compared Ripes' high-water mark, which gave 3.1–3.9 host bytes per guest byte. That result is not credible. One libstdc++ hash node holds a next pointer, an 8-byte key and a 1-byte value (24 B, a 32 B allocation), plus about 8 B of bucket array, so the floor is about 40 B per guest byte. Regions of 32–64 KiB are also small compared with the noise in a GUI process's peak memory.

I repeated the measurement with a large region against a small control, writing a non-zero word to every slot (`benchmarks/memory_large.S`, 4 MiB; `benchmarks/memory_control.S`, 64 KiB), and recorded the peak RSS of the Ripes CLI process with `/usr/bin/time -f %M` on `RV32_ISS`:

| Program | Guest bytes written | Ripes peak RSS (KiB) |
|---|---:|---:|
| `memory_control.S` | 65,536 | 35,796 |
| `memory_large.S` | 4,194,304 | 210,824 |

$$
\text{slope} = \frac{(210{,}824 - 35{,}796) \times 1024}{4{,}194{,}304 - 65{,}536} \approx 43.4\ \text{host B per guest B}
$$

The control absorbs Ripes' fixed cost (about 35 MB), so the difference isolates the per-byte cost. As an independent check, inserting the same keys into a bare `std::unordered_map<uint64_t, uint8_t>` gives the same slope (43.4 B/B at 4 MiB, 43.7 B/B at 16 MiB), so almost all of it is the hash map itself.

At that slope the baseline's 18,405,414-byte peak would cost about 800 MB of host memory, on top of the roughly $10^9$ instructions needed to build the table.

## 4. Ripes Instruction Throughput

A ten-million-iteration RV32I loop (`benchmarks/throughput_10m.S`):

| Processor | Retired | Cycles | Wall time | Rate |
|---|---:|---:|---:|---:|
| `RV32_ISS` | 20,000,004 | 20,000,004 | 0.582 s | 34.36 M instr/s |
| `RV32_5S` | 20,000,004 | 40,000,008 | 73.201 s | 0.2732 M instr/s |

`RV32_ISS` is used for all instruction counts; `RV32_5S` is used to step through a single query and for the pipeline walkthrough.

---

# Stage 2 — Memory-Bounded Representation and Search

## 5. Replacing BFS with Iterative IDA*

The queue is what makes BFS too big, and it exists only because BFS enumerates the whole space. IDA* needs no queue. It runs depth-first searches with a cost bound on

$$
f(n) = g(n) + h(n),
$$

where $g(n)$ is the number of moves made and $h(n)$ is an admissible lower bound on the remaining distance. The first bound is $h(s_0)$. If no solution fits, the bound becomes the smallest $f$ that exceeded it, and the search repeats.

Termination: each iteration is a depth-first search of a tree whose depth is limited by the bound, so it is finite. The bound strictly increases between iterations, and every reachable state has distance at most 11, so an iteration with bound $\ge d(s_0)$ is reached after finitely many steps and finds a solution. The code also stops if the bound would exceed 32, as a guard against invalid input.

Optimality: because $h$ never overestimates, no solution shorter than the current bound was skipped, so the first solution found is optimal in HTM.

## 6. Explicit Stack Instead of Recursion

Recursion is not allowed, so the depth-first search keeps fixed-size per-depth arrays: permutation rank, orientation rank, the three pattern states, and the next move to try. The HTM diameter is 11, so the search memory is $O(d)$ with $d \le 11$ instead of $O(|V|)$ for BFS. Everything is sized at assembly time; no heap is used.

## 7. Ranked State Representation

The state is split into a permutation rank in $0..5039$ (Lehmer code) and an orientation rank in $0..728$ (six ternary digits). `report.md` section 4 shows that the two parts evolve independently, so a move is two table lookups:

$$
p' = T_p[p][m], \qquad o' = T_o[o][m].
$$

## 8. Admissible Heuristic

$$
h(s) = \max\bigl(h_p(s), h_o(s), h_4(s), h_{3a}(s), h_{3b}(s)\bigr)
$$

1. permutation distance,
2. orientation distance,
3. one 4-cubie pattern database,
4. two 3-cubie pattern databases.

Each table holds exact distances in an abstraction of the puzzle: a projection that forgets some cubies, or forgets positions or orientations. Every move of the real puzzle maps to a move of the abstraction, so a solution of length $d$ projects to a path of length at most $d$, and each $h_i(s) \le h^*(s)$. The maximum of lower bounds is a lower bound. The tables are generated on the host and linked as read-only data; the search runs on the target. The complete 3,674,160-state distance table is never linked.

The 128 KiB budget is what limits the abstraction sizes. After the transition tables, the remaining space goes to the pattern databases, which is why one 4-cubie and two 3-cubie tables are used rather than a larger single pattern.

---

# Stage 3 — C Optimization and Correctness Verification

## 9. Exhaustive Host-Side Verification

The host verifier `tests/verify_host_gates.c` builds the exact BFS table over all 3,674,160 states and checks the heuristic and the search against it.

## 10. H1 — Heuristic Admissibility

```text
states = 3,674,160   max_h = 8   violations = 0
```

$h(s) \le h^*(s)$ for every reachable state. **H1: PASS**

## 11. H2 — Heuristic-Table Sanity Checks

| Table | Maximum | Solved-state value |
|---|---:|---:|
| permutation | 7 | 0 |
| orientation | 6 | 0 |
| 4-cubie PDB | 8 | 0 |
| 3-cubie PDB A | 7 | 0 |
| 3-cubie PDB B | 7 | 0 |

**H2: PASS.** H4 does not apply: every table stores one `uint8_t` per entry, so there is no packed accessor. Packing to nibbles would cost about five extra instructions per lookup, and the search performs several lookups per expanded node.

## 12. H3 — Optimality Against Exact BFS

```text
states = 3,674,160   mismatches = 0
CPU time = 153.476 s   wall time = 2:35.04   max RSS = 20,096 KiB
```

The IDA* solution length equals the exact BFS distance for every reachable state. **H3: PASS.**

H1–H3 were re-run after the final changes and passed again. (The verifier source was missing its `rank_state()` helper in the Phase 1 commit and did not compile from the repository; it has been added.)

## 13. Target-Side Validation

The target program validates every result itself instead of relying on inspection of the output:

1. the solution length is at most 11, and equals the expected length when one is given (`EXPECT_LEN`);
2. every move id is in `0..8`;
3. the moves are applied, one quarter turn at a time, to an independent copy of the input using the `source[]`/`twist[]` corner model, and the result must be the solved state.

The program exits through `ecall 93`, so the Ripes exit code is the validation result (0 = pass).

The built-in test table (`SELFTEST=1`) contains my own test cases:

| State | Case | Expected moves | Result |
|---|---|---:|---|
| `12345671111111` | solved | 0 | PASS |
| `25314672313211` | short scramble | 1 | PASS |
| `74523162333332` | LED demo state | 5 | PASS |
| `62345713133111` | `tests/solutions.txt` | 8 | PASS |
| `24513763133333` | `tests/solutions.txt` | 9 | PASS |
| `25416373331111` | independent state | 10 | PASS |
| `21345671111111` | report vector | 11 | PASS |

For T7, the same program was run on both models (`PRINT=0`):

| Processor | Retired | Cycles | CPI | Exit |
|---|---:|---:|---:|---:|
| `RV32_ISS` | 21,997,698 | 21,997,698 | 1.00 | 0 |
| `RV32_5S` | 21,997,697 | 28,252,404 | 1.28 | 0 |

The extra 28% of cycles on `RV32_5S` are pipeline stalls and branch flushes; the search is branch-heavy.

---

# Stage 4 — Handwritten RV32I Implementation

## 14. Final Handwritten Path

```text
main (src/input/inline_target_main.S)
 |-- parse_state_rv32        14-character input -> p[7], o[7]
 |-- solver_solve_rv32
 |     |-- valid_rv32
 |     `-- solve_v5_rv32     IDA* bound loop
 |           |-- rank_state_parts_rv32, pattern extraction
 |           |-- heuristic_v5_rv32
 |           `-- search_v5_rv32_handwritten_final
 `-- validation (vm_quarter), optional printout, optional LED redraw
```

| File | Purpose |
|---|---|
| `src/solver/valid_rv32.S` | state validation |
| `src/solver/rank_state_parts_rv32.S` | permutation/orientation ranking |
| `src/solver/pattern_rank_rv32.S` | pattern ranking |
| `src/solver/pattern_extract_rv32.S` | pattern extraction |
| `src/solver/pattern_quarter_rv32_unrolled.S` | unrolled pattern transitions and their table |
| `src/solver/heuristic_v5_rv32.S` | five-table maximum heuristic |
| `src/solver/solve_v5_rv32.S` | IDA* bound control |
| `src/solver/search_v5_rv32_handwritten_final.S` | explicit-stack search |
| `src/solver/solver_solve_rv32.S` | public solver interface |
| `src/input/inline_state_rv32.S` | assembly-time input and parser |
| `src/input/inline_target_main.S` | driver: validation, printout, self-test, `.if RENDER` animation |
| `src/led/led_renderer_rv32_fast.S` | LED renderer |

`reference/solver_ida_core_handwritten_work.c` contributes only its constant tables to the link; its C functions are unreferenced and removed by `--gc-sections`.

## 15. RV32I ISA Audit

The target is built with `-march=rv32i -mabi=ilp32`; `readelf -A` reports `rv32i2p1`. `objdump -d` of both the measurement build and the LED build contains no `mul`, `mulh`, `mulhsu`, `mulhu`, `div`, `divu`, `rem` or `remu`, and `nm` shows no `__mulsi3`, `__divsi3`, `__udivsi3`, `__modsi3` or `__umodsi3`.

Products by small constants are shift-and-add sequences:

```asm
slli t2, a0, 3
sub  t2, t2, a0        # face * 7 = (face << 3) - face
```

The Lehmer rank multiplies by $7-i$, which takes only the values 1..7, so `rank_state_parts_rv32` dispatches to a fixed sequence per multiplier (for example $\times 3 = 2p + p$, $\times 6 = 4p + 2p$, $\times 7 = 8p - p$) instead of a generic multiply.

Orientation arithmetic adds two values of at most 2, so the sum is at most 4 and one conditional subtract replaces `% 3`:

```asm
add  t6, t6, a2        # o + twist, at most 4
addi a2, t6, -3
bltz a2, 1f
mv   t6, a2            # subtract 3 only when the sum is >= 3
1:
```

Division by 3 (to split a move id into face and turn count) is a loop of at most two subtractions.

## 16. Handwritten Search Refinement

Same input (report vector), `RV32_ISS`, solver call only:

| Version | Main change | `.text` | Retired instructions |
|---|---|---:|---:|
| CP1 | explicit-stack search + loop-based pattern updates | 3,080 B | 21,950,326 |
| CP2 | unrolled 3-/4-cubie pattern updates | 3,244 B | 17,738,811 |
| CP3 | hoisted permutation/orientation row bases | 3,244 B | 17,137,243 |

CP1 → CP2 removes 19.19% of retired instructions for 164 B of code; CP2 → CP3 removes another 3.39% at no code cost; CP1 → CP3 is 21.93% overall.

## 17. GCC `-O2` Reference Versus Handwritten Assembly

The final C algorithm compiled with GCC 14.2.0 `-O2 -march=rv32i -mabi=ilp32`, same input:

| Build | `.text` | Retired instructions | RV32_ISS wall time |
|---|---:|---:|---:|
| GCC `-O2` final C | 3,712 B | 20,568,913 | 807 ms |
| handwritten final | 3,244 B | 17,137,243 | 695 ms |

The handwritten version is 468 B (12.61%) smaller and retires 3,431,670 (16.68%) fewer instructions. The GCC build calls the `__mulsi3` software multiply helper; the handwritten version uses shift-and-add sequences instead, and computes each transition-table row base once per node (CP3).

---

# Final Quantitative Results

## 18. Static-Memory Gate

Solver build (renderer compiled out):

```text
.rodata = 119,821 B   .data = 0 B   .bss = 4,128 B   (.sdata = 7 B, .sbss = 4 B)
```

$$
0 + 4{,}128 + 119{,}821 = 123{,}949\ \text{B} < 131{,}072\ \text{B}
$$

Margin: 7,123 B (7,112 B including `.sdata` and `.sbss`). **PASS**

| Build | `.rodata` | `.bss` | Total | Margin |
|---|---:|---:|---:|---:|
| solver build | 119,821 | 4,128 | 123,949 | 7,123 |
| arbitrary-input build (`PRINT=0`) | 119,888 | 4,192 | 124,080 | 6,992 |
| LED build (`RENDER=1`) | 120,012 | 4,192 | 124,204 | 6,868 |

The Phase 1 solver build was 124,777 B. The 828 B saved is an unreferenced 780-byte copy of the pattern transition table (`o3_pattern_anchor`) that was linked into `.rodata` but never read.

## 19. Required Distance-11 Vector

`21345671111111` has optimal HTM distance 11. The solver call retires **17,137,243** instructions; the whole arbitrary-input program, including parsing and validation, retires 17,142,511.

## 20. Exhaustive Distance-11 Verification

Every one of the 2,644 distance-11 states was built into the arbitrary-input program with `EXPECT_LEN=11`, so each run also verified that the path has 11 moves and reaches the solved state.

```text
tested = 2,644 / 2,644   failures = 0
min = 6,483,719   median = 11,701,002   mean = 12,658,398   max = 48,282,220
```

The maximum is for `14325671111111` (internal zero-based form `14325670000000`). Only 7 states exceed 40 M and 3 exceed 45 M, which is why a single sampled state says little about the worst case.

$$
50{,}000{,}000 - 48{,}282{,}220 = 1{,}717{,}780
$$

The search alone (Phase 1 measurement, without validation) peaked at 48,276,943 on the same state. **PASS**

As a cross-check, I also ran every build through a small RV32I instruction-count simulator (`tools/rv32i_iss.c`); its counts match Ripes `--iret` to within one instruction.

---

# Arbitrary Assembly-Time Input

## 21. Canonical 14-Character State

The input is `PPPPPPPOOOOOOO`: seven permutation digits `1..7` followed by seven orientation digits `1..3`. It is inlined at assembly time:

```bash
./build_inline_target.sh 21345671111111                  # inline_target.elf
EXPECT_LEN=auto ./build_inline_target.sh 14325671111111  # also require the BFS distance
SELFTEST=1 ./build_inline_target.sh                      # built-in test table
```

`parse_state_rv32` rejects a string that is not exactly 14 characters or has a digit out of range; `valid_rv32` then rejects duplicate cubies and orientation sums not divisible by 3. Exit codes: 0 pass, 2 malformed string, 3 invalid state, 4 wrong length, 5 bad move id, 6 not solved.

## 22. Inline-Input Results

| State | Distance | Retired (`RV32_ISS`) | Exit |
|---|---:|---:|---:|
| `21345671111111` | 11 | 17,142,511 | 0 |
| `14325671111111` | 11 | 48,282,220 | 0 |
| `25416373331111` | 10 | 2,708,976 | 0 |

With `PRINT=1` the program also prints the result, for example:

```text
state 21345671111111: 11 moves: R B' D2 R' B R' B' R D2 R B  PASS
```

---

# LED Matrix Visualization

## 23. One Source, Two Builds

The renderer sits behind an assemble-time switch in `src/input/inline_target_main.S`:

```asm
.ifndef RENDER
.equ RENDER, 0
.endif
...
.if RENDER
    call    show_state      # one frame per 90-degree turn
.endif
```

`RENDER=0` produces the CLI build used for every `--iret` figure; `RENDER=1` (`./build_inline_led.sh STATE DELAY`) produces the GUI build. The two builds differ only in the `.if RENDER` blocks. Both the driver and the renderer are RV32I assembly.

## 24. Mapping

The LED Matrix is set to Width 35, Height 25. Each LED is one 32-bit word holding 24-bit RGB, indexed row-major as `y * WIDTH + x`, addressed through `LED_MATRIX_0_BASE`, `LED_MATRIX_0_WIDTH` and `LED_MATRIX_0_HEIGHT`. (The peripheral's in-GUI description gives a column-major formula, which does not match the implementation.)

The six faces form an unfolded net in a 4 x 3 grid of face slots. Each face is 2 x 2 facelets and each facelet is 4 x 3 pixels, so the net is $8 \times 4 + 3 = 35$ pixels wide (three separator columns) and $6 \times 3 + 2 = 20$ pixels tall (two separator rows), leaving 5 spare rows.

A facelet's colour is found from the cubie at that corner position and its orientation: `(slot - ori) mod 3` selects which of the cubie's three stickers faces that side. The mapping was checked against a physical sticker model.

The row offset uses

$$
35y = (y \ll 5) + (y \ll 1) + y,
$$

computed once per facelet, after which the 4 x 3 facelet is written with 12 `sw` instructions at fixed offsets.

## 25. Solver-Driven Animation

```text
input state -> draw -> solver -> for each returned move:
                                   for each quarter turn: apply, redraw, wait
                                -> check solved
```

The animation is driven by the moves the solver returns, not by a recording. A half turn is drawn as two frames and an inverse turn as three, so every frame differs from the previous one by exactly one 90-degree turn. The demo state `74523162333332` is solved in 5 moves (13 frames). With `LED_DELAY = 2000`, the LED build retires 92,326 instructions on `RV32_ISS` and exits with code 0.

---

# RV32_5S Pipeline Walkthrough

## 26. Five-Stage Overlap

In the LED program on Ripes `RV32_5S`, at cycle 4 five instructions occupy IF, ID, EX, MEM and WB at the same time. At cycle 5 the first instruction retires and its destination register changes, which separates an instruction being in the pipeline from an instruction retiring.

## 27. LED Memory-Mapped Store

```asm
lui x28, 0xf0000
add x7, x7, x28
sw  x31, 0(x7)
```

The `sw` reads `x7` one cycle after the `add` produces it, a RAW dependency. The register-file view has not yet been updated when the `sw` is in EX; the forwarding unit supplies the new `x7` from the EX/MEM register, visible as the forwarding multiplexer selecting the forwarded input.

## 28. `sw x31, 0(x7)` Through the Stages

$$
M[x7 + 0] \leftarrow x31
$$

- **IF**: fetch the instruction.
- **ID**: decode; read `x7` and `x31`.
- **EX**: the ALU forms the effective address $x7 + 0$.
- **MEM**: data-memory write enable is asserted and `x31` is written to the LED framebuffer.
- **WB**: register write enable is 0; a store has no destination register.

## 29. Direct MMIO Observation

With `x31 = 0x000000ff` and `LED_MATRIX_0_BASE = 0xf0000000`, one blue LED appears right after the store passes the MEM-stage clock edge. Blue is in the least significant byte. After the breakpoint is removed, the complete net is drawn on the 35 x 25 matrix.

---

# Changes After the Phase 1 Submission

| Change | Why |
|---|---|
| LED driver moved from C to the assembly driver, with the renderer behind `.if RENDER` | the assignment requires the display to be driven from assembly and one source tree to produce both builds |
| validation inside the program (length, move range, apply path, solved check) and `SELFTEST` table | the arbitrary-input build previously returned 0 whenever the solver returned, without checking the path |
| unreferenced `o3_pattern_anchor` removed, `pattern_tables_anchor` moved next to its only user | 828 B less static data; the unrolled code no longer depends on a retired file |
| exhaustive sweep script rewritten | it depended on build directories that were not in the repository and only checked the length |
| `rank_state()` added to the host verifier | the verifier did not compile from the repository |
| memory measurement redone with 4 MiB vs 64 KiB | the 32/64 KiB measurement was too small and gave an implausible slope |

The solver itself (search, heuristic, tables) is unchanged, so the solver-call instruction counts in sections 16, 17 and 19 are unchanged.

---

# Reproducibility

- Repository: https://github.com/N26151902/minirubik
- Forked from upstream `sysprog21/minirubik` at commit `231796c`.
- Final commit: `049d240` (code); later commits only update this note and its evidence
- Ripes `v2.2.6-106-g5b8a616`, `RV32_ISS` for counts, `RV32_5S` for the pipeline.

```bash
./build_inline_target.sh 21345671111111
Ripes --mode cli --src inline_target.elf -t elf --proc RV32_ISS --iret --runinfo
SELFTEST=1 ./build_inline_target.sh
./build_inline_led.sh 74523162333332 2000
RIPES=/path/to/Ripes scripts/exhaustive_handwritten_reliable.sh
```

---

# AI Disclosure

AI tools were used for code assistance, debugging, experiment planning, optimization suggestions, test construction, documentation drafting and review. After Phase 1, an AI assistant reviewed the repository and proposed the changes listed under "Changes After the Phase 1 Submission"; I reviewed each change, and every instruction count, size and memory figure in this note was measured by me in Ripes `v2.2.6-106-g5b8a616` on my own machine.

Three decisions show how AI output was handled. Each is recorded in `docs/dev_notes.md`.

**Accepted — unrolling the pattern updates (CP1 → CP2).** The suggestion was to replace the loop in the 3- and 4-cubie pattern quarter-turn with straight-line code. I accepted it after measuring it: retired instructions fell from 21,950,326 to 17,738,811 (−19.19%) for 164 B more `.text`, and H3 still passed on all states. The cost is small and the hot path runs once per child of every expanded node, so the trade was clear.

**Modified — removing the hidden division helpers.** An AI-assisted C core passed every functional test, but a symbol audit I ran afterwards (`nm` on the linked ELF) found `__udivsi3` and `__umodsi3` from libgcc. There were no M-extension opcodes, so the ISA check alone did not catch it, yet the assignment forbids these helpers. I did not keep the AI's version as it was: I restructured the core to keep the permutation and orientation ranks separate and to check the orientation sum without `%`, so the division disappeared instead of being reimplemented. The static data went down to 123,948 B, and the full 2,644-state sweep was rerun on the rebuilt core.

**Rejected — the compiler-derived search loop.** One AI-assisted step transplanted GCC `-O3` output for the search hot loop (`search_v5_rv32_o3.S`). It was functionally correct and faster than my first handwritten version (16,318,025 retired instructions on the report vector). I rejected it as the final search because its instruction scheduling came from the compiler, and the assignment requires handwritten assembly that beats GCC rather than reuses it. I rewrote the search by hand (`search_v5_rv32_handwritten_final.S`), measured it against a real GCC `-O2` build of the same C algorithm (17,137,243 vs 20,568,913), and kept the `-O3` file only in `archive/old_search/` as a reference.

In this final round, I also did not use the AI's own simulator counts as results: the AI ran the builds on its own RV32I simulator, and I re-measured every figure in Ripes on my machine before putting it in this note.
