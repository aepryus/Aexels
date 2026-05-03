# Black Holes

Two black holes orbit each other under the gravitational mechanism described in the Gravity II addendum.  Each frame the simulation:

1. Splats the two point masses onto a 64×64 density grid via cloud-in-cell weighting.
2. Solves the discrete Poisson equation $\nabla^2 \Phi = 4\pi G \rho$ on the GPU using Jacobi iteration, warm-started from the previous frame's solution.
3. Samples $-\nabla \Phi$ at each black hole's location.
4. Advances the black holes via leapfrog integration.

The point of this lab is the architecture, not the visual.  In Phase 0 the gravity comes through a Poisson solve rather than a direct $1/r^2$ force calculation.  For two bodies that's overkill; the same machinery scales to arbitrarily many masses with no change to the cost of the gravity step.  Every cell in the grid feels gravity from every mass simultaneously through one solve, regardless of how many masses there are.

This is the $O(n)$ claim of the accelerant concept: the gravitational interaction between $n$ masses costs the same as the Poisson solve, which is independent of $n$ for any fixed grid resolution.

## What Phase 0 doesn't show

The orbits here don't decay.  Pure Newtonian gravity gives stable elliptic orbits, and Phase 0 is pure Newton; the two black holes circle each other forever.  The inspiral and merger come from energy loss to gravitational waves, which in Universe X is the dissipation produced by the Aexel Equation:

$$
\frac{\partial \mathbf{v}_a}{\partial t} + (\mathbf{v}_a \cdot \nabla) \mathbf{v}_a = \mathbf{u} - \varepsilon \nabla^2 \mathbf{v}_a
$$

Phase 1 adds the aexel velocity field $\mathbf{v}_a$ as a second texture, advected each frame, and replaces the direct Newtonian step with the black holes riding the local aexel velocity.  The viscosity $\varepsilon$ becomes the inspiral rate.
