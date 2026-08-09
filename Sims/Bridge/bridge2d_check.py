#!/usr/bin/env python3
"""Which engineered emission density gives equal bidirectional capture in 2D?

The 3D bridge model (bridge.py) verifies that ItL Rule 3 —
(1-b^2)/(1-b cos t)^2 — exactly cancels the fore/aft capture geometry in 3D.
The Hyle Lab is 2D.  Hypothesis: in 2D the cancellation needs the 2D-correct
form sqrt(1-b^2)/(1-b cos t) (one power of kappa, normalization keeping the
total rate beta-independent), and the 3D form leaves an uncancelled kappa,
producing the ~(1+b)/(1-b) capture asymmetry the lab just showed.
"""
import numpy as np

C = 1.0
L = 1.0
R = 0.02 * L          # target radius
BETA = 0.6
N = 4_000_000

rng = np.random.default_rng(1)

def sample_theta(density, n):
    """Inverse-CDF sample of emission angle theta in [0, 2pi) (from velocity dir)."""
    grid = np.linspace(0, 2*np.pi, 16385)
    mid = 0.5*(grid[1:] + grid[:-1])
    w = density(mid)
    cdf = np.concatenate([[0.0], np.cumsum(w)])
    cdf /= cdf[-1]
    u = rng.uniform(0, 1, n)
    return np.interp(u, cdf, grid)

def capture_fraction(density, ahead):
    """Source at origin, v = BETA*x; co-moving target disc radius R at
    (+L,0) if ahead else (-L,0).  Fraction of emitted pings captured
    (first entry of the relative-motion ray into the disc)."""
    theta = sample_theta(density, N)
    d = np.stack([np.cos(theta), np.sin(theta)], axis=1)       # flight dir (unit, speed C)
    v = np.array([BETA*C, 0.0])
    T0 = np.array([L if ahead else -L, 0.0])
    relP = -T0[None, :]                                        # ping start - target center
    relV = d*C - v[None, :]
    b = np.einsum('ij,ij->i', relP, relV)
    A = np.einsum('ij,ij->i', relV, relV)
    c0 = float(relP[0] @ relP[0]) - R*R
    disc = b*b - A*c0
    hit = (b < 0) & (disc >= 0)
    return np.mean(hit)

d3 = lambda t: (1-BETA**2)/(1-BETA*np.cos(t))**2               # ItL Rule 3 (3D form)
d2 = lambda t: np.sqrt(1-BETA**2)/(1-BETA*np.cos(t))           # 2D-correct engineered form
iso = lambda t: np.ones_like(t)

print(f"beta={BETA}, r/L={R/L}, N={N}")
print(f"{'density':>12} {'fwd (chase)':>12} {'back':>12} {'ratio f/b':>10}")
for name, dens in [("3D Rule 3", d3), ("2D form", d2), ("isotropic", iso)]:
    f = capture_fraction(dens, ahead=True)
    bk = capture_fraction(dens, ahead=False)
    print(f"{name:>12} {f:12.6e} {bk:12.6e} {f/bk:10.3f}")
print(f"\n(static 2D reference: asin(r/L)/pi = {np.arcsin(R/L)/np.pi:.6e})")
