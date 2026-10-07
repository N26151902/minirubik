# Phase 1 Remaining Requirements - Student Execution Checklist

Source: official 2026 CA HW1 specification. This checklist is procedural only.
The technical choices, measurements, RV32I assembly, optimization reasoning, and analysis submitted to HackMD must be the student's own work.

## Stage 1 measurements
- [ ] Measure host-bytes-per-guest-byte ratio on this Ripes installation using a large guest-memory write loop and a small control.
- [ ] Record raw host-memory measurements and compute the slope/ratio yourself.
- [ ] Measure retired-instructions-per-second for RV32_ISS.
- [ ] Measure retired-instructions-per-second for at least one pipelined model.
- [ ] Record Ripes version and exact processor names.

## Stage 4 comparison
- [ ] Build the student's final C algorithm with riscv64-unknown-elf-gcc -O2 -march=rv32i -mabi=ilp32.
- [ ] Record linked .text bytes with renderer compiled out.
- [ ] Record --iret for the same input used to measure handwritten assembly.
- [ ] Compare GCC -O2 C baseline against handwritten assembly in code size and retired instructions.
- [ ] Explain personally why assembly wins or why any case does not.

## Iterative refinement
- [ ] Choose at least three meaningful assembly checkpoints.
- [ ] For each checkpoint record linked .text bytes and --iret on the same input.
- [ ] Explain personally what changed and why it affected instruction count/code size.

## LED Matrix
- [ ] One source tree must support renderer-off measurement build and renderer-on GUI build.
- [ ] LED Matrix = width 35, height 25.
- [ ] Renderer must be driven from assembly and use LED_MATRIX_0_BASE / WIDTH / HEIGHT symbols.
- [ ] Draw unfolded six-face net.
- [ ] Six colors remain distinguishable.
- [ ] Redraw after every actual solver-emitted move.
- [ ] Animation must use actual solver output, not prerecorded moves.
- [ ] Visually confirm initial scramble -> each move -> solved state in Ripes GUI.
- [ ] Capture required evidence/screenshots.
- [ ] T7: solved, short scramble, distance-11, and grader state reproduce on RV32_ISS and at least one visual pipeline model.

## Instruction-level walkthrough
- [ ] Pick a concrete instruction sequence from your own submitted program.
- [ ] In Ripes visualize register write enable and relevant mux selections.
- [ ] Walk the selected instruction through IF, ID, EX, MEM, WB.
- [ ] Explain personally what each stage does.
- [ ] Include a memory-writing instruction and explain address/data/write-enable behavior and why the memory result is correct.

## HackMD
- [ ] English only.
- [ ] Separate sections for stages 1-4.
- [ ] Mathematical state-space treatment: <R,B,D>, order 7!*3^6, Cayley graph/generators, HTM diameter 11, orientation-sum modulo-3 invariant.
- [ ] Reasoning must connect each optimization stage to the next.
- [ ] Quantify memory: bytes per table, peak working set, how obtained.
- [ ] Explain RV32I-specific instruction sequences personally.
- [ ] Analyze LED mapping and pipeline walkthrough personally.
- [ ] Do not paste full source listings; link GitHub and quote only short fragments.
- [ ] Retain at least three substantive HackMD revisions.
- [ ] Publish for public read; write permission owner-only.
- [ ] Record HackMD revision URL.

## Submission
- [ ] Push meaningful commits.
- [ ] Tag the exact submitted commit.
- [ ] Record tag + HackMD revision URL in submission form.
- [ ] Include required AI disclosure.
