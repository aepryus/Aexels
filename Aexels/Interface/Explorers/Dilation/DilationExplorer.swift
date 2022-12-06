//
//  DilationExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class DilationExplorer: Explorer {
    let dilationView: DilationView = DilationView()
    let dilationLimbo: Limbo = Limbo()
    let fixedDilationView: DilationView = DilationView(chaseCameraOn: true)
    let fixedDilationLimbo: Limbo = Limbo()
    let pulseLimbo = LimboButton(title: "Pulse")
    let cSlider: CSlider = CSlider()
    let cLimbo: Limbo = Limbo()
    let vSlider: VSlider = VSlider()
    let vLimbo: Limbo = Limbo()
    let playButton: PlayButton = PlayButton()
    let resetButton: ResetButton = ResetButton()
    let trailsSwap: SwapButton = SwapButton(expandHitBox: false)
    let autoSwap: SwapButton = SwapButton(expandHitBox: false)
    let controlsLimbo: Limbo = Limbo()
    let closeLimbo = LimboButton(title: "Close")
    
	init(parent: UIView) { super.init(parent: parent, name: "Dilation", key: "Dilation", canExplore: true) }
    
// Events ==========================================================================================
    var n: Int = 1
    override func onOpen() {
        Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
            self.dilationView.tic()
            self.fixedDilationView.slaveTic()
            self.n += 1
            if self.dilationView.autoOn && self.n % 120 == 0 { self.dilationView.pulse() }
            complete()
        }
        Aexels.sync.link.preferredFramesPerSecond = 60
        
    }
    override func onOpened() {
        self.dilationView.play()
    }
    override func onClose() {
        self.dilationView.stop()
    }

// Explorer ========================================================================================
    override func createLimbos() {
        // DilationLimbo
        dilationLimbo.content = dilationView
        fixedDilationLimbo.content = fixedDilationView
        fixedDilationView.extractUniverse(from: dilationView)
        
        cSlider.onChange = { (speedOfLight: Double) in
            self.dilationView.speedOfLight = speedOfLight
        }
        cLimbo.content = cSlider
        
        
        vSlider.onChange = { (velocity: Double) in
            self.dilationView.velocity = velocity
        }
        vLimbo.content = vSlider
        
        playButton.playing = true
        controlsLimbo.addSubview(playButton)
        playButton.onPlay = { [unowned self] in
            self.dilationView.play()
        }
        playButton.onStop = { [unowned self] in
            self.dilationView.stop()
        }

        controlsLimbo.addSubview(resetButton)
        resetButton.addAction(for: .touchUpInside) { [unowned self] in
            self.playButton.stop()
            self.dilationView.reset()
            self.dilationView.tic()
        }
        
        controlsLimbo.addSubview(trailsSwap)
        trailsSwap.addAction(for: .touchUpInside) { [unowned self] in
            self.trailsSwap.rotateView()
            self.dilationView.trailsOn = !self.dilationView.trailsOn
        }

        controlsLimbo.addSubview(autoSwap)
        autoSwap.addAction(for: .touchUpInside) { [unowned self] in
            self.autoSwap.rotateView()
            self.dilationView.autoOn = !self.dilationView.autoOn
        }

        // PulseLimbo
        pulseLimbo.alpha = 0
        pulseLimbo.addAction { [unowned self] in
            self.dilationView.pulse()
        }

        // CloseLimbo
        closeLimbo.alpha = 0
        closeLimbo.addAction(for: .touchUpInside) { [unowned self] in
            self.closeExplorer()
            Aexels.nexus.brightenNexus()
        }
        
        limbos = [
            dilationLimbo,
            fixedDilationLimbo,
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

        let vw: CGFloat = Screen.width - dilationLimbo.right - p
        fixedDilationLimbo.topLeft(dx: dilationLimbo.right, dy: topY, width: vw, height: vw)
        pulseLimbo.bottomLeft(dx: p, dy: -botY, width: 176*s, height: 110*s)
        cLimbo.bottomLeft(dx: pulseLimbo.right, dy: -botY, width: 176*s, height: 110*s)
        vLimbo.bottomLeft(dx: cLimbo.right, dy: -botY, width: 176*s, height: 110*s)
        controlsLimbo.bottomLeft(dx: vLimbo.right, dy: -botY, width: 216*s, height: 110*s)
        closeLimbo.bottomRight(dx: -p, dy: -botY, width: 176*s, height: 110*s)
        
        let bw: CGFloat = 40*s
        playButton.left(dx: 15*s, size: CGSize(width: bw, height: 30*s))
        resetButton.left(dx: 15*s+bw, size: CGSize(width: bw, height: 30*s))
        trailsSwap.left(dx: resetButton.right+20*s, size: CGSize(width: 26*s, height: 26*s))
        autoSwap.left(dx: trailsSwap.right+15*s, size: CGSize(width: 26*s, height: 26*s))
    }
}
