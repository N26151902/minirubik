#include <stdint.h>
#define CUBIES 7
#define MAX_DEPTH 32
int solver_init(void);
int solver_solve(const uint8_t p[7], const uint8_t o[7], uint8_t moves[32], int *move_count);
typedef struct { uint8_t p[7], o[7]; } state_t;
static const uint8_t source[3][7]={{1,4,2,0,3,5,6},{0,1,2,4,5,6,3},{0,2,5,3,1,4,6}};
static const uint8_t twist[3][7]={{1,2,0,2,1,0,0},{0,0,0,1,2,1,2},{0,0,0,0,0,0,0}};
static state_t turn(state_t s,uint8_t f){
 state_t r;
 for(int d=0;d<7;++d){uint8_t q=source[f][d];r.p[d]=s.p[q];uint8_t x=s.o[q]+twist[f][d];if(x>=3)x-=3;r.o[d]=x;}
 return r;
}
static state_t move(state_t s,uint8_t m){uint8_t f=(m>=6)?2:(m>=3);uint8_t n=(uint8_t)(m-f*3+1);while(n--)s=turn(s,f);return s;}
static int solved(const state_t*s){for(int i=0;i<7;++i)if(s->p[i]!=i||s->o[i])return 0;return 1;}
static int test(const uint8_t p[7],const uint8_t o[7],int want){
 uint8_t ms[32];int n=-1;state_t s;
 if(!solver_solve(p,o,ms,&n)||n!=want)return 0;
 for(int i=0;i<7;++i){s.p[i]=p[i];s.o[i]=o[i];}
 for(int i=0;i<n;++i){if(ms[i]>=9)return 0;s=move(s,ms[i]);}
 return solved(&s);
}
int main(void){
 static const uint8_t ps[3][7]={{0,1,2,3,4,5,6},{1,4,2,0,3,5,6},{1,0,2,3,4,5,6}};
 static const uint8_t os[3][7]={{0,0,0,0,0,0,0},{1,2,0,2,1,0,0},{0,0,0,0,0,0,0}};
 static const int want[3]={0,1,11};
 if(!solver_init())return 10;
 for(int i=0;i<3;++i)if(!test(ps[i],os[i],want[i]))return 20+i;
 return 0;
}
