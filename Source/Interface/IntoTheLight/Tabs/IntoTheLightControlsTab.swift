//
//  IntoTheLightControlsTab.swift
//  Aexels
//
//  Phase 1.1 controls — aether velocity, pings per volley, and time
//  steps per volley.
//

import Acheron
import UIKit

class IntoTheLightControlsTab: TabsCellTab {
    unowned let explorer: IntoTheLightExplorer!

    var fieldSlider: RegionSlider!

    let velocitySlider: Slider = Slider()
    let pingsPerVolleySlider: Slider = Slider()
    let timeStepsPerVolleySlider: Slider = Slider()
    let frequencySlider: Slider = Slider()
    let amplitudeSlider: Slider = Slider()

    let magnitudeBoolButton: BoolButton = BoolButton(name: "magnitude")
    let aberrationBoolButton: BoolButton = BoolButton(name: "aberration")
    let fullPingsBoolButton: BoolButton = BoolButton(name: "full pings")
    let deltaCupolaBoolButton: BoolButton = BoolButton(name: "delta cupola")
    let analyticDiscBoolButton: BoolButton = BoolButton(name: "analytic disc")
    let trackSourceBoolButton: BoolButton = BoolButton(name: "track source")

    let velocityLabel: UILabel = UILabel()
    let lambdaLabel: UILabel = UILabel()
    let pingsPerVolleyLabel: UILabel = UILabel()
    let timeStepsPerVolleyLabel: UILabel = UILabel()
    let frequencyLabel: UILabel = UILabel()
    let amplitudeLabel: UILabel = UILabel()

    // Lit while a phantom wave is propagating; goes dark when the
    // slow-direction wavefront finally exits the disc.
    let phantomIndicator: UIView = UIView()
    private var phantomIndicatorTimer: Timer?

    init(explorer: IntoTheLightExplorer) {
        self.explorer = explorer
        super.init(name: "Controls".localized)

        // Field-mode picker: switches between LW-E, LW-B, and LW-R verification.
        fieldSlider = RegionSlider { [unowned self] (page: String) in
            switch page {
            case "Magnetic":
                self.explorer.renderer.fieldMode = .magnetic
                self.applyControlsAvailability(forRadiation: false)
                self.applyModePresets(forRadiation: false)
            case "Radiation":
                self.explorer.renderer.fieldMode = .radiation
                self.applyControlsAvailability(forRadiation: true)
                self.applyModePresets(forRadiation: true)
            default:
                self.explorer.renderer.fieldMode = .electric
                self.applyControlsAvailability(forRadiation: false)
                self.applyModePresets(forRadiation: false)
            }
            // Force one frame so the analytic disc re-renders against
            // the new mode immediately, even if playback is paused.
            self.explorer.stepOnce()
        }
        fieldSlider.pages = ["Electric", "Magnetic", "Radiation"]
        addSubview(fieldSlider)

        // Match SitD (Electromagnetism) ControlsTab: Avenir-Heavy 13*s,
        // right-aligned, white.  Italic variant for the γ readout under
        // the velocity slider.
        let pen: Pen = Pen(font: .avenir(size: 13*s), color: .white, alignment: .right)
        let italicPen: Pen = Pen(font: UIFont(name: "Avenir-HeavyOblique", size: 10*s)!, color: .white, alignment: .right)

        // Universal (always shown) sliders ----------------------------
        pingsPerVolleyLabel.text = "pings per volley".localized
        pingsPerVolleyLabel.pen = pen
        addSubview(pingsPerVolleyLabel)

        pingsPerVolleySlider.options = [12, 24, 36, 48, 60, 120, 240, 360, 480, 600, 900, 1200]
        addSubview(pingsPerVolleySlider)
        pingsPerVolleySlider.onChange = { [unowned self] (count: Int) in
            self.explorer.renderer.pingsPerVolley = Int32(count)
        }

        timeStepsPerVolleyLabel.text = "time steps per volley".localized
        timeStepsPerVolleyLabel.pen = pen
        addSubview(timeStepsPerVolleyLabel)

        timeStepsPerVolleySlider.options = [1, 2, 3, 5, 6, 10, 12, 15, 20, 30, 60, 120, 180, 240, 480, 600]
        addSubview(timeStepsPerVolleySlider)
        timeStepsPerVolleySlider.onChange = { [unowned self] (steps: Int) in
            self.explorer.renderer.timeStepsPerVolley = steps
        }

        // Mode-varying sliders ----------------------------------------
        velocityLabel.text = "aether velocity (% of c)".localized
        velocityLabel.pen = pen
        addSubview(velocityLabel)
        lambdaLabel.attributedText = italicPen.format("γ = \(String(format: "%3.2f", TCGamma(explorer.renderer.velocity)))")
        addSubview(lambdaLabel)

        velocitySlider.options = [0, 10, 20, 50, 70, 90, 99]
        addSubview(velocitySlider)
        // While the slider is being dragged: only update γ and the
        // analytic disc (which reads renderer.velocity directly).  The
        // model rebuild is deferred to onRelease so dragging doesn't
        // queue a phantom calc per tick.
        velocitySlider.onChange = { [unowned self] (percent: Int) in
            let v: Double = Double(percent) / 100
            self.explorer.renderer.velocity = v
            let italicPen: Pen = Pen(font: UIFont(name: "Avenir-HeavyOblique", size: 10*self.s)!, color: .white, alignment: .right)
            self.lambdaLabel.attributedText = italicPen.format("γ = \(String(format: "%3.2f", TCGamma(v)))")
        }
        velocitySlider.onRelease = { [unowned self] _ in
            self.explorer.renderer.commit()
        }

        // Radiation-only: frequency and amplitude sliders.  Slider
        // options are integers; the renderer multiplies by 0.01 for
        // ω (so 4 → ω = 0.04 rad/tic) and uses amplitude directly as
        // world-unit swing.  The two are coupled so peak β = Aω/c
        // never crosses 0.9 — whichever slider the user pushes, the
        // other backs off if the product would otherwise exceed c.
        frequencyLabel.text = "frequency".localized
        frequencyLabel.pen = pen
        addSubview(frequencyLabel)
        frequencySlider.options = [1, 2, 4, 6, 8, 12, 20]
        addSubview(frequencySlider)
        frequencySlider.onChange = { [unowned self] (value: Int) in
            self.explorer.renderer.radiationOmega = Double(value) / 100.0
            self.clampAmplitudeForFrequency()
        }
        frequencyLabel.alpha = 0
        frequencySlider.alpha = 0

        amplitudeLabel.text = "amplitude".localized
        amplitudeLabel.pen = pen
        addSubview(amplitudeLabel)
        amplitudeSlider.options = [5, 10, 15, 25, 50, 100, 200]
        addSubview(amplitudeSlider)
        amplitudeSlider.onChange = { [unowned self] (value: Int) in
            self.explorer.renderer.radiationAmplitude = Double(value)
            self.clampFrequencyForAmplitude()
        }
        amplitudeLabel.alpha = 0
        amplitudeSlider.alpha = 0

        // Bool buttons ------------------------------------------------
        magnitudeBoolButton.on = explorer.renderer.magnitudeOn
        addSubview(magnitudeBoolButton)
        magnitudeBoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.magnitudeOn = on
            // In R mode the setter invalidated the atlas; pump frames
            // synchronously so the new field renders immediately even
            // while paused.
            if self.explorer.renderer.fieldMode == .radiation {
                self.explorer.pumpRadiationAtlas()
            }
            self.explorer.stepOnce()
        }

        aberrationBoolButton.on = explorer.renderer.aberrationOn
        addSubview(aberrationBoolButton)
        aberrationBoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.aberrationOn = on
            if self.explorer.renderer.fieldMode == .radiation {
                self.explorer.pumpRadiationAtlas()
            }
            self.explorer.stepOnce()
        }

        fullPingsBoolButton.on = explorer.renderer.fullPingsOn
        addSubview(fullPingsBoolButton)
        fullPingsBoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.fullPingsOn = on
        }

        // Render ping arms as the delta cupola (C − c·n̂_em = −v_src).
        // Strips the dominant radial-propagation thrust and leaves the
        // source-velocity content — flat in E (zero β), constant in E
        // with drift, oscillating in R.  Pair with full-pings on.
        deltaCupolaBoolButton.on = explorer.renderer.deltaCupolaOn
        addSubview(deltaCupolaBoolButton)
        deltaCupolaBoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.deltaCupolaOn = on
        }
        deltaCupolaBoolButton.alpha = 0  // hidden in E/B; revealed in R

        analyticDiscBoolButton.on = explorer.renderer.analyticDiscOn
        addSubview(analyticDiscBoolButton)
        analyticDiscBoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.analyticDiscOn = on
        }

        // Radiation-only: when on, the camera tracks the oscillating
        // teslon (current behaviour — source stays centred, aether
        // grid streams past).  When off, the camera stays anchored in
        // the aether frame and the source visibly oscillates across
        // the screen.
        trackSourceBoolButton.on = explorer.renderer.radiationTracksSource
        addSubview(trackSourceBoolButton)
        trackSourceBoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.radiationTracksSource = on
        }
        trackSourceBoolButton.alpha = 0  // start hidden; only visible in radiation mode

        // Phantom wave indicator — small filled circle that fades in
        // while a phantom is propagating and fades out when the slow
        // wavefront finally finishes (well after the visible wave has
        // left the disc).  Polled at 10 Hz; cheap compared to draw.
        phantomIndicator.backgroundColor = UIColor.white
        phantomIndicator.layer.cornerRadius = 5*s
        phantomIndicator.alpha = 0
        phantomIndicator.isUserInteractionEnabled = false
        addSubview(phantomIndicator)
        phantomIndicatorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let target: CGFloat = self.explorer.renderer.phantomActive ? 1.0 : 0.0
            if abs(self.phantomIndicator.alpha - target) > 0.01 {
                UIView.animate(withDuration: 0.25) { self.phantomIndicator.alpha = target }
            }
        }
    }

    deinit {
        phantomIndicatorTimer?.invalidate()
    }

    // Coupling helpers — when the user pushes one slider so the product
    // Aω would exceed c, snap the other slider down to the largest
    // option that keeps the source's peak β ≤ 0.9.  Slider.setTo doesn't
    // fire onChange, so this can't recurse.
    private let radiationPeakBetaCap: Double = 0.9
    private let radiationC: Double = 3.0
    private func clampAmplitudeForFrequency() {
        let omega = self.explorer.renderer.radiationOmega
        guard omega > 1e-9 else { return }
        let maxAmp = radiationPeakBetaCap * radiationC / omega
        if self.explorer.renderer.radiationAmplitude > maxAmp {
            if let snap = amplitudeSlider.options.filter({ Double($0) <= maxAmp }).max() {
                amplitudeSlider.setTo(snap)
                self.explorer.renderer.radiationAmplitude = Double(snap)
            }
        }
    }
    private func clampFrequencyForAmplitude() {
        let amp = self.explorer.renderer.radiationAmplitude
        guard amp > 1e-9 else { return }
        let maxOmega = radiationPeakBetaCap * radiationC / amp
        let maxFreqValue = maxOmega * 100.0
        if self.explorer.renderer.radiationOmega > maxOmega {
            if let snap = frequencySlider.options.filter({ Double($0) <= maxFreqValue }).max() {
                frequencySlider.setTo(snap)
                self.explorer.renderer.radiationOmega = Double(snap) / 100.0
            }
        }
    }

    // Per-mode visibility:
    //   • Faded in R only: velocity slider + γ readout (aether velocity
    //     is the E/B story, not the R story).
    //   • Visible only in R: track source, frequency, amplitude,
    //     delta cupola.
    //   • Visible in all modes: magnitude, aberration, full pings,
    //     analytic disc, pings-per-volley, time-steps-per-volley.
    private func applyControlsAvailability(forRadiation: Bool) {
        let faded: [UIView] = [
            velocityLabel, lambdaLabel, velocitySlider
        ]
        for v in faded {
            v.alpha = forRadiation ? 0.0 : 1.0
            v.isUserInteractionEnabled = !forRadiation
        }
        let radiationOnly: [UIView] = [
            trackSourceBoolButton,
            frequencyLabel, frequencySlider,
            amplitudeLabel, amplitudeSlider,
            deltaCupolaBoolButton
        ]
        for v in radiationOnly {
            v.alpha = forRadiation ? 1.0 : 0.0
            v.isUserInteractionEnabled = forRadiation
        }
    }

    // Mode-specific presets.  Applied on every mode switch (so
    // toggling/sliding within a mode is preserved while you stay
    // there, and switching tabs restores the mode's preferred
    // opening view):
    //   E/B: pings 120, timeSteps 12, full pings ON, delta cupola ON
    //        (the latter doesn't matter — control hidden in E/B —
    //        but kept truthful so toggling back to R doesn't carry
    //        a stale value).
    //   R:   pings 36, timeSteps 5, freq 6 (ω=0.06), amplitude 5,
    //        full pings OFF, delta cupola OFF — the radiation icon
    //        view.
    private func applyModePresets(forRadiation: Bool) {
        // Full pings: on for E/B (arrows fan out radially showing the
        // cupola structure); off for R (body-only icon view).
        let fullPings = !forRadiation
        explorer.renderer.fullPingsOn = fullPings
        fullPingsBoolButton.on = fullPings

        // Delta cupola: ALWAYS off on mode switch.  In E/B it's not
        // meaningful (the control is hidden); in R the icon view wants
        // it off too.  User can opt in within R.
        explorer.renderer.deltaCupolaOn = false
        deltaCupolaBoolButton.on = false

        let pings: Int32 = forRadiation ? 36 : 120
        // timeSteps × 3 and freq / 3 vs the pre-c=1.0 defaults — keeps
        // wavelength-per-volley roughly constant now that the radiation
        // wavefront propagates at 1.0 instead of 3.0.
        let steps: Int = forRadiation ? 15 : 12
        explorer.renderer.pingsPerVolley = pings
        explorer.renderer.timeStepsPerVolley = steps
        pingsPerVolleySlider.setTo(Int(pings))
        timeStepsPerVolleySlider.setTo(steps)

        if forRadiation {
            explorer.renderer.radiationOmega = 0.02
            explorer.renderer.radiationAmplitude = 5.0
            frequencySlider.setTo(2)
            amplitudeSlider.setTo(5)
        }
    }

// AEView ==========================================================================================
    override func layoutSubviews() {
        let sliderWidth: CGFloat = width-60*s

        // Field-mode picker at the top, full width.
        fieldSlider.frame = CGRect(x: 30*s, y: 12*s, width: sliderWidth, height: 28*s)

        // Phantom indicator: small dot just inside the right edge,
        // vertically centred on the field-mode picker.
        phantomIndicator.frame = CGRect(x: width - 22*s, y: 21*s, width: 10*s, height: 10*s)

        // SitD-style spacing: label (height 18*s), then 12*s gap, then
        // slider (height 40*s), then 50*s gap to the next block.
        var y: CGFloat = 56*s

        // Universal sliders at the top -------------------------------
        pingsPerVolleyLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 12*s
        pingsPerVolleySlider.top(dy: y, width: sliderWidth, height: 40*s)
        y += 50*s

        timeStepsPerVolleyLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 12*s
        timeStepsPerVolleySlider.top(dy: y, width: sliderWidth, height: 40*s)
        y += 50*s

        // Mode-varying sliders ---------------------------------------
        // Velocity (E/M) and frequency (R) share the same slot — they
        // are never visible at the same time.
        velocityLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        frequencyLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 12*s
        velocitySlider.top(dy: y, width: sliderWidth, height: 40*s)
        frequencySlider.top(dy: y, width: sliderWidth, height: 40*s)
        // γ readout floats just under the velocity slider (E/M only).
        lambdaLabel.topLeft(dx: 30*s, dy: y + 40*s - 3*s, width: 240*s, height: 16*s)
        y += 50*s

        // Amplitude (R only) — empty slot in E/M.
        amplitudeLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 12*s
        amplitudeSlider.top(dy: y, width: sliderWidth, height: 40*s)
        y += 50*s

        // Bool buttons -----------------------------------------------
        // Each toggle gets its own slot.  Track-source slot is empty in
        // E/B; delta-cupola slot is empty in E/B; both fill in R mode.
        y += 10*s
        trackSourceBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        magnitudeBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        aberrationBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        fullPingsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        deltaCupolaBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        analyticDiscBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)

        velocitySlider.setTo(Int(explorer.renderer.velocity * 100))
        pingsPerVolleySlider.setTo(Int(explorer.renderer.pingsPerVolley))
        timeStepsPerVolleySlider.setTo(explorer.renderer.timeStepsPerVolley)
        frequencySlider.setTo(Int(round(explorer.renderer.radiationOmega * 100)))
        amplitudeSlider.setTo(Int(round(explorer.renderer.radiationAmplitude)))
    }
}
