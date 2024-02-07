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
    let cyto: Cyto = Cyto(rows: 15, cols: 3)
    let aexelsLabel: NexusLabel = NexusLabel(text: "Aexels", size: 72*Screen.s)
    let versionLabel: NexusLabel = NexusLabel(text: "v\(Aexels.version)", size:20*Screen.s)
    let glass: UIView = UIView()
    let scrollView: UIScrollView = UIScrollView()

    let messageLimbo: MessageLimbo = MessageLimbo()

    
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
        
        if Screen.iPhone {
        } else {
            cyto.rows = 15
            cyto.cols = 3
            cyto.padding = 6*s
            
            let view: UIView = UIView()
            view.backgroundColor = .clear
            
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
        
        view.addSubview(aexelsLabel)
        aexelsLabel.addGestureRecognizer(TouchingGesture(target: self, action: #selector(onTouch)))

        view.addSubview(versionLabel)
//        view.addSubview(messageLimbo)
    }
    
    override func layoutRatio056() {
    }
    override func layoutRatio133() {
        
        versionLabel.alpha = 0
        
        aexelsLabel.bottomRight(dx: -20*s, dy: -0*s, width: 300*s, height: 96*s)
        versionLabel.topLeft(dx: aexelsLabel.left-15*s, dy: aexelsLabel.top+62*s, width: 300*s, height: 30*s)


        
        glass.left(dx: 16*s, dy: Screen.safeTop/2, width: 480*s, height: view.height-Screen.safeTop-Screen.safeBottom-32*s)
//        glass.layer.shadowPath = CGPath(roundedRect: glass.bounds, cornerWidth: 8*s, cornerHeight: 8*s, transform: nil)
        scrollView.frame = glass.bounds
        
        cyto.top(dy: 8*s, width: glass.width-16*s, height: 2000*s)
        cyto.layout()
        
        scrollView.contentSize = CGSize(width: glass.width, height: cyto.height+16*s)
        
        messageLimbo.left(dx: glass.right+20*s, dy: Screen.safeTop/2, width: view.width-glass.right-2*20*s, height: glass.height)
    }
}
