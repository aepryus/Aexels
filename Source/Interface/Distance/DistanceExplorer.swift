//
//  DistanceExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 2/17/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import MetalKit
import UIKit

class DistanceExplorer: Explorer, TimeControlDelegate {
    let cyto: Cyto = Cyto(rows: 3, cols: 2)

    // Title ======
    let titleView: UIView = UIView()
    let titleLabel: UILabel = UILabel()

    // Tabs =======
    let tabsCell: TabsCell = TabsCell(c: 1, r: 1)

    let controlsTab: TabsCellTab = TabsCellTab(name: "Controls".localized)
    let experimentsTab: TabsCellTab = TabsCellTab(name: "Experiments".localized)
    let notesTab: NotesTab = NotesTab(key: "distance")
    
    // Quick ======
    let quickView: UIView = UIView()
    let timeControl: TimeControl = TimeControl()
    
    init() { super.init(key: "distance") }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabsCell.tabs = [controlsTab, experimentsTab, notesTab]

        cyto.cells = [
            LimboCell(c: 0, r: 0, h: 3),
            MaskCell(content: titleView, c: 1, r: 0, cutout: true),
            tabsCell,
            LimboCell(content: quickView, c: 1, r: 2)
        ]
        view.addSubview(cyto)
        
        // Title ========
        titleLabel.text = "Distance and Radius".localized
        titleLabel.pen = Pen(font: .optima(size: 20*s), color: .white, alignment: .center)
        titleView.addSubview(titleLabel)
        
        timeControl.playButton.playing = true
        timeControl.delegate = self
        quickView.addSubview(timeControl)
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
    }
}
