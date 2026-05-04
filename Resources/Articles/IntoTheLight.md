# Into the Light

The Oddly Reminiscent Dynamics of a Blind Communication Protocol

## Introduction

In the Shot in the Dark article we introduced a blind communication protocol for nodes moving at constant velocity in a medium that supports signal propagation at fixed speed c.  Each node periodically emits an omnidirectional volley of pings traveling at speed c.  Each ping carries a single encoded vector, the cupola, defined as 𝐂 = 𝐜 − 𝐯ₛ, where 𝐜 is the ping's translation vector (of magnitude c) and 𝐯ₛ is the velocity of the source.  When a target node intercepts a ping, it sends a return pong by reflecting the ping's translation vector across the cupola; Euclid's Angle Bisector Theorem guarantees that the resulting pong intercepts the source exactly.

The companion article treated this as a self-contained geometric puzzle, with the proviso that the source was not accelerating.  Here we extend the protocol with a small set of rules that turn it into a dynamical system supporting bound composite objects that can translate across the medium without falling apart.  We then explore the dynamics that emerge.

## The Rules

We extend the cupola algorithm with four rules.  The first two add dynamics.  The remaining two are required for translating composite objects to internally behave as they did at rest.

### Rule 1: Impulse

> When a ping reaches a target, an impulse of magnitude q|𝐂| is locked in along the cupola direction.  The impulse is applied to the target when the corresponding pong returns to the source.  The proportionality constant q is universal: it is the same for every node.

Each node also carries a per-node scalar quantity, which we call the node's hyle η.  Hyle determines a node's inertia: an impulse of magnitude F delivered to a node with hyle η produces a velocity change of magnitude F/η.

### Rule 2: Species

Rule 1 alone provides only one half of an interaction: when a source A sends a ping to a target B, B receives an impulse, but the direction of that impulse is determined entirely by the cupola of A's ping.  To get a coherent two-node interaction, B must also send pings to A, and A's response to B's pings must be such that the resulting pair of impulses is consistent (either both nodes pushed apart, or both pulled together).  To enable both attractive and repulsive interactions, we make each node one of two types.

> Each node is either an *outie* or an *innie*.  Outies emit pings with cupolas pointing outward; innies emit pings with cupolas pointing inward.  The impulse delivered by Rule 1 to a target is along +𝐂 if the target is an outie and along −𝐂 if the target is an innie.

Two outies, or two innies, push apart.  An outie and an innie pull together.  Bound configurations are possible between mixed pairs.  Like-type pairs cannot bind.  The protocol therefore admits two-type composite systems — structures held together by the attraction between outies and innies — but does not admit single-type bound configurations.

### Rule 3: Engineered Emission Density

Rules 1 and 2 give nodes the ability to interact and bind.  We would like the interactions to be rich enough that bound composite systems can also translate across the medium without falling apart.  The internal coherence of a composite system depends on the timing of its ping–pong exchanges; if that timing is consistent regardless of orientation the system can move, but if it varies with orientation the system cannot remain coherent under translation.

We compute the round-trip time in two configurations.

**Perpendicular separation.**  Consider two co-moving nodes separated by a fixed distance L perpendicular to their direction of translation at speed v.  The outbound ping must lead the moving target, traveling a diagonal path.  If the one-way time is t, the ping covers ct while the target covers vt, with L as the third side of a right triangle:

(ct)² = L² + (vt)²  ⟹  t = L/√(c²−v²)

By symmetry the return pong takes the same time.  The total round-trip is

T⊥ = 2L/√(c²−v²) = 2Lγ/c

where β = v/c and γ = 1/√(1−β²).

**Parallel separation.**  Now consider the same two co-moving nodes, but separated by distance L along the direction of translation.  The outbound ping chases the retreating target and takes L/(c−v).  The pong returns against the source's motion in L/(c+v).  The total is

T∥ = L/(c−v) + L/(c+v) = 2Lc/(c²−v²) = 2Lγ²/c

**The asymmetry.**  The two round-trip times do not match: T⊥ = 2Lγ/c but T∥ = 2Lγ²/c.  They differ by a factor of γ.  A composite system whose internal timing depends on orientation cannot maintain itself coherently while moving; a system formed at rest will fall apart as soon as it begins to translate.

The only way to make a moving composite system coherent is to allow its physical separations to differ from those it had at rest.  Suppose the parallel separation contracts from L to a new value L′, while the perpendicular separation remains L.  Setting the new round-trip times equal:

2L′γ²/c = 2Lγ/c  ⟹  L′ = L/γ

A composite system, when set in motion at speed v, must contract along its direction of motion by the factor 1/γ for its internal ping–pong timing to remain consistent across orientations.

A consequence worth noting: the matched round-trip time 2Lγ/c exceeds the rest round-trip 2L/c by a factor of γ.  A moving composite system updates its internal state more slowly than it did at rest.  From the system's own perspective this is invisible — all internal processes slow down by the same factor — but in the medium, the dynamic processes within a moving system run at a rate reduced by 1/γ.

**The natural shape.**  We now ask what corrective angular density on emission is needed to produce the L/γ contracted ellipsoid as the equilibrium configuration of a moving composite system.  Begin by seeing what the cupola dynamics gives without any angular structure imposed.  Take ρ(θ, β) ≡ ρ₀ — isotropic emission at constant rate per medium-time.  The static-target impulse on a probe co-moving with the source has a κ factor in the denominator (κ = 1 − 𝐧̂ · 𝛃) that produces strong forward focusing: at θ = 0 (forward), κ = 1 − β; at θ = π (backward), κ = 1 + β.  Combined with the cupola direction (𝐧̂ − 𝛃), the impulse magnitude varies sharply with angle.

The natural equilibrium shape — the locus on which a co-moving probe experiences a fixed impulse magnitude — is therefore not a sphere when β > 0, nor is it the contracted ellipse demanded above.  It is asymmetric front-to-back: compressed forward, stretched backward, with a comet tail.  As β → 1 the asymmetry diverges.  Without a corrective angular density, a moving system has no coherent contracted shape.

![](ITLImg1 "The natural shape (red) at three values of β, with the L/γ contracted ellipse (blue) and the rest sphere (gray dotted) shown for reference.  With isotropic emission, the moving system's equilibrium locus is asymmetric and offset backward from the source; the asymmetry diverges as β → 1.  A corrective angular density is needed to turn the comet tail into the symmetric ellipse.")

**The correction.**  Working through the impulse calculation at perpendicular and parallel configurations and requiring the contracted ellipsoid to be the equilibrium locus produces a unique angular density:

> A source moving at velocity 𝐯 emits pings with angular density
>
> ρ(θ, β) = (1 − β²)ρ₀ / (1 − β cos θ)²
>
> where θ is the angle between the ping's direction and the source's velocity.

The (1 − β²) prefactor is the normalization that fixes the perpendicular magnitude at the required value; the 1/(1 − β cos θ)² in the denominator does the angular reshaping that turns the comet tail into the ellipse.  The cupola flux at a co-moving probe has a natural 1/κ angular factor; for the impulse on the probe to land on the symmetric ellipse, what is needed is a 1/κ³ angular factor in the impulse formula.  Rule 3 supplies the remaining 1/κ² in the emission density.

### Rule 4: Kinetic Hyle

Rule 3 engineers the contraction.  It is not, by itself, sufficient.  Consider two co-moving same-type nodes at perpendicular separation L, system translating at 𝐯 = v 𝐱̂.  The medium-frame impulse has magnitude qρ₀/(γL²), pointing perpendicular to motion.  With hyle assumed constant (η = η₀ regardless of velocity), the medium-frame acceleration is a_med = F/η₀ = a_rest/γ.

The internal observer's clocks run at 1/γ of medium time.  Reading off acceleration as displacement per internal-time-squared, the internal observer measures a_int = a_med · γ² = γ a_rest.  Protons fly apart γ times faster than at rest.  This is wrong: internal-rest-equivalence demands the system internally behave as it did at rest.

The remedy is for the node's hyle itself to inflate with motion:

> A node moving through the medium at speed v has hyle
>
> η = γ η₀
>
> where η₀ is its rest hyle.  The additional (γ − 1)η₀ is the kinetic hyle.

With Rule 4, the medium-frame acceleration becomes a_med = F/(γη₀) = a_rest/γ², and the internal observer measures a_int = a_med · γ² = a_rest.  Internal dynamics are recovered.

Rule 3 alone is not sufficient: the perpendicular force law it produces is too weak by a factor of γ for the at-rest experience to be recovered through dilated clocks alone.  Rule 4 supplies the missing factor through inertial inflation.  The dependency is one-directional — Rule 3 is forced by the signaling-coherence requirement, and Rule 4 is forced in turn by Rule 3's force law combined with internal-rest-equivalence.  Together they make moving composite systems internally indistinguishable from their rest configurations.

## The Work Theorem

The work done in accelerating a node from rest to velocity v has a closed form.  With momentum 𝐩 = η𝐯 = γη₀𝐯, the differential is d𝐩/dv = η₀γ³.  The work integral is

W = ∫₀ᵛ v′ (dp/dv′) dv′ = η₀ ∫₀ᵛ γ³v′ dv′ = η₀c²(γ − 1)

The result has the form of a hyle quantity multiplied by c²: the work delivered to the node equals the kinetic hyle (γ − 1)η₀ scaled by c².  Inverting, hyle and the work integral are related by

η = η₀ + W/c²

Equivalently, work and hyle are interconvertible at the conversion rate c²:

W = c²Δη

Any change in a node's hyle equals 1/c² times the work delivered to (or extracted from) it.

## The Dynamics

We can now write down the dynamics that emerge from the four rules.  Throughout, S denotes a source node at position 𝐫ₛ with velocity 𝐯ₛ and acceleration 𝐚ₛ, and T denotes a target at position 𝐫ₜ with velocity 𝐯ₜ.  Let 𝐧̂ be the unit vector from S's retarded position toward T, and let R be the distance from that retarded position to T.  Define 𝛃 = 𝐯ₛ/c.  The projection factor κ = 1 − 𝐧̂ · 𝛃 is the same quantity that appeared in Rule 3.

### Static Target

The flux of pings at a stationary target, accounting for the geometric spreading and the retarded-time-to-observer-time Jacobian dt_e/dt_o = 1/κ, is

flux = ρ(θ, β) / (κc²τ²)

The static-target impulse rate, from Rule 1, is

𝐅₀ = (1 − β²)(𝐧̂ − 𝛃) / (κ³R²)

The factor 1/κ³ in the denominator decomposes cleanly: 1/κ² from Rule 3's emission density, and one further factor of 1/κ from the retarded-time Jacobian.  The (1 − β²) in the numerator comes from Rule 3 directly.

### Moving Target

A target moving at velocity 𝐯ₜ through the ping stream of S experiences two modifications to the static-target impulse:

1. **Arrival rate.**  A target moving toward the ping stream meets pings more frequently than a stationary target; one moving away meets them less frequently.  The arrival rate is multiplied by (1 − 𝐧̂ · 𝐯ₜ/c).
2. **Direction shift.**  A moving target perceives each ping as arriving from a slightly different direction than a stationary target would.  This contributes a component along 𝐧̂ proportional to 𝐯ₜ · 𝐅₀/c.

The total impulse on a moving target is therefore

𝐅ₜ = 𝐅₀(1 − 𝐧̂ · 𝐯ₜ/c) + 𝐧̂(𝐯ₜ · 𝐅₀/c)

Using the vector identity 𝐯ₜ × (𝐧̂ × 𝐅₀) = 𝐧̂(𝐯ₜ · 𝐅₀) − 𝐅₀(𝐯ₜ · 𝐧̂), this rearranges to

𝐅ₜ = 𝐅₀ + (1/c) 𝐯ₜ × (𝐧̂ × 𝐅₀)

The impulse on a moving target is the impulse on a stationary target plus a correction expressible as a vector cross product involving 𝐯ₜ and the derived quantity 𝐁 ≡ (1/c) 𝐧̂ × 𝐅₀.

### Accelerating Nodes

The cases above considered constant-velocity sources.  We now consider what happens when the source is accelerating during the emission of its pings.

A ping is not emitted instantaneously; emission takes a finite interval of time.  For a constant-velocity source, the cupola at the start of emission and the cupola at the end of emission are identical.  The ping carries a single, well-defined cupola.

For an accelerating source, the velocity changes during the emission interval.  The cupola 𝐂 = 𝐧̂ − 𝛃 rotates during emission: if 𝛃 at the start of emission differs from 𝛃 at the end, the cupola direction shifts.  The ping does not emerge with a single static cupola; it emerges with a *rotating* cupola, the rotation rate set by the source's acceleration during emission.

When this rotating-cupola contribution is folded into the impulse formula, it adds a term that falls off as 1/R rather than 1/R².  The geometric spreading still contributes 1/R², as for the static cupola; the additional factor of R in the numerator comes from the time derivative itself.  The result is

𝐅 = (1 − β²)(𝐧̂ − 𝛃) / (κ³R²) + 𝐧̂ × [(𝐧̂ − 𝛃) × 𝛃̇] / (κ³R)

The first term is the static-cupola contribution.  The second is the rotating-cupola contribution.

### Total Power Radiated

Integrating the rotating-cupola contribution over a sphere surrounding the source yields the total power radiated:

P = (2q²/3c) γ⁶ [𝛃̇ · 𝛃̇ − (𝛃 × 𝛃̇) · (𝛃 × 𝛃̇)]

In the non-translating limit (𝛃 → 0), this reduces to the familiar Larmor formula:

P = 2q²a²/(3c³)

## Hyle Loss in Acceleration

The protocol's hyle determines a node's inertial response to impulse but does not appear in any of the impulse magnitudes calculated above.  The rate of impulse delivery is set entirely by q, ρ₀, and the source's kinematics.  We now ask what hyle budget supports an accelerating source's emission of rotating-cupola pings.

A ping with a non-rotating cupola is a pure directional signal: it carries Rule 1's impulse-determining cupola but has no internal dynamic content of its own.  A ping with a rotating cupola is different.  The rotation has angular content that the ping carries with it through the medium, and producing this angular content draws hyle from the source at emission.  The hyle must come from somewhere, and the only available source is the source's own.

Only an accelerating node emits rotating-cupola pings.  An accelerating node therefore loses hyle at the rate at which its pings carry rotational content away.  The source's rest hyle decreases at rate

dη₀/dt|radiated = −P/c²

Notice the structure.  The rate P at which the source loses hyle (in work-equivalent units) depends on q, the protocol's coupling constant, and on the source's kinematics.  It does *not* depend on the source's hyle.  Two nodes with very different hyle, undergoing the same acceleration, radiate at the same rate P.  The source's hyle controls how much external impulse is needed to produce a given acceleration, but once an acceleration is happening, the rate of hyle loss to rotating-cupola pings is set by 𝛃̇ alone.

## The Self-Force on an Accelerating Node

### Only Rotating Pings Carry Momentum

A ping with a static cupola is a pure directional signal carrying no internal dynamic content.  We further stipulate that a ping with a static cupola carries no hyle.  A ping with a rotating cupola is different: the rotation is genuine angular content propagating with the ping at speed c through the medium.  Some quantity of hyle h_ping therefore travels with each rotating-cupola ping.  A signal of hyle h_ping propagating at c in direction 𝐧̂ carries momentum h_ping c along 𝐧̂.

The no-self-force property of free uniform motion follows immediately.  When 𝛃̇ = 0, no ping carries a rotating cupola, so h_ping = 0 and 𝐩_ping = 0 for every emitted ping.  A free uniformly moving node sheds no momentum into the medium and experiences no self-force.  This is direct from the protocol's structure; no additional postulate is required.

### Recoil

For an accelerating source, integrating the per-ping momentum over the sphere yields

d𝐩_rad/dt = (P/c) 𝛃

The recoil force on the source from emission is therefore

𝐅_back = −(P/c) 𝛃

This recoil vanishes when the source is at rest in the medium (𝛃 = 0).  At that moment the source loses hyle at rate P/c² but no momentum — consistent with the fore-aft symmetry of the angular pattern at β = 0.

### Conservation Closure

Combining the per-ping kinematics with the frame-invariance of the radiated power P and time dilation, the rest hyle of an accelerating source decreases in medium time at rate

η̇₀ = −P/(γc²)

In the source's internal time, dη₀/dt̃ = −P/c².  The rest hyle that leaves the source per source-internal tick is the radiated power divided by c² — an aesthetically clean statement given that η₀ is the source's own intrinsic scalar.

### Per-Photon Hyle Content

The hyle-loss rate is a global statement about how the source's hyle decreases as it radiates.  It says nothing about how that loss is partitioned across individual emitted pings.

The natural starting point is to identify a "photon" with a ping carrying a rotating cupola, with frequency read off from the cupola's rate of change.  But the cupola is a vector, and its rate of change has more structure than a single number: the cupola traces a trajectory in the plane perpendicular to the line of sight, and what we call "frequency" depends on which feature of that trajectory we track.

For a source undergoing simple harmonic motion or circular motion, the cupola at the observer oscillates at the source's emission frequency Ω₀, regardless of the observer direction 𝐧̂.  The amplitude of the oscillation scales as sin θ, but the temporal frequency does not depend on θ.

With Ω identified as the cupola's temporal repetition frequency, every photon emitted by a source at frequency Ω₀ has the same frequency Ω = Ω₀, regardless of emission angle.  The angular dependence of hyle emission must therefore fall on photon density, not on per-photon energy.  The sin²θ angular distribution falls onto photon number density, not onto per-photon energy.  This is consistent with E = ℏΩ holding for each photon.

The protocol's pings are emitted at uniform angular density ρ₀ at 𝛃 = 0 (Rule 3 reduces to a constant for a stationary source).  Photon density at 𝛃 = 0 scales as sin²θ.  The two cannot stand in one-to-one correspondence; their angular distributions differ.

A photon is therefore a coarse-graining concept, not identifiable with a single ping.  The cupola algorithm's pings are the protocol's primitive directional signals, emitted uniformly.  A photon, in the standard quantum sense, emerges as a feature of the cupola's collective motion at the observer: a packet of cupola oscillation at frequency Ω carrying energy ℏΩ.

A full development of this mapping, including the mechanism by which discrete photon-counting structure emerges from continuous ping streams, is beyond the scope of this article.

## Walls and Geometry

Until now we have considered nodes interacting in unconstrained space.  We now introduce *walls*: extended regions composed of densely packed nodes that can flow freely along the wall but not perpendicular to it.  A wall is therefore not a single object but a structured collection of nodes.

When a ping traveling through space encounters such a wall, the dense free-flowing nodes within the wall collectively respond.  The natural choice is:

> When a ping with translation vector 𝐜 and cupola 𝐂 encounters a wall with surface normal 𝐧̂ₛ:
>
> 1. The ping's translation vector reflects: 𝐜 → 𝐜 − 2(𝐜 · 𝐧̂ₛ)𝐧̂ₛ
> 2. The cupola's tangential component flips while its normal component is preserved: 𝐂 → 2(𝐂 · 𝐧̂ₛ)𝐧̂ₛ − 𝐂

The ping's path bounces in the standard mirror-reflection sense, but the cupola transformation is the negative of a mirror reflection: it flips the tangential component of the cupola while leaving the normal component intact.

This rule has a geometric consequence worth noting.  At any point on the wall surface, the contribution to the local impulse field from the incident ping is its cupola; the contribution from the bounced ping is the transformed cupola.  By the wall rule, the tangential components of these two contributions are equal and opposite at the surface, while the normal components add.  The tangential impulse field vanishes on the wall surface; the normal impulse field doubles.  This is the boundary condition that the dense free-flowing nodes within the wall would impose if their motion were such that no net tangential impulse could persist on the wall surface.

Together with the cupola algorithm, the wall rule yields a complete forward-evaluation scheme for the impulse field in the presence of arbitrary wall geometries.  A useful identity makes implementation straightforward: after k wall encounters, the cumulative cupola transformation reduces to multiplication by (−1)ᵏ.  The complete simulator can therefore be implemented using straight-line ray tracing through the geometry, with the cupola at the target equal to (−1)ᵏ times the unit vector from the appropriate virtual source.

## The Pong Bridge: Open Questions

When a pong returns to a source, an impulse is delivered to the target of the corresponding ping.  We have not specified the mechanism by which the hyle associated with this impulse is bookkept across the two interacting nodes.

### When the Impulse Is Delivered

The impulse described by Rule 1 is locked in when the ping reaches the target but delivered when the pong returns to the source.  Why is the impulse not delivered immediately when the ping arrives at the target?

Consider two nodes A and B separated along the direction of translation, with A leading and B trailing.  Both emit pings continuously.  A's ping reaches B after time L/(c+v), while B's ping reaches A after time L/(c−v).  These one-way times are unequal, and no orientation adjustment of the system can equalize them.  If the impulse were delivered at ping arrival, the impulse on B and the impulse on A would land at different times.  The system would experience a net impulse in some direction at any given moment, and bilateral exchanges would not balance.

The pong return, however, is symmetric.  Combined with the contraction provided by Rule 3, the round-trip times for A's exchange with B and B's exchange with A are equal.  If the impulses are delivered upon pong return rather than ping arrival, the two impulses arrive at A and B simultaneously.  Bilateral exchanges balance.

This dictates the timing in Rule 1.  A consequence worth stating: bilateral exchanges between any pair of nodes deliver equal-and-opposite impulses simultaneously.  The cupola protocol delivers action–reaction balance between any interacting pair, same-type or mixed.

### The Energetics

We now ask how the hyle is accounted for across the bridge endpoints.  There are two natural possibilities.

**Possibility A.**  The impulse parameters are fixed at the moment of ping emission.  The cupola encodes the direction; the geometry encodes the magnitude.  When the pong completes the round trip, the impulse is simply delivered — it was determined in advance.  Because the round-trip times of the two reciprocal bridges are equal, the two impulses are guaranteed to be equal, opposite, and simultaneous.  The hyle books balance not because hyle moves between the nodes but because the two local hyle changes are guaranteed to be equal and opposite by the geometry of the bridges.

**Possibility B.**  Hyle physically transfers across the completed bridge at the moment of completion.  This provides explicit local conservation: the hyle leaving one node is the hyle arriving at the other.  However, the two endpoints of the bridge are spatially separated, and any transfer between them at the moment of bridge completion would be instantaneous over a non-local extent.  No signal travels faster than c in this scenario, since the bridge is established by sub-c pings and pongs and only after the bridge is established does the hyle move; nonetheless, possibility B does involve a non-local transfer at bridge completion, departing from strict locality.

The two possibilities are dynamically equivalent for the cases we have analyzed.  They differ in their account of the underlying energetics, and the difference may matter for cases involving multi-node interactions, partial bridges, or non-equilibrium configurations.  Resolving this question is the central open problem in the dynamics of the protocol.

## Conclusion

Four rules added to the cupola protocol: an impulse of magnitude q|𝐂| along the cupola, locked in at ping arrival and delivered to the target when the corresponding pong returns to the source (Rule 1); two node types (outies and innies) that set the sign of the impulse delivered to a target (Rule 2); an emission angular density (1 − β²)ρ₀/(1 − β cos θ)² in the medium (Rule 3); and a hyle scalar that inflates with motion as η = γη₀ (Rule 4).  From these:

 - Composite systems can form (Rules 1, 2) and translate without falling apart (Rules 3, 4).
 - Moving systems contract along the direction of motion by 1/γ (Rule 3).
 - Moving systems carry kinetic hyle (γ − 1)η₀, with total hyle η = γη₀ (Rule 4).
 - Internal updating of moving systems is reduced by 1/γ (round-trip timing).
 - Rule 4 is forced by Rule 3: the force law Rule 3 produces requires Rule 4's inertial inflation for moving composite systems to behave internally as they did at rest.
 - The impulse on a moving target is the impulse on a stationary target plus a velocity-dependent correction expressible as 𝐯ₜ × 𝐁/c for a derived quantity 𝐁.
 - An accelerating node loses hyle at the rate given by the Liénard formula, reducing to 2q²a²/(3c³) in the non-translating limit.
 - Conservation at emission gives a recoil force −P𝛃/c on a moving accelerating source (vanishing at 𝛃 = 0) and a rest-hyle loss rate η̇₀ = −P/(γc²).
 - Walls obey a tangential-flips, normal-preserves bounce rule.

The energetics of the pong bridge remain open.
