# The Squish and the Accelerant

## Gauss' Curse

Since the very first insight, detailed in the 'Expansion' article, the Gauss problem has hung over this entire Universe X concept.  Namely, the problem that the aexel flux through each shell (the area of a sphere times the flow rate of the aexels) is not a constant and as such the aexels, as they flow inward, can't be conserved.

In addition to that, no progress had been made in understanding anything about aexel dynamics: Did they have momentum?  How did they exert a force on one another?  What is the mechanism for their destruction and creation?

New experimental data became available that I wasn't expecting.  Increasing evidence seemed to indicate that the gravitational force traveled at the speed of light.  The observation of gravitational waves by the LIGO sensor in 2017 showed that they too traveled at about the speed of light.  Certainly, there was nothing in Universe X that said gravitational waves couldn't travel at the speed of light, but also there was nothing that said they had to.

And one last thing I couldn't figure out: if aexels are being pulled towards concentrations of mass like a tablecloth through a hole, why aren't they less dense rather than more dense as you get closer to the mass?

Into this mix, I had two new tools available to me, LLMs and the ability to develop simulations using the GPU, which greatly increased the number of particles I could model.  It was time to explain this idea to my computer; it was time to figure out what was really going on here.

At this point in Universe X, gravity was understood through two basic concepts:
- that hyle destroyed the crystalline aexels and therefore pulled more aexels towards it like a tablecloth being pulled through a hole in a table,
- that gravity was not a force, but rather was a result of the acceleration of the aexels themselves and that the dilation at any point due to gravity was simply a measure of the rate of aexel flow at that point.

But Gauss and the other issues I just mentioned made reconciling these two concepts very difficult.  I decided the best way to move forward was to just try to explain both of these concepts to my computer and hopefully a method reconciling the two would occur to me during the process.

The simulation that modeled the destruction of aexels was named InsideOut.  The simulation that modeled the velocity and acceleration of the aexels from the outside was called OutsideIn.  The ultimate solution here came in two steps, the first step led me to realize that OutsideIn was correct (with modification), but the InsideOut was incorrect.  The second step led me to realize that InsideOut was also correct, but that a looser join to OutsideIn was required.

## The Squish

The InsideOut mechanism started with an aexel sink at the location of the mass.  Each second that mass would destroy a fixed number of aexels.  Those missing aexels would need to be replaced, so each shell surrounding the mass would need to have those missing aexels flowing through it each second.  At every point a distance r from the center there would be a specific velocity and acceleration of those aexels.

The OutsideIn mechanism started with the aexel flow.  It posited that the dilation at any point is an indication of the velocity of the aexels flowing through that point.  From that velocity the acceleration at every point could be calculated.

When you do those calculations the InsideOut mechanism gives a 1/r² relation for the velocity.  The OutsideIn mechanism gives a 1/r² relation for the acceleration.  How can these two be reconciled?

My thought since the very beginning of Universe X is that I would be able to resolve this through density variations, but when it came time to actually explain this to my computer I realized two things.  One, given the aexel model of distance, there actually is zero density wiggle room.  You can't increase density without increasing distance.  The Cartesian distance is irrelevant, the only thing that matters is the number of aexels you must jump to, to get from one point to the other.

The other issue is that, for example, for the Earth the aexel compression is quite mild.  The gravitational radius of the Earth is only 4 mm greater than the circumference radius.  Even if there was wiggle room in the density there is no way the severe correction that was required could be accommodated in this slight squeeze.

My mind boggled; is space actually 4D?  Are we living on the 3D surface of some 4D pond?  The thought of abandoning the entirely 3D sand box of Universe X was horrifying.

And then finally, the solution came to me.  I had long posited that gravity was not a force, but rather was an emergent phenomenon caused by the flow of aexels.  But, this was wrong and also sort of right.  Gravity *is* a force, but not a force on teslons and edisons; instead it is a force on the aexels themselves with the teslons and edisons coming along for the ride.

I had made the assumption that the destruction of aexels by hyle was local, but that assumption was also wrong.  The destruction happens as the aexels flow into smaller and smaller shells and consequently get squeezed out of existence.  It doesn't need to obey Gauss' law because the aexels don't necessarily get squished local to hyle.

We had seen how to solve the 1/r² force previously in E&M, so all we need to do is posit the existence of g-pings and voila, we have our gravitational force, but applied to the aexels themselves not the matter sitting on those aexels.

## The Accelerant

Once I sat down to start thinking about implementing the g-ping solution, problems became apparent at once.

As previously noted in the Kinematics article, the electromagnetic phenomenon is huge compared to the aexels.  The sophistication available to E&M compared to gravity might perhaps be akin to the sophistication available to an individual human compared to an individual bacteria.

It also operates on wildly smaller distances.  The idea that each bit of hyle was somehow sending out g-pings in all directions with such granularity that it would hit each and every aexel in each and every corner of the universe seemed ridiculously intractable.

My expanding salt analogy was useful in understanding E&M, but perhaps it was leading me astray here.  And in fact through the InsideOut mechanism I realized that there *was* another way to achieve a 1/r² relationship.  Namely, instead of *adding* particles to a system to achieve the relation, one could *subtract* particles instead.  In the first case the 1/r² relationship is represented by the density of the particles at any point.  In the second case the 1/r² relationship is represented by the current of particles at any point.

And with this thought the concept of the 'Accelerant' fluid was born.  Hyle destroys accelerant.  The velocity of the accelerant at any point is promoted to an acceleration of the aexels at that same point.

And as such, an absurdly intractable O(n²) g-ping problem is converted into a much more manageable O(n) fluid dynamics problem of the accelerant.

Now admittedly, this is a next level inference even in the world of Universe X.  However, even if it's totally off base, but succeeds in speeding up gravitational simulations, it can be a powerful tool.

On the other hand, if it does speed up gravitational simulations, why wouldn't 'god' make use of the same optimization in designing our universe?
