//
//  HyleControlsTab.swift
//  Aexels
//
//  The bridge sim's controls: L/r graduated 2^2 … 2^11, and the
//  render button.  Velocities are not here — they are vectors on the
//  nodes, picked up and dragged on the stage.
//

import Acheron
import OoviumEngine
import UIKit

// The render button: same chrome as PulseButton, but the glyph is what
// render produces — two node rings with the foam dotted between them.
class HyleRenderButton: AXButton {

// UIView ==========================================================================================
    override func draw(_ rect: CGRect) {
        let ss: CGFloat = rect.width/60/Screen.s

        let c = UIGraphicsGetCurrentContext()!

        let border = CGMutablePath(roundedRect: rect.inset(by: UIEdgeInsets(top: 3*s, left: 3*s*ss, bottom: 3*s*ss, right: 3*s*ss)), cornerWidth: 7*s*ss, cornerHeight: 7*s*ss, transform: nil)
        c.addPath(border)

        let stroke = isHighlighted ? Text.Color.lavender.uiColor : UIColor.white

        let center = CGPoint(x: width/2, y: height/2+10*s*ss)
        let nodeR: CGFloat = 6*ss
        let nodeX: CGFloat = 17*ss
        c.addEllipse(in: CGRect(x: center.x - nodeX - nodeR, y: center.y - nodeR, width: 2*nodeR, height: 2*nodeR))
        c.addEllipse(in: CGRect(x: center.x + nodeX - nodeR, y: center.y - nodeR, width: 2*nodeR, height: 2*nodeR))

        c.setStrokeColor(stroke.cgColor)
        c.setLineWidth(3*ss)
        c.strokePath()

        // the foam between the rings
        let dotR: CGFloat = 2*ss
        for x in [-7*ss, 0, 7*ss] {
            c.addEllipse(in: CGRect(x: center.x + x - dotR, y: center.y - dotR, width: 2*dotR, height: 2*dotR))
        }
        c.setFillColor(stroke.cgColor)
        c.fillPath()

        let pen = Pen(font: UIFont(name: "Avenir-Heavy", size: 15*s*ss)!, color: stroke, alignment: .center)
        "render".draw(in: CGRect(x: (width-60*s*ss)/2, y: 10*s*ss, width: 60*s*ss, height: 20*s*ss), pen: pen)
    }
}

class HyleControlsTab: TabsCellTab {
    unowned let explorer: HyleLabExplorer!

    let ratioSlider: Slider = Slider()
    let pingsPerVolleySlider: Slider = Slider()
    let timeStepsPerVolleySlider: Slider = Slider()
    let ratioLabel: UILabel = UILabel()
    let pingsPerVolleyLabel: UILabel = UILabel()
    let timeStepsPerVolleyLabel: UILabel = UILabel()
    let preRenderBoolButton: BoolButton = BoolButton(name: "pre-render")
    let showPingsBoolButton: BoolButton = BoolButton(name: "show pings")
    let bridgeABoolButton: BoolButton = BoolButton(name: "bridge → A")
    let bridgeBBoolButton: BoolButton = BoolButton(name: "bridge → B")
    let renderButton: HyleRenderButton = HyleRenderButton()

    init(explorer: HyleLabExplorer) {
        self.explorer = explorer
        super.init(name: "Controls".localized)

        let pen: Pen = Pen(font: .avenir(size: 13*s), color: .white, alignment: .right)

        ratioLabel.text = "L / r".localized
        ratioLabel.pen = pen
        addSubview(ratioLabel)
        ratioSlider.options = [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048]
        addSubview(ratioSlider)
        ratioSlider.onChange = { [unowned self] (value: Int) in
            self.explorer.renderer.lOverR = Double(value)
        }

        // Densities — as in SitD.
        pingsPerVolleyLabel.text = "pings per volley".localized
        pingsPerVolleyLabel.pen = pen
        addSubview(pingsPerVolleyLabel)
        pingsPerVolleySlider.options = [12, 24, 36, 48, 60, 120, 240, 360, 480, 600, 900, 1200]
        addSubview(pingsPerVolleySlider)
        pingsPerVolleySlider.onChange = { [unowned self] (count: Int) in
            self.explorer.renderer.pingsPerVolley = count
        }

        timeStepsPerVolleyLabel.text = "time steps per volley".localized
        timeStepsPerVolleyLabel.pen = pen
        addSubview(timeStepsPerVolleyLabel)
        timeStepsPerVolleySlider.options = [1, 2, 3, 5, 6, 10, 12, 15, 20, 30, 60, 120, 180, 240, 480, 600]
        addSubview(timeStepsPerVolleySlider)
        timeStepsPerVolleySlider.onChange = { [unowned self] (steps: Int) in
            self.explorer.renderer.ticsPerVolley = steps
        }

        // pre-render: watch the generation playback when rendering.
        preRenderBoolButton.on = explorer.renderer.showProcess
        addSubview(preRenderBoolButton)
        preRenderBoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.showProcess = on
        }

        showPingsBoolButton.on = explorer.renderer.showPings
        addSubview(showPingsBoolButton)
        showPingsBoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.showPings = on
            self.explorer.redraw()
        }

        bridgeABoolButton.on = explorer.renderer.showBridgeToA
        addSubview(bridgeABoolButton)
        bridgeABoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.showBridgeToA = on
            self.explorer.redraw()
        }

        bridgeBBoolButton.on = explorer.renderer.showBridgeToB
        addSubview(bridgeBBoolButton)
        bridgeBBoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.showBridgeToB = on
            self.explorer.redraw()
        }

        addSubview(renderButton)
        renderButton.addAction { [unowned self] in
            self.explorer.render()
        }
    }

    func sync() {
        ratioSlider.setTo(Int(round(explorer.renderer.lOverR)))
        pingsPerVolleySlider.setTo(explorer.renderer.pingsPerVolley)
        timeStepsPerVolleySlider.setTo(explorer.renderer.ticsPerVolley)
        preRenderBoolButton.on = explorer.renderer.showProcess
        showPingsBoolButton.on = explorer.renderer.showPings
        bridgeABoolButton.on = explorer.renderer.showBridgeToA
        bridgeBBoolButton.on = explorer.renderer.showBridgeToB
    }

// AEView ==========================================================================================
    override func layoutSubviews() {
        let sliderWidth: CGFloat = width-60*s

        var y: CGFloat = 24*s

        ratioLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 10*s
        ratioSlider.top(dy: y, width: sliderWidth, height: 40*s)
        y += 56*s

        pingsPerVolleyLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 10*s
        pingsPerVolleySlider.top(dy: y, width: sliderWidth, height: 40*s)
        y += 56*s

        timeStepsPerVolleyLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 10*s
        timeStepsPerVolleySlider.top(dy: y, width: sliderWidth, height: 40*s)
        y += 60*s

        preRenderBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        showPingsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        bridgeABoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        bridgeBBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 40*s

        renderButton.top(dy: y, width: 70*s, height: 70*s)

        sync()
    }
}
