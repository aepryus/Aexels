//
//  ExplorerViewController.swift
//  Aexels
//
//  Created by Joe Charlier on 1/29/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
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
    
    var explorer: AEViewController? = nil {
        didSet {
            if let nexusExplorer: NexusExplorer = oldValue as? NexusExplorer {
                graphView.timer.stop()
                nexusExplorer.view.removeFromSuperview()
            }
            
            guard let explorer else { return }
            explorer.view.alpha = 0
            explorer.view.frame = view.bounds
            
            if let explorer: Explorer = explorer as? Explorer {
                explorer.openExplorer(view: view)
                explorer.view.alpha = 1
                view.addSubview(explorer.view)
            } else {
                view.addSubview(explorer.view)
                UIView.animate(withDuration: 0.2) { explorer.view.alpha = 1 }
            }            
        }
    }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        view.addSubview(graphView)
        
        explorer = NexusExplorer()
    }
    override func viewWillLayoutSubviews() {
        imageView.frame = view.bounds
        graphView.topLeft(dx: 510*s, dy: 10*s, width: 600*s, height: 800*s)
    }
}
