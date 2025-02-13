//
//  DilationTab.swift
//  Aexels
//
//  Created by Joe Charlier on 2/12/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class DilationTab: TabsCellTab {
    unowned let explorer: DilationExplorer!

    let cSlider: CSlider = CSlider()
    let vSlider: VSlider = VSlider()
    
    let autoSwap: BoolButton = BoolButton(name: "auto")
    let tailsSwap: BoolButton = BoolButton(name: "tails")
    let cameraSwap: BoolButton = BoolButton(name: "fixed")
    
    let lightSpeedLabel: UILabel = UILabel()
    let cLabel: UILabel = UILabel()
    let velocityLabel: UILabel = UILabel()
    let lambdaLabel: UILabel = UILabel()
    
    init(explorer: DilationExplorer) {
        self.explorer = explorer
        
        super.init(name: "Controls".localized)
        
        addSubview(cSlider)
        cSlider.onChange = { (speedOfLight: Double) in
            self.explorer.renderer.speedOfLight = Int(speedOfLight)
        }

        addSubview(vSlider)
        vSlider.onChange = { (velocity: Double) in
            self.explorer.renderer.velocity = velocity
            
            let s: CGFloat = self.s
            let italicPen: Pen = Pen(font: UIFont(name: "Verdana-Italic", size: 10*s)!, color: .white, alignment: .right)
            self.lambdaLabel.attributedText = italicPen.format("γ = \(String(format: "%3.2f", TCGamma(explorer.renderer.velocity)))")
        }

        tailsSwap.on = true
        addSubview(tailsSwap)
        tailsSwap.onChange = { (tailsOn: Bool) in
            self.explorer.renderer.tailsOn = tailsOn
        }

        autoSwap.on = true
        addSubview(autoSwap)
        autoSwap.onChange = { (autoOn: Bool) in
            self.explorer.renderer.autoOn = autoOn
        }

        cameraSwap.on = false
        addSubview(cameraSwap)
        cameraSwap.onChange = { (cameraOn: Bool) in
            self.explorer.swapAetherFrame()
        }
        
        // Labels
        let pen: Pen = Pen(font: .verdana(size: 15*s), color: .white, alignment: .right)
        let italicPen: Pen = Pen(font: UIFont(name: "Verdana-Italic", size: 10*s)!, color: .white, alignment: .right)
        
        var sb = pen.format("speed of light (c)")
        lightSpeedLabel.attributedText = sb
        addSubview(lightSpeedLabel)
        
        sb = italicPen.format("points per second")
        cLabel.attributedText = sb
        addSubview(cLabel)
        
        sb = pen.format("aether velocity (% of c)")
        velocityLabel.attributedText = sb
        addSubview(velocityLabel)
        
        sb = italicPen.format("γ = \(String(format: "%3.2f", TCGamma(explorer.renderer.velocity)))")
        lambdaLabel.attributedText = sb
        addSubview(lambdaLabel)
    }
    
// AEView ==========================================================================================
    override func layoutSubviews() {
        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let height = Screen.height - topY - botY
        let s = height / 748

        var y: CGFloat = 30*s
        
        lightSpeedLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        cLabel.topLeft(dx: 14*2, dy: lightSpeedLabel.bottom-3*s, width: cSlider.width, height: 20*s)
        y += 24*s
        cSlider.top(dy: y, width: 300*s, height: 40*s)
        y += 80*s
        
        velocityLabel.topRight(dx: -14*s, dy: y, width: 240*s, height: 18*s)
        lambdaLabel.topLeft(dx: vSlider.left, dy: velocityLabel.bottom-3*s, width: vSlider.width, height: 20*s)
        y += 24*s
        vSlider.top(dy: y, width: 300*s, height: 40*s)
        y += 100*s

        autoSwap.topLeft(dx: 30*s, dy: y, width: 100*s, height: 24*s)
        y += 30*s
        tailsSwap.topLeft(dx: 30*s, dy: y, width: 100*s, height: 24*s)
        y += 30*s
        cameraSwap.topLeft(dx: 30*s, dy: y, width: 100*s, height: 24*s)

        cSlider.setTo(60)
        vSlider.setTo(0.5)
    }
}
