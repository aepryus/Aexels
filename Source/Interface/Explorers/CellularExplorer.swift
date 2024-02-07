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

class CellularExplorer: Explorer, AetherViewDelegate {
    lazy var engine: CellularEngine = {
        let cellsPerSide: Int
        if Screen.iPhone { cellsPerSide = Int(335*Screen.s) }
        else if Screen.iPad { cellsPerSide = Int(432*(Screen.height - Screen.safeTop - Screen.safeBottom)/748) }
        else { cellsPerSide = Int(Screen.scaler == 1 ? 465 : 609) }
        return CellularEngine(side: cellsPerSide)
    }()
    
    lazy var aetherView: AetherView = {
        var tools: [[Tool?]] = Array(repeating: Array(repeating: nil, count: 2), count: 2)
        tools[0][0] = AetherView.objectTool
        tools[1][0] = AetherView.gateTool
        tools[0][1] = AetherView.mechTool
        
        let aetherView: AetherView = AetherView(aether: engine.aether, toolBox: ToolBox(tools), toolsOn: false, oldPicker: true)
        aetherView.backgroundColor = .clear
        aetherView.aetherViewDelegate = self
        aetherView.orb = Orb(aetherView: aetherView, view: Aexels.nexus.view, dx: 0, dy: 0)
        Aexels.aetherView = aetherView
        aetherView.toolBarOffset = UIOffset(horizontal: -3, vertical: 6)
        
        return aetherView
    }()
    lazy var ooviumView: OoviumView = OoviumView(aetherView: aetherView)
    lazy var ooviumCell: LimboCell = LimboCell(content: ooviumView, c: 2, r: 2, h: 3)
    
    let cyto: Cyto = Cyto(rows: 5, cols: 3)
    
    let largeCell: CellularView = CellularView()
    let mediumCell: CellularView = CellularView()
    let smallCell: CellularView = CellularView()
    let dilatorView: DilatorView = DilatorView()
    var messageLimbo: MessageLimbo = MessageLimbo()
    let controlsView: UIView = UIView()

// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()

        _ = Facade.create(space: Space.local) as! SpaceFacade
        let facade: AetherFacade = Facade.create(ooviumKey: "Local::Game of Life") as! AetherFacade
        facade.load { (json: String?) in
            guard let json = json else { return }
            self.open(aether: Aether(json: json))
        }
        
        largeCell.zoomView = mediumCell
        mediumCell.parentView = largeCell
        mediumCell.zoomView = smallCell
        smallCell.parentView = mediumCell
        
        mediumCell.zoom = 2
        smallCell.zoom = 4
        
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
        
//        var length: CGFloat = CGFloat(largeCell.points); large.set(content: largeCell, size: CGSize(width: length, height: length))
//        length = CGFloat(mediumCell.points); medium.set(content: mediumCell, size: CGSize(width: length, height: length))
//        length = CGFloat(smallCell.points); small.set(content: smallCell, size: CGSize(width: length, height: length))
        
        play.onPlay = { [unowned self] in
            self.engine.start(aether: self.aetherView.aether)
        }
        play.onStop = { [unowned self] in
            self.engine.stop()
        }
        controlsView.addSubview(play)
        
        controlsView.addSubview(reset)
        reset.addAction(for: .touchUpInside) { [unowned self] in
            self.play.stop()
            self.engine.configureViews()
            self.engine.reset()
            self.engine.needsCompile = true
        }
        
        controlsView.addSubview(guide)
        guide.addAction(for: .touchUpInside) { [unowned self] in
            self.engine.guideOn = !self.engine.guideOn
            self.guide.stateOn = self.engine.guideOn
            self.guide.setNeedsDisplay()
            self.largeCell.flash()
            self.mediumCell.flash()
        }

        cyto.padding = 0
        cyto.cells = [
            LimboCell(content: largeCell, c: 0, r: 0, w: 2, h: 3),
            LimboCell(content: mediumCell, c: 0, r: 3, h: 2),
            LimboCell(content: smallCell, c: 1, r: 3),
            LimboCell(content: controlsView, c: 1, r: 4),
            LimboCell(c: 2, r: 0),
            LimboCell(content: dilatorView, c: 2, r: 1),
            ooviumCell
        ]
        cyto.layout()
        view.addSubview(cyto)
    }
    
// AEViewController ================================================================================
    override func layout1024x768() {
        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let height = Screen.height - topY - botY
        let s = height / 748
        let y: CGFloat = 360*s
        let ch: CGFloat = 72*s
        let bw: CGFloat = 50*s
        let sw: CGFloat = 176*s
        let q: CGFloat = 26*s
        
        let lW: CGFloat = 462*s

//        large.topLeft(dx: 5*s, dy: topY, width: lW, height: lW)
//        medium.topLeft(dx: large.left, dy: large.bottom, width: 286*s, height: 286*s)
//        small.topLeft(dx: medium.right, dy: large.bottom, width: 176*s, height: 176*s)
//        messageLimbo.closeOn = true
//        messageLimbo.frame = CGRect(x: large.right, y: topY, width: Screen.width-lW-10*s, height: 768*s-20*s-y-ch)
//
//        closeButton.topLeft(dx: messageLimbo.right-50*s, dy: messageLimbo.top, width: 50*s, height: 50*s)
//
//        controls.topLeft(dx: small.left, dy: small.bottom, width: small.width, height: medium.height-small.height)
        play.left(dx: sw/2-q-bw, size: CGSize(width: bw, height: 30*s))
        reset.left(dx: sw/2-bw/2, size: CGSize(width: bw, height: 30*s))
        guide.left(dx: sw/2+q, size: CGSize(width: bw, height: 30*s))
//
//        dilator.frame = CGRect(x: large.right, y: messageLimbo.bottom, width: Screen.width-lW-10*s, height: ch)

        // Aether
//        aetherLimbo.frame = CGRect(x: large.right, y: dilator.bottom, width: Screen.width-lW-10*s, height: y)
//        aetherLimbo.renderPaths()
//        aetherLimbo.alpha = 0

        aetherView.renderToolBars()
        aetherView.placeToolBars()
        aetherView.showToolBars()
        aetherView.invokeAetherPicker()
        aetherView.stretch()

        cyto.Xs = [286*s, 176*s]
        cyto.Ys = [768*s-20*s-y-ch, ch, lW-ch-(768*s-20*s-y-ch), 176*s]
        cyto.frame = CGRect(x: 5*s, y: topY, width: view.width-10*s, height: view.height-topY-botY)
        cyto.layout()
        
        if Screen.mac { aetherView.aetherPickerOffset = UIOffset(horizontal: -ooviumCell.left-10*s, vertical: -ooviumCell.top+12*s) }
        else { aetherView.aetherPickerOffset = UIOffset(horizontal: -ooviumCell.left-10*s, vertical: -ooviumCell.top+12*s) }
    }
    
// AetherViewDelegate ==============================================================================
    func onNew(aetherView: AetherView, aether: Aether) {
        self.engine.needsCompile = true
        let auto: Auto = aether.create(at: .zero)
        aether.xOffset = Double(self.aetherView.width) - 130
        aether.yOffset = Double(self.aetherView.height) - 100
        auto.statesChain.replaceWith(tokens: "dg:2")
        aether.evaluate()
    }
    func onClose(aetherView: AetherView, aether: Aether) {}
    func onOpen(aetherView: AetherView, aether: Aether) {
        self.engine.needsCompile = true
        self.open(aether: aether)
    }
    func onSave(aetherView: AetherView, aether: Aether) {}


    
// =================================================================================================
// =================================================================================================
// =================================================================================================

	var first = [Limbo]()
	var second = [Limbo]()
	var isFirst: Bool = true


	
//	var aetherLimbo: ContentLimbo!
//	let controls = Limbo()
//	let dilator = Limbo(p: 12)
//	let large = Limbo()
//	var medium = Limbo()
//	let small = Limbo()
//	let empty = Limbo()
//    let close = LimboButton(title: "Close")
    let closeButton: CloseButton = CloseButton()
	let swapper = Limbo()
	let swapButton = SwapButton()
    let deadLimbo: Limbo = Limbo()

	let guide = GuideButton()
	let reset = ResetButton()
	let play = PlayButton()
    
	
    init() {
        super.init(name: "Cellular Automata", key: "cellular", canExplore: true)
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
            messageLimbo.key = "GameOfLife"
		} else if aether.name == "Demons" {
            messageLimbo.key = "Demons"
		} else {
            messageLimbo.key = "Oovium"
		}
        messageLimbo.load()
	}
	
	private func floorQ(x: CGFloat, to: Int) -> Int { Int(floor(x/CGFloat(to))*CGFloat(to)) }
	
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
//			limbos = [swapper] + first + [close]
		}
	}
	
// Explorer ========================================================================================
	override func createLimbos() {
//        return
        
		// Cellular Views ==================
		// Large
//		limbos.append(large)
		
		// Medium
//		mediumCell.zoom = 2
//		limbos.append(medium)
		
		// Small
//		smallCell.zoom = 4
//		limbos.append(small)
		

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
		
//		var length: CGFloat = CGFloat(largeCell.points); large.set(content: largeCell, size: CGSize(width: length, height: length))
//		length = CGFloat(mediumCell.points); medium.set(content: mediumCell, size: CGSize(width: length, height: length))
//		length = CGFloat(smallCell.points); small.set(content: smallCell, size: CGSize(width: length, height: length))

		// Message =========================
        messageLimbo = MessageLimbo()
		
		// Aether ==========================
        _ = Facade.create(space: Space.local) as! SpaceFacade
        let facade: AetherFacade = Facade.create(ooviumKey: "Local::Game of Life") as! AetherFacade
        facade.load { (json: String?) in
			guard let json = json else { return }
			self.open(aether: Aether(json: json))
		}

//		var tools: [[Tool?]] = Array(repeating: Array(repeating: nil, count: 2), count: 2)
//		tools[0][0] = AetherView.objectTool
//		tools[1][0] = AetherView.gateTool
//		tools[0][1] = AetherView.mechTool
//		
//		aetherView = AetherView(aether: engine.aether, toolBox: ToolBox(tools), toolsOn: false, oldPicker: true)
//        aetherView.backgroundColor = .clear
//		aetherView.aetherViewDelegate = self
//        aetherView.orb = Orb(aetherView: aetherView, view: Aexels.nexus.view, dx: 0, dy: 0)
//		Aexels.aetherView = aetherView
//		aetherView.toolBarOffset = UIOffset(horizontal: -3, vertical: 6)

//		aetherLimbo = ContentLimbo(content: aetherView)
		
		// Dilator =========================
//		dilatorView.onChange = { (frameRate: Int) in
//			self.engine.frameRate = frameRate
//		}
//		dilator.content = dilatorView
//		limbos.append(dilator)
		
		engine.onMeasure = {(actualSps: Double)->() in
			print("actual frame rate: \(actualSps)")
		}
		
		// Controls ========================
//		limbos.append(controls)
		
//		play.onPlay = { [unowned self] in
//			self.engine.start(aether: self.aetherView.aether)
//		}
//		play.onStop = { [unowned self] in
//			self.engine.stop()
//		}
//		controls.addSubview(play)
//		
//		controls.addSubview(reset)
//		reset.addAction(for: .touchUpInside) { [unowned self] in
//			self.play.stop()
//			self.engine.configureViews()
//			self.engine.reset()
//			self.engine.needsCompile = true
//		}
//		
//		controls.addSubview(guide)
//		guide.addAction(for: .touchUpInside) { [unowned self] in
//			self.engine.guideOn = !self.engine.guideOn
//			self.guide.stateOn = self.engine.guideOn
//			self.guide.setNeedsDisplay()
//			self.largeCell.flash()
//			self.mediumCell.flash()
//		}
//
//		// Close ===========================
//        close.alpha = 0
//        close.addAction(for: .touchUpInside) { [unowned self] in
//            self.isFirst = true
//            self.aetherView.snuffToolBars()
//            self.closeExplorer()
//            Aexels.nexus.brightenNexus()
//        }
//        limbos.append(close)

        closeButton.alpha = 0
        closeButton.addAction(for: .touchUpInside) { [unowned self] in
			self.isFirst = true
			self.aetherView.snuffToolBars()
			self.closeExplorer()
//			Aexels.nexus.brightenNexus()
		}
		limbos.append(closeButton)

		// Swapper =========================
		if Screen.iPhone {
			swapButton.addAction(for: .touchUpInside) { [unowned self] in
				self.swapButton.rotateView()
				if self.isFirst {
					self.isFirst = false
					self.dimLimbos(self.first)
					self.brightenLimbos(self.second)
//					self.limbos = [self.swapper] + self.second + [self.close]
					self.aetherView.snuffToolBars()
				} else {
					self.isFirst = true
					self.dimLimbos(self.second)
					self.brightenLimbos(self.first)
//					self.limbos = [self.swapper] + self.first + [self.close]
					self.aetherView.invokeAetherPicker()
					self.aetherView.showToolBars()
				}
				self.swapper.removeFromSuperview()
				self.view.addSubview(self.swapper)
//				self.close.removeFromSuperview()
//				self.view.addSubview(self.close)
			}
			swapper.content = swapButton
			limbos.append(swapper)

//			first = [aetherLimbo, messageLimbo]
//			if Screen.dimensions == .dim375x812 || Screen.dimensions == .dim414x896 {
//				second = [empty, controls, dilator, large, medium, small]
//			} else {
//				second = [controls, dilator, large, medium, small]
//			}
		}
		
		if Screen.iPhone {
			brightenLimbos(first)
//			limbos = [swapper] + first + [close]
		} else {
//			limbos.append(aetherLimbo)
			limbos.append(messageLimbo)
		}
	}
    override func layout375x667() {
//        let lw: CGFloat = 375*s-10*s
//        let mw: CGFloat = 221*s
//        let sw: CGFloat = lw-mw
//        let bw: CGFloat = 40*s
//
//        large.frame = CGRect(x: 5*s, y: 20*s, width: lw, height: lw)
//        medium.frame = CGRect(x: 5*s, y: large.bottom, width: mw, height: mw)
//        small.frame = CGRect(x: medium.right, y: large.bottom, width: sw, height: sw)
//        swapper.frame = CGRect(x: 5*s, y: medium.bottom, width: 56*s, height: 56*s)
//        dilator.frame = CGRect(x: swapper.right, y: medium.bottom, width: medium.width-swapper.width, height: swapper.height)
//        close.frame = CGRect(x: medium.right, y: medium.bottom, width: small.width, height: swapper.height)
//
//        controls.frame = CGRect(x: medium.right, y: small.bottom, width: small.width, height: medium.height-small.height)
//        play.left(dx: 15*s, size: CGSize(width: bw, height: 30*s))
//        reset.left(dx: 15*s+bw, size: CGSize(width: bw, height: 30*s))
//        guide.left(dx: 15*s+2*bw, size: CGSize(width: bw, height: 30*s))
//        
//        // AetherLimbo
//        aetherLimbo.frame = CGRect(x: 5*s, y: 20*s, width: lw, height: lw)
//        aetherLimbo.renderPaths()
//        aetherLimbo.alpha = 0
//        
//        aetherView.toolBarOffset = UIOffset(horizontal: -9, vertical: 9)
//        aetherView.aetherPickerOffset = UIOffset(horizontal: -10, vertical: -4)
//
//        aetherView.renderToolBars()
//        aetherView.placeToolBars()
//        aetherView.showToolBars()
//        aetherView.stretch()
//
//        // Message
//        messageLimbo.cutouts[Position.bottomRight] = Cutout(width: small.width, height: swapper.height)
//        messageLimbo.cutouts[Position.bottomLeft] = Cutout(width: swapper.height, height: swapper.height)
//        messageLimbo.frame = CGRect(x: 5*s, y: aetherLimbo.bottom, width: lw, height: Screen.height-aetherLimbo.bottom-5*s)
    }
    override func layout375x812() {
//        let lw: CGFloat = Screen.width-10*s
//        let mw: CGFloat = 221*s
//        let sw: CGFloat = lw-mw
//        let bw: CGFloat = 40*s
//        let sh: CGFloat = 56*s
//        
//        large.frame = CGRect(x: 5*s, y: Screen.safeTop, width: lw, height: lw)
//        medium.frame = CGRect(x: 5*s, y: large.bottom, width: mw, height: mw)
//        small.frame = CGRect(x: medium.right, y: large.bottom, width: sw, height: sw)
//        
//        controls.frame = CGRect(x: medium.right, y: small.bottom, width: small.width, height: medium.height-small.height)
//        play.left(dx: 15*s, size: CGSize(width: bw, height: 30*s))
//        reset.left(dx: 15*s+bw, size: CGSize(width: bw, height: 30*s))
//        guide.left(dx: 15*s+2*bw, size: CGSize(width: bw, height: 30*s))
//        
//        // AetherLimbo
//        aetherLimbo.frame = CGRect(x: 5*s, y: Screen.safeTop, width: lw, height: lw)
//        aetherLimbo.renderPaths()
//        aetherLimbo.alpha = 0
//        
//        aetherView.toolBarOffset = UIOffset(horizontal: -9, vertical: 9)
//        aetherView.aetherPickerOffset = UIOffset(horizontal: -10, vertical: -4)
//
//        aetherView.renderToolBars()
//        aetherView.placeToolBars()
//        aetherView.showToolBars()
//        aetherView.stretch()
//        
//        // Message
//        messageLimbo.cutouts[Position.bottomRight] = Cutout(width: small.width, height: sh)
//        messageLimbo.cutouts[Position.bottomLeft] = Cutout(width: sh, height: sh)
//        messageLimbo.frame = CGRect(x: 5*s, y: aetherLimbo.bottom, width: lw, height: Screen.height-aetherLimbo.bottom-Screen.safeBottom)
//        
//        swapper.frame = CGRect(x: 5*s, y: messageLimbo.bottom-sh, width: sh, height: sh)
//        dilator.frame = CGRect(x: 5*s, y: medium.bottom, width: Screen.width-10*s, height: sh)
//        close.frame = CGRect(x: messageLimbo.right-small.width, y: messageLimbo.bottom-sh, width: small.width, height: sh)
//        
//        empty.cutouts[Position.bottomRight] = Cutout(width: small.width, height: sh)
//        empty.cutouts[Position.bottomLeft] = Cutout(width: sh, height: sh)
//        empty.frame = CGRect(x: 5*s, y: dilator.bottom, width: Screen.width-10*s, height: Screen.height-dilator.bottom-Screen.safeBottom)
    }
}
