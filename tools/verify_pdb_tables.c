/*
 * Independent check of the linked pattern databases.
 *
 * For each PDB (4-cubie {0,3,5,6}, 3-cubie {0,1,2}, 3-cubie {2,5,6}):
 *   1. enumerate every abstract state directly (all ordered placements of
 *      the tracked cubies x all orientations) and check that the rank
 *      function used by the solver maps them one-to-one onto 0..N-1;
 *   2. run a fresh BFS from the solved pattern with the solver's own
 *      quarter-turn function, using a visited flag per state;
 *   3. require that the BFS reaches all N states and that its distance
 *      equals the linked table entry for every state.
 *
 * Build: cc -O2 -Ireference -o verify_pdb tools/verify_pdb_tables.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "solver_ida_core_v5.c"

typedef uint32_t (*rank_fn)(const uint8_t *, const uint8_t *);
typedef void (*quarter_fn)(uint8_t *, uint8_t *, uint8_t);

static uint32_t rank4(const uint8_t *p, const uint8_t *o) { return pattern4_rank_parts(p, o); }
static uint32_t rank3(const uint8_t *p, const uint8_t *o) { return pattern3_rank_parts(p, o); }
static void quarter4(uint8_t *p, uint8_t *o, uint8_t f) { pattern_quarter(p, o, f); }
static void quarter3(uint8_t *p, uint8_t *o, uint8_t f) { pattern3_quarter(p, o, f); }

/* Enumerate all states of a k-cubie pattern; store each one by its rank. */
static int enumerate(int k, uint32_t n, rank_fn rank, uint8_t *pos_of, uint8_t *ori_of)
{
    uint8_t *hit = calloc(n, 1);
    uint32_t count = 0, orients = 1;
    for (int i = 0; i < k; ++i) orients *= 3;
    uint8_t pos[4], ori[4];
    for (uint32_t a = 0; a < 7 * 7 * 7 * 7; ++a) {
        uint32_t t = a;
        for (int i = 0; i < 4; ++i) { pos[i] = (uint8_t)(t % 7); t /= 7; }
        if (k == 3 && pos[3] != 0) continue;           /* use 3 digits only */
        int distinct = 1;
        for (int i = 0; i < k; ++i)
            for (int j = 0; j < i; ++j)
                if (pos[i] == pos[j]) distinct = 0;
        if (!distinct) continue;
        for (uint32_t b = 0; b < orients; ++b) {
            uint32_t u = b;
            for (int i = 0; i < k; ++i) { ori[i] = (uint8_t)(u % 3); u /= 3; }
            uint32_t r = rank(pos, ori);
            if (r >= n || hit[r]) { free(hit); return 0; } /* out of range or collision */
            hit[r] = 1; ++count;
            memcpy(pos_of + 4 * r, pos, 4);
            memcpy(ori_of + 4 * r, ori, 4);
        }
    }
    free(hit);
    return count == n;
}

static int check(const char *name, int k, uint32_t n, const uint8_t cubies[],
                 const uint8_t table[], rank_fn rank, quarter_fn quarter)
{
    uint8_t *pos_of = malloc(4 * n), *ori_of = malloc(4 * n), *dist = malloc(n);
    uint32_t *queue = malloc(4 * n);
    int bijective = enumerate(k, n, rank, pos_of, ori_of);

    memset(dist, 0xff, n);
    uint8_t pos[4] = {0}, ori[4] = {0};
    for (int i = 0; i < k; ++i) pos[i] = cubies[i];      /* solved: cubie i at i */
    uint32_t head = 0, tail = 0, start = rank(pos, ori);
    dist[start] = 0;
    queue[tail++] = start;
    while (head < tail) {
        uint32_t here = queue[head++];
        for (uint8_t face = 0; face < 3; ++face) {
            uint8_t p[4], o[4];
            memcpy(p, pos_of + 4 * here, 4);
            memcpy(o, ori_of + 4 * here, 4);
            for (int turn = 0; turn < 3; ++turn) {        /* X, X2, X' */
                quarter(p, o, face);
                uint32_t next = rank(p, o);
                if (dist[next] == 0xff) {
                    dist[next] = (uint8_t)(dist[here] + 1);
                    queue[tail++] = next;
                }
            }
        }
    }
    uint32_t mismatches = 0, maxd = 0;
    for (uint32_t i = 0; i < n; ++i) {
        if (dist[i] != table[i]) ++mismatches;
        if (dist[i] != 0xff && dist[i] > maxd) maxd = dist[i];
    }
    int ok = bijective && tail == n && mismatches == 0;
    printf("%s: states=%u rank_bijective=%s reached=%u unreached=%u max=%u "
           "table_mismatches=%u => %s\n",
           name, n, bijective ? "yes" : "NO", tail, n - tail, maxd, mismatches,
           ok ? "PASS" : "FAIL");
    free(pos_of); free(ori_of); free(dist); free(queue);
    return ok;
}

int main(void)
{
    int ok = 1;
    ok &= check("PDB4 {0,3,5,6}", 4, PATTERN_STATES_4, pattern_cubies, pattern_dist, rank4, quarter4);
    ok &= check("PDB3 {0,1,2}  ", 3, PATTERN_STATES_3, pattern3a_cubies, pattern3a_dist, rank3, quarter3);
    ok &= check("PDB3 {2,5,6}  ", 3, PATTERN_STATES_3, pattern3b_cubies, pattern3b_dist, rank3, quarter3);
    return ok ? 0 : 1;
}
