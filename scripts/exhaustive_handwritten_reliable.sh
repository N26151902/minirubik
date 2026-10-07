#!/bin/bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
RIPES="$HOME/下載/Ripes-v2.2.6-106-g5b8a616-linux-x86_64.AppImage"
export DISPLAY=:0
export XAUTHORITY=/run/user/1000/.mutter-Xwaylandauth.3PE5W3
export QT_QPA_PLATFORM=xcb
# Reuse the already-built handwritten integration objects in /tmp.
# final_build/search_v5_rv32_handwritten_final.o is the optimized handwritten search under test.
test -f final_build/search_v5_rv32_handwritten_final.o || exit 90
test -f final_build/pattern_quarter_rv32_unrolled.o || exit 91
: > benchmarks/handwritten_reliable_results.tsv
max=0; maxstate=''; n=0; failures=0
while IFS= read -r s; do
  n=$((n+1))
  p0=$((${s:0:1}-1)); p1=$((${s:1:1}-1)); p2=$((${s:2:1}-1)); p3=$((${s:3:1}-1)); p4=$((${s:4:1}-1)); p5=$((${s:5:1}-1)); p6=$((${s:6:1}-1))
  o0=${s:7:1}; o1=${s:8:1}; o2=${s:9:1}; o3=${s:10:1}; o4=${s:11:1}; o5=${s:12:1}; o6=${s:13:1}
  cat > exhaustive_harness.c <<EOF
#include <stdint.h>
int solver_init_rv32(void); int solver_solve_rv32(const uint8_t p[7], const uint8_t o[7], uint8_t moves[32], int *move_count);
int main(void){const uint8_t p[7]={$p0,$p1,$p2,$p3,$p4,$p5,$p6}; const uint8_t o[7]={$o0,$o1,$o2,$o3,$o4,$o5,$o6}; uint8_t m[32]; int c=-1; if(!solver_init_rv32())return 2; if(!solver_solve_rv32(p,o,m,&c))return 3; return c==11?0:4;}
EOF
  riscv64-unknown-elf-gcc -O3 -march=rv32i -mabi=ilp32 -ffreestanding -nostdlib -c exhaustive_harness.c -o exhaustive_harness.o || { echo -e "$s\tCOMPILE_FAIL" >> benchmarks/handwritten_reliable_results.tsv; continue; }
  riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Wl,--gc-sections final_validation/start_exit93.o final_build/core.o final_build/valid_rv32.o final_build/rank_state_parts_rv32.o final_build/pattern_rank_rv32.o final_build/pattern_extract_rv32.o final_build/pattern_quarter_rv32.o final_build/pattern_quarter_rv32_unrolled.o final_build/heuristic_v5_rv32.o final_build/solver_solve_rv32.o final_build/search_v5_rv32_handwritten_final.o final_build/solve_v5_rv32.o exhaustive_harness.o -o exhaustive.elf 2>/dev/null || { echo -e "$s\tLINK_FAIL" >> benchmarks/handwritten_reliable_results.tsv; continue; }
  out=$("$RIPES" --mode cli --src exhaustive.elf -t elf --proc RV32_ISS --iret --cycles --runinfo 2>/dev/null)
  ret=$(printf '%s\n' "$out" | awk '/instructions retired/{getline; print; exit}')
  exitcode=$(printf '%s\n' "$out" | sed -n 's/Program exited with code: //p' | head -1)
  if [[ -z "$ret" ]]; then ret=RUN_FAIL; fi
  printf '%s\t%s\t%s\n' "$s" "$ret" "${exitcode:-NA}" >> benchmarks/handwritten_reliable_results.tsv
  if [[ "$ret" =~ ^[0-9]+$ ]] && (( ret > max )); then max=$ret; maxstate=$s; fi
  if [[ "${exitcode:-NA}" != 0 ]]; then failures=$((failures+1)); fi
  if (( n % 50 == 0 )); then printf 'progress=%d max=%s state=%s failures=%d\n' "$n" "$max" "$maxstate" "$failures" > benchmarks/handwritten_reliable_progress.txt; fi
done < <(head -n 2644 tests/distance11_states.txt)
printf 'DONE count=%d max=%s state=%s failures=%d\n' "$n" "$max" "$maxstate" "$failures" > benchmarks/handwritten_reliable_progress.txt
