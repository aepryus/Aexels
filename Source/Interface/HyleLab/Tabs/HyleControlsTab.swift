//
//  HyleControlsTab.swift
//  Aexels
//
//  The bridge sim's controls: L/r graduated 2^2 … 2^11, and the
//  render button.  Velocities are not here — they are vectors on the
//  nodes, picked up and dragged on the stage.
//

import Acheron
import UIKit

class HyleControlsTab: TabsCellTab {
    unowned let explorer: HyleLabExplorer!

    let ratioSlider: Slider = Slider()
    let pingsPerVolleySlider: Slider = Slider()
    let timeStepsPerVolleySlider: Slider = Slider()
    let ratioLabel: UILabel = UILabel()
    let pingsPerVolleyLabel: UILabel = UILabel()
    let timeStepsPerVolleyLabel: UILabel = UILabel()
    let preRenderBoolButton: BoolButton = BoolButton(name: "pre-render")
    let renderButton: PulseButton = PulseButton(name: "render")

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

        preRenderBoolButton.on = explorer.renderer.showPreRender
        addSubview(preRenderBoolButton)
        preRenderBoolButton.onChange = { [unowned self] (on: Bool) in
            self.explorer.renderer.showPreRender = on
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
        preRenderBoolButton.on = explorer.renderer.showPreRender
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
        y += 40*s

        renderButton.top(dy: y, width: 70*s, height: 70*s)

        sync()
    }
}
