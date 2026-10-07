# CA2026 HW1 Final Verification Checklist

Last audited: 2026-10-07

## Confirmed
- [x] Handwritten final is RV32I only; readelf reports rv32i2p1.
- [x] No RV32M mul/div/rem instructions and no compiler arithmetic helpers in the handwritten final.
- [x] Solver rubric static gate: 124,777 B <= 131,072 B (`.data + .bss + .rodata`); conservative total including `.sdata + .sbss` is 124,788 B.
- [x] Required vector 21345671111111 returns an optimal 11-move solution.
- [x] Known worst distance-11 state is below 50M retired instructions: 48,276,932.
- [x] Reliable ecall-93 exhaustive sweep: 2,644 / 2,644 distance-11 states passed with zero failures.
- [x] All 2,644 distance-11 states measured below 50M; maximum 48,276,943 on state 14325670000000.
- [x] H1 admissibility, H2 PDB checks, and H3 C-reference optimality checks completed previously.
- [x] Target harness independently applies returned moves and verifies solved.
- [x] Target validation passes on RV32_ISS and RV32_5S with a0=0; ecall-93 RV32_ISS also exits with real code 0.
- [x] Three own target tests: solved, one-move short scramble, distance-11 required vector.
- [x] Arbitrary 14-character assembly-time input implemented and tested on multiple states; the LED build uses the same input path.
- [x] GCC -O2 comparison now uses the pure-C final algorithm source.
- [x] Handwritten beats GCC final-C on report vector: 17,137,243 vs 20,568,913 retired; 3,244 vs 3,712 B .text.
- [x] Three handwritten optimization checkpoints have explicit measurements.
- [x] Stage-1 host-byte/guest-byte measurements recorded: 3.875 B/B (32 KiB), 3.0625 B/B (64 KiB).
- [x] Stage-1 throughput recorded: RV32_ISS ~34.36 M instr/s; RV32_5S ~0.2732 M instr/s.
- [x] Handwritten RV32I LED renderer completed.
- [x] Final LED demo uses actual solver output and redraws after solver moves.
- [x] Corrected LED sticker orientation verified against a physical model.
- [x] LED build static gate passes: 124,912 B for .data+.bss+.rodata.
- [x] LED demo RV32_ISS audit: a0=0, 178,969 retired.

## Still requires human/UI/submission action
- [x] Final Ripes GUI LED evidence captured with the selected LED demo.
- [x] Required instruction-level RV32_5S pipeline/MMIO walkthrough completed and documented.
- [ ] Put the completed English report material into the public HackMD and verify public-read / write permission Signed-in users settings.
- [ ] Ensure HackMD has at least three substantive revision-history entries.
- [x] Final Git cleanup prepared: only intended source, report, and evidence files are staged; generated ELFs/objects/logs are excluded.
- [ ] Commit and push the intended final checkpoint.
- [ ] Create the required submission tag/revision URL if required by the assignment.
