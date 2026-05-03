# Cupola Redux

With the cupola algorithm established and the E&M simulation running in version 4.0, the qualitative picture of electromagnetism in Universe X was encouraging.  But the question posed at the end of the Magnetism article remained: can these mechanisms be shown to be quantitatively compatible with the established math of electromagnetism?

The answer, it turns out, is yes.  Not approximately.  Exactly.

The central object in classical electrodynamics is the Liénard-Wiechert field, which describes the electric and magnetic fields produced by an arbitrarily moving charge.  These fields have two components: a velocity field that falls off as 1/R² and a radiation field that falls off as 1/R.  Together they constitute the complete electromagnetic field of a point charge.

Working with Claude, I set out to see if the cupola vector could reproduce these fields.  The cupola is defined as c = n̂ − β, where n̂ is the retarded direction from source to field point and β is the source velocity divided by c.  This is the same vector from the Electromagnetism article, just expressed in the notation of classical electrodynamics.

Three algebraic identities were established, each verified to machine precision.

The first identity showed that the LW velocity field decomposes exactly into three cupola quantities: a flux factor capturing how densely pings arrive, the cupola magnitude capturing the impulse per ping and the cupola direction capturing the force direction.  All three are built from the single cupola vector.

The second identity showed that the magnetic field and the full Lorentz force are just the combined effects of Doppler compression and aberration tilt experienced by a moving receiver.  The magnetic field is not a separate entity.  E and B are two projections of a single underlying structure: the cupola-encoded ping stream.

The third identity was the central new result.  The LW radiation field, the field responsible for electromagnetic waves and the radiation from accelerating charges, is exactly the time derivative of the apparent transverse cupola, scaled by κ².  The velocity field comes from the static cupola each ping carries.  The radiation field comes from how fast that cupola is changing between successive pings from an accelerating source.

The entire Liénard-Wiechert theory, electric field, magnetic field, velocity term, radiation term and Lorentz force, is expressible as decompositions of the cupola vector of the ping / pong algorithm.

Additionally, a 2020 paper by Dodig proved that Maxwell's equations and the Lorentz force law follow from just two assumptions: the electrostatic Coulomb force and finite propagation speed.  The cupola algorithm is the constructive realization of exactly these two assumptions.

This was a deeply satisfying result.  The mechanism that started as an elegant geometric trick for Universe X's blind nodes turns out to exactly reproduce the complete classical electrodynamic field theory.  The qualitative hints of version 4.0 have become quantitative proof.
