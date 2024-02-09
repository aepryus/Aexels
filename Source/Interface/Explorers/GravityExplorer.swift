//
//  GravityExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 8/16/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class GravityExplorer: Explorer {
    let engine: GravityEngine
    lazy var gravityView = GravityView(engine: engine)
    let gravityLimbo = Limbo()
    let messageLimbo: MessageLimbo = MessageLimbo()
    let closeLimbo = LimboButton(title: "Close")
    let closeButton: CloseButton = CloseButton()

    init() {
        engine = GravityEngine(size: .zero)
        super.init(name: "Gravity", key: "Gravity", canExplore: true)
    }
    
// Events ==========================================================================================
    override func onOpened() { engine.play() }
    override func onClose() { engine.stop() }

// Explorer ========================================================================================
    override func createLimbos() {
        // AetherLimbo
        gravityLimbo.content = gravityView
        
        // MessageLimbo
        messageLimbo.key = "GravityLab"
        
        // CloseLimbo
        closeLimbo.alpha = 0
        closeLimbo.addAction(for: .touchUpInside) { [unowned self] in
            self.closeExplorer()
//            Aexels.nexus.brightenNexus()
        }

        closeButton.addAction(for: .touchUpInside) { [unowned self] in
            self.closeExplorer()
//            Aexels.nexus.brightenNexus()
        }
        
//        if Screen.iPhone {
//            first = [messageLimbo]
//            second = [aetherLimbo, expLimbo]
//            brightenLimbos(second)
//            limbos = [swapper, closeLimbo] + second
//        } else {
//            limbos = [aetherLimbo, expLimbo, messageLimbo, closeButton];
//        }

        limbos = [gravityLimbo, messageLimbo, closeButton];
    }
    override func layout375x667() {
//        let size = UIScreen.main.bounds.size
        
//        let w = size.width - 10*s

//        gravityLimbo.frame = CGRect(x: 5*s, y: Screen.safeTop, width: w, height: expLimbo.top-Screen.safeTop)
//        closeLimbo.topLeft(dx: messageLimbo.right-139*s, dy: messageLimbo.bottom-60*s, width: 139*s, height: 60*s)
    }
    override func layout1024x768() {
        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let height = Screen.height - topY - botY
        let s = height / 748
        
        let p: CGFloat = 5*s
        let uw: CGFloat = height - 110*s

        gravityLimbo.topLeft(dx: p, dy: topY, width: uw, height: uw)

        messageLimbo.frame = CGRect(x: gravityLimbo.right, y: topY, width: Screen.width-2*p-gravityLimbo.width, height: Screen.height-botY-topY)
        messageLimbo.closeOn = true
        messageLimbo.renderPaths()
        
        closeButton.topLeft(dx: messageLimbo.right-50*s, dy: messageLimbo.top, width: 50*s, height: 50*s)
        
        engine.universe.pointee.width = gravityView.width
        engine.universe.pointee.height = gravityView.height
    }
}
