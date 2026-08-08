//
//  pongbridge.c
//  Demo 0: the Static Pong Bridge, from nothing.
//
//  Standalone — no dependence on any existing Aexels code.  The only
//  physics is: emit, fly, capture, respond.  It ends with the static
//  pong bridge as an emergent census measured against exact predicted
//  numbers.  No hyle, no parcels, no mode axes, no motion.  Pure traffic.
//
//  Objects (all of them):
//    Node:  fixed position, radius a.  Emits pings; answers captures
//           with pongs.
//    Ping:  point + unit direction, speed c.  Emitted isotropically at
//           rho0 per tic.
//    Pong:  same kinematics; created only in response to a capture,
//           launched from the capture point, aimed at the emitting
//           node's center.  Dies on arrival.  Never answered.
//    Capture: a ping entering another node's radius is absorbed and
//           triggers exactly one pong.
//
//  Units — the constants table both papers owe starts here:
//    tic          = 1 time unit (the integration step).
//    length unit  = 1 (node radius a and separation L in these units).
//    c            = 1 length per tic.
//    rho0         = pings emitted per tic per emitting node.
//  Design pins, recorded as made:
//    - Emission is stratified: theta_j = 2*pi*(j + u_t)/rho0 with
//      u_t = frac(PHI*t + 0.37*nodeIndex), PHI the golden ratio
//      conjugate.  Low-discrepancy, deterministic, reproducible; no RNG
//      anywhere in the sim.
//    - Collision is exact segment-circle first-entry per tic: no
//      tunneling at any speed/radius combination.
//    - Event times are continuous: a pong born at tic-fraction s
//      advances the remaining (1-s)*c the same tic; capture and arrival
//      times are quadratic-solve exact, not tic-quantized.
//    - Pings are not captured by their own emitter (they are born
//      inside it).  Pongs interact only with their target.
//    - A ping whose ray cannot intersect any other node's disc may be
//      culled at birth (miss-cull).  Physics is unchanged — pings
//      interact with nothing but node discs — but stage 0 and the
//      snapshot run with the full cloud (miss-cull off).
//
//  Build:  cc -O2 -o pongbridge pongbridge.c -lm
//  Run:    ./pongbridge            (all stages, report to stdout)
//          ./pongbridge snapshot   (also writes pongbridge_snapshot.svg)
//

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PHI 0.6180339887498949

typedef struct { double x, y; } V2;


// -------------------------------------------------------------------------
// Nodes

typedef struct {
    V2 pos;
    double a;            // radius
    int emitting;        // streams pings when set
    int answering;       // answers captures with pongs when set
    long emitted;        // lifetime ping count
    long captures;       // pings absorbed here
    long pongArrivals;   // pongs that died here (this node was the target)
} Node;

// -------------------------------------------------------------------------
// Traffic.  Struct-of-arrays pools with end-of-tic compaction.

typedef struct {
    V2 pos, dir;         // dir is unit
    int source;          // node index that emitted it
    int alive;
} Ping;

typedef struct {
    V2 pos, dir;
    int target;          // node index it is aimed at (the ping's emitter)
    double tBorn;        // continuous capture time
    int alive;
} Pong;

typedef struct {
    Node nodes[2];
    int nodeCount;
    double c;
    double cullR;        // pings beyond this distance from origin die
    int missCull;        // cull non-capturing pings at birth
    long tic;            // integer tic counter

    Ping* pings; int pingCount, pingCap;
    Pong* pongs; int pongCount, pongCap;

    // Measurement hooks, reset per window.
    long wCaptures[2];       // captures at node i
    long wArrivals[2];       // pong arrivals at node i (as target)
    double wFlightSum[2];    // summed pong flight times by target
    double wFlightMin[2], wFlightMax[2];
    double lastArrival[2];   // most recent continuous arrival time by target
    double lastCapture[2];   // most recent continuous capture time at node i
    double censusSum[2];     // summed per-tic in-flight pong counts by target
    long censusTicks;
} Sim;

static Sim* simCreate(double c, double cullR) {
    Sim* s = (Sim*)calloc(1, sizeof(Sim));
    s->c = c; s->cullR = cullR;
    s->pingCap = 1024; s->pings = (Ping*)malloc(sizeof(Ping)*s->pingCap);
    s->pongCap = 1024; s->pongs = (Pong*)malloc(sizeof(Pong)*s->pongCap);
    s->wFlightMin[0] = s->wFlightMin[1] = 1e300;
    return s;
}
static void simRelease(Sim* s) { free(s->pings); free(s->pongs); free(s); }

static void simResetWindow(Sim* s) {
    for (int i=0;i<2;i++) {
        s->wCaptures[i]=0; s->wArrivals[i]=0; s->wFlightSum[i]=0;
        s->wFlightMin[i]=1e300; s->wFlightMax[i]=0; s->censusSum[i]=0;
    }
    s->censusTicks = 0;
}

static Ping* simAddPing(Sim* s) {
    if (s->pingCount == s->pingCap) { s->pingCap *= 2; s->pings = (Ping*)realloc(s->pings, sizeof(Ping)*s->pingCap); }
    return &s->pings[s->pingCount++];
}
static Pong* simAddPong(Sim* s) {
    if (s->pongCount == s->pongCap) { s->pongCap *= 2; s->pongs = (Pong*)realloc(s->pongs, sizeof(Pong)*s->pongCap); }
    return &s->pongs[s->pongCount++];
}

// First entry of the segment p -> p + d*s0 (d unit) into the circle
// (C, r).  Returns the entry distance in [0, s0], or -1 for no entry.
// A start already inside the circle returns -1 (entry only).
static double segCircleEntry(V2 p, V2 d, double s0, V2 C, double r) {
    double qx = p.x - C.x, qy = p.y - C.y;
    double c0 = qx*qx + qy*qy - r*r;
    if (c0 <= 0) return -1;                       // already inside
    double b = qx*d.x + qy*d.y;                   // half of the linear term
    if (b >= 0) return -1;                        // moving away
    double disc = b*b - c0;
    if (disc < 0) return -1;                      // ray misses
    double sEnter = -b - sqrt(disc);
    return (sEnter <= s0) ? sEnter : -1;
}

// Does an infinite ray from p along d hit the circle (C, r)?
static int rayHitsCircle(V2 p, V2 d, V2 C, double r) {
    double qx = p.x - C.x, qy = p.y - C.y;
    double c0 = qx*qx + qy*qy - r*r;
    if (c0 <= 0) return 1;
    double b = qx*d.x + qy*d.y;
    if (b >= 0) return 0;
    return b*b - c0 >= 0;
}

// A capture: absorb the ping, answer with a pong (if the capturing node
// answers).  This function is Demo 1's extension point — the m-hat sign
// classification hangs off the same event.
static void simCapture(Sim* s, int nodeIndex, Ping* ping, V2 point, double tCapture, double remaining) {
    Node* node = &s->nodes[nodeIndex];
    node->captures++;
    s->wCaptures[nodeIndex]++;
    s->lastCapture[nodeIndex] = tCapture;
    ping->alive = 0;

    if (!node->answering) return;

    Node* source = &s->nodes[ping->source];
    double dx = source->pos.x - point.x, dy = source->pos.y - point.y;
    double len = sqrt(dx*dx + dy*dy);
    if (len < 1e-12) return;

    Pong* pong = simAddPong(s);
    pong->pos = point;
    pong->dir.x = dx/len; pong->dir.y = dy/len;
    pong->target = ping->source;
    pong->tBorn = tCapture;
    pong->alive = 1;

    // Advance the remaining fraction of this tic immediately, checking
    // for same-tic arrival, so event times stay continuous.
    if (remaining > 0) {
        double sEnter = segCircleEntry(pong->pos, pong->dir, remaining, source->pos, source->a);
        if (sEnter >= 0) {
            double tArrive = tCapture + sEnter / s->c;
            double flight = tArrive - pong->tBorn;
            s->nodes[pong->target].pongArrivals++;
            s->wArrivals[pong->target]++;
            s->wFlightSum[pong->target] += flight;
            if (flight < s->wFlightMin[pong->target]) s->wFlightMin[pong->target] = flight;
            if (flight > s->wFlightMax[pong->target]) s->wFlightMax[pong->target] = flight;
            s->lastArrival[pong->target] = tArrive;
            pong->alive = 0;
        } else {
            pong->pos.x += pong->dir.x * remaining;
            pong->pos.y += pong->dir.y * remaining;
        }
    }
}

static void simTic(Sim* s) {
    double step = s->c;   // distance per tic

    // 1. Emission at the tic boundary.
    for (int n=0;n<s->nodeCount;n++) {
        Node* node = &s->nodes[n];
        if (!node->emitting) continue;
        // Stratified isotropic volley (see design pins).
        extern int gRho0;
        double u = fmod(PHI * (double)s->tic + 0.37 * n, 1.0);
        for (int j=0;j<gRho0;j++) {
            double theta = 2.0*M_PI*((double)j + u)/(double)gRho0;
            V2 dir = { cos(theta), sin(theta) };
            if (s->missCull) {
                int hits = 0;
                for (int m=0;m<s->nodeCount && !hits;m++)
                    if (m != n) hits = rayHitsCircle(node->pos, dir, s->nodes[m].pos, s->nodes[m].a);
                if (!hits) { node->emitted++; continue; }   // counted, culled
            }
            Ping* ping = simAddPing(s);
            ping->pos = node->pos;
            ping->dir = dir;
            ping->source = n;
            ping->alive = 1;
            node->emitted++;
        }
    }

    // 2. Fly the pings; captures spawn pongs (which finish the tic
    //    themselves inside simCapture).
    int pongPre = s->pongCount;   // pongs that existed before this tic's captures
    for (int i=0;i<s->pingCount;i++) {
        Ping* ping = &s->pings[i];
        if (!ping->alive) continue;
        int hitNode = -1; double hitS = 1e300;
        for (int n=0;n<s->nodeCount;n++) {
            if (n == ping->source) continue;
            double sEnter = segCircleEntry(ping->pos, ping->dir, step, s->nodes[n].pos, s->nodes[n].a);
            if (sEnter >= 0 && sEnter < hitS) { hitS = sEnter; hitNode = n; }
        }
        if (hitNode >= 0) {
            V2 point = { ping->pos.x + ping->dir.x*hitS, ping->pos.y + ping->dir.y*hitS };
            double tCapture = (double)s->tic + hitS / s->c;
            simCapture(s, hitNode, ping, point, tCapture, step - hitS);
        } else {
            ping->pos.x += ping->dir.x * step;
            ping->pos.y += ping->dir.y * step;
            double dx = ping->pos.x, dy = ping->pos.y;
            if (dx*dx + dy*dy > s->cullR*s->cullR) ping->alive = 0;
        }
    }

    // 3. Fly the pre-existing pongs.
    for (int i=0;i<pongPre;i++) {
        Pong* pong = &s->pongs[i];
        if (!pong->alive) continue;
        Node* target = &s->nodes[pong->target];
        double sEnter = segCircleEntry(pong->pos, pong->dir, step, target->pos, target->a);
        if (sEnter >= 0) {
            double tArrive = (double)s->tic + sEnter / s->c;
            double flight = tArrive - pong->tBorn;
            target->pongArrivals++;
            s->wArrivals[pong->target]++;
            s->wFlightSum[pong->target] += flight;
            if (flight < s->wFlightMin[pong->target]) s->wFlightMin[pong->target] = flight;
            if (flight > s->wFlightMax[pong->target]) s->wFlightMax[pong->target] = flight;
            s->lastArrival[pong->target] = tArrive;
            pong->alive = 0;
        } else {
            pong->pos.x += pong->dir.x * step;
            pong->pos.y += pong->dir.y * step;
        }
    }

    // 4. Compact the pools; sample the census at the tic boundary.
    int k = 0;
    for (int i=0;i<s->pingCount;i++) if (s->pings[i].alive) s->pings[k++] = s->pings[i];
    s->pingCount = k;
    k = 0;
    long census[2] = {0,0};
    for (int i=0;i<s->pongCount;i++) if (s->pongs[i].alive) { census[s->pongs[i].target]++; s->pongs[k++] = s->pongs[i]; }
    s->pongCount = k;
    s->censusSum[0] += (double)census[0];
    s->censusSum[1] += (double)census[1];
    s->censusTicks++;

    s->tic++;
}

// -------------------------------------------------------------------------
// Exact geometric references (the analytic side of the comparison).
// Emission is uniform in theta from the node CENTER, so every reference
// is a one-dimensional quadrature over the capture arc.

typedef struct {
    double captureFrac;      // asin(a/L)/pi — exact fraction of pings captured
    double captureFracApprox;// a/(pi*L)     — the brief's leading-order form
    double meanFlight;       // mean pong flight time (capture point -> target radius)
    double censusExact;      // rho0 * captureFrac * meanFlight — per direction
    double censusBrief;      // rho0 * a / (pi*c) — the brief's L-independent census
    double drainExact;       // (2*sqrt(L^2-a^2) - a)/c — last pong arrival after cutoff
} Ref;

// Entry distance from the emitter center to the capture point, for a ray
// at angle theta off the line of centers.
static double entryDist(double L, double a, double theta) {
    double st = L*sin(theta);
    return L*cos(theta) - sqrt(a*a - st*st);
}

static Ref refCompute(double L, double a, double c, int rho0) {
    Ref r;
    double thMax = asin(a/L);
    r.captureFrac = thMax / M_PI;
    r.captureFracApprox = a / (M_PI * L);
    const int N = 200000;
    double sum = 0;
    for (int i=0;i<N;i++) {
        double theta = thMax * ((double)i + 0.5) / (double)N;   // symmetric: use half arc
        sum += entryDist(L, a, theta) - a;                       // flight: entry point -> target circle
    }
    r.meanFlight = (sum / (double)N) / c;
    r.censusExact = (double)rho0 * r.captureFrac * r.meanFlight;
    r.censusBrief = (double)rho0 * a / (M_PI * c);
    r.drainExact = (2.0*sqrt(L*L - a*a) - a) / c;
    return r;
}

// -------------------------------------------------------------------------
// Stages

int gRho0 = 360;   // pings per tic per emitting node (global so simTic sees it)

static void banner(const char* title) {
    printf("\n=========================================================================\n");
    printf("%s\n", title);
    printf("=========================================================================\n");
}

static double relErr(double measured, double predicted) {
    return predicted == 0 ? 0 : (measured - predicted) / predicted;
}

// Stage 0 — one node breathing.  Full cloud, no miss-cull.
static void stage0(void) {
    banner("STAGE 0 — one node breathing (plumbing)");
    gRho0 = 360;
    int T = 250;
    Sim* s = simCreate(1.0, 1e9);   // no cull: keep every ping
    s->nodeCount = 1;
    s->nodes[0] = (Node){ .pos = {0,0}, .a = 10, .emitting = 1, .answering = 1 };
    for (int t=0;t<T;t++) simTic(s);

    long expectedEmitted = (long)gRho0 * T;
    printf("emission count:   %ld   expected rho0*t = %ld   %s\n",
        s->nodes[0].emitted, expectedEmitted,
        s->nodes[0].emitted == expectedEmitted ? "EXACT" : "** MISMATCH **");

    // 1/r density: annulus [r, r+1) should hold exactly rho0 pings (one
    // volley ring per annulus), so count/(2*pi*r) falls as 1/r.
    int rMin = 20, rMax = T - 10;
    long worst = 0; int worstR = 0;
    long* bins = (long*)calloc(rMax+2, sizeof(long));
    for (int i=0;i<s->pingCount;i++) {
        double r = sqrt(s->pings[i].pos.x*s->pings[i].pos.x + s->pings[i].pos.y*s->pings[i].pos.y);
        int b = (int)floor(r + 0.5);   // volley rings sit at integer radii; bin centers there
        if (b >= 0 && b <= rMax+1) bins[b]++;
    }
    for (int r=rMin;r<rMax;r++) {
        long dev = labs(bins[r] - gRho0);
        if (dev > worst) { worst = dev; worstR = r; }
    }
    printf("annulus census:   [r,r+1) holds rho0=%d pings per annulus, r in [%d,%d)\n", gRho0, rMin, rMax);
    printf("                  worst deviation: %ld pings (at r=%d)  =>  density ~ 1/r %s\n",
        worst, worstR, worst == 0 ? "EXACT" : worst <= 1 ? "(within 1: boundary rounding)" : "** BROKEN **");
    free(bins);
    simRelease(s);
}

// Shared driver for stages 1-3: two nodes at separation L.
static Sim* bridgeSim(double L, double a, int emitA, int emitB, int answerA, int answerB) {
    Sim* s = simCreate(1.0, L + 4*a + 50);
    s->missCull = 1;
    s->nodeCount = 2;
    s->nodes[0] = (Node){ .pos = {-L/2, 0}, .a = a, .emitting = emitA, .answering = answerA };
    s->nodes[1] = (Node){ .pos = { L/2, 0}, .a = a, .emitting = emitB, .answering = answerB };
    return s;
}

// Stage 1 — one-way traffic: A emits, B silently captures.
static void stage1(void) {
    banner("STAGE 1 — one-way traffic (capture rate)");
    struct { double L, a; } cfg[] = { {400, 10}, {200, 50} };
    for (int i=0;i<2;i++) {
        double L = cfg[i].L, a = cfg[i].a;
        gRho0 = 360;
        Ref ref = refCompute(L, a, 1.0, gRho0);
        Sim* s = bridgeSim(L, a, 1, 0, 0, 0);
        long warm = (long)(L + 4*a) + 50;
        for (long t=0;t<warm;t++) simTic(s);
        simResetWindow(s);
        long W = 4000;
        for (long t=0;t<W;t++) simTic(s);
        double rate = (double)s->wCaptures[1] / (double)W;
        double exact  = gRho0 * ref.captureFrac;
        double approx = gRho0 * ref.captureFracApprox;
        printf("L=%4.0f a=%.0f rho0=%d:\n", L, a, gRho0);
        printf("  capture rate     %.6f /tic\n", rate);
        printf("  exact  rho0*asin(a/L)/pi  = %.6f   residual %+.3e\n", exact, relErr(rate, exact));
        printf("  brief  rho0*a/(pi*L)      = %.6f   residual %+.3e   (a/L=%.3f: leading-order gap)\n",
            approx, relErr(rate, approx), a/L);
        simRelease(s);
    }
}

// Stage 2 — the answer: B answers with pongs.
static void stage2(void) {
    banner("STAGE 2 — the answer (pong return)");
    double L = 400, a = 10;
    gRho0 = 360;
    Ref ref = refCompute(L, a, 1.0, gRho0);
    Sim* s = bridgeSim(L, a, 1, 0, 0, 1);   // A emits; B answers
    long warm = 2*(long)L + 100;
    for (long t=0;t<warm;t++) simTic(s);
    simResetWindow(s);
    long W = 4000;
    for (long t=0;t<W;t++) simTic(s);
    double captureRate = (double)s->wCaptures[1] / (double)W;
    double arrivalRate = (double)s->wArrivals[0] / (double)W;
    double meanFlight  = s->wFlightSum[0] / (double)s->wArrivals[0];
    printf("L=%.0f a=%.0f rho0=%d:\n", L, a, gRho0);
    printf("  capture rate at B      %.6f /tic\n", captureRate);
    printf("  pong arrivals at A     %.6f /tic    (steady state: equal)   residual %+.3e\n",
        arrivalRate, relErr(arrivalRate, captureRate));
    printf("  flight time  mean %.4f   min %.4f   max %.4f  (tics)\n",
        meanFlight, s->wFlightMin[0], s->wFlightMax[0]);
    printf("  exact mean (quadrature)  %.4f    residual %+.3e\n", ref.meanFlight, relErr(meanFlight, ref.meanFlight));
    printf("  brief: L/c = %.1f with spread ~a/c;  measured spread %.4f  (finite-a offset: pong dies at radius a)\n",
        L, s->wFlightMax[0] - s->wFlightMin[0]);
    simRelease(s);
}

// Stage 3 — the bridge: both emitting, both answering.
static void stage3(void) {
    banner("STAGE 3 — the bridge (census, refresh)");
    gRho0 = 360;

    // 3.1 The census, with the L sweep.
    printf("census per direction (in-flight pongs), rho0=%d, a=10:\n", gRho0);
    printf("  %6s  %12s  %12s  %12s  %12s  %10s\n", "L", "measured", "exact-quad", "resid", "brief-N", "vs-brief");
    double Ls[] = { 200, 400, 800, 1600 };
    for (int i=0;i<4;i++) {
        double L = Ls[i], a = 10;
        Ref ref = refCompute(L, a, 1.0, gRho0);
        Sim* s = bridgeSim(L, a, 1, 1, 1, 1);
        long warm = 2*(long)L + 200;
        for (long t=0;t<warm;t++) simTic(s);
        simResetWindow(s);
        long W = 2000;
        for (long t=0;t<W;t++) simTic(s);
        double census = 0.5*(s->censusSum[0] + s->censusSum[1]) / (double)s->censusTicks;
        printf("  %6.0f  %12.3f  %12.3f  %+12.3e  %12.3f  %+9.4f%%\n",
            L, census, ref.censusExact, relErr(census, ref.censusExact),
            ref.censusBrief, 100.0*relErr(census, ref.censusBrief));
        simRelease(s);
    }
    printf("  (brief-N = rho0*a/(pi*c) = L-independent point-node limit; the vs-brief\n");
    printf("   column is the finite-a residual ~ -(1+pi/4)*a/L, vanishing as L grows.)\n");

    // 3.2 The rho0 sweep at fixed L: census scales linearly.
    printf("\ncensus / rho0 at L=400, a=10 (linearity in rho0):\n");
    int rhos[] = { 90, 180, 360, 720 };
    for (int i=0;i<4;i++) {
        gRho0 = rhos[i];
        double L = 400, a = 10;
        Ref ref = refCompute(L, a, 1.0, gRho0);
        Sim* s = bridgeSim(L, a, 1, 1, 1, 1);
        long warm = 2*(long)L + 200;
        for (long t=0;t<warm;t++) simTic(s);
        simResetWindow(s);
        long W = 2000;
        for (long t=0;t<W;t++) simTic(s);
        double census = 0.5*(s->censusSum[0] + s->censusSum[1]) / (double)s->censusTicks;
        printf("  rho0=%4d:  census %10.3f   census/rho0 %.6f   exact %.6f   residual %+.3e\n",
            rhos[i], census, census/rhos[i], ref.censusExact/rhos[i], relErr(census/rhos[i], ref.censusExact/rhos[i]));
        simRelease(s);
    }
    gRho0 = 360;

    // 3.3 The refresh: kill A's emission, stopwatch the drain of the
    // B->A pong stream.  The exact drain (2*sqrt(L^2-a^2)-a)/c belongs
    // to the continuum emitter (it includes the tangent ray); a
    // discretized volley undershoots it by the edge-of-arc sampling
    // gap, which closes under rho0 refinement — so the stopwatch is
    // reported as a refinement ladder.
    printf("\nrefresh (kill A's emission after its last volley at t_last; drain the B->A stream):\n");
    double L = 400, a = 10;
    Ref ref = refCompute(L, a, 1.0, gRho0);
    printf("  exact (continuum): last capture t_last + %.4f; last pong lands t_last + %.4f; brief 2L/c = %.1f\n",
        sqrt(L*L - a*a), ref.drainExact, 2*L);
    printf("  (the shortfall below is the edge-of-arc sampling gap of the FINAL volley —\n");
    printf("   it depends on that volley's angular offset, so each rho0 is averaged over\n");
    printf("   %d cutoff phases; expected scaling: mean shortfall ~ rho0^-1/2)\n", 16);
    printf("  %8s  %16s  %16s  %10s  %8s\n", "rho0", "mean-shortfall", "max-shortfall", "ratio", "empty?");
    int drainRhos[] = { 360, 1440, 5760, 23040 };
    const int K = 16;
    double prevMean = 0;
    for (int i=0;i<4;i++) {
        gRho0 = drainRhos[i];
        double sum = 0, worst = 0;
        int allEmpty = 1;
        for (int k=0;k<K;k++) {
            Sim* s = bridgeSim(L, a, 1, 1, 1, 1);
            long warm = 2*(long)L + 50 + k;       // vary the cutoff phase
            for (long t=0;t<warm;t++) simTic(s);
            double tLast = (double)s->tic - 1;    // tic of A's final volley
            s->nodes[0].emitting = 0;             // A goes dark
            for (long t=0;t<(long)(2.2*L);t++) simTic(s);
            for (int j=0;j<s->pongCount;j++) if (s->pongs[j].target == 0) allEmpty = 0;
            double shortfall = ref.drainExact - (s->lastArrival[0] - tLast);
            sum += shortfall;
            if (shortfall > worst) worst = shortfall;
            simRelease(s);
        }
        double mean = sum / K;
        printf("  %8d  %16.4f  %16.4f", gRho0, mean, worst);
        if (i > 0) printf("  %9.2fx", prevMean/mean); else printf("  %10s", "-");
        printf("  %8s\n", allEmpty ? "YES" : "** NO **");
        prevMean = mean;
    }
    gRho0 = 360;
    printf("  (drain converges to the continuum stopwatch from below; asymptotic order\n");
    printf("   1/2 in rho0 (4x => 2x), with finite-sample scatter in the step ratios.\n");
    printf("   The bridge always empties completely: it outlives its source by two\n");
    printf("   transits, never more.)\n");
}

// The cones — a steady-state snapshot rendered to SVG.  Full cloud so
// the ping traffic shows too.
static void snapshot(void) {
    banner("SNAPSHOT — the cones (pongbridge_snapshot.svg)");
    gRho0 = 720;
    double L = 150, a = 12;
    Sim* s = simCreate(1.0, L + 4*a + 40);
    s->missCull = 0;    // full cloud for the picture
    s->nodeCount = 2;
    s->nodes[0] = (Node){ .pos = {-L/2, 0}, .a = a, .emitting = 1, .answering = 1 };
    s->nodes[1] = (Node){ .pos = { L/2, 0}, .a = a, .emitting = 1, .answering = 1 };
    long T = 3*(long)L;
    for (long t=0;t<T;t++) simTic(s);

    FILE* f = fopen("pongbridge_snapshot.svg", "w");
    if (!f) { printf("  could not open pongbridge_snapshot.svg\n"); simRelease(s); return; }
    double W = 900, H = 560, scale = 2.2;
    double cx = W/2, cy = H/2;
    fprintf(f, "<svg xmlns='http://www.w3.org/2000/svg' width='%.0f' height='%.0f' viewBox='0 0 %.0f %.0f'>\n", W, H, W, H);
    fprintf(f, "<rect width='%.0f' height='%.0f' fill='#0b0e14'/>\n", W, H);
    fprintf(f, "<text x='%.0f' y='30' fill='#8899aa' font-family='monospace' font-size='14' text-anchor='middle'>"
               "Demo 0 - the static pong bridge   (L=%.0f, a=%.0f, rho0=%d, t=%ld)</text>\n", cx, L, a, gRho0, T);
    // Ping cloud, faint (subsampled: the picture needs texture, not 300k circles).
    int stride = s->pingCount / 12000 + 1;
    for (int i=0;i<s->pingCount;i+=stride) {
        double x = cx + s->pings[i].pos.x*scale, y = cy + s->pings[i].pos.y*scale;
        if (x < 0 || x > W || y < 0 || y > H) continue;
        fprintf(f, "<circle cx='%.1f' cy='%.1f' r='0.7' fill='#334455' fill-opacity='0.5'/>\n", x, y);
    }
    // Pong streams: target A = warm, target B = cool.
    for (int i=0;i<s->pongCount;i++) {
        double x = cx + s->pongs[i].pos.x*scale, y = cy + s->pongs[i].pos.y*scale;
        const char* color = s->pongs[i].target == 0 ? "#ffb347" : "#5fd3f3";
        fprintf(f, "<circle cx='%.1f' cy='%.1f' r='1.6' fill='%s' fill-opacity='0.85'/>\n", x, y, color);
    }
    // Nodes.
    for (int n=0;n<2;n++) {
        fprintf(f, "<circle cx='%.1f' cy='%.1f' r='%.1f' fill='none' stroke='#ffffff' stroke-width='1.5'/>\n",
            cx + s->nodes[n].pos.x*scale, cy + s->nodes[n].pos.y*scale, s->nodes[n].a*scale);
        fprintf(f, "<text x='%.1f' y='%.1f' fill='#ffffff' font-family='monospace' font-size='16' text-anchor='middle'>%c</text>\n",
            cx + s->nodes[n].pos.x*scale, cy + s->nodes[n].pos.y*scale - s->nodes[n].a*scale - 8, n == 0 ? 'A' : 'B');
    }
    fprintf(f, "<text x='%.0f' y='%.0f' fill='#ffb347' font-family='monospace' font-size='12'>pongs -&gt; A</text>\n", 30.0, H-40);
    fprintf(f, "<text x='%.0f' y='%.0f' fill='#5fd3f3' font-family='monospace' font-size='12'>pongs -&gt; B</text>\n", 30.0, H-22);
    fprintf(f, "</svg>\n");
    fclose(f);
    long toA=0, toB=0;
    for (int i=0;i<s->pongCount;i++) { if (s->pongs[i].target==0) toA++; else toB++; }
    printf("  wrote pongbridge_snapshot.svg  (pings %d, pongs->A %ld, pongs->B %ld)\n", s->pingCount, toA, toB);
    simRelease(s);
}

int main(int argc, char** argv) {
    printf("Demo 0 — the Static Pong Bridge, from nothing.\n");
    printf("Units: tic=1, c=1 length/tic, deterministic stratified emission (no RNG).\n");
    stage0();
    stage1();
    stage2();
    stage3();
    if (argc > 1 && strcmp(argv[1], "snapshot") == 0) snapshot();
    printf("\ndone.\n");
    return 0;
}
