#!/usr/bin/env python3
"""
Bridge/bridge.py — the instantaneous bridge between two constant-velocity nodes.

The model the room converged on (Joe + F-Rf, 2026-08-08):
  * Medium frame, c = 1, L = 1 (scale-free: only r/L matters geometrically).
  * State: v_A, v_B (vectors, |v| < 1), and the ratio r/L. Continuum
    granularity assumed (open question, parked).
  * From the transport's perspective c ~ 0, so the bridge is read as a frozen
    snapshot at t = 0: every connecting signal's position and carried vectors.
  * Two instantaneous bridges, one per source node: the A-circuit (pings
    A->B in flight now, plus pongs B->A in flight now that answer earlier
    A-pings) and the B-circuit (mirror).

Rules implemented AS STATED in the papers:
  * SitD: cupola C = c_vec - v_source; pong = the ping's path mirrored over
    that ping's cupola vector; pong travels at c and intercepts the source
    exactly (verified numerically here, not assumed).
  * ItL Rule 3: angular emission density rho(theta) = (1-b^2) rho0 /
    (1 - b cos theta)^2, theta measured from the source's velocity.
    Total emission = 4 pi rho0 for every beta (verified here).

Everything below is exact for constant velocities except where marked
"numerical" (quadrature / root-finding at machine tolerance).
"""

import numpy as np

C = 1.0          # medium signal speed
RHO0 = 1.0       # emission density scale (results scale linearly)


# ---------------------------------------------------------------- kinematics

def make_state(vA, vB, ratio, L=1.0):
    """State: node A at origin at t=0, node B at (L,0,0) at t=0."""
    vA, vB = np.asarray(vA, float), np.asarray(vB, float)
    assert np.linalg.norm(vA) < C and np.linalg.norm(vB) < C
    return dict(A0=np.zeros(3), B0=np.array([L, 0.0, 0.0]),
                vA=vA, vB=vB, r=ratio * L, L=L)


def pos(P0, v, t):
    return P0 + v * t


def rule3_density(n_hat, v):
    """ItL Rule 3: angular density for emission direction n_hat from a
    source with velocity v.  rho0 = RHO0."""
    b = np.linalg.norm(v)
    if b == 0.0:
        return RHO0
    ct = np.dot(n_hat, v) / b
    return (1.0 - b * b) * RHO0 / (1.0 - b * ct) ** 2


def intercept_time(P_e, t_e, T0, vT):
    """Ping emitted at P_e at time t_e, aimed to reach the CENTER of a target
    whose worldline is T0 + vT*t.  Returns (t_a, n_hat): arrival time and the
    required emission direction.  Exact (quadratic)."""
    d0 = T0 - P_e
    a = np.dot(vT, vT) - C * C
    b = 2.0 * (np.dot(d0, vT) + C * C * t_e)
    c = np.dot(d0, d0) - C * C * t_e * t_e
    disc = b * b - 4 * a * c
    if a == 0.0:
        t_a = -c / b
    else:
        r1 = (-b + np.sqrt(disc)) / (2 * a)
        r2 = (-b - np.sqrt(disc)) / (2 * a)
        t_a = max(r1, r2) if max(r1, r2) > t_e else min(r1, r2)
    n = (T0 + vT * t_a - P_e)
    n_hat = n / np.linalg.norm(n)
    return t_a, n_hat


def hits(P_e, t_e, n_hat, T0, vT, r):
    """Does a ping emitted (P_e, t_e) along n_hat pass within r of the target
    center?  Exact closest-approach test on the relative straight line."""
    # relative position at time t >= t_e: (P_e - T0) + n_hat*(t-t_e) - vT*t
    w = n_hat * C - vT                       # relative velocity
    q0 = P_e - T0 - vT * t_e - 0.0           # relative position at t_e:
    q0 = P_e + 0.0 - (T0 + vT * t_e)
    t_rel = -np.dot(q0, w) / np.dot(w, w)    # time after t_e of closest approach
    if t_rel < 0:
        return False, np.inf
    dmin = np.linalg.norm(q0 + w * t_rel)
    return dmin <= r, dmin


def solve_emission_window(S0, vS, T0, vT):
    """Emission time t_e* < 0 such that a center-aimed ping arrives exactly
    at t = 0 (the oldest ping still in flight at the snapshot).  Exact."""
    # |T0 - (S0 + vS t_e)| = -c t_e   with t_e < 0
    d0 = T0 - S0
    a = np.dot(vS, vS) - C * C
    b = -2.0 * np.dot(d0, vS)          # careful: derive fresh
    # |d0 - vS t|^2 = t^2  ->  (vS.vS - 1) t^2 - 2 d0.vS t + d0.d0 = 0
    b = -2.0 * np.dot(d0, vS)
    c = np.dot(d0, d0)
    disc = b * b - 4 * a * c
    r1 = (-b + np.sqrt(disc)) / (2 * a)
    r2 = (-b - np.sqrt(disc)) / (2 * a)
    roots = [r for r in (r1, r2) if r < 0]
    return max(roots)                   # the least-negative (most recent) root


# ------------------------------------------------------------------ the pong

def pong_direction(n_hat, cupola):
    """SitD: the pong mirrors the ping's path over the ping's cupola vector.
    Reflect the REVERSED translation direction about the cupola axis."""
    c_hat = cupola / np.linalg.norm(cupola)
    u = -n_hat
    return 2.0 * np.dot(u, c_hat) * c_hat - u


def pong_return_time(Q, t_a, p_hat, S0, vS):
    """Pong emitted at Q at t_a along p_hat; time t_r at which it meets the
    source worldline S0 + vS t (closest approach; exact interception for
    constant velocities is VERIFIED by the caller, not assumed)."""
    w = p_hat * C - vS
    q0 = Q - (S0 + vS * t_a)
    t_rel = -np.dot(q0, w) / np.dot(w, w)
    miss = np.linalg.norm(q0 + w * t_rel)
    return t_a + t_rel, miss


# ------------------------------------------------- solid angle of the target

def capture_cone(P_e, t_e, T0, vT, r, n_samples=4000, rng=None):
    """Solid angle of emission directions from (P_e, t_e) that intercept the
    moving target sphere of radius r.  Monte Carlo inside a safe cone around
    the central ray (numerical; error ~ 1/sqrt(n))."""
    rng = rng or np.random.default_rng(0)
    t_a, n_hat = intercept_time(P_e, t_e, T0, vT)
    D = C * (t_a - t_e)
    half = 3.0 * (r / D)                       # generous cone
    # basis around n_hat
    a = np.array([1.0, 0, 0]) if abs(n_hat[0]) < 0.9 else np.array([0, 1.0, 0])
    e1 = np.cross(n_hat, a); e1 /= np.linalg.norm(e1)
    e2 = np.cross(n_hat, e1)
    cos_half = np.cos(half)
    u = rng.uniform(cos_half, 1.0, n_samples)
    ph = rng.uniform(0, 2 * np.pi, n_samples)
    s = np.sqrt(1 - u * u)
    dirs = (u[:, None] * n_hat + (s * np.cos(ph))[:, None] * e1
            + (s * np.sin(ph))[:, None] * e2)
    hit = 0
    for d in dirs:
        ok, _ = hits(P_e, t_e, d, T0, vT, r)
        hit += ok
    omega_cone = 2 * np.pi * (1 - cos_half)
    return omega_cone * hit / n_samples, t_a, n_hat


# ------------------------------------------------------------- the snapshot

def circuit_snapshot(state, source='A', n_slices=60, cone_samples=3000,
                     seed=1):
    """The SOURCE-sourced instantaneous bridge at t = 0.

    Returns dict with:
      ping leg: emission times, current positions, cupolas, local linear
                density (signals per unit corridor length), feed flux
      pong leg: the same for the return stream
      scalars : transit times, fluxes, in-flight counts, capture fraction,
                corridor sag, pong interception error (the SitD guarantee,
                measured)."""
    rng = np.random.default_rng(seed)
    if source == 'A':
        S0, vS, T0, vT = state['A0'], state['vA'], state['B0'], state['vB']
    else:
        S0, vS, T0, vT = state['B0'], state['vB'], state['A0'], state['vA']
    r = state['r']

    # --- ping leg ---------------------------------------------------------
    te_star = solve_emission_window(S0, vS, T0, vT)     # oldest in flight
    te_grid = np.linspace(te_star * (1 - 1e-9), 0.0, n_slices)
    ping = dict(t_e=[], pos=[], cupola=[], flux=[], t_a=[], n_hat=[])
    for te in te_grid:
        Pe = pos(S0, vS, te)
        omega, t_a, n_hat = capture_cone(Pe, te, T0, vT, r,
                                         n_samples=cone_samples, rng=rng)
        feed = rule3_density(n_hat, vS) * omega          # pings / unit time
        ping['t_e'].append(te); ping['t_a'].append(t_a)
        ping['n_hat'].append(n_hat)
        ping['pos'].append(Pe + n_hat * C * (0.0 - te))
        ping['cupola'].append(n_hat * C - vS)
        ping['flux'].append(feed)
    for k in ping:
        ping[k] = np.asarray(ping[k])

    # linear density along the corridor: lambda = feed * |dt_e/ds|
    ds = np.linalg.norm(np.gradient(ping['pos'], axis=0), axis=1)
    dte = np.gradient(ping['t_e'])
    ping['lambda'] = ping['flux'] * np.abs(dte) / ds   # signals per unit length

    # corridor sag: max distance of the ping locus from the chord S(0)->T(0)
    chord = (T0 - S0); chord_hat = chord / np.linalg.norm(chord)
    rel = ping['pos'] - S0
    perp = rel - np.outer(rel @ chord_hat, chord_hat)
    sag = np.linalg.norm(perp, axis=1).max()

    # in-flight count on the ping leg:  integral of feed over the window
    N_ping = np.trapezoid(ping['flux'], ping['t_e'])

    # arrival flux at the target NOW: feed at t_e* carried through the
    # emission->arrival Jacobian dt_e/dt_a
    dta = np.gradient(ping['t_a'])
    arr_jac = np.abs(dte / dta)
    arrival_flux_now = ping['flux'][0] * arr_jac[0]

    # --- pong leg ---------------------------------------------------------
    # pongs in flight now answer pings that ARRIVED at t_a <= 0; the oldest
    # pong still in flight left at t_a with return time t_r >= 0.
    # March emission times back until the pong from that ping has returned.
    pong = dict(t_emit=[], pos=[], cupola=[], flux=[], t_r=[], miss=[])
    te = te_star                       # ping arriving exactly now
    # walk further back in emission time
    step = abs(te_star) / n_slices
    te_back = te_star
    guard = 0
    while guard < 20 * n_slices:
        guard += 1
        Pe = pos(S0, vS, te_back)
        t_a, n_hat = intercept_time(Pe, te_back, T0, vT)
        Q = pos(T0, vT, t_a)                       # arrival point (center)
        cup = n_hat * C - vS
        p_hat = pong_direction(n_hat, cup)
        t_r, miss = pong_return_time(Q, t_a, p_hat, S0, vS)
        if t_r < 0:                                # already returned
            break
        if t_a <= 0:                               # pong in flight now
            omega, _, _ = capture_cone(Pe, te_back, T0, vT, r,
                                       n_samples=cone_samples, rng=rng)
            feed = rule3_density(n_hat, vS) * omega
            pong['t_emit'].append(t_a)
            pong['pos'].append(Q + p_hat * C * (0.0 - t_a))
            pong['cupola'].append(p_hat * C - vT)  # pong's source is target
            pong['flux'].append(feed)
            pong['t_r'].append(t_r)
            pong['miss'].append(miss)
        te_back -= step
    for k in pong:
        pong[k] = np.asarray(pong[k])
    N_pong = np.trapezoid(pong['flux'], pong['t_emit']) if len(pong['t_emit']) > 1 else 0.0

    # capture fraction of the full volley (at the snapshot's youngest ping)
    omega0, t_a0, aim0 = capture_cone(S0, 0.0, T0, vT, r,
                                      n_samples=8 * cone_samples, rng=rng)
    capture = rule3_density(aim0, vS) * omega0 / (4 * np.pi * RHO0)

    round_trip = (pong['t_r'][0] - pong['t_emit'][0] + ping['t_a'][-1]
                  if len(pong['t_r']) else np.nan)
    return dict(source=source, ping=ping, pong=pong,
                round_trip=ping['t_a'][-1] + (pong['t_r'][0] - pong['t_emit'][0]
                                              if len(pong['t_r']) else np.nan),
                transit_ping=ping['t_a'][-1] - 0.0,
                oldest_in_flight=-te_star,
                N_ping=abs(N_ping), N_pong=abs(N_pong),
                feed_flux=ping['flux'][-1],
                arrival_flux=arrival_flux_now,
                capture_fraction=capture,
                corridor_sag=sag,
                pong_miss_max=(pong['miss'].max() if len(pong['miss']) else 0.0))


# ---------------------------------------------------------------- verifiers

def verify_rule3_total(v, n=200_000, seed=2):
    """Gate: total emission over the sphere = 4 pi rho0 for every beta."""
    rng = np.random.default_rng(seed)
    z = rng.uniform(-1, 1, n); ph = rng.uniform(0, 2 * np.pi, n)
    s = np.sqrt(1 - z * z)
    dirs = np.stack([s * np.cos(ph), s * np.sin(ph), z], axis=1)
    b = np.linalg.norm(v)
    if b == 0:
        vals = np.full(n, RHO0)
    else:
        ct = dirs @ (v / b)
        vals = (1 - b * b) * RHO0 / (1 - b * ct) ** 2
    return vals.mean() * 4 * np.pi         # MC estimate of the integral


def verify_discrete(state, source='A', n_pings=2_000_000, seed=3):
    """Monte Carlo the actual protocol: emit n_pings per Rule 3 (exact
    inverse-CDF in cos theta), count interceptions of the target extent.
    Returns the discrete capture fraction (compare: circuit capture)."""
    rng = np.random.default_rng(seed)
    if source == 'A':
        S0, vS, T0, vT = state['A0'], state['vA'], state['B0'], state['vB']
    else:
        S0, vS, T0, vT = state['B0'], state['vB'], state['A0'], state['vA']
    b = np.linalg.norm(vS)
    u = rng.uniform(0, 1, n_pings)
    if b == 0:
        ct = rng.uniform(-1, 1, n_pings)
    else:
        # inverse CDF of (1-b^2)/(1-b c)^2 on [-1,1]:
        # F(c) = (1-b^2)/(2b) * [1/(1-bc) - 1/(1+b)]
        ct = (1.0 / (1.0 + b) + 2 * b * u / (1 - b * b))
        ct = (1.0 - 1.0 / ct) / b
    ph = rng.uniform(0, 2 * np.pi, n_pings)
    st = np.sqrt(np.clip(1 - ct * ct, 0, None))
    # basis: z-axis along vS (or arbitrary when b = 0)
    if b == 0:
        zax = np.array([0, 0, 1.0])
    else:
        zax = vS / b
    a = np.array([1.0, 0, 0]) if abs(zax[0]) < 0.9 else np.array([0, 1.0, 0])
    e1 = np.cross(zax, a); e1 /= np.linalg.norm(e1)
    e2 = np.cross(zax, e1)
    dirs = (ct[:, None] * zax + (st * np.cos(ph))[:, None] * e1
            + (st * np.sin(ph))[:, None] * e2)
    # closest-approach hit test, vectorized, emission at t=0 from S0
    w = dirs * C - vT
    q0 = S0 - T0
    wq = w @ q0 * -1.0
    ww = np.einsum('ij,ij->i', w, w)
    t_rel = wq / ww
    t_rel = np.clip(t_rel, 0, None)
    dmin = np.linalg.norm(q0[None, :] + w * t_rel[:, None], axis=1)
    return (dmin <= state['r']).mean()


# --------------------------------------------------------------------- demo

def report(state, label):
    print(f"\n=== {label} ===")
    print(f"    v_A={state['vA']}, v_B={state['vB']}, r/L={state['r']/state['L']}")
    tot = verify_rule3_total(state['vA'])
    print(f"    [gate] Rule-3 total emission = {tot:.4f}  (4*pi*rho0 = {4*np.pi:.4f})")
    for src in ('A', 'B'):
        c = circuit_snapshot(state, src)
        disc = verify_discrete(state, src)
        print(f"  -- {src}-sourced bridge --")
        print(f"    capture fraction     : {c['capture_fraction']:.3e}"
              f"   (discrete MC: {disc:.3e};  (r/L)^2/4 = {(state['r']/state['L'])**2/4:.3e})")
        print(f"    ping transit time    : {c['transit_ping']:.4f}"
              f"   oldest ping in flight: {c['oldest_in_flight']:.4f}")
        print(f"    feed flux (now)      : {c['feed_flux']:.4e}   arrival flux (now): {c['arrival_flux']:.4e}")
        print(f"    in flight: pings     : {c['N_ping']:.4e}   pongs: {c['N_pong']:.4e}")
        print(f"    round-trip time      : {c['round_trip']:.4f}   circuit total in flight: {c['N_ping']+c['N_pong']:.4e}")
        print(f"    corridor sag / L     : {c['corridor_sag']/state['L']:.4e}")
        print(f"    pong return miss     : {c['pong_miss_max']:.2e}  (SitD exact-return check)")
    return


# -------------------------------------------------------------------- figure

def plot_cases(cases, fname='snapshots.png'):
    """Left: linear density of each stream along the corridor (A->B axis).
    Right: the carried vectors for the A-sourced ping stream — translation
    (gray) vs cupola (blue) — the bridge's stored data."""
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    n = len(cases)
    fig, axes = plt.subplots(n, 2, figsize=(11, 3 * n))
    for row, (label, state) in enumerate(cases):
        axd, axv = axes[row]
        chord = state['B0'] - state['A0']; Lc = np.linalg.norm(chord)
        ch = chord / Lc
        for src, colp, colq in (('A', 'tab:blue', 'tab:cyan'),
                                ('B', 'tab:red', 'tab:orange')):
            c = circuit_snapshot(state, src, n_slices=120)
            x = ((c['ping']['pos'] - state['A0']) @ ch) / Lc
            axd.plot(x, c['ping']['lambda'], color=colp, lw=2,
                     label=f'{src}-pings')
            if len(c['pong']['pos']) > 1:
                Q = np.asarray(c['pong']['pos'])
                xq = ((Q - state['A0']) @ ch) / Lc
                # pong linear density: flux * |dt_emit/ds|
                dsq = np.linalg.norm(np.gradient(Q, axis=0), axis=1)
                dtq = np.abs(np.gradient(c['pong']['t_emit']))
                axd.plot(xq, c['pong']['flux'] * dtq / dsq, color=colq,
                         lw=1.4, ls='--', label=f'{src}-pongs')
        axd.set_title(f'{label} — stream densities', fontsize=10)
        axd.set_xlabel('position along corridor (A=0, B=1)')
        axd.set_ylabel(r'linear density $\lambda(s)$')
        axd.legend(fontsize=7); axd.grid(alpha=.25)

        cA = circuit_snapshot(state, 'A', n_slices=16)
        P = cA['ping']['pos']; x = ((P - state['A0']) @ ch) / Lc
        for k in range(len(P)):
            axv.annotate('', xy=(x[k] + 0.06 * cA['ping']['n_hat'][k][0],
                                 0.06 * cA['ping']['n_hat'][k][1]),
                         xytext=(x[k], 0),
                         arrowprops=dict(arrowstyle='->', color='gray', lw=1))
            cup = cA['ping']['cupola'][k]; cup = cup / np.linalg.norm(cup)
            axv.annotate('', xy=(x[k] + 0.06 * cup[0], 0.06 * cup[1]),
                         xytext=(x[k], 0),
                         arrowprops=dict(arrowstyle='->', color='tab:blue', lw=1.4))
        axv.set_ylim(-0.12, 0.12); axv.set_xlim(-0.05, 1.05)
        axv.set_title('A-ping carried vectors: translation (gray), cupola (blue)',
                      fontsize=9)
        axv.grid(alpha=.25)
    fig.suptitle('Instantaneous bridges at t=0 (c=1, L=1, rho0=1)', fontsize=12)
    fig.tight_layout()
    fig.savefig(fname, dpi=140)
    print(f"wrote {fname}")


if __name__ == '__main__':
    RL = 0.02
    report(make_state([0, 0, 0], [0, 0, 0], RL), "static pair (control)")
    report(make_state([0.6, 0, 0], [0.6, 0, 0], RL), "co-moving, parallel (alpha=0), beta=0.6")
    report(make_state([0, 0.6, 0], [0, 0.6, 0], RL), "co-moving, perpendicular (alpha=90), beta=0.6")
    report(make_state([0.3, 0, 0], [-0.3, 0, 0], RL), "head-on approach, beta=0.3 each")
    plot_cases([
        ("static pair", make_state([0, 0, 0], [0, 0, 0], RL)),
        ("co-moving parallel, beta=0.6", make_state([0.6, 0, 0], [0.6, 0, 0], RL)),
        ("co-moving perpendicular, beta=0.6", make_state([0, 0.6, 0], [0, 0.6, 0], RL)),
        ("head-on, beta=0.3 each", make_state([0.3, 0, 0], [-0.3, 0, 0], RL)),
    ])
