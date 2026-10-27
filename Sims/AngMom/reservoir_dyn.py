"""reservoir_dyn.py — F-Ph's bridge reservoir in a node's equation of motion.

Request: Physics Claudes/Chat.md, F-Ph 2026-10-27 (ba81fa0); candidate in
Mechanism/wild/node_side_reservoir.py (c3ac206).  c = 1, node inertia m = 1,
p = gamma v, reaction time tau = (2/3) q^2 / m.  Push: a harmonic binding
F = -K r from a fixed centre (K = 1, slow-limit period 2 pi), a 3-force on p.

The node: dp/dt = F - P v + d(p_S)/dt, the recoil -P v (eq:Fback) plus the
rate of change of what the bridge reservoir holds (momentum -p_S, hyle -E_S).
    (a) reservoir from the node's own acceleration A = dp/dt:
            p_S = tau gamma A,   E_S = tau gamma dgamma/dt,   P = tau gamma^2 (A^2 - (v.A)^2)
        — this is ALD exactly (third order; state r, p, A).
    (b) reservoir from the push the bridge carries (A -> F/m):
            p_S = tau gamma F,   E_S = tau gamma (v.F),       P_b = tau gamma^2 (F^2 - (v.F)^2)
        — Landau-Lifshitz class (second order; state r, Pi = p - p_S).
Books, node + reservoir + radiated (+ the centre's impulse for momentum):
    energy    gamma - 1 + K r^2/2 - E_S + int P
    momentum  p - p_S + int P v - int F
    angular   (r x p) - (r x p_S) + int [P (r x v) + v x p_S]
For (b) the radiation a far observer sees is set by the ACTUAL motion,
P_act = tau gamma^2 (A^2 - (v.A)^2) with A = dp/dt; its rival to P_b is
reported as the honest book.

(a) cannot run forward (the runaway mode grows as e^{t/(tau gamma)}); its
runaway-free solution is found by integrating BACKWARD from (b)'s end state,
along which that mode decays.  The forward runaway and, for the release, the
pre-acceleration are measured on that solution.

Run: .venv/bin/python reservoir_dyn.py [quick]
"""
import math
import sys

K = 1.0
T = 2*math.pi


def push(x, y, on):
    return (-K*x, -K*y) if on else (0.0, 0.0)


def rk4(f, t, s, h, on):
    k1 = f(t, s, on)
    k2 = f(t + h/2, [a + h/2*b for a, b in zip(s, k1)], on)
    k3 = f(t + h/2, [a + h/2*b for a, b in zip(s, k2)], on)
    k4 = f(t + h, [a + h*b for a, b in zip(s, k3)], on)
    return [a + h/6*(b + 2*c + 2*d + e) for a, b, c, d, e in zip(s, k1, k2, k3, k4)]


# ---- (a) ALD: state x, y, px, py, Ax, Ay, then the radiated integrals E, Px, Py, J, and the centre's Ix, Iy
def rhs_a(tau):
    def f(t, s, on):
        x, y, px, py, Ax, Ay = s[:6]
        g = math.sqrt(1 + px*px + py*py)
        vx, vy = px/g, py/g
        Fx, Fy = push(x, y, on)
        vA = vx*Ax + vy*Ay                       # dgamma/dt
        P = tau*g*g*(Ax*Ax + Ay*Ay - vA*vA)
        # A = F - P v + tau (dgamma/dt A + gamma dA/dt)
        dAx = (Ax - Fx + P*vx - tau*vA*Ax)/(tau*g)
        dAy = (Ay - Fy + P*vy - tau*vA*Ay)/(tau*g)
        J = P*(x*vy - y*vx) + tau*g*(vx*Ay - vy*Ax)
        return [vx, vy, Ax, Ay, dAx, dAy, P, P*vx, P*vy, J, Fx, Fy]
    return f


def books_a(s, tau):
    x, y, px, py, Ax, Ay, E, Px, Py, J, Ix, Iy = s
    g = math.sqrt(1 + px*px + py*py)
    vx, vy = px/g, py/g
    ES = tau*g*(vx*Ax + vy*Ay)
    Sx, Sy = tau*g*Ax, tau*g*Ay
    return ((px*px + py*py)/(g + 1) + K*(x*x + y*y)/2 - ES + E,
            (px - Sx + Px - Ix, py - Sy + Py - Iy),
            (x*py - y*px) - (x*Sy - y*Sx) + J,
            ES, E, J)


# ---- (b) reservoir from the push: state x, y, Pi_x, Pi_y, then E_b, Px, Py, J_b, Ix, Iy, E_act, J_act
def momentum_b(x, y, Pix, Piy, tau, on):
    Fx, Fy = push(x, y, on)
    px, py = Pix, Piy
    for _ in range(60):
        g = math.sqrt(1 + px*px + py*py)
        nx, ny = Pix + tau*g*Fx, Piy + tau*g*Fy
        if abs(nx - px) + abs(ny - py) < 1e-17:
            break
        px, py = nx, ny
    g = math.sqrt(1 + px*px + py*py)
    return px, py, g, Fx, Fy


def rhs_b(tau):
    def f(t, s, on):
        x, y, Pix, Piy = s[:4]
        px, py, g, Fx, Fy = momentum_b(x, y, Pix, Piy, tau, on)
        vx, vy = px/g, py/g
        vF = vx*Fx + vy*Fy
        Pb = tau*g*g*(Fx*Fx + Fy*Fy - vF*vF)
        dPix, dPiy = Fx - Pb*vx, Fy - Pb*vy
        # the node's actual dp/dt = dPi/dt + tau d(gamma F)/dt, dF/dt = -K v, dgamma/dt = v.(dp/dt)
        dFx, dFy = (-K*vx, -K*vy) if on else (0.0, 0.0)
        Bx, By = dPix + tau*g*dFx, dPiy + tau*g*dFy
        gd = (vx*Bx + vy*By)/(1 - tau*vF)
        Ax, Ay = Bx + tau*gd*Fx, By + tau*gd*Fy
        Pact = tau*g*g*(Ax*Ax + Ay*Ay - gd*gd)
        Lv = x*vy - y*vx
        Jb = Pb*Lv + tau*g*(vx*Fy - vy*Fx)
        Jact = Pact*Lv + tau*g*(vx*Ay - vy*Ax)
        return [vx, vy, dPix, dPiy, Pb, Pb*vx, Pb*vy, Jb, Fx, Fy, Pact, Jact]
    return f


def state_b(s, tau, on):
    """r, p and the actual acceleration A of a (b) state — the hand-off to (a)."""
    x, y = s[0], s[1]
    px, py, g, Fx, Fy = momentum_b(x, y, s[2], s[3], tau, on)
    d = rhs_b(tau)(0, s, on)
    vx, vy = px/g, py/g
    dFx, dFy = (-K*vx, -K*vy) if on else (0.0, 0.0)
    Bx, By = d[2] + tau*g*dFx, d[3] + tau*g*dFy
    gd = (vx*Bx + vy*By)/(1 - tau*(vx*Fx + vy*Fy))
    return x, y, px, py, Bx + tau*gd*Fx, By + tau*gd*Fy


def books_b(s, tau, on):
    x, y, Pix, Piy, E, Px, Py, J, Ix, Iy, Eact, Jact = s
    px, py, g, Fx, Fy = momentum_b(x, y, Pix, Piy, tau, on)
    vx, vy = px/g, py/g
    ES = tau*g*(vx*Fx + vy*Fy)
    Sx, Sy = tau*g*Fx, tau*g*Fy
    return ((px*px + py*py)/(g + 1) + K*(x*x + y*y)/2 - ES + E,
            (px - Sx + Px - Ix, py - Sy + Py - Iy),
            (x*py - y*px) - (x*Sy - y*Sx) + J,
            ES, E, J, Eact, Jact)


def run(case, x0, y0, px0, py0, release, tau, periods):
    tend = periods*T
    # (b) forward from t = 0 (for the release, the push switches on at t = 0+: Pi = p - p_S is continuous, p is kicked)
    nb = int(periods*4000)
    hb = tend/nb
    fb = rhs_b(tau)
    sb = [x0, y0, px0, py0] + [0.0]*8
    b0 = books_b(sb, tau, True)
    ESmax, E1, s_t1, t1 = 0.0, None, None, None
    for i in range(nb):
        sb = rk4(fb, i*hb, sb, hb, True)
        bk = books_b(sb, tau, True)
        ESmax = max(ESmax, abs(bk[3]))
        if i + 1 == nb//periods:
            E1 = bk[4]
        if s_t1 is None and (i + 1)*hb >= 40*tau:
            s_t1, t1 = list(sb), (i + 1)*hb
    b1 = books_b(sb, tau, True)
    Erad, Jrad = b1[4], b1[5]
    kick = math.hypot(*momentum_b(x0, y0, px0, py0, tau, True)[:2]) - math.hypot(px0, py0)

    # (a) backward from (b)'s end state, h = tau/4, through t = 0 and (release) on to t = -20 tau
    fa = rhs_a(tau)
    ha = tau/4
    na = int(round(tend/ha))
    sa = list(state_b(sb, tau, True)) + [0.0]*6
    a1 = books_a(sa, tau)
    for i in range(na):
        t = tend - i*ha
        sa = rk4(fa, t, sa, -ha, True)
    a0 = books_a(sa, tau)
    at0 = list(sa)
    pre = None
    if release:
        # runaway-free (a) through the release: backward from (b) at t1 = 40 tau (off-manifold error decays as e^-40)
        n1 = math.ceil(t1/(tau/4))
        h1 = t1/n1
        s = list(state_b(s_t1, tau, True)) + [0.0]*6
        for i in range(n1):
            s = rk4(fa, t1 - i*h1, s, -h1, True)
        F0 = K*math.hypot(x0, y0)
        A0 = math.hypot(s[4], s[5])
        p0 = math.hypot(s[2], s[3])
        dr0 = math.hypot(s[0] - x0, s[1] - y0)/math.hypot(x0, y0)
        prof = {}
        for j in range(80):
            s = rk4(fa, -j*ha, s, -ha, False)
            k = (j + 1)/4
            if k in (1, 2, 5):
                prof[k] = math.hypot(s[4], s[5])/A0
        pre = (A0/F0, prof, p0, math.hypot(s[2], s[3]), tau*F0, dr0)

    # (a) forward, the runaway: from the runaway-free state at t = 0, and from the naive A = F
    def runaway(s):
        s = list(s)
        Amax = 10*K*math.hypot(x0, y0) + 1
        for i in range(int(200*4)):
            s = rk4(fa, i*ha, s, ha, True)
            if math.hypot(s[4], s[5]) > Amax or not math.isfinite(s[4]):
                return (i + 1)*ha
        return None
    Fx, Fy = push(at0[0], at0[1], True)
    t_exact = runaway(at0)
    t_naive = runaway([x0, y0, px0, py0, Fx, Fy] + [0.0]*6)

    def ang(d, J):
        return f"{d/J:+.1e}" if abs(J) > 1e-30 else "  —"
    E0 = b0[0]
    print(f"{case}   tau = {tau:g}   {periods} periods   radiated {Erad/E0:.3f} of the initial energy")
    print(f"  (b) own books:     energy {(b1[0]-b0[0])/Erad:+.1e}   momentum {math.hypot(b1[1][0]-b0[1][0], b1[1][1]-b0[1][1])/Erad:.1e}"
          f"   angular {ang(b1[2]-b0[2], Jrad)}")
    print(f"      honest books (actual radiation):  energy {(b1[0]-b0[0]-Erad+b1[6])/b1[6]:+.1e}   angular {ang(b1[2]-b0[2]-Jrad+b1[7], b1[7])}")
    print(f"      reservoir |E_S| max = {ESmax/E1:.3f} of the first period's radiated energy")
    if release:
        print(f"      release kick |dp| = {kick:.4e}  (tau F0 = {tau*K*math.hypot(x0, y0):.4e})")
    print(f"  (a) runaway-free books (backward):  energy {(a0[0]-a1[0])/Erad:+.1e}   momentum {math.hypot(a0[1][0]-a1[1][0], a0[1][1]-a1[1][1])/Erad:.1e}"
          f"   angular {ang(a0[2]-a1[2], Jrad)}")
    dr = math.hypot(at0[0]-x0, at0[1]-y0)/math.hypot(x0, y0)
    print(f"      (a) vs (b) after {periods} periods: |dr|/r0 = {dr:.1e}")
    print(f"      forward runaway: from the runaway-free state at {t_exact/tau:.0f} tau, from A = F at {t_naive/tau:.0f} tau"
          f"  (period {T/tau:.0f} tau)")
    if pre:
        A0F0, prof, p0, pinf, tF, dr0 = pre
        print(f"      pre-acceleration: |A(0)|/F0 = {A0F0:.4f};  |A(-k tau)|/|A(0)| "
              + ", ".join(f"k={k:g}: {v:.4f}" for k, v in prof.items()) + f"  (e^-1, e^-2, e^-5 = 0.3679, 0.1353, 0.0067)")
        print(f"      |p(0)| = {p0:.4e} gathered before release (tau F0 = {tF:.4e});  |p(-20 tau)| = {pinf:.1e};  |r(0) - r0|/r0 = {dr0:.1e}")
    print(flush=True)


if __name__ == "__main__":
    quick = len(sys.argv) > 1 and sys.argv[1] == "quick"
    taus = (1e-2,) if quick else (1e-2, 1e-3)
    for tau in taus:
        periods = 20
        for name, beta in (("circular", 0.01), ("circular", 0.3)):
            g = 1/math.sqrt(1 - beta*beta)
            r0 = beta*math.sqrt(g/K)                     # gamma v^2 / r = K r
            run(f"circular beta {beta}", r0, 0.0, 0.0, g*beta, False, tau, periods)
        for a in (0.01, 0.3):
            run(f"ellipse 2:1 a {a}", a, 0.0, 0.0, a/2, False, tau, periods)
        for a in (0.01, 0.3):
            run(f"release from rest at r0 {a}", a, 0.0, 0.0, 0.0, True, tau, periods)
