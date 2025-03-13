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

class ExplorerViewController: AEViewController {
    let imageView: UIImageView = UIImageView(image: UIImage(named: "OldBack"))
    
    lazy var graphView: GraphView = {
        let graphView = GraphView(graph: GraphView.graphInstance())
        graphView.alpha = 0.2
        return graphView
    }()
    let aexelsLabel: NexusLabel = NexusLabel(text: "Aexels", size: 48*Screen.s)
    let versionLabel: NexusLabel = NexusLabel(text: "v\(Aexels.version)", size:16*Screen.s)
    var iPhoneTabGesture: UITapGestureRecognizer!
    
    var explorer: AEViewController? = nil {
        didSet {
            if explorer == oldValue {
                guard let nexusExplorer: NexusExplorer = self.explorer as? NexusExplorer else { return }
                if Screen.iPhone {
                    UIView.animate(withDuration: 0.5) {
                        nexusExplorer.articleView.alpha = 0
                        nexusExplorer.currentCapsule.alpha = 0
                    } completion: { (complete: Bool) in
                        nexusExplorer.articleView.removeFromSuperview()
                        nexusExplorer.currentCapsule.removeFromSuperview()
                        nexusExplorer.glyphsView.alpha = 0
                        nexusExplorer.glyphsScroll.contentOffset = nexusExplorer.glyphsOffset
                        UIView.animate(withDuration: 0.5) {
                            self.visionBar.alpha = 1
                            nexusExplorer.snapGlyphs()
                        }
                    }
                } else {
                    UIView.animate(withDuration: 0.5) {
                        nexusExplorer.view.alpha = 0
                    } completion: { (complete: Bool) in
                        self.visionBar.alwaysExpanded = true
                        self.visionBar.expand()
                        nexusExplorer.articleView.removeFromSuperview()
                        nexusExplorer.currentCapsule.removeFromSuperview()
                        nexusExplorer.articleView.alpha = 0
                        nexusExplorer.currentCapsule.alpha = 0
                        nexusExplorer.snapGlyphs()
                        self.graphView.start()
                        DispatchQueue.main.async { self.startMusic() }
                        UIView.animate(withDuration: 0.5) { nexusExplorer.view.alpha = 1 }
                    }
                }
                return
            }
            if oldValue is NexusExplorer {
                visionBar.alwaysExpanded = false
                self.visionBar.contract()
                graphView.stop()
                stopMusic()
            }
            UIView.animate(withDuration: 0.5) {
                if Screen.iPhone && oldValue is NexusExplorer { self.visionBar.alpha = 0 }
                oldValue?.view.alpha = 0
            } completion: { (complete: Bool) in
                if let nexusExplorer: NexusExplorer = self.explorer as? NexusExplorer {
                    if !Screen.iPhone {
                        self.visionBar.alwaysExpanded = true
                        self.visionBar.expand()
                    } else {
                        if oldValue == nil {
                            self.visionBar.alpha = 0
                            self.view.addSubview(self.visionBar)
                            self.visionBar.topRight(dx: -5*self.s, dy: Screen.safeTop+5*self.s)
                        }
                        self.visionBar.snap(to: Aexels.nexusExplorer.vision)
                    }
                    nexusExplorer.articleView.removeFromSuperview()
                    nexusExplorer.currentCapsule.removeFromSuperview()
                    nexusExplorer.articleView.alpha = 0
                    nexusExplorer.currentCapsule.alpha = 0
                    nexusExplorer.contextGlyphsView.alpha = 0
                    nexusExplorer.snapGlyphs()
                    if !Screen.iPhone { self.graphView.start() }
                    if !Screen.iPhone { DispatchQueue.main.async { self.startMusic() } }
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

                UIView.animate(withDuration: 0.5) {
                    if Screen.iPhone && explorer is NexusExplorer { self.visionBar.alpha = 1 }
                    explorer.view.alpha = 1
                }
            }
        }
    }
    
    lazy var visionBar: VisionBar = {
        let visions: [[Vision?]] = [
            [
                Aexels.nexusExplorer.vision,
                Aexels.aetherExplorer.vision,
                Aexels.cellularExplorer.vision,
                Aexels.kinematicsExplorer.vision,
                Aexels.distanceExplorer.vision,
                Aexels.gravityExplorer.vision,
                Aexels.dilationExplorer.vision,
                Aexels.contractionExplorer.vision,
                Aexels.electromagnetismExplorer.vision
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
                if self.musicOn { player.volume += 0.02 }
                else { player.volume -= 0.02 }
                if (self.musicOn && player.volume >= 0.2) || (!self.musicOn && player.volume <= 0) {
                    timer.invalidate()
                    self.timer = nil
                }
                if player.volume <= 0 { player.stop() }
            }
        }
    }
    func startMusic() {
        guard Aexels.settings.musicOn else { return }
        musicOn = true
        rampVolume()
    }
    func stopMusic() {
        guard Aexels.settings.musicOn else { return }
        musicOn = false
        rampVolume()
    }
    
// Events ==========================================================================================
    var graphOn: Bool = false
    @objc func onTap() {
        view.removeGestureRecognizer(iPhoneTabGesture)
        stopMusic()
        UIView.animate(withDuration: 1.0) {
            self.aexelsLabel.alpha = 0
            self.versionLabel.alpha = 0
        } completion: { (complete: Bool) in
            self.graphView.stop()
            self.aexelsLabel.removeFromSuperview()
            self.versionLabel.removeFromSuperview()
            self.explorer = Aexels.nexusExplorer
        }
    }
    
// AEViewController ================================================================================
    override func layoutRatio046() {
        imageView.frame = view.bounds
        tripWire.frame = view.bounds
        let a: CGFloat = 0.7
        graphView.bottom(dy: -50*s, width: 600*s*a, height: 800*s*a)
        aexelsLabel.topLeft(dx: 20*s, dy: 140*s, width: 200*s, height: 96*s)
        versionLabel.topLeft(dx: aexelsLabel.left-15*s, dy: aexelsLabel.top+42*s, width: 200*s, height: 30*s)
        visionBar.topRight(dx: -5*s, dy: Screen.safeTop+(Screen.mac ? 5*s : 0))
    }
    override func layoutRatio143() {
        imageView.frame = view.bounds
        tripWire.frame = view.bounds
        let a: CGFloat = 0.7
        graphView.bottomRight(dx: -30*s, dy: -10*s, width: 600*s*a, height: 800*s*a)
        aexelsLabel.bottomRight(dx: -30*s, dy: -0*s, width: 300*s, height: 96*s)
        versionLabel.topLeft(dx: aexelsLabel.left-15*s, dy: aexelsLabel.top+42*s, width: 300*s, height: 30*s)
        visionBar.topRight(dx: -5*s, dy: Screen.safeTop+(Screen.mac ? 5*s : 0))
    }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(imageView)
        view.addSubview(graphView)
        view.addSubview(aexelsLabel)
        view.addSubview(versionLabel)
        view.addSubview(tripWire)
        

        if !Screen.iPhone {
            view.addSubview(visionBar)
            visionBar.topRight(dx: -5*s, dy: Screen.safeTop+5*s)
            explorer = Aexels.nexusExplorer
        }

        graphView.start()
        
        initMusic()
        startMusic()
        
        layout()
        
        if Screen.iPhone {
            iPhoneTabGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
            view.addGestureRecognizer(iPhoneTabGesture)
        } else {
            UIView.animate(withDuration: 3, delay: 5) {
                self.aexelsLabel.alpha = 0
                self.versionLabel.alpha = 0
            }
        }
    }
}
