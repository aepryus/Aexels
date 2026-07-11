# Four Clocks

Imagine a lone planet and 4 clocks.  The 4 clocks, W, X, Y and Z are situated as follows:  W sits at infinity, X is falling from infinity at escape velocity and is currently at a point r above the planet, Y is resting on a platform a distance r above the surface and Z is blasting off to infinity at escape velocity also currently at the point r above the planet.

![](tint:4Clocks)

What is the time dilation experienced by each of the 4 clocks.

Clock W at infinity is not translating at all, so it has no translational velocity and therefore its dilation is 1.

$$
\gamma = \gamma(0) = 1
$$

Clock X is simply floating down with the aexels and similarly not translating at all; its dilation is also equal to 1.

$$
\gamma = \gamma(0) = 1
$$

Clock Y is sitting on the platform above the surface of the planet with the aexels flowing through it towards the planet as described in the Floating Leaf article.  Its dilation can be calculated by plugging the escape velocity at the platform into the dilation equation:

$$
\gamma = \gamma(v_e) = \frac{1}{\sqrt{1-\frac{2GM}{rc^2}}}
$$

Clock Z is blasting up from the surface.  The aexels will be moving towards the planet at the escape velocity for r.  The clock itself will be moving away from the planet at that exact same escape velocity in the opposite direction.  Therefore the translational velocity of clock Z will be 2 times that escape velocity.  Plugging that into the dilation equation gives:

$$
\gamma = \gamma(2v_e) = \frac{1}{\sqrt{1-\frac{8GM}{rc^2}}}
$$

A generalized equation for the dilation of a system moving in such a scenario can be described.  One simply needs to calculate the net translational velocity of the system and plug that into the dilation equation.  The net translational velocity will simply be the length of the escape velocity vector minus the system's velocity vector; giving:

$$
\gamma(\vec{v}, \vec{v_e}) = \gamma(|\vec{v} - \vec{v_e}|)
$$

Let's now consider the exact same thought experiment in our Universe.  In our universe the behavior of just such a system is described by the Schwarzschild metric which is a solution to Einstein's equations for a non-rotating sphere.

There is a constant of motion for an inertial observer in the Schwarzschild metric:

$$
\left(1 - \frac{r_s}{r}\right)\frac{dt}{d\tau} = \frac{E}{mc^2}
$$

For a clock starting from rest at infinity, energy will entirely be due to its intrinsic mass and therefore will be equal to mc².  Using this we can calculate gamma:

$$
\begin{aligned}
E &= mc^2 \\
\\
\frac{dt}{d\tau} &= \frac{1}{\left(1 - \frac{r_s}{r}\right)} \\
\\
r_s &= \frac{2GM}{c^2} \\
\\
\gamma = \frac{dt}{d\tau} &= \frac{1}{1-\frac{2GM}{rc^2}}
\end{aligned}
$$

In our universe the dilation of such a system is never a function of the direction of the velocity vector.  The dilation of the falling clock and the blasting off clock is exactly the same.

For our universe the time dilation of the 4 clocks is as follows:

Clock W, r goes to infinity, 1/r goes to 0 and gamma goes to 1.

$$
\gamma = 1
$$

Clock X

$$
\gamma = \frac{1}{1 - \frac{2GM}{rc^2}} = \gamma(v_e)^2
$$

Clock Y, as mentioned previously matches the dilation of Clock Y in Universe X.

$$
\gamma = \gamma(v_e) = \frac{1}{\sqrt{1-\frac{2GM}{rc^2}}}
$$

Clock Z

$$
\gamma = \frac{1}{1 - \frac{2GM}{rc^2}} = \gamma(v_e)^2
$$

The dilation of clocks W and Y match in the two universes; the dilation of clock X and Z do not.  And more so, for any given r,

Universe X:
    W = X < Y < Z

Our Universe
    W < Y < X = Z

This is a rather substantial deviation in the two universes.  How could such a discrepancy arise?

Recall in the Conspiracy article it was shown that Reciprocity could not possibly be true.

One of the first steps in the derivation of Einstein's field equations is the definition of ds² = c²dt² - dx² - dy² - dz² and to note that because of reciprocity this term is a constant for all frames.  But, if reciprocity is false, ds² invariance is false.

The metric did, however, get the dilation correct for clocks W and Y, even if it was wrong for clocks X and Z.  It worked for the static clocks, but not for the translating ones.  The Reciprocity assumption broke the calculation for moving systems.

The 'constant of motion' is what introduces ds² invariance and consequently throws things off the tracks.

One might also note that Einstein's General Relativity has only ever been experimentally tested using static systems.

Beyond all this there may be something else being illustrated here.  Consider the following again:

    W = X

This hints at a potentially new, much stronger equivalence principle, that a system in free fall is precisely equivalent to a system in flat space.  This concept is further explored in the Gravity II article.
