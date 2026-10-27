# AngMom — independent rebuild of the angular-momentum closure

Handoff: `Physics/Mechanism/aexels-handoff-angmom.md` (F-Ph, 2026-10-27).
Built from ItL's definitions (S3.3 apparent transverse dioptra; eq:Fback
recoil; S5.3 bridge share); F-Ph's scripts not read.  c = W = 1.

```
python3 -m venv .venv && .venv/bin/pip install numpy
.venv/bin/python angmom.py        # ping side, three-rung ladder (~4 min; 'quick' = two rungs)
.venv/bin/python check_spin.py    # spin share by an independent route
.venv/bin/python node_side.py     # node-side books, circle and ellipse
.venv/bin/python ald_check.py     # radiated J vs relativistic ALD torque
.venv/bin/python reservoir_dyn.py  # F-Ph's bridge reservoir in the equation of motion (~30 s)
```

## Method (angmom.py)

Far observer in direction n, retarded direction = n, t_obs = t_e − n·r,
κ = 1 − n·β.  X = D⊥/κ with D = n − β.  Fourier over observer time:
c_m = (1/T)∫ X e^{imt_obs} dt_obs = (1/T)∫ κX e^{imt_obs} dt_e, and
κX = (β·n)n − β — κ cancels, the integrand is smooth and periodic in
t_e, the uniform trapezoid is spectrally exact.  ∂_φ c_m is analytic
under the integral.  Sphere: Gauss–Legendre in cosθ × uniform φ.
Per harmonic: flux m²|c_m|², spin Im(c*×c)_z, orbital Σ_j Im(c_j* ∂_φ c_j),
J rate = flux·(s+l)/m.  Convergence is spectral — rungs agree to ~1e-11,
not second order.

## Results

J_z/(P/W), spin + orbital:

| case | spin | orbital | total | F-Ph |
|---|---|---|---|---|
| circular β 0.01 | 0.499930001 | 0.500069999 | 1.00000000000000 | 0.500 + 0.500 |
| circular β 0.3 | 0.437954680 | 0.562045320 | 1.00000000000000 | 0.438 + 0.562 |
| circular β 0.6 | **0.264951980** | **0.735048020** | 1.00000000000000 | 0.267 + 0.733 |
| ellipse 2:1, β 0.01 | 0.399969500 | 0.400039499 | 0.800008999 | 0.400 + 0.400 = 0.800 |
| ellipse 2:1, β 0.3 | 0.372179912 | 0.435031897 | 0.807211809 | — |
| ellipse 2:1, β 0.6 | | | 0.814336283 | — |

- **Circular β 0.6: the split is 0.26495 / 0.73505, not 0.267 / 0.733.**
  Two independent routes agree to 12 digits (check_spin.py: Newton-
  inverted retarded times, D⊥/κ evaluated directly, FFT over a uniform
  observer-time grid).  β 0.01 and 0.3 confirm F-Ph's numbers.
- The circular total is exact to 1e-14 at every β — and is a symmetry
  identity, not a physics test: for a rigidly rotating pattern
  c_m(φ) = R(φ) c_m(0) e^{imφ}, so spin + Cartesian orbital = m
  pointwise and J = P/W for ANY rigidly rotating radiator.  It verifies
  the machinery.
- Normalization: the radiation-side P equals ⟨Liénard P⟩ to 1e-12.
- Radiated J equals the time-averaged relativistic Abraham–Lorentz–
  Dirac torque to 10 digits in every case (ald_check.py).
- Side check: slow circular orbit, m = 1 Stokes V/I = 2cosθ/(1+cos²θ)
  to 1e-7 (the O(β²) of β = 0.001).

## The node side — closes on the circle, fails on the ellipse

ItL as written: recoil Pv (eq:Fback) + the S5.3 bridge share P/(γ²v),
both against the motion: P/v along −v̂, P the instantaneous power.  On the
circle (r×v)/v² = 1/W, so torque = P/W at every speed — closes.
On any other orbit the torque is ⟨P (r×v)_z / v²⟩:

| orbit | node side (ItL) | radiated = ALD |
|---|---|---|
| circular, any β | 1.0000000000 | 1.0000000000 |
| ellipse 2:1, β 0.01 | 1.1999734983 | 0.8000089990 |
| ellipse 2:1, β 0.3 | 1.1747116535 | 0.8072118088 |
| ellipse 2:1, β 0.6 | 1.0763876796 | 0.8143362832 |

Per period, under S5.3 as written, energy and momentum BOTH close (energy
1 to 1e-10, momentum 0 to 1e-14) — only angular momentum catches the
error, which is why energy/momentum checks never saw it.  node_side.py
scores any candidate force law on all three books (add a function to
CANDIDATES).

Slow-limit closed forms (a:b ellipse): node 2 − 2ab/(a²+b²) = 1.2,
radiation 2ab/(a²+b²) = 0.8.  The node loses 50 % more angular momentum
than its radiation carries, every period — a secular imbalance, so no
periodic register can hold it.

Why: the bridge share is fixed by INSTANTANEOUS energy balance (F·v = P
at every moment), which fixes only the along-v component, and placing all
of it against the motion distributes the drag as P/v ∝ r²/v.  LW's own
reaction (ALD) differs from it by the Schott term — a total derivative,
invisible in the energy books over a period, but not in the torque
distribution: on the harmonic ellipse the slow ALD drag is (2/3)q²W²v,
∝ v, not ∝ r²/v.  The circle is the one orbit where the two coincide
(P/v and ȧ both constant along −v̂).  A repair would let the bridge hold
a Schott-type register — energy the bridge stores and returns within
the period — so the impulse it delivers need not match P instant by
instant.  The ellipse is the discriminating test for any such rule.

## The bridge reservoir in a node's equation of motion (reservoir_dyn.py)

F-Ph's candidate S5.3 repair (Physics c3ac206, request ba81fa0): recoil
−P v plus a bridge reservoir holding momentum −p_S, hyle −E_S, handing the
node their rates of change.  c = m = K = 1, push F = −K r from a fixed
centre, τ = (2/3)q²/m, pure-Python RK4 (~30 s; 'quick' = τ 0.01 only).

- **(a) reservoir from the node's acceleration** (p_S = τγA): this IS ALD —
  the reservoir is ALD's Schott part.  Third order.  Run forward it runs
  away within 31–44 τ even from the exact runaway-free state (roundoff
  seeds it), 9–19 τ from A = F — under 1/15 of a period at τW = 0.01.  Its
  runaway-free solution (integrated backward from (b)'s end state, where
  the runaway mode decays) closes all three books with the reservoir to
  1e-12 — and pre-accelerates: released from rest, the node moves before
  the push acts, |A(−kτ)|/|A(0)| = e^−k to 4 digits, gathering τF₀ of
  momentum by t = 0.  A bridge running forward in time cannot do this.
- **(b) reservoir from the push the bridge carries** (p_S = τγF,
  E_S = τγ v·F; Landau–Lifshitz class).  Second order, runs forward, no
  runaway, no pre-acceleration; at release an instant kick of exactly
  τF₀ — the momentum ALD gathers by pre-accelerating.  Momentum and
  angular books close by construction (1e-13); energy closes to a
  bounded O(τ²) remainder (E_S's hyle partner is exact only on the
  zeroth-order motion).

Book residuals over 20 periods, relative to the radiated amount,
τ = 0.01 / 0.001.  "Honest" = node + (b)'s reservoir against the radiation
the actual motion emits (P = τγ²(A² − (v·A)²), A = dp/dt), the kick's own
radiation excluded:

| case | (b) energy, own | (b) energy, honest | (b) angular, honest | max \|E_S\| / a period's radiation |
|---|---|---|---|---|
| circular β 0.01 | +5.0e-5 / +5.0e-7 | +5.0e-5 / +5.0e-7 | −3.2e-9 / −4.7e-11 | 0.002 / 0.000 |
| circular β 0.3 | +5.4e-5 / +5.5e-7 | +4.9e-5 / +4.8e-7 | −3.4e-6 / −5.1e-8 | 0.002 / 0.000 |
| ellipse 2:1, a 0.01 | +8.0e-5 / +8.0e-7 | +2.0e-5 / +2.0e-7 | −4.4e-9 / −6.5e-11 | 0.099 / 0.096 |
| ellipse 2:1, a 0.3 | +1.0e-4 / +2.7e-6 | −8.6e-6 / −1.9e-6 | −4.4e-6 / −1.5e-7 | 0.099 / 0.096 |
| release from rest, a 0.01 | +1.0e-4 / +1.0e-6 | +5.6e-9 / −9.7e-11 | — | 0.164 / 0.160 |
| release from rest, a 0.3 | +1.3e-4 / +7.4e-6 | −4.1e-5 / −6.9e-6 | — | 0.169 / 0.165 |

Not secular: the ellipse a 0.3, τ 0.001 relative energy residual is
7.4e-6 / 8.9e-6 / 2.7e-6 / 2.8e-6 at 5 / 10 / 20 / 40 periods while the
radiated energy grows 7×.  Compare S5.3 as written: 1.2 against 0.8 on the
ellipse, every period.  (a) and (b) trajectories agree to |Δr|/r₀ ≤ 7.5e-3
(τ 0.01), ≤ 7e-5 (τ 0.001).  The reservoir stays bounded: zero on the
circle, ~0.1 of a period's radiation on the ellipse, ~0.17 at release.
The kick at a sudden release is a velocity step (its Larmor radiation is
not finite); any physical push switches on over a transit time.
