//
//  HyleLabExplorer.swift
//  Aexels
//
//  Demo 0: the static pong bridge.  Two nodes; emit, fly, capture,
//  respond — nothing else.  The standing pong population between them
//  is the bridge: two directed cones, emerging rather than drawn.
//  Engine: Philippine sea; physics verified headless in Sims/PongBridge.
//

import Acheron
import MetalKit
import UIKit

class HyleLabExplorer: Explorer {
    private var metalView: MTKView!

    let notesTab: NotesTab = NotesTab(key: "hyleLab")
    var controlsTab: HyleControlsTab!
    private var experimentsTab: ExperimentsTab!

    var renderer: HyleRenderer!

    override var experiment: Experiment? {
        didSet {
            guard experiment !== oldValue, let experiment: HyleExperiment = experiment as? HyleExperiment else { return }
            renderer.apply(experiment: experiment)
            controlsTab.sync()
            updateStakes()
            metalView.draw()
        }
    }

    // The stake-setter's scoreboard: measured split vs (1 + cos chi)/2.
    private let stakeALabel: UILabel = UILabel()
    private let stakeBLabel: UILabel = UILabel()
    private let caseLabel: UILabel = UILabel()
    private var stakeTimer: Timer?

    init() {
        super.init(key: "hyleLab")
        experiments = HyleExperiment.experiments
    }

    private func updateStakes() {
        guard let renderer else { return }
        stakeALabel.text = String(format: "A-circuit   pings → B  %d   pongs → A  %d", renderer.connectingPingsA, renderer.pongsToA)
        stakeBLabel.text = String(format: "B-circuit   pings → A  %d   pongs → B  %d", renderer.connectingPingsB, renderer.pongsToB)
        caseLabel.text = renderer.stateName + "   —   the frozen bridge (transport clock)"
    }

// UIViewController ================================================================================
    override func viewDidLoad() {
        cyto = Screen.iPhone ? Cyto(rows: 2, cols: 1) : Cyto(rows: 3, cols: 2)
        view.addSubview(cyto)

        tabsCell = Screen.iPhone ? TabsCell(c: 0, r: 0) : TabsCell(c: 1, r: 1)

        super.viewDidLoad()

        metalView = MTKView(frame: view.bounds)
        metalView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        metalView.isOpaque = false

        renderer = HyleRenderer(view: metalView)
        controlsTab = HyleControlsTab(explorer: self)
        experimentsTab = ExperimentsTab(explorer: self)

        [stakeALabel, stakeBLabel, caseLabel].forEach {
            $0.pen = Pen(font: UIFont.monospacedSystemFont(ofSize: 10*s, weight: .medium), color: UIColor(white: 1, alpha: 0.8))
            metalView.addSubview($0)
        }
        stakeALabel.frame = CGRect(x: 10*s, y: 8*s, width: 380*s, height: 15*s)
        stakeBLabel.frame = CGRect(x: 10*s, y: 25*s, width: 380*s, height: 15*s)
        caseLabel.frame = CGRect(x: 10*s, y: 42*s, width: 380*s, height: 15*s)
        stakeTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in self?.updateStakes() }

        tabsCell.tabs = [controlsTab, experimentsTab, notesTab]

        if Screen.iPhone {
            cyto.cells = [
                LimboCell(content: metalView, c: 0, r: 0),
                MaskCell(content: quickView, c: 0, r: 1, cutouts: [.lowerLeft, .lowerRight])
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

        // The lab opens frozen: the bridge is a snapshot on the
        // transport clock.  Play opts into watching the c-clock.
        timeControl.playButton.playing = false
    }

// AEViewController ================================================================================
    override func layoutRatio046() {
        super.layoutRatio046()
        let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
        let uh: CGFloat = height - 80*s
        cyto.Ys = [uh]
        cyto.layout()
        timeControl.center(width: 114*s, height: 54*s)

        if experiment == nil { experiment = experiments[0] }
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

        if experiment == nil { experiment = experiments[0] }
    }

// TimeControlDelegate =============================================================================
    // The bridge is a static entity: there is nothing for the c-clock
    // to do on stage.  Play bounces back to stopped; Step is reserved
    // for the coming transport phase — a step will be one transport
    // event across the bridge, once that rule exists.
    override func onPlay()  { timeControl.playButton.stop() }
    override func onStep()  { }
    override func onReset() { renderer.loadUniverse(); metalView.draw(); timeControl.playButton.stop(); updateStakes() }
    override func onStop()  { }
}
