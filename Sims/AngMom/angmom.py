"""angmom.py — independent rebuild of the angular-momentum closure (F-Ax).

Handoff: Physics/Mechanism/aexels-handoff-angmom.md (F-Ph, 2026-10-27).
Built from ItL's definitions only; F-Ph's scripts not read.  One frame
(the medium), c = 1, orbit frequency W = 1.

Node on x = a cos t, y = b sin t.  Far observer in direction n; the
retarded direction is n itself, observer time t_obs = t_e - n.r(t_e),
kappa = 1 - n.beta = dt_obs/dt_e.

ItL S3.3: D = n - beta, D_perp = D - kappa n = -(beta - (beta.n) n),
apparent transverse dioptra X = D_perp / kappa.  Its observer-time
derivative is the LW radiation field (eq:E3 x one arrival Jacobian).

Fourier over observer time, X(t) = sum_m c_m e^{-imt} + c.c.:
    c_m = (1/T) int X e^{im t_obs} dt_obs = (1/T) int kappa X e^{im t_obs} dt_e
and kappa X = (beta.n) n - beta, so kappa cancels: the integrand is
smooth and periodic in t_e and the uniform-t_e trapezoid is spectrally
exact.  d/dphi of c_m is taken analytically under the integral (n and
t_obs both depend on phi), not by finite differences.

Per harmonic m (photon of frequency m), per solid angle:
    energy flux       ~ m^2 |c_m|^2
    spin_z            = Im(c_m* x c_m)_z / |c_m|^2
    orbital_z         = sum_j Im(c_mj* d_phi c_mj) / |c_m|^2  (Cartesian)
    J_z rate          ~ flux (spin_z + orbital_z) / m
Sphere: Gauss-Legendre in cos(theta), uniform phi (trapezoid, spectral).

Node side (ItL, analytic): recoil -P beta (eq:Fback) plus the S5.3
bridge share P/(gamma^2 v) against the motion: P(v + (1-v^2)/v) = P/v,
torque (P/v)(v/W) = P/W on the circular orbit at every speed.

Run: .venv/bin/python angmom.py
"""
import sys
import numpy as np


def harmonics(a, b, n_theta, n_phi, n_t, m_max):
    """Return per-direction weights and the sphere-integrated P, J_spin, J_orb."""
    mu, wmu = np.polynomial.legendre.leggauss(n_theta)
    st = np.sqrt(1.0 - mu**2)
    phi = 2*np.pi*np.arange(n_phi)/n_phi
    wphi = 2*np.pi/n_phi
    t = 2*np.pi*np.arange(n_t)/n_t

    # Direction n and its phi-derivative, shape (n_theta, n_phi, 3).
    n = np.stack([st[:, None]*np.cos(phi)[None, :],
                  st[:, None]*np.sin(phi)[None, :],
                  np.broadcast_to(mu[:, None], (n_theta, n_phi))], axis=-1)
    dn = np.stack([-st[:, None]*np.sin(phi)[None, :],
                   st[:, None]*np.cos(phi)[None, :],
                   np.zeros((n_theta, n_phi))], axis=-1)

    # Orbit, shape (n_t, 3).
    r = np.stack([a*np.cos(t), b*np.sin(t), np.zeros(n_t)], axis=-1)
    beta = np.stack([-a*np.sin(t), b*np.cos(t), np.zeros(n_t)], axis=-1)

    nr = np.einsum('ijk,tk->ijt', n, r)          # n.r
    nb = np.einsum('ijk,tk->ijt', n, beta)       # n.beta
    dnr = np.einsum('ijk,tk->ijt', dn, r)        # dn.r
    dnb = np.einsum('ijk,tk->ijt', dn, beta)     # dn.beta
    tobs = t[None, None, :] - nr

    # kappa X = (beta.n) n - beta, and its phi-derivative (at fixed t_e).
    g = nb[..., None]*n[:, :, None, :] - beta[None, None, :, :]
    dg = dnb[..., None]*n[:, :, None, :] + nb[..., None]*dn[:, :, None, :]

    e1 = np.exp(1j*tobs)
    em = np.ones_like(e1)
    dA = (wmu[:, None]*wphi)                     # sphere weights
    P = Js = Jo = 0.0
    per_m = []
    for m in range(1, m_max+1):
        em = em*e1
        c = np.einsum('ijtk,ijt->ijk', g, em)/n_t
        # d/dphi [g e^{im tobs}] = dg e + g (im)(-dn.r) e
        dc = (np.einsum('ijtk,ijt->ijk', dg, em)
              + np.einsum('ijtk,ijt->ijk', g, (-1j*m*dnr)*em))/n_t
        c2 = np.sum(np.abs(c)**2, axis=-1)
        spin = 2*np.imag(np.conj(c[..., 0])*c[..., 1])              # Im(c* x c)_z
        orb = np.sum(np.imag(np.conj(c)*dc), axis=-1)
        pm = np.sum(dA*m**2*c2)
        sm = np.sum(dA*m*spin)                                       # flux*spin/m
        om = np.sum(dA*m*orb)
        P += pm; Js += sm; Jo += om
        per_m.append((m, pm, sm, om))
    return P, Js, Jo, per_m, (mu, n, c)


def closure(a, b, n_theta, n_phi, n_t, m_max):
    P, Js, Jo, per_m, _ = harmonics(a, b, n_theta, n_phi, n_t, m_max)
    # J/(P/W) with W = 1
    return Js/P, Jo/P, (Js+Jo)/P, per_m[-1][1]/P


def ellipticity_check(beta, n_theta=16):
    """Slow circular orbit: Stokes V/I of the m = 1 harmonic vs 2cos/(1+cos^2)."""
    _, _, _, _, (mu, n, c) = harmonics(beta, beta, n_theta, 4, 64, 1)
    # transverse basis at phi = 0: e_theta = (cos, 0, -sin), e_phi = (0, 1, 0)
    st = np.sqrt(1 - mu**2)
    eth = np.stack([mu, 0*mu, -st], axis=-1)
    eph = np.stack([0*mu, 1+0*mu, 0*mu], axis=-1)
    ct = np.einsum('ik,ik->i', c[:, 0, :], eth)
    cp = np.einsum('ik,ik->i', c[:, 0, :], eph)
    V = 2*np.imag(np.conj(ct)*cp)/(np.abs(ct)**2 + np.abs(cp)**2)
    return np.max(np.abs(V - 2*mu/(1 + mu**2)))


if __name__ == "__main__":
    cases = [("circular", 0.01, 0.01), ("circular", 0.3, 0.3), ("circular", 0.6, 0.6),
             ("ellipse 2:1", 0.01, 0.005), ("ellipse 2:1", 0.3, 0.15)]
    expected = {("circular", 0.01): (0.500, 0.500, 1.0), ("circular", 0.3): (0.438, 0.562, 1.0),
                ("circular", 0.6): (0.267, 0.733, 1.0), ("ellipse 2:1", 0.01): (0.400, 0.400, 0.8)}
    ladders = [(24, 16, 256, 40), (48, 32, 512, 80), (96, 64, 1024, 160)]
    if len(sys.argv) > 1 and sys.argv[1] == "quick":
        ladders = ladders[:2]
    print("node side (ItL, analytic): recoil P v + S5.3 bridge P/(gamma^2 v) = P/v -> torque P/W at every speed")
    for beta in (0.01, 0.3, 0.6, 0.9):
        g2 = 1/(1 - beta**2)
        print(f"  beta {beta}: (v + 1/(gamma^2 v)) * v = {(beta + 1/(g2*beta))*beta:.15f}")
    print()
    print("ping side: J_z / (P/W), spin + orbital, sphere x time x harmonic ladder")
    print(f"  {'case':<12} {'beta':<5} {'n_th x n_ph x n_t, M':<22} {'spin':<16} {'orbital':<16} {'total':<18} {'last-m P share':<10}")
    for name, a, b in cases:
        for nth, nph, nt, M in ladders:
            s, o, tot, tail = closure(a, b, nth, nph, nt, M)
            print(f"  {name:<12} {a:<5} {f'{nth}x{nph}x{nt}, {M}':<22} {s:<16.12f} {o:<16.12f} {tot:<18.14f} {tail:.1e}")
        exp = expected.get((name, a))
        if exp:
            print(f"  {'':<12} {'':<5} {'F-Ph expected':<22} {exp[0]:<16} {exp[1]:<16} {exp[2]}")
        print()
    print("side check: slow circular orbit, m = 1 Stokes V/I vs 2cos(theta)/(1+cos^2(theta)): max |diff| =",
          f"{ellipticity_check(0.001):.2e}")
