//
//  CellularExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import OoviumLib
import UIKit

final class CellularExplorer: Explorer {
	var first = [LimboView]()
	var second = [LimboView]()
	var isFirst: Bool = true

	var engine: CellularEngine
	
	init (view: UIView) {
		let s = Aexels.iPad() ?  432 : 335
		engine = CellularEngine(aetherName: "Game of Life", w: s, h: s)!
		super.init(view: view, name: "Cellular Automata", key: "CellularAutomata", canExplore: true)
	}
	
// Events ==========================================================================================
	override func onClose() {
		self.engine.stop()
	}
	
// Explorer ========================================================================================
	func iPadLimbos() -> [LimboView] {
		var limbos = [LimboView]()
		
		let x: CGFloat = 432
		let y: CGFloat = 400
		let ch: CGFloat = 72
		
		let aether = LimboView()
		aether.frame = CGRect(x: 5, y: 20, width: 1024-(x+30)-10, height: y)
		limbos.append(aether)
		
		let dilator = LimboView()
		dilator.frame = CGRect(x: 205, y: 20+y, width: 1024-(x+30)-200-10, height: ch)
		let dilatorView = DilatorView()
		dilatorView.onChange = { (current: Double) in
			self.engine.interval = 1/current
		}
		dilator.content = dilatorView
		limbos.append(dilator)
		
		engine.onMeasure = {(actualSps: Double)->() in
			dilatorView.actualSps = CGFloat(actualSps)
		}
		
		let message = MessageView(frame: CGRect(x: 5, y: 20+y+ch, width: 1024-(x+30)-10, height: 768-20-y-ch))
		message.load(key: "GameOfLife")
		limbos.append(message)
		
		let large = LimboView()
		large.frame = CGRect(x: 1024-462-5, y: 20, width: x+30, height: x+30)
		let largeCell = CellularView(frame: CGRect(x: 15, y: 15, width: 432, height: 432))
		engine.addView(largeCell)
		large.content = largeCell
		limbos.append(large)
		
		let medium = LimboView()
		medium.frame = CGRect(x: 1024-462-5, y: 20+462, width: 286, height: 286)
		let mediumCell = CellularView(frame: CGRect(x: 15, y: 15, width: 256, height: 256))
		mediumCell.zoom = 2
		engine.addView(mediumCell)
		medium.content = mediumCell
		limbos.append(medium)
		
		let small = LimboView()
		small.frame = CGRect(x: 1024-462-5+286, y: 20+462, width: 176, height: 176)
		let smallCell = CellularView(frame: CGRect(x: 16, y: 16, width: 144, height: 144))
		smallCell.zoom = 4
		engine.addView(smallCell)
		small.content = smallCell
		limbos.append(small)
		
		largeCell.zoomView = mediumCell
		mediumCell.zoomView = smallCell
		
		// Controls ========================
		let controls = LimboView()
		controls.frame = CGRect(x: 5, y: 20+y, width: 200, height: ch)
		limbos.append(controls)
		
		let bw: CGFloat = 50
		let q: CGFloat = 26
		
		let play = PlayButton()
		play.onPlay = {
			self.engine.start()
		}
		play.onStop = {
			self.engine.stop()
		}
		play.frame = CGRect(x: 100-q-bw, y: 21, width: bw, height: 30)
		controls.addSubview(play)
		
		let reset = ResetButton()
		reset.frame = CGRect(x: 100-bw/2, y: 21, width: bw, height: 30)
		controls.addSubview(reset)
		reset.add(for: .touchUpInside) { 
			play.stop()
			self.engine.reset()
		}
		
		let guide = GuideButton()
		guide.frame = CGRect(x: 100+q, y: 21, width: bw, height: 30)
		controls.addSubview(guide)
		guide.add(for: .touchUpInside) { 
			self.engine.guideOn = !self.engine.guideOn
			guide.stateOn = self.engine.guideOn
			guide.setNeedsDisplay()
		}
		
		// Close
		let size = CGSize(width: 144, height: 78)
		let close = LimboView()
		close.frame = CGRect(x: 1024-5-size.width, y: 768-size.height, width: size.width, height: size.height)
		close.alpha = 0
		let button = UIButton(type: .custom)
		button.setTitle("Close", for: .normal)
		button.titleLabel!.font = UIFont.aexelFont(size: 24)
		button.add(for: .touchUpInside) {
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		close.content = button
		
		return limbos
	}
	func iPhoneLimbos() -> [LimboView] {
		var limbos = [LimboView]()

		let lw: CGFloat = 375-10
		let mw: CGFloat = 221
		let sw: CGFloat = lw-mw
		
		// Controls ========================
		let bw: CGFloat = 40
		let controls = LimboView()
		controls.frame = CGRect(x: 5, y: 20, width: bw*3+30, height: 56)
		limbos.append(controls)
		
		let play = PlayButton()
		play.onPlay = {
			self.engine.start()
		}
		play.onStop = {
			self.engine.stop()
		}
		play.frame = CGRect(x: 15, y: 15, width: bw, height: 30)
		controls.addSubview(play)
		
		let reset = ResetButton()
		reset.frame = CGRect(x: 15+bw, y: 15, width: bw, height: 30)
		controls.addSubview(reset)
		reset.add(for: .touchUpInside) { 
			play.stop()
			self.engine.reset()
		}
		
		let guide = GuideButton()
		guide.frame = CGRect(x: 15+2*bw, y: 15, width: bw, height: 30)
		controls.addSubview(guide)
		guide.add(for: .touchUpInside) { 
			self.engine.guideOn = !self.engine.guideOn
			guide.stateOn = self.engine.guideOn
			guide.setNeedsDisplay()
		}
		
		// Dilator =========================
		let dilator = LimboView(p: 12)
		dilator.frame = CGRect(x: controls.right, y: 20, width: lw-controls.width-controls.height, height: controls.height)
		let dilatorView = DilatorView()
		dilatorView.onChange = { (current: Double) in
			self.engine.interval = 1/current
		}
		dilator.content = dilatorView
		limbos.append(dilator)

		engine.onMeasure = {(actualSps: Double)->() in
			dilatorView.actualSps = CGFloat(actualSps)
		}

		// Swapper =========================
		let swapper = LimboView()
		swapper.frame = CGRect(x: dilator.right, y: 20, width: controls.height, height: controls.height)
		let swapButton = SwapButton()
//		button.backgroundColor = UIColor.red.withAlphaComponent(0.5)
		swapButton.add(for: .touchUpInside) {
			swapButton.rotateView()
			if self.isFirst {
				self.isFirst = false
				self.dimLimbos(self.first)
				self.brightenLimbos(self.second)
				self.limboViews = [swapper] + self.second
			} else {
				self.isFirst = true
				self.dimLimbos(self.second)
				self.brightenLimbos(self.first)
				self.limboViews = [swapper] + self.first
			}
			swapper.removeFromSuperview()
			self.view.addSubview(swapper)
		}
		swapper.content = swapButton
		limbos.append(swapper)
		
		// Large
		let large = LimboView()
		large.frame = CGRect(x: 5, y: controls.bottom, width: lw, height: lw)
		let largeCell = CellularView(frame: CGRect(x: 15, y: 15, width: lw-30, height: lw-30))
		engine.addView(largeCell)
		large.content = largeCell
		limbos.append(large)
		
		// Medium
		let medium = LimboView()
		medium.frame = CGRect(x: 5, y: large.bottom, width: mw, height: mw)
		let mediumCell = CellularView(frame: CGRect(x: 15, y: 15, width: 190, height: 190))
		mediumCell.zoom = 2
		engine.addView(mediumCell)
		medium.content = mediumCell
		limbos.append(medium)
		
		// Small
		let small = LimboView()
		small.frame = CGRect(x: medium.right, y: large.bottom, width: sw, height: sw)
		let smallCell = CellularView(frame: CGRect(x: 16, y: 16, width: 112, height: 112))
		smallCell.zoom = 4
		engine.addView(smallCell)
		small.content = smallCell
		limbos.append(small)
		
		largeCell.zoomView = mediumCell
		mediumCell.zoomView = smallCell

		// Close
		let size = CGSize(width: 144, height: 78)
		let close1 = LimboView()
		close1.frame = CGRect(x: 375-5-size.width, y: 667-5-size.height, width: size.width, height: size.height)
		close1.alpha = 0
		let button1 = UIButton(type: .custom)
		button1.setTitle("Close", for: .normal)
		button1.titleLabel!.font = UIFont.aexelFont(size: 24)
		button1.add(for: .touchUpInside) {
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		close1.content = button1
		limbos.append(close1)

		// Aether
		let aether = LimboView()
		aether.cutouts[Position.topRight] = Cutout(width: controls.height, height: controls.height)
		aether.frame = CGRect(x: 5, y: 20, width: lw, height: lw)
		aether.renderPaths()
		
		let label = UILabel(frame: CGRect(x: 209, y: 311, width: 144, height: 40))
		label.text = "Oovium"
		label.textAlignment = .center
		label.textColor = UIColor.white.withAlphaComponent(0.3)
		label.font = UIFont(name: "Georgia", size: 36)
		aether.addSubview(label)

		let aetherView = AetherView(aether: engine.aether)
		aether.content = aetherView

		// Message
		let message = MessageView(frame: CGRect(x: 5, y: aether.bottom, width: lw, height: Aexels.size.height-aether.bottom-5))
		message.cutouts[Position.bottomRight] = Cutout(width: 139, height: 60)
		message.load(key: "GameOfLife")
		message.renderPaths()
		
		// Close
		let size2 = CGSize(width: 139, height: 60)
		let close2 = LimboView()
		close2.frame = CGRect(x: 375-5-size2.width, y: 667-5-size2.height, width: size2.width, height: size2.height)
		close2.alpha = 0
		let button2 = UIButton(type: .custom)
		button2.setTitle("Close", for: .normal)
		button2.titleLabel!.font = UIFont.aexelFont(size: 24)
		button2.add(for: .touchUpInside) {
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		close2.content = button2
		
		first = [controls, dilator, large, medium, small, close1]
		second = [aether, message, close2]
		
		return limbos
	}
	
	override func createLimbos() -> [LimboView] {
		if Aexels.iPad() {
			return iPadLimbos()
		} else {
			return iPhoneLimbos()
		}
	}
}
