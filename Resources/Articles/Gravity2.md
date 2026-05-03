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
