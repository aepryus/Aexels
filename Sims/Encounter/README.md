# Encounter — rung 0 of the dynamics ladder

The symmetric head-on encounter, run on the Hyle Lab's engine
(`Source/Engines/Hyle/Philippine`) with the rules' own dynamics switched
on.  Oracle: `Physics/Mechanism/rung0-encounter-oracle.py` (F-Ph desk,
2026-08-30).

```
make && ./encounter            # v0 = 0.15, 0.30, three-rung refinement ladder
./encounter q 0.05 0.10 0.20   # 'q' = middle rung only
```

## The test

Two identical outies (η₀ = 1, c = 1) approach head-on at ±v₀ from
separation r₀, in 2D.  Force normalized to F = 1/r at rest (the 2D log
potential): impulse quota q = π/(N a), so the isotropic capture rate
N a/(π r) per tic times q|C| gives 1/r.  The closed form for an
instantaneous census is

    r_min / r₀ = exp(−v₀²),   elastic exit (|v_exit| = v₀).

The oracle's naive-retarded run (impulse from the emission-time r,
delivered a round trip late, no aberration) misses by 50× in energy at
v₀ = 0.15 and collides at 0.3.  The question was whether the lab —
retardation real, aberration real — lands on the closed form.

Note the regime: the deceleration takes ~v₀ r₀ tics (160 at v₀ = 0.15)
while a round trip is ~2 r₀ (2000).  The whole turn happens inside 8%
of one exchange cycle.  The delivered force during the turn was locked
before the turn began.

## What the engine runs

- Rule 3 emission, 2D-correct form √(1−β²)ρ₀/(1−β cos θ); per-ping
  cupola C = n̂ − β; exact moving-disc capture.
- Rule 1: impulse q|C| along C locked at capture, riding the pong,
  delivered to the captor when the pong enters the source's disc.
- Rule 2: species sign (both outies here).
- Rule 5: the arrival-rate clause is real (the moving disc meets pings
  at its own rate — not applied twice); the direction clause
  n̂ (v_t · I₀)/c is applied per ping at capture.
- Momentum update: Newtonian v += I/η₀ (the oracle's convention) or
  Rule 4 (p = γη₀v).  Both reported.
- Initial condition: a lookback at uniform approach with impulses armed
  but the nodes held (the steady corridor of uniform motion), released
  the tic the separation crosses r₀ — the lab's counterpart of "full
  force present at r₀".  The lookback must exceed 2r₀/(1−3v₀) for the
  first round trip from the start position to complete before release
  (an earlier short lookback left the force at zero for 280 tics after
  release and was caught by the force trace).
- Cone emission: only the part of each volley aimed within ±h of the
  partner is emitted, count scaled by the window's Rule-3 mass, so the
  captures are exactly those of the full volley (h = 2.5× the largest
  capture angle).

## Results (2026-08-31)

Refinement ladder: a/r₀ halves as N doubles (capture rate ≈ 16/tic
fixed).  `<F r>unif` = the delivered force × separation averaged over
the last 400 held tics (the rules' force law for uniform approach);
`F_rel r₀` = the same over the first 40 tics after release.

```
v0 = 0.150   closed r_min/r0 = 0.977751        (1-b^2)^1.5 = 0.9664
  a/r0      N      dyn    r_min/r0   vs closed  exit v/v0  <F r>unif  F_rel*r0  t_turn
  0.02500   2000   newt   0.976251   -1.53e-03  0.92682    0.9802     0.9701    161
  0.01250   4000   newt   0.976137   -1.65e-03  0.93324    0.9733     0.9656    162
  0.01250   4000   rule4  0.975741   -2.06e-03  0.93575    0.9733     0.9656    163
  0.00625   8000   newt   0.976037   -1.75e-03  0.92993    0.9695     0.9610    162

v0 = 0.200   closed r_min/r0 = 0.960789        (1-b^2)^1.5 = 0.9406
  0.02500   2000   newt   0.957231   -3.70e-03  0.93093    0.9573     0.9560    218
  0.01250   4000   newt   0.956779   -4.17e-03  0.92857    0.9485     0.9500    221
  0.01250   4000   rule4  0.955495   -5.51e-03  0.92793    0.9485     0.9510    225
  0.00625   8000   newt   0.956573   -4.39e-03  0.92516    0.9449     0.9380    222

middle rung, Newtonian:
  v0     closed     r_min/r0   vs closed   exit v/v0  <F r>unif  (1-b^2)^1.5
  0.05   0.997503   0.997496   -7.6e-06    0.968      0.9983     0.9963
  0.10   0.990050   0.989594   -4.6e-04    0.948      0.9909     0.9850
  0.15   0.977751   0.976137   -1.7e-03    0.933      0.9733     0.9664
  0.20   0.960789   0.956779   -4.2e-03    0.929      0.9485     0.9406
  0.30   0.913931   0.896541   -1.9e-02    0.938      —          0.8682
```

### Verdict

1. **Not the closed form.**  The lab turns deeper than the closed form
   at every β, the deficit growing ~β⁴ in r_min/r₀ (−7.6e-6 at 0.05,
   −1.7e-3 at 0.15, −1.9e-2 at 0.30), i.e. 7–8 % deeper in the
   excursion r₀ − r_min at 0.15, 20 % at 0.30; and the encounter is
   inelastic — exit speed 0.93–0.97 v₀ (6–14 % of the kinetic energy
   lost) at every β including 0.05.  Stable under refinement (the r_min
   deficit moves by ~1e-4 per halving of a/r₀).  Aberration hides most
   of the retardation — the naive-retarded oracle collides — but not
   all of it: the rules do not reproduce instantaneous-census dynamics
   when the turn happens inside one exchange cycle.

2. **The rules' force law for uniform approach, derived and verified.**
   Factor-accounting the chain for two nodes approaching head-on at ±β
   (2D, collinear; θ = 0 for both emitters):

   | factor | source | 2D |
   |---|---|---|
   | emission density at θ = 0 | Rule 3, 2D form | (1+β)^½ (1−β)^−½ |
   | capture window a(1+β)/r_e | flight r_e/(1+β) | (1+β) |
   | emission→capture clock | dt_e/dt_c | (1+β)/(1−β) |
   | cupola magnitude | |n̂ − β| | (1−β) |
   | Rule 5 direction clause | I₀ + n̂(v_t·I₀)/c | (1−β) |
   | capture→delivery clock | pong met by the source | (1+β)/(1−β) |
   | emission distance → present | r_e = r_now ((1+β)/(1−β))² | (1−β)²/(1+β)² |

   Product: **F = (1−β²)^{3/2} / r_now**.  The harness measures the
   held-phase force at 0.9802 / 0.9733 / 0.9695 across the ladder at
   β = 0.15, linear in a/r₀, extrapolating to 0.9657 against 0.9664;
   at β = 0.20, 0.9573 / 0.9485 / 0.9449 → 0.9413 against 0.9406.
   Verified to ~1e-3.  For reference, 2D electrodynamics gives
   (1−β²)/r for the same configuration.

   The same accounting in 3D (density (1+β)/(1−β), window (1+β)²,
   distance ((1−β)/(1+β))⁴) gives **(1+β)(1−β)³ / r²** — asymmetric
   between approach and recession, 0.71 of the rest force at β = 0.15
   against electrodynamics' (1−β²) = 0.98.  DESK ANALYTIC ONLY — not
   yet run; a 3D harness item.  Cross-check that the accounting
   reproduces the paper: for a co-moving collinear pair it gives
   (1−β²)² / r² to both nodes, equal both ways (the paper's
   F₀(1∓β) ± βF₀ = F₀ balance), which with the 1/γ contraction is
   (1−β²) × rest — ItL §2.3's structure.

3. **Where the rest of the deficit comes from.**  With the rules' own
   force law the closed form would be exp(−v₀²/(1−β²)^{3/2}) = 0.97699
   at 0.15; the lab reaches 0.97614.  The remainder is the lag: the
   force delivered during the turn was locked while the pair was still
   in uniform approach, and its delivery is metered by the *source's*
   current speed (pong arrival rate (1+β_B)/(1−β_A)) — the trace shows
   the delivered force falling from 0.95 to 0.84 of 1/r as the pair
   slows, before the nodes' own deceleration has reached the field.
   That metering is Rule 1's "applied when the pong returns" clause
   acting as a non-local coupling to the partner's present velocity.

4. **Rule 4 vs Newtonian**: 0.4e-3 (0.15) to 7e-3 (0.30) in r_min/r₀ —
   the γ corrections, as expected; not the story.

## Files

- `encounter.c` — the harness (links the engine directly).
- Engine additions for this rung (all off by default; the in-app
  bridge lab is unchanged): `PCUniverseSetDynamics`, `PCUniverseSetHeld`,
  `PCUniverseSetCone`, `PCNodeSetHyle`; pongs carry `captor` and
  `impulse`; nodes carry `hyle`, `outie`, `v0`, impulse diagnostics;
  the Rule-3 table rebuilds when |v| drifts.
