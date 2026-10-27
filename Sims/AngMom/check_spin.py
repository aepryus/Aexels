"""Independent route for the circular-orbit spin share: sample X = D_perp/kappa
directly (no kappa cancellation) on a UNIFORM observer-time grid via Newton-
inverted retarded times, FFT over observer time, Gauss-Legendre in cos(theta).
Circular orbit => phi-independent; phi = 0.  c = W = 1."""
import sys
import numpy as np

def spin_share(beta, n_theta, n_obs):
    mu, wmu = np.polynomial.legendre.leggauss(n_theta)
    st = np.sqrt(1 - mu**2)
    T = 2*np.pi
    tobs = T*np.arange(n_obs)/n_obs
    P = S = 0.0
    for i in range(n_theta):
        n = np.array([st[i], 0.0, mu[i]])
        # t_obs = t_e - n.r(t_e), n.r = beta sin(theta) cos(t_e)
        te = tobs.copy()
        for _ in range(60):
            f = te - beta*st[i]*np.cos(te) - tobs
            te -= f/(1 + beta*st[i]*np.sin(te))
        bvec = np.stack([-beta*np.sin(te), beta*np.cos(te), 0*te], axis=-1)
        D = n[None, :] - bvec
        kappa = D @ n
        X = (D - kappa[:, None]*n[None, :])/kappa[:, None]
        # X(t) = sum_m c_m e^{-imt} + c.c.  ->  c_m = (1/N) sum X e^{+imt}
        C = np.fft.ifft(X, axis=0)          # ifft: (1/N) sum x e^{+i 2 pi k m / N}
        M = n_obs//2 - 1
        c = C[1:M+1]
        m = np.arange(1, M+1)
        c2 = np.sum(np.abs(c)**2, axis=1)
        spin = 2*np.imag(np.conj(c[:, 0])*c[:, 1])
        P += wmu[i]*np.sum(m**2*c2)
        S += wmu[i]*np.sum(m*spin)
    return S/P

for beta in (0.01, 0.3, 0.6):
    for nth, nobs in ((48, 512), (96, 2048)):
        print(f"beta {beta}: n_theta {nth}, n_obs {nobs}: spin share {spin_share(beta, nth, nobs):.12f}")
