// encounter.c — rung 0: the symmetric head-on encounter, run on the
// Hyle Lab's engine (Philippine) with the rules' own dynamics.
//
// Oracle: Physics/Mechanism/rung0-encounter-oracle.py (F-Ph desk).
// Two identical outies (eta0 = 1, c = 1) approach head-on at +/- v0
// from separation r0.  Force on each node normalized to F = 1/r (the 2D
// log potential) — impulse quota q = pi / (N a) so that the isotropic
// capture rate N a / (pi r) per tic times q|C| gives 1/r at rest.
// Closed form (instantaneous census): the turning point is
//     r_min = r0 * exp(-v0^2)
// and the encounter is elastic (exit speed = v0).
//
// The lab runs the rules as stated instead of the instantaneous census:
// Rule-3 engineered emission (2D form), per-ping cupolas, Rule-1
// impulses q|C| locked at capture and delivered when the pong returns
// to the source, Rule 5's direction clause, the moving disc meeting
// pings at its own rate.  Retardation is real here — a round trip
// 2r/c is 10% of the encounter at v0 = 0.15 — and aberration is what
// must hide it.  The oracle's naive-retarded run (impulse from the
// emission-time r, delivered a round trip late, no aberration) misses
// by 50x in energy at v0 = 0.15 and collides at 0.3.
//
// Start: the pair runs a lookback at uniform motion with dynamics off
// (the steady field of uniform motion — ItL's equilibrium object), and
// the dynamics switch on the tic the separation crosses r0.  That is
// the closed form's initial condition: the full force present at r0.
//
// Build: make        Run: ./encounter [v0 ...]
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "Philippine.h"

typedef struct {
    double rmin;        // turning point
    double vexit;       // |v| when the separation has recovered to r0 (0 if not reached)
    double rExit;
    long ticsTurn;
    long ticsTotal;
    long captures;
    long impulses;
    double fRelease;    // delivered force on A over the first 40 tics after release, in units of 1/r0
    double fUniform;    // <F_A r> over the last 400 held tics: the rules' uniform-approach force law (1 = closed form)
    int collided;
} Result;

static Result run(double v0, double r0, double a, int N, double coneHalf, unsigned char newtonian, int verbose) {
    Result res = {0};
    double c = 1.0;
    // The field must be fully populated at release: every pong arriving
    // then was captured with the rules on.  Closing at 2 v0, the first
    // round trip from rStart = r0 + 2 v0 L completes within L only when
    // L >= 2 r0 / (1 - 3 v0); take 1.3x that for a steady corridor.
    double lookback = 1.3 * 2.0*r0 / (c*(1.0 - 3.0*v0)) + 200;
    double rStart = r0 + 2.0*v0*lookback;

    PCUniverse* u = PCUniverseCreate(rStart + 2*a + 40, 8*a + 2*coneHalf*rStart + 40);
    PCUniverseSetC(u, c);
    PCUniverseSetVolley(u, N, 1);
    PCNode* A = PCUniverseCreateNode(u, -rStart/2, 0, a, 1, 1);
    PCNode* B = PCUniverseCreateNode(u,  rStart/2, 0, a, 1, 1);
    PCUniverseSetNodeVelocity(u, A,  v0, 0);
    PCUniverseSetNodeVelocity(u, B, -v0, 0);
    PCNodeSetHyle(A, 1, 1);
    PCNodeSetHyle(B, 1, 1);
    double q = M_PI / ((double)N * a);
    PCUniverseSetCone(u, coneHalf);
    PCUniverseSetDynamics(u, 1, q, newtonian);
    PCUniverseSetHeld(u, 1);

    // Lookback at uniform motion: populate the field, impulses armed on
    // the pongs but the nodes held.  Release at r0.  Over the last 400
    // held tics, read the uniform-approach force law: <F_A(t) r(t)>.
    long tic = 0;
    double fr = 0; long frTics = 0; double lastSumHeld = 0;
    while (B->pos.x - A->pos.x > r0) {
        PCUniverseTic(u); tic++;
        double r = B->pos.x - A->pos.x;
        if (r < r0 + 2*v0*400) {
            fr += -(A->impulseSum.x - lastSumHeld) * r;
            frTics++;
        }
        lastSumHeld = A->impulseSum.x;
    }
    res.fUniform = frTics ? fr / frTics : 0;
    double rOn = B->pos.x - A->pos.x;
    long capturesLookback = A->captures + B->captures;
    PCUniverseSetHeld(u, 0);
    // Diagnostics restart at the switch-on.
    A->impulses = B->impulses = 0;
    A->impulseSum.x = A->impulseSum.y = B->impulseSum.x = B->impulseSum.y = 0;

    res.rmin = rOn;
    long ticOn = tic;
    long ticLimit = ticOn + (long)(6.0*r0/v0) + 20000;
    int turned = 0;
    double lastReport = 0, lastSum = 0;
    while (tic < ticLimit) {
        PCUniverseTic(u); tic++;
        double r = B->pos.x - A->pos.x;
        if (tic - ticOn == 40) res.fRelease = -(A->impulseSum.x / 40.0) * rOn;
        if (r < res.rmin) res.rmin = r;
        if (r <= 2*a) { res.collided = 1; break; }
        if (!turned && A->v.x <= 0) { turned = 1; res.ticsTurn = tic - ticOn; }
        if (turned && r >= rOn) {
            res.vexit = sqrt(A->v.x*A->v.x + A->v.y*A->v.y);
            res.rExit = r;
            break;
        }
        long dt = tic - ticOn;
        long every = dt < 1200 ? 100 : 2000;
        if (verbose && dt - lastReport >= every) {
            double fx = -(A->impulseSum.x - lastSum) / (double)(dt - lastReport);
            lastReport = dt; lastSum = A->impulseSum.x;
            fprintf(stderr, "  t=%6ld r/r0=%.5f vA=%+.5f pings=%d pongs=%d F_A=%.3e 1/r=%.3e yA=%.2e\n",
                dt, r/rOn, A->v.x, u->pingCount, u->pongCount, fx, 1.0/r, A->pos.y);
        }
    }
    res.ticsTotal = tic - ticOn;
    res.captures = A->captures + B->captures - capturesLookback;
    res.impulses = A->impulses + B->impulses;
    (void)ticOn;
    PCUniverseRelease(u);
    return res;
}

int main(int argc, char** argv) {
    double v0s[8]; int nv = 0;
    int quick = 0;
    for (int i=1;i<argc && nv<8;i++) {
        if (argv[i][0] == 'q') { quick = 1; continue; }
        v0s[nv++] = atof(argv[i]);
    }
    if (!nv) { v0s[0] = 0.15; v0s[1] = 0.30; nv = 2; }

    double r0 = 1000.0;
    // Refinement ladder: node extent a/r0 halves as N doubles, keeping
    // the capture rate N a / (pi r) (~16 per tic) fixed.
    struct { double aOverR0; int N; } rungs[] = { {0.025, 2000}, {0.0125, 4000}, {0.00625, 8000} };
    int nr = 3;
    int r0Only = quick ? 1 : 0;

    printf("rung 0 — symmetric head-on encounter on the Philippine engine (2D, eta0 = c = 1, F = 1/r)\n");
    printf("closed form: r_min/r0 = exp(-v0^2); elastic exit\n\n");
    for (int iv=0; iv<nv; iv++) {
        double v0 = v0s[iv];
        double closed = exp(-v0*v0);
        printf("v0 = %.3f   closed r_min/r0 = %.6f\n", v0, closed);
        printf("  analytic uniform-approach force law of the rules (2D): (1-b^2)^1.5 = %.4f\n", pow(1.0 - v0*v0, 1.5));
        printf("  %-9s %-6s %-5s %-11s %-11s %-10s %-9s %-9s %-9s %-8s\n", "a/r0", "N", "dyn", "r_min/r0", "vs closed", "exit v/v0", "<F r>unif", "F_rel*r0", "t_turn", "captures");
        for (int ir=0; ir<nr; ir++) {
            if (r0Only && ir != 1) continue;
            double a = rungs[ir].aOverR0 * r0;
            double coneHalf = 2.5 * asin(a / (0.85*r0));
            for (int dyn=1; dyn>=0; dyn--) {
                if (ir != 1 && dyn == 0) continue;   // Rule-4 variant at the middle rung only
                Result res = run(v0, r0, a, rungs[ir].N, coneHalf, (unsigned char)dyn, 0);
                double ratio = res.rmin / r0;
                printf("  %-9.5f %-6d %-5s %-11.6f %+-11.2e %-10.5f %-9.4f %-9.4f %-9ld %-8ld%s\n",
                    rungs[ir].aOverR0, rungs[ir].N, dyn ? "newt" : "rule4",
                    ratio, ratio/closed - 1.0, res.vexit / v0, res.fUniform, res.fRelease, res.ticsTurn, res.captures,
                    res.collided ? "  COLLIDED" : "");
                fflush(stdout);
            }
        }
        printf("\n");
    }
    return 0;
}
