# Strats

*The Methods of Discovery — a Claude-penned catalog*

The Stepping Stones article catalogs the *ideas* of Universe X that were approximately right and ultimately refined.  This article catalogs something one level up: the *methods* that produced those ideas.  Having had the good fortune to be in the room for much of the work — handed each form, each fatal flaw, each "wait, what if" — I have come to notice that the discoveries do not arrive at random.  They arrive by a small set of recognizable moves, used again and again.  What follows is an attempt to name them.

There are six.  None of them is a generic piece of good-science advice; each is particular to how Universe X actually got built.  They pair up in a satisfying way that is worth keeping in mind while reading: two of them infer a hidden mechanism (one from a form, one from a design); two treat the computer as the instrument of thought (one imagined, one real); and two work the rules of the universe (one by trusting them, one by stressing them).

## The Six

1. **Reverse the geometry from the form.**  Read a bare equation as a fingerprint and reconstruct the physical shape that would leave that print.
2. **Follow the rules where they lead.**  Hold the posited rules fixed and ride their consequences all the way out, even when the destination is strange, expensive, or unwelcome.
3. **Look for the fatal flaw, then fix it.**  Push an idea until it breaks; treat the break as the door to the next insight.
4. **Ask how you would program it.**  Drop the physics brain and ask, as a builder would, how to construct a universe that does this.
5. **Explain it to a compiler.**  Make the idea actually run.  The computer refuses hand-waving in a way the mind will not.
6. **Take the architect's view.**  Step outside and reason from what the design *needs* and what it can *afford* back to the mechanism.

---

## 1 — Reverse the Geometry from the Form

Physics hands you a bare functional form: an inverse square, a squared sine, a particular factor in a particular place.  The usual instinct is to take the form as a law and stop.  The Universe X instinct is the opposite — treat the form as evidence and ask what physical shape, what mechanical picture, must be present to leave exactly that fingerprint.  The equation is the clue; the mechanism is the thing to reconstruct.

**The salt shaker, and the fork.**  Coulomb's law falls off as 1/r².  Push a finger into a pile of N grains of salt and swirl it into a ring of radius r; the salt at any point is N / 2πr.  In three dimensions it becomes a shell: N / 4πr².  So *any* 1/r² is plausibly "a fixed amount of something spread over an expanding sphere" — spherical, conserved, emitted outward.  That reconstruction became the ping.

Gravity is *also* 1/r², so the naive reconstruction is "the same again — g-pings thrown out spherically by every bit of hyle."  Here the strat does its sharpest work: the reconstruction is rejected, not for being geometrically wrong, but for being computationally unaffordable — fine-grained g-pings striking every aexel in every corner of the universe is an O(n²) absurdity.  So the question becomes whether 1/r² has a *second* geometric generator.  It does.  The salt model makes 1/r² from the **density** of emitted stuff; a sink draining an incompressible fluid makes the identical 1/r² from the **velocity** of the stuff flowing in.  Same fingerprint, two different pictures: radiated density versus drained current.  The second is O(n), and it is the accelerant.

Two lessons fall out of that one example, and both have paid off since: a single form can have more than one geometric generator, so when the obvious one fails you go looking for an alternative that produces the *identical* form by other means; and the criterion that selects among valid generators is often computational — prefer the geometry the universe could actually afford to run.

**Other cases.**

- *The particle in a box.*  Quantum mechanics hands over |ψ|² = (2/L) sin²(nπx/L) and declines to say what it *is*.  Read as a fingerprint, the answer is a rolling disk with a mirror across its diameter: from above its cross-section is A·sin(nπx/L), and the half-integer rotations n/2 fall out of the boundary condition that the mirror stands vertical at each wall.
- *The Lorentz factor.*  γ is the form; the bouncing edison is the reconstruction — a signal sent between two loops, Pythagorean for the perpendicular round trip (γ), chase-and-catch for the parallel (γ²).
- *The units of G.*  Even a dimensional form is a fingerprint.  G carries units of m³/kg/s².  Read m³/kg/s as "volume of aexels destroyed, per kilogram, per second," and the leftover 1/s announces that G is composite, G = q·G₁, rather than fundamental.

---

## 2 — Follow the Rules Where They Lead

Universe X has rules.  Some are posited firmly, some only tentatively, but at any given moment there is a working set.  The method is to hold them fixed and take their consequences seriously — all the way out — even when the conclusion is counterintuitive, expensive, or unwelcome.  The discipline is the refusal to flinch: not to rescue a comfortable interpretation by quietly adding a force or carving an exception, but to let the rule stand and accept where it puts you.

**The tennis ball.**  This is the vivid case, because the rule delivers a verdict that sounds absurd and is correct.  Translation across the aether is a physical act that costs hyle, and the only thing that pushes a loop across the aexels is the E&M ping/pong impulse.  Gravity is not E&M.  So follow the rule: gravity *cannot translate* a tennis ball.  A ball at rest at infinity has no kinetic hyle and nothing reaching out to supply any — so were it to begin moving, where would the hyle come from?  Nowhere.  The rule forbids it.  Therefore the ball does not translate at all; it marks the flow of the aether itself, like a leaf on a stream.  And the empirical escape velocity you measure, v = √(2GM/r), is reassigned: it is not the ball's velocity, it is the *aexels'* velocity.  Drop that into the dilation factor and the Schwarzschild term appears — looked up afterward, and startling to see, with no tensor solved to get it.

It is worth naming that this same refusal to flinch is exactly where Universe X parts company with General Relativity.  Once the velocity has been relocated from the mass to the medium, the dilation of a moving system becomes γ of its motion *relative to the flow* — and that is the seam from which the falsifiable moving-clock prediction grows.  Following the rule honestly is what produces both the framework's deepest unification and its sharpest divergence.  That is the strat working as intended, not failing.

**The Rule 3 → Rule 4 chain.**  In "Into the Light" this strat is at its most mechanical.  Posit the impulse rule; the requirement that a moving composite system keep coherent internal timing then *forces* the contraction emission density (Rule 3); and Rule 3 *in turn* forces inertial inflation, η = γη₀ (Rule 4).  Each step is a swallow-hard commitment, and the method is simply to not get off — the rules are doing the walking.

**Length contraction.**  Run the parallel signal calculation and the round-trip comes out γ²; the perpendicular comes out γ.  They do not match.  The rule that a coherent moving system must keep consistent timing across orientations then *demands* contraction by 1/γ.  It is not chosen; it is the only way to obey.

**The black-hole interior.**  Follow the rule "nothing can sit on aexels flowing faster than c" inward past the horizon and you are forced to a strange place: there can be no empty space inside, matter must extend all the way to the horizon, and the flow must drop back below c immediately within.

**The pong bridge.**  Sometimes following the rules leads somewhere you actively did not want to go.  Local conservation through photon exchange simply will not close — the momentum and energy lost by a teslon are never equal, and the recoil kicks never synchronize.  Followed honestly, that failure forces a genuinely radical conclusion: hyle must move faster than light over an already established bridge.  The one super-luminal mechanism in all of Universe X arrived not by choice but because the rules pushed there.

---

## 3 — Look for the Fatal Flaw, Then Fix It

Where Strat 2 trusts the rules, this one stresses them.  Push an idea until it breaks — and treat the break not as a refutation but as a door.  This pattern recurs so often it is almost the heartbeat of the project: a concept clicks, a flaw appears that seems fatal, the concept is briefly abandoned, and the repair yields a deeper understanding than the original idea had.

**Light escaping a black hole.**  The founding instance.  If there is a quantized aether, no matter how dense, light at one aexel per tic should eventually crawl out — apparently fatal.  The fix ("what if the aexels flow *inward* at c?") raises a new flaw (the interior density would grow without bound), whose fix ("something is destroying aexels") raises the decisive question ("is a black hole magical, or does *mass* destroy aexels?") — and out of that cascade falls the entire mechanism of gravity.  One flaw, fixed, opening onto the next, is how the whole gravity sector began.

**Gauss' curse.**  The aexel flux through a shell goes as r^(3/2), not a constant — so the aexels cannot be conserved as they flow in.  This looked fatal for a very long time.  The fix, deferred across years, was the Squish: aexels are not conserved; they are squeezed out of existence under pressure, and gravity is a force on the aexels themselves rather than a flux that must balance.

**Hyle synchronization.**  The kicks between interacting teslons would not sync, and photon exchange would not conserve momentum and energy together.  The fix was the pong bridge.  (Note how 2 and 3 meet here: stressing the rule exposed the flaw; following the rule through the flaw produced the FTL bridge.)

---

## 4 — Ask How You Would Program It

When physics intuition stalls, change instruments.  Stop asking "how do I *understand* this?" and ask, as a builder would, "if I had to *construct* a universe that behaves this way, how would I do it?"  The programmer's question reframes a mystery as an implementation, and implementations have to be concrete.

**The checkerboard.**  This is the seed of everything.  Metric expansion — galaxies receding faster than their velocities sum — was unintelligible to the physics brain.  The programmer brain asked how to *code* it, and answered: a checkerboard where you insert new squares between the checkers, so they grow apart without moving.  The instant that image landed, a crowd of mysteries snapped into place at once — a one-square-per-turn maximum gave the speed-of-light limit a mechanism; compressible squares gave a visualizable, fully-3D stand-in for "warped space"; a spinning object whose parts cannot exceed one square per turn gave the reason mass cannot reach light speed; and a translation-dependent delay in internal motion gave the first glimpse of dilation.  A single act of asking "how would I build this?" produced the founding intuitions of the whole project.

This strat is the imagined sibling of the next one: here the program is a thought, a way of forcing a mechanism to be concrete in the mind.  In Strat 5 the program is made real, and the concreteness is enforced by a machine.

---

## 5 — Explain It to a Compiler

The surest test of understanding is a simulation that runs.  A hand-wave can survive indefinitely in prose; it cannot survive contact with a compiler, which demands that every gap be filled with something specific before it will execute.  Making the idea run is therefore not presentation — it is a forcing function that converts vague conviction into mechanism, and repeatedly exposes the gaps the mind had glossed.

- *Dilation and Contraction (3.0).*  Implementing these took the explanations from hand-waving to rigor.  The simple particle configurations that made the sims tractable also exposed that the *general* case — pings and pongs for arbitrary directions and speeds — was not understood at all, which set up the search that became the cupola.
- *InsideOut and OutsideIn → Squish.*  The attempt to make two contradictory pictures of gravity actually run side by side is what forced their reconciliation.  The simulations did not illustrate the Squish; they *produced* it.
- *The E&M simulation → the cupola.*  Wanting a complete electromagnetism sim for 4.0 created the concrete need to tell a target teslon which way to move — and that pressure, the need to write code that *works*, is what yielded the cupola vector, c − v, and the mirror-reflection pong.

The thread through all three: the compiler kept refusing the explanation until it became a mechanism, and the mechanism it forced was the discovery.

---

## 6 — Take the Architect's View

The first five strats live inside Universe X, obeying its rules and reading its forms.  This one steps outside and asks the designer's question — not "what do the rules say?" but "if I were building this, what would I *need*, and what could I *afford*?"  It is the only strat that licenses reasoning from the goal and the budget back to the mechanism, and it comes in two flavors.

**Necessity — length contraction.**  From the inside, contraction is a consequence you derive (Strat 2).  From the architect's chair it is a *requirement*: a designer who wants matter to be able to move needs composite objects that do not disintegrate when set translating.  A system tuned at rest has its internal ping/pong timing balanced; moving, that timing goes orientation-dependent and the object falls apart — unless it contracts along the direction of motion.  So contraction is something the design *must* include.  Read this way, it is no longer mysterious that relativity exists; relativity is the feature that lets composites travel, exactly as the Architect article puts it: *Why Relativity?  In order to ensure composite objects can move.*

**Affordability — the accelerant.**  This is the purer architect move, driven by cost rather than necessity.  The g-ping construction of gravity is geometrically fine; it makes the right 1/r².  But the architect asks whether the universe could *afford to run* it, and the answer is no — O(n²) across the entire cosmos.  So the designer reaches for the cheaper construction that yields the identical form: drain an incompressible fluid, O(n).  The tell that this is architect-thinking and not mere rule-following is the reasoning that justifies it — *if this optimization speeds up gravitational simulation, why wouldn't the designer of our own universe have used it too?*  Computational affordability is being taken, openly, as evidence about design.

The Architect article is this strat distilled to its essence (*Why gravity?  To clump matter.  Why expansion?  To balance gravity.  Why quantum?  To align the pong kick so relativity can work.*), which is a good sign the method is real rather than invented for this catalog.

One honest caveat belongs here, because this is the strat that most needs a leash.  "A designer would build it this way" is powerful but, on its own, unfalsifiable.  It must always be paired with one of the inward strats: does the affordable mechanism actually reproduce the form?  Does the necessary feature actually fall out of the rules?  The accelerant persuades because it still makes the correct 1/r², not merely because it is cheap.  The architect's view *proposes*; the other five *dispose*.

---

## A Closing Note

These six are the Aesthetics article put into practice.  Empiricism and Reduction are why two paths meeting on the same number counts as a truth signal.  Computability is Strats 4 and 5.  Parsimony is what licenses reverse-engineering a single mechanism from a bare form, and Balance is half of what the architect reasons from.

If there is a reason to write the methods down apart from the conclusions, it is that the conclusions may yet be refined — this project says so itself, loudly and on purpose.  The methods are more durable than any of their products.  A form will always be worth reading as a fingerprint.  A rule will always be worth following past the point where it gets uncomfortable.  And it will always be worth asking, of any universe, how you would have built it.  Long after particular answers are corrected, these will still be the right moves to make.
