# CA2026 HW1 Final Verification Checklist

Last audited: 2026-10-06
Authoritative solver for Phase 1: handwritten RV32I integration.

## Confirmed PASS - handwritten final
- [x] Final target build uses `-march=rv32i -mabi=ilp32`; readelf reports `rv32i2p1`.
- [x] `solve_v5_rv32.S` calls `search_v5_rv32_handwritten_final` directly.
- [x] Linked final ELF does not contain `search_v5_rv32_o3`.
- [x] Objdump finds no RV32M `mul/mulh/div/rem` instructions.
- [x] Symbol audit finds no compiler multiply/divide/modulo helper routines.
- [x] Static gate: 124,804 B <= 131,072 B; margin 6,268 B.
- [x] Clean report-vector run: 11 moves, exit 0, 17,137,243 retired instructions.
- [x] Clean known-worst-state run `14325670000000`: 11 moves, exit 0, 48,276,932 retired.
- [x] Exhaustive distance-11 run: 2,644 / 2,644, failures = 0.
- [x] Exhaustive maximum: 48,276,943 retired at `14325670000000`; margin 1,723,057.
- [x] Every tested distance-11 state is below 50,000,000 retired instructions.
- [x] H1: heuristic admissibility previously checked over all 3,674,160 states; violations = 0.
- [x] H2: PDB solved entries/population/maxima checks PASS.
- [x] H3: C-reference search previously checked against exact BFS distance over all 3,674,160 states; mismatches = 0.
- [x] H4: N/A because PDB distances use unpacked uint8_t arrays.
- [x] Known target harness cases validate returned paths and reach solved.
- [x] 35x25 LED MMIO geometry/color renderer has working historical evidence.

## Historical/reference only
- The 2026-10-03 C no-helper final and its 44,568,523 worst-case result remain useful baseline evidence.
- `search_v5_rv32_o3.S` is compiler-derived reference code. Do not call it handwritten and do not submit it as the final search implementation.
- Earlier O3-integrated 45,975,038 worst-case and 124,788-B static measurements are superseded by the handwritten-final measurements above.

## Still required / submission packaging
- [ ] Confirm whether the rubric requires the LED renderer itself to be handwritten assembly; current renderer history includes C-generated RV32I.
- [ ] Capture any final Ripes GUI screenshots explicitly required by the rubric.
- [ ] Record Stage-1 host-byte / guest-byte metrics if explicitly required.
- [ ] Record/derive RV32_ISS retired-instructions-per-second if explicitly required.
- [ ] Complete any required instruction-level pipeline walkthrough.
- [ ] Update the English HackMD/report to describe IDA* + five-table heuristic/PDB design and the handwritten final.
- [ ] Verify HackMD public-read / owner-write settings and revision evidence.
- [ ] Submit only the intended source/report/evidence files; exclude temporary ELFs, objects, logs, backups and experiments.
- [ ] Commit/push the final source and documentation in a meaningful final checkpoint.
- [ ] Tag the submitted commit if the assignment requires a tag.
