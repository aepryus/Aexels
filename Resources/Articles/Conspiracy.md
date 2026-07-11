# Conspiracy

Imagine a model of ship, the Chronos, with a large digital display on its hull that is linked to a stopwatch inside the ship.

![](Chronos)

Two of these ships are placed 1 AU apart with a beacon placed equidistant between them.  The beacon flashes and when each ship receives the signal they start their stopwatches and one of the ships blasts off towards the other.  When the ships pass one another they both note their clock and the other ship's clock.

What is the 'win condition' here that proves the following:
- basic physical reality: that two observers looking at the same display at the same time at the same place will see the same thing.
- dilation: that the clocks in the two ships will move at different rates.
- reciprocity: that both ships will see the other ship's clock as being dilated.

If the observers read different values off the same display while looking at it at the same time from the same place, then physical reality breaks down.  There is no magic 'relativity of simultaneity' wand coming to the rescue here.

If both clocks show the same value, then dilation breaks down.

If both observers see a fast clock and a slow clock and agree on which is which than reciprocity breaks down.

There is no win condition that confirms all three, only two can be true.  Luckily while there is a multitude of experimental evidence for basic physical reality and much evidence for dilation, there is precisely zero evidence for reciprocity.  Not a single experiment has ever confirmed it.  This makes the choice of which condition to abandon quite easy.

Reciprocity can not be true.

## The Experiment

The discrepancy between Universe X and General Relativity is not merely theoretical.  It is testable with modest equipment.

Send a clock up a vertical track, measure its elapsed ticks.  Send the same clock down the same track at the same speed, measure its elapsed ticks.  Compare the two numbers.

General Relativity predicts the two numbers are identical; time dilation depends on speed squared, so direction does not matter.

Universe X predicts they differ.  The Earth's gravitational field creates an aether inflow at 11.2 km/s.  A clock moving downward moves with that flow and experiences less total dilation.  A clock moving upward moves against it and experiences more.  The difference is proportional to 2 × 11,200 × v_cart / c².

At a cart speed of 5 m/s, the fractional dilation difference between up and down runs is about 1.2 × 10⁻¹².  At 30 m/s, about 7.5 × 10⁻¹².  A good OCXO has short-term stability of 10⁻¹² to 10⁻¹³, so the signal is detectable with modest averaging.

The hardware is straightforward: a 1-meter V-slot aluminum rail mounted vertically, a roller carriage carrying a military-grade OCXO, a small battery and an ESP32 with Bluetooth for readout, a pneumatic launcher at one end and an eddy current copper plate brake at the other, with a stationary reference OCXO on the bench.  Total cost under $2000.

The result is binary.  Either the up count and down count differ systematically, or they do not.  A few thousand runs, achievable in a day of automated operation, would give a definitive answer at high statistical significance.

Why has this not been done?  General Relativity predicts exactly zero difference.  No one builds experiments to measure effects their theory says do not exist.  Every prior test of gravitational time dilation has used static clocks, which both frameworks agree on.  The specific comparison of moving clocks in opposite vertical directions has never been performed.
