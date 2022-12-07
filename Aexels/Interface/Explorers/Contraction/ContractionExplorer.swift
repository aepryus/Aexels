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
    let closeLimbo = LimboButton(title: "Close")

    init(parent: UIView) {
        engine = DilationEngine(size: .zero)
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

        // CloseLimbo
        closeLimbo.alpha = 0
        closeLimbo.addAction(for: .touchUpInside) { [unowned self] in
            self.closeExplorer()
            Aexels.nexus.brightenNexus()
        }
        
        limbos = [dilationLimbo, pulseLimbo, closeLimbo]
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
    }

}
