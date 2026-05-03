# Electricity, Magnetism and the Cupola

## Pings and Pongs

Back in the day, while at university, long before Universe X, I was continually attempting to wrap my head around various phenomena in physics.  I got a salt shaker and shook some salt out onto my desk, gathered it into a pile and then pushed my finger into the pile creating a ring.  I then continually increased the radius of the ring by swirling my finger around inside.

It occurred to me that as I increased the radius of the ring the amount of salt at any point would fall off at 1/r and would fall off at 1/r² if I could perform a similar exercise in three dimensions.  I thought that there must be some mechanism akin to this salt model underpinning the 1/r² forces in Physics, but I had no idea how that would work or how to explain the seemingly endless supply of 'salt' needed.

When I released Aexel 3.0 in December of 2022 it included the new Dilation and Contraction simulations.  Implementing these simulations took my explanations for Dilation and Contraction from hand waving to a rigorous implementation; supporting my long held contention that the best way to make sure you understand something is to explain it to a computer.

But, for those two simulations I used a very simple and specific configuration of the particles.  Those configurations made calculating the trajectories of pings and pongs quite easy, but I had no idea how to do so in the general case, for particles moving in arbitrary directions and with various speeds.  I figured there must be a way to encode enough information in the ping in order to accomplish it, but I had no idea what that information was.

For Aexels 4.0 I wanted to add a much more complete electromagnetism simulation.  In order to accomplish this, I needed to figure out how to tell the target teslon which direction it needed to move in response to the ping it had encountered.  After playing with some geometry and trigonometry I realized there was a remarkably simple way to determine the direction of the force: just take the vector of the absolute trajectory of the ping of length c and subtract the vector of the absolute trajectory of the source teslon of length v.  (The term 'absolute' here, means the translation across the aexels themselves, i.e., relative to the v = 0 frame.)

This resultant vector would indicate the exact direction of the force.  Each ping could be embedded with this vector and any teslon encountering the particle would know which direction the force was to be applied.  I named this vector the 'cupola'.

But, this target teslon also needed to respond with a pong that was guaranteed to intersect with the source teslon.  I soon realized that if you reflected the absolute translation vector over the cupola vector and sent out a response edison also at the speed of light, the pong would precisely intersect that source teslon, assuming it had moved with constant velocity.

With these results in hand, I proceeded to build a simulation in the Aexels app.  Seeing this perfect and elegant ping / pong dance was really quite magical.

![](CupImg01)

## Magnetism and the Lorentz Force

Also from my university days, I had some highly vague sense that the E and B fields and the Linear and Angular momentum vectors had to be some sort of orthogonal pointers, but this was a very foggy / undeveloped notion.

When I had first heard of magnetic and electric forces being frame dependent I reacted with great consternation and received no satisfactory explanation of what was really going on.  But, now armed with this new cupola vector the true nature of the E and B fields started to take form.

I realized that the B field was just the cross product of the cupola vector and the frame dependent translation vector; and with that realization, the frame dependence of the E and B fields finally made sense.

There is an equation in physics that really does not seem to fit in with all the other equations, the Lorentz force:

    F = qv × B

Not only is this force applied *perpendicular* to the B field, but is a function of v!  And while in Universe X the v of the Lorentz transformations represents the rate of the translation across the aexels, what does this v represent?  Two substantial mysteries in one small equation.

The first mystery is relatively easy to dismantle.  The B field being just the cross of the cupola and frame dependent translation vectors means it is simply an artificial amalgam of two more fundamental vectors.  The force is actually not perpendicular at all; it's in the exact same plane defined by the cupola and frame dependent translation vectors.

As far as the velocity dependence of the force, if one plays with the numbers when dealing with the force one teslon exerts on another one can see that ultimately all E&M forces are simply coulomb forces in the frame of the source teslon.

The B component of the force only comes into play when trying to make sense of that E force in another frame.  It's a mathematical trick to make the force make sense in other frames and that amount of correction that is needed here is a function of the velocity of charge relative to the reference frame.

## Hyle Exchange

Unfortunately, modeling the hyle exchange was not nearly as straightforward.  The problem is that in natural units the momentum and energy carried by a photon is always equal.  But the momentum and energy lost by a teslon is never equal.  So how do you maintain local conservation through photon exchange?

Here I think we have butted up against the mysteries of Quantum Mechanics and this mystery will be left to be tackled in some future version of Aexels.
