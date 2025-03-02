//
//  GravityExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 8/16/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import MetalKit
import UIKit

class GravityExplorer: Explorer {
    // Tabs =======
    let controlsTab: TabsCellTab = TabsCellTab(name: "Controls".localized)
    let experimentsTab: TabsCellTab = TabsCellTab(name: "Experiments".localized)
    let notesTab: NotesTab = NotesTab(key: "gravity")
    
    // Universe ===
    private var gravityMetal: MTKView!
    var renderer: GravityRenderer!

    init() { super.init(key: "gravity") }
    
// Events ==========================================================================================
    @objc func onTap(_ gesture: UITapGestureRecognizer) {
        let point: CGPoint = gesture.location(in: gravityMetal) - CGPoint(x: gravityMetal.width/2, y: gravityMetal.height/2)
        let ring: UnsafeMutablePointer<MCRing>? = MCUniverseRingAt(renderer.universe, CV2(x: point.x, y: point.y))
        if let ring { MCUniverseSetFocusRing(renderer.universe, ring) }
    }
    @objc func onDoubleTap(_ gesture: UITapGestureRecognizer) {
        let point: CGPoint = gesture.location(in: gravityMetal) - CGPoint(x: gravityMetal.width/2, y: gravityMetal.height/2)
        MCUniverseCreateMoon(renderer.universe, point.x, point.y, 1, 1, 10)
    }

// UIViewController ================================================================================
    override func viewDidLoad() {
        cyto = Screen.iPhone ? Cyto(rows: 3, cols: 1) : Cyto(rows: 3, cols: 2)
        view.addSubview(cyto)
        
        tabsCell = Screen.iPhone ? TabsCell(c: 0, r: 0) : TabsCell(c: 1, r: 1)

        super.viewDidLoad()
        
        gravityMetal = MTKView(frame: view.bounds)
        gravityMetal.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        gravityMetal.isOpaque = false
        gravityMetal.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap(_:)))
        gesture.numberOfTapsRequired = 2
        gravityMetal.addGestureRecognizer(gesture)

        renderer = GravityRenderer(view: gravityMetal)

        tabsCell.tabs = [controlsTab, experimentsTab, notesTab]

        if Screen.iPhone {
            cyto.cells = [
                LimboCell(c: 0, r: 0),
                LimboCell(content: gravityMetal, c: 0, r: 1),
                MaskCell(content: quickView, c: 0, r: 2, cutouts: [.lowerLeft, .lowerRight])
            ]
            configCyto.cells = [
                tabsCell,
                titleCell
            ]
        } else {
            cyto.cells = [
                LimboCell(content: gravityMetal, c: 0, r: 0, h: 3),
                titleCell,
                tabsCell,
                LimboCell(content: quickView, c: 1, r: 2)
            ]
        }
    }

// AEViewController ================================================================================
    override func layoutRatio046() {
        super.layoutRatio046()

        let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
        let uh: CGFloat = height - 80*s
        let uw: CGFloat = view.width-10*s

        cyto.Ys = [uh-uw, uw]
        cyto.layout()
        
        timeControl.center(width: 114*s, height: 54*s)
    }
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
    }
    
// TimeControlDelegate =============================================================================
    override func onPlay() {
        gravityMetal.isPaused = false
    }
    override func onStep() {
        gravityMetal.draw()
    }
    override func onReset() {
        renderer.onReset()
        gravityMetal.draw()
        timeControl.playButton.stop()
    }
    override func onStop() {
        gravityMetal.isPaused = true
    }
}
