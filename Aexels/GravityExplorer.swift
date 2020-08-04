//
//  GravityExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumLib
import UIKit

class GravityExplorer: Explorer {
	let gravityView = GravityView()
	let gravityLimbo = Limbo()
	let expAButton = ExpButton(name: "12\nAexels")
	let expBButton = ExpButton(name: "60\nAexels")
	let expCButton = ExpButton(name: "360\nAexels")
	let expDButton = ExpButton(name: "Game\nof\nLife")
	let expLimbo = Limbo()
	let messageLimbo: MessageLimbo = MessageLimbo()
	let closeLimbo = LimboButton(title: "Close")
	
	let swapper: Limbo = Limbo()
	let swapButton: SwapButton = SwapButton()
	var first = [Limbo]()
	var second = [Limbo]()
	var isFirst: Bool = true

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
			self.gravityView.experimentA()
			self.expAButton.activated = true
			self.expBButton.activated = false
			self.expCButton.activated = false
			self.expDButton.activated = false
		}
		self.expAButton.activated = true
		expLimbo.addSubview(expAButton)

		expBButton.addAction {
			self.gravityView.experimentB()
			self.expAButton.activated = false
			self.expBButton.activated = true
			self.expCButton.activated = false
			self.expDButton.activated = false
		}
		expLimbo.addSubview(expBButton)

		expCButton.addAction {
			self.gravityView.experimentC()
			self.expAButton.activated = false
			self.expBButton.activated = false
			self.expCButton.activated = true
			self.expDButton.activated = false
		}
		expLimbo.addSubview(expCButton)

		expDButton.addAction {
			self.gravityView.experimentD()
			self.expAButton.activated = false
			self.expBButton.activated = false
			self.expCButton.activated = false
			self.expDButton.activated = true
		}
		expLimbo.addSubview(expDButton)
		
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
			limbos.append(swapper)
		}

		// CloseLimbo
		closeLimbo.alpha = 0
		closeLimbo.addAction(for: .touchUpInside) { [unowned self] in
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		
		if Screen.iPhone {
			first = [messageLimbo]
			second = [gravityLimbo, expLimbo]
			brightenLimbos(first)
			limbos = [swapper] + first + [closeLimbo]
		} else {
			limbos = [gravityLimbo, expLimbo, messageLimbo, closeLimbo];
		}
	}
	override func layout375x667() {
		let size = UIScreen.main.bounds.size
		
//		let h = size.height - 110*s - 20*s
		let w = size.width - 10*s
//		let ch = size.height - 20*s - h - 15*2*s + 1*s
//		let vw: CGFloat = 72*s
//		let sh: CGFloat = 56*s
//
//
//		let dx: CGFloat = 32*s

		expLimbo.frame = CGRect(x: 5*s, y: Screen.height-140*s-Screen.safeBottom, width: w, height: 140*s)
		expLimbo.cutouts[Position.bottomRight] = Cutout(width: 139*s, height: 60*s)
		expLimbo.cutouts[Position.bottomLeft] = Cutout(width: 56*s, height: 56*s)
		expLimbo.renderPaths()

		gravityLimbo.frame = CGRect(x: 5*s, y: Screen.safeTop, width: w, height: expLimbo.top-Screen.safeTop)

		let om = 15*s
		let im = 9*s
		let bw = (expLimbo.width-2*om-3*im)/4
		let bh = (expLimbo.height-2*om)/1-60*s
		expAButton.topLeft(dx: om, dy: om, width: bw, height: bh)
		expBButton.topLeft(dx: om+bw+im, dy: om, width: bw, height: bh)
		expCButton.topLeft(dx: om+2*bw+2*im, dy: om, width: bw, height: bh)
		expDButton.topLeft(dx: om+3*bw+3*im, dy: om, width: bw, height: bh)

		messageLimbo.frame = CGRect(x: 5*s, y: Screen.safeTop, width: w, height: Screen.height-Screen.safeTop-Screen.safeBottom)
		messageLimbo.cutouts[Position.bottomRight] = Cutout(width: 139*s, height: 60*s)
		messageLimbo.cutouts[Position.bottomLeft] = Cutout(width: 56*s, height: 56*s)
		messageLimbo.renderPaths()
		
		swapper.topLeft(dx: 5*s, dy: messageLimbo.bottom-56*s, width: 56*s, height: 56*s)
		closeLimbo.topLeft(dx: messageLimbo.right-139*s, dy: messageLimbo.bottom-60*s, width: 139*s, height: 60*s)
	}
	override func layout1024x768() {
		let height = Screen.height - Screen.safeTop - Screen.safeBottom
		let s = height / 748
		
		let p: CGFloat = 5*s
		let uw: CGFloat = height

		gravityLimbo.topLeft(dx: p, dy: Screen.safeTop, width: uw, height: uw)
		closeLimbo.bottomRight(dx: -p, dy: -Screen.safeBottom, width: 176*s, height: 110*s)
		expLimbo.topRight(dx: -p, dy: Screen.safeTop, width: Screen.width-2*p-gravityLimbo.width, height: 80*s)

		let om = 15*s
		let im = 9*s
		let bw = (expLimbo.width-2*om-3*im)/4
		let bh = (expLimbo.height-2*om)/1
		expAButton.topLeft(dx: om, dy: om, width: bw, height: bh)
		expBButton.topLeft(dx: om+bw+im, dy: om, width: bw, height: bh)
		expCButton.topLeft(dx: om+2*bw+2*im, dy: om, width: bw, height: bh)
		expDButton.topLeft(dx: om+3*bw+3*im, dy: om, width: bw, height: bh)
		
		messageLimbo.frame = CGRect(x: gravityLimbo.right, y: expLimbo.bottom, width: expLimbo.width, height: Screen.height-expLimbo.bottom-Screen.safeBottom)
		messageLimbo.cutouts[Position.bottomRight] = Cutout(width: 176*s, height: 110*s)
		messageLimbo.renderPaths()
	}
}
