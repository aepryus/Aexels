//
//  IntoTheLightControlsTab.swift
//  Aexels
//
//  Phase 1 controls for the Into the Light Lab — single VSlider for
//  aether velocity (positive values slide the aether to the left
//  underneath a centered teslon).
//

import Acheron
import UIKit

class IntoTheLightControlsTab: TabsCellTab {
    unowned let explorer: IntoTheLightExplorer!

    let velocitySlider: Slider = Slider()
    let velocityLabel: UILabel = UILabel()
    let lambdaLabel: UILabel = UILabel()

    init(explorer: IntoTheLightExplorer) {
        self.explorer = explorer
        super.init(name: "Controls".localized)

        velocitySlider.options = [0, 10, 20, 50, 70, 90, 99]
        addSubview(velocitySlider)
        velocitySlider.onChange = { (percent: Int) in
            let v: Double = Double(percent) / 100
            self.explorer.renderer.velocity = v
            let italicPen: Pen = Pen(font: UIFont(name: "Verdana-Italic", size: 10*self.s)!, color: .white, alignment: .right)
            self.lambdaLabel.attributedText = italicPen.format("γ = \(String(format: "%3.2f", TCGamma(v)))")
        }

        let pen: Pen = Pen(font: .verdana(size: 15*s), color: .white, alignment: .right)
        let italicPen: Pen = Pen(font: UIFont(name: "Verdana-Italic", size: 10*s)!, color: .white, alignment: .right)

        velocityLabel.attributedText = pen.format("aether velocity (% of c)")
        addSubview(velocityLabel)

        lambdaLabel.attributedText = italicPen.format("γ = \(String(format: "%3.2f", TCGamma(0)))")
        addSubview(lambdaLabel)
    }

// AEView ==========================================================================================
    override func layoutSubviews() {
        var y: CGFloat = 30*s
        let sliderWidth: CGFloat = width-60*s

        velocityLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        lambdaLabel.topLeft(dx: 30*s, dy: velocityLabel.bottom-3*s, width: 240*s, height: 20*s)
        y += 24*s
        velocitySlider.top(dy: y, width: sliderWidth, height: 40*s)

        velocitySlider.setTo(0)
    }
}
