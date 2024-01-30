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

class NexusExplorer: Explorer {
    let graphView: GraphView
    
    let aether: Aether
    let graph: Graph
    
    init() {
        
        aether = Aether()
        graph = aether.create(at: .zero)
        graph.surfaceOn = true
        graph.fXChain = Chain("va:Gp1.u")
        graph.fYChain = Chain("va:Gp1.v")
        graph.fZChain = Chain("fn:sin;va:Gp1.u;op:×;va:Gp1.v;op:+;va:Gp1.t;sp:);op:÷;dg:3")
        graph.sUChain = Chain(natural: "-7")
        graph.eUChain = Chain(natural: "7")
        graph.dUChain = Chain(natural: "70")
        graph.sVChain = Chain(natural: "-7")
        graph.eVChain = Chain(natural: "7")
        graph.dVChain = Chain(natural: "70")
        graph.onLoad()
        aether.onLoad()

        let grey: CGFloat = 0.0
        graph.netColor = RGB(r: grey, g: grey, b: grey)
        graph.sU = graph.sUChain.tower.value
        graph.eU = graph.eUChain.tower.value
        let stepsU: Double = graph.dUChain.tower.value
        graph.dU = (graph.eU-graph.sU)/stepsU
        graph.sV = graph.sVChain.tower.value
        graph.eV = graph.eVChain.tower.value
        let stepsV: Double = graph.dVChain.tower.value
        graph.dV = (graph.eV-graph.sV)/stepsV
        graph.t = graph.tChain.tower.value
        graph.look = V3(-0.597824245607881, -0.542194458806552, -0.904535868587812)

        graphView = GraphView(graph: graph)
        graphView.alpha = 0.3
        
        super.init(name: "", key: "", canExplore: false)
    }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(graphView)
    }
    override func viewWillLayoutSubviews() {
        graphView.frame = view.bounds
    }
}
