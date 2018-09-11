//
//  CellularExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Loom
import OoviumLib
import UIKit

final class CellularExplorer: Explorer {
	var first = [Limbo]()
	var second = [Limbo]()
	var isFirst: Bool = true

	var engine: CellularEngine
	
	var aetherView: AetherView!
	let largeCell: CellularView = CellularView()
	
	var aetherLimbo = Limbo()
	let controls = Limbo()
	let dilator = Limbo(p: 12)
	let dilatorView = DilatorView()
	var message: MessageLimbo!
	let large = Limbo()
	var medium = Limbo()
	let small = Limbo()
	let close = LimboButton(title: "Close")
	let swapper = Limbo()
	
	let guide = GuideButton()
	let reset = ResetButton()
	let play = PlayButton()
	let ooviumLabel = UILabel()
	
	init(parent: UIView) {
		let s = Aexels.iPad() ?  432 : 335
		engine = CellularEngine(w: s, h: s)
		Hovers.initialize()
		super.init(parent: parent, name: "Cellular Automata", key: "CellularAutomata", canExplore: true)
	}
	
	func open(aether: Aether) {
		play.stop()

		engine.removeAllViews()

		engine.addView(largeCell)

		engine.compile(aether: aether)

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
			self.engine.reset()
		}
		
		if aether.name == "Game of Life" {
			message.key = "GameOfLife"
		} else if aether.name == "Demons" {
			message.key = "Demons"
		} else {
			message.key = "Oovium"
		}
		message.load()
	}
	
// Events ==========================================================================================
	override func onOpen() {
		Aexels.timer.configure(interval: dilatorView.interval, {
			self.engine.tic()
		})
		aetherView.layoutAetherPicker()
	}
	override func onOpening() {
		aetherView.snapAetherPicker()
		aetherView.showToolBars()
	}
	override func onClose() {
		aetherView.dismissAetherPicker()
		aetherView.snuffToolBars()
		self.play.stop()
		if D.current().iPhone {
			limbos = [swapper] + first + [close]
		}
	}
	
// Explorer ========================================================================================
	override func createLimbos() {
		// Cellular Views ==================
		// Large
		large.content = largeCell
		limbos.append(large)
		
		// Medium
		let mediumCell = CellularView()
		mediumCell.zoom = 2
		medium.content = mediumCell
		limbos.append(medium)
		
		// Small
		let smallCell = CellularView()
		smallCell.zoom = 4
		small.content = smallCell
		limbos.append(small)
		
		largeCell.zoomView = mediumCell
		mediumCell.zoomView = smallCell
		
		if D.current().iPhone {
			largeCell.cells = 335
			mediumCell.cells = 190
			smallCell.cells = 112
		} else /*if D.current().iPad*/{
			largeCell.cells = 432
			mediumCell.cells = 256
			smallCell.cells = 144
		}
		
		// Message =========================
		message = MessageLimbo()
		
		// Aether ==========================
		let aether = Local.loadAether(name: "Game of Life")
		open(aether: aether)
		
		var tools: [[Tool?]] = Array(repeating: Array(repeating: nil, count: 2), count: 2)
		tools[0][0] = AetherView.objectTool
		tools[1][0] = AetherView.gateTool
		tools[0][1] = AetherView.mechTool
		
		aetherView = AetherView(aether: engine.aether, toolBox: ToolBox(tools))
		aetherView.toolBarOffset = UIOffset(horizontal: -9, vertical: 9)
		
		aetherView.onSwap = {[weak self](aether: Aether) in
			guard let me = self else {return}
			me.engine.needsCompile = true
			me.open(aether: aether)
		}
		aetherView.onNew = {[weak self](aether: Aether) in
			guard let me = self else {return}
			me.engine.needsCompile = true
			let auto = aether.createAuto(at: V2(0, 0))
			auto.statesChain = Chain("0:2")
		}
		
		aetherLimbo = ContentLimbo(content: aetherView)
		
		aetherLimbo.addSubview(ooviumLabel)
		ooviumLabel.text = "Oovium"
		ooviumLabel.textAlignment = .center
		ooviumLabel.textColor = UIColor.white.withAlphaComponent(0.3)
		ooviumLabel.font = UIFont(name: "Georgia", size: 36)
		
		engine.addView(largeCell)

		// Dilator =========================
		dilatorView.onChange = { (current: Double) in
			self.engine.interval = 1/current
		}
		dilator.content = dilatorView
		limbos.append(dilator)
		
		engine.onMeasure = {(actualSps: Double)->() in
			self.dilatorView.actualSps = CGFloat(actualSps)
		}
		
		// Controls ========================
		limbos.append(controls)
		
		play.onPlay = { [weak self] in
			guard let me = self else {return}
			
			me.engine.start(aether: me.aetherView.aether)
			
//			self?.aetherView.markPositions()
//			let attributes = self?.aetherView.aether.unload()
//			if let attributes = attributes {
//				print(JSON.toJSON(attributes: attributes))
//			}
		}
		play.onStop = { [weak self] in
			guard let me = self else {return}
			me.engine.stop()
		}
		controls.addSubview(play)
		
		controls.addSubview(reset)
		reset.addAction(for: .touchUpInside) { [weak self] in
			guard let me = self else {return}
			me.play.stop()
			me.engine.configureViews()
			me.engine.reset()
		}
		
		controls.addSubview(guide)
		guide.addAction(for: .touchUpInside) { [weak self] in
			guard let me = self else {return}
			me.engine.guideOn = !me.engine.guideOn
			me.guide.stateOn = me.engine.guideOn
			me.guide.setNeedsDisplay()
		}

		// Close ===========================
		close.alpha = 0
		close.addAction(for: .touchUpInside) { [weak self] in
			guard let me = self else {return}
			me.isFirst = true
			me.aetherView.snuffToolBars()
			me.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		limbos.append(close)

		// Swapper =========================
		if D.current().iPhone {
			let swapButton = SwapButton()
			swapButton.addAction(for: .touchUpInside) { [weak self] in
				guard let me = self else {return}
				swapButton.rotateView()
				if me.isFirst {
					me.isFirst = false
					me.dimLimbos(me.first)
					me.brightenLimbos(me.second)
					me.limbos = [me.swapper] + me.second + [me.close]
					me.aetherView.snuffToolBars()
				} else {
					me.isFirst = true
					me.dimLimbos(me.second)
					me.brightenLimbos(me.first)
					me.limbos = [me.swapper] + me.first + [me.close]
					me.aetherView.invokeAetherPicker()
					me.aetherView.showToolBars()
				}
				me.swapper.removeFromSuperview()
				me.parent.addSubview(me.swapper)
				me.close.removeFromSuperview()
				me.parent.addSubview(me.close)
			}
			swapper.content = swapButton
			limbos.append(swapper)

			first = [aetherLimbo, message]
			second = [controls, dilator, large, medium, small]
		}
		
		if D.current().iPhone {
			brightenLimbos(first)
			limbos = [swapper] + first + [close]
		} else {
			limbos.append(aetherLimbo)
			limbos.append(message)
		}
	}
	override func layout375x667() {
		let lw: CGFloat = 375-10
		let mw: CGFloat = 221
		let sw: CGFloat = lw-mw
		let bw: CGFloat = 40

		large.frame = CGRect(x: 5, y: 20, width: lw, height: lw)
		medium.frame = CGRect(x: 5, y: large.bottom, width: mw, height: mw)
		small.frame = CGRect(x: medium.right, y: large.bottom, width: sw, height: sw)
		swapper.frame = CGRect(x: 5, y: medium.bottom, width: 56, height: 56)
		dilator.frame = CGRect(x: swapper.right, y: medium.bottom, width: medium.width-swapper.width, height: swapper.height)
		close.frame = CGRect(x: medium.right, y: medium.bottom, width: small.width, height: swapper.height)

		controls.frame = CGRect(x: medium.right, y: small.bottom, width: small.width, height: medium.height-small.height)
		play.left(offset: UIOffset(horizontal: 15, vertical: 0), size: CGSize(width: bw, height: 30))
		reset.left(offset: UIOffset(horizontal: 15+bw, vertical: 0), size: CGSize(width: bw, height: 30))
		guide.left(offset: UIOffset(horizontal: 15+2*bw, vertical: 0), size: CGSize(width: bw, height: 30))
		
		// AetherLimbo
		aetherLimbo.frame = CGRect(x: 5, y: 20, width: lw, height: lw)
		aetherLimbo.renderPaths()
		aetherLimbo.alpha = 0
		
		aetherView.toolBarOffset = UIOffset(horizontal: -9, vertical: 9)
		aetherView.aetherPickerOffset = UIOffset(horizontal: 7, vertical: 12)

		aetherView.renderToolBars()
		aetherView.placeToolBars()
		aetherView.showToolBars()
		aetherView.stretch()

		ooviumLabel.bottomRight(offset: UIOffset(horizontal: -12, vertical: -14), size: CGSize(width: 144, height: 40))

		// Message
		message.cutouts[Position.bottomRight] = Cutout(width: small.width, height: swapper.height)
		message.cutouts[Position.bottomLeft] = Cutout(width: swapper.height, height: swapper.height)
		message.frame = CGRect(x: 5, y: aetherLimbo.bottom, width: lw, height: Aexels.size.height-aetherLimbo.bottom-5)
	}
	override func layout1024x768() {
		let x: CGFloat = 432
		let y: CGFloat = 400
		let ch: CGFloat = 72
		let bw: CGFloat = 50
		let q: CGFloat = 26

		large.frame = CGRect(x: 1024-462-5, y: 20, width: x+30, height: x+30)
		medium.frame = CGRect(x: 1024-462-5, y: 20+462, width: 286, height: 286)
		small.frame = CGRect(x: 1024-462-5+286, y: 20+462, width: 176, height: 176)
		dilator.frame = CGRect(x: 205, y: 20+y, width: 1024-(x+30)-200-10, height: ch)
		message.frame = CGRect(x: 5, y: 20+y+ch, width: 1024-(x+30)-10, height: 768-20-y-ch)
		close.frame = CGRect(x: medium.right, y: small.bottom, width: small.width, height: medium.height-small.height)

		controls.frame = CGRect(x: 5, y: 20+y, width: 200, height: ch)
		play.left(offset: UIOffset(horizontal: 100-q-bw, vertical: 0), size: CGSize(width: bw, height: 30))
		reset.left(offset: UIOffset(horizontal: 100-bw/2, vertical: 0), size: CGSize(width: bw, height: 30))
		guide.left(offset: UIOffset(horizontal: 100+q, vertical: 0), size: CGSize(width: bw, height: 30))
		
		// Aether
		aetherLimbo.frame = CGRect(x: 5, y: 20, width: 1024-(x+30)-10, height: y)
		aetherLimbo.renderPaths()
		aetherLimbo.alpha = 0

		aetherView.toolBarOffset = UIOffset(horizontal: -9, vertical: 9)
		aetherView.aetherPickerOffset = UIOffset(horizontal: 7, vertical: 12)

		aetherView.renderToolBars()
		aetherView.placeToolBars()
		aetherView.showToolBars()
		aetherView.invokeAetherPicker()
		aetherView.stretch()

		ooviumLabel.bottomRight(offset: UIOffset(horizontal: -12, vertical: -14), size: CGSize(width: 144, height: 40))
	}
}
