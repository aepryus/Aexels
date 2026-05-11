The cupola algorithm fires test pings outward from a point source at rest in the lab while the aether streams past at velocity $\beta c$.  Each ping carries a cupola vector $\mathbf{C} = c\,\hat{n}_{em} - \mathbf{v}_{src}$ — the medium-frame ray direction minus the source's lab-frame velocity — and the question is whether depositing $|\mathbf{C}|/R$ along each ping's path reproduces the Liénard–Wiechert field magnitude.

The lab answers it visually.

  - **Analytic disc** (rainbow background): the closed-form Liénard–Wiechert intensity $|E|(R,\theta) \propto (1-\beta^2)\,|\hat{n}-\beta|/(\kappa^3 R^2)$ with $\kappa = 1-\hat{n}\cdot\beta$, rendered straight from the formula.  This is the target.

  - **Cupola sensor field**: a 128×240 polar $(R,\theta)$ colormap rebuilt off-thread on every commit.  A phantom calc fires 8500 pings on an isolated universe and atomically deposits $|\mathbf{C}|/R$ into the cell each ping passes through; the result *is* the cupola algorithm's output, no kernels or curvature corrections.

  - **Pings**: the live auto-fire stream rendered as dots over the disc.  Each ping body is shaded by sampling the cupola sensor field at its current position.  When the cupola algorithm matches LW, ping bodies converge onto the disc band beneath them; when toggles disagree (e.g. **magnitude** off, or **aberration** off at $\beta>0$), they visibly diverge.

The asymmetry is the most striking thing once aberration is on.  Rule-3 emission density $\rho(\theta,\beta) = (1-\beta^2)/(1-\beta\cos\theta)^2$ collapses the forward channel — at $\beta=0.7$ the forward-to-backward ping ratio is about 30:1, and at $\beta=0.99$ it's nearly total.  The retrograde dominance is *exactly* what mass inflation $\eta = \gamma\eta_0$ (Rule 4) requires for momentum balance.  Rule 3 forces Rule 4.

## Controls

  - **velocity**: aether velocity as % of $c$.  Drag updates only the analytic disc; on release, the cupola model rebuilds on a phantom universe and swaps in.
  - **magnitude**: applies the $|\mathbf{C}|$ scaling.  Cupola arms render at length proportional to magnitude, and the deposited field weight is $|\mathbf{C}|/R$ rather than $1/R$.
  - **aberration**: enables Rule-3 emission density on the source.  Off ⇒ uniform-$\theta$ medium-frame emission.
  - **full pings**: renders each ping as body + cupola arm + head, showing the cupola vector itself.  Off shows just the body.
  - **analytic disc**: the LW closed-form reference.  Off shows the cupola algorithm's output unaided.

## Caveats

The lab is 2D, but Rule 3 is the 3D angular density.  The C engine inverse-CDFs that distribution at lab-frame angles directly, rather than uniform-$\theta'$ in the source rest frame followed by Lorentz aberration — the two recipes produce different 2D densities, and the 3D Rule-3 form is what matches the disc.

At extreme $\beta$ a geometric artifact appears in the forward direction: the slow-direction wavefront moves at $(1-\beta)c$, so at $\beta=0.99$ the forward portion of an 8500-ping pulse only reaches $R\approx 30$ in the sampling window, and the pixel resolution of the forward beam isn't enough to populate it cleanly.  The disc and the algorithm both still agree there in principle — it's a sampling limitation, not a model failure.
