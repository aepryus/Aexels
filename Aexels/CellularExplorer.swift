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
	let swapButton = SwapButton()
	
	let guide = GuideButton()
	let reset = ResetButton()
	let play = PlayButton()
	let ooviumLabel = UILabel()
	
	init(parent: UIView) {
		let d = Screen.iPad ?  Int(432*Screen.s) : Int(335*Screen.s)
		engine = CellularEngine(w: d, h: d)
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
		
		let a = largeCell.width/2
		largeCell.zoom(at: CGPoint(x: a, y: a))
	}
	
	private func roundQ(x: CGFloat, to: Int) -> Int {
		return Int(floor(x/CGFloat(to))*CGFloat(to))
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
	override func onOpened() {
		let a = largeCell.width/2
		largeCell.zoom(at: CGPoint(x: a, y: a))
	}
	override func onClose() {
		aetherView.dismissAetherPicker()
		aetherView.snuffToolBars()
		play.stop()
		if Screen.iPhone {
			swapButton.resetView()
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

		if Screen.iPhone {
			largeCell.cells = roundQ(x: 335*s, to: 1)
			mediumCell.cells = roundQ(x: 190*s, to: 2)
			smallCell.cells = roundQ(x: 112*s, to: 4)
		} else /*if Screen.iPad*/{
			largeCell.cells = roundQ(x: 432*s, to: 1)
			mediumCell.cells = roundQ(x: 256*s, to: 2)
			smallCell.cells = roundQ(x: 144*s, to: 4)
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
		Oovium.aetherView = aetherView
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
			if Screen.iPhone {
				aether.xOffset = 230
				aether.yOffset = 250
			} else {
				aether.xOffset = 400
				aether.yOffset = 270
			}
			auto.statesChain = Chain("0:2")
		}
		
		aetherLimbo = ContentLimbo(content: aetherView)
		
		aetherLimbo.addSubview(ooviumLabel)
		ooviumLabel.text = "Oovium"
		ooviumLabel.textAlignment = .center
		ooviumLabel.textColor = UIColor.white.withAlphaComponent(0.3)
		ooviumLabel.font = UIFont(name: "Georgia", size: 36*s)
		
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
			me.engine.needsCompile = true
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
		if Screen.iPhone {
			swapButton.addAction(for: .touchUpInside) { [weak self] in
				guard let me = self else {return}
				me.swapButton.rotateView()
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
		
		if Screen.iPhone {
			brightenLimbos(first)
			limbos = [swapper] + first + [close]
		} else {
			limbos.append(aetherLimbo)
			limbos.append(message)
		}
	}
	override func layout375x667() {
		let lw: CGFloat = 375*s-10*s
		let mw: CGFloat = 221*s
		let sw: CGFloat = lw-mw
		let bw: CGFloat = 40*s

		large.frame = CGRect(x: 5*s, y: 20*s, width: lw, height: lw)
		medium.frame = CGRect(x: 5*s, y: large.bottom, width: mw, height: mw)
		small.frame = CGRect(x: medium.right, y: large.bottom, width: sw, height: sw)
		swapper.frame = CGRect(x: 5*s, y: medium.bottom, width: 56*s, height: 56*s)
		dilator.frame = CGRect(x: swapper.right, y: medium.bottom, width: medium.width-swapper.width, height: swapper.height)
		close.frame = CGRect(x: medium.right, y: medium.bottom, width: small.width, height: swapper.height)

		controls.frame = CGRect(x: medium.right, y: small.bottom, width: small.width, height: medium.height-small.height)
		play.left(offset: UIOffset(horizontal: 15*s, vertical: 0), size: CGSize(width: bw, height: 30*s))
		reset.left(offset: UIOffset(horizontal: 15*s+bw, vertical: 0), size: CGSize(width: bw, height: 30*s))
		guide.left(offset: UIOffset(horizontal: 15*s+2*bw, vertical: 0), size: CGSize(width: bw, height: 30*s))
		
		// AetherLimbo
		aetherLimbo.frame = CGRect(x: 5*s, y: 20*s, width: lw, height: lw)
		aetherLimbo.renderPaths()
		aetherLimbo.alpha = 0
		
		aetherView.toolBarOffset = UIOffset(horizontal: -9, vertical: 9)
		aetherView.aetherPickerOffset = UIOffset(horizontal: 7, vertical: 12)

		aetherView.renderToolBars()
		aetherView.placeToolBars()
		aetherView.showToolBars()
		aetherView.stretch()

		ooviumLabel.bottomRight(offset: UIOffset(horizontal: -12*s, vertical: -14*s), size: CGSize(width: 144*s, height: 40*s))

		// Message
		message.cutouts[Position.bottomRight] = Cutout(width: small.width, height: swapper.height)
		message.cutouts[Position.bottomLeft] = Cutout(width: swapper.height, height: swapper.height)
		message.frame = CGRect(x: 5*s, y: aetherLimbo.bottom, width: lw, height: Screen.height-aetherLimbo.bottom-5*s)
	}
	override func layout1024x768() {
		let x: CGFloat = 432*s
		let y: CGFloat = 400*s
		let ch: CGFloat = 72*s
		let bw: CGFloat = 50*s
		let q: CGFloat = 26*s

		large.frame = CGRect(x: (1024-462-5)*s, y: 20*s, width: x+30*s, height: x+30*s)
		medium.frame = CGRect(x: (1024-462-5)*s, y: 20*s+462*s, width: 286*s, height: 286*s)
		small.frame = CGRect(x: (1024-462-5+286)*s, y: 20*s+462*s, width: 176*s, height: 176*s)
		dilator.frame = CGRect(x: 205*s, y: 20*s+y, width: 1024*s-(x+30*s)-200*s-10*s, height: ch)
		message.frame = CGRect(x: 5*s, y: 20*s+y+ch, width: 1024*s-(x+30*s)-10*s, height: 768*s-20*s-y-ch)
		close.frame = CGRect(x: medium.right, y: small.bottom, width: small.width, height: medium.height-small.height)

		controls.frame = CGRect(x: 5*s, y: 20*s+y, width: 200*s, height: ch)
		play.left(offset: UIOffset(horizontal: 100*s-q-bw, vertical: 0), size: CGSize(width: bw, height: 30*s))
		reset.left(offset: UIOffset(horizontal: 100*s-bw/2, vertical: 0), size: CGSize(width: bw, height: 30*s))
		guide.left(offset: UIOffset(horizontal: 100*s+q, vertical: 0), size: CGSize(width: bw, height: 30*s))
		
		// Aether
		aetherLimbo.frame = CGRect(x: 5*s, y: 20*s, width: 1024*s-(x+30*s)-10*s, height: y)
		aetherLimbo.renderPaths()
		aetherLimbo.alpha = 0

		aetherView.toolBarOffset = UIOffset(horizontal: -9, vertical: 9)
		aetherView.aetherPickerOffset = UIOffset(horizontal: 7, vertical: 12)

		aetherView.renderToolBars()
		aetherView.placeToolBars()
		aetherView.showToolBars()
		aetherView.invokeAetherPicker()
		aetherView.stretch()

		ooviumLabel.bottomRight(offset: UIOffset(horizontal: -12*s, vertical: -14*s), size: CGSize(width: 144*s, height: 40*s))
	}
}
