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
    let aexelsLabel: NexusLabel = NexusLabel(text: "Aexels", size: 72*Screen.s)
    let versionLabel: NexusLabel = NexusLabel(text: "v\(Aexels.version)", size:20*Screen.s)
    let scrollView: UIScrollView = UIScrollView()
    let glyphsView: GlyphsView = GlyphsView()
    let articleView: ArticleView = ArticleView()
    let navigator: ArticleNavigator = ArticleNavigator()

    func showArticle(key: String) {
        articleView.key = key
        UIView.animate(withDuration: 0.5) {
            self.glyphsView.alpha = 0
        } completion: { (complete: Bool) in
            self.glyphsView.removeFromSuperview()
            self.articleView.alpha = 0
            self.scrollView.contentSize = self.articleView.scrollViewContentSize
            self.scrollView.contentOffset = .zero
            self.scrollView.addSubview(self.articleView)
            UIView.animate(withDuration: 0.5) {
                self.articleView.alpha = 1
            }
        }
    }
    
    func showGlyphs() {
        articleView.removeFromSuperview()
        articleView.alpha = 0
        glyphsView.alpha = 1
        scrollView.addSubview(glyphsView)
        scrollView.contentSize = glyphsView.frame.size
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
                
        view.addSubview(aexelsLabel)
        aexelsLabel.addGestureRecognizer(TouchingGesture(target: self, action: #selector(onTouch)))
        
        versionLabel.alpha = 0
        view.addSubview(versionLabel)

        let p: CGFloat = 3*s
        
        let universeXGlyph: ArticleGlyph = ArticleGlyph(key: "intro", radius: 110*s+2*p, x: 70*s, y: 30*s)
        let aetherGlyph: ArticleGlyph = ArticleGlyph(key: "aether", radius: 80*s+2*p, x: 50*s, y: 180*s)
        let cellularGlyph: ArticleGlyph = ArticleGlyph(key: "cellular", radius: 100*s+2*p, x: 230*s, y: 330*s)
        let kinematicsGlyph: ArticleGlyph = ArticleGlyph(key: "kinematics", radius: 110*s+2*p, x: 30*s, y: 480*s)
        let gravityGlyph: ArticleGlyph = ArticleGlyph(key: "gravity", radius: 90*s+2*p, x: 200*s, y: 630*s)
        let dilationGlyph: ArticleGlyph = ArticleGlyph(key: "dilation", radius: 100*s+2*p, x: 30*s, y: 780*s)
        let contractionGlyph: ArticleGlyph = ArticleGlyph(key: "contraction", radius: 120*s+2*p, x: 30*s, y: 930*s)
        let darknessGlyph: ArticleGlyph = ArticleGlyph(key: "darkness", radius: 120*s+2*p, x: 250*s, y: 1130*s)
        let equivalenceGlyph: ArticleGlyph = ArticleGlyph(key: "equivalence", radius: 120*s+2*p, x: 230*s, y: 1400*s)
        let electromagnetismGlyph: ArticleGlyph = ArticleGlyph(key: "electromagnetism", radius: 110*s+2*p, x: 30*s, y: 1240*s)
        let discrepanciesGlyph: ArticleGlyph = ArticleGlyph(key: "discrepancy", radius: 130*s+2*p, x: 30*s, y: 1530*s)
        let epilogueGlyph: ArticleGlyph = ArticleGlyph(key: "epilogue", radius: 90*s+2*p, x: 200*s, y: 2000*s)

        let aetherExpGlyph: ExplorerGlyph = ExplorerGlyph(image: UIImage(named: "aether_icon")!, radius: 50*s+2*p, x: 230*s, y: 70*s)
        let cellularExpGlyph: ExplorerGlyph = ExplorerGlyph(image: UIImage(named: "cellular_icon")!, radius: 50*s+2*p, x: 400*s, y: 300*s)
        let kinematicsExpGlyph: ExplorerGlyph = ExplorerGlyph(image: UIImage(named: "kinematics_icon")!, radius: 50*s+2*p, x: 230*s, y: 530*s)
        let dilationExpGlyph: ExplorerGlyph = ExplorerGlyph(image: UIImage(named: "dilation_icon")!, radius: 50*s+2*p, x: 230*s, y: 800*s)
        let contractionExpGlyph: ExplorerGlyph = ExplorerGlyph(image: UIImage(named: "contraction_icon")!, radius: 50*s+2*p, x: 90*s, y: 1100*s)

        let blackHoleGlyph: AsideGlyph = AsideGlyph(name: "Black Holes", radius: 40*s+2*p, x: 370*s, y: 700*s)
        let twinParadoxGlyph: AsideGlyph = AsideGlyph(name: "Twin Paradox", radius: 54*s+2*p, x: 70*s, y: 630*s)
        let narwhalGlyph: AsideGlyph = AsideGlyph(name: "Narwhal, Walrus and Dolphin", radius: 60*s+2*p, x: 190*s, y: 930*s)
        let symetricGlyph: AsideGlyph = AsideGlyph(name: "Symetric Frames", radius: 54*s+2*p, x: 330*s, y: 1600*s)
        let blackShieldGlyph: AsideGlyph = AsideGlyph(name: "Black Shield", radius: 46*s+2*p, x: 380*s, y: 1700*s)
        let quantumBellGlyph: AsideGlyph = AsideGlyph(name: "Quantum and Bell", radius: 60*s+2*p, x: 280*s, y: 1800*s)

        glyphsView.add(glyph: universeXGlyph)
        glyphsView.add(glyph: aetherGlyph)
        glyphsView.add(glyph: cellularGlyph)
        glyphsView.add(glyph: kinematicsGlyph)
        glyphsView.add(glyph: gravityGlyph)
        glyphsView.add(glyph: dilationGlyph)
        glyphsView.add(glyph: contractionGlyph)
        glyphsView.add(glyph: darknessGlyph)
        glyphsView.add(glyph: equivalenceGlyph)
        glyphsView.add(glyph: electromagnetismGlyph)
        glyphsView.add(glyph: discrepanciesGlyph)
        glyphsView.add(glyph: epilogueGlyph)

        glyphsView.add(glyph: aetherExpGlyph)
        glyphsView.add(glyph: cellularExpGlyph)
        glyphsView.add(glyph: kinematicsExpGlyph)
        glyphsView.add(glyph: dilationExpGlyph)
        glyphsView.add(glyph: contractionExpGlyph)

        glyphsView.add(glyph: blackHoleGlyph)
        glyphsView.add(glyph: twinParadoxGlyph)
        glyphsView.add(glyph: narwhalGlyph)
        glyphsView.add(glyph: symetricGlyph)
        glyphsView.add(glyph: blackShieldGlyph)
        glyphsView.add(glyph: quantumBellGlyph)

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
        
        electromagnetismGlyph.link(to: discrepanciesGlyph)
        
        discrepanciesGlyph.link(to: epilogueGlyph)
        discrepanciesGlyph.link(to: symetricGlyph)
        discrepanciesGlyph.link(to: blackShieldGlyph)
        discrepanciesGlyph.link(to: quantumBellGlyph)
        
        scrollView.addSubview(glyphsView)
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        articleView.scrollView = scrollView
        
        navigator.transform = CGAffineTransform(rotationAngle: -.pi/2)
        view.addSubview(navigator)
        navigator.topLeft(width: 32*s, height: navigator.width)
        
        navigator.tokens = ["Gravity", "Universe X", "◎"]
    }
    
    override func layoutRatio056() {
    }
    override func layoutRatio133() {
        aexelsLabel.bottomRight(dx: -20*s, dy: -0*s, width: 300*s, height: 96*s)
        versionLabel.topLeft(dx: aexelsLabel.left-15*s, dy: aexelsLabel.top+62*s, width: 300*s, height: 30*s)
        glyphsView.frame = CGRect(x: 20*s, y: Screen.safeTop+20*s, width: 700, height: 3000)
        articleView.frame = glyphsView.frame
        scrollView.frame = CGRect(x: 20*s, y: Screen.safeTop, width: 700, height: view.height-Screen.safeTop-Screen.safeBottom)
        if glyphsView.superview != nil {
            scrollView.contentSize = glyphsView.frame.size
        }
        navigator.topLeft(dx: 5*s, dy: 340*s, width: 32*s, height: navigator.width)
    }
}
