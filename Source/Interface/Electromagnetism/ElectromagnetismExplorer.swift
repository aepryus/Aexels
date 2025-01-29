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
    
    let imageView = UIImageView()

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
            if let electromagnetism = experiment?.electromagnetism, electromagnetism.aetherFrameOn != aetherFrameOn {
                swapAetherFrame { self.applyExperiment() }
            } else { applyExperiment() }
        }
    }
    
    init() {
        super.init(key: "electromagnetism")
        aetherCell.alpha = 0
        
        experiments.append(Experiment.teslonsInABox())
        experiments.append(Experiment.exploringThePing())
        experiments.append(Experiment.whatIsMagnetism())
        experiments.append(Experiment.whatIsPotentialEnergy())
        experiments.append(Experiment.dilationRedux())
        experiments.append(Experiment.contractionRedux())
    }
    
    func applyExperiment() {
        experiment?.electromagnetism?.regenerateTeslons(size: systemView.bounds.size)
        controlsTab.experiment = experiment
        renderer.experiment = experiment
        systemView.draw()
        aetherView.draw()
//        timeControl.playButton.stop()
        controlsTab.applyControls()
    }
    
    func swapAetherFrame(_ onComplete: @escaping ()->() = {}) {
        aetherFrameOn = !aetherFrameOn
        
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
        
        cyto.cells = [
//            LimboCell(content: imageView, c: 0, r: 0, h: 4),
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
        
        timeControl.playButton.play()
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
        
//        print("Q:\(imageView.bounds)")
//        imageView.image = Engine.renderHex(size: imageView.bounds.size)

        
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
