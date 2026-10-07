/* GUI LED build harness: renders the initial scramble, solves it with the
 * handwritten RV32I solver, redraws after every solver-emitted move, then
 * checks that the final state is solved.  Returns 0 in a0 on success.
 *
 * QUARTER_FRAMES = 1 draws every 90-degree quarter turn as its own frame
 * (a solver move such as R2 or R' becomes 2 or 3 frames); 0 = one frame per
 * solver move.
 * LED_DELAY = busy-wait iterations after each frame (about 5 instructions
 * per iteration).  Tune it to the GUI speed of the processor model:
 *   RV32_ISS (Run/F8): ~20000  -> ~0.1 s per frame
 *   RV32_5S  (Run/F8): 0-500   -> the frame itself already takes ~0.1-1 s
 */
#include <stdint.h>
#ifndef LED_DELAY
#define LED_DELAY 20000u
#endif
#ifndef QUARTER_FRAMES
#define QUARTER_FRAMES 0
#endif
int solver_init_rv32(void);
int solver_solve_rv32(const uint8_t p[7], const uint8_t o[7], uint8_t moves[32], int *count);
void led_render_init(void);
void led_render_state(const uint8_t p[7], const uint8_t o[7]);
void led_render_step(unsigned step, unsigned total);
#ifdef INLINE_INPUT
int load_inline_state_rv32(uint8_t p[7], uint8_t o[7]);
#endif

static void pause_visible(void){ volatile unsigned n = LED_DELAY; while (n--) __asm__ volatile("nop"); }

static const uint8_t src[3][7]={{1,4,2,0,3,5,6},{0,1,2,4,5,6,3},{0,2,5,3,1,4,6}};
static const uint8_t tw[3][7]={{1,2,0,2,1,0,0},{0,0,0,1,2,1,2},{0,0,0,0,0,0,0}};
typedef struct { uint8_t p[7], o[7]; } state_t;
static state_t quarter(state_t s, uint8_t f){ state_t r;
  for (unsigned d=0; d<7; ++d){ uint8_t q=src[f][d]; uint8_t x=s.o[q]+tw[f][d]; if(x>=3)x-=3; r.p[d]=s.p[q]; r.o[d]=x; }
  return r; }
static state_t apply(state_t s, uint8_t m){ uint8_t f=(m>=6)?2:(m>=3); uint8_t n=(uint8_t)(m-f*3+1); while(n--) s=quarter(s,f); return s; }

#ifndef SCRAMBLE_P
#define SCRAMBLE_P 1,4,2,0,3,5,6
#define SCRAMBLE_O 1,2,0,2,1,0,0
#endif
int main(void){
  uint8_t moves[32]; int count=-1; state_t s;
#ifdef INLINE_INPUT
  if (!load_inline_state_rv32(s.p, s.o)) return 9;
#else
  static const uint8_t p0[7]={SCRAMBLE_P}; static const uint8_t o0[7]={SCRAMBLE_O};
  for (unsigned i=0;i<7;++i){ s.p[i]=p0[i]; s.o[i]=o0[i]; }
#endif
  led_render_init();
  led_render_state(s.p, s.o);
  led_render_step(0, 1);
  pause_visible();
  if (!solver_init_rv32()) return 10;
  if (!solver_solve_rv32(s.p, s.o, moves, &count)) return 11;
  if (count < 0 || count > 11) return 12;
#ifdef EXPECT_MOVES
  if (count != EXPECT_MOVES) return 12;
#endif
  for (int i=0;i<count;++i){
    if (moves[i] > 8) return 13;
#if QUARTER_FRAMES
    /* Show a half turn / inverse turn as 2 / 3 separate quarter turns of the
     * same face, so every frame differs from the previous one by exactly one
     * 90-degree face rotation. */
    { uint8_t f=(moves[i]>=6)?2:(moves[i]>=3); uint8_t n=(uint8_t)(moves[i]-f*3+1);
      while (n--) { s = quarter(s, f); led_render_state(s.p, s.o); pause_visible(); } }
#else
    s = apply(s, moves[i]);
    led_render_state(s.p, s.o);
    pause_visible();
#endif
    led_render_step((unsigned)(i+1), (unsigned)count);
  }
  for (unsigned i=0;i<7;++i) if (s.p[i]!=i || s.o[i]!=0) return 14;
  pause_visible();
  return 0;
}
