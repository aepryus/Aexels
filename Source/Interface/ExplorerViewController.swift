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
    
    lazy var graphView: GraphView = {
        let graphView = GraphView(graph: GraphView.graphInstance())
        graphView.alpha = 0.2
        return graphView
    }()
    
    var explorer: AEViewController? = nil {
        didSet {
            guard explorer != oldValue else { return }
            if oldValue is NexusExplorer {
                graphView.stop()
                stopMusic()
            }
            UIView.animate(withDuration: 0.5) {
                oldValue?.view.alpha = 0
            } completion: { (complete: Bool) in
                if let nexusExplorer: NexusExplorer = self.explorer as? NexusExplorer {
                    nexusExplorer.articleView.removeFromSuperview()
                    nexusExplorer.currentCapsule.removeFromSuperview()
                    nexusExplorer.articleView.alpha = 0
                    nexusExplorer.currentCapsule.alpha = 0
                    nexusExplorer.interchange.alpha = 0
                    nexusExplorer.snapGlyphs()
                    self.graphView.start()
                    DispatchQueue.main.async { self.startMusic() }
                }
                if let oldValue { oldValue.view.removeFromSuperview() }

                guard let explorer = self.explorer else { return }
                explorer.view.alpha = 0
                explorer.view.frame = self.view.bounds
                
                if let explorer: Explorer = explorer as? Explorer {
                    self.visionBar.select(vision: explorer.vision)
                    self.view.addSubview(explorer.view)
                } else {
                    self.view.addSubview(explorer.view)
                }
                self.view.bringSubviewToFront(self.tripWire)
                self.view.bringSubviewToFront(self.visionBar)

                UIView.animate(withDuration: 0.5) { explorer.view.alpha = 1 }
            }

        }
    }
    
    lazy var visionBar: VisionBar = {
        let visions: [[Vision?]] = [
            [
                ExplorerVision(explorer: Aexels.nexusExplorer),
                Aexels.aetherExplorer.vision,
                Aexels.cellularExplorer.vision,
                Aexels.kinematicsExplorer.vision,
                Aexels.distanceExplorer.vision,
                Aexels.gravityExplorer.vision,
                Aexels.dilationExplorer.vision,
                Aexels.contractionExplorer.vision
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
        let a: CGFloat = 0.8
        graphView.bottomRight(dx: -10*s, dy: -10*s, width: 600*s*a, height: 800*s*a)
        visionBar.topRight(dx: -5*s, dy: Screen.safeTop+(Screen.mac ? 5*s : 0))
    }
}
