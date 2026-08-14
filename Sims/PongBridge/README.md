# Demo 0 — the Static Pong Bridge, from nothing

Standalone minimal sim (single C file, no dependence on any existing Aexels
code) whose only physics is: **emit, fly, capture, respond**. It ends with the
static pong bridge as an emergent census measured against exact predicted
numbers. No hyle, no parcels, no mode axes, no motion. Pure traffic.

Brief: F-Ph via Joe, 2026-08-08 (Physics repo, Claudes/Chat.md thread).
Seat: F-Ax. This directory is deliberately outside the Xcode project; the
HyleLab stub (Source/Interface/HyleLab, off the Quantum glyph) is the eventual
visual home.

## Build / run

```
make run        # all stages, report to stdout
make snapshot   # also writes pongbridge_snapshot.svg (the cones)
```

## The constants table (all unit choices, recorded as made)

| choice | value |
|---|---|
| tic | 1 time unit (the integration step) |
| c | 1 length per tic |
| rho0 | pings per tic per emitting node |
| emission | stratified: theta_j = 2pi(j + u_t)/rho0, u_t = frac(PHI·t + 0.37·nodeIndex); deterministic, no RNG anywhere |
| collision | exact segment–circle first-entry per tic (no tunneling) |
| event times | continuous: mid-tic spawns advance the remaining fraction the same tic; capture/arrival times are quadratic-solve exact |
| self-capture | none: pings ignore their emitter (born inside it); pongs interact only with their target |
| miss-cull | pings whose ray cannot hit the other node's disc may be culled at birth (physics unchanged); OFF for stage 0 and the snapshot |

## Acceptance results (this machine, 2026-08-08; deterministic — no seeds)

**Stage 0 — plumbing.** Emission count = rho0·t EXACT (90000/90000). Annulus
census [r, r+1) holds exactly rho0 pings per annulus (worst deviation 0), so
area density falls as 1/r. EXACT.

**Stage 1 — capture rate.** Measured against exact rho0·asin(a/L)/pi, and
against the brief's leading-order rho0·a/(piL):

| L | a | measured /tic | vs exact | vs brief |
|---|---|---|---|---|
| 400 | 10 | 2.865250 | +5.7e-05 | +1.6e-04 |
| 200 | 50 | 28.953000 | -7.0e-05 | +1.1e-02 |

The a/L = 0.25 row resolves the asin correction: the sim tracks the exact
form, not the leading-order one.

**Stage 2 — pong return.** Arrival rate at A = capture rate at B (residual
-1.7e-04). Flight time mean 382.1038 vs quadrature-exact 382.1045 (residual
-2.0e-06); spread 9.79 ~ a-scale, as briefed. The mean sits below L/c = 400
because the capture point is up to a inside B's near face and the pong dies at
A's radius a — finite-a geometry, characterized, not error.

**Stage 3 — the census.** In-flight pongs per direction, rho0=360, a=10:

| L | measured | exact-quad | residual | brief N=rho0·a/(pi·c) | vs brief |
|---|---|---|---|---|---|
| 200 | 1043.384 | 1043.582 | -1.9e-04 | 1145.916 | -8.95% |
| 400 | 1094.748 | 1094.763 | -1.3e-05 | 1145.916 | -4.47% |
| 800 | 1120.459 | 1120.341 | +1.1e-04 | 1145.916 | -2.22% |
| 1600 | 1133.215 | 1133.129 | +7.7e-05 | 1145.916 | -1.11% |

The L-independent census is confirmed as the point-node limit: the finite-a
residual is -(1 + pi/4)·a/L (capture-face inset + death at radius a), halving
as L doubles — visible above. Linearity in rho0 holds to ~2e-05 over
rho0 = 90..720 (census/rho0 constant at 3.0410).

**Stage 3 — the refresh.** Kill A's emission after its final volley: the
B->A stream drains completely, on the stopwatch. Continuum-exact drain =
(2·sqrt(L^2-a^2) - a)/c = 789.75 for L=400, a=10 (the brief's 2L/c = 800 is
the point-node limit). A discretized volley undershoots by the edge-of-arc
sampling gap of the final volley; averaged over 16 cutoff phases:

| rho0 | mean shortfall | max shortfall |
|---|---|---|
| 360 | 7.39 | 10.87 |
| 1440 | 3.73 | 6.64 |
| 5760 | 2.69 | 4.42 |
| 23040 | 1.60 | 2.74 |

Converges to the continuum stopwatch from below (asymptotic order 1/2 in
rho0); the bridge empties to exactly zero in every run — it outlives its
source by two transits, never more.

**The cones.** `make snapshot` renders the steady state: two pong streams,
each broad (~a) at its origin face and converging on the far node — the
directed cones and the lens between them, emerging rather than drawn.

## Architecture notes (for Demo 1 and 2)

Captures flow through a single `simCapture(...)` — Demo 1's m-hat unit vector
and sign classification hang off that event without rebuilding anything.
Demo 2's stakes-and-race hangs off the same capture events. The traffic layer
here is the chassis.
