//
//  GravityExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class GravityExplorer: Explorer {
	let gravityView = GravityView()
	let gravityLimbo = Limbo()
    let expAButton = ExpButton(name: Screen.iPhone ? "12" : "12\nAexels")
	let expBButton = ExpButton(name: Screen.iPhone ? "60" : "60\nAexels")
	let expCButton = ExpButton(name: Screen.iPhone ? "360" : "360\nAexels")
	let expDButton = ExpButton(name: Screen.iPhone ? "G\no\nL" : "Game\nof\nLife")
    let expEButton = ExpButton(shape: .line)
    let expFButton = ExpButton(shape: .rectangle)
    let expGButton = ExpButton(shape: .box)
    let expHButton = ExpButton(shape: .ring)
    let expIButton = ExpButton(shape: .circle)
    let expJButton = ExpButton(shape: .nothing)
	let expLimbo = Limbo()
	let messageLimbo: MessageLimbo = MessageLimbo()
	let closeLimbo = LimboButton(title: "Close")
    let closeButton: CloseButton = CloseButton()
    lazy var experiments: [ExpButton] = { [
        expAButton,
        expBButton,
        expCButton,
        expDButton,
        expEButton,
        expFButton,
        expGButton,
        expHButton,
        expIButton,
        expJButton
    ] }()
	
	let swapper: Limbo = Limbo()
	let swapButton: SwapButton = SwapButton()
	var first = [Limbo]()
	var second = [Limbo]()
	var isFirst: Bool = false

	init(parent: UIView) {
		super.init(parent: parent, name: "Gravity", key: "Gravity", canExplore: true)
	}
	
// Events ==========================================================================================
	override func onOpen() {
		Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
			self.gravityView.tic()
			complete()
		}
		Aexels.sync.link.preferredFramesPerSecond = 60
		
	}
	override func onOpened() {
		self.gravityView.play()
	}
	override func onClose() {
		self.gravityView.stop()
	}

// Explorer ========================================================================================
	override func createLimbos() {
		// GravityLimbo
		gravityLimbo.content = gravityView
		
		expAButton.addAction {
            self.experiments.forEach { $0.activated = false }
			self.gravityView.experimentA()
			self.expAButton.activated = true
		}
		self.expAButton.activated = true
		expLimbo.addSubview(expAButton)

		expBButton.addAction {
            self.experiments.forEach { $0.activated = false }
			self.gravityView.experimentB()
			self.expBButton.activated = true
		}
		expLimbo.addSubview(expBButton)

		expCButton.addAction {
            self.experiments.forEach { $0.activated = false }
			self.gravityView.experimentC()
			self.expCButton.activated = true
		}
		expLimbo.addSubview(expCButton)

		expDButton.addAction {
            self.experiments.forEach { $0.activated = false }
			self.gravityView.experimentD()
			self.expDButton.activated = true
		}
		expLimbo.addSubview(expDButton)

        expEButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.gravityView.experimentE()
            self.expEButton.activated = true
        }
        expLimbo.addSubview(expEButton)

        expFButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.gravityView.experimentF()
            self.expFButton.activated = true
        }
        expLimbo.addSubview(expFButton)

        expGButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.gravityView.experimentG()
            self.expGButton.activated = true
        }
        expLimbo.addSubview(expGButton)

        expHButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.gravityView.experimentH()
            self.expHButton.activated = true
        }
        expLimbo.addSubview(expHButton)

        expIButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.gravityView.experimentI()
            self.expIButton.activated = true
        }
        expLimbo.addSubview(expIButton)
        
        expJButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.gravityView.experimentJ()
            self.expJButton.activated = true
        }
        expLimbo.addSubview(expJButton)

		// MessageLimbo
		messageLimbo.key = "GravityLab"
		
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

        closeButton.addAction(for: .touchUpInside) { [unowned self] in
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		
		if Screen.iPhone {
			first = [messageLimbo]
			second = [gravityLimbo, expLimbo]
			brightenLimbos(second)
			limbos = [swapper, closeLimbo] + second
		} else {
			limbos = [gravityLimbo, expLimbo, messageLimbo, closeButton];
		}
	}
	override func layout375x667() {
        let size = UIScreen.main.bounds.size
        
        let w = size.width - 10*s

        expLimbo.frame = CGRect(x: 5*s, y: Screen.height-140*s-Screen.safeBottom, width: w, height: 140*s)
        expLimbo.cutouts[Position.bottomRight] = Cutout(width: 139*s, height: 60*s)
        expLimbo.cutouts[Position.bottomLeft] = Cutout(width: 56*s, height: 56*s)
        expLimbo.renderPaths()

        gravityLimbo.frame = CGRect(x: 5*s, y: Screen.safeTop, width: w, height: expLimbo.top-Screen.safeTop)

        let om = 15*s
        let im = 6*s
        let bw = (expLimbo.width-2*om-9*im)/10
        let bh = (expLimbo.height-2*om)/1-60*s
        expAButton.topLeft(dx: om, dy: om, width: bw, height: bh)
        expBButton.topLeft(dx: om+bw+im, dy: om, width: bw, height: bh)
        expCButton.topLeft(dx: om+2*bw+2*im, dy: om, width: bw, height: bh)
        expDButton.topLeft(dx: om+3*bw+3*im, dy: om, width: bw, height: bh)
        expEButton.topLeft(dx: om+4*bw+4*im, dy: om, width: bw, height: bh)
        expFButton.topLeft(dx: om+5*bw+5*im, dy: om, width: bw, height: bh)
        expGButton.topLeft(dx: om+6*bw+6*im, dy: om, width: bw, height: bh)
        expHButton.topLeft(dx: om+7*bw+7*im, dy: om, width: bw, height: bh)
        expIButton.topLeft(dx: om+8*bw+8*im, dy: om, width: bw, height: bh)
        expJButton.topLeft(dx: om+9*bw+9*im, dy: om, width: bw, height: bh)

        messageLimbo.frame = CGRect(x: 5*s, y: Screen.safeTop, width: w, height: Screen.height-Screen.safeTop-Screen.safeBottom)
        messageLimbo.cutouts[Position.bottomRight] = Cutout(width: 139*s, height: 60*s)
        messageLimbo.cutouts[Position.bottomLeft] = Cutout(width: 56*s, height: 56*s)
        messageLimbo.renderPaths()
        
        swapper.topLeft(dx: 5*s, dy: messageLimbo.bottom-56*s, width: 56*s, height: 56*s)
        closeLimbo.topLeft(dx: messageLimbo.right-139*s, dy: messageLimbo.bottom-60*s, width: 139*s, height: 60*s)
	}
	override func layout1024x768() {
		let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
		let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
		let height = Screen.height - topY - botY
		let s = height / 748
		
		let p: CGFloat = 5*s
		let uw: CGFloat = height - 110*s

		gravityLimbo.topLeft(dx: p, dy: topY, width: uw, height: uw)
		expLimbo.topLeft(dx: p, dy: gravityLimbo.bottom, width: gravityLimbo.width, height: Screen.height-botY-gravityLimbo.bottom)

		let om = 24*s
		let im = 6*s
		let bw = (expLimbo.width-2*om-9*im)/10
		let bh = (expLimbo.height-2*om)/1
		expAButton.topLeft(dx: om, dy: om, width: bw, height: bh)
		expBButton.topLeft(dx: om+bw+im, dy: om, width: bw, height: bh)
		expCButton.topLeft(dx: om+2*bw+2*im, dy: om, width: bw, height: bh)
		expDButton.topLeft(dx: om+3*bw+3*im, dy: om, width: bw, height: bh)
        expEButton.topLeft(dx: om+4*bw+4*im, dy: om, width: bw, height: bh)
        expFButton.topLeft(dx: om+5*bw+5*im, dy: om, width: bw, height: bh)
        expGButton.topLeft(dx: om+6*bw+6*im, dy: om, width: bw, height: bh)
        expHButton.topLeft(dx: om+7*bw+7*im, dy: om, width: bw, height: bh)
        expIButton.topLeft(dx: om+8*bw+8*im, dy: om, width: bw, height: bh)
        expJButton.topLeft(dx: om+9*bw+9*im, dy: om, width: bw, height: bh)

		messageLimbo.frame = CGRect(x: gravityLimbo.right, y: topY, width: Screen.width-2*p-gravityLimbo.width, height: Screen.height-botY-topY)
        messageLimbo.closeOn = true
		messageLimbo.renderPaths()
        
        closeButton.topLeft(dx: messageLimbo.right-50*s, dy: messageLimbo.top, width: 50*s, height: 50*s)
	}
}
