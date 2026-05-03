# A Shot in the Dark

Consider a two dimensional plane containing nodes that can translate across it at some arbitrary velocity v.  These nodes are blind; they cannot see other nodes or even know if any exist.  However, each node can send out signals that travel at a fixed velocity c across the plane (where v < c) and can intercept such signals from other nodes.

The challenge: how can two such blind nodes establish a private line of communication?

A first attempt might have each node send out volleys of pings in all directions.  When a target node intercepts a ping, it responds with a volley of pongs, also in all directions.  For two nodes this works, but with three or more nodes the responses become hopelessly entangled; a node would receive pongs motivated by other nodes and have no way to sort them out.

The response therefore cannot be omnidirectional.  It must be a single, precisely aimed pong sent on a trajectory guaranteed to intercept the source node.  The challenge is that the responding node knows nothing about the source: not its position, not its velocity, not its distance.

At first, a solution seems unlikely.  But there is a remarkably elegant algorithm that solves the problem using a single encoded vector.

When a source node S sends out a ping traveling at velocity c, that ping is embedded with a vector called the 'cupola', defined as the ping's translation vector minus the source node's velocity vector: c - v.  This cupola vector has a remarkable property: as the ping translates across the plane, the cupola always points from the ping toward the *current* position of S, even though S has been moving the entire time.

When a target node T intercepts the ping, it reads the cupola to determine the direction back toward S.  It then sends out a pong by mirroring the incoming ping's translation vector across the cupola.

But does this pong actually hit S?  The paths of the ping, the pong and the source node form a triangle.  The cupola, by definition of the algorithm, bisects the angle between the ping and pong paths.  Euclid's Angle Bisector Theorem (Elements VI.3) then guarantees that the pong and S will arrive at the intersection point at the exact same moment.

The proof that the algorithm works has been hiding in Euclid for over two thousand years.

This cupola algorithm is the mechanism underpinning Electromagnetism in Universe X.  The formal proof has been written up as a paper titled 'A Shot in the Dark: How to Hit a (Cooperating) Invisible Moving Target' submitted to the American Mathematical Monthly.
