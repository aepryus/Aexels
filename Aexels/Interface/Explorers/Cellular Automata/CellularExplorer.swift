//
//  CellularExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import OoviumKit
import UIKit

final class CellularExplorer: Explorer, AetherViewDelegate {
	var first = [Limbo]()
	var second = [Limbo]()
	var isFirst: Bool = true

	var engine: CellularEngine
	
	var aetherView: AetherView!
	let largeCell: CellularView = CellularView()
	let mediumCell: CellularView = CellularView()
	let smallCell: CellularView = CellularView()
	
	var aetherLimbo: ContentLimbo!
	let controls = Limbo()
	let dilator = Limbo(p: 12)
	let dilatorView = DilatorView()
	var message: MessageLimbo!
	let large = Limbo()
	var medium = Limbo()
	let small = Limbo()
	let empty = Limbo()
	let close = LimboButton(title: "Close")
	let swapper = Limbo()
	let swapButton = SwapButton()
	
	let guide = GuideButton()
	let reset = ResetButton()
	let play = PlayButton()
	let ooviumLabel = UILabel()
	
	init(parent: UIView) {
		let height = Screen.height - Screen.safeTop - Screen.safeBottom
		let s = height / 748
		let d: Int
		if Screen.iPhone { d = Int(335*Screen.s) }
		else if Screen.iPad { d = Int(432*s) }
		else /*if Screen.mac*/ { d = Int(Screen.scaler == 1 ? 465 : 609) }
		engine = CellularEngine(side: d)
		super.init(parent: parent, name: "Cellular Automata", key: "CellularAutomata", canExplore: true)
	}
	
	func open(aether: Aether) {
		play.stop()

		engine.removeAllViews()

		engine.addView(largeCell)
		engine.addView(mediumCell)
		engine.addView(smallCell)

		engine.compile(aether: aether)

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
			self.engine.reset()
			let a = self.largeCell.width/2
			self.largeCell.zoom(at: CGPoint(x: a, y: a))
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
	
	private func floorQ(x: CGFloat, to: Int) -> Int {
		return Int(floor(x/CGFloat(to))*CGFloat(to))
	}
	
// Events ==========================================================================================
	override func onOpen() {
		Aexels.sync.link.preferredFramesPerSecond = dilatorView.frameRate
		engine.defineOnFire()
		aetherView.layoutAetherPicker()
	}
	override func onOpening() {
		aetherView.snapAetherPicker()
		aetherView.showToolBars()
	}
	override func onOpened() {}
	override func onClose() {
		aetherView.dismissAetherPicker()
		aetherView.snuffToolBars()
		play.stop()
		if Screen.iPhone {
			swapButton.resetView()
			limbos = [swapper] + first + [close]
		}
	}
	
// AetherViewDelegate ==============================================================================
	func onNew(aetherView: AetherView, aether: Aether) {
		self.engine.needsCompile = true
		let auto = aether.createAuto(at: V2(0, 0))
		aether.xOffset = Double(self.aetherView.width) - 130
		aether.yOffset = Double(self.aetherView.height) - 100
		auto.statesChain.replaceWith(tokens: "0:2")
		aether.prepare()
		aether.evaluate()
	}
	func onClose(aetherView: AetherView, aether: Aether) {}
	func onOpen(aetherView: AetherView, aether: Aether) {
		self.engine.needsCompile = true
		self.open(aether: aether)
	}
	func onSave(aetherView: AetherView, aether: Aether) {}

// Explorer ========================================================================================
	override func createLimbos() {
		// Cellular Views ==================
		// Large
		limbos.append(large)
		
		// Medium
		mediumCell.zoom = 2
		limbos.append(medium)
		
		// Small
		smallCell.zoom = 4
		limbos.append(small)
		
		largeCell.zoomView = mediumCell
		mediumCell.parentView = largeCell
		mediumCell.zoomView = smallCell
		smallCell.parentView = mediumCell

		if Screen.iPhone {
			largeCell.points = floorQ(x: 335*s, to: 1)
			mediumCell.points = floorQ(x: 190*s, to: 2)
			smallCell.points = floorQ(x: 112*s, to: 4)
		} else /*if Screen.iPad*/{
			let height = Screen.height - Screen.safeTop - Screen.safeBottom
			let s = height / 748
			largeCell.points = floorQ(x: 432*s, to: 1)
			mediumCell.points = floorQ(x: 256*s, to: 2)
			smallCell.points = floorQ(x: 144*s, to: 4)
		}
		
		var length: CGFloat = CGFloat(largeCell.points); large.set(content: largeCell, size: CGSize(width: length, height: length))
		length = CGFloat(mediumCell.points); medium.set(content: mediumCell, size: CGSize(width: length, height: length))
		length = CGFloat(smallCell.points); small.set(content: smallCell, size: CGSize(width: length, height: length))

		// Message =========================
		message = MessageLimbo()
		
		// Aether ==========================
		Space.local.loadAether(name: "Game of Life") { (json: String?) in
			guard let json = json else { return }
			self.open(aether: Aether(json: json))
		}

		var tools: [[Tool?]] = Array(repeating: Array(repeating: nil, count: 2), count: 2)
		tools[0][0] = AetherView.objectTool
		tools[1][0] = AetherView.gateTool
		tools[0][1] = AetherView.mechTool
		
		aetherView = AetherView(aether: engine.aether, toolBox: ToolBox(tools), toolsOn: false, oldPicker: true)
		aetherView.aetherViewDelegate = self
		Aexels.aetherView = aetherView
//		aetherView.toolBarOffset = UIOffset(horizontal: -9, vertical: 9)

		aetherLimbo = ContentLimbo(content: aetherView)
		
		ooviumLabel.text = "Oovium"
		ooviumLabel.textAlignment = .center
		ooviumLabel.textColor = UIColor.white.withAlphaComponent(0.3)
		ooviumLabel.font = UIFont(name: "Georgia", size: 36*s)
		aetherLimbo.addSubview(ooviumLabel)
		aetherLimbo.bringContentToFront()

		// Dilator =========================
		dilatorView.onChange = { (frameRate: Int) in
			self.engine.frameRate = frameRate
		}
		dilator.content = dilatorView
		limbos.append(dilator)
		
		engine.onMeasure = {(actualSps: Double)->() in
			print("actual frame rate: \(actualSps)")
		}
		
		// Controls ========================
		limbos.append(controls)
		
		play.onPlay = { [unowned self] in
			self.engine.start(aether: self.aetherView.aether)
			
//			self.aetherView.markPositions()
//			print(self.aetherView.aether.unload().toJSON())
		}
		play.onStop = { [unowned self] in
			self.engine.stop()
		}
		controls.addSubview(play)
		
		controls.addSubview(reset)
		reset.addAction(for: .touchUpInside) { [unowned self] in
			self.play.stop()
			self.engine.configureViews()
			self.engine.reset()
			self.engine.needsCompile = true
		}
		
		controls.addSubview(guide)
		guide.addAction(for: .touchUpInside) { [unowned self] in
			self.engine.guideOn = !self.engine.guideOn
			self.guide.stateOn = self.engine.guideOn
			self.guide.setNeedsDisplay()
			self.largeCell.flash()
			self.mediumCell.flash()
		}

		// Close ===========================
		close.alpha = 0
		close.addAction(for: .touchUpInside) { [unowned self] in
			self.isFirst = true
			self.aetherView.snuffToolBars()
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		limbos.append(close)

		// Swapper =========================
		if Screen.iPhone {
			swapButton.addAction(for: .touchUpInside) { [unowned self] in
				self.swapButton.rotateView()
				if self.isFirst {
					self.isFirst = false
					self.dimLimbos(self.first)
					self.brightenLimbos(self.second)
					self.limbos = [self.swapper] + self.second + [self.close]
					self.aetherView.snuffToolBars()
				} else {
					self.isFirst = true
					self.dimLimbos(self.second)
					self.brightenLimbos(self.first)
					self.limbos = [self.swapper] + self.first + [self.close]
					self.aetherView.invokeAetherPicker()
					self.aetherView.showToolBars()
				}
				self.swapper.removeFromSuperview()
				self.parent.addSubview(self.swapper)
				self.close.removeFromSuperview()
				self.parent.addSubview(self.close)
			}
			swapper.content = swapButton
			limbos.append(swapper)

			first = [aetherLimbo, message]
			if Screen.dimensions == .dim375x812 || Screen.dimensions == .dim414x896 {
				second = [empty, controls, dilator, large, medium, small]
			} else {
				second = [controls, dilator, large, medium, small]
			}
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
		play.left(dx: 15*s, size: CGSize(width: bw, height: 30*s))
		reset.left(dx: 15*s+bw, size: CGSize(width: bw, height: 30*s))
		guide.left(dx: 15*s+2*bw, size: CGSize(width: bw, height: 30*s))
		
		// AetherLimbo
		aetherLimbo.frame = CGRect(x: 5*s, y: 20*s, width: lw, height: lw)
		aetherLimbo.renderPaths()
		aetherLimbo.alpha = 0
		
		aetherView.toolBarOffset = UIOffset(horizontal: -9, vertical: 9)
		aetherView.aetherPickerOffset = UIOffset(horizontal: -10, vertical: -4)

		aetherView.renderToolBars()
		aetherView.placeToolBars()
		aetherView.showToolBars()
		aetherView.stretch()

		ooviumLabel.bottomRight(dx: -12*s, dy: -14*s, size: CGSize(width: 144*s, height: 40*s))

		// Message
		message.cutouts[Position.bottomRight] = Cutout(width: small.width, height: swapper.height)
		message.cutouts[Position.bottomLeft] = Cutout(width: swapper.height, height: swapper.height)
		message.frame = CGRect(x: 5*s, y: aetherLimbo.bottom, width: lw, height: Screen.height-aetherLimbo.bottom-5*s)
	}
	override func layout375x812() {
		let lw: CGFloat = Screen.width-10*s
		let mw: CGFloat = 221*s
		let sw: CGFloat = lw-mw
		let bw: CGFloat = 40*s
		let sh: CGFloat = 56*s
		
		large.frame = CGRect(x: 5*s, y: Screen.safeTop, width: lw, height: lw)
		medium.frame = CGRect(x: 5*s, y: large.bottom, width: mw, height: mw)
		small.frame = CGRect(x: medium.right, y: large.bottom, width: sw, height: sw)
		
		controls.frame = CGRect(x: medium.right, y: small.bottom, width: small.width, height: medium.height-small.height)
		play.left(dx: 15*s, size: CGSize(width: bw, height: 30*s))
		reset.left(dx: 15*s+bw, size: CGSize(width: bw, height: 30*s))
		guide.left(dx: 15*s+2*bw, size: CGSize(width: bw, height: 30*s))
		
		// AetherLimbo
		aetherLimbo.frame = CGRect(x: 5*s, y: Screen.safeTop, width: lw, height: lw)
		aetherLimbo.renderPaths()
		aetherLimbo.alpha = 0
		
		aetherView.toolBarOffset = UIOffset(horizontal: -9, vertical: 9)
		aetherView.aetherPickerOffset = UIOffset(horizontal: -10, vertical: -4)

		aetherView.renderToolBars()
		aetherView.placeToolBars()
		aetherView.showToolBars()
		aetherView.stretch()
		
		ooviumLabel.bottomRight(dx: -12*s, dy: -14*s, size: CGSize(width: 144*s, height: 40*s))
		
		// Message
		message.cutouts[Position.bottomRight] = Cutout(width: small.width, height: sh)
		message.cutouts[Position.bottomLeft] = Cutout(width: sh, height: sh)
		message.frame = CGRect(x: 5*s, y: aetherLimbo.bottom, width: lw, height: Screen.height-aetherLimbo.bottom-Screen.safeBottom)
		
		swapper.frame = CGRect(x: 5*s, y: message.bottom-sh, width: sh, height: sh)
		dilator.frame = CGRect(x: 5*s, y: medium.bottom, width: Screen.width-10*s, height: sh)
		close.frame = CGRect(x: message.right-small.width, y: message.bottom-sh, width: small.width, height: sh)
		
		empty.cutouts[Position.bottomRight] = Cutout(width: small.width, height: sh)
		empty.cutouts[Position.bottomLeft] = Cutout(width: sh, height: sh)
		empty.frame = CGRect(x: 5*s, y: dilator.bottom, width: Screen.width-10*s, height: Screen.height-dilator.bottom-Screen.safeBottom)
	}
	override func layout1024x768() {
		let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
		let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
		let height = Screen.height - topY - botY
		let s = height / 748
		let y: CGFloat = 400*s
		let ch: CGFloat = 72*s
		let bw: CGFloat = 50*s
		let q: CGFloat = 26*s
		
		let lW: CGFloat = 462*s

		large.topRight(dx: -5*s, dy: topY, width: lW, height: lW)
		medium.topLeft(dx: large.left, dy: large.bottom, width: 286*s, height: 286*s)
		small.topRight(dx: -5*s, dy: large.bottom, width: 176*s, height: 176*s)
		dilator.frame = CGRect(x: 205*s, y: topY+y, width: Screen.width-lW-200*s-10*s, height: ch)
		message.frame = CGRect(x: 5*s, y: topY+y+ch, width: Screen.width-lW-10*s, height: 768*s-20*s-y-ch)
		close.topLeft(dx: Screen.width-5*s-small.width, dy: medium.bottom-(medium.height-small.height), width: small.width, height: medium.height-small.height)

		controls.frame = CGRect(x: 5*s, y: topY+y, width: 200*s, height: ch)
		play.left(dx: 100*s-q-bw, size: CGSize(width: bw, height: 30*s))
		reset.left(dx: 100*s-bw/2, size: CGSize(width: bw, height: 30*s))
		guide.left(dx: 100*s+q, size: CGSize(width: bw, height: 30*s))
		
		// Aether
		aetherLimbo.frame = CGRect(x: 5*s, y: topY, width: Screen.width-lW-10*s, height: y)
		aetherLimbo.renderPaths()
		aetherLimbo.alpha = 0

		if Screen.mac {
			aetherView.aetherPickerOffset = UIOffset(horizontal: -12, vertical: -10)
		}
		else {
			aetherView.aetherPickerOffset = UIOffset(horizontal: -12, vertical: -6)
//			aetherView.toolBarOffset = UIOffset(horizontal: -9, vertical: 9)
		}

		aetherView.renderToolBars()
		aetherView.placeToolBars()
		aetherView.showToolBars()
		aetherView.invokeAetherPicker()
		aetherView.stretch()

		ooviumLabel.bottomRight(dx: -12*s, dy: -14*s, size: CGSize(width: 144*s, height: 40*s))
	}
}
