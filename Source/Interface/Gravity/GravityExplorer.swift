//
//  GravityExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 8/16/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class GravityExplorer: Explorer, TimeControlDelegate {
    let cyto: Cyto = Cyto(rows: 3, cols: 2)

    // Title ======
    let titleView: UIView = UIView()
    let titleLabel: UILabel = UILabel()

    // Tabs =======
    let tabsCell: TabsCell = TabsCell(c: 1, r: 1)

    let controlsTab: TabsCellTab = TabsCellTab(name: "Controls".localized)
    let experimentsTab: TabsCellTab = TabsCellTab(name: "Experiments".localized)
    let notesTab: NotesTab = NotesTab(key: "gravity")
    
    // Quick ======
    let quickView: UIView = UIView()
    let timeControl: TimeControl = TimeControl()
    
    // Universe ===
    let engine: GravityEngine = GravityEngine(size: .zero)
    lazy var gravityView = GravityView(engine: engine)

    init() { super.init(key: "gravity") }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabsCell.tabs = [controlsTab, experimentsTab, notesTab]

        cyto.cells = [
            LimboCell(content: gravityView, c: 0, r: 0, h: 3),
            MaskCell(content: titleView, c: 1, r: 0, cutouts: [.upperRight]),
            tabsCell,
            LimboCell(content: quickView, c: 1, r: 2)
        ]
        view.addSubview(cyto)
        
        // Title ========
        titleLabel.text = "Gravity".localized
        titleLabel.pen = Pen(font: .optima(size: 20*s), color: .white, alignment: .center)
        titleView.addSubview(titleLabel)
        
        timeControl.playButton.playing = true
        timeControl.delegate = self
        quickView.addSubview(timeControl)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        engine.play()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        engine.stop()
    }

// AEViewController ================================================================================
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
        
        engine.size = gravityView.frame.size
    }
}
