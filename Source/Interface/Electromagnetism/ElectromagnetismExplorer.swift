//
//  ElectromagnetismExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 12/12/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import MetalKit
import UIKit

class ElectromagnetismExplorer: Explorer, TimeControlDelegate {
    enum Mode { case simulation, configuration }
    private let cyto: Cyto = !Screen.iPhone ? Cyto(rows: 4, cols: 2) : Cyto(rows: 3, cols: 1)
    private let configCyto: Cyto = Cyto(rows: 2, cols: 1)

    private let systemCell: LimboCell = !Screen.iPhone ? LimboCell(c: 0, r: 0, h: 4) : LimboCell(c: 0, r: 0, h: 2)
    private let aetherCell: LimboCell = !Screen.iPhone ? LimboCell(c: 0, r: 2, h: 2) : LimboCell(c: 0, r: 1)
    private let tabsCell: TabsCell = !Screen.iPhone ? TabsCell(c: 1, r: 1, h: 2) : TabsCell(c: 0, r: 0)
    private let titleCell: MaskCell = !Screen.iPhone ? MaskCell(content: UIView(), c: 1, r: 0, cutouts: [.upperRight]) : MaskCell(content: UIView(), c: 0, r: 1, cutouts: [.lowerLeft, .lowerRight])
    
    private var systemView: MTKView!
    private var aetherView: MTKView!
    let experimentView: UIView = UIView()
    let controlsView: UIView = UIView()
    
    // Metal ======
    var renderer: ElectromagnetismRenderer!

    // Title ======
    let titleLabel: UILabel = UILabel()
    
    // Controls ===
    let timeControl: TimeControl = TimeControl()
    let pingButton: PulseButton = PulseButton(name: Screen.iPhone ? nil : "ping")

    private var controlsTab: ControlsTab!
    let zoomsTab: TabsCellTab = TabsCellTab(name: "Zooms".localized)
    private var experimentsTab: ExperimentsTab!
    let notesTab: NotesTab = NotesTab(key: "electromagnetism")
    
    private var aetherFrameOn: Bool = false
    
    var experiments: [Experiment] = []
    var experiment: Experiment? = nil {
        didSet {
            guard experiment !== oldValue else { return }
            if let electromagnetism = experiment?.electromagnetism, electromagnetism.aetherFrameOn != aetherFrameOn {
                swapAetherFrame { self.applyExperiment() }
            } else { applyExperiment() }
        }
    }
    
    var mode: Mode = .simulation
    
    init() {
        
        super.init(key: "electromagnetism")
        aetherCell.alpha = 0
        
        experiments.append(.teslonsInABox())
        experiments.append(.exploringThePing())
        experiments.append(.whatIsMagnetism())
        experiments.append(.whatIsPotentialEnergy())
        experiments.append(.dilationRedux())
        experiments.append(.contractionRedux())
        experiments.append(.understandingFrames())
        experiments.append(.hondaAndTesla())
    }
    
    func applyExperiment() {
        experiment?.electromagnetism?.regenerateTeslons(size: systemView.drawableSize / systemView.contentScaleFactor)
        controlsTab.experiment = experiment
        renderer.experiment = experiment
        systemView.draw()
        aetherView.draw()
        controlsTab.applyControls()
    }
    
    func swapAetherFrame(_ onComplete: @escaping ()->() = {}) {
        aetherFrameOn = !aetherFrameOn
        
        if Screen.iPhone {
            if aetherFrameOn {
                aetherCell.alpha = 1
                systemCell.h = 1
                cyto.cells.append(self.aetherCell)
                cyto.layout()
            } else {
                aetherCell.alpha = 0
                systemCell.h = 2
                aetherCell.removeFromSuperview()
                cyto.layout()
            }
            onComplete()
        } else {
            let duration: CGFloat = 0.5
            
            if aetherFrameOn {
                UIView.animate(withDuration: duration) {
                    self.systemCell.alpha = 0
                } completion: { (complete: Bool) in
                    self.systemCell.h = 2
                    self.cyto.cells.append(self.aetherCell)
                    self.cyto.layout()
                    self.renderer.onReset()
                    onComplete()
                    UIView.animate(withDuration: duration) {
                        self.systemCell.alpha = 1
                        self.aetherCell.alpha = 1
                    }
                }
            } else {
                UIView.animate(withDuration: duration) {
                    self.systemCell.alpha = 0
                    self.aetherCell.alpha = 0
                } completion: { (complete: Bool) in
                    self.systemCell.h = 4
                    self.aetherCell.removeFromSuperview()
                    self.cyto.cells.remove(object: self.aetherCell)
                    self.cyto.layout()
                    self.renderer.onReset()
                    onComplete()
                    UIView.animate(withDuration: duration) {
                        self.systemCell.alpha = 1
                    }
                }
                
            }
        }
    }
    
    func drawAllMetalViews() {
        systemView.draw()
        aetherView.draw()
    }
    
    func toConfiguration() {
        UIView.animate(withDuration: 0.2) {
            self.cyto.alpha = 0
        } completion: { (complete: Bool) in
            self.cyto.isHidden = true
            self.configCyto.isHidden = false
            UIView.animate(withDuration: 0.2) {
                self.configCyto.alpha = 1
            }
        }
    }
    func toSimulation() {
        UIView.animate(withDuration: 0.2) {
            self.configCyto.alpha = 0
        } completion: { (complete: Bool) in
            self.configCyto.isHidden = true
            self.cyto.isHidden = false
            UIView.animate(withDuration: 0.2) {
                self.cyto.alpha = 1
            }
        }
    }
    
    func swapLimbos() {
        if mode == .simulation {
            mode = .configuration
            toConfiguration()
        } else {
            mode = .simulation
            toSimulation()
        }
    }
    func tapSwapButton() {
        swapButton.rotateView()
        swapLimbos()
    }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        systemView = MTKView(frame: view.bounds)
        systemView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        systemView.isOpaque = false
        
        let aetherView: MTKView = MTKView(frame: view.bounds)
        aetherView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        aetherView.isOpaque = false
        self.aetherView = aetherView

        renderer = ElectromagnetismRenderer(systemView: systemView, aetherView: aetherView)
        controlsTab = ControlsTab(explorer: self)
        experimentsTab = ExperimentsTab(explorer: self)
        
        systemCell.content = systemView
        aetherCell.content = aetherView
        tabsCell.tabs = [controlsTab, zoomsTab, experimentsTab, notesTab]
        
        if Screen.iPhone {
            cyto.cells = [
                systemCell,
                MaskCell(content: controlsView, c: 0, r: 2, cutouts: [.lowerLeft, .lowerRight])
            ]
            configCyto.cells = [
                tabsCell,
                titleCell
            ]
        } else {
            cyto.cells = [
                systemCell,
                titleCell,
                tabsCell,
                LimboCell(content: controlsView, c: 1, r: 3)
            ]
        }
        view.addSubview(cyto)
        
        configCyto.alpha = 0
        configCyto.isHidden = true
        view.addSubview(configCyto)
        
        // Title ========
        titleLabel.text = "Electricity and Magnetism".localized
        titleLabel.pen = Pen(font: .optima(size: 20*s), color: .white, alignment: .center)
        titleCell.content?.addSubview(titleLabel)
        
        timeControl.playButton.playing = true
        timeControl.delegate = self
        controlsView.addSubview(timeControl)

        controlsView.addSubview(pingButton)
        pingButton.addAction { [unowned self] in
            self.renderer.onPing()
        }
        
        timeControl.playButton.play()
        
        if Screen.iPhone {
            view.addSubview(swapperButton)
            swapButton.addAction { [unowned swapButton] in
                swapButton.rotateView()
                self.swapLimbos()
            }
            
            view.addSubview(glyphsButton)
        }
    }

// AEViewController ================================================================================
    override func layoutRatio056() {
        super.layoutRatio056()
        
        let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
        let uh: CGFloat = height - 80*s
        
        cyto.frame = CGRect(x: 5*s, y: safeTop, width: view.width-10*s, height: height)
        configCyto.frame = cyto.frame

        cyto.Ys = [uh/2, uh/2]
        cyto.layout()
        
        configCyto.Ys = [uh]
        configCyto.layout()

        titleLabel.center(width: 300*s, height: 24*s)
        timeControl.left(dx: 72*s, width: 114*s, height: 54*s)
        pingButton.right(dx: -84*s, width: 50*s, height: 50*s)
        
        experiment = experiments[0]
    }
    override func layout1024x768() {
        let safeTop: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let safeBottom: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let cytoSize: CGSize = CGSize(width: view.width-10*s, height: Screen.height - safeTop - safeBottom)
        let universeWidth: CGFloat = cytoSize.height

        cyto.Xs = [universeWidth]
        cyto.Ys = [70*s, universeWidth/2-70*s, universeWidth/2-110*s, 110*s]
        cyto.frame = CGRect(x: 5*s, y: safeTop, width: view.width-10*s, height: cytoSize.height)
        cyto.layout()
        
        titleLabel.center(width: 300*s, height: 24*s)
        timeControl.left(dx: 10*s, width: 114*s, height: 54*s)
        pingButton.right(dx: -15*s, width: 60*s, height: 80*s)
        
        experiment = experiments[0]
    }
    
// TimeControlDelegate =============================================================================
    func onPlay() {
        systemView.isPaused = false
        aetherView.isPaused = false
    }
    func onStep() {
        systemView.draw()
        aetherView.draw()
    }
    func onReset() {
        renderer.onReset()
        controlsTab.applyControls()
        systemView.draw()
        aetherView.draw()
        timeControl.playButton.stop()
    }
    func onStop() {
        systemView.isPaused = true
        aetherView.isPaused = true
    }
}
