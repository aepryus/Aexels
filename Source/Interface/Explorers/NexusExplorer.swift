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
    let glyphsView: GlyphsView = GlyphsView()
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
//        view.addSubview(glass)
        
        scrollView.showsVerticalScrollIndicator = false
//        scrollView.addSubview(glyphView)
//        glass.addSubview(scrollView)
        view.addSubview(scrollView)
        
        view.addSubview(aexelsLabel)
        aexelsLabel.addGestureRecognizer(TouchingGesture(target: self, action: #selector(onTouch)))
        
        let p: CGFloat = 3*s
        var y: CGFloat = 30*s
        var dy: CGFloat = 120*s
        
        let universeXGlyph: ArticleGlyph = ArticleGlyph(name: "Universe X", radius: 110*s+2*p)
        glyphsView.add(glyph: universeXGlyph)
        universeXGlyph.frame = CGRect(x: 30*s, y: y, width: universeXGlyph.radius, height: universeXGlyph.radius)
        y += dy

        let aetherGlyph: ArticleGlyph = ArticleGlyph(name: "Aether", radius: 80*s+2*p)
        glyphsView.add(glyph: aetherGlyph)
        aetherGlyph.frame = CGRect(x: 30*s, y: y, width: aetherGlyph.radius, height: aetherGlyph.radius)
        y += dy

        let cellularGlyph: ArticleGlyph = ArticleGlyph(name: "Cellular Automata", radius: 100*s+2*p)
        glyphsView.add(glyph: cellularGlyph)
        cellularGlyph.frame = CGRect(x: 30*s, y: y, width: cellularGlyph.radius, height: cellularGlyph.radius)
        y += dy

        let kinematicsGlyph: ArticleGlyph = ArticleGlyph(name: "Kinematics", radius: 110*s+2*p)
        glyphsView.add(glyph: kinematicsGlyph)
        kinematicsGlyph.frame = CGRect(x: 30*s, y: y, width: kinematicsGlyph.radius, height: kinematicsGlyph.radius)
        y += dy

        let gravityGlyph: ArticleGlyph = ArticleGlyph(name: "Gravity", radius: 90*s+2*p)
        glyphsView.add(glyph: gravityGlyph)
        gravityGlyph.frame = CGRect(x: 30*s, y: y, width: gravityGlyph.radius, height: gravityGlyph.radius)
        y += dy

        let dilationGlyph: ArticleGlyph = ArticleGlyph(name: "Dilation", radius: 100*s+2*p)
        glyphsView.add(glyph: dilationGlyph)
        dilationGlyph.frame = CGRect(x: 30*s, y: y, width: dilationGlyph.radius, height: dilationGlyph.radius)
        y += dy

        let contractionGlyph: ArticleGlyph = ArticleGlyph(name: "Contraction", radius: 120*s+2*p)
        glyphsView.add(glyph: contractionGlyph)
        contractionGlyph.frame = CGRect(x: 30*s, y: y, width: contractionGlyph.radius, height: contractionGlyph.radius)
        y += dy

        let darknessGlyph: ArticleGlyph = ArticleGlyph(name: "Darkness", radius: 120*s+2*p)
        glyphsView.add(glyph: darknessGlyph)
        darknessGlyph.frame = CGRect(x: 30*s, y: y, width: darknessGlyph.radius, height: darknessGlyph.radius)
        y += dy

        let equivalenceGlyph: ArticleGlyph = ArticleGlyph(name: "Equivalence", radius: 120*s+2*p)
        glyphsView.add(glyph: equivalenceGlyph)
        equivalenceGlyph.frame = CGRect(x: 30*s, y: y, width: equivalenceGlyph.radius, height: equivalenceGlyph.radius)
        y += dy

        let electromagnetismGlyph: ArticleGlyph = ArticleGlyph(name: "Electro Magnetism", radius: 110*s+2*p)
        glyphsView.add(glyph: electromagnetismGlyph)
        electromagnetismGlyph.frame = CGRect(x: 30*s, y: y, width: electromagnetismGlyph.radius, height: electromagnetismGlyph.radius)
        y += dy

        let discrepanciesGlyph: ArticleGlyph = ArticleGlyph(name: "Discrepancies", radius: 130*s+2*p)
        glyphsView.add(glyph: discrepanciesGlyph)
        discrepanciesGlyph.frame = CGRect(x: 30*s, y: y, width: discrepanciesGlyph.radius, height: discrepanciesGlyph.radius)
        y += dy

        let epilogueGlyph: ArticleGlyph = ArticleGlyph(name: "Epilogue", radius: 90*s+2*p)
        glyphsView.add(glyph: epilogueGlyph)
        epilogueGlyph.frame = CGRect(x: 30*s, y: y, width: epilogueGlyph.radius, height: epilogueGlyph.radius)
        y += dy


        y = 30*s
        let aetherExpGlyph: ExplorerGlyph = ExplorerGlyph(image: UIImage(named: "aether_icon")!, radius: 50*s+2*p)
        glyphsView.add(glyph: aetherExpGlyph)
        aetherExpGlyph.frame = CGRect(x: 30*s, y: y, width: aetherExpGlyph.radius, height: aetherExpGlyph.radius)
        y += dy

        let cellularExpGlyph: ExplorerGlyph = ExplorerGlyph(image: UIImage(named: "cellular_icon")!, radius: 50*s+2*p)
        glyphsView.add(glyph: cellularExpGlyph)
        cellularExpGlyph.frame = CGRect(x: 30*s, y: y, width: cellularExpGlyph.radius, height: cellularExpGlyph.radius)
        y += dy

        let kinematicsExpGlyph: ExplorerGlyph = ExplorerGlyph(image: UIImage(named: "kinematics_icon")!, radius: 50*s+2*p)
        glyphsView.add(glyph: kinematicsExpGlyph)
        kinematicsExpGlyph.frame = CGRect(x: 30*s, y: y, width: kinematicsExpGlyph.radius, height: kinematicsExpGlyph.radius)
        y += dy

        let dilationExpGlyph: ExplorerGlyph = ExplorerGlyph(image: UIImage(named: "dilation_icon")!, radius: 50*s+2*p)
        glyphsView.add(glyph: dilationExpGlyph)
        dilationExpGlyph.frame = CGRect(x: 30*s, y: y, width: dilationExpGlyph.radius, height: dilationExpGlyph.radius)
        y += dy

        let contractionExpGlyph: ExplorerGlyph = ExplorerGlyph(image: UIImage(named: "contraction_icon")!, radius: 50*s+2*p)
        glyphsView.add(glyph: contractionExpGlyph)
        contractionExpGlyph.frame = CGRect(x: 30*s, y: y, width: contractionExpGlyph.radius, height: contractionExpGlyph.radius)
        y += dy

        y = 30*s
        let blackHoleGlyph: AsideGlyph = AsideGlyph(name: "Black Holes", radius: 40*s+2*p)
        glyphsView.add(glyph: blackHoleGlyph)
        blackHoleGlyph.frame = CGRect(x: 30*s, y: y, width: blackHoleGlyph.radius, height: blackHoleGlyph.radius)
        y += dy
        
        let twinParadoxGlyph: AsideGlyph = AsideGlyph(name: "Twin Paradox", radius: 54*s+2*p)
        glyphsView.add(glyph: twinParadoxGlyph)
        twinParadoxGlyph.frame = CGRect(x: 30*s, y: y, width: twinParadoxGlyph.radius, height: twinParadoxGlyph.radius)
        y += dy

        let narwhalGlyph: AsideGlyph = AsideGlyph(name: "Narwhal, Walrus and Dolphin", radius: 60*s+2*p)
        glyphsView.add(glyph: narwhalGlyph)
        narwhalGlyph.frame = CGRect(x: 30*s, y: y, width: narwhalGlyph.radius, height: narwhalGlyph.radius)
        y += dy

        let symetricGlyph: AsideGlyph = AsideGlyph(name: "Symetric Frames", radius: 54*s+2*p)
        glyphsView.add(glyph: symetricGlyph)
        symetricGlyph.frame = CGRect(x: 30*s, y: y, width: symetricGlyph.radius, height: symetricGlyph.radius)
        y += dy

        let blackShieldGlyph: AsideGlyph = AsideGlyph(name: "Black Shield", radius: 46*s+2*p)
        glyphsView.add(glyph: blackShieldGlyph)
        blackShieldGlyph.frame = CGRect(x: 30*s, y: y, width: blackShieldGlyph.radius, height: blackShieldGlyph.radius)
        y += dy

        let quantumBellGlyph: AsideGlyph = AsideGlyph(name: "Quantum and Bell", radius: 60*s+2*p)
        glyphsView.add(glyph: quantumBellGlyph)
        quantumBellGlyph.frame = CGRect(x: 30*s, y: y, width: quantumBellGlyph.radius, height: quantumBellGlyph.radius)
        y += dy
                
        scrollView.addSubview(glyphsView)
        
        universeXGlyph.link(to: aetherGlyph)
        
        aetherGlyph.link(to: cellularGlyph)
        aetherGlyph.link(to: aetherExpGlyph)
        
        cellularGlyph.link(to: kinematicsGlyph)
        cellularGlyph.link(to: cellularExpGlyph)
        
        kinematicsGlyph.link(to: gravityGlyph)
        kinematicsGlyph.link(to: kinematicsExpGlyph)
        
        gravityGlyph.link(to: dilationGlyph)
        gravityGlyph.link(to: blackHoleGlyph)
        
        dilationGlyph.link(to: contractionGlyph)
        dilationGlyph.link(to: dilationExpGlyph)
        dilationGlyph.link(to: twinParadoxGlyph)
        
        contractionGlyph.link(to: darknessGlyph)
        contractionGlyph.link(to: contractionExpGlyph)
        contractionGlyph.link(to: narwhalGlyph)
        
        darknessGlyph.link(to: equivalenceGlyph)
        
        equivalenceGlyph.link(to: electromagnetismGlyph)
        
        discrepanciesGlyph.link(to: epilogueGlyph)
        discrepanciesGlyph.link(to: symetricGlyph)
        discrepanciesGlyph.link(to: blackShieldGlyph)
        discrepanciesGlyph.link(to: quantumBellGlyph)

        view.addSubview(versionLabel)
//        view.addSubview(messageLimbo)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        messageLimbo.removeFromSuperview()
        brightenNexus()
    }
    
    override func layoutRatio056() {
    }
    override func layoutRatio133() {
        
        versionLabel.alpha = 0
        
        aexelsLabel.bottomRight(dx: -20*s, dy: -0*s, width: 300*s, height: 96*s)
        versionLabel.topLeft(dx: aexelsLabel.left-15*s, dy: aexelsLabel.top+62*s, width: 300*s, height: 30*s)


        
        glass.left(dx: 16*s, dy: Screen.safeTop/2, width: 480*s, height: view.height-Screen.safeTop-Screen.safeBottom-32*s)
        glyphsView.frame = CGRect(x: 20*s, y: Screen.safeTop+20*s, width: 700, height: 2000)
//        glass.layer.shadowPath = CGPath(roundedRect: glass.bounds, cornerWidth: 8*s, cornerHeight: 8*s, transform: nil)
        scrollView.frame = CGRect(x: 20*s, y: Screen.safeTop, width: 700, height: view.height-Screen.safeTop-Screen.safeBottom)
        
        cyto.top(dy: 8*s, width: glass.width-16*s, height: 2000*s)
        cyto.layout()
        
        scrollView.contentSize = glyphsView.frame.size
        
        messageLimbo.left(dx: glass.right+20*s, dy: Screen.safeTop/2, width: view.width-glass.right-2*20*s, height: glass.height)
    }
}
