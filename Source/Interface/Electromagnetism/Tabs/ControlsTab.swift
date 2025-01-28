//
//  ControlsTab.swift
//  Aexels
//
//  Created by Joe Charlier on 1/23/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ControlsTab: TabsCellTab {
    unowned let explorer: ElectromagnetismExplorer!
    
    let speedOfLightLabel: UILabel = UILabel()
    let speedOfAetherLabel: UILabel = UILabel()
    let volliesPerSecondLabel: UILabel = UILabel()
    let pingsPerVolleyLabel: UILabel = UILabel()

    let speedOfLightSlider: Slider = Slider()
    let aetherVelocitySlider: Slider = Slider()
    let timeStepsPerVolleySlider: Slider = Slider()
    let pingsPerVolleySlider: Slider = Slider()
    
    let autoVolleyBoolButton: BoolButton = BoolButton(name: "auto volley")
    let hyleExchangeBoolButton: BoolButton = BoolButton(name: "hyle exchange")
    let aetherFrameBoolButton: BoolButton = BoolButton(name: "aether frame")
    let cameraWallsBoolButton: BoolButton = BoolButton(name: "camera walls")

    let pingsBoolButton: BoolButton = BoolButton(name: "pings")
    let pongsBoolButton: BoolButton = BoolButton(name: "pongs")
    let photonsBoolButton: BoolButton = BoolButton(name: "photons")
    

    let pongButton: PulseButton = PulseButton(name: "pong")
    
    var experiment: Experiment? {
        didSet {
            guard let experiment, let electromagnetism = experiment.electromagnetism else { return }
            speedOfLightSlider.setTo(electromagnetism.speedOfLight)
            aetherVelocitySlider.setTo(electromagnetism.aetherVelocity)
            timeStepsPerVolleySlider.setTo(electromagnetism.timeStepsPerVolley)
            pingsPerVolleySlider.setTo(electromagnetism.pingsPerVolley)
            autoVolleyBoolButton.on = electromagnetism.autoVolleyOn
            hyleExchangeBoolButton.on = electromagnetism.hyleExchangeOn
            aetherFrameBoolButton.on = electromagnetism.aetherFrameOn
            cameraWallsBoolButton.on = electromagnetism.cameraWallsOn
            pingsBoolButton.on = electromagnetism.pingRenderMode != .minimal
            pongsBoolButton.on = electromagnetism.pongRenderMode != .minimal
            photonsBoolButton.on = electromagnetism.photonRenderMode != .minimal
        }
    }

    init(explorer: ElectromagnetismExplorer) {
        self.explorer = explorer
        super.init(name: "Controls".localized)
        
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
        
        speedOfLightSlider.options = [1, 2, 3, 4, 5, 6, 7, 8]
        addSubview(speedOfLightSlider)
        speedOfLightSlider.onChange = { (speedOfLight: Int) in
            self.explorer.renderer.speedOfLight = speedOfLight
        }
        
        aetherVelocitySlider.options = [-99, -90, -70, -50, -20, -10, 0, 10, 20, 50, 70, 90, 99]
        addSubview(aetherVelocitySlider)
        aetherVelocitySlider.onChange = { (speedOfAether: Int) in
            self.explorer.renderer.velocity = Double(speedOfAether)/100
        }
        
        pingsPerVolleySlider.options = [12, 24, 36, 48, 60, 120, 240, 360, 480, 600, 900, 1200]
        addSubview(pingsPerVolleySlider)
        pingsPerVolleySlider.onChange = { (pingsPerVolley: Int) in
            self.explorer.renderer.pingsPerVolley = Int32(pingsPerVolley)
        }

        timeStepsPerVolleySlider.options = [1, 2, 3, 5, 6, 10, 12, 15, 20, 30, 60, 120, 180, 240, 480, 600]
        addSubview(timeStepsPerVolleySlider)
        timeStepsPerVolleySlider.onChange = { (timeStepsPerVolley: Int) in
            self.explorer.renderer.timeStepsPerVolley = timeStepsPerVolley
        }

        autoVolleyBoolButton.on = true
        addSubview(autoVolleyBoolButton)
        autoVolleyBoolButton.onChange =  { (on: Bool) in self.explorer.renderer.autoOn = on }
        
        hyleExchangeBoolButton.on = false
        addSubview(hyleExchangeBoolButton)
        hyleExchangeBoolButton.onChange =  { (on: Bool) in self.explorer.renderer.hyleExchangeOn = on }

        aetherFrameBoolButton.on = false
        addSubview(aetherFrameBoolButton)
        aetherFrameBoolButton.onChange =  { (on: Bool) in self.explorer.swapAetherFrame() }
        
        cameraWallsBoolButton.on = true
        addSubview(cameraWallsBoolButton)
        cameraWallsBoolButton.onChange =  { (on: Bool) in self.explorer.renderer.wallsOn = on }

        pingsBoolButton.on = false
        addSubview(pingsBoolButton)
        pingsBoolButton.onChange =  { (on: Bool) in self.explorer.renderer.pingVectorsOn = on }

        pongsBoolButton.on = true
        addSubview(pongsBoolButton)
        pongsBoolButton.onChange =  { (on: Bool) in self.explorer.renderer.pongVectorsOn = on }

        photonsBoolButton.on = true
        addSubview(photonsBoolButton)
        photonsBoolButton.onChange =  { (on: Bool) in self.explorer.renderer.photonVectorsOn = on }

        pongButton.addAction {
            self.explorer.renderer.onPong()
        }
    }
    
    func applyControls() {
        explorer.renderer.speedOfLight = speedOfLightSlider.option
        explorer.renderer.velocity = Double(aetherVelocitySlider.option)/100
        explorer.renderer.pingsPerVolley = Int32(pingsPerVolleySlider.option)
        explorer.renderer.timeStepsPerVolley = timeStepsPerVolleySlider.option
        explorer.renderer.autoOn = autoVolleyBoolButton.on
        explorer.renderer.wallsOn = cameraWallsBoolButton.on
        explorer.renderer.hyleExchangeOn = hyleExchangeBoolButton.on
        explorer.renderer.pingVectorsOn = pingsBoolButton.on
        explorer.renderer.pongVectorsOn = pongsBoolButton.on
        explorer.renderer.photonVectorsOn = photonsBoolButton.on
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        
        var y: CGFloat = 20*s
        
        speedOfLightLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 12*s
        speedOfLightSlider.top(dy: y, width: 300*s, height: 40*s)
        y += 50*s
        
        speedOfAetherLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 12*s
        aetherVelocitySlider.top(dy: y, width: 300*s, height: 40*s)
        y += 50*s
        
        pingsPerVolleyLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 12*s
        pingsPerVolleySlider.top(dy: y, width: 300*s, height: 40*s)
        y += 50*s

        volliesPerSecondLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        y += 12*s
        timeStepsPerVolleySlider.top(dy: y, width: 300*s, height: 40*s)
        y += 50*s

        y += 10*s
        autoVolleyBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        cameraWallsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        hyleExchangeBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        aetherFrameBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 40*s
        
        pingsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 24*s
        pongsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 24*s
        photonsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)

        pongButton.bottomRight(dx: -30*s, dy: -50*s, width: 60*s, height: 80*s)
    }
}
