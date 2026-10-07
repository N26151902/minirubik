# CA2026 HW1 File Manifest

## Final target source
- `src/solver/solver_solve_rv32.S` — public solver wrapper.
- `src/solver/solve_v5_rv32.S` — IDA* bound/orchestration layer.
- `src/solver/search_v5_rv32_handwritten_final.S` — final iterative handwritten RV32I search.
- `src/solver/heuristic_v5_rv32.S` — maximum of five admissible heuristics.
- `src/solver/valid_rv32.S` — state validation.
- `src/solver/rank_state_parts_rv32.S` — permutation/orientation ranks.
- `src/solver/pattern_rank_rv32.S` — pattern ranks.
- `src/solver/pattern_extract_rv32.S` — pattern extraction.
- `src/solver/pattern_quarter_rv32_unrolled.S` — optimized pattern transitions.
- `src/solver/pattern_quarter_rv32.S` — retained table-anchor/reference transition implementation required by the final link.
- `reference/solver_ida_core_handwritten_work.c` — constant transition/PDB data used by the assembly implementation.

## Input and visualization
- `src/input/inline_state_rv32.S` — canonical 14-character assembly-time input parser.
- `src/input/inline_target_main.S` — arbitrary-state target harness.
- `src/input/start_exit93.S` — reliable bare-metal Ripes exit path.
- `src/led/led_renderer_rv32_fast.S` — final handwritten LED renderer.
- `src/led/ripes_led_exports_fast.S` — Ripes LED symbol wrapper.
- `tests/led_asm_harness.c` — animation/control harness.

## Reproduction
- `build_inline_target.sh` — convenience wrapper for `scripts/build_inline_target.sh`.
- `build_inline_led.sh` — convenience wrapper for `scripts/build_inline_led.sh`.
- `scripts/exhaustive_handwritten_reliable.sh` — exhaustive distance-11 measurement procedure.
- `tests/target_validation.c` — solved/short/distance-11 target validation.
- `tests/verify_host_gates.c` — host correctness-gate verifier.

## Evidence
- `benchmarks/HOST_GATES_RESULTS.txt` — H1/H2/H3 results.
- `benchmarks/handwritten_reliable_results.tsv` — 2,644 distance-11 measurements.
- `benchmarks/handwritten_reliable_progress.txt` — exhaustive final summary.
- `benchmarks/MEASUREMENTS.txt` — assembly optimization checkpoints.
- `docs/HANDWRITTEN_FINAL_REPORT.md` — concise final report.
- `docs/PHASE1_HACKMD_DRAFT.md` — HackMD submission draft.
- `docs/dev_notes.md` — development history.

## Reference / historical material
- `reference/solver.c` and `reference/mini.c` — original/reference host programs.
- `reference/solver_ida_core_v5.c` — C algorithm reference.
- `archive/old_search/` — earlier handwritten/compiler-derived search checkpoints; not final.
- `archive/old_harnesses/` and `archive/old_results/` — superseded measurement material retained for traceability.

Generated `.o`, `.elf`, `.log`, `.inline_build/`, `final_build/`, and GUI build directories are local artifacts and are not part of the final source layout.
