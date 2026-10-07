#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
STATE="${1:-21345671111111}"
if [[ ! "$STATE" =~ ^[1-7]{7}[1-3]{7}$ ]]; then
    echo "usage: $0 PPPPPPPOOOOOOO  (P digits 1..7, O digits 1..3)" >&2
    exit 2
fi
CC=riscv64-unknown-elf-gcc
CFLAGS=(-O3 -march=rv32i -mabi=ilp32 -ffreestanding -nostdlib -ffunction-sections -fdata-sections -Itables)
rm -rf .inline_build
mkdir .inline_build
$CC "${CFLAGS[@]}" -c reference/solver_ida_core_handwritten_work.c -o .inline_build/core.o
for f in valid_rv32.S rank_state_parts_rv32.S pattern_rank_rv32.S pattern_extract_rv32.S pattern_quarter_rv32.S pattern_quarter_rv32_unrolled.S heuristic_v5_rv32.S solver_solve_rv32.S search_v5_rv32_handwritten_final.S solve_v5_rv32.S; do
    $CC "${CFLAGS[@]}" -c "src/solver/$f" -o ".inline_build/${f%.S}.o"
done
$CC "${CFLAGS[@]}" -DCUBE_STATE=\""$STATE"\" -c src/input/inline_state_rv32.S -o .inline_build/inline_state.o
$CC "${CFLAGS[@]}" -c src/input/inline_target_main.S -o .inline_build/inline_main.o
$CC "${CFLAGS[@]}" -c src/input/start_exit93.S -o .inline_build/start.o
$CC -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Wl,--gc-sections \
  .inline_build/start.o .inline_build/core.o \
  .inline_build/valid_rv32.o .inline_build/rank_state_parts_rv32.o \
  .inline_build/pattern_rank_rv32.o .inline_build/pattern_extract_rv32.o \
  .inline_build/pattern_quarter_rv32.o .inline_build/pattern_quarter_rv32_unrolled.o \
  .inline_build/heuristic_v5_rv32.o .inline_build/solver_solve_rv32.o \
  .inline_build/search_v5_rv32_handwritten_final.o .inline_build/solve_v5_rv32.o \
  .inline_build/inline_state.o .inline_build/inline_main.o -o inline_target.elf
echo "built inline_target.elf with CUBE_STATE=$STATE"
