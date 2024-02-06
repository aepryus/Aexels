//
//  NexusExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/29/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import OoviumKit
import UIKit

class NexusExplorer: AEViewController {
    let cyto: Cyto = Cyto()
    let limbo: Limbo = ContentLimbo(content: UIView())
    let aexelsLabel: NexusLabel = NexusLabel(text: "Aexels", size: 72*Screen.s)
    let versionLabel: NexusLabel = NexusLabel(text: "v\(Aexels.version)", size:20*Screen.s)
    let glass: UIView = UIView()
    let scrollView: UIScrollView = UIScrollView()

    let messageLimbo: MessageLimbo = MessageLimbo()

    let aether: Aether = Aether()
    lazy var graph: Graph = aether.create(at: .zero)
    lazy var graphView: GraphView = {
        graph.surfaceOn = true
        graph.fXChain = Chain("va:Gp1.u")
        graph.fYChain = Chain("va:Gp1.v")
        graph.fZChain = Chain("fn:sin;va:Gp1.u;op:×;va:Gp1.v;op:+;va:Gp1.t;sp:);op:÷;dg:3")
//        graph.sUChain = Chain(natural: "-7")
//        graph.eUChain = Chain(natural: "7")
//        graph.dUChain = Chain(natural: "70")
//        graph.sVChain = Chain(natural: "-7")
//        graph.eVChain = Chain(natural: "7")
//        graph.dVChain = Chain(natural: "70")
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
//        graph.look = V3(-0.597824245607881, -0.542194458806552, -0.904535868587812)
        graph.surfaceOn = true

        let graphView = GraphView(graph: graph)
        graphView.alpha = 0.2
//        graphView.layer.shadowRadius = 2
//        graphView.layer.shadowOffset = CGSize(width: 2, height: 2)
//        graphView.layer.shadowOpacity = 0.8
        return graphView
    }()
    
    func showArticle(key: String) {
        dimNexus()
        messageLimbo.key = key
        messageLimbo.load()
        view.addSubview(messageLimbo)
    }
    
    func dimNexus() {
        UIView.animate(withDuration: 0.2) {
            self.aexelsLabel.alpha = 0.1
//            self.glass.alpha = 0
        }
    }
    func brightenNexus() {
        UIView.animate(withDuration: 0.2) {
            self.aexelsLabel.alpha = 1
            self.glass.alpha = 1
        }
    }
        
// Events ==========================================================================================
    @objc func onTouch(gesture: TouchingGesture) {
        if gesture.state == .began {
            UIView.animate(withDuration: 0.2) {
                self.versionLabel.alpha = 1
            }
        } else if gesture.state == .ended {
            UIView.animate(withDuration: 0.2) {
                self.versionLabel.alpha = 0
            }
        }
    }
        
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(graphView)
        
        if Screen.iPhone {
        } else {
            cyto.rows = 15
            cyto.cols = 3
            cyto.padding = 6*s
            
            let view: UIView = UIView()
            view.backgroundColor = .clear
//            view.backgroundColor = .blue.tone(0.5).alpha(0.5)
            
//                IntroExplorer(),
//                AetherExplorer(),
//                CellularExplorer(),
//                KinematicsExplorer(),
//                GravityExplorer(),
//                DilationExplorer(),
//                ContractionExplorer(),
//                DarknessExplorer(),
//                EquivalenceExplorer(),
//                ElectromagnetismExplorer(),
//                DiscrepancyExplorer(),
//                EpilogueExplorer()

            
            cyto.cells = [
                ArticleCell(key: "intro", c: 0, r: 0, w: 2),
                ArticleCell(key: "aether", c: 2, r: 0),
                ArticleCell(key: "cellular", c: 0, r: 1, w: 2),
                ExplorerCell(explorer: CellularExplorer(), c: 2, r: 1),
                ArticleCell(key: "kinematics", c: 0, r: 2),
                ExplorerCell(explorer: KinematicsExplorer(), c: 1, r: 2),
                ArticleCell(key: "gravity", c: 2, r: 2),
                ExplorerCell(explorer: AetherExplorer(), c: 2, r: 3),
                ArticleCell(key: "dilation", c: 0, r: 3),
                ExplorerCell(explorer: DilationExplorer(), c: 1, r: 3),
                ArticleCell(key: "contraction", c: 0, r: 4),
                ExplorerCell(explorer: ContractionExplorer(), c: 1, r: 4),
                ArticleCell(key: "darkness", c: 2, r: 4),
                ArticleCell(key: "equivalence", c: 0, r: 5),
                ArticleCell(key: "electromagnetism", c: 1, r: 5),
                ArticleCell(key: "discrepancy", c: 2, r: 5),
                ArticleCell(key: "epilogue", c: 1, r: 6),
            ]
        }
//        view.addSubview(cyto)
        
        glass.backgroundColor = .black.tint(0.8)
        glass.layer.cornerRadius = 8*s
        glass.layer.shadowRadius = 8*s
        glass.layer.shadowOffset = CGSize(width: 8*s, height: 8*s)
        glass.layer.shadowOpacity = 0.6
        glass.layer.borderColor = UIColor.white.shade(0.5).cgColor
        glass.layer.borderWidth = 1*s
        view.addSubview(glass)
        
        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(cyto)
        glass.addSubview(scrollView)
        
//        view.addSubview(limbo)
        
        view.addSubview(aexelsLabel)
        aexelsLabel.addGestureRecognizer(TouchingGesture(target: self, action: #selector(onTouch)))

        view.addSubview(versionLabel)
//        view.addSubview(messageLimbo)
    }
    override func layoutRatio056() {
        graph.view = V3(8.91167255619427, 8.2567481154179, 9.63093990157929)*0.39
        graphView.frame = view.bounds
    }
    override func layoutRatio133() {
        graphView.topLeft(dx: 510*s, dy: 10*s, width: 600*s, height: 800*s)
        
//        aexelsLabel.frame = CGRect(x: 16*s, y: 42*s, width: 300*s, height: 64*s)

        // Version
//        versionLabel.frame = CGRect(x: 16*s, y: 95*s, width: 300*s, height: 30*s)
        versionLabel.alpha = 0
        
        aexelsLabel.bottomRight(dx: -20*s, dy: -0*s, width: 300*s, height: 96*s)
        versionLabel.topLeft(dx: aexelsLabel.left-15*s, dy: aexelsLabel.top+62*s, width: 300*s, height: 30*s)


        
//        cyto.backgroundColor = .magenta.tone(0.5).alpha(0.4)
//        cyto.frame = CGRect(x: Screen.safeLeft+3, y: Screen.safeTop+3, width: view.width-(Screen.safeLeft+3)-3, height: view.height-(Screen.safeTop+3)-3-Screen.safeBottom)

        glass.left(dx: 16*s, dy: Screen.safeTop/2, width: 480*s, height: view.height-Screen.safeTop-Screen.safeBottom-32*s)
//        glass.layer.shadowPath = CGPath(roundedRect: glass.bounds, cornerWidth: 8*s, cornerHeight: 8*s, transform: nil)
        scrollView.frame = glass.bounds
        
        cyto.top(dy: 8*s, width: glass.width-16*s, height: 2000*s)
        cyto.layout()
        
        scrollView.contentSize = CGSize(width: glass.width, height: cyto.height+16*s)
        
        messageLimbo.left(dx: glass.right+20*s, dy: Screen.safeTop/2, width: view.width-glass.right-2*20*s, height: glass.height)

        limbo.topLeft(dx: 300, dy: 200, width: 400, height: 300)
    }
}
