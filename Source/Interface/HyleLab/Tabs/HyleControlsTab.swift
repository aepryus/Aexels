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
    let ratioLabel: UILabel = UILabel()
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

        addSubview(renderButton)
        renderButton.addAction { [unowned self] in
            self.explorer.render()
        }
    }

    func sync() {
        ratioSlider.setTo(Int(round(explorer.renderer.lOverR)))
    }

// AEView ==========================================================================================
    override func layoutSubviews() {
        let sliderWidth: CGFloat = width-60*s

        var y: CGFloat = 24*s

        ratioLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 10*s
        ratioSlider.top(dy: y, width: sliderWidth, height: 40*s)
        y += 66*s

        renderButton.top(dy: y, width: 70*s, height: 70*s)

        sync()
    }
}
