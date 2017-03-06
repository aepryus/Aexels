//
//  CellularExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

final class CellularExplorer: Explorer {

	var engine: CellularEngine
	
	init () {
		let s = Aexels.iPad() ?  432 : 335
		engine = CellularEngine(aetherName: "Game of Life", w: s, h: s)!
		super.init(name: "Cellular Automata", key: "CellularAutomata", canExplore: true)
	}
	
// Events ==========================================================================================
	override func onClose () {
		self.engine.stop()
	}
	
// Explorer ========================================================================================
	func iPadLimbos () -> [LimboView] {
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
		
		let play = PlayButton(onPlay: {
			self.engine.start()
		}) {
			self.engine.stop()
		}
		play.frame = CGRect(x: 100-q-bw, y: 21, width: bw, height: 30)
		controls.addSubview(play)
		
		let reset = ResetButton()
		reset.frame = CGRect(x: 100-bw/2, y: 21, width: bw, height: 30)
		controls.addSubview(reset)
		reset.addClosure({
			play.stop()
			self.engine.reset()
		}, controlEvents: .touchUpInside)
		
		let guide = GuideButton()
		guide.frame = CGRect(x: 100+q, y: 21, width: bw, height: 30)
		controls.addSubview(guide)
		guide.addClosure({
			self.engine.guideOn = !self.engine.guideOn
			guide.stateOn = self.engine.guideOn
			guide.setNeedsDisplay()
		}, controlEvents: .touchUpInside)
		
		return limbos
	}
	func iPhoneLimbos () -> [LimboView] {
		var limbos = [LimboView]()
		
		let w = 375-10
		
		// CellularViews
		let large = LimboView()
		large.frame = CGRect(x: 5, y: 20, width: w, height: w)
		let largeCell = CellularView(frame: CGRect(x: 15, y: 15, width: w-30, height: w-30))
		engine.addView(largeCell)
		large.content = largeCell
		limbos.append(large)

		// Controls ========================
		let controls = LimboView()
		controls.frame = CGRect(x: 5, y: 20+w, width: 150, height: 60)
		limbos.append(controls)
		
		let bw: CGFloat = 50
		let q: CGFloat = 26
		
		let play = PlayButton(onPlay: {
			self.engine.start()
		}) {
			self.engine.stop()
		}
		play.frame = CGRect(x: 100-q-bw, y: 15, width: bw, height: 30)
		controls.addSubview(play)
		
		let reset = ResetButton()
		reset.frame = CGRect(x: 100-bw/2, y: 15, width: bw, height: 30)
		controls.addSubview(reset)
		reset.addClosure({
			play.stop()
			self.engine.reset()
		}, controlEvents: .touchUpInside)
		
		// Dilator =========================
		let dilator = LimboView()
		dilator.frame = CGRect(x: 155, y: 20+w, width: 375-150-10, height: 60)
		let dilatorView = DilatorView()
		dilatorView.onChange = { (current: Double) in
			self.engine.interval = 1/current
		}
		dilator.content = dilatorView
		limbos.append(dilator)
		
		// Message
		let message = MessageView(frame: CGRect(x: 5, y: 20+w+60, width: 375-10, height: 667-20-365-60-60-5))
		message.load(key: "GameOfLife")
		limbos.append(message)
		
		return limbos
	}
	
	override func createLimbos () -> [LimboView] {
		if Aexels.iPad() {
			return iPadLimbos()
		} else {
			return iPhoneLimbos()
		}
	}
}
