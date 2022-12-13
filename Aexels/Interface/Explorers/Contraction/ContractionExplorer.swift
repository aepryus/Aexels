//
//  ContractionExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class ContractionExplorer: Explorer {
    let engine: DilationEngine
    lazy var dilationView: DilationView = DilationView(engine: engine)
    let dilationLimbo: Limbo = Limbo()
    let cSlider: CSlider = CSlider()
    let vSlider: VSlider = VSlider()
    let playButton: PlayButton = PlayButton()
    let resetButton: ResetButton = ResetButton()
    let autoSwap: BoolButton = BoolButton(text: "auto")
    let tailsSwap: BoolButton = BoolButton(text: "tails")
    let contractSwap: BoolButton = BoolButton(text: "contract")
    let pulseButton: PulseButton = PulseButton()
    let controlsLimbo: Limbo = Limbo()
    let messageLimbo: MessageLimbo = MessageLimbo()
    let closeLimbo = LimboButton(title: "Close")
    
    let lightSpeedLabel: UILabel = UILabel()
    let cLabel: UILabel = UILabel()
    let velocityLabel: UILabel = UILabel()
    let lambdaLabel: UILabel = UILabel()
    
    let swapper: Limbo = Limbo()
    let swapButton: SwapButton = SwapButton()
    var first: [Limbo] = []
    var second: [Limbo] = []
    var isFirst: Bool = false

    init(parent: UIView) {
        let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
        let s: CGFloat = height / 748
        let mainLen: CGFloat = height - 110*s
        let fixLen: CGFloat = Screen.width - mainLen - 10*s

        engine = DilationEngine(size: CGSize(width: max(mainLen, fixLen*2+123), height: mainLen), horizontalOn: true)

        super.init(parent: parent, name: "Contraction", key: "Contraction", canExplore: true)

        engine.onVelocityChange = { (v: TCVelocity) in
            let italicPen: Pen = Pen(font: UIFont(name: "Verdana-Italic", size: 10*s)!, color: .white, alignment: .center)
            let sb = italicPen.format("λ = \(String(format: "%3.2f", TCLambda(self.engine.velocity)))")
            self.lambdaLabel.attributedText = sb
        }
    }
    
// Events ==========================================================================================
    override func onOpen() {
        Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
            self.engine.tic()
            complete()
        }
        Aexels.sync.link.preferredFramesPerSecond = 60
        
    }
    override func onOpened() { engine.play() }
    override func onClose() { engine.stop() }

// Explorer ========================================================================================
    override func createLimbos() {
        // DilationLimbo
        dilationLimbo.content = dilationView
        
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
            self.engine.tailsOn = !self.engine.tailsOn
        }

        controlsLimbo.addSubview(autoSwap)
        autoSwap.addAction(for: .touchUpInside) { [unowned self] in
            self.autoSwap.rotateView()
            self.engine.autoOn = !self.engine.autoOn
        }

        controlsLimbo.addSubview(contractSwap)
        contractSwap.addAction(for: .touchUpInside) { [unowned self] in
            self.contractSwap.rotateView()
            self.engine.swapContract()
        }
        
        controlsLimbo.addSubview(pulseButton)
        pulseButton.addAction {
            self.engine.pulse()
        }
        
        // MessageLimbo
        messageLimbo.key = "ContractionLab"

        // Swapper =========================
        if Screen.iPhone {
            swapButton.addAction(for: .touchUpInside) { [unowned self] in
                self.swapButton.rotateView()
                if self.isFirst {
                    self.isFirst = false
                    self.dimLimbos(self.first)
                    self.brightenLimbos(self.second)
                    self.limbos = [self.swapper] + self.second + [self.closeLimbo]
                } else {
                    self.isFirst = true
                    self.dimLimbos(self.second)
                    self.brightenLimbos(self.first)
                    self.limbos = [self.swapper] + self.first + [self.closeLimbo]
                }
                self.swapper.removeFromSuperview()
                self.parent.addSubview(self.swapper)
                self.closeLimbo.removeFromSuperview()
                self.parent.addSubview(self.closeLimbo)
            }
            swapper.content = swapButton
        }

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
        
        if Screen.iPhone {
            first = [messageLimbo]
            second = [dilationLimbo, controlsLimbo]
            brightenLimbos(second)
            limbos = [swapper] + second + [closeLimbo]
        } else {
            limbos = [
                dilationLimbo,
                controlsLimbo,
                messageLimbo,
                closeLimbo
            ]
        }
    }
    override func layout375x667() {
        let w = UIScreen.main.bounds.size.width - 10*s

        controlsLimbo.frame = CGRect(x: 5*s, y: Screen.height-180*s-Screen.safeBottom, width: w, height: 180*s)
        controlsLimbo.cutouts[Position.bottomRight] = Cutout(width: 139*s, height: 60*s)
        controlsLimbo.cutouts[Position.bottomLeft] = Cutout(width: 56*s, height: 56*s)
        controlsLimbo.renderPaths()

        dilationLimbo.frame = CGRect(x: 5*s, y: Screen.safeTop, width: w, height: controlsLimbo.top-Screen.safeTop)

        messageLimbo.frame = CGRect(x: 5*s, y: Screen.safeTop, width: w, height: Screen.height-Screen.safeTop-Screen.safeBottom)
        messageLimbo.cutouts[Position.bottomRight] = Cutout(width: 139*s, height: 60*s)
        messageLimbo.cutouts[Position.bottomLeft] = Cutout(width: 56*s, height: 56*s)
        messageLimbo.renderPaths()
        
        swapper.topLeft(dx: 5*s, dy: messageLimbo.bottom-56*s, width: 56*s, height: 56*s)
        closeLimbo.topLeft(dx: messageLimbo.right-139*s, dy: messageLimbo.bottom-60*s, width: 139*s, height: 60*s)
        
        playButton.topLeft(dx: 12*s, dy: 28*s, size: CGSize(width: 40*s, height: 30*s))
        resetButton.topLeft(dx: 15*s, dy: playButton.bottom+12*s, size: CGSize(width: 40*s, height: 30*s))
        cSlider.topLeft(dx: resetButton.right+18*s, dy: 96*s, width: 136*s, height: 40*s)
        vSlider.topLeft(dx: cSlider.left-6*s, dy: 16*s, width: cSlider.width, height: cSlider.height)
        autoSwap.topLeft(dx: vSlider.right+8*s, dy: 16*s)
        tailsSwap.topLeft(dx: autoSwap.left, dy: autoSwap.bottom+3*s)
        contractSwap.topLeft(dx: autoSwap.left, dy: tailsSwap.bottom+3*s)
        pulseButton.topRight(dx: -13*s, dy: 21*s, width: 45*s, height: 80*s)

        lightSpeedLabel.topLeft(dx: cSlider.left, dy: cSlider.bottom-8*s, width: cSlider.width, height: 20*s)
        cLabel.topLeft(dx: cSlider.left, dy: lightSpeedLabel.bottom-5*s, width: cSlider.width, height: 20*s)
        velocityLabel.topLeft(dx: vSlider.left, dy: vSlider.bottom-7*s, width: vSlider.width, height: 20*s)
        lambdaLabel.topLeft(dx: vSlider.left, dy: velocityLabel.bottom-5*s, width: vSlider.width, height: 20*s)

        cSlider.setTo(60)
        vSlider.setTo(0.5)
    }
    override func layout1024x768() {
        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let height = Screen.height - topY - botY
        let s = height / 748
        
        let p: CGFloat = 5*s
        let uw: CGFloat = height - 110*s

        dilationLimbo.topLeft(dx: p, dy: topY, width: uw, height: uw)
        closeLimbo.bottomRight(dx: -p, dy: -botY, width: 176*s, height: 110*s)

        controlsLimbo.bottomLeft(dx: p, dy: -botY, width: dilationLimbo.width, height: 110*s)
        closeLimbo.bottomRight(dx: -p, dy: -botY, width: 176*s, height: 110*s)
        
        let bw: CGFloat = 40*s
        playButton.left(dx: 15*s, size: CGSize(width: bw, height: 30*s))
        resetButton.left(dx: 15*s+bw, size: CGSize(width: bw, height: 30*s))
        cSlider.topLeft(dx: resetButton.right+18*s, dy: 16*s, width: 140*s, height: 40*s)
        vSlider.topLeft(dx: cSlider.right+20*s, dy: cSlider.top, width: 140*s, height: 40*s)
        autoSwap.left(dx: vSlider.right+30*s, dy: -30*s)
        tailsSwap.left(dx: autoSwap.left)
        contractSwap.left(dx: autoSwap.left, dy: 30*s)
        pulseButton.right(dx: -15*s, width: 60*s, height: 80*s)

        lightSpeedLabel.topLeft(dx: cSlider.left, dy: cSlider.bottom-8*s, width: cSlider.width, height: 20*s)
        cLabel.topLeft(dx: cSlider.left, dy: lightSpeedLabel.bottom-2*s, width: cSlider.width, height: 20*s)
        velocityLabel.topLeft(dx: vSlider.left, dy: vSlider.bottom-8*s, width: vSlider.width, height: 20*s)
        lambdaLabel.topLeft(dx: vSlider.left, dy: velocityLabel.bottom-2*s, width: vSlider.width, height: 20*s)

        cSlider.setTo(60)
        vSlider.setTo(0.5)

        messageLimbo.frame = CGRect(x: dilationLimbo.right, y: topY, width: Screen.width-2*p-dilationLimbo.width, height: Screen.height-botY-topY)
        messageLimbo.cutouts[Position.bottomRight] = Cutout(width: 176*s, height: 110*s)
        messageLimbo.renderPaths()
    }
}
