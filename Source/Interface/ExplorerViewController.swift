//
//  ExplorerViewController.swift
//  Aexels
//
//  Created by Joe Charlier on 1/29/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import AVFoundation
import OoviumEngine
import OoviumKit
import UIKit

class ExplorerViewController: UIViewController {
    let imageView: UIImageView = UIImageView(image: UIImage(named: "OldBack"))
    
    let aether: Aether = Aether()
    lazy var graph: Graph = aether.create(at: .zero)
    lazy var graphView: GraphView = {
        graph.surfaceOn = true
        graph.fXChain = Chain("va:Gp1.u")
        graph.fYChain = Chain("va:Gp1.v")
        graph.fZChain = Chain("fn:sin;va:Gp1.u;op:×;va:Gp1.v;op:+;va:Gp1.t;sp:);op:÷;dg:3")
        graph.sUChain = Chain(natural: "-4")
        graph.eUChain = Chain(natural: "4")
        graph.dUChain = Chain(natural: "40")
        graph.sVChain = Chain(natural: "-4")
        graph.eVChain = Chain(natural: "4")
        graph.dVChain = Chain(natural: "40")
        graph.onLoad()
        aether.onLoad()

        let net: CGFloat = 0.0
        let light: CGFloat = 0.8
        let surface: CGFloat = 0.2
        graph.netColor = RGB(r: net, g: net, b: net)
        graph.lightColor = RGB(r: light, g: light, b: light)
        graph.surfaceColor = RGB(r: surface, g: surface, b: surface)
        graph.surfaceOn = true
        graph.sU = graph.sUChain.tower.value
        graph.eU = graph.eUChain.tower.value
        let stepsU: Double = graph.dUChain.tower.value
        graph.dU = (graph.eU-graph.sU)/stepsU
        graph.sV = graph.sVChain.tower.value
        graph.eV = graph.eVChain.tower.value
        let stepsV: Double = graph.dVChain.tower.value
        graph.dV = (graph.eV-graph.sV)/stepsV
        graph.t = graph.tChain.tower.value
        graph.surfaceOn = true

        let graphView = GraphView(graph: graph)
        graphView.alpha = 0.2
        return graphView
    }()
    
    var explorer: AEViewController? = nil {
        didSet {
            guard explorer != oldValue else { return }
            if let nexusExplorer: NexusExplorer = explorer as? NexusExplorer {
                nexusExplorer.articleView.removeFromSuperview()
                nexusExplorer.navigator.removeFromSuperview()
                nexusExplorer.articleView.alpha = 0
                nexusExplorer.navigator.alpha = 0
                nexusExplorer.showGlyphs()
                graphView.timer.start()
                DispatchQueue.main.async { self.startMusic() }
            } else if oldValue is NexusExplorer {
                graphView.timer.stop()
                stopMusic()
            }

            if let oldValue { oldValue.view.removeFromSuperview() }

            guard let explorer else { return }
            explorer.view.alpha = 0
            explorer.view.frame = view.bounds
            
            if let explorer: Explorer = explorer as? Explorer {
                explorer.view.alpha = 1
                view.addSubview(explorer.view)
            } else {
                view.addSubview(explorer.view)
                UIView.animate(withDuration: 0.2) { explorer.view.alpha = 1 }
            }
//            visionBar.select(vision: visionB)
            view.bringSubviewToFront(tripWire)
            view.bringSubviewToFront(visionBar)
        }
    }
    
    lazy var visionBar: VisionBar = {
        let visions: [[Vision?]] = [
            [
                ExplorerVision(explorer: Aexels.nexusExplorer),
                ExplorerVision(explorer: Aexels.aetherExplorer),
                ExplorerVision(explorer: Aexels.cellularExplorer),
                ExplorerVision(explorer: Aexels.kinematicsExplorer),
                ExplorerVision(explorer: Aexels.dilationExplorer),
                ExplorerVision(explorer: Aexels.contractionExplorer)
            ]
        ]
        let visionBox: VisionBox = VisionBox(visions: visions)
        let visionBar: VisionBar = VisionBar(visionBox: visionBox)
        return visionBar
    }()
    
    lazy var tripWire: TripWire = TripWire() { self.visionBar.contract() }
    
    func initMusic() {
        guard let url: URL = Bundle.main.url(forResource: "Aexels3", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            player?.numberOfLoops = -1
            player?.volume = 0
        }
        catch { print("startMusic ERROR: \(error)") }
    }
    
    var player: AVAudioPlayer?
    var musicOn: Bool = false
    var timer: Timer? = nil
    private func rampVolume() {
        guard let player else { return }
        if timer == nil {
            if !player.isPlaying { player.play() }
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { (timer: Timer) in
                guard let player = self.player else { return }
                if self.musicOn { player.volume += 0.05 }
                else { player.volume -= 0.05 }
                if player.volume >= 1 || player.volume <= 0 {
                    timer.invalidate()
                    self.timer = nil
                }
                if player.volume <= 0 { player.stop() }
            }
        }
    }
    func startMusic() {
        musicOn = true
        rampVolume()
    }
    func stopMusic() {
        musicOn = false
        rampVolume()
    }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        view.addSubview(graphView)
        view.addSubview(tripWire)
        view.addSubview(visionBar)
        visionBar.topRight(dx: -5*s, dy: Screen.safeTop+5*s)

        explorer = Aexels.nexusExplorer
        
        initMusic()
        startMusic()
    }
    override func viewWillLayoutSubviews() {
        imageView.frame = view.bounds
        tripWire.frame = view.bounds
        graphView.topLeft(dx: 510*s, dy: 10*s, width: 600*s, height: 800*s)
        visionBar.topRight(dx: -5*s, dy: Screen.safeTop+(Screen.mac ? 5*s : 0))
    }
}
