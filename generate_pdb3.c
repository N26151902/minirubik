#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define STATES3 5670U

static const uint8_t source[3][7] = {
    {1,4,2,0,3,5,6},
    {0,1,2,4,5,6,3},
    {0,2,5,3,1,4,6}
};

static const uint8_t twist[3][7] = {
    {1,2,0,2,1,0,0},
    {0,0,0,1,2,1,2},
    {0,0,0,0,0,0,0}
};

static const uint8_t destination[3][7] = {
    {3,0,2,4,1,5,6},
    {0,1,2,6,3,4,5},
    {0,4,1,3,5,2,6}
};

static uint32_t rank3(const uint8_t pos[3],
                      const uint8_t ori[3])
{
    uint8_t avail[7] = {0,1,2,3,4,5,6};
    uint32_t pr = 0;
    uint32_t orank = 0;
    int n = 7;

    for (int k = 0; k < 3; ++k) {
        int q = 0;

        while (avail[q] != pos[k])
            ++q;

        pr = pr * (uint32_t)n + (uint32_t)q;

        for (int j = q; j + 1 < n; ++j)
            avail[j] = avail[j + 1];

        --n;

        orank = orank * 3U + ori[k];
    }

    return pr * 27U + orank;
}

static void decode3(uint32_t idx,
                    uint8_t pos[3],
                    uint8_t ori[3])
{
    uint32_t orank = idx % 27U;
    uint32_t pr = idx / 27U;

    for (int k = 2; k >= 0; --k) {
        ori[k] = (uint8_t)(orank % 3U);
        orank /= 3U;
    }

    uint8_t digits[3];

    for (int k = 2; k >= 0; --k) {
        uint32_t base = (uint32_t)(7 - k);
        digits[k] = (uint8_t)(pr % base);
        pr /= base;
    }

    uint8_t avail[7] = {0,1,2,3,4,5,6};
    int n = 7;

    for (int k = 0; k < 3; ++k) {
        int q = digits[k];

        pos[k] = avail[q];

        for (int j = q; j + 1 < n; ++j)
            avail[j] = avail[j + 1];

        --n;
    }
}

static void quarter3(uint8_t pos[3],
                     uint8_t ori[3],
                     uint8_t face)
{
    for (int k = 0; k < 3; ++k) {
        uint8_t d = destination[face][pos[k]];

        uint8_t x =
            (uint8_t)(ori[k] + twist[face][d]);

        if (x >= 3)
            x = (uint8_t)(x - 3);

        pos[k] = d;
        ori[k] = x;
    }
}

static int build(uint8_t dist[STATES3],
                 const uint8_t cubies[3])
{
    uint32_t queue[STATES3];

    memset(dist, 0xFF, STATES3);

    /*
     * Find the abstract solved state.
     *
     * In the solved cube:
     * cubie i is at position i and orientation 0.
     */
    uint8_t pos[3] = {
        cubies[0],
        cubies[1],
        cubies[2]
    };

    uint8_t ori[3] = {0,0,0};

    uint32_t start = rank3(pos, ori);

    uint32_t head = 0;
    uint32_t tail = 0;

    dist[start] = 0;
    queue[tail++] = start;

    while (head < tail) {
        uint32_t here = queue[head++];

        decode3(here, pos, ori);

        for (uint8_t face = 0; face < 3; ++face) {
            uint8_t np[3];
            uint8_t no[3];

            memcpy(np, pos, sizeof(np));
            memcpy(no, ori, sizeof(no));

            for (int turn = 0; turn < 3; ++turn) {
                quarter3(np, no, face);

                uint32_t next = rank3(np, no);

                if (dist[next] == 0xFF) {
                    dist[next] =
                        (uint8_t)(dist[here] + 1);

                    queue[tail++] = next;
                }
            }
        }
    }

    return tail == STATES3;
}


static void verify_pdb(const char *name,
                       const uint8_t dist[STATES3])
{
    uint32_t unvisited = 0;
    uint32_t zeros = 0;
    uint8_t max_distance = 0;

    for (uint32_t i = 0; i < STATES3; ++i) {
        if (dist[i] == 0xFF) {
            ++unvisited;
            continue;
        }

        if (dist[i] == 0)
            ++zeros;

        if (dist[i] > max_distance)
            max_distance = dist[i];
    }

    fprintf(stderr,
            "%s: states=%u unvisited=%u zeros=%u max_distance=%u\n",
            name,
            STATES3,
            unvisited,
            zeros,
            max_distance);
}

static void print_array(const char *name,
                        const uint8_t dist[STATES3])
{
    printf(
        "static const uint8_t %s[PATTERN_STATES_3] = {\n",
        name
    );

    for (uint32_t i = 0; i < STATES3; ++i) {
        printf("%u", dist[i]);

        if (i + 1 != STATES3)
            printf(",");

        if ((i + 1) % 24 == 0)
            printf("\n");
        else
            printf(" ");
    }

    printf("\n};\n\n");
}

int main(void)
{
    uint8_t a[STATES3];
    uint8_t b[STATES3];

    const uint8_t cubies_a[3] = {0,1,2};
    const uint8_t cubies_b[3] = {2,5,6};

    if (!build(a, cubies_a)) {
        fprintf(stderr, "failed to build PDB3 012\n");
        return 1;
    }

    if (!build(b, cubies_b)) {
        fprintf(stderr, "failed to build PDB3 256\n");
        return 1;
    }

    verify_pdb("PDB3 012", a);
    verify_pdb("PDB3 256", b);

    printf("#define PATTERN_STATES_3 5670U\n\n");

    print_array("pattern3a_dist", a);
    print_array("pattern3b_dist", b);

    return 0;
}
