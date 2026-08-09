//
//  HyleLabExplorer.swift
//  Aexels
//
//  The bridge, rendered as the static entity it is.  Fixed stage: the
//  nodes never move on screen; L/r shows as disc size.  Each node's
//  velocity is a vector on the node — pick it up and drag it.  Render
//  runs the actual simulator from far enough back that the corridor is
//  full when the nodes land on their stage positions at t = 0; the
//  plot then freezes: pings as cloud, pongs as the foam transport will
//  pass hyle through.
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

    private let foamLabel: UILabel = UILabel()
    private let pingLabel: UILabel = UILabel()
    private let caseLabel: UILabel = UILabel()
    private var readoutTimer: Timer?

    private var dragging: Int = -1   // -1 none, 0 = A, 1 = B

    override var experiment: Experiment? {
        didSet {
            guard experiment !== oldValue, let experiment: HyleExperiment = experiment as? HyleExperiment else { return }
            renderer.apply(experiment: experiment)
            controlsTab.sync()
            updateReadout()
            metalView.draw()
        }
    }

    init() {
        super.init(key: "hyleLab")
        experiments = HyleExperiment.experiments
    }

    func render() {
        renderer.generate()
        updateReadout()
        metalView.draw()
    }

    private func updateReadout() {
        guard let renderer else { return }
        foamLabel.text = String(format: "foam → A  %d      foam → B  %d", renderer.pongsToA, renderer.pongsToB)
        pingLabel.text = String(format: "pings in flight  %d", renderer.pingsInFlight)
        caseLabel.text = renderer.stateName + "   —   frozen at t=0"
    }

// Dragging the velocity vectors ===================================================================
    @objc private func onPan(_ gesture: UIPanGestureRecognizer) {
        let p: CGPoint = gesture.location(in: metalView)
        let point: SIMD2<Double> = SIMD2<Double>(Double(p.x), Double(p.y))
        switch gesture.state {
        case .began:
            let grab: Double = max(renderer.r * 1.3, 30)
            let dA: Double = simd_length(point - renderer.A0)
            let dB: Double = simd_length(point - renderer.B0)
            if dA < dB && dA < grab + 160 { dragging = 0 }
            else if dB <= dA && dB < grab + 160 { dragging = 1 }
            else { dragging = -1 }
        case .changed:
            guard dragging >= 0 else { return }
            let center: SIMD2<Double> = dragging == 0 ? renderer.A0 : renderer.B0
            var v: SIMD2<Double> = (point - center) / 160.0     // 160 pt of drag = 0.9c
            var beta: Double = simd_length(v) * 0.9
            if beta < 0.04 { v = .zero; beta = 0 }
            if beta > 0.9 { v = v * (0.9 / beta) * (beta / 0.9); beta = 0.9 }
            let unit: SIMD2<Double> = beta > 0 ? simd_normalize(v) : .zero
            if dragging == 0 { renderer.vA = unit * beta } else { renderer.vB = unit * beta }
            updateReadout()
            metalView.draw()
        default:
            dragging = -1
        }
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

        metalView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan(_:))))

        [foamLabel, pingLabel, caseLabel].forEach {
            $0.pen = Pen(font: UIFont.monospacedSystemFont(ofSize: 10*s, weight: .medium), color: UIColor(white: 1, alpha: 0.8))
            metalView.addSubview($0)
        }
        foamLabel.frame = CGRect(x: 10*s, y: 8*s, width: 380*s, height: 15*s)
        pingLabel.frame = CGRect(x: 10*s, y: 25*s, width: 380*s, height: 15*s)
        caseLabel.frame = CGRect(x: 10*s, y: 42*s, width: 380*s, height: 15*s)
        readoutTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.updateReadout() }

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
    // The frozen plot is the object; the coming transport phase owns
    // these controls (a step will be one transport event over the
    // foam, once that rule exists).
    override func onPlay()  { timeControl.playButton.stop() }
    override func onStep()  { }
    override func onReset() { render(); timeControl.playButton.stop() }
    override func onStop()  { }
}
