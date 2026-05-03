# Gravity II

## Special Relativity

Standard General Relativity notation can be used to describe Special Relativity.  Consider a spaceship traveling at velocity 𝑐/2 over flat space in our universe.

There is a convention in General Relativity that relates the dilation and contraction of a particular inertial frame (called the proper frame) to an inertial frame at infinity (called the coordinate frame).

This convention calculates how time and distance in the stationary reference frame appear when measured by instruments in the moving frame. The observed time interval is multiplied by the speed of light to convert it to an equivalent distance. This time-derived distance is then subtracted from the observed spatial measurement. The resulting difference represents the fundamental quantity 'spacetime' and is denoted by ds.

For example, recall the Lorentz factor:

![](tint:G2Eq01)

For a spaceship traveling at 𝑐/2, γ will be approximately equal to 1.155.  Time will be slowed in the moving ship, so a second at infinity will only appear to be 0.866 seconds long.  The meter stick will be contracted on the moving space ship and so a meter stick at infinity will appear to be 1.155 meters long.

We can then calculate the 'spacetime' by taking x - 𝑐 t ≈ 1.155 - 0.866 𝑐.

Using the standard General Relativity notation this calculation can be represented as:

![](tint:G2Eq02)

## General Relativity

After many years and the help of a number of mathematicians Einstein developed his field equations:

![](tint:G2Eq03)

The G and T elements here represent 4 by 4 tensors, each is a function of a 4D point in spacetime, resulting in a 10 equation 10 unknown partial differential equation on a 4 dimensional manifold.  After a century, these equations have been solved for only a handful of highly simple and symmetric geometries.

One of those solutions is the Schwarzschild Metric, which describes the spacetime geometry exterior to a perfect stationary non-rotating spherical mass.  The Schwarzschild Metric is as follows:

![](tint:G2Eq04)

At first glance this equation looks quite complicated.  However, there are a few ways we can simplify it.  The metric uses spherical coordinates.  The last term involving the dθ and dϕ angles is exactly the same for flat spherical coordinates and as such there is no interesting physics going on there, as such that term can be ignored and the focus can be placed solely on the radial motion.

Previously, in the Four Leafs article we used classical mechanics to derive the escape velocity around a spherical mass.  The result was:

![](tint:G2Eq05)

At this point, looking at the Lorentz factor, the escape velocity and the Schwarzschild metric minus the angles term, an interesting substitution can be made.  If one substitutes in γ(vₑ) (and ignores the angles term), the Schwarzschild metric becomes:

![](tint:G2Eq06)

Suddenly, the Schwarzschild metric doesn't look too complicated and one might also note that it is precisely the same as the Special Relativity equation from above.  An obvious physical interpretation pops out.  This is just a static system with an aether flowing through it at the escape velocity and as such it behaves exactly like a translating system on flat space.

SR = GR

A much stronger version of the equivalence principle appears, that a system in free fall is precisely the same as a system in flat space.  And it doesn't appear as an axiom, but a transparently obvious consequence of the physical mechanisms in play.

Furthermore, the dr component in this equation simply represents the length contraction of meter sticks at that point (because of the flow of aether).  As such there is zero warping of the aether and there is not even any compression of the aether.  Not only is space flat in Universe X, but the aether is flat also.  'Space' isn't warping, rather meter sticks at those points are contracting making the distance from that point to the center to appear to be longer than it should be because it's being measured by shrunken meter sticks.

## Squish

According to the Gravity I article, gravity is not a force on other masses, but rather is a force on the aexels themselves; this creates an issue.  If the aexels are flowing in at the escape velocity then we can multiply the escape velocity by the surface area of each shell and see that the flux is not constant:

![](tint:G2Eq07)

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
\begin{aligned}
\nabla \cdot \mathbf{u} &= -4\pi G \rho \\
\\
\nabla \times \mathbf{u} &= 0
\end{aligned}
$$

The second equation closes the system: with no rotational sources, the accelerant flow is purely a gradient flow.  Equivalently, $\mathbf{u} = -\nabla \Phi$ where $\nabla^2 \Phi = 4\pi G \rho$.  This is Poisson's equation in fluid clothing.  For a spherical mass $M$, Gauss's law gives:

$$
\mathbf{u} = -\frac{GM}{r^2} \hat{\mathbf{r}}
$$

The accelerant velocity at any point is, numerically and dimensionally, the Newtonian gravitational acceleration at that point.  Newton's $1/r^2$ law is not an axiom here; it is the equilibrium configuration of an incompressible flow sinking into a localized hyle sink.  The accelerant's job is to be Newton.

## The Aexel Equation

The accelerant velocity at a point does not directly accelerate matter; it accelerates the aexels at that point.  The promotion is one to one: the velocity of the accelerant at $\mathbf{x}$ equals the acceleration imparted to whatever aexel happens to be sitting at $\mathbf{x}$.

In Eulerian form, the velocity field $\mathbf{v}_a$ of the aexels obeys:

$$
\frac{\partial \mathbf{v}_a}{\partial t} + (\mathbf{v}_a \cdot \nabla) \mathbf{v}_a = \mathbf{u}
$$

The left side is the material derivative $D \mathbf{v}_a / D t$, the acceleration of an aexel as it moves through space.  The right side is the local accelerant velocity.  This is the Aexel Equation.

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

## Recovering Newton

A test particle in free fall co-moves with the aexels: $\mathbf{v}_{\text{ball}} = \mathbf{v}_a$.  Its acceleration is the material derivative of its velocity:

$$
\frac{D \mathbf{v}_{\text{ball}}}{D t} = \frac{D \mathbf{v}_a}{D t} = \mathbf{u} = -\frac{GM}{r^2} \hat{\mathbf{r}}
$$

Newton's gravitational acceleration is exactly the accelerant velocity.  This is the entire content of Newton in Universe X: every freely falling object inherits the local $\mathbf{u}$ through the aexels carrying it.

## Recovering General Relativity

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

This is the Schwarzschild metric, recovered without any tensors, without any field equations of GR, without solving any four dimensional ten-equation ten-unknown PDE on a curved manifold.  The metric drops out as the kinematic shadow of two simple 3D fluid equations on flat space.

## Why It Works

The reason both Newton and GR fall out cleanly is that they describe the same underlying mechanism in different limits.

Newton concerns the acceleration directly.  In Universe X the acceleration field is $\mathbf{u}$, and the Accelerant Equation gives $\mathbf{u} = -(GM/r^2) \hat{\mathbf{r}}$ for a point mass.  Newton is just the Accelerant Equation, untouched.

GR concerns the kinematic consequences of matter sitting on aexels that have already acquired velocity $\mathbf{v}_a$.  Those consequences, dilation and contraction, depend only on $\mathbf{v}_a$, not on $\mathbf{u}$ directly.  The Aexel Equation provides the nonlinear $\mathbf{v}_a(\mathbf{u})$ relation; for the static spherical case, $v_a^2 = 2GM/r$.  Plugging that into the standard Universe X dilation formula reproduces the Schwarzschild metric.

Newton is the Accelerant Equation.  GR is the Aexel Equation seen through the Lorentz factor.  Universe X has both because it has both fluids; that's why it can recover both theories without introducing either as a postulate.

## An Aside on the Antimatter Case

Sign-flipping the source term handles the antimatter case discussed in the Darkness article:

$$
\nabla \cdot \mathbf{u} = +4\pi G \rho
$$

For a uniform density of antihyle dust, by Gauss's law applied from any chosen origin, $\mathbf{u} = +(4\pi G\rho/3)\, r\, \hat{\mathbf{r}}$.  The Aexel Equation then gives a $v_a(r)$ growing linearly with $r$, reproducing the qualitative Hubble behavior of the Aexel Sources article on the Path of Discovery.  The same two PDEs handle both the local gravitational dynamics of stars and planets and the global behavior of antimatter dust between galaxies, with no additional machinery introduced.
