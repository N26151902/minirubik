#include <stdint.h>
typedef struct { uint8_t p[7], o[7]; } state_t;
int solver_init_rv32(void);
int solver_solve_rv32(const uint8_t p[7], const uint8_t o[7], uint8_t moves[32], int *move_count);
static const uint8_t src[3][7]={{1,4,2,0,3,5,6},{0,1,2,4,5,6,3},{0,2,5,3,1,4,6}};
static const uint8_t tw[3][7]={{1,2,0,2,1,0,0},{0,0,0,1,2,1,2},{0,0,0,0,0,0,0}};
static state_t quarter(state_t s,uint8_t f){state_t r;for(unsigned d=0;d<7;++d){uint8_t q=src[f][d],x=s.o[q]+tw[f][d];if(x>=3)x-=3;r.p[d]=s.p[q];r.o[d]=x;}return r;}
static state_t apply(state_t s,uint8_t m){uint8_t f=(m>=6)?2:(m>=3),n=(uint8_t)(m-f*3+1);while(n--)s=quarter(s,f);return s;}
static int is_solved(const state_t*s){for(unsigned i=0;i<7;++i)if(s->p[i]!=i||s->o[i])return 0;return 1;}
static int test(const uint8_t p[7],const uint8_t o[7],int expected){
 uint8_t moves[32]; int n=-1; state_t s;
 if(!solver_solve_rv32(p,o,moves,&n))return 1;
 if(n!=expected)return 2;
 for(unsigned i=0;i<7;++i){s.p[i]=p[i];s.o[i]=o[i];}
 for(int i=0;i<n;++i){if(moves[i]>=9)return 3;s=apply(s,moves[i]);}
 return is_solved(&s)?0:4;
}
int main(void){
 static const uint8_t p0[7]={0,1,2,3,4,5,6}, o0[7]={0,0,0,0,0,0,0};
 static const uint8_t p1[7]={1,4,2,0,3,5,6}, o1[7]={1,2,0,2,1,0,0};
 static const uint8_t p11[7]={1,0,2,3,4,5,6}, o11[7]={0,0,0,0,0,0,0};
 if(!solver_init_rv32())return 10;
 int r;
 if((r=test(p0,o0,0)))return 20+r;
 if((r=test(p1,o1,1)))return 30+r;
 if((r=test(p11,o11,11)))return 40+r;
 return 0;
}
