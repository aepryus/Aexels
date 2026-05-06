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

    let magnitudeBoolButton: BoolButton = BoolButton(name: "magnitude")
    let aberrationBoolButton: BoolButton = BoolButton(name: "aberration")
    let fullPingsBoolButton: BoolButton = BoolButton(name: "full pings")
    let analyticDiscBoolButton: BoolButton = BoolButton(name: "analytic disc")

    let velocityLabel: UILabel = UILabel()
    let lambdaLabel: UILabel = UILabel()
    let pingsPerVolleyLabel: UILabel = UILabel()
    let timeStepsPerVolleyLabel: UILabel = UILabel()

    init(explorer: IntoTheLightExplorer) {
        self.explorer = explorer
        super.init(name: "Controls".localized)

        // Field-mode picker: switches between LW-E and LW-B verification.
        fieldSlider = RegionSlider { [unowned self] (page: String) in
            self.explorer.renderer.fieldMode = (page == "Magnetic") ? .magnetic : .electric
        }
        fieldSlider.pages = ["Electric", "Magnetic"]
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
    }

// AEView ==========================================================================================
    override func layoutSubviews() {
        let sliderWidth: CGFloat = width-60*s

        // Field-mode picker at the top, full width.
        fieldSlider.frame = CGRect(x: 30*s, y: 12*s, width: sliderWidth, height: 28*s)

        var y: CGFloat = 56*s

        velocityLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        lambdaLabel.topLeft(dx: 30*s, dy: velocityLabel.bottom-3*s, width: 240*s, height: 20*s)
        y += 24*s
        velocitySlider.top(dy: y, width: sliderWidth, height: 40*s)
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
        y += 30*s
        aberrationBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        fullPingsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        analyticDiscBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)

        velocitySlider.setTo(Int(explorer.renderer.velocity * 100))
        pingsPerVolleySlider.setTo(Int(explorer.renderer.pingsPerVolley))
        timeStepsPerVolleySlider.setTo(explorer.renderer.timeStepsPerVolley)
    }
}
