//
//  DilationExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class DilationExplorer: Explorer {
    let engine: DilationEngine
    lazy var dilationView: DilationView = DilationView(engine: engine)
    let dilationLimbo: Limbo = Limbo()
    lazy var fixedDilationView: DilationView = DilationView(engine: engine, chaseCameraOn: true)
    let fixedDilationLimbo: Limbo = Limbo()
    let cSlider: CSlider = CSlider()
    let vSlider: VSlider = VSlider()
    let playButton: PlayButton = PlayButton()
    let resetButton: ResetButton = ResetButton()
    let autoSwap: BoolButton = BoolButton(text: "auto")
    let tailsSwap: BoolButton = BoolButton(text: "tails")
    let cameraSwap: BoolButton = BoolButton(text: "camera")
    let pulseButton: PulseButton = PulseButton()
    let controlsLimbo: Limbo = Limbo()
    let messageLimbo: MessageLimbo = MessageLimbo()
    let closeLimbo = LimboButton(title: "Close")
    
    let lightSpeedLabel: UILabel = UILabel()
    let cLabel: UILabel = UILabel()
    let velocityLabel: UILabel = UILabel()
    let lambdaLabel: UILabel = UILabel()
    
    var cameraOn: Bool = true
    
	init(parent: UIView) {
        let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
        let s: CGFloat = height / 748
        let mainLen: CGFloat = height - 110*s
        let fixLen: CGFloat = Screen.width - mainLen - 10*s

        engine = DilationEngine(size: CGSize(width: max(mainLen, fixLen*2+123), height: mainLen))
        
        super.init(parent: parent, name: "Dilation", key: "Dilation", canExplore: true)
        
        engine.onVelocityChange = { (v: TCVelocity) in
            let italicPen: Pen = Pen(font: UIFont(name: "Verdana-Italic", size: 10*s)!, color: .white, alignment: .center)
            let sb = italicPen.format("λ = \(String(format: "%3.2f", TCLambda(self.engine.velocity)))")
            self.lambdaLabel.attributedText = sb
        }
    }
    
    func swapCamera() {
        self.cameraOn = !cameraOn
        
        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let height = Screen.height - topY - botY
        let s = height / 748
        
        let p: CGFloat = 5*s

        if self.cameraOn {
            messageLimbo.frame = CGRect(x: dilationLimbo.right, y: fixedDilationLimbo.bottom, width: Screen.width-2*p-dilationLimbo.width, height: Screen.height-botY-fixedDilationLimbo.bottom)
            brightenLimbos([fixedDilationLimbo])
            limbos = [
                dilationLimbo,
                fixedDilationLimbo,
                controlsLimbo,
                messageLimbo,
                closeLimbo
            ]
        } else {
            messageLimbo.frame = CGRect(x: dilationLimbo.right, y: Screen.safeTop + (Screen.mac ? 5*s : 0), width: Screen.width-2*p-dilationLimbo.width, height: Screen.height-botY-topY)
            dimLimbos([fixedDilationLimbo])
            limbos = [
                dilationLimbo,
                controlsLimbo,
                messageLimbo,
                closeLimbo
            ]
        }
    }
    
// Events ==========================================================================================
    var n: Int = 1
    override func onOpened() { engine.play() }
    override func onClose() { engine.stop() }

// Explorer ========================================================================================
    override func createLimbos() {
        // DilationLimbo
        dilationLimbo.content = dilationView
        engine.trailsOn = true
        fixedDilationLimbo.content = fixedDilationView
        
        controlsLimbo.addSubview(cSlider)
        cSlider.onChange = { (speedOfLight: Double) in
            self.engine.speedOfLight = speedOfLight
        }

        controlsLimbo.addSubview(vSlider)
        vSlider.onChange = { (velocity: Double) in
            self.engine.velocity = velocity
            self.engine.camera.pointee.v.s = abs(velocity)
            self.engine.camera.pointee.v.q = velocity > 0 ? .pi/2 : .pi*3/2
        }

        playButton.playing = true
        controlsLimbo.addSubview(playButton)
        playButton.onPlay = { [unowned self] in
            self.engine.play()
        }
        playButton.onStop = { [unowned self] in
            self.engine.stop()
        }

        controlsLimbo.addSubview(resetButton)
        resetButton.addAction(for: .touchUpInside) { [unowned self] in
            self.playButton.stop()
            self.engine.reset()
            self.engine.tic()
        }
        
        controlsLimbo.addSubview(tailsSwap)
        tailsSwap.addAction(for: .touchUpInside) { [unowned self] in
            self.tailsSwap.rotateView()
            self.engine.trailsOn = !self.engine.trailsOn
        }

        controlsLimbo.addSubview(autoSwap)
        autoSwap.addAction(for: .touchUpInside) { [unowned self] in
            self.autoSwap.rotateView()
            self.engine.autoOn = !self.engine.autoOn
        }

        controlsLimbo.addSubview(cameraSwap)
        cameraSwap.addAction(for: .touchUpInside) { [unowned self] in
            self.cameraSwap.rotateView()
            self.swapCamera()
        }
        
        controlsLimbo.addSubview(pulseButton)
        pulseButton.addAction {
            self.engine.pulse()
        }

        // MessageLimbo
        messageLimbo.key = "DilationLab"

        // CloseLimbo
        closeLimbo.alpha = 0
        closeLimbo.addAction(for: .touchUpInside) { [unowned self] in
            self.closeExplorer()
            Aexels.nexus.brightenNexus()
        }
        
        // Labels
        let pen: Pen = Pen(font: .verdana(size: 15*s), color: .white, alignment: .center)
        let italicPen: Pen = Pen(font: UIFont(name: "Verdana-Italic", size: 10*s)!, color: .white, alignment: .center)
        
        var sb = pen.format("speed of light (c)")
        lightSpeedLabel.attributedText = sb
        controlsLimbo.addSubview(lightSpeedLabel)
        
        sb = italicPen.format("points per second")
        cLabel.attributedText = sb
        controlsLimbo.addSubview(cLabel)
        
        sb = pen.format("velocity (% of c)")
        velocityLabel.attributedText = sb
        controlsLimbo.addSubview(velocityLabel)
        
        sb = italicPen.format("λ = \(String(format: "%3.2f", TCLambda(engine.velocity)))")
        lambdaLabel.attributedText = sb
        controlsLimbo.addSubview(lambdaLabel)

        limbos = [
            dilationLimbo,
            fixedDilationLimbo,
            controlsLimbo,
            messageLimbo,
            closeLimbo
        ]
    }
    override func layout375x667() {
        closeLimbo.bottomRight(dx: -5*s, dy: -Screen.safeBottom, width: 139*s, height: 60*s)
    }
    override func layout1024x768() {
        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let height = Screen.height - topY - botY
        let s = height / 748
        
        let p: CGFloat = 5*s
        let uw: CGFloat = height - 110*s

        dilationLimbo.topLeft(dx: p, dy: topY, width: uw, height: uw)
        let vw: CGFloat = Screen.width - dilationLimbo.right - p
        fixedDilationLimbo.topLeft(dx: dilationLimbo.right, dy: topY, width: vw, height: vw)

        closeLimbo.bottomRight(dx: -p, dy: -botY, width: 176*s, height: 110*s)

        controlsLimbo.bottomLeft(dx: p, dy: -botY, width: dilationLimbo.width, height: 110*s)
        closeLimbo.bottomRight(dx: -p, dy: -botY, width: 176*s, height: 110*s)
        
        let bw: CGFloat = 40*s
        playButton.left(dx: 15*s, size: CGSize(width: bw, height: 30*s))
        resetButton.left(dx: 15*s+bw, size: CGSize(width: bw, height: 30*s))
        cSlider.topLeft(dx: resetButton.right+15*s, dy: 58*s, width: 140*s, height: 40*s)
        vSlider.topLeft(dx: cSlider.right+20*s, dy: 54*s, width: 140*s, height: 40*s)
        autoSwap.left(dx: vSlider.right+30*s, dy: -30*s)
        tailsSwap.left(dx: autoSwap.left)
        cameraSwap.left(dx: autoSwap.left, dy: 30*s)
        pulseButton.right(dx: -15*s, width: 60*s, height: 80*s)

        lightSpeedLabel.topLeft(dx: cSlider.left, dy: 20*s, width: cSlider.width, height: 20*s)
        cLabel.topLeft(dx: cSlider.left, dy: 36*s, width: cSlider.width, height: 20*s)
        velocityLabel.topLeft(dx: vSlider.left, dy: 20*s, width: vSlider.width, height: 20*s)
        lambdaLabel.topLeft(dx: vSlider.left, dy: 36*s, width: vSlider.width, height: 20*s)

        cSlider.setTo(60)
        vSlider.setTo(0.5)

        messageLimbo.frame = CGRect(x: dilationLimbo.right, y: fixedDilationLimbo.bottom, width: Screen.width-2*p-dilationLimbo.width, height: Screen.height-botY-fixedDilationLimbo.bottom)
        messageLimbo.cutouts[Position.bottomRight] = Cutout(width: 176*s, height: 110*s)
        messageLimbo.renderPaths()
    }
}
