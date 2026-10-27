"""Node-side books for a prescribed orbit under a candidate reaction-force law.

Any candidate f(t) (force on the node per unit medium time) is scored against
the radiation over one period, three books at once:
    energy    -<f.v>      / <P>        (radiation carries <P>)
    momentum  -<f>        / <P>        (radiation carries <P beta>, eq:mom_flux)
    angular   -<(r x f)_z> / (<P>/W)   (radiation carries angmom.py's J)
Built-in candidates:
    s53  — ItL as written: recoil -P beta (eq:Fback) + the S5.3 bridge share
           P/(gamma^2 v) against the motion = P/v along -v_hat, P the
           instantaneous Lienard power (eq:power).
    ald  — the relativistic Abraham-Lorentz-Dirac force (metric +,-,-,-:
           F^mu = (2/3)q^2 [u''^mu - a^2 u^mu], f = F/gamma).
To test a new delivery rule, add a function (t, r, v, acc) -> f and list it
in CANDIDATES.  c = W = q = 1; spectral differentiation in t.
"""
import numpy as np
from angmom import harmonics

N = 4096
t = 2*np.pi*np.arange(N)/N


def Dt(f):
    k = np.fft.fftfreq(N, d=1.0/N)
    return np.real(np.fft.ifft(1j*k[:, None]*np.fft.fft(f, axis=0), axis=0))


def lienard(v, acc):
    g2 = 1/(1 - np.sum(v*v, -1))
    cr = v[:, 0]*acc[:, 1] - v[:, 1]*acc[:, 0]
    return (2/3)*g2**3*(np.sum(acc*acc, -1) - cr**2)


def s53(r, v, acc):
    P = lienard(v, acc)
    v2 = np.sum(v*v, -1)
    return -(P/v2)[:, None]*v


def ald(r, v, acc):
    g = 1/np.sqrt(1 - np.sum(v*v, -1))
    u = np.column_stack([g, g[:, None]*v])
    du = g[:, None]*Dt(u)
    ddu = g[:, None]*Dt(du)
    a2 = np.sum(du[:, 1:]**2, -1) - du[:, 0]**2
    F = (2/3)*(ddu - a2[:, None]*u)
    return F[:, 1:]/g[:, None]


CANDIDATES = [("S5.3 as written", s53), ("ALD", ald)]


def books(a, b):
    r = np.stack([a*np.cos(t), b*np.sin(t)], -1)
    v = np.stack([-a*np.sin(t), b*np.cos(t)], -1)
    acc = -r
    P = lienard(v, acc)
    mP = np.mean(P)
    Pr, Js, Jo, _, _ = harmonics(a, b, 48, 32, 512, 80)
    out = []
    for name, law in CANDIDATES:
        f = law(r, v, acc)
        energy = -np.mean(np.sum(f*v, -1))/mP
        mom = -np.mean(f, axis=0)/mP
        ang = -np.mean(r[:, 0]*f[:, 1] - r[:, 1]*f[:, 0])/mP
        out.append((name, energy, np.max(np.abs(mom)), ang))
    radP = (2*Pr/(4*np.pi))/mP
    return out, (Js+Jo)/Pr, radP


if __name__ == "__main__":
    print("books per period; radiation targets: energy 1, momentum 0 (closed orbit), angular = radiated J/(P/W)")
    for name, a, b in (("circular", 0.01, 0.01), ("circular", 0.6, 0.6),
                       ("ellipse 2:1", 0.01, 0.005), ("ellipse 2:1", 0.3, 0.15), ("ellipse 2:1", 0.6, 0.3)):
        out, Jrad, radP = books(a, b)
        print(f"{name} beta {a}: radiation J/(P/W) = {Jrad:.10f}   (radiation P / <Lienard P> = {radP:.12f})")
        for cname, e, m, ang in out:
            print(f"    {cname:<16} energy {e:.10f}   |momentum| {m:.1e}   angular {ang:.10f}")
    k = 2*2*1/(4+1)
    print(f"slow-limit closed forms, a:b = 2:1: S5.3 angular 2 - 2ab/(a^2+b^2) = {2-k:.4f}; radiation 2ab/(a^2+b^2) = {k:.4f}")
