//
//  GravityExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class GravityExplorer: Explorer {
	let gravityView = GravityView()
	let gravityLimbo = Limbo()
	let playButton = PlayButton()
	let playLimbo = Limbo()
	let resetButton = ResetButton()
	let resetLimbo = Limbo()
	let closeLimbo = LimboButton(title: "Close")

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
//		playButton.play()
	}
	override func onClose() {
		playButton.stop()
	}

// Explorer ========================================================================================
	override func createLimbos() {
		// GravityLimbo
		gravityLimbo.content = gravityView

		// PlayLimbo
		playButton.onPlay = { [unowned self] in
			self.gravityView.play()
		}
		playButton.onStop = { [unowned self] in
			self.gravityView.stop()
		}
		playLimbo.content = playButton
		
		// ResetLimbo
		resetButton.addAction(for: .touchUpInside) { [unowned self] in
			self.playButton.stop()
			self.gravityView.reset()
			self.playButton.play()
		}
		resetLimbo.content = resetButton
		
		// CloseLimbo
		closeLimbo.alpha = 0
		closeLimbo.addAction(for: .touchUpInside) { [unowned self] in
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		
		limbos = [gravityLimbo,playLimbo,resetLimbo,closeLimbo];
	}
	override func layout1024x768() {
		let height = Screen.height - Screen.safeTop - Screen.safeBottom
		let s = height / 748
		
		let p: CGFloat = 5*s
		let uw: CGFloat = height

		gravityLimbo.topLeft(dx: p, dy: Screen.safeTop, width: uw, height: uw)
		playLimbo.right(dx: -60*s, width: 60*s, height: 60*s)
		resetLimbo.right(dx: -60*s, dy: 60*s, width: 60*s, height: 60*s)
		closeLimbo.bottomRight(dx: -p, dy: -Screen.safeBottom-p, width: 176*s, height: 110*s)
	}
}
