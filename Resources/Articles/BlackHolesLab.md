# Black Hole Lab

Two black holes orbit each other under the gravitational mechanism described in the Gravity II article.  Each frame the simulation:

1. Computes the accelerant potential $\Phi$ analytically per cell on a 256×256 GPU texture from the current black hole positions.
2. Computes $\mathbf{u} = -\nabla\Phi$ on the grid.
3. Computes the algebraic aether velocity field $\mathbf{v}_a = \sqrt{2|\Phi|} \cdot (-\nabla\Phi/|\nabla\Phi|)$ — the Floating Leaf equilibrium.
4. Samples $\mathbf{u}$ at each black hole's location and advances the black holes via leapfrog integration.
5. Advects three independent test-particle systems: aether parcels riding $\mathbf{v}_a$, accelerant parcels riding $\mathbf{u}$, and matter parcels with their own Galilean inertia integrating $\mathbf{u}$.

A viscosity slider applies an optional Stokes drag $-\gamma \mathbf{v}_{BH}$ to demonstrate inspiral and merger as effective dissipation.

## What this lab is

A real-time visualization of the **static-equilibrium predictions** of the accelerant model.  At every instant the aether is in algebraic equilibrium with the current mass distribution, recomputed each frame.  The three particle flows make the model's three distinct fields visible at once: the matter swarm has inertia and orbits, the aether parcels ride the equilibrium $\mathbf{v}_a$ (slower, smoother), the accelerant parcels ride $\mathbf{u}$ (faster, $1/r^2$ falloff so they're concentrated tightly near the wells).

This is the regime where the model's predictions for static observers — the Floating Leaf escape-velocity argument, the Four Clocks W=X=1 / Y=γ / Z=γ_2v split, the surface dilation matching Schwarzschild — are exactly correct and visible.

## What this lab is not

A full dynamic simulation of the wave equation governing $\Phi$:

$$\frac{\partial^2 \Phi}{\partial t^2} = c^2(\nabla^2 \Phi - S)$$

That equation is what would propagate finite-$c$ disturbances and produce real radiation-driven inspiral, comparable in scope to numerical relativity.  Implementing it stably with sharp point-mass sources is real CFD engineering — Hirai 2016 and Maeda 2024 have done it at galaxy scales, but bringing the same approach to LIGO-scale near-merger BBH precision is a substantial follow-on project.  This lab does not perform that simulation.

The orbital decay shown via the viscosity slider is **effective dissipation**, not radiation reaction emergent from the model.  The slider tunes a Stokes-style drag coefficient applied directly to the black holes; the field is unaware of it.

## Why ship it this way

The static-equilibrium picture is the part of the model that's already on solid ground — derivations match, predictions are visible, the lab runs in real time on consumer hardware.  Showing it cleanly, with the three flows distinctly visualized, is more useful than shipping a numerically fragile dynamic simulation that obscures rather than illustrates.  The dynamic version is a research project; the static visualization is a teaching tool, and that's the role this lab plays.
