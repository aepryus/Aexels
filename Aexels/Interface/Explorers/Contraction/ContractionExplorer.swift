//
//  ContractionExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ContractionExplorer: Explorer {
    let engine: DilationEngine
    lazy var dilationView: DilationView = DilationView(engine: engine)
    let dilationLimbo: Limbo = Limbo()
    let pulseLimbo = LimboButton(title: "Pulse")
    let cSlider: CSlider = CSlider()
    let cLimbo: Limbo = Limbo()
    let vSlider: VSlider = VSlider()
    let vLimbo: Limbo = Limbo()
    let playButton: PlayButton = PlayButton()
    let resetButton: ResetButton = ResetButton()
    let trailsSwap: SwapButton = SwapButton(expandHitBox: false)
    let autoSwap: SwapButton = SwapButton(expandHitBox: false)
    let contractSwap: SwapButton = SwapButton(expandHitBox: false)
    let controlsLimbo: Limbo = Limbo()
    let closeLimbo = LimboButton(title: "Close")

    init(parent: UIView) {
        let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
        let s: CGFloat = height / 748
        let mainLen: CGFloat = height - 110*s
        let fixLen: CGFloat = Screen.width - mainLen - 10*s

        engine = DilationEngine(size: CGSize(width: max(mainLen, fixLen*2+123), height: mainLen), horizontalOn: true)

        super.init(parent: parent, name: "Contraction", key: "Contraction", canExplore: true)
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
        
        // PulseLimbo
        pulseLimbo.alpha = 0
        pulseLimbo.addAction { [unowned self] in
            self.engine.pulse()
        }
        
        cSlider.onChange = { (speedOfLight: Double) in
            self.engine.speedOfLight = speedOfLight
        }
        cLimbo.content = cSlider
                
        vSlider.onChange = { (velocity: Double) in
            self.engine.velocity = velocity
            self.engine.camera.pointee.v.s = abs(velocity)
            self.engine.camera.pointee.v.q = velocity > 0 ? .pi/2 : .pi*3/2
        }
        vLimbo.content = vSlider
        
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
//            self.engine.camera = self.engine.createCamera()
//            self.engine.camera = self.engine.createCamera(teleport: true)
            self.engine.tic()
        }
        
        controlsLimbo.addSubview(trailsSwap)
        trailsSwap.addAction(for: .touchUpInside) { [unowned self] in
            self.trailsSwap.rotateView()
            self.engine.trailsOn = !self.engine.trailsOn
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

        // CloseLimbo
        closeLimbo.alpha = 0
        closeLimbo.addAction(for: .touchUpInside) { [unowned self] in
            self.closeExplorer()
            Aexels.nexus.brightenNexus()
        }
                
        limbos = [
            dilationLimbo,
            pulseLimbo,
            controlsLimbo,
            cLimbo,
            vLimbo,
            closeLimbo
        ]
    }
    override func layout375x667() {
//        gravityLimbo.frame = CGRect(x: 5*s, y: Screen.safeTop, width: w, height: expLimbo.top-Screen.safeTop)
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
        pulseLimbo.bottomLeft(dx: p, dy: -botY, width: 176*s, height: 110*s)
        closeLimbo.bottomRight(dx: -p, dy: -botY, width: 176*s, height: 110*s)

        cLimbo.bottomLeft(dx: pulseLimbo.right, dy: -botY, width: 176*s, height: 110*s)
        vLimbo.bottomLeft(dx: cLimbo.right, dy: -botY, width: 176*s, height: 110*s)
        controlsLimbo.bottomLeft(dx: vLimbo.right, dy: -botY, width: 266*s, height: 110*s)
        closeLimbo.bottomRight(dx: -p, dy: -botY, width: 176*s, height: 110*s)
        
        let bw: CGFloat = 40*s
        playButton.left(dx: 15*s, size: CGSize(width: bw, height: 30*s))
        resetButton.left(dx: 15*s+bw, size: CGSize(width: bw, height: 30*s))
        trailsSwap.left(dx: resetButton.right+20*s, size: CGSize(width: 26*s, height: 26*s))
        autoSwap.left(dx: trailsSwap.right+15*s, size: CGSize(width: 26*s, height: 26*s))
        contractSwap.left(dx: autoSwap.right+15*s, size: CGSize(width: 26*s, height: 26*s))

        cSlider.setTo(60)
        vSlider.setTo(0.5)
    }
}
