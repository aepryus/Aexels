//
//  BlackHolesControlsTab.swift
//  Aexels
//
//  Toggle visualization layers + viscosity slider.
//

import Acheron
import UIKit

class BlackHolesControlsTab: TabsCellTab {
    unowned let explorer: BlackHolesExplorer!

    let wellsBoolButton: BoolButton = BoolButton(name: "wells")
    let accelerantBoolButton: BoolButton = BoolButton(name: "accelerant")
    let aetherBoolButton: BoolButton = BoolButton(name: "aether")
    let matterBoolButton: BoolButton = BoolButton(name: "matter")

    let viscosityLabel: UILabel = UILabel()
    let viscositySlider: Slider = Slider()

    init(explorer: BlackHolesExplorer) {
        self.explorer = explorer
        super.init(name: "Controls".localized)

        wellsBoolButton.on = true
        addSubview(wellsBoolButton)
        wellsBoolButton.onChange = { (on: Bool) in self.explorer.renderer.wellsOn = on }

        accelerantBoolButton.on = false
        addSubview(accelerantBoolButton)
        accelerantBoolButton.onChange = { (on: Bool) in self.explorer.renderer.accelerantOn = on }

        aetherBoolButton.on = true
        addSubview(aetherBoolButton)
        aetherBoolButton.onChange = { (on: Bool) in self.explorer.renderer.aetherOn = on }

        matterBoolButton.on = false
        addSubview(matterBoolButton)
        matterBoolButton.onChange = { (on: Bool) in self.explorer.renderer.matterOn = on }

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
        accelerantBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        aetherBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        matterBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 40*s

        let sliderWidth: CGFloat = width - 60*s
        viscosityLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 12*s
        viscositySlider.top(dy: y, width: sliderWidth, height: 40*s)
    }
}
