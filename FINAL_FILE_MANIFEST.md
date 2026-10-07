# CA2026 HW1 File Manifest

## A. Final source - primary submission candidates
These implement or directly support the final handwritten RV32I solver:
- `solver_solve_rv32.S` - public handwritten wrapper.
- `solve_v5_rv32.S` - IDA* bound/orchestration layer; calls final handwritten search.
- `search_v5_rv32_handwritten_final.S` - final handwritten iterative IDA* search.
- `heuristic_v5_rv32.S` - five-table max heuristic.
- `valid_rv32.S` - input-state validation.
- `rank_state_parts_rv32.S` - permutation/orientation rank.
- `pattern_rank_rv32.S` - pattern ranks.
- `pattern_extract_rv32.S` - pattern extraction.
- `pattern_quarter_rv32_unrolled.S` - final hot pattern transitions.
- `pattern_quarter_rv32.S` - table anchor/reference transition implementation; retain because the final link currently uses its exported table anchor.
- `solver_ida_core_handwritten_work.c` - exported constant transition/PDB data used by the assembly implementation. Rename/refactor before submission only if the rubric requires a particular filename.
- `start.S` - bare-metal startup used for Ripes target builds.

## B. Report and verification evidence
Recommended to retain in the repository and submit only if the rubric asks for evidence:
- `HANDWRITTEN_FINAL_REPORT.md` - concise final design/results report.
- `HW1_FINAL_CHECKLIST.md` - current pass/gap checklist.
- `dev_notes.md` - development history and measured checkpoints.
- `RV32I_TRANSLATION_PLAN.md` - translation rationale/plan.
- `handwritten_inline_exhaustive_results.tsv` - all 2,644 handwritten exhaustive measurements.
- `handwritten_inline_exhaustive_progress.txt` - final exhaustive summary.
- `distance11_states.txt` - distance-11 input set.
- `exhaustive_handwritten_inline.sh` - exhaustive measurement script.
- `worst_handwritten_harness.c` - standalone worst-state harness.

## C. Historical/reference source - normally do not submit as final implementation
- `search_v5_rv32_o3.S` - compiler-derived O3 search reference; NOT handwritten final.
- `search_v5_rv32_handwritten.S` - first handwritten search before optimization.
- `search_v5_rv32_handwritten_inline.S` - optimized checkpoint from which final was frozen.
- `solver_ida_core_v5.c` and `solver_ida_core_v5_*.c` - C baselines/checkpoints.
- `solver_gcc_O2.s`, `solver_ida_core*.s` - compiler-generated/reference assembly.
- PDB experiment/generator programs and result files.

## D. Generated/test artifacts - do not submit unless explicitly requested
- `final_build/` - clean local verification objects/ELFs.
- all `*.o`, `*.elf`, `*.log` generated during experiments.
- `exhaustive.elf`, `report_vector*.elf`, `solver_ida_rv32*.elf`, `target_gates.elf`.
- backup files containing `backup`, `pre_`, `GOLDEN_DO_NOT_TOUCH`, or similar experiment labels.
- host-only test executables such as `dump_d11`, `generate_pdb3`, `verify_host_gates`, and experiment binaries.

## Important packaging note
Do not blindly submit every untracked file in the working tree. The repository contains extensive experimental and generated artifacts. Final packaging should follow the assignment's exact required filenames and include only the necessary source plus explicitly requested evidence.

## E. Final arbitrary-input and LED entry points
- inline_state_rv32.S - handwritten parser for the canonical 14-character assembly-time state.
- inline_target_main.S - arbitrary-state target harness.
- start_exit93.S - reliable Ripes exit-code startup.
- build_inline_target.sh - clean source build for an arbitrary target state.
- build_inline_led.sh - same arbitrary state path with the LED renderer.
- led_asm_build_fast/led_renderer_rv32_fast.S - handwritten fast LED renderer.
- led_asm_build_fast/ripes_led_exports_fast.S - Ripes LED symbol wrapper used for GNU linking.
- led_asm_build_fast/led_asm_harness.c - animation/control harness; validates final solved state.
