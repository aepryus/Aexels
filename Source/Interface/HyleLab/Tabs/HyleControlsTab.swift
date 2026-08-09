//
//  HyleControlsTab.swift
//  Aexels
//
//  The bridge state, exposed: (v_A, v_B, r/L).  Speeds in % of c,
//  directions in degrees, node extent as % of separation.  The case
//  picker writes the same variables the sliders do; touching a slider
//  makes the case "custom".
//

import Acheron
import UIKit

class HyleControlsTab: TabsCellTab {
    unowned let explorer: HyleLabExplorer!

    var caseSlider: RegionSlider!

    let betaASlider: Slider = Slider()
    let thetaASlider: Slider = Slider()
    let betaBSlider: Slider = Slider()
    let thetaBSlider: Slider = Slider()
    let ratioSlider: Slider = Slider()

    let betaALabel: UILabel = UILabel()
    let thetaALabel: UILabel = UILabel()
    let betaBLabel: UILabel = UILabel()
    let thetaBLabel: UILabel = UILabel()
    let ratioLabel: UILabel = UILabel()
    let gammaALabel: UILabel = UILabel()
    let gammaBLabel: UILabel = UILabel()

    init(explorer: HyleLabExplorer) {
        self.explorer = explorer
        super.init(name: "Controls".localized)

        caseSlider = RegionSlider { [unowned self] (page: String) in
            let index: Int
            switch page {
                case "∥ 0.6":    index = 1
                case "⊥ 0.6":    index = 2
                case "head-on":  index = 3
                default:         index = 0
            }
            self.explorer.renderer.applyPreset(index)
            self.sync()
        }
        caseSlider.pages = ["static", "∥ 0.6", "⊥ 0.6", "head-on"]
        addSubview(caseSlider)

        let pen: Pen = Pen(font: .avenir(size: 13*s), color: .white, alignment: .right)
        let italicPen: Pen = Pen(font: UIFont(name: "Avenir-HeavyOblique", size: 10*s)!, color: .white, alignment: .right)

        betaALabel.text = "node A velocity (% of c)".localized
        betaALabel.pen = pen
        addSubview(betaALabel)
        betaASlider.options = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90]
        addSubview(betaASlider)
        betaASlider.onChange = { [unowned self] (percent: Int) in
            self.explorer.renderer.betaA = Double(percent)/100
            self.gammaALabel.attributedText = italicPen.format("γ = \(String(format: "%3.2f", TCGamma(Double(percent)/100)))")
            self.explorer.renderer.loadUniverse()
        }
        gammaALabel.attributedText = italicPen.format("γ = 1.00")
        addSubview(gammaALabel)

        thetaALabel.text = "node A direction (°)".localized
        thetaALabel.pen = pen
        addSubview(thetaALabel)
        thetaASlider.options = [0, 45, 90, 135, 180, 225, 270, 315]
        addSubview(thetaASlider)
        thetaASlider.onChange = { [unowned self] (degrees: Int) in
            self.explorer.renderer.thetaA = Double(degrees)
            self.explorer.renderer.loadUniverse()
        }

        betaBLabel.text = "node B velocity (% of c)".localized
        betaBLabel.pen = pen
        addSubview(betaBLabel)
        betaBSlider.options = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90]
        addSubview(betaBSlider)
        betaBSlider.onChange = { [unowned self] (percent: Int) in
            self.explorer.renderer.betaB = Double(percent)/100
            self.gammaBLabel.attributedText = italicPen.format("γ = \(String(format: "%3.2f", TCGamma(Double(percent)/100)))")
            self.explorer.renderer.loadUniverse()
        }
        gammaBLabel.attributedText = italicPen.format("γ = 1.00")
        addSubview(gammaBLabel)

        thetaBLabel.text = "node B direction (°)".localized
        thetaBLabel.pen = pen
        addSubview(thetaBLabel)
        thetaBSlider.options = [0, 45, 90, 135, 180, 225, 270, 315]
        addSubview(thetaBSlider)
        thetaBSlider.onChange = { [unowned self] (degrees: Int) in
            self.explorer.renderer.thetaB = Double(degrees)
            self.explorer.renderer.loadUniverse()
        }

        ratioLabel.text = "node extent r/L (%)".localized
        ratioLabel.pen = pen
        addSubview(ratioLabel)
        ratioSlider.options = [2, 4, 6, 8, 12, 16, 20]
        addSubview(ratioSlider)
        ratioSlider.onChange = { [unowned self] (percent: Int) in
            self.explorer.renderer.ratio = Double(percent)/100
            self.explorer.renderer.loadUniverse()
        }
    }

    // Reflect the renderer's current state into the sliders (called
    // after the case button or the case picker writes the state).
    func sync() {
        let renderer: HyleRenderer = explorer.renderer
        betaASlider.setTo(Int(round(renderer.betaA * 100)))
        thetaASlider.setTo(Int(round(renderer.thetaA)))
        betaBSlider.setTo(Int(round(renderer.betaB * 100)))
        thetaBSlider.setTo(Int(round(renderer.thetaB)))
        ratioSlider.setTo(Int(round(renderer.ratio * 100)))
        let italicPen: Pen = Pen(font: UIFont(name: "Avenir-HeavyOblique", size: 10*s)!, color: .white, alignment: .right)
        gammaALabel.attributedText = italicPen.format("γ = \(String(format: "%3.2f", TCGamma(renderer.betaA)))")
        gammaBLabel.attributedText = italicPen.format("γ = \(String(format: "%3.2f", TCGamma(renderer.betaB)))")
    }

// AEView ==========================================================================================
    override func layoutSubviews() {
        let sliderWidth: CGFloat = width-60*s

        caseSlider.frame = CGRect(x: 30*s, y: 12*s, width: sliderWidth, height: 28*s)

        var y: CGFloat = 52*s

        betaALabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 10*s
        betaASlider.top(dy: y, width: sliderWidth, height: 40*s)
        gammaALabel.topLeft(dx: 30*s, dy: y + 38*s, width: 240*s, height: 16*s)
        y += 58*s

        thetaALabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 10*s
        thetaASlider.top(dy: y, width: sliderWidth, height: 40*s)
        y += 46*s

        betaBLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 10*s
        betaBSlider.top(dy: y, width: sliderWidth, height: 40*s)
        gammaBLabel.topLeft(dx: 30*s, dy: y + 38*s, width: 240*s, height: 16*s)
        y += 58*s

        thetaBLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 10*s
        thetaBSlider.top(dy: y, width: sliderWidth, height: 40*s)
        y += 46*s

        ratioLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 10*s
        ratioSlider.top(dy: y, width: sliderWidth, height: 40*s)

        sync()
    }
}
