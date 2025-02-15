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
    
    let largeView: CellularView = CellularView()
    let mediumView: CellularView = CellularView()
    let smallView: CellularView = CellularView()
    let dilatorView: DilatorView = DilatorView()
    let controlsView: UIView = UIView()
    
    let guide = GuideButton()
    
    // Tabs =======
    let ooviumTab: OoviumTab = OoviumTab()
    var experimentsTab: ExperimentsTab!
    let notesTab: NotesTab = NotesTab(key: "cellular")
    
    init() {
        super.init(key: "cellular")
        experiments = CellularExperiment.loadExperiments()
    }
    
    func open(aether: Aether) {
        timeControl.playButton.stop()

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
    }
    private func floorQ(x: CGFloat, to: Int) -> Int { Int(floor(x/CGFloat(to))*CGFloat(to)) }
    
// Explorer ========================================================================================
    override var shortName: String { "Automata" }
    override var experiment: Experiment? {
        didSet {
            guard let experiment: CellularExperiment = experiment as? CellularExperiment else { return }
            Space.local.loadAether(facade: experiment.facade) { (json: String?) in
                guard let json else { return }
                let aether: Aether = Aether(json: json)
                self.aetherView.swapToAether(aether: aether)
                self.engine.needsCompile = true
                self.open(aether: aether)
            }
        }
    }

// UIViewController ================================================================================
    override func viewDidLoad() {
        cyto = Screen.iPhone ? Cyto(rows: 4, cols: 2) : Cyto(rows: 5, cols: 4)
        view.addSubview(cyto)
        
        if !Screen.iPhone { titleCell.c = 3 }
        tabsCell = Screen.iPhone ? TabsCell(c: 0, r: 0) : TabsCell(c: 3, r: 1, h: 3)

        super.viewDidLoad()
        
        experimentsTab = ExperimentsTab(explorer: self)
        tabsCell.tabs = [ooviumTab, experimentsTab, notesTab]

        _ = Facade.create(space: Space.local) as! SpaceFacade
        let facade: AetherFacade = Facade.create(ooviumKey: "Local::Game of Life") as! AetherFacade
        facade.load { (json: String?) in
            guard let json = json else { return }
            self.open(aether: Aether(json: json))
        }
        
        ooviumTab.ooviumView = ooviumView

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

        quickView.addSubview(guide)
        guide.addAction(for: .touchUpInside) { [unowned self] in
            self.engine.guideOn = !self.engine.guideOn
            self.guide.stateOn = self.engine.guideOn
            self.guide.setNeedsDisplay()
            self.largeView.flash()
            self.mediumView.flash()
        }
        
        quickView.addSubview(dilatorView)
        dilatorView.onChange = { (frameRate: Int) in
            self.engine.frameRate = frameRate
        }
        
        if Screen.iPhone {
            cyto.cells = [
                LimboCell(content: largeView, size: CGSize(width: largeView.points, height: largeView.points), c: 0, r: 0, w: 2),
                LimboCell(content: mediumView, size: CGSize(width: mediumView.points, height: mediumView.points), c: 0, r: 1, h: 2),
                LimboCell(content: smallView, size: CGSize(width: smallView.points, height: smallView.points), c: 1, r: 1),
                LimboCell(c: 1, r: 2),
                MaskCell(content: quickView, c: 0, r: 3, w: 2, cutouts: [.lowerLeft, .lowerRight])
            ]
            configCyto.cells = [
                tabsCell,
                titleCell
            ]
        } else {
            cyto.cells = [
                LimboCell(c: 0, r: 0, h: 5),
                LimboCell(content: largeView, size: CGSize(width: largeView.points, height: largeView.points), c: 1, r: 0, w: 2, h: 2),
                LimboCell(content: mediumView, size: CGSize(width: mediumView.points, height: mediumView.points), c: 1, r: 2, h: 3),
                LimboCell(content: smallView, size: CGSize(width: smallView.points, height: smallView.points), c: 2, r: 2),
                LimboCell(c: 2, r: 3, h: 2),
                titleCell,
                tabsCell,
                LimboCell(content: quickView, c: 3, r: 4)
            ]
        }
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
        timeControl.playButton.stop()
    }
    
// AEViewController ================================================================================
    override func layoutRatio046() {
        super.layoutRatio046()

        let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
        
        cyto.frame = CGRect(x: 5*s, y: safeTop, width: view.width-10*s, height: height)
        configCyto.frame = cyto.frame

        let lw: CGFloat = Screen.width-10*s
        let mw: CGFloat = 221*s
        let sw: CGFloat = lw-mw
        
        let x1 = lw
        let x2 = lw+sw
        let x3 = lw+mw
        
        cyto.Xs = [mw]
        cyto.Ys = [x1, x2-x1, x3-x2]

        cyto.layout()
        configCyto.layout()
        
        let dy: CGFloat = -20*s
        timeControl.left(dx: 20*s, dy: dy, width: 114*s, height: 54*s)
        guide.left(dx: 130*s, dy: dy, size: CGSize(width: 50*(height / 748), height: 30*s))
        dilatorView.left(dx: 180*s, dy: dy, width: 150*s, height: 40*s)
    }
    override func layoutRatio056() {
        self.layoutRatio046()
        
        timeControl.left(dx: 50*s, width: 114*s, height: 54*s)
        let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
        guide.left(dx: 160*s, size: CGSize(width: 50*(height / 748), height: 30*s))
        dilatorView.left(dx: 205*s, width: 105*s, height: 40*s)
    }
    override func layoutRatio143() {
        let safeTop: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let safeBottom: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let cytoSize: CGSize = CGSize(width: view.width-10*s, height: Screen.height - safeTop - safeBottom)
        let universeWidth: CGFloat = cytoSize.height

        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let height = Screen.height - topY - botY
        let oS = height / 748
        let bw: CGFloat = 50*(height / 748)
        
        aetherView.renderToolBars()
        aetherView.placeToolBars()
        aetherView.showToolBars()
        aetherView.invokeAetherPicker()
        aetherView.stretch()
        
        cyto.Xs = [universeWidth-286*oS-176*oS, 286*oS, 176*oS]

        let titleH = 70*s
        let largeH = 462*oS
        let smallH = 176*oS
        let quickH = 110*s
        
        let x1 = titleH
        let x2 = largeH
        let x3 = largeH+smallH
        let x4 = universeWidth-quickH
        
        cyto.Ys = [x1, x2-x1, x3-x2, x4-x3]
        
        cyto.frame = CGRect(x: 5*s, y: topY, width: view.width-10*s, height: view.height-topY-botY)
        cyto.layout()
                
        titleLabel.center(width: 300*s, height: 24*s)
        timeControl.left(dx: 10*s, width: 114*s, height: 54*s)
        guide.left(dx: 120*s, size: CGSize(width: bw, height: 30*s))
        dilatorView.left(dx: 170*s, width: 150*s, height: 40*s)

//        experiment = experiments[0]
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
    
// TimeControlDelegate =============================================================================
    override func onPlay() {
        engine.start(aether: self.aetherView.aether)
    }
    override func onStep() {
        engine.doStep()
    }
    override func onReset() {
        timeControl.playButton.stop()
        engine.configureViews()
        engine.reset()
        engine.needsCompile = true
    }
    override func onStop() {
        engine.stop()
    }
}
