#include <stdint.h>
#include "expect.h"
void led_render_init(void); void led_render_state(const uint8_t*,const uint8_t*);
int main(void){ volatile uint32_t *fb=(volatile uint32_t*)0xf0000000u; int bad=0;
 for(int k=0;k<NS;k++){ for(int i=0;i<875;i++) fb[i]=0x12345678; led_render_init(); led_render_state(P[k],O[k]);
  for(int i=0;i<875;i++) if(fb[i]!=FB[k][i]) bad++; }
 return bad>255?255:bad; }
