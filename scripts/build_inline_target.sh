#!/bin/bash
# Build the RV32I solver for one 14-character state inlined at assembly time.
#
#   scripts/build_inline_target.sh STATE            -> inline_target.elf
#
# Environment (all optional):
#   RENDER=1        GUI build with the LED renderer (output inline_led.elf)
#   LED_DELAY=N     busy-wait iterations per LED frame (RENDER=1 only)
#   PRINT=0|1       print the solution through Ripes ecalls (default 1)
#   SELFTEST=1      ignore STATE and run the built-in test table
#   EXPECT_LEN=N    require a solution of exactly N moves;
#   EXPECT_LEN=auto take N from the host BFS oracle (./solver, built if needed)
#   REUSE_OBJS=1    keep the solver objects from a previous build and only
#                   re-assemble the input and driver (used by the sweep script)
#   OUT=file.elf    output name
#
# The RENDER=0 and RENDER=1 builds come from the same source files and differ
# only in the `.if RENDER` blocks of src/input/inline_target_main.S.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

STATE="${1:-21345671111111}"
if [[ ! "$STATE" =~ ^[1-7]{7}[1-3]{7}$ ]]; then
    echo "usage: $0 PPPPPPPOOOOOOO  (P digits 1..7, O digits 1..3)" >&2
    exit 2
fi
RENDER="${RENDER:-0}"
PRINT="${PRINT:-1}"
SELFTEST="${SELFTEST:-0}"
LED_DELAY="${LED_DELAY:-2000}"
EXPECT_LEN="${EXPECT_LEN:-}"
if [[ "$RENDER" == 1 ]]; then OUT="${OUT:-inline_led.elf}"; else OUT="${OUT:-inline_target.elf}"; fi

if [[ "$EXPECT_LEN" == auto ]]; then
    [[ -x ./solver ]] || make -s solver >/dev/null
    sol="$(./solver "$STATE")" || { echo "host solver rejected $STATE" >&2; exit 2; }
    EXPECT_LEN="$(wc -w <<<"$sol" | tr -d ' ')"
fi

CC=riscv64-unknown-elf-gcc
ARCH=(-march=rv32i -mabi=ilp32)
CFLAGS=("${ARCH[@]}" -O3 -ffreestanding -nostdlib -ffunction-sections -fdata-sections -Itables)
B=.inline_build
SOLVER_OBJS=(valid_rv32 rank_state_parts_rv32 pattern_rank_rv32 pattern_extract_rv32
             pattern_quarter_rv32_unrolled heuristic_v5_rv32 solver_solve_rv32
             search_v5_rv32_handwritten_final solve_v5_rv32)

if [[ "${REUSE_OBJS:-0}" != 1 || ! -f $B/core.o ]]; then
    rm -rf $B
    mkdir $B
    # Only the read-only transition/heuristic tables of this file survive
    # --gc-sections; its C search functions are unreferenced and discarded.
    $CC "${CFLAGS[@]}" -c reference/solver_ida_core_handwritten_work.c -o $B/core.o
    for f in "${SOLVER_OBJS[@]}"; do
        $CC "${CFLAGS[@]}" -c "src/solver/$f.S" -o "$B/$f.o"
    done
    $CC "${CFLAGS[@]}" -c src/input/start_exit93.S -o $B/start.o
fi

DEFS=(-Wa,--defsym,RENDER="$RENDER" -Wa,--defsym,PRINT="$PRINT"
      -Wa,--defsym,SELFTEST="$SELFTEST" -Wa,--defsym,LED_DELAY="$LED_DELAY")
[[ -n "$EXPECT_LEN" ]] && DEFS+=(-Wa,--defsym,EXPECT_LEN="$EXPECT_LEN")

$CC "${CFLAGS[@]}" -DCUBE_STATE=\""$STATE"\" -c src/input/inline_state_rv32.S -o $B/inline_state.o
$CC "${CFLAGS[@]}" "${DEFS[@]}" -Wa,-Isrc/led -c src/input/inline_target_main.S -o $B/inline_main.o

OBJS=()
for f in "${SOLVER_OBJS[@]}"; do OBJS+=("$B/$f.o"); done
$CC "${ARCH[@]}" -nostdlib -nostartfiles -Wl,--gc-sections \
    $B/start.o $B/core.o "${OBJS[@]}" \
    $B/inline_state.o $B/inline_main.o -o "$OUT"

if [[ "$SELFTEST" == 1 ]]; then what="built-in test table"; else what="CUBE_STATE=$STATE"; fi
echo "built $OUT ($what, RENDER=$RENDER, PRINT=$PRINT${EXPECT_LEN:+, EXPECT_LEN=$EXPECT_LEN})"
