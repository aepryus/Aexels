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
    let cameraSwap: BoolButton = BoolButton(text: "fixed")
    let pulseButton: PulseButton = PulseButton()
    let controlsView: UIView = UIView()
    let messageLimbo: MessageLimbo = MessageLimbo()
    let closeLimbo = LimboButton(title: "Close")
    let closeButton: CloseButton = CloseButton()
    
    let lightSpeedLabel: UILabel = UILabel()
    let cLabel: UILabel = UILabel()
    let velocityLabel: UILabel = UILabel()
    let lambdaLabel: UILabel = UILabel()
    
    var cameraOn: Bool = false

    let swapper: Limbo = Limbo()
    let swapButton: SwapButton = SwapButton()
    var first: [Limbo] = []
    var second: [Limbo] = []
    var isFirst: Bool = false
    
    let cyto: Cyto = Cyto(rows: 2, cols: 2)

	init() {
        let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
        let s: CGFloat = height / 748
        let mainLen: CGFloat = height - 110*s
        let fixLen: CGFloat = Screen.width - mainLen - 10*s

        engine = DilationEngine(size: CGSize(width: max(mainLen, fixLen*2+123), height: mainLen))
        
        super.init(name: "Dilation", key: "dilation", canExplore: true)
        
        engine.onVelocityChange = { (v: TCVelocity) in
            let italicPen: Pen = Pen(font: UIFont(name: "Verdana-Italic", size: 10*s)!, color: .white, alignment: .center)
            let sb = italicPen.format("γ = \(String(format: "%3.2f", TCLambda(self.engine.velocity)))")
            self.lambdaLabel.attributedText = sb
        }
    }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // DilationLimbo
        dilationLimbo.content = dilationView
        fixedDilationLimbo.content = fixedDilationView
        
        controlsView.addSubview(cSlider)
        cSlider.onChange = { (speedOfLight: Double) in
            self.engine.speedOfLight = speedOfLight
        }

        controlsView.addSubview(vSlider)
        vSlider.onChange = { (velocity: Double) in
            self.engine.velocity = velocity
            self.engine.camera.pointee.v.s = abs(velocity)
            self.engine.camera.pointee.v.q = velocity > 0 ? .pi/2 : .pi*3/2
        }

        playButton.playing = true
        controlsView.addSubview(playButton)
        playButton.onPlay = { [unowned self] in
            self.engine.play()
        }
        playButton.onStop = { [unowned self] in
            self.engine.stop()
        }

        controlsView.addSubview(resetButton)
        resetButton.addAction(for: .touchUpInside) { [unowned self] in
            self.engine.reset()
            self.engine.tic()
        }
        
        controlsView.addSubview(tailsSwap)
        tailsSwap.addAction(for: .touchUpInside) { [unowned self] in
            self.tailsSwap.rotateView()
            self.engine.tailsOn = !self.engine.tailsOn
        }

        controlsView.addSubview(autoSwap)
        autoSwap.addAction(for: .touchUpInside) { [unowned self] in
            self.autoSwap.rotateView()
            self.engine.autoOn = !self.engine.autoOn
        }

        controlsView.addSubview(cameraSwap)
        cameraSwap.addAction(for: .touchUpInside) { [unowned self] in
            self.cameraSwap.rotateView()
            self.swapCamera()
        }
        
        controlsView.addSubview(pulseButton)
        pulseButton.addAction {
            self.engine.pulse()
        }

        // MessageLimbo
        messageLimbo.key = "DilationLab"

        // Swapper =========================
        if Screen.iPhone {
            swapButton.addAction(for: .touchUpInside) { [unowned self] in
                self.swapButton.rotateView()
                if self.isFirst {
                    self.isFirst = false
                    self.dimLimbos(self.first)
                    self.brightenLimbos(self.second)
//                    self.limbos = [self.swapper] + self.second + [self.closeLimbo]
                } else {
                    self.isFirst = true
                    self.dimLimbos(self.second)
                    self.brightenLimbos(self.first)
//                    self.limbos = [self.swapper] + self.first + [self.closeLimbo]
                }
                self.swapper.removeFromSuperview()
                self.view.addSubview(self.swapper)
                self.closeLimbo.removeFromSuperview()
                self.view.addSubview(self.closeLimbo)
            }
            swapper.content = swapButton
        }

        // CloseLimbo
        closeLimbo.alpha = 0
        closeLimbo.addAction(for: .touchUpInside) { [unowned self] in
            self.closeExplorer()
//            Aexels.nexus.brightenNexus()
        }

        closeButton.alpha = 0
        closeButton.addAction(for: .touchUpInside) { [unowned self] in
            self.closeExplorer()
//            Aexels.nexus.brightenNexus()
        }
        
        // Labels
        let pen: Pen = Pen(font: .verdana(size: 15*s), color: .white, alignment: .center)
        let italicPen: Pen = Pen(font: UIFont(name: "Verdana-Italic", size: 10*s)!, color: .white, alignment: .center)
        
        var sb = pen.format("speed of light (c)")
        lightSpeedLabel.attributedText = sb
        controlsView.addSubview(lightSpeedLabel)
        
        sb = italicPen.format("points per second")
        cLabel.attributedText = sb
        controlsView.addSubview(cLabel)
        
        sb = pen.format("velocity (% of c)")
        velocityLabel.attributedText = sb
        controlsView.addSubview(velocityLabel)
        
        sb = italicPen.format("γ = \(String(format: "%3.2f", TCLambda(engine.velocity)))")
        lambdaLabel.attributedText = sb
        controlsView.addSubview(lambdaLabel)

//        if Screen.iPhone {
//            first = [messageLimbo]
//            second = [dilationLimbo, controlsView]
//            brightenLimbos(second)
//            limbos = [swapper] + second + [closeLimbo]
//        } else {
//            limbos = [
//                dilationLimbo,
//                controlsView,
//                messageLimbo,
//                closeButton
//            ]
//        }
        
        cyto.cells = [
            LimboCell(content: dilationView, c: 0, r: 0),
            LimboCell(content: UIView(), c: 1, r: 0, h: 2, cutout: true),
            LimboCell(content: controlsView, c: 0, r: 1),
        ]
        view.addSubview(cyto)
    }
    
// AEViewController ================================================================================
    override func layout1024x768() {
        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let height = Screen.height - topY - botY
        let s = height / 748
        
//        let p: CGFloat = 5*s
        let uw: CGFloat = height - 110*s
        
        cyto.Xs = [uw]
        cyto.Ys = [uw]
        cyto.frame = CGRect(x: 5*s, y: topY, width: view.width-10*s, height: view.height-topY-botY)
        cyto.layout()

//        dilationLimbo.topLeft(dx: p, dy: topY, width: uw, height: uw)
//        let vw: CGFloat = Screen.width - dilationLimbo.right - p
//        fixedDilationLimbo.topLeft(dx: dilationLimbo.right, dy: topY+height-vw, width: vw, height: vw)

//        controlsView.bottomLeft(dx: p, dy: -botY, width: dilationLimbo.width, height: 110*s)
//        closeButton.bottomRight(dx: -p, dy: -botY, width: 176*s, height: 110*s)
        
        let bw: CGFloat = 40*s
        playButton.left(size: CGSize(width: bw, height: 30*s))
        resetButton.left(dx: bw, size: CGSize(width: bw, height: 30*s))
        cSlider.topLeft(dx: resetButton.right+18*s, dy: 1*s, width: 140*s, height: 40*s)
        vSlider.topLeft(dx: cSlider.right+20*s, dy: cSlider.top, width: 140*s, height: 40*s)
        autoSwap.left(dx: vSlider.right+30*s, dy: -30*s)
        tailsSwap.left(dx: autoSwap.left)
        cameraSwap.left(dx: autoSwap.left, dy: 30*s)
        pulseButton.right(dx: -15*s, width: 60*s, height: 80*s)

        lightSpeedLabel.topLeft(dx: cSlider.left, dy: cSlider.bottom-8*s, width: cSlider.width, height: 20*s)
        cLabel.topLeft(dx: cSlider.left, dy: lightSpeedLabel.bottom-2*s, width: cSlider.width, height: 20*s)
        velocityLabel.topLeft(dx: vSlider.left, dy: vSlider.bottom-8*s, width: vSlider.width, height: 20*s)
        lambdaLabel.topLeft(dx: vSlider.left, dy: velocityLabel.bottom-2*s, width: vSlider.width, height: 20*s)

//        messageLimbo.frame = CGRect(x: dilationLimbo.right, y: topY, width: Screen.width-2*p-dilationLimbo.width, height: Screen.height-botY-topY)
//        messageLimbo.closeOn = true
//        messageLimbo.renderPaths()
        
//        closeButton.topLeft(dx: messageLimbo.right-50*s, dy: messageLimbo.top, width: 50*s, height: 50*s)

        cSlider.setTo(60)
        vSlider.setTo(0.5)
    }

// =================================================================================================
// =================================================================================================
// =================================================================================================
// =================================================================================================
// =================================================================================================

    func swapCamera() {
        self.cameraOn = !cameraOn
        
        if !Screen.iPhone {
            let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
            let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
            let height = Screen.height - topY - botY
            let s = height / 748
            
            let p: CGFloat = 5*s

            if self.cameraOn {
                messageLimbo.frame = CGRect(x: dilationLimbo.right, y: topY, width: Screen.width-2*p-dilationLimbo.width, height: fixedDilationLimbo.top-topY)
                brightenLimbos([fixedDilationLimbo])
//                limbos = [
//                    dilationLimbo,
//                    fixedDilationLimbo,
//                    controlsView,
//                    messageLimbo,
//                    closeButton
//                ]
            } else {
                messageLimbo.frame = CGRect(x: dilationLimbo.right, y: topY, width: Screen.width-2*p-dilationLimbo.width, height: Screen.height-botY-topY)
                dimLimbos([fixedDilationLimbo])
//                limbos = [
//                    dilationLimbo,
//                    controlsView,
//                    messageLimbo,
//                    closeButton
//                ]
            }
        } else {
            if self.cameraOn {
//                first = [messageLimbo]
//                second = [fixedDilationLimbo, controlsView]
//                dimLimbos([dilationLimbo])
//                brightenLimbos([fixedDilationLimbo])
//                limbos = [
//                    fixedDilationLimbo,
//                    controlsView,
//                    swapper,
//                    closeLimbo
//                ]
            } else {
//                first = [messageLimbo]
//                second = [dilationLimbo, controlsView]
//                dimLimbos([fixedDilationLimbo])
//                brightenLimbos([dilationLimbo])
//                limbos = [
//                    dilationLimbo,
//                    controlsView,
//                    swapper,
//                    closeLimbo
//                ]
            }
        }
    }
    
// Events ==========================================================================================
    override func onOpened() { engine.play() }
    override func onClose() { engine.stop() }

// Explorer ========================================================================================
    override func layout375x667() {
        let w = UIScreen.main.bounds.size.width - 10*s

        controlsView.frame = CGRect(x: 5*s, y: Screen.height-180*s-Screen.safeBottom, width: w, height: 180*s)
//        controlsView.cutouts[Position.bottomRight] = Cutout(width: 139*s, height: 60*s)
//        controlsView.cutouts[Position.bottomLeft] = Cutout(width: 56*s, height: 56*s)
//        controlsView.renderPaths()

        dilationLimbo.frame = CGRect(x: 5*s, y: Screen.safeTop, width: w, height: controlsView.top-Screen.safeTop)
        fixedDilationLimbo.frame = dilationLimbo.frame

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
        autoSwap.topLeft(dx: vSlider.right+16*s, dy: 16*s)
        tailsSwap.topLeft(dx: autoSwap.left, dy: autoSwap.bottom+3*s)
        cameraSwap.topLeft(dx: autoSwap.left, dy: tailsSwap.bottom+3*s)
        pulseButton.topRight(dx: -16*s, dy: 21*s, width: 45*s, height: 80*s)

        lightSpeedLabel.topLeft(dx: cSlider.left, dy: cSlider.bottom-8*s, width: cSlider.width, height: 20*s)
        cLabel.topLeft(dx: cSlider.left, dy: lightSpeedLabel.bottom-5*s, width: cSlider.width, height: 20*s)
        velocityLabel.topLeft(dx: vSlider.left, dy: vSlider.bottom-7*s, width: vSlider.width, height: 20*s)
        lambdaLabel.topLeft(dx: vSlider.left, dy: velocityLabel.bottom-5*s, width: vSlider.width, height: 20*s)

        cSlider.setTo(60)
        vSlider.setTo(0.5)
    }
}
