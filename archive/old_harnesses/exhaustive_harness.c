#include <stdint.h>
int solver_init(void); int solver_solve(const uint8_t p[7], const uint8_t o[7], uint8_t moves[32], int *move_count);
int main(void){const uint8_t p[7]={6,5,4,3,2,1,0}; const uint8_t o[7]={2,0,0,2,0,2,0}; uint8_t m[32]; int c=-1; if(!solver_init())return 2; if(!solver_solve(p,o,m,&c))return 3; return c==11?0:4;}
