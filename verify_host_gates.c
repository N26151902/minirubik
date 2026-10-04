#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>

#include "solver_ida_core_v5.c"

static uint8_t *exact_dist;
static uint32_t *queue_rank;

static int build_exact_bfs(void) {
    exact_dist = malloc(STATES);
    queue_rank = malloc((size_t)STATES * sizeof(*queue_rank));
    if (!exact_dist || !queue_rank) return 0;
    memset(exact_dist, 0xff, STATES);
    uint32_t head = 0, tail = 0;
    exact_dist[0] = 0;
    queue_rank[tail++] = 0;
    while (head < tail) {
        uint32_t r = queue_rank[head++];
        state_t s; unrank_state(r, &s);
        for (uint8_t m = 0; m < MOVES; ++m) {
            state_t t = apply_move(s, m);
            uint32_t nr = rank_state(&t);
            if (exact_dist[nr] == 0xff) {
                exact_dist[nr] = (uint8_t)(exact_dist[r] + 1);
                queue_rank[tail++] = nr;
            }
        }
    }
    return tail == STATES;
}

static int state_heuristic(const state_t *s) {
    uint32_t r = rank_state(s);
    uint8_t p4[4], o4[4], p3a[3], o3a[3], p3b[3], o3b[3];
    pattern_from_state(s, p4, o4);
    pattern3_from_state(s, pattern3a_cubies, p3a, o3a);
    pattern3_from_state(s, pattern3b_cubies, p3b, o3b);
    return heuristic_v5((uint16_t)(r / ORIENTATIONS),
                        (uint16_t)(r % ORIENTATIONS),
                        p4, o4, p3a, o3a, p3b, o3b);
}

static int check_h1(void) {
    unsigned bad = 0; int maxh = 0;
    for (uint32_t r = 0; r < STATES; ++r) {
        state_t s; unrank_state(r, &s);
        int h = state_heuristic(&s);
        if (h > maxh) maxh = h;
        if (h > exact_dist[r]) {
            if (bad < 10) printf("H1 BAD rank=%u h=%d d=%u\n", r,h,exact_dist[r]);
            ++bad;
        }
    }
    printf("H1: states=%u max_h=%d violations=%u => %s\n",
           STATES, maxh, bad, bad ? "FAIL" : "PASS");
    return bad == 0;
}

static int max_table(const uint8_t *a, size_t n) {
    int m = -1;
    for (size_t i=0;i<n;++i) if (a[i] > m) m=a[i];
    return m;
}

static int check_h2(void) {
    state_t solved={{0,1,2,3,4,5,6},{0,0,0,0,0,0,0}};
    uint8_t p4[4],o4[4],p3a[3],o3a[3],p3b[3],o3b[3];
    pattern_from_state(&solved,p4,o4);
    pattern3_from_state(&solved,pattern3a_cubies,p3a,o3a);
    pattern3_from_state(&solved,pattern3b_cubies,p3b,o3b);
    uint32_t i4=pattern4_rank_parts(p4,o4);
    uint32_t i3a=pattern3_rank_parts(p3a,o3a);
    uint32_t i3b=pattern3_rank_parts(p3b,o3b);
    int ok = perm_dist[0]==0 && ori_dist[0]==0;
    ok = ok && pattern_dist[i4]==0;
    ok = ok && pattern3a_dist[i3a]==0 && pattern3b_dist[i3b]==0;
    printf("H2 perm max=%d solved=%u; ori max=%d solved=%u\n",
      max_table(perm_dist,PERMUTATIONS),perm_dist[0],
      max_table(ori_dist,ORIENTATIONS),ori_dist[0]);
    printf("H2 pdb4 max=%d solved=%u; pdb3a max=%d solved=%u; pdb3b max=%d solved=%u => %s\n",
      max_table(pattern_dist,PATTERN_STATES_4),pattern_dist[i4],
      max_table(pattern3a_dist,PATTERN_STATES_3),pattern3a_dist[i3a],
      max_table(pattern3b_dist,PATTERN_STATES_3),pattern3b_dist[i3b],
      ok?"PASS":"FAIL");
    return ok;
}

static int check_h4(void) {
    puts("H4: not applicable: final PDB arrays use one uint8_t per entry; there is no packed accessor.");
    return 1;
}

static int check_h3(void) {
    uint8_t moves[MAX_DEPTH]; int count=0; unsigned bad=0;
    clock_t begin=clock();
    for (uint32_t r=0;r<STATES;++r) {
        state_t s; unrank_state(r,&s);
        if (!solver_solve(s.p,s.o,moves,&count) || count != exact_dist[r]) {
            if (bad < 10) printf("H3 BAD rank=%u got=%d exact=%u\n",r,count,exact_dist[r]);
            ++bad;
        }
        if ((r+1)%100000==0) {
            printf("H3 progress %u/%u bad=%u\n",r+1,STATES,bad);
            fflush(stdout);
        }
    }
    double sec=(double)(clock()-begin)/CLOCKS_PER_SEC;
    printf("H3: states=%u mismatches=%u cpu_seconds=%.3f => %s\n",
           STATES,bad,sec,bad?"FAIL":"PASS");
    return bad==0;
}

int main(void) {
    clock_t begin=clock();
    if (!build_exact_bfs()) { puts("exact BFS build failed"); return 2; }
    printf("Exact BFS built: states=%u seconds=%.3f\n",STATES,
           (double)(clock()-begin)/CLOCKS_PER_SEC);
    int ok=check_h1();
    ok=check_h2() && ok;
    ok=check_h4() && ok;
    ok=check_h3() && ok;
    free(queue_rank); free(exact_dist);
    return ok?0:1;
}
