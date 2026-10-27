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
