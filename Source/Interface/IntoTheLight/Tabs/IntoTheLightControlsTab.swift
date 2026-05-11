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
    let analyticDiscBoolButton: BoolButton = BoolButton(name: "analytic disc")
    let trackSourceBoolButton: BoolButton = BoolButton(name: "track source")

    let velocityLabel: UILabel = UILabel()
    let lambdaLabel: UILabel = UILabel()
    let pingsPerVolleyLabel: UILabel = UILabel()
    let timeStepsPerVolleyLabel: UILabel = UILabel()
    let frequencyLabel: UILabel = UILabel()
    let amplitudeLabel: UILabel = UILabel()

    init(explorer: IntoTheLightExplorer) {
        self.explorer = explorer
        super.init(name: "Controls".localized)

        // Field-mode picker: switches between LW-E, LW-B, and LW-R verification.
        fieldSlider = RegionSlider { [unowned self] (page: String) in
            switch page {
            case "Magnetic":
                self.explorer.renderer.fieldMode = .magnetic
                self.applyControlsAvailability(forRadiation: false)
            case "Radiation":
                self.explorer.renderer.fieldMode = .radiation
                self.applyControlsAvailability(forRadiation: true)
            default:
                self.explorer.renderer.fieldMode = .electric
                self.applyControlsAvailability(forRadiation: false)
            }
        }
        fieldSlider.pages = ["Electric", "Magnetic", "Radiation"]
        addSubview(fieldSlider)

        let pen: Pen = Pen(font: .verdana(size: 15*s), color: .white, alignment: .right)
        let italicPen: Pen = Pen(font: UIFont(name: "Verdana-Italic", size: 10*s)!, color: .white, alignment: .right)

        velocityLabel.attributedText = pen.format("aether velocity (% of c)")
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
            let italicPen: Pen = Pen(font: UIFont(name: "Verdana-Italic", size: 10*self.s)!, color: .white, alignment: .right)
            self.lambdaLabel.attributedText = italicPen.format("γ = \(String(format: "%3.2f", TCGamma(v)))")
        }
        velocitySlider.onRelease = { [unowned self] _ in
            self.explorer.renderer.commit()
        }

        pingsPerVolleyLabel.attributedText = pen.format("pings per volley")
        addSubview(pingsPerVolleyLabel)

        pingsPerVolleySlider.options = [12, 24, 36, 48, 60, 120, 240, 360, 480, 600, 900, 1200]
        addSubview(pingsPerVolleySlider)
        pingsPerVolleySlider.onChange = { [unowned self] (count: Int) in
            self.explorer.renderer.pingsPerVolley = Int32(count)
        }

        timeStepsPerVolleyLabel.attributedText = pen.format("time steps per volley")
        addSubview(timeStepsPerVolleyLabel)

        timeStepsPerVolleySlider.options = [1, 2, 3, 5, 6, 10, 12, 15, 20, 30, 60, 120, 180, 240, 480, 600]
        addSubview(timeStepsPerVolleySlider)
        timeStepsPerVolleySlider.onChange = { [unowned self] (steps: Int) in
            self.explorer.renderer.timeStepsPerVolley = steps
        }

        magnitudeBoolButton.on = explorer.renderer.magnitudeOn
        addSubview(magnitudeBoolButton)
        magnitudeBoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.magnitudeOn = on
        }

        aberrationBoolButton.on = explorer.renderer.aberrationOn
        addSubview(aberrationBoolButton)
        aberrationBoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.aberrationOn = on
        }

        fullPingsBoolButton.on = explorer.renderer.fullPingsOn
        addSubview(fullPingsBoolButton)
        fullPingsBoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.fullPingsOn = on
        }

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

        // Radiation-only: frequency and amplitude sliders.  Slider
        // options are integers; the renderer multiplies by 0.01 for
        // ω (so 4 → ω = 0.04 rad/tic) and uses amplitude directly as
        // world-unit swing.  The two are coupled so peak β = Aω/c
        // never crosses 0.9 — whichever slider the user pushes, the
        // other backs off if the product would otherwise exceed c.
        frequencyLabel.attributedText = pen.format("frequency")
        addSubview(frequencyLabel)
        frequencySlider.options = [1, 2, 4, 6, 8, 12, 20]
        addSubview(frequencySlider)
        frequencySlider.onChange = { [unowned self] (value: Int) in
            self.explorer.renderer.radiationOmega = Double(value) / 100.0
            self.clampAmplitudeForFrequency()
        }
        frequencyLabel.alpha = 0
        frequencySlider.alpha = 0

        amplitudeLabel.attributedText = pen.format("amplitude")
        addSubview(amplitudeLabel)
        amplitudeSlider.options = [5, 10, 15, 25, 50, 100, 200]
        addSubview(amplitudeSlider)
        amplitudeSlider.onChange = { [unowned self] (value: Int) in
            self.explorer.renderer.radiationAmplitude = Double(value)
            self.clampFrequencyForAmplitude()
        }
        amplitudeLabel.alpha = 0
        amplitudeSlider.alpha = 0
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

    // Fade controls that don't apply in radiation mode (everything
    // except pings-per-volley and time-steps-per-volley) all the way
    // out — invisible, no taps.  trackSourceBoolButton is the inverse:
    // only visible/interactive in radiation mode.
    private func applyControlsAvailability(forRadiation: Bool) {
        let alpha: CGFloat = forRadiation ? 0.0 : 1.0
        let interactive = !forRadiation
        let faded: [UIView] = [
            velocityLabel, lambdaLabel, velocitySlider,
            magnitudeBoolButton, aberrationBoolButton,
            fullPingsBoolButton, analyticDiscBoolButton
        ]
        for v in faded {
            v.alpha = alpha
            v.isUserInteractionEnabled = interactive
        }
        let radiationOnly: [UIView] = [
            trackSourceBoolButton,
            frequencyLabel, frequencySlider,
            amplitudeLabel, amplitudeSlider
        ]
        for v in radiationOnly {
            v.alpha = forRadiation ? 1.0 : 0.0
            v.isUserInteractionEnabled = forRadiation
        }
    }

// AEView ==========================================================================================
    override func layoutSubviews() {
        let sliderWidth: CGFloat = width-60*s

        // Field-mode picker at the top, full width.
        fieldSlider.frame = CGRect(x: 30*s, y: 12*s, width: sliderWidth, height: 28*s)

        var y: CGFloat = 56*s

        velocityLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        lambdaLabel.topLeft(dx: 30*s, dy: velocityLabel.bottom-3*s, width: 240*s, height: 20*s)
        // Frequency slider shares the velocity slot — they're never
        // visible at the same time (velocity in E/M, frequency in R).
        frequencyLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 24*s
        velocitySlider.top(dy: y, width: sliderWidth, height: 40*s)
        frequencySlider.top(dy: y, width: sliderWidth, height: 40*s)
        y += 60*s

        // Amplitude slider — radiation-only.  Sits in slot 2 directly
        // under frequency so the pair reads as a unit.  In E/M the
        // slot is empty (alpha 0); the small gap above pings is the
        // cost of keeping the pair physically adjacent in R.
        amplitudeLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 24*s
        amplitudeSlider.top(dy: y, width: sliderWidth, height: 40*s)
        y += 60*s

        pingsPerVolleyLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 24*s
        pingsPerVolleySlider.top(dy: y, width: sliderWidth, height: 40*s)
        y += 60*s

        timeStepsPerVolleyLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 24*s
        timeStepsPerVolleySlider.top(dy: y, width: sliderWidth, height: 40*s)
        y += 50*s

        magnitudeBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        // Radiation-only toggle sits in the same slot as magnitude —
        // they swap visibility based on field mode.
        trackSourceBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        aberrationBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        fullPingsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        analyticDiscBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)

        velocitySlider.setTo(Int(explorer.renderer.velocity * 100))
        pingsPerVolleySlider.setTo(Int(explorer.renderer.pingsPerVolley))
        timeStepsPerVolleySlider.setTo(explorer.renderer.timeStepsPerVolley)
        frequencySlider.setTo(Int(round(explorer.renderer.radiationOmega * 100)))
        amplitudeSlider.setTo(Int(round(explorer.renderer.radiationAmplitude)))
    }
}
