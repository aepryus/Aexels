//
//  CellularExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

final class CellularExplorer: Explorer {
	var aether = LimboView()
	var controls = LimboView()
	var dilator = LimboView()
	var message = MessageView()
	var large = LimboView()
	var medium = LimboView()
	var small = LimboView()
	
	var engine = CellularEngine(aetherName: "Game of Life", w: 432, h: 432)!
	
	init () {
		super.init(name: "Cellular Automata", key: "CellularAutomata", canExplore: true)
	}
	
	// Explorer ========================================================================================
	override func loadView (_ view: UIView) {
		
		let x: CGFloat = 432
		let y: CGFloat = 400
		let ch: CGFloat = 72

		aether.frame = CGRect(x: 5, y: 20, width: 1024-(x+30)-10, height: y)
		limboViews.append(aether)
		
		controls.frame = CGRect(x: 5, y: 20+y, width: 200, height: ch)
		limboViews.append(controls)
		
		dilator.frame = CGRect(x: 205, y: 20+y, width: 1024-(x+30)-200-10, height: ch)
		limboViews.append(dilator)
		
		message.frame = CGRect(x: 5, y: 20+y+ch, width: 1024-(x+30)-10, height: 768-20-y-ch)
		message.load(key: "GameOfLife")
		limboViews.append(message)
		
		large.frame = CGRect(x: 1024-462-5, y: 20, width: x+30, height: x+30)
		let largeCell = CellularView(frame: CGRect(x: 15, y: 15, width: 432, height: 432))
		engine.addView(largeCell)
		large.content = largeCell
		limboViews.append(large)
		
		medium.frame = CGRect(x: 1024-462-5, y: 20+462, width: 286, height: 286)
		let mediumCell = CellularView(frame: CGRect(x: 15, y: 15, width: 256, height: 256))
		mediumCell.zoom = 2
		engine.addView(mediumCell)
		medium.content = mediumCell
		limboViews.append(medium)
		
		small.frame = CGRect(x: 1024-462-5+286, y: 20+462, width: 176, height: 176)
		let smallCell = CellularView(frame: CGRect(x: 16, y: 16, width: 144, height: 144))
		smallCell.zoom = 4
		engine.addView(smallCell)
		small.content = smallCell
		limboViews.append(small)
		
		largeCell.zoomView = mediumCell
		mediumCell.zoomView = smallCell
		
		// Controls ========================
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
		
		super.loadView(view)
	}
}
