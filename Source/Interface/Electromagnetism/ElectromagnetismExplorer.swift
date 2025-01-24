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
    
    private var metalView: MTKView!
    let titleView: UIView = UIView()
    let experimentView: UIView = UIView()
    let controlsView: UIView = UIView()

    // Metal ======
    private var renderer: ElectromagnetismRenderer!

    // Title ======
    let titleLabel: UILabel = UILabel()
    
    // Controls ===
    let timeControl: TimeControl = TimeControl()
    let pingButton: PulseButton = PulseButton(name: "ping")

    private var parametersTab: ParametersTab!
    let zoomsTab: TabsCellTab = TabsCellTab(name: "Zooms".localized)
    let experimentsTab: TabsCellTab = TabsCellTab(name: "Experiments".localized)
    let notesTab: NotesTab = NotesTab(key: "electromagnetism")


    init() { super.init(key: "electromagnetism") }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        metalView = MTKView(frame: CGRect(origin: .zero, size: CGSize(width: 1001.1350788249184, height: 1001.1350788249184)))
        metalView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        metalView.isOpaque = false
        view.addSubview(metalView)
        
        renderer = ElectromagnetismRenderer(metalView: metalView)
        parametersTab = ParametersTab(renderer: renderer)
        
        let tabsCell: TabsCell = TabsCell(c: 1, r: 1, h: 2)
        tabsCell.tabs = [parametersTab, zoomsTab, experimentsTab, notesTab]

        cyto.cells = [
            LimboCell(content: metalView, c: 0, r: 0, h: 4),
            MaskCell(content: titleView, c: 1, r: 0, cutout: true),
            tabsCell,
            LimboCell(content: controlsView, c: 1, r: 3),
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
        metalView.isPaused = false
    }
    func onStep() {
        metalView.draw()
    }
    func onReset() {
        renderer.onReset()
        metalView.draw()
        timeControl.playButton.stop()
    }
    func onStop() {
        metalView.isPaused = true
    }
}
