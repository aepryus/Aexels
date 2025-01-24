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
    let timeStepsPerVolleySlider: Slider = Slider()
    let pingsPerVolleySlider: Slider = Slider()
    
    let autoBoolButton: BoolButton = BoolButton(name: "auto volley")
    let hyleBoolButton: BoolButton = BoolButton(name: "hyle exchange")
    let aetherBoolButton: BoolButton = BoolButton(name: "aether frame")
    let wallsBoolButton: BoolButton = BoolButton(name: "camera walls")

    let pingsBoolButton: BoolButton = BoolButton(name: "pings")
    let pongsBoolButton: BoolButton = BoolButton(name: "pongs")
    let photonsBoolButton: BoolButton = BoolButton(name: "photons")
    

    let pongButton: PulseButton = PulseButton(name: "pong")

    init(renderer: ElectromagnetismRenderer) {
        self.renderer = renderer
        super.init(name: "Parameters".localized)
        
        let pen: Pen = Pen(font: .avenir(size: 13*s), color: .white, alignment: .right)
        
        speedOfLightLabel.text = "speed of light".localized
        speedOfLightLabel.pen = pen
        addSubview(speedOfLightLabel)
        
        speedOfAetherLabel.text = "aether velocity".localized
        speedOfAetherLabel.pen = pen
        addSubview(speedOfAetherLabel)
        
        pingsPerVolleyLabel.text = "pings per volley".localized
        pingsPerVolleyLabel.pen = pen
        addSubview(pingsPerVolleyLabel)

        volliesPerSecondLabel.text = "time steps per volley".localized
        volliesPerSecondLabel.pen = pen
        
        addSubview(volliesPerSecondLabel)
        
        addSubview(speedOfLightSlider)
        speedOfLightSlider.onChange = { (speedOfLight: Double) in
        }
        
        addSubview(speedOfAetherSlider)
        speedOfAetherSlider.onChange = { (speedOfAether: Double) in
        }
        
        pingsPerVolleySlider.options = [12, 24, 36, 48, 60, 120, 240, 360, 480, 600, 900, 1200]
        addSubview(pingsPerVolleySlider)
        pingsPerVolleySlider.onChange = { (pingsPerVolley: Int) in
            self.renderer.pingsPerVolley = Int32(pingsPerVolley)
        }

        timeStepsPerVolleySlider.options = [10, 12, 15, 20, 30, 60, 120, 180, 240, 480, 960]
        addSubview(timeStepsPerVolleySlider)
        timeStepsPerVolleySlider.onChange = { (timeStepsPerVolley: Int) in
            self.renderer.timeStepsPerVolley = timeStepsPerVolley
        }

        addSubview(autoBoolButton)
        addSubview(hyleBoolButton)
        addSubview(aetherBoolButton)
        addSubview(wallsBoolButton)

        addSubview(pingsBoolButton)
        addSubview(pongsBoolButton)
        addSubview(photonsBoolButton)

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

        speedOfLightSlider.setTo(60)
        speedOfAetherSlider.setTo(0.0)
        pingsPerVolleySlider.setTo(480)
        timeStepsPerVolleySlider.setTo(60)
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        
        var y: CGFloat = 20*s
        
        speedOfLightLabel.topRight(dx: -14*s, dy: y, width: 120*s, height: 18*s)
        y += 12*s
        speedOfLightSlider.top(dy: y, width: 300*s, height: 40*s)
        y += 50*s
        
        speedOfAetherLabel.topRight(dx: -14*s, dy: y, width: 120*s, height: 18*s)
        y += 12*s
        speedOfAetherSlider.top(dy: y, width: 300*s, height: 40*s)
        y += 50*s
        
        pingsPerVolleyLabel.topRight(dx: -14*s, dy: y, width: 120*s, height: 18*s)
        y += 12*s
        pingsPerVolleySlider.top(dy: y, width: 300*s, height: 40*s)
        y += 50*s

        volliesPerSecondLabel.topRight(dx: -14*s, dy: y, width: 120*s, height: 18*s)
        y += 12*s
        timeStepsPerVolleySlider.top(dy: y, width: 300*s, height: 40*s)
        y += 50*s

        y += 10*s
        autoBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        hyleBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        aetherBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        wallsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 40*s
        pingsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        pongsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        photonsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)

        pongButton.bottomRight(dx: -30*s, dy: -50*s, width: 60*s, height: 80*s)

        speedOfLightSlider.setTo(60)
        speedOfAetherSlider.setTo(0.0)
        pingsPerVolleySlider.setTo(480)
        timeStepsPerVolleySlider.setTo(60)
    }
}
