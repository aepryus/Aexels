//
//  AetherExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class AetherExplorer: Explorer {
    
    let aexelsView: AexelsView = AexelsView()

    let swapper: Limbo = Limbo()
    var first: [Limbo] = [Limbo]()
    var second: [Limbo] = [Limbo]()
    var isFirst: Bool = false
    
    let articleScroll: UIScrollView = UIScrollView()
    let articleView: ArticleView = ArticleView()
    
    var experimentsTab: ExperimentsTab!
    let notesTab: NotesTab = NotesTab(key: "aether")
    
    init() {
        super.init(key: "aether")    
        experiments = AetherExperiment.experiments
    }
    
    func initExperiment() {
        guard let experiment: AetherExperiment = experiment as? AetherExperiment else { return }
        
        switch experiment.letter {
            case .A: aexelsView.experimentA()
            case .B: aexelsView.experimentB()
            case .C: aexelsView.experimentC()
            case .D: aexelsView.experimentD()
            case .E: aexelsView.experimentE()
            case .F: aexelsView.experimentF()
            case .G: aexelsView.experimentG()
            case .H: aexelsView.experimentH()
            case .I: aexelsView.experimentI()
            case .J: aexelsView.experimentJ()
       }
    }
    
// Explorer ========================================================================================
    override var experiment: Experiment? {
        didSet { initExperiment() }
    }
    
    
// AEViewController ================================================================================
    override func layoutRatio056() {
        super.layoutRatio056()
        experiment = experiments[0]
    }
    override func layout1024x768() {
        super.layout1024x768()
        
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

// UIViewController ================================================================================
    override func viewDidLoad() {
        
        cyto = Screen.iPhone ? Cyto(rows: 2, cols: 1) : Cyto(rows: 2, cols: 2)
        view.addSubview(cyto)
        
        tabsCell = Screen.iPhone ? TabsCell(c: 0, r: 0) : TabsCell(c: 1, r: 1)

        super.viewDidLoad()
        
        experimentsTab = ExperimentsTab(explorer: self)
        
        tabsCell.tabs = [experimentsTab, notesTab]
        
        articleView.font = UIFont(name: "Verdana", size: 18*s)!
        articleView.color = .white
        articleView.scrollView = articleScroll
        articleView.key = "aetherLab"
        articleScroll.addSubview(articleView)        
        
        if Screen.iPhone {
            cyto.cells = [
                LimboCell(content: aexelsView, c: 0, r: 0),
                MaskCell(content: quickView, c: 0, r: 1, cutouts: [.lowerLeft, .lowerRight])
            ]
            configCyto.cells = [
                tabsCell,
                titleCell
            ]
        } else {
            cyto.cells = [
                LimboCell(content: aexelsView, c: 0, r: 0, h: 3),
                titleCell,
                tabsCell,
                LimboCell(content: quickView, c: 1, r: 2)
            ]
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        aexelsView.play()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        aexelsView.stop()
    }
    
// TimeControlDelegate =============================================================================
    override func onPlay() { aexelsView.play() }
    override func onStep() { aexelsView.tic() }
    override func onReset() { initExperiment() }
    override func onStop() { aexelsView.stop() }
}
