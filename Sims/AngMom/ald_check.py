"""Cross-check: time-averaged torque of the relativistic Abraham-Lorentz-Dirac
force on the prescribed orbit vs the radiated J from angmom.py (classical
conservation: the Schott term is a total derivative and averages out over a
period).  Metric (+,-,-,-): F^mu = (2/3) q^2 [u''^mu - a^2 u^mu], dp/dt = F/gamma.
Spectral differentiation in t.  c = W = q = 1."""
import numpy as np
from angmom import harmonics

def Dt(f, n):
    k = np.fft.fftfreq(n, d=1.0/n)
    return np.real(np.fft.ifft(1j*k[:, None]*np.fft.fft(f, axis=0), axis=0))

N = 4096
t = 2*np.pi*np.arange(N)/N
for a, b in ((0.6, 0.6), (0.01, 0.005), (0.3, 0.15), (0.6, 0.3)):
    r = np.stack([a*np.cos(t), b*np.sin(t)], -1)
    v = np.stack([-a*np.sin(t), b*np.cos(t)], -1)
    g = 1/np.sqrt(1 - np.sum(v*v, -1))
    u = np.column_stack([g, g[:, None]*v])                 # (u0, ux, uy)
    du = g[:, None]*Dt(u, N)                               # du/dtau
    ddu = g[:, None]*Dt(du, N)
    a2 = np.sum(du[:, 1:]**2, -1) - du[:, 0]**2
    F = (2/3)*(ddu - a2[:, None]*u)
    f = F[:, 1:]/g[:, None]
    torque = r[:, 0]*f[:, 1] - r[:, 1]*f[:, 0]
    P = (2/3)*a2                                           # Lienard: P = (2/3) a^2 (invariant)
    P_, Js, Jo, _, _ = harmonics(a, b, 48, 32, 512, 80)
    print(f"a {a:<5} b {b:<6} ALD <torque>/(<P>/W) = {-np.mean(torque)/np.mean(P):.10f}   radiated J/(P/W) = {(Js+Jo)/P_:.10f}")
