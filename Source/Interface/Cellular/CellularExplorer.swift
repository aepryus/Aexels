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
        aetherView.orb = Orb(aetherView: aetherView, view: Aexels.explorerViewController.view, dx: 0, dy: 0)
        aetherView.hideScrollIndicators()
        Aexels.aetherView = aetherView
        aetherView.toolBarOffset = UIOffset(horizontal: -3, vertical: 6)
        
        return aetherView
    }()
    lazy var ooviumView: OoviumView = OoviumView(aetherView: aetherView)
    lazy var ooviumCell: MaskCell = MaskCell(content: ooviumView, c: 2, r: 2, h: 3)
    
    let cyto: Cyto = Cyto(rows: 5, cols: 3)
    
    let largeView: CellularView = CellularView()
    let mediumView: CellularView = CellularView()
    let smallView: CellularView = CellularView()
    let articleScroll: UIScrollView = UIScrollView()
    let articleView: ArticleView = ArticleView()
    let dilatorView: DilatorView = DilatorView()
    let controlsView: UIView = UIView()
    
// Explorer ========================================================================================
    override var shortName: String { "Automata" }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()

        _ = Facade.create(space: Space.local) as! SpaceFacade
        let facade: AetherFacade = Facade.create(ooviumKey: "Local::Game of Life") as! AetherFacade
        facade.load { (json: String?) in
            guard let json = json else { return }
            self.open(aether: Aether(json: json))
        }
        
        largeView.zoomView = mediumView
        mediumView.parentView = largeView
        mediumView.zoomView = smallView
        smallView.parentView = mediumView
        
        mediumView.zoom = 2
        smallView.zoom = 4
        
        if Screen.iPhone {
            largeView.points = floorQ(x: 335*s, to: 1)
            mediumView.points = floorQ(x: 190*s, to: 2)
            smallView.points = floorQ(x: 112*s, to: 4)
        } else /*if Screen.iPad*/{
            let height = Screen.height - Screen.safeTop - Screen.safeBottom
            let s = height / 748
            largeView.points = floorQ(x: 432*s, to: 1)
            mediumView.points = floorQ(x: 256*s, to: 2)
            smallView.points = floorQ(x: 144*s, to: 4)
        }
        
        articleView.font = UIFont(name: "Verdana", size: 18*s)!
        articleView.color = .white
        articleView.scrollView = articleScroll
        articleScroll.addSubview(articleView)
        
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
            self.largeView.flash()
            self.mediumView.flash()
        }
        
        dilatorView.onChange = { (frameRate: Int) in
            self.engine.frameRate = frameRate
        }

        cyto.cells = [
            LimboCell(content: largeView, size: CGSize(width: largeView.points, height: largeView.points), c: 0, r: 0, w: 2, h: 3),
            LimboCell(content: mediumView, size: CGSize(width: mediumView.points, height: mediumView.points), c: 0, r: 3, h: 2),
            LimboCell(content: smallView, size: CGSize(width: smallView.points, height: smallView.points), c: 1, r: 3),
            LimboCell(content: controlsView, c: 1, r: 4),
            MaskCell(content: articleScroll, c: 2, r: 0, cutouts: [.upperRight]),
            LimboCell(content: dilatorView, c: 2, r: 1, p: 12),
            ooviumCell
        ]
        cyto.layout()
        view.addSubview(cyto)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Aexels.sync.link.preferredFramesPerSecond = dilatorView.frameRate
        engine.defineOnFire()
        aetherView.layoutAetherPicker()
        aetherView.snapAetherPicker()
        aetherView.showToolBars()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        aetherView.dismissAetherPicker()
        aetherView.snuffToolBars()
        play.stop()
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

        aetherView.renderToolBars()
        aetherView.placeToolBars()
        aetherView.showToolBars()
        aetherView.invokeAetherPicker()
        aetherView.stretch()

        cyto.Xs = [286*s, 176*s]
        cyto.Ys = [768*s-20*s-y-ch, ch, lW-ch-(768*s-20*s-y-ch), 176*s]
        cyto.frame = CGRect(x: 5*s, y: topY, width: view.width-10*s, height: view.height-topY-botY)
        cyto.layout()
        
        articleView.load()
        articleScroll.contentSize = articleView.scrollViewContentSize
        articleView.frame = CGRect(x: 10*s, y: 0, width: articleScroll.width-20*s, height: articleScroll.height)
        
        play.left(dx: sw/2-q-bw-15*s, size: CGSize(width: bw, height: 30*s))
        reset.left(dx: sw/2-bw/2-15*s, size: CGSize(width: bw, height: 30*s))
        guide.left(dx: sw/2+q-15*s, size: CGSize(width: bw, height: 30*s))
        
        aetherView.aetherPickerOffset = UIOffset(horizontal: -ooviumCell.left-cyto.left-10*s, vertical: -ooviumCell.top-cyto.top+12*s)
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

    let closeButton: CloseButton = CloseButton()
	let swapper = Limbo()
	let swapButton = SwapButton()
    let deadLimbo: Limbo = Limbo()

	let guide = GuideButton()
	let reset = ResetButton()
	let play = PlayButton()
    
	
    init() { super.init(key: "cellular") }
	
	func open(aether: Aether) {
		play.stop()

		engine.removeAllViews()

		engine.addView(largeView)
		engine.addView(mediumView)
		engine.addView(smallView)

		engine.compile(aether: aether)

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
			self.engine.reset()
			let a = self.largeView.width/2
			self.largeView.zoom(at: CGPoint(x: a, y: a))
		}
		
		if aether.name == "Game of Life" {
            articleView.key = "gameOfLife"
		} else if aether.name == "Demons" {
            articleView.key = "demons"
		} else {
            articleView.key = "oovium"
		}
        articleView.load()
        articleScroll.contentSize = articleView.scrollViewContentSize
        articleScroll.contentOffset = .zero
	}
	
	private func floorQ(x: CGFloat, to: Int) -> Int { Int(floor(x/CGFloat(to))*CGFloat(to)) }
	
// Events ==========================================================================================
//	override func onOpen() {
//		Aexels.sync.link.preferredFramesPerSecond = dilatorView.frameRate
//		engine.defineOnFire()
//		aetherView.layoutAetherPicker()
//	}
//	override func onOpening() {
//		aetherView.snapAetherPicker()
//		aetherView.showToolBars()
//	}
//	override func onOpened() {}
//	override func onClose() {
//		aetherView.dismissAetherPicker()
//		aetherView.snuffToolBars()
//		play.stop()
//	}
	
// Explorer ========================================================================================
    override func layout375x667() {
    }
    override func layout375x812() {
    }
}
