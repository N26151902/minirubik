#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
STATE="${1:-74523162333332}"
DELAY="${2:-2000}"
./scripts/build_inline_target.sh "$STATE" >/dev/null
CC=riscv64-unknown-elf-gcc
CFLAGS=(-O2 -march=rv32i -mabi=ilp32 -ffreestanding -nostdlib -ffunction-sections -fdata-sections -Itables)
$CC "${CFLAGS[@]}" -DINLINE_INPUT=1 -DLED_DELAY="$DELAY" -DQUARTER_FRAMES=1 -c tests/led_asm_harness.c -o .inline_build/led_harness.o
$CC -march=rv32i -mabi=ilp32 -Wa,-Isrc/led -c src/led/ripes_led_exports_fast.S -o .inline_build/led_renderer.o
$CC -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Wl,--gc-sections \
  .inline_build/start.o .inline_build/core.o \
  .inline_build/valid_rv32.o .inline_build/rank_state_parts_rv32.o \
  .inline_build/pattern_rank_rv32.o .inline_build/pattern_extract_rv32.o \
  .inline_build/pattern_quarter_rv32.o .inline_build/pattern_quarter_rv32_unrolled.o \
  .inline_build/heuristic_v5_rv32.o .inline_build/solver_solve_rv32.o \
  .inline_build/search_v5_rv32_handwritten_final.o .inline_build/solve_v5_rv32.o \
  .inline_build/inline_state.o .inline_build/led_renderer.o .inline_build/led_harness.o \
  -o inline_led.elf
echo "built inline_led.elf with CUBE_STATE=$STATE LED_DELAY=$DELAY"
