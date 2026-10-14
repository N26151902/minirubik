#!/bin/bash
# Run every distance-11 state in tests/distance11_states.txt through the
# final RV32I build on Ripes RV32_ISS and record retired instructions.
#
#   RIPES=/path/to/Ripes.AppImage scripts/exhaustive_handwritten_reliable.sh
#
# Each state is built with EXPECT_LEN=11 and PRINT=0, so the program itself
# checks that the solution has 11 moves and that applying it reaches the
# solved cube; a non-zero exit code is a failure.  Solver objects are built
# once and reused (REUSE_OBJS=1); only the input string is re-assembled.
#
# Input file states use zero-based orientation digits (e.g. 14325670000000);
# they are converted to the canonical 1-based form here.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
RIPES="${RIPES:?set RIPES to the Ripes executable or AppImage}"
PROC="${PROC:-RV32_ISS}"
RESULTS=benchmarks/handwritten_reliable_results.tsv
PROGRESS=benchmarks/handwritten_reliable_progress.txt

scripts/build_inline_target.sh 21345671111111 >/dev/null || exit 90
: > "$RESULTS"
max=0; maxstate=''; n=0; failures=0
while IFS= read -r s; do
    [[ "$s" =~ ^[1-7]{7}[0-2]{7}$ ]] || continue   # skip the summary trailer
    n=$((n+1))
    canon="${s:0:7}"
    for ((i = 7; i < 14; i++)); do canon+=$(( ${s:i:1} + 1 )); done
    if ! REUSE_OBJS=1 PRINT=0 EXPECT_LEN=11 OUT=exhaustive.elf \
            scripts/build_inline_target.sh "$canon" >/dev/null 2>&1; then
        printf '%s\tBUILD_FAIL\tNA\n' "$s" >> "$RESULTS"; failures=$((failures+1)); continue
    fi
    out=$("$RIPES" --mode cli --src exhaustive.elf -t elf --proc "$PROC" --iret --runinfo 2>/dev/null)
    ret=$(printf '%s\n' "$out" | awk '/instructions retired/{getline; print; exit}')
    exitcode=$(printf '%s\n' "$out" | sed -n 's/Program exited with code: //p' | head -1)
    [[ -z "$ret" ]] && ret=RUN_FAIL
    printf '%s\t%s\t%s\n' "$s" "$ret" "${exitcode:-NA}" >> "$RESULTS"
    if [[ "$ret" =~ ^[0-9]+$ ]] && (( ret > max )); then max=$ret; maxstate=$s; fi
    [[ "${exitcode:-NA}" != 0 ]] && failures=$((failures+1))
    if (( n % 50 == 0 )); then
        printf 'progress=%d max=%s state=%s failures=%d\n' "$n" "$max" "$maxstate" "$failures" > "$PROGRESS"
    fi
done < tests/distance11_states.txt
rm -f exhaustive.elf
printf 'DONE count=%d max=%s state=%s failures=%d\n' "$n" "$max" "$maxstate" "$failures" | tee "$PROGRESS"
