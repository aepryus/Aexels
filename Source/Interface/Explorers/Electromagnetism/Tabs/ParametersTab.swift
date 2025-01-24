//
//  ParametersTab.swift
//  Aexels
//
//  Created by Joe Charlier on 1/23/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ParametersTab: TabsCellTab {
    unowned let renderer: ElectromagnetismRenderer!
    
    let speedOfLightLabel: UILabel = UILabel()
    let speedOfAetherLabel: UILabel = UILabel()
    let volliesPerSecondLabel: UILabel = UILabel()
    let pingsPerVolleyLabel: UILabel = UILabel()

    let speedOfLightSlider: CSlider = CSlider()
    let speedOfAetherSlider: VSlider = VSlider()
    let volliesPerSecondSlider: Slider = Slider()
    let pingsPerVolleySlider: Slider = Slider()
    
    let autoSwap: BoolButtonOld = BoolButtonOld(text: "auto volley")
    let hyleOnSwap: BoolButtonOld = BoolButtonOld(text: "hyle exchange")

    let pongButton: PulseButton = PulseButton(name: "pong")

    init(renderer: ElectromagnetismRenderer) {
        self.renderer = renderer
        super.init(name: "Parameters".localized)
        
        let pen: Pen = Pen(font: .avenir(size: 13*s), color: .white)
        
        speedOfLightLabel.text = "speed of light".localized
        speedOfLightLabel.pen = pen
        addSubview(speedOfLightLabel)
        
        speedOfAetherLabel.text = "aether velocity".localized
        speedOfAetherLabel.pen = pen
        addSubview(speedOfAetherLabel)
        
        pingsPerVolleyLabel.text = "pings per volley".localized
        pingsPerVolleyLabel.pen = pen
        addSubview(pingsPerVolleyLabel)

        volliesPerSecondLabel.text = "volley frequency".localized
        volliesPerSecondLabel.pen = pen
        
        addSubview(volliesPerSecondLabel)
        
        
        addSubview(speedOfLightSlider)
        addSubview(speedOfAetherSlider)
        
        pingsPerVolleySlider.options = [12, 24, 36, 48, 60, 120, 240, 360, 480, 600, 900, 1200]
        addSubview(pingsPerVolleySlider)

        volliesPerSecondSlider.options = [10, 12, 15, 20, 30, 60, 120, 180, 240, 480, 960, 1920]
        addSubview(volliesPerSecondSlider)

        addSubview(autoSwap)
        addSubview(hyleOnSwap)
        
        addSubview(pongButton)
        
        //        controlsView.addSubview(cSlider)
//                cSlider.onChange = { (speedOfLight: Double) in
        //            self.engine.speedOfLight = speedOfLight
//                }
                        
//                vSlider.velocity = 0
        //        controlsView.addSubview(vSlider)
//                vSlider.onChange = { (velocity: Double) in
        //            self.engine.velocity = velocity
//                }
                
                
        //        controlsView.addSubview(autoSwap)
//                autoSwap.addAction(for: .touchUpInside) { [unowned self] in
//                    self.autoSwap.rotateView()
        //            self.engine.autoOn = !self.engine.autoOn
//                }
        pongButton.addAction {
            self.renderer.onPong()
        }

    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        
        var y: CGFloat = 20*s
        
        speedOfLightLabel.topLeft(dx: 14*s, dy: y, width: 120*s, height: 18*s)
        y += 12*s
        speedOfLightSlider.top(dy: y, width: 300*s, height: 40*s)
        y += 50*s
        
        speedOfAetherLabel.topLeft(dx: 14*s, dy: y, width: 120*s, height: 18*s)
        y += 12*s
        speedOfAetherSlider.top(dy: y, width: 300*s, height: 40*s)
        y += 50*s
        
        pingsPerVolleyLabel.topLeft(dx: 14*s, dy: y, width: 120*s, height: 18*s)
        y += 12*s
        pingsPerVolleySlider.top(dy: y, width: 300*s, height: 40*s)
        y += 50*s

        autoSwap.topLeft(dx: 10*s, dy: y)
        y += 30*s
        volliesPerSecondLabel.topLeft(dx: 14*s, dy: y, width: 120*s, height: 18*s)
        y += 12*s
        volliesPerSecondSlider.top(dy: y, width: 300*s, height: 40*s)
        y += 50*s

        hyleOnSwap.topLeft(dx: 10*s, dy: y)

        pongButton.bottomRight(dx: -30*s, dy: -100*s, width: 60*s, height: 80*s)

        speedOfLightSlider.setTo(60)
        speedOfAetherSlider.setTo(0.0)
    }
}
