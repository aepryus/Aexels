"""Node side for a general prescribed orbit, ItL as written: recoil -P beta
(eq:Fback, magnitude P v against the motion) plus S5.3's bridge share
P/(gamma^2 v) against the motion = P/v along -v_hat, P(t) the instantaneous
Lienard power (ItL eq:power).  Angular momentum lost per unit time:
<P (r x v)_z / v^2>.  Reported as a ratio to <P>/W.  Also: the normalization
check of angmom.py's radiation-side P against <Lienard P>.  c = W = 1, q = 1."""
import numpy as np
from angmom import harmonics

def lienard(a, b, t):
    v = np.stack([-a*np.sin(t), b*np.cos(t), 0*t], -1)
    acc = np.stack([-a*np.cos(t), -b*np.sin(t), 0*t], -1)
    v2 = np.sum(v*v, -1)
    g2 = 1/(1 - v2)
    cr = np.cross(v, acc)
    P = (2/3)*g2**3*(np.sum(acc*acc, -1) - np.sum(cr*cr, -1))
    r = np.stack([a*np.cos(t), b*np.sin(t), 0*t], -1)
    rxv = np.cross(r, v)[:, 2]
    return P, v2, rxv

t = 2*np.pi*np.arange(4096)/4096
for name, a, b, J_rad in (("circular", 0.01, 0.01, 1.0), ("circular", 0.6, 0.6, 1.0),
                          ("ellipse 2:1", 0.01, 0.005, 0.80000899897617),
                          ("ellipse 2:1", 0.3, 0.15, 0.80721180880975),
                          ("ellipse 2:1", 0.6, 0.3, None)):
    P, v2, rxv = lienard(a, b, t)
    node = np.mean(P*rxv/v2)/np.mean(P)
    Prad = harmonics(a, b, 48, 32, 512, 80)[0]
    norm = (2*Prad/(4*np.pi))/np.mean(P)
    if J_rad is None:
        P_, Js, Jo, _, _ = harmonics(a, b, 48, 32, 512, 80); J_rad = (Js+Jo)/P_
    print(f"{name:<12} beta {a:<5} node side (recoil + bridge, along -v) {node:.10f}   radiation {J_rad:.10f}   "
          f"P_rad/<P_Lienard> {norm:.12f}")
k = 2*2*1/(4+1)
print(f"slow-limit closed forms, a:b = 2:1: node 2 - 2ab/(a^2+b^2) = {2-k:.4f}; radiation 2ab/(a^2+b^2) = {k:.4f}")
