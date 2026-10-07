# CA2026 HW1 — Memory-Bounded Optimal MiniRubik Solver

This repository contains the Phase 1 implementation for the CA2026 MiniRubik assignment. The final target solver is handwritten RV32I and uses iterative IDA* with five admissible lower bounds. Host-side programs are used only to generate/verify data and to establish exact BFS reference distances.

## Final measured results

| Item | Result |
|---|---:|
| Reachable states | 3,674,160 |
| HTM diameter | 11 |
| `.data + .bss + .rodata` (official measured solver core) | 124,777 B |
| Required vector `21345671111111` | 17,137,243 retired instructions |
| Exhaustive distance-11 maximum | 48,276,943 retired instructions |
| Distance-11 states checked | 2,644 / 2,644 PASS |
| Final handwritten `.text` | 3,244 B |

The reorganized arbitrary-input build is also within the 128 KiB gate (124,846 B including the inline input string/parser data). The exhaustive maximum is below the 50,000,000-instruction gate. See `benchmarks/` and `docs/HANDWRITTEN_FINAL_REPORT.md` for the measurement context.

## Repository layout

- `src/solver/` — final handwritten RV32I solver and hot-path helpers.
- `src/input/` — assembly-time 14-character state parser and bare-metal entry.
- `src/led/` — Ripes 35x25 LED Matrix renderer.
- `reference/` — C reference/baseline implementations and constant table data linked by the RV32I solver.
- `tables/` — generated table artifacts kept separately from executable search logic.
- `tests/` — target validation, host correctness gates, and renderer tests.
- `scripts/` — reproducible target/LED build and exhaustive-test scripts.
- `benchmarks/` — retained measurement evidence.
- `docs/` — final report, HackMD draft, checklist, and development notes.
- `tools/` — host-side generators/analysis utilities.
- `archive/` — historical checkpoints retained for development traceability; these are not the final implementation.

## Final implementation

The final search path is:

`solver_solve_rv32 -> solve_v5_rv32 -> heuristic_v5_rv32 -> search_v5_rv32_handwritten_final`

The search is iterative IDA* (no recursion and no heap allocation). Its heuristic is the maximum of permutation, orientation, one 4-cubie pattern database, and two 3-cubie pattern databases. The maximum remains admissible, while the pattern abstractions capture position/orientation coupling that separate permutation/orientation abstractions can miss.

The full 3,674,160-state distance table is **not** linked into the target. Exact BFS is used only on the host as a correctness oracle.

## Build an arbitrary target state

The canonical input is seven permutation digits (`1..7`) followed by seven orientation digits (`1..3`). For example:

```sh
./build_inline_target.sh 21345671111111
```

The top-level wrapper calls `scripts/build_inline_target.sh` and produces `inline_target.elf`.

For the LED visualization:

```sh
./build_inline_led.sh 74523162333332 2000
```

This produces `inline_led.elf`. The renderer is intentionally excluded from official solver-performance measurements.

## Correctness evidence

Host verification established:

- H1: all 3,674,160 reachable states satisfy `h(s) <= d_BFS(s)`.
- H2: all heuristic tables are populated and have the solved entry equal to zero.
- H3: IDA* solution length equals the exact BFS distance for all 3,674,160 states.
- Distance-11 target sweep: 2,644 / 2,644 states passed with a worst case of 48,276,943 retired instructions.

See `benchmarks/HOST_GATES_RESULTS.txt` and `benchmarks/handwritten_reliable_progress.txt`.

## RV32I and LED

The final target is built for `-march=rv32i -mabi=ilp32`; the final audit contains no multiply/divide compiler helpers. The LED renderer uses the Ripes LED Matrix symbols and writes one 32-bit RGB word per pixel in row-major order. The GUI renderer and official CLI performance build share the same solver; only the renderer path differs.

## Historical files

Files under `archive/` are deliberately retained so optimization steps can be inspected. In particular, compiler-derived and earlier handwritten search versions are **references only**. The final search implementation is `src/solver/search_v5_rv32_handwritten_final.S`.

## Documentation

Start with `docs/HANDWRITTEN_FINAL_REPORT.md` for the concise technical report and `docs/PHASE1_HACKMD_DRAFT.md` for the submission-note draft. `docs/dev_notes.md` records development history and measurements.
