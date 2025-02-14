//
//  KinematicsExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
//import OoviumKit
import UIKit

class KinematicsExplorer: Explorer {
    enum Universe { case kinematics, newtonian }
    
    let newtonianView: NewtonianView = NewtonianView()
    let kinematicsView: KinematicsView = KinematicsView()
    
    lazy var universeCell: LimboCell = Screen.iPhone ? LimboCell(content: kinematicsView, c: 0, r: 0) : LimboCell(content: kinematicsView, c: 0, r: 0, h: 3)

    // Tabs =======
    lazy var controlsTab: KinematicsTab = KinematicsTab(explorer: self)
    var experimentsTab: ExperimentsTab!
    let notesTab: NotesTab = NotesTab(key: "kinematics")

    init() {
        super.init(key: "kinematics")
        experiments = KinematicsExperiment.experiments
    }
    
    var universe: Universe { controlsTab.universePicker.pageNo == 0 ? .newtonian : .kinematics }
    
    func initExperiment() {
        guard let experiment: KinematicsExperiment = experiment as? KinematicsExperiment else { return }
        
        switch experiment.letter {
            case .A: experimentA()
            case .B: experimentB()
       }
    }
    
    func experimentA() {
        let q = 0.3
        let sn = sin(Double.pi/6)
        let cs = cos(Double.pi/6)
        
        self.kinematicsView.Xa = V2(0, 0)
        self.kinematicsView.Va = V2(0.5, -1.5)
        self.kinematicsView.Vl = V2(-cs*q/2, -sn*q/4)
        
        self.kinematicsView.x = 3
        self.kinematicsView.y = 3
        self.kinematicsView.o = 1

        self.controlsTab.aetherVector.vector = self.kinematicsView.Va
        self.controlsTab.loopVector.vector = self.kinematicsView.Vl
    }
    func experimentB() {
        self.kinematicsView.Xa = V2(0, 0)
        self.kinematicsView.Va = V2(0, -1)
        self.kinematicsView.Vl = V2(0, 0)
        
        if Screen.iPhone {
            self.kinematicsView.x = 1
            self.kinematicsView.y = 0
            self.kinematicsView.o = 1
        } else {
            self.kinematicsView.x = 3
            self.kinematicsView.y = 0
            self.kinematicsView.o = 0
        }
        
        self.controlsTab.aetherVector.vector = self.kinematicsView.Va
        self.controlsTab.loopVector.vector = self.kinematicsView.Vl
    }

// Explorer ========================================================================================
    override var experiment: Experiment? {
        didSet { initExperiment() }
    }
        
// UIVIewController ================================================================================
    override func viewDidLoad() {
        cyto = Screen.iPhone ? Cyto(rows: 2, cols: 1) : Cyto(rows: 3, cols: 2)
        view.addSubview(cyto)
        
        tabsCell = Screen.iPhone ? TabsCell(c: 0, r: 0) : TabsCell(c: 1, r: 1)

        super.viewDidLoad()
        
        experimentsTab = ExperimentsTab(explorer: self)
        tabsCell.tabs = [controlsTab, experimentsTab, notesTab]

        if Screen.iPhone {
            cyto.cells = [
                universeCell,
                MaskCell(content: quickView, c: 0, r: 1, cutouts: [.lowerLeft, .lowerRight])
            ]
            configCyto.cells = [
                tabsCell,
                titleCell
            ]
        } else {
            cyto.cells = [
                universeCell,
                titleCell,
                tabsCell,
                LimboCell(content: quickView, c: 1, r: 2)
            ]
        }
        
        kinematicsView.onTic = { [unowned self] (velocity: V2) in
            self.controlsTab.loopVector.vector = velocity
        }
        newtonianView.onTic = { [unowned self] (velocity: V2) in
            self.controlsTab.loopVector.vector = velocity
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if controlsTab.universePicker.pageNo == 0 {
            Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
                self.newtonianView.tic()
                complete()
            }
        } else {
            Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
                self.kinematicsView.tic()
                complete()
            }
        }
        Aexels.sync.link.preferredFramesPerSecond = 60
        timeControl.playButton.stop()
        timeControl.playButton.play()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timeControl.playButton.play()
        timeControl.playButton.stop()
    }

// AEViewController ================================================================================
    override func layoutRatio056() {
        super.layoutRatio056()
        experiment = experiments[0]
    }
    override func layout1024x768() {
        let safeTop: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let safeBottom: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let cytoSize: CGSize = CGSize(width: view.width-10*s, height: Screen.height - safeTop - safeBottom)
        let universeWidth: CGFloat = cytoSize.height

        cyto.Xs = [universeWidth]
        cyto.Ys = [70*s, universeWidth-70*s-110*s, 110*s]
        cyto.frame = CGRect(x: 5*s, y: safeTop, width: view.width-10*s, height: cytoSize.height)
        cyto.layout()
        
        titleLabel.center(width: 300*s, height: 24*s)
        timeControl.left(dx: 10*s, width: 114*s, height: 54*s)
        experiment = experiments[0]
    }
    
// TimeControlDelegate =============================================================================
    override func onPlay() {
        switch universe {
            case .kinematics:   kinematicsView.play()
            case .newtonian:    newtonianView.play()
        }
    }
    override func onStep() {
        switch universe {
            case .kinematics:   kinematicsView.tic()
            case .newtonian:    newtonianView.tic()
        }
    }
    override func onReset() {
        timeControl.playButton.stop()
        initExperiment()
        onStep()
    }
    override func onStop() {
        switch universe {
            case .kinematics:   kinematicsView.stop()
            case .newtonian:    newtonianView.stop()
        }
    }
}
