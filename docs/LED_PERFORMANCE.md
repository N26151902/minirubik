# Why `minirubik_final_asm_led.elf` is slow in Ripes, and the fix

## 1. Where the instructions go (measured, Ripes CLI, RV32_ISS)

| Part of `minirubik_final_asm_led.elf` | Retired instructions | Share |
|---|---:|---:|
| 3 × `pause` busy-wait (20,000 iterations × 5 instr) | 300,000 | 73.5% |
| `led_render_init` (clear 875 LEDs) | 63,162 | 15.5% |
| 2 × `led_render_state` (24 facelets × 12 LEDs) | 40,724 | 10.0% |
| solver (1-move scramble) + harness | 4,183 | 1.0% |
| **Total** | **408,069** | |

Method: the ELF was binary-patched to set the delay count to 0, then to replace the render calls with `nop`, and re-run each time.

Per LED written, the original renderer spends about 70 instructions:
- `.Lput_led` computes `y*WIDTH` with a repeated-addition loop, up to 24 iterations × 4 instructions, for every pixel.
- It re-checks the bounds and recomputes `LED_MATRIX_0_BASE` for every pixel.
- `led_render_init` and `.Lfill_facelet` call it once per pixel, with stack spills around each call.

## 2. Why that becomes "very slow" in the GUI

The program is only about 0.4 M instructions, which takes 23 ms in CLI on `RV32_ISS` and 2.6 s on `RV32_5S`. The slowness comes from how the GUI clocks the model:

| GUI mode / model | Approx. speed | Time for 408k instructions |
|---|---|---|
| **Auto clock (F6)**, default interval 100 ms | 10 cycles/s | ≈ 11 h (RV32_5S: 635k cycles ≈ 17.6 h) |
| Auto clock at the 1 ms minimum | ≤ 1,000 cycles/s | ≥ 7 min (RV32_5S: ≥ 10.6 min) |
| **Run (F8)**, RV32_5S (course table: 20.5 k instr/s) | 20.5 k/s | ≈ 20 s |
| **Run (F8)**, RV32_ISS (course table: 1.09 M instr/s) | 1.09 M/s | ≈ 0.4 s |

Sources:
- Ripes source at the same commit `5b8a616`: `RIPES_SETTING_AUTOCLOCK_INTERVAL` defaults to 100 ms, the spin-box range is 1–10000 ms, and Auto clock issues one clock per timer tick. The default processor is `RV32_5S`.
- Run (F8) is documented as "Execute simulator without updating UI (fast execution)". In Run mode, the LED widget is still refreshed: each `IOLedMatrix::ioWrite` emits `scheduleUpdate()`, which is connected to `QWidget::update()`.
- The `instr/s` rows come from the course spec's table (RV32_ISS 1.09 M/s, RV32_SS 86 k/s, RV32_5S 20.5 k/s, RV32_6S_DUAL 6.2 k/s).

So, in order of impact:
1. **Use Run (F8), not Auto clock or Clock**, for the animation. Auto clock is meant for watching single instructions move through the pipeline.
2. **Use `RV32_ISS` for the animation**. Use the 5-stage model only for the instruction-level walkthrough. The spec says the visual pipeline models are "worth using to step through a single query".
3. **Delays are tuned for ISS**. On RV32_5S each 100k-instruction pause costs ~5 s and dominates the run. Re-tune `LED_DELAY` per model.
4. **Renderer cost**. 104k instructions per run, 63k of them for clearing the screen.
5. With a real distance-11 scramble, the solver itself is 17–48 M instructions. In GUI that is ~15–45 s on RV32_ISS and ~15–40 min on RV32_5S, whatever the renderer does. Demo the GUI on `RV32_ISS`, or use a short scramble on a pipeline model.

## 3. Fast renderer (`led_renderer_rv32_fast.S`)

It keeps the same ABI, colors and layout, and is still handwritten RV32I with no M extension. The changes:
- `y*35` is computed once per facelet as `(y<<5)+(y<<1)+y`, not with a per-pixel loop.
- A facelet is 12 `sw` through one pointer, with row stride `WIDTH*4`. There is no per-pixel call, bounds check or stack traffic.
- The clear loop writes 5 words per iteration through a single pointer.
- `led_render_state` is a leaf function that uses only caller-saved registers.
- The `led_corner_faces` sticker order is corrected (see 4b). For that reason, the equivalence test against the old renderer no longer applies to this version.

**Correctness.** `renderer_equivalence_test.c` draws 42 states with both renderers and compares all 875 framebuffer words:
- The 42 states are solved, the worst state `14325670000000`, and 40 random distance-11 states.
- Result: 0 mismatches.
- A deliberately corrupted color is detected, which confirms the test can fail.

**Result** (same 1-move scramble; `a0 = 0`, i.e. solved and verified):

| Build | RV32_ISS retired | RV32_5S cycles | `.text` |
|---|---:|---:|---:|
| original (`minirubik_final_asm_led.elf`) | 408,069 | 635,136 | 4,656 B |
| fast renderer, `LED_DELAY=20000` | 308,670 | — | 4,340 B |
| fast renderer, `LED_DELAY=2000` | 38,667 | 58,548 | 4,328 B |
| fast renderer, `LED_DELAY=0` | 8,664 | 10,557 | 4,316 B |

Without delays, the work drops from 108,060 to 8,664 instructions, 12.5× less. At the course's RV32_5S GUI rate, the run goes from ~20 s to under 1 s with `LED_DELAY=0`, or ~2 s with `LED_DELAY=2000`.

## 4. Important side finding: "exit code 0" does not mean success

`start.S` exits with `li a7, 10; ecall`. Ripes always prints `Program exited with code: 0` for ecall 10, regardless of what `main` returned. A test harness returning 7 still prints "exit code 0", and `a0` holds 7.

**`main`'s return value is in `a0`/`x10`.** Read it with `--regs`, or exit with ecall 93 (`a7=93`, code in `a0`).

- The exhaustive script `exhaustive_handwritten_inline.sh` counts failures from the "exited with code" line, so its `failures=0` does not prove that every state returned 11 moves.
- `a0` was re-checked for the report vector, the worst state, the C -O2 baseline and all checkpoints, and all return 0.
- This was subsequently repeated with ecall 93: all 2,644 distance-11 states passed with zero failures; maximum retired instructions were 48,276,943.

## 4b. Rendering bug (fixed): the net did not show real face turns

The original sticker table `led_corner_faces` listed the three faces of
positions 0, 2, 4 and 6 in the wrong cyclic order for the solver's twist
convention. This is the same table in `led_renderer_rv32.S` and in the C
`led_renderer.c`.

As a result, one solver quarter turn changed the wrong stickers:
- **R** changed 12 stickers and scrambled the red face itself.
- **D** changed only 4 stickers.

A real turn keeps the turned face uniform and changes exactly 8 stickers, 2 on each of its 4 neighbours.

How the fix was derived (`derive_sticker_model.py`):
- A 3-D sticker cube was built from the README geometry (R, B, D turns; README position 0 fixed; twist measured on the U/D sticker).
- It reproduces the solver's `src`/`tw` move tables exactly, for single turns and for 300 random turns.
- Rendering from the corrected table matches that physical cube on 200 random scrambles.

Corrected table (`led_face_corner` was already right):
```
led_corner_faces: .byte 0,2,1, 3,1,2, 3,2,4, 0,1,5, 3,5,1, 3,4,5, 0,5,4, 0,4,2
   (was)          .byte 0,1,2, 3,1,2, 3,4,2, 0,1,5, 3,1,5, 3,4,5, 0,4,5, 0,2,4
```

How the fixed renderer was checked:
- `renderer_correctness_test.c` compares the RV32I renderer framebuffer with the physical model's expected framebuffer on 20 states.
- On those 20 states, the fixed renderer gives 0 mismatches. The original renderer has more than 255 mismatching words.
- `expected_frames_5move.png` shows the expected frames for the 5-move demo.

Other changes in this build:
- The harness has an option `QUARTER_FRAMES=1` that draws a half turn or an inverse turn (R2, R') as 2 or 3 quarter-turn frames. Each frame is then exactly one 90° face rotation.
- The `fast_d*.elf` builds have been rebuilt with the fix: 1-move scramble, one frame per solver move.
- New builds:
  - `fixed_1move_d2000.elf` and `fixed_1move_d20000.elf`: quarter-turn frames.
  - `fixed_5move_d2000.elf` and `fixed_5move_d20000.elf`: scramble `p=6,3,4,1,2,0,5 o=1,2,2,2,2,2,1`, solver answer B' R2 D B' R', 12 quarter-turn frames.
  - `fixed_5move_d20000_permove.elf`: one frame per solver move.
- All of them return `a0 = 0`.

## 5. Build

```bash
# GNU build (exports the LED symbols the way Ripes would)
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -c ripes_led_exports_fast.S -o led_fast.o
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -DLED_DELAY=2000 \
    -c led_asm_harness.c -o led_harness.o
# link with start.o + solver objects exactly like the existing LED build, replacing the old renderer object
```

Prebuilt ELFs: `fast_d20000.elf`, `fast_d2000.elf`, `fast_d0.elf`, for the same 1-move scramble as the original ELF. In Ripes:
1. Add an LED Matrix with width 35 and height 25.
2. Load the ELF.
3. Select RV32_ISS.
4. Press **Run (F8)**.
