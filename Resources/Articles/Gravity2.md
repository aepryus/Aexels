# Gravity II

## Special Relativity

Standard General Relativity notation can be used to describe Special Relativity.  Consider a spaceship traveling at velocity 𝑐/2 over flat space in our universe.

There is a convention in General Relativity that relates the dilation and contraction of a particular inertial frame (called the proper frame) to an inertial frame at infinity (called the coordinate frame).

This convention calculates how time and distance in the stationary reference frame appear when measured by instruments in the moving frame. The observed time interval is multiplied by the speed of light to convert it to an equivalent distance. This time-derived distance is then subtracted from the observed spatial measurement. The resulting difference represents the fundamental quantity 'spacetime' and is denoted by ds.

For example, recall the Lorentz factor:

$$
\gamma(v) = \frac{1}{\sqrt{1 - \frac{v^2}{c^2}}}
$$

For a spaceship traveling at 𝑐/2, γ will be approximately equal to 1.155.  Time will be slowed in the moving ship, so a second at infinity will only appear to be 0.866 seconds long.  The meter stick will be contracted on the moving space ship and so a meter stick at infinity will appear to be 1.155 meters long.

We can then calculate the 'spacetime' by taking x - 𝑐 t ≈ 1.155 - 0.866 𝑐.

Using the standard General Relativity notation this calculation can be represented as:

$$
ds^2 = -\frac{1}{\gamma(v)^2} c^2 dt^2 + \gamma(v)^2 dr^2
$$

## General Relativity

After many years and the help of a number of mathematicians Einstein developed his field equations:

$$
G_{\mu\nu} = \frac{8\pi G}{c^4} T_{\mu\nu}
$$

The G and T elements here represent 4 by 4 tensors, each is a function of a 4D point in spacetime, resulting in a 10 equation 10 unknown partial differential equation on a 4 dimensional manifold.  After a century, these equations have been solved for only a handful of highly simple and symmetric geometries.

One of those solutions is the Schwarzschild Metric, which describes the spacetime geometry exterior to a perfect stationary non-rotating spherical mass.  The Schwarzschild Metric is as follows:

$$
ds^2 = -\left(1 - \frac{2GM}{rc^2}\right) c^2 dt^2 + \left(1 - \frac{2GM}{rc^2}\right)^{-1} dr^2 + r^2(d\theta^2 + \sin^2\theta\, d\phi^2)
$$

At first glance this equation looks quite complicated.  However, there are a few ways we can simplify it.  The metric uses spherical coordinates.  The last term involving the dθ and dϕ angles is exactly the same for flat spherical coordinates and as such there is no interesting physics going on there, as such that term can be ignored and the focus can be placed solely on the radial motion.

Previously, in the Four Leafs article we used classical mechanics to derive the escape velocity around a spherical mass.  The result was:

$$
v_e = \sqrt{\frac{2GM}{r}}
$$

At this point, looking at the Lorentz factor, the escape velocity and the Schwarzschild metric minus the angles term, an interesting substitution can be made.  If one substitutes in γ(vₑ) (and ignores the angles term), the Schwarzschild metric becomes:

$$
ds^2 = -\frac{1}{\gamma(v_e)^2} c^2 dt^2 + \gamma(v_e)^2 dr^2
$$

Suddenly, the Schwarzschild metric doesn't look too complicated and one might also note that it is precisely the same as the Special Relativity equation from above.  An obvious physical interpretation pops out.  This is just a static system with an aether flowing through it at the escape velocity and as such it behaves exactly like a translating system on flat space.

SR = GR

A much stronger version of the equivalence principle appears, that a system in free fall is precisely the same as a system in flat space.  And it doesn't appear as an axiom, but a transparently obvious consequence of the physical mechanisms in play.

Furthermore, the dr component in this equation simply represents the length contraction of meter sticks at that point (because of the flow of aether).  As such there is zero warping of the aether and there is not even any compression of the aether.  Not only is space flat in Universe X, but the aether is flat also.  'Space' isn't warping, rather meter sticks at those points are contracting making the distance from that point to the center to appear to be longer than it should be because it's being measured by shrunken meter sticks.

## Squish

According to the Gravity I article, gravity is not a force on other masses, but rather is a force on the aexels themselves; this creates an issue.  If the aexels are flowing in at the escape velocity then we can multiply the escape velocity by the surface area of each shell and see that the flux is not constant:

$$
\phi(r) = 4\pi r^2 \cdot \sqrt{\frac{2GM}{r}} = 4\pi \cdot \sqrt{2GM} \cdot r^{3/2}
$$

This varies with r^(3/2).  There is no way the aexels can be conserved.  There is no way Gauss' law can apply.  In Universe X, aexels do not satisfy Gauss' law.  They are very fragile and when a pressure is applied to them beyond a certain threshold they get squished and disappear entirely.  This allows for the aexel density to stay largely fixed.  (For a much more thorough discussion of how this mechanism was discovered, refer to the 'Squish' article on the 'Path of Discovery'.)

## Accelerant

Hyle pulls on the aexels themselves inducing an acceleration:

A = GM/r².

Given our experience from Electromagnetism of how to construct a 1/r² force, it would be possible to conjecture that there is a similar mechanism at use here.  Theoretically, each bit of hyle could send out g-pings in all directions that apply some sort of acceleration to the aexels themselves.  These g-pings fall off at 1 / 4pi r², giving us our perfect 1/r² force on the aexels.

However, while that works conceptually, logistically, it's intractable.  Unlike E&M which is generally quite short range, gravity has to work across the entire Universe.  And as mentioned in the Kinematics article, E&M phenomena are huge compared to gravity.  The mechanisms in play in E&M can be much more complex, gravity needs to be simple.  And since the aexels are so small and since each needs to get hit at any distance from any bit of hyle, the amount of 'particles' that need to be tracked is just ridiculous.  But, there are actually two ways to get a 1/r² effect.  Certainly, a volley of dust sent out everywhere can achieve the effect.  But, as the InsideOut lab pointed out, for a fluid being destroyed and pulled in, the velocity of the fluid will also create a 1/r² effect.  Essentially, it's the removal of fluid that is spreading out a 1/r².

Of course this removal creates a velocity and not an acceleration.  However, this leaves an entirely tractable way of calculating the gravity throughout the entire universe at O(n).

Imagine each aexel holds a fluid called 'accelerant'.  Hyle doesn't destroy aexels, it destroys accelerant.  This accelerant then flows to replace the destroyed accelerant.  The velocity of the accelerant flowing causes an acceleration on the aexels it is flowing through.

Now the gravity problem goes from being an absurd tracking of an absurd amount of g-pings traveling throughout the entire universe, to a simple local pressure equalization problem of the accelerant.

Now, of course, this is a leap well beyond anything previous in Universe X.  And the reason for making this leap is novel, the concern for the computational strain of Universe X itself.  However, even if this is entirely false, this concept could greatly speed the modeling of gravitational phenomena.  It takes a problem naively implemented as O(n²) that is reduced to  O(n ln(n)) by using approximate methods and replaces it with a method that is O(n) and precise, not an approximation any longer.

Claude Opus 4.7 Stub - v4.5 Addendum ===================

## The Field Equations

The articles thus far have described the gravitational mechanism qualitatively: hyle destroys accelerant; the resulting flow of accelerant induces an acceleration in the aexels; matter sitting atop those aexels comes along for the ride.  We can now write this down as two partial differential equations, one for each fluid.

## The Accelerant Equation

Let $\mathbf{u}$ be the velocity field of the accelerant and $\rho$ the density of hyle.  The accelerant is approximately incompressible; antihyle creates accelerant at the rate hyle destroys it, and the spawn / squish mechanism keeps the underlying aexel density essentially fixed.

For an incompressible fluid with sinks (hyle) and sources (antihyle), the divergence of the velocity field equals the net source density.  Choosing the proportionality constant so the eventual answers match the empirical strength of gravity:

$$
\nabla \cdot \mathbf{u} = -4\pi G \rho
$$

This fixes the *divergence* of the accelerant — how much flows in — but a vector field is not determined by its divergence alone; its *curl* must also be specified.  For a single stationary mass there is no rotational source, so we take the flow to be irrotational:

$$
\nabla \times \mathbf{u} = 0 \qquad \text{(static, non-rotating closure)}
$$

With this closure the accelerant flow is purely a gradient flow.  Equivalently, $\mathbf{u} = -\nabla \Phi$ where $\nabla^2 \Phi = 4\pi G \rho$.  This is Poisson's equation in fluid clothing.  For a spherical mass $M$, Gauss's law gives:

$$
\mathbf{u} = -\frac{GM}{r^2} \hat{\mathbf{r}}
$$

The accelerant velocity at any point is, numerically and dimensionally, the Newtonian gravitational acceleration at that point.  Newton's $1/r^2$ law is not an axiom here; it is the equilibrium configuration of an incompressible flow sinking into a localized hyle sink.  The accelerant's job is to be Newton.

**Scope of this closure.**  Two properties of the equation above must be named honestly, because each marks an edge of validity rather than a finished result:

- *It is instantaneous.*  Poisson's equation is elliptic; a change in $\rho$ here re-solves the field everywhere at once.  That is Newton's own action-at-a-distance — the very absurdity quoted in Gravity I — re-entering through the accelerant.  The empirical fact that gravity propagates at $c$ (LIGO, 2017) is therefore *not yet honored* by this equation.  Honoring it requires the accelerant to be slightly *compressible*, so that disturbances travel as a wave at a finite speed (the accelerant's sound speed, which must come out to $c$).  See *Beyond the Static Sphere* below.

- *It forbids rotation.*  The closure $\nabla\times\mathbf{u}=0$ is a *choice*, valid only when nothing rotational sources the flow.  A spinning or moving mass does source a rotational component, and a strictly curl-free field cannot represent it.  This is why the static system below recovers Schwarzschild exactly and **cannot reach Kerr at all** — not approximately, but structurally.  The missing piece is a vorticity (gravitomagnetic) sector, also deferred to *Beyond the Static Sphere*.

## The Aexel Equation

The accelerant velocity at a point does not directly accelerate matter; it accelerates the aexels at that point.  The promotion is one to one: the velocity of the accelerant at $\mathbf{x}$ equals the acceleration imparted to whatever aexel happens to be sitting at $\mathbf{x}$.

In Eulerian form, the velocity field $\mathbf{v}_a$ of the aexels obeys:

$$
\frac{\partial \mathbf{v}_a}{\partial t} + (\mathbf{v}_a \cdot \nabla) \mathbf{v}_a = \mathbf{u}
$$

The left side is the material derivative $D \mathbf{v}_a / D t$, the acceleration of an aexel as it moves through space.  The right side is the local accelerant velocity.  This is the Aexel Equation.

Note that the convective term $(\mathbf{v}_a\cdot\nabla)\mathbf{v}_a$ is **quadratic** in $\mathbf{v}_a$.  Two consequences follow that will matter later: aexel velocities do **not** superpose (only the linear accelerant field $\mathbf{u}$ does), and reversing a flow ($\mathbf{v}_a \to -\mathbf{v}_a$) does **not** produce another valid solution — a sink's inflow and a source's outflow are not mirror images.

## The Static Spherical Solution

For a stationary point mass $M$, the aexel field is steady and purely radial: $\mathbf{v}_a = v(r) \hat{\mathbf{r}}$.  The partial time derivative vanishes and the convective term reduces to $v\, (dv/dr)\, \hat{\mathbf{r}}$.  Setting this equal to $u_r = -GM/r^2$:

$$
\begin{aligned}
v \frac{dv}{dr} &= -\frac{GM}{r^2} \\
\\
\frac{1}{2} \frac{d(v^2)}{dr} &= -\frac{GM}{r^2} \\
\\
v^2 &= \frac{2GM}{r}
\end{aligned}
$$

The aexel velocity at radius $r$ is the escape velocity.  This is exactly the result obtained in the Floating Leaf article from the entirely different argument that a tennis ball falling from infinity must be co-moving with the aexels, so its impact velocity (the escape velocity) is the aexel velocity at the surface.  Two arguments, the same answer.  Floating Leaf is the integrated form of the Aexel Equation in spherical symmetry.

(One caution that the quadratic convective term forces: $v^2 = 2GM/r$ is the *integral* of the field along the path for a **point** mass.  It is **not** a pointwise rule that may be re-used by substituting a growing enclosed mass $M_\text{enc}(r)$ — doing so double-counts the work.  For any distributed source the Aexel Equation must be integrated directly.  This is the correction behind the cosmological coefficient in the Antimatter aside below.)

## Recovering Schwarzschild

A test particle held stationary on a platform at radius $r$ is *not* co-moving with the aexels; the aexels flow past it at $\mathbf{v}_a$, so the platform observer is translating at speed $|\mathbf{v}_a|$ relative to the aether.  All the standard Universe X consequences of translation now apply: the observer's clock animates at rate $1/\gamma$ and the observer's radial meter sticks contract by $1/\gamma$, where:

$$
\gamma^2 = \frac{1}{1 - v_a^2/c^2} = \frac{1}{1 - \frac{2GM}{rc^2}}
$$

The proper time interval at radius $r$ is $d\tau = dt/\gamma = \sqrt{1 - 2GM/rc^2}\, dt$.  This is the Schwarzschild $g_{tt}$ term, exactly.

For radial proper distance: each platform meter stick measures only $1/\gamma$ in the aether frame, so the proper distance spanning a coordinate $dr$ is $\gamma\, dr$.  This is the Schwarzschild $g_{rr}$ term, exactly.

Assembling:

$$
ds^2 = -\left(1 - \frac{2GM}{rc^2}\right) c^2 dt^2 + \left(1 - \frac{2GM}{rc^2}\right)^{-1} dr^2 + r^2 d\Omega^2
$$

This is the **Schwarzschild** metric — the exterior geometry of a stationary, non-rotating, spherical mass — recovered without any tensors, without the field equations of GR, without solving any four-dimensional ten-equation ten-unknown PDE on a curved manifold.  The metric drops out as the kinematic shadow of two simple 3D fluid equations on flat space.

It is worth being precise about what has and has not been shown.  What the two equations reproduce exactly is the **static, spherically symmetric** sector of General Relativity: Schwarzschild, and with it Newtonian gravity, gravitational time dilation, light bending and perihelion precession (these follow from the exact Schwarzschild form).  What they do **not** yet reach is the rest of GR — rotating sources (Kerr, frame-dragging), finite-speed propagation, and gravitational radiation — all of which live in the curl and the time-derivative that the static closure set to zero.  "SR = GR" is the right slogan for the static sphere; the general claim is an aspiration the next section scopes.

## Why It Works

The reason both Newton and Schwarzschild fall out cleanly is that they describe the same underlying mechanism in different limits.

Newton concerns the acceleration directly.  In Universe X the acceleration field is $\mathbf{u}$, and the Accelerant Equation gives $\mathbf{u} = -(GM/r^2) \hat{\mathbf{r}}$ for a point mass.  Newton is just the Accelerant Equation, untouched.

Schwarzschild concerns the kinematic consequences of matter sitting on aexels that have already acquired velocity $\mathbf{v}_a$.  Those consequences, dilation and contraction, depend only on $\mathbf{v}_a$, not on $\mathbf{u}$ directly.  The Aexel Equation provides the nonlinear $\mathbf{v}_a(\mathbf{u})$ relation; for the static spherical case, $v_a^2 = 2GM/r$.  Plugging that into the standard Universe X dilation formula reproduces the Schwarzschild metric.

Newton is the Accelerant Equation.  Schwarzschild is the Aexel Equation seen through the Lorentz factor.  Universe X has both because it has both fluids; that's why it can recover both without introducing either as a postulate.

## Beyond the Static Sphere

*(Provisional. The two equations above are established and self-consistent for the static, non-rotating sphere. This section sketches the two generalizations the static closure leaves out. Their structure is fixed by analogy with the accelerant's E&M cousin; the coupling coefficients marked below are not yet derived from the Universe X mechanism — that derivation, the "gravitational Rule 3," is the open calculation that this section depends on.)*

The static closure threw away two things: the curl of the accelerant, and its time derivative.  Restoring them is what would carry the framework from "Schwarzschild" to "General Relativity."

**Finite propagation.**  An incompressible accelerant gives the instantaneous elliptic equation.  Allowing slight compressibility turns the elliptic Poisson operator into a hyperbolic wave operator, so disturbances in the field propagate at a finite speed $c_g$:

$$
\frac{1}{c_g^2}\frac{\partial^2 \Phi}{\partial t^2} - \nabla^2 \Phi = -4\pi G\rho
$$

The empirical constraint is $c_g = c$ (LIGO/Virgo, GW170817).  In Universe X this should be a *consequence* — the accelerant's signal speed inherited from the same lattice that fixes the speed of light — rather than a number inserted by hand.  Establishing $c_g = c$ from the mechanism, not assuming it, is part of the open work.

**Rotation (the gravitomagnetic sector).**  A moving or spinning mass carries a mass current $\mathbf{j} = \rho\,\mathbf{v}$, and that current must source a *circulating* component of the accelerant that the curl-free closure forbids.  By direct analogy with the way a moving charge sources a magnetic field in the Electromagnetism article, introduce a gravitomagnetic field $\boldsymbol{\xi}$ alongside the (gravitoelectric) accelerant $\mathbf{u}$:

$$
\begin{aligned}
\nabla \cdot \mathbf{u} &= -4\pi G \rho \\
\nabla \times \mathbf{u} &= -\frac{\partial \boldsymbol{\xi}}{\partial t} \\
\nabla \cdot \boldsymbol{\xi} &= 0 \\
\nabla \times \boldsymbol{\xi} &= \kappa\,\frac{G}{c^2}\,\mathbf{j} + \frac{1}{c_g^2}\frac{\partial \mathbf{u}}{\partial t}
\end{aligned}
$$

with a force law on the aexels that now includes a velocity-dependent term,

$$
\mathbf{a} = \mathbf{u} + \mathbf{v}\times\boldsymbol{\xi},
$$

the $\mathbf{v}\times\boldsymbol{\xi}$ term being frame-dragging.  This is the standard gravitoelectromagnetic structure; with it, a spinning mass produces Lense–Thirring precession (the Gravity Probe B result) and the system can begin to approach the off-diagonal $g_{t\phi}$ terms of Kerr.

The constant $\kappa$ (the analogue of the factors $4$ and $2$ that appear in the standard linearized-GR version of these equations) is **inserted here, not derived**.  In E&M the corresponding factor was fixed by the cupola mechanism; the gravitational counterpart — deriving $\kappa$, and equivalently the deflection enhancement $\gamma(1+\beta^2)$ for a *moving* sink — is the single most leveraged open calculation in the gravity sector, because the same derivation also fixes the moving-source field, settles whether kinetic hyle gravitates as $\rho(1+\langle\beta^2\rangle)=\rho+3p/c^2$ (Tolman's active density, which would carry the interior toward the TOV equation), and underwrites the radiation sector.  Until it is done, the equations of this section are the *right shape* with an *unearned coupling*, and should be read as a program, not a result.

## An Aside on the Antimatter Case

Sign-flipping the source term handles the antimatter case discussed in the Darkness article:

$$
\nabla \cdot \mathbf{u} = +4\pi G \rho
$$

For a uniform density of antihyle dust, Gauss's law applied from any chosen origin gives $\mathbf{u} = +(4\pi G\rho/3)\, r\, \hat{\mathbf{r}}$.

The expansion rate must then be read off the **Aexel Equation**, not by mirroring the point-mass escape-velocity formula (which, as noted above, is not a pointwise law and double-counts when fed a growing enclosed mass).  The clean route uses homogeneity directly: the only steady velocity field consistent with a uniform medium is $\mathbf{v}_a = H\mathbf{x}$ about any origin, so $(\mathbf{v}_a\cdot\nabla)\mathbf{v}_a = H^2\mathbf{x}$, and the Aexel Equation $D\mathbf{v}_a/Dt = \mathbf{u}$ gives, in one line,

$$
H^2 \mathbf{x} = \frac{4\pi G\rho}{3}\,\mathbf{x}
\qquad\Longrightarrow\qquad
\boxed{\,H^2 = \frac{4\pi G\rho}{3}\,}
$$

Hubble's linear law $\mathbf{v}_a = H\mathbf{x}$ is thus not assumed but *derived* as the unique homogeneous steady solution, with the coefficient attached.  Note this is **half** the naive Friedmann coefficient $8\pi G\rho/3$: the factor of two is exactly the double-counting incurred by the mirrored escape-velocity shortcut, and the honest value is fixed — the normalization of $\nabla\cdot\mathbf{u}$ and the one-to-one $v\!\Rightarrow\!a$ promotion are both pinned by the static Schwarzschild sector, leaving no slack to restore it.  The same two PDEs handle both the local gravitational dynamics of stars and planets and the global behavior of antimatter dust between galaxies, with no additional machinery introduced.
