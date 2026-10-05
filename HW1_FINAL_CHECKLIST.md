# CA2026 HW1 Final Verification Checklist

Last audited: 2026-10-04

## Confirmed PASS
- [x] RV32I build uses `-march=rv32i -mabi=ilp32`.
- [x] Final no-helper ELF audit contains none of `__mulsi3`, `__divsi3`, `__udivsi3`, `__modsi3`, or `__umodsi3`.
- [x] Static limit: `.data + .bss + .rodata = 123,948 B <= 131,072 B` (margin 7,124 B).
- [x] Exhaustive HTM-distance-11 set contains 2,644 states.
- [x] Final no-helper exhaustive run: 2,644 / 2,644 states, failures = 0.
- [x] Every distance-11 state retires fewer than 50,000,000 instructions on RV32_ISS.
- [x] Worst state: `14325670000000`, 44,568,523 retired instructions (margin 5,431,477).
- [x] Report vector `21345671111111`: 15,820,031 retired instructions, exit code 0.
- [x] H1: heuristic admissibility checked over all 3,674,160 states; violations = 0.
- [x] H2: PDB solved entries/population/maxima checks PASS.
- [x] H3: final search checked against exact BFS distance over all 3,674,160 states; mismatches = 0.
- [x] H4: N/A because final PDB distances use unpacked uint8_t arrays.
- [x] T5 known target-harness cases apply returned paths and reach solved on RV32I target.
- [x] T6 required vector reaches solved at optimal distance 11.
- [x] RV32_5S target harness: exit 0; 15,825,701 retired; 18,437,979 cycles; CPI 1.1650655; IPC 0.8583208.
- [x] 35x25 LED MMIO geometry/color renderer is working; animation-only golden reference preserved.

## In progress / partial evidence
- [ ] T7 final: known harness cases pass on RV32_ISS and RV32_5S, but grader-provided state is not yet available.
- [ ] Actual-solver LED GUI: 3-move build showed the initial scramble and executed; 1-move actual-solver build awaits final visual solved-state confirmation.
- [ ] Capture final Ripes screenshots/evidence after actual-solver LED confirmation.

## Still required before submission
- [ ] Record required Stage-1 host-byte and guest-byte measurements.
- [ ] Record/derive the required RV32_ISS retired-instructions-per-second metric if the rubric requires it.
- [ ] Complete instruction-level pipeline walkthrough evidence.
- [ ] Complete handwritten-RV32I implementation/integration required by Phase 1.
- [ ] Compare handwritten RV32I against GCC `-O2` RV32I final-C baseline (instructions and code size).
- [ ] Ensure final LED renderer/integration satisfies the handwritten-assembly requirement, not only C compiled to RV32I.
- [ ] Update the English HackMD/report from the old BFS description to the final IDA*/PDB design.
- [ ] Verify HackMD public-read / owner-write settings and required revision evidence.
- [ ] Decide final source/evidence files; exclude temporary ELFs/logs/backups unless intentionally submitted.
- [ ] Commit and push verification, LED, and later handwritten-RV32I work in meaningful stages.
- [ ] Tag the final submitted commit and record the tag plus HackMD revision URL.
