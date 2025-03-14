//
//  InsideOutExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 2/17/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import MetalKit
import UIKit

class InsideOutExplorer: Explorer {

    // Tabs =======
    let notesTab: NotesTab = NotesTab(key: "insideOut")
    let sliceBoolButton: BoolButton = BoolButton(name: "Slice")
    
    let cylinderView: CylinderView = CylinderView()
    
    init() { super.init(key: "insideOut") }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        cyto = Screen.iPhone ? Cyto(rows: 2, cols: 1) : Cyto(rows: 3, cols: 2)
        view.addSubview(cyto)
        
        tabsCell = Screen.iPhone ? TabsCell(c: 0, r: 0) : TabsCell(c: 1, r: 1)

        super.viewDidLoad()
        
        tabsCell.tabs = [notesTab]

        if Screen.iPhone {
            cyto.cells = [
                LimboCell(content: cylinderView, c: 0, r: 0),
                MaskCell(content: quickView, c: 0, r: 1, cutouts: [.lowerLeft, .lowerRight])
            ]
            configCyto.cells = [
                tabsCell,
                titleCell
            ]
        } else {
            cyto.cells = [
                LimboCell(content: cylinderView, c: 0, r: 0, h: 3),
                titleCell,
                tabsCell,
                LimboCell(content: quickView, c: 1, r: 2)
            ]
        }
        
        quickView.addSubview(sliceBoolButton)
        sliceBoolButton.onChange =  { (on: Bool) in
            self.cylinderView.sliceOn = !self.cylinderView.sliceOn
            self.cylinderView.setNeedsDisplay()
        }
        
        Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
            self.cylinderView.drainCylinders()
            complete()
        }
        Aexels.sync.link.preferredFramesPerSecond = 3
        
        timeControl.playButton.playing = false
    }

// AEViewController ================================================================================
//    override func layoutRatio046() {
//        super.layoutRatio046()
//    }
    override func layoutRatio143() {
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
        
        sliceBoolButton.left(dx: 200*s, width: 240*s, height: 24*s)
    }
    
// TimeControlDelegate =============================================================================
    override func onPlay() {
        Aexels.sync.start()
    }
    override func onStep() {
        cylinderView.drainCylinders()
    }
    override func onReset() {
        cylinderView.resetCylinders()
    }
    override func onStop() {
        Aexels.sync.stop()
    }
}
