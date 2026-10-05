# Handwritten RV32I Translation Plan

Date: 2026-10-04
Source of truth: solver_ida_core_v5.c
Target: RV32I / ILP32, Ripes v2.2.6-106-g5b8a616

## Goal

Do not translate the whole C file blindly. Treat the final C solver as the behavioral specification, then replace compiler-generated pieces with understandable handwritten RV32I in small verified steps.

## Current solver structure

1. solver_solve
   - validate pointers
   - copy p[7]/o[7] into state_t
   - valid(state)
   - solve_v5(state)
   - copy global path[] to output moves[]
2. solve_v5
   - rank permutation/orientation
   - extract 4-cubie and two 3-cubie pattern states
   - compute initial heuristic bound
   - repeatedly call iterative search_v5 until FOUND
3. search_v5
   - explicit depth stacks (no recursion)
   - evaluate f = depth + heuristic
   - prune if f > bound
   - detect solved p==0 && o==0
   - suppress consecutive moves on the same face
   - update permutation/orientation through precomputed transition tables
   - update pattern states
   - descend/backtrack iteratively
4. heuristic_v5
   - max of permutation, orientation, PDB4, PDB3a, PDB3b distances
5. pattern/rank helpers
   - pattern3_rank_parts
   - pattern3_quarter
   - pattern4_rank_parts
   - pattern_quarter
   - pattern extraction
   - rank_state_parts
6. valid
   - cubie range, duplicate permutation, orientation-sum checks

## Recommended handwritten order

Phase A (learn ABI / easy):
1. solver_init (return 1)
2. valid
3. rank_state_parts
4. pattern extraction helpers

Phase B (table/addressing):
5. pattern3_rank_parts
6. pattern3_quarter
7. pattern4 rank/update
8. heuristic_v5

Phase C (search):
9. solve_v5
10. search_v5

Phase D (integration):
11. solver_solve
12. LED renderer hook / final target harness

Each handwritten function must be tested against the C implementation before replacing the next function.

## Register-planning principle

Do not freeze exact assignments until inspecting each function, but use:
- a0-a7: ABI arguments / return values
- t0-t6: short-lived calculations
- s0-s11: loop/search values that must survive calls
- sp: explicit local arrays / saved registers
- ra: save only in non-leaf functions

For search_v5, likely long-lived values include depth, bound, minimum, and base pointers to explicit stacks. Keep hot values in s-registers where this reduces repeated stack loads.

## Optimization targets versus GCC

Look especially for:
- compiler helper calls such as __mulsi3
- repeated stack reloads in search_v5
- address arithmetic that can use shifts/adds
- repeated setup of table base addresses
- avoidable function-call overhead in hot pattern/heuristic code
- hot-loop values that can stay in registers
- face*3 as (face<<1)+face
- fixed small multipliers implemented with shifts/adds

## Verification after every stage

1. Build with -march=rv32i -mabi=ilp32.
2. Objdump/readelf: RV32I only.
3. Symbol audit: no forbidden compiler helpers in final handwritten build.
4. Correctness: solved + short scramble + required distance-11 vector.
5. Compare returned solution/path against C reference where applicable.
6. Ripes RV32_ISS retired instructions.
7. Track .text and .data+.bss+.rodata.
8. Periodically rerun exhaustive distance-11 performance set after search changes.

## Important distinction

The GCC -O2 output is a baseline and learning reference, not the handwritten submission. The handwritten version should be explainable instruction-by-instruction and should record why each optimization was chosen.
