# A Shot in the Dark

How to Hit a (Cooperating) Invisible Moving Target

## Introduction

Consider a two-dimensional plane that can contain nodes, each of which can sit still or translate across the plane at some arbitrary velocity v.  These nodes are blind and cannot see other nodes or even know if any exist at all.

However, each node does have the ability to send out signals that travel quickly and at a fixed velocity c across the plane itself (v < c).  The nodes also have the ability to intercept such signals and respond with their own signals in order to complete the handshake.

For a first pass we could imagine each node periodically sending out a volley of pings in all directions.  When another node intercepts one of these pings it could respond with a volley of pongs also sent out in all directions.  And if there were solely two nodes, this would work fine.  However, once a third node is added into the mix, things get complicated.

Imagine nodes A, B and C existing on the plane.  Each sends out a volley of pings looking for other nodes.  C will receive pings from both A and B, and will then respond with a volley of pongs sent out in all directions for each.  Consequently, A will receive pongs from C motivated by itself, as well as those motivated by B.  As more and more nodes get added things will get increasingly convoluted.

For this reason, the response cannot be a volley of pongs sent off in all directions.  It must somehow be a surgical shot, sent off in a single direction such that it is guaranteed to intercept the source node, the challenge of this being that the responding node does not know what the source node's current position or velocity is.  It doesn't know if it's close or far away, and it doesn't know if it's stationary, moving slowly, or moving fast, or in which direction.

At first, a solution perhaps seems unlikely.  But as we'll see, there is a remarkably elegant algorithm that will enable a response pong to be sent such that it is guaranteed to impact the source (as long as the source node does not accelerate).

## The Cupola

When a source node (S) sends out its pings, it wants to store enough information in each ping so that any target nodes (T) that intercept the ping will be able to send a return pong that will precisely find its way back to S, thereby completing the handshake.

If we think of each node as having little computers and complete knowledge of their world, each could perhaps store a packet of information in their pings that contained their precise world position, velocity and world time at the moment that each ping was released.  With that information each intercepting T could then compare that data with their own current world position and world time and calculate the (one and only) intercept angle needed to launch their reply pong so that it is guaranteed to impact S (again assuming no acceleration).

This would require that each node has precise knowledge of their world, sophisticated calculators and pings that can hold a fair amount of data.  What if instead these nodes have none of that information and both the nodes and the pings are significantly less sophisticated?

![](SDImg1 "The co-moving nodes S and T move to the right at v. A ping moves from S(t₀) to T(t₁) at c. A pong is then sent out mirrored across the vertical line connecting S(t₁) to T(t₁); moving from T(t₁) to S(t₂) also at c.")

Let's first consider a simple case: two co-moving nodes, positioned perpendicular to the direction of translation.  The ping that will eventually hit the T node will have needed to lead the T a bit and have been sent out slightly angled towards the direction of translation.  In this case, when the ping connected with T, it would be very clear what direction the pong would need to be sent in order to reconnect with S: it would just be the mirror of the incoming translation vector over the line connecting the current positions of S and T, which is precisely vertical.

At this point we could make a guess that this simple case hints at the answer to the general case.  If we could know the line between S and T, we could simply mirror the incoming ping translation vector over that connecting line in order to arrive at the outgoing pong vector.

At any time t, S will be at S₀ + 𝐯ₛ t whereas the ping will be at S₀ + 𝐜 t.  The displacement from S to the ping is therefore 𝐜 t − 𝐯ₛ t = (𝐜 − 𝐯ₛ) t.  This indicates that the direction of the displacement is constant over time.  Let's name this displacement vector 𝐜 − 𝐯ₛ as the **cupola**.

Instead of imagining our pings as spheres, let's imagine them as footballs (oblong spheres).  Let's orient each of these footballs along the direction of their cupola vector.  These footballs, as they move, will then store two vectors: the vector of its translation (its velocity) and the vector of its orientation (the cupola); and certainly these two vectors might not be aligned.

![](SDImg2 "The cupola is calculated by subtracting v from c. As the ping translates, the cupola always points to the current position of S, while the translation vector always points back to where S was when the ping was released.")

From the diagram we can see that as S and the ping move, the ping's cupola is always pointing back towards the current position of S, while the ping's translation vector always points back to the original position of S at the time that the ping was released.

![](SDImg3 "A full volley of football-shaped pings radiating outward in a circle centered at the origination point. Each ping is oriented along its cupola vector, all pointing to the current position of S.")

This becomes even more apparent if we look at a full volley of pings.  The circle of the pings radiating outwards is centered at the point that the pings were released from, but each of the little footballs is pointed directly at the current position of S.

Now when the ping is intercepted by T, it can read the ping's cupola in order to determine the exact direction towards S.  It can then respond to the ping with a pong by mirroring the incoming ping's translation vector over that same ping's cupola vector.

## The Pong

We now have a proposed solution to our puzzle.  By encoding a single vector into our pings we are able to calculate a precise return trajectory for our pong that we hope will intersect S, thereby completing the handshake.  But does it?

![](SDImg4 "The geometry of the ping–pong–cupola triangle. The cupola bisects the angle between the ping path b₁ and the pong path b₂, while a₁ is the distance traveled by S during the ping and a₂ is the distance traveled by S during the pong.")

This diagram shows the node S translating to the right across the plane starting from when the ping was released.  In the top right we see the location where the ping is intercepted by the T node.  The length a₁ represents the distance that S traveled from the moment of the ping's release until the moment of the ping's capture; b₁ shows the path of the ping itself during that same time frame.

Once the ping is intercepted, T responds with a mirrored pong, where the angle between the ping and the cupola is equal to the angle between the pong and the cupola (but on the opposite side).  Here a₂ represents the distance traveled by S during the pong's transit and b₂ represents the pong's path during that same interval.

But do S and the pong actually intersect at that exact same point at the exact same time?  In order for that to be the case the ratio a₁/b₁ would need to match a₂/b₂ precisely.  How do we prove that that is the case?

In Euclid's Elements VI.3 he proves the following:

> If an angle of a triangle is bisected by a straight line cutting the base, then the segments of the base have the same ratio as the remaining sides of the triangle.

In this case the paths of the ping, the pong and the source node S form a triangle.  The cupola, by definition of the algorithm itself, bisects the ping–pong angle.  As a result, based on Euclid's aforementioned Angle Bisector Theorem, we know that:

a₁ / b₁ = a₂ / b₂

thereby proving that the pong and S will both arrive at the intersection point at the exact same moment and consequently proving that our cupola algorithm will allow for our blind nodes to communicate directly with one another by using an omnidirectional ping volley followed by a precisely directed pong response.

## Conclusion

In this way we have created a perhaps surprisingly elegant mechanism that allows multiple blind nodes to form private communication channels between themselves.  It does this by sending out football-shaped pings oriented in a manner that enables any intercepting node to know exactly how to connect back to the originating node with a response pong.

![](SDImg5 "A simulation of the cupola algorithm. The hexagon pattern represents the plane; the two large white circles the nodes; the expanding grey circles dense volleys of football-shaped pings expanding outwards; and the red footballs the response pongs, traveling directly back to the source, creating a pong 'bridge' between the two nodes.")
