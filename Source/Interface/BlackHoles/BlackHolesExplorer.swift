//
//  BlackHolesExplorer.swift
//  Aexels
//
//  Explorer for the Black Holes lab. Phase 0 just hosts the metal
//  view and the notes tab; controls (mass slider, separation, later
//  viscosity for the Phase 1 inspiral) are added in subsequent phases.
//

import Acheron
import MetalKit

class BlackHolesExplorer: Explorer {
    private var metalView: MTKView!

    let notesTab: NotesTab = NotesTab(key: "blackHolesLab")
    var controlsTab: BlackHolesControlsTab!

    var renderer: BlackHolesRenderer!

    init() { super.init(key: "blackHolesLab") }

// UIViewController ================================================================================
    override func viewDidLoad() {
        cyto = Screen.iPhone ? Cyto(rows: 3, cols: 1) : Cyto(rows: 3, cols: 2)
        view.addSubview(cyto)

        tabsCell = Screen.iPhone ? TabsCell(c: 0, r: 0) : TabsCell(c: 1, r: 1)

        super.viewDidLoad()

        metalView = MTKView(frame: view.bounds)
        metalView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        metalView.isOpaque = false

        renderer = BlackHolesRenderer(view: metalView)
        controlsTab = BlackHolesControlsTab(explorer: self)

        tabsCell.tabs = [controlsTab, notesTab]

        if Screen.iPhone {
            cyto.cells = [
                LimboCell(c: 0, r: 0),
                LimboCell(content: metalView, c: 0, r: 1),
                MaskCell(content: quickView, c: 0, r: 2, cutouts: [.lowerLeft, .lowerRight])
            ]
            configCyto.cells = [
                tabsCell,
                titleCell
            ]
        } else {
            cyto.cells = [
                LimboCell(content: metalView, c: 0, r: 0, h: 3),
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
    override func onPlay()  { metalView.isPaused = false }
    override func onStep()  { metalView.draw() }
    override func onReset() { renderer.onReset(); metalView.draw(); timeControl.playButton.stop() }
    override func onStop()  { metalView.isPaused = true }
}
