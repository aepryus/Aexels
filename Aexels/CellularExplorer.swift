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
	var first = [Limbo]()
	var second = [Limbo]()
	var isFirst: Bool = true

	var engine: CellularEngine
	
	var aetherView: AetherView!
	
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
	func iPadLimbos() -> [Limbo] {
		var limbos = [Limbo]()
		
		let x: CGFloat = 432
		let y: CGFloat = 400
		let ch: CGFloat = 72
		
		let aether = Limbo()
		aether.frame = CGRect(x: 5, y: 20, width: 1024-(x+30)-10, height: y)
		limbos.append(aether)
		
		let dilator = Limbo()
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
		
		let message = MessageLimbo(frame: CGRect(x: 5, y: 20+y+ch, width: 1024-(x+30)-10, height: 768-20-y-ch))
		message.load(key: "GameOfLife")
		limbos.append(message)
		
		let large = Limbo()
		large.frame = CGRect(x: 1024-462-5, y: 20, width: x+30, height: x+30)
		let largeCell = CellularView(frame: CGRect(x: 15, y: 15, width: 432, height: 432))
		engine.addView(largeCell)
		large.content = largeCell
		limbos.append(large)
		
		let medium = Limbo()
		medium.frame = CGRect(x: 1024-462-5, y: 20+462, width: 286, height: 286)
		let mediumCell = CellularView(frame: CGRect(x: 15, y: 15, width: 256, height: 256))
		mediumCell.zoom = 2
		engine.addView(mediumCell)
		medium.content = mediumCell
		limbos.append(medium)
		
		let small = Limbo()
		small.frame = CGRect(x: 1024-462-5+286, y: 20+462, width: 176, height: 176)
		let smallCell = CellularView(frame: CGRect(x: 16, y: 16, width: 144, height: 144))
		smallCell.zoom = 4
		engine.addView(smallCell)
		small.content = smallCell
		limbos.append(small)
		
		largeCell.zoomView = mediumCell
		mediumCell.zoomView = smallCell
		
		// Controls ========================
		let controls = Limbo()
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
		controls.addSubview(play)
		play.left(offset: UIOffset(horizontal: 100-q-bw, vertical: 0), size: CGSize(width: bw, height: 30))
		
		let reset = ResetButton()
		controls.addSubview(reset)
		reset.add(for: .touchUpInside) { 
			play.stop()
			self.engine.reset()
		}
		reset.left(offset: UIOffset(horizontal: 100-bw/2, vertical: 0), size: CGSize(width: bw, height: 30))

		let guide = GuideButton()
		controls.addSubview(guide)
		guide.add(for: .touchUpInside) { 
			self.engine.guideOn = !self.engine.guideOn
			guide.stateOn = self.engine.guideOn
			guide.setNeedsDisplay()
		}
		guide.left(offset: UIOffset(horizontal: 100+q, vertical: 0), size: CGSize(width: bw, height: 30))

		// Close
		let size = CGSize(width: 144, height: 78)
		let close = Limbo()
		close.frame = CGRect(x: 1024-5-size.width, y: 768-size.height, width: size.width, height: size.height)
		close.alpha = 0
		let button = AXButton()
		button.setTitle("Close", for: .normal)
		button.add(for: .touchUpInside) {
			self.aetherView.snuffToolBars()
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		close.content = button
		
		return limbos
	}
	func iPhoneLimbos() -> [Limbo] {
		var limbos = [Limbo]()

		let lw: CGFloat = 375-10
		let mw: CGFloat = 221
		let sw: CGFloat = lw-mw
		
		// Large
		let large = Limbo()
		large.frame = CGRect(x: 5, y: 20, width: lw, height: lw)
		let largeCell = CellularView(frame: CGRect(x: 15, y: 15, width: lw-30, height: lw-30))
		engine.addView(largeCell)
		large.content = largeCell
		limbos.append(large)
		
		// Medium
		let medium = Limbo()
		medium.frame = CGRect(x: 5, y: large.bottom, width: mw, height: mw)
		let mediumCell = CellularView(frame: CGRect(x: 15, y: 15, width: 190, height: 190))
		mediumCell.zoom = 2
		medium.content = mediumCell
		limbos.append(medium)
		
		// Small
		let small = Limbo()
		small.frame = CGRect(x: medium.right, y: large.bottom, width: sw, height: sw)
		let smallCell = CellularView(frame: CGRect(x: 16, y: 16, width: 112, height: 112))
		smallCell.zoom = 4
		small.content = smallCell
		limbos.append(small)
		
		largeCell.zoomView = mediumCell
		mediumCell.zoomView = smallCell
		
		// Swapper =========================
		let swapper = Limbo()
		swapper.frame = CGRect(x: 5, y: medium.bottom, width: 56, height: 56)
		let swapButton = SwapButton()
		//		button.backgroundColor = UIColor.red.withAlphaComponent(0.5)
		swapButton.add(for: .touchUpInside) {
			swapButton.rotateView()
			if self.isFirst {
				self.isFirst = false
				self.dimLimbos(self.first)
				self.brightenLimbos(self.second)
				self.limbos = [swapper] + self.second
				self.aetherView.showToolBars()
			} else {
				self.isFirst = true
				self.dimLimbos(self.second)
				self.brightenLimbos(self.first)
				self.limbos = [swapper] + self.first
				self.aetherView.snuffToolBars()
			}
			swapper.removeFromSuperview()
			self.view.addSubview(swapper)
		}
		swapper.content = swapButton
		limbos.append(swapper)
		
		// Controls ========================
		let bw: CGFloat = 40
		let controls = Limbo()
		controls.frame = CGRect(x: medium.right, y: small.bottom, width: small.width, height: medium.height-small.height)
		limbos.append(controls)
		
		let play = PlayButton()
		play.onPlay = {
			self.engine.start()
		}
		play.onStop = {
			self.engine.stop()
		}
		controls.addSubview(play)
		play.left(offset: UIOffset(horizontal: 15, vertical: 0), size: CGSize(width: bw, height: 30))

		let reset = ResetButton()
		controls.addSubview(reset)
		reset.left(offset: UIOffset(horizontal: 15+bw, vertical: 0), size: CGSize(width: bw, height: 30))
		reset.add(for: .touchUpInside) {
			play.stop()
			self.engine.reset()
		}
		
		let guide = GuideButton()
		controls.addSubview(guide)
		guide.left(offset: UIOffset(horizontal: 15+2*bw, vertical: 0), size: CGSize(width: bw, height: 30))
		guide.add(for: .touchUpInside) {
			self.engine.guideOn = !self.engine.guideOn
			guide.stateOn = self.engine.guideOn
			guide.setNeedsDisplay()
		}
		
		// Dilator =========================
		let dilator = Limbo(p: 12)
		dilator.frame = CGRect(x: swapper.right, y: medium.bottom, width: medium.width-swapper.width, height: swapper.height)
		let dilatorView = DilatorView()
		dilatorView.onChange = { (current: Double) in
			self.engine.interval = 1/current
		}
		dilator.content = dilatorView
		limbos.append(dilator)

		engine.onMeasure = {(actualSps: Double)->() in
			dilatorView.actualSps = CGFloat(actualSps)
		}

		// Close
		let close1 = Limbo()
		close1.frame = CGRect(x: medium.right, y: medium.bottom, width: small.width, height: swapper.height)
		close1.alpha = 0
		let button1 = AXButton()
		button1.setTitle("Close", for: .normal)
		button1.add(for: .touchUpInside) {
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		close1.content = button1
		limbos.append(close1)

		// Aether
		var tools: [[Tool?]] = Array(repeating: Array(repeating: nil, count: 2), count: 2)
		tools[0][0] = AetherView.objectTool
		tools[1][0] = AetherView.gateTool
		tools[0][1] = AetherView.mechTool
		
		aetherView = AetherView(aether: engine.aether, toolBox: ToolBox(tools))
		aetherView.toolBarPadding = UIOffset(horizontal: -9, vertical: 9)

		let aether = ContentLimbo(frame: CGRect(x: 5, y: 20, width: lw, height: lw), content: aetherView)
		aether.frame = CGRect(x: 5, y: 20, width: lw, height: lw)
		aether.renderPaths()
		aether.alpha = 0
		
		let label = UILabel(frame: CGRect(x: 209, y: 311, width: 144, height: 40))
		label.text = "Oovium"
		label.textAlignment = .center
		label.textColor = UIColor.white.withAlphaComponent(0.3)
		label.font = UIFont(name: "Georgia", size: 36)
		aether.addSubview(label)
		
		aetherView.renderToolBars()
		aetherView.placeToolBars()
		aetherView.stretch()
		
		// Message
		let message = MessageLimbo(frame: CGRect(x: 5, y: aether.bottom, width: lw, height: Aexels.size.height-aether.bottom-5))
		message.cutouts[Position.bottomRight] = Cutout(width: small.width, height: swapper.height)
		message.cutouts[Position.bottomLeft] = Cutout(width: swapper.height, height: swapper.height)
		message.load(key: "GameOfLife")
		message.renderPaths()
		message.alpha = 0
		
		// Close
		let close2 = Limbo()
		close2.frame = CGRect(x: medium.right, y: medium.bottom, width: small.width, height: swapper.height)
		close2.alpha = 0
		let button2 = AXButton()
		button2.setTitle("Close", for: .normal)
		button2.add(for: .touchUpInside) {
			self.isFirst = true
			self.aetherView.snuffToolBars()
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		close2.content = button2
		close2.alpha = 0
		
		first = [controls, dilator, large, medium, small, close1]
		second = [aether, message, close2]
		
		return limbos
	}
	
	override func createLimbos() -> [Limbo] {
		if Aexels.iPad() {
			return iPadLimbos()
		} else {
			return iPhoneLimbos()
		}
	}
}
