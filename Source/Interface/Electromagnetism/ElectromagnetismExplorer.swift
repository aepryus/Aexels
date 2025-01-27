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
    private let cyto: Cyto = Cyto(rows: 4, cols: 2)
    
    private let systemCell: LimboCell = LimboCell(c: 0, r: 0, h: 4)
    private let aetherCell: LimboCell = LimboCell(c: 0, r: 2, h: 2)
    private let tabsCell: TabsCell = TabsCell(c: 1, r: 1, h: 2)
    
    private var systemView: MTKView!
    private var aetherView: MTKView!
    let titleView: UIView = UIView()
    let experimentView: UIView = UIView()
    let controlsView: UIView = UIView()

    // Metal ======
    var renderer: ElectromagnetismRenderer!

    // Title ======
    let titleLabel: UILabel = UILabel()
    
    // Controls ===
    let timeControl: TimeControl = TimeControl()
    let pingButton: PulseButton = PulseButton(name: "ping")

    private var controlsTab: ControlsTab!
    let zoomsTab: TabsCellTab = TabsCellTab(name: "Zooms".localized)
    private var experimentsTab: ExperimentsTab!
    let notesTab: NotesTab = NotesTab(key: "electromagnetism")
    
    private var aetherFrameOn: Bool = false
    
    var experiments: [Experiment] = []
    var experiment: Experiment? = nil {
        didSet {
            onStop()
            if let electromagnetism = experiment?.electromagnetism, electromagnetism.aetherFrameOn != aetherFrameOn {
                swapAetherFrame { self.applyExperiment() }
            } else { applyExperiment() }
        }
    }
    
    private static let fullSize: CGSize = CGSize(width: 1001.1350788249184, height: 1001.1350788249184)
    private static let halfSize: CGSize = CGSize(width: 1001.1350788249184, height: 479.9931939718036)

    init() {
        super.init(key: "electromagnetism")
        aetherCell.alpha = 0
        
        experiments.append(Experiment.teslonsInABox(size: ElectromagnetismExplorer.fullSize))
        experiments.append(Experiment.whatIsMagnetism(size: ElectromagnetismExplorer.halfSize))
        experiments.append(Experiment.whatIsPotentialEnergy(size: ElectromagnetismExplorer.fullSize))
        experiments.append(Experiment.dilationRedux(size: ElectromagnetismExplorer.fullSize))
        experiments.append(Experiment.contractionRedux(size: ElectromagnetismExplorer.fullSize))
    }
    
    func applyExperiment() {
        controlsTab.experiment = experiment
        renderer.experiment = experiment
        systemView.draw()
        aetherView.draw()
        timeControl.playButton.stop()
        controlsTab.applyControls()
    }
    
    func swapAetherFrame(_ onComplete: @escaping ()->() = {}) {
        aetherFrameOn = !aetherFrameOn
        
        let duration: CGFloat = 0.5
        
        if aetherFrameOn {
            UIView.animate(withDuration: duration) {
                self.systemCell.alpha = 0
            } completion: { (complete: Bool) in
                self.renderer.size = ElectromagnetismExplorer.halfSize
                self.systemCell.h = 2
                self.cyto.cells.append(self.aetherCell)
                self.cyto.layout()
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
                self.renderer.size = ElectromagnetismExplorer.fullSize
                self.systemCell.h = 4
                self.aetherCell.removeFromSuperview()
                self.cyto.cells.remove(object: self.aetherCell)
                self.cyto.layout()
                onComplete()
                UIView.animate(withDuration: duration) {
                    self.systemCell.alpha = 1
                }
            }

        }
    }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        systemView = MTKView(frame: CGRect(origin: .zero, size: ElectromagnetismExplorer.fullSize))
        systemView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        systemView.isOpaque = false
        
        let aetherView: MTKView = MTKView(frame: CGRect(origin: .zero, size: ElectromagnetismExplorer.halfSize))
        aetherView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        aetherView.isOpaque = false
        self.aetherView = aetherView

        renderer = ElectromagnetismRenderer(systemView: systemView, aetherView: aetherView)
        controlsTab = ControlsTab(explorer: self)
        experimentsTab = ExperimentsTab(explorer: self)
        
        systemCell.content = systemView
        aetherCell.content = aetherView
        tabsCell.tabs = [controlsTab, zoomsTab, experimentsTab, notesTab]

        cyto.cells = [
            systemCell,
            MaskCell(content: titleView, c: 1, r: 0, cutout: true),
            tabsCell,
            LimboCell(content: controlsView, c: 1, r: 3)
        ]
        view.addSubview(cyto)
        
        // Title ========
        titleLabel.text = "Electricity and Magnetism".localized
        titleLabel.pen = Pen(font: .optima(size: 20*s), color: .white, alignment: .center)
        titleView.addSubview(titleLabel)
        
        timeControl.playButton.playing = true
        timeControl.delegate = self
        controlsView.addSubview(timeControl)

        controlsView.addSubview(pingButton)
        pingButton.addAction { [unowned self] in
            self.renderer.onPing()
        }
    }

// AEViewController ================================================================================
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
