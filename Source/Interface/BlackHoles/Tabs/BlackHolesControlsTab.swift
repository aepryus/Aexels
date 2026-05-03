//
//  BlackHolesControlsTab.swift
//  Aexels
//
//  Toggle the two visualization layers and tune the Phase 1.4
//  viscosity drag.
//

import Acheron
import UIKit

class BlackHolesControlsTab: TabsCellTab {
    unowned let explorer: BlackHolesExplorer!

    let wellsBoolButton: BoolButton = BoolButton(name: "wells")
    let flowBoolButton: BoolButton = BoolButton(name: "flow")

    let viscosityLabel: UILabel = UILabel()
    let viscositySlider: Slider = Slider()

    init(explorer: BlackHolesExplorer) {
        self.explorer = explorer
        super.init(name: "Controls".localized)

        wellsBoolButton.on = true
        addSubview(wellsBoolButton)
        wellsBoolButton.onChange = { (on: Bool) in self.explorer.renderer.wellsOn = on }

        flowBoolButton.on = true
        addSubview(flowBoolButton)
        flowBoolButton.onChange = { (on: Bool) in self.explorer.renderer.flowOn = on }

        // Slider values are γ × 1000 so the widget can show ints. The
        // physical drag coefficient applied to each BH is dragGamma =
        // option / 1000. 0 = off, 150 = aggressive merge in seconds.
        let pen: Pen = Pen(font: .avenir(size: 13*s), color: .white, alignment: .right)
        viscosityLabel.text = "viscosity ×1000"
        viscosityLabel.pen = pen
        addSubview(viscosityLabel)

        viscositySlider.options = [0, 5, 10, 15, 25, 40, 60, 100, 150]
        addSubview(viscositySlider)
        viscositySlider.onChange = { (value: Int) in
            self.explorer.renderer.dragGamma = Float(value) / 1000
        }
        viscositySlider.setTo(0)
    }

// UIView ==========================================================================================
    override func layoutSubviews() {
        var y: CGFloat = 40*s

        wellsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        flowBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 40*s

        let sliderWidth: CGFloat = width - 60*s
        viscosityLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 12*s
        viscositySlider.top(dy: y, width: sliderWidth, height: 40*s)
    }
}
