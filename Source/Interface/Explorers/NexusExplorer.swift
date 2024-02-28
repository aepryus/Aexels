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
    let interchange: Interchange = Interchange()
    var currentCapsule: ArticleCapsule = ArticleCapsule("◎", article: Article(key: ""))

    func show(article: Article) {
        guard article.key != articleView.key else { return }
        if interchange.superview == nil { view.addSubview(interchange) }
        if currentCapsule.superview == nil { view.addSubview(currentCapsule) }
        UIView.animate(withDuration: 0.5) {
            self.glyphsView.alpha = 0
            self.currentCapsule.alpha = 0
            self.articleView.alpha = 0
            self.interchange.alpha = 0
        } completion: { (complete: Bool) in
            self.articleView.key = article.key
            self.currentCapsule.article = article
            self.interchange.article = article
            self.glyphsView.removeFromSuperview()
            self.scrollView.contentSize = self.articleView.scrollViewContentSize
            self.scrollView.contentOffset = .zero
            self.scrollView.addSubview(self.articleView)
            UIView.animate(withDuration: 0.5) {
                self.articleView.alpha = 1
                self.currentCapsule.alpha = 1
                self.interchange.alpha = 1
            }
        }
    }
    
    func showGlyphs() {
        glyphsView.alpha = 0
        scrollView.addSubview(glyphsView)
        
        UIView.animate(withDuration: 0.5) {
            self.currentCapsule.alpha = 0
            self.interchange.alpha = 0
            self.articleView.alpha = 0
        } completion: { (complete: Bool) in
            self.articleView.removeFromSuperview()
            self.currentCapsule.removeFromSuperview()
            self.interchange.removeFromSuperview()
            self.articleView.key = nil
            self.scrollView.contentSize = self.glyphsView.frame.size
            self.scrollView.contentOffset = .zero
            self.scrollView.addSubview(self.articleView)
            UIView.animate(withDuration: 0.5) {
                self.glyphsView.alpha = 1
            }
        }

    }
    func snapGlyphs() {
        articleView.removeFromSuperview()
        currentCapsule.removeFromSuperview()
        interchange.removeFromSuperview()
        scrollView.addSubview(glyphsView)
        articleView.key = nil
        scrollView.contentSize = self.glyphsView.frame.size
        scrollView.contentOffset = .zero
        scrollView.addSubview(self.articleView)
        glyphsView.alpha = 1
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
        
        let universeXGlyph: ArticleGlyph = ArticleGlyph(article: Article.intro, radius: 110*s+2*p, x: 70*s, y: 30*s)
        let aetherGlyph: ArticleGlyph = ArticleGlyph(article: Article.aether, radius: 80*s+2*p, x: 50*s, y: 180*s)
        let cellularGlyph: ArticleGlyph = ArticleGlyph(article: Article.cellular, radius: 100*s+2*p, x: 230*s, y: 330*s)
        let kinematicsGlyph: ArticleGlyph = ArticleGlyph(article: Article.kinematics, radius: 110*s+2*p, x: 30*s, y: 480*s)
        let gravityGlyph: ArticleGlyph = ArticleGlyph(article: Article.gravity, radius: 90*s+2*p, x: 200*s, y: 630*s)
        let dilationGlyph: ArticleGlyph = ArticleGlyph(article: Article.dilation, radius: 100*s+2*p, x: 30*s, y: 780*s)
        let contractionGlyph: ArticleGlyph = ArticleGlyph(article: Article.contraction, radius: 120*s+2*p, x: 30*s, y: 930*s)
        let darknessGlyph: ArticleGlyph = ArticleGlyph(article: Article.darkness, radius: 120*s+2*p, x: 250*s, y: 1130*s)
        let equivalenceGlyph: ArticleGlyph = ArticleGlyph(article: Article.equivalence, radius: 120*s+2*p, x: 230*s, y: 1400*s)
        let electromagnetismGlyph: ArticleGlyph = ArticleGlyph(article: Article.electromagnetism, radius: 110*s+2*p, x: 30*s, y: 1240*s)
        let discrepanciesGlyph: ArticleGlyph = ArticleGlyph(article: Article.discrepancy, radius: 130*s+2*p, x: 30*s, y: 1530*s)
        let epilogueGlyph: ArticleGlyph = ArticleGlyph(article: Article.epilogue, radius: 90*s+2*p, x: 200*s, y: 2000*s)

        let aetherExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.aetherExplorer, radius: 50*s+2*p, x: 75*s, y: 315*s)
        let cellularExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.cellularExplorer, radius: 50*s+2*p, x: 400*s, y: 300*s)
        let kinematicsExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.kinematicsExplorer, radius: 50*s+2*p, x: 230*s, y: 530*s)
        let distanceExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.distanceExplorer, radius: 50*s+2*p, x: 320*s, y: 600*s)
        let gravityExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.gravityExplorer, radius: 50*s+2*p, x: 380*s, y: 670*s)
        let dilationExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.dilationExplorer, radius: 50*s+2*p, x: 230*s, y: 800*s)
        let contractionExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.contractionExplorer, radius: 50*s+2*p, x: 90*s, y: 1100*s)

        let forwardGlyph: AsideGlyph = AsideGlyph(article: Article.forward, radius: 56*s+2*p, x: 270*s, y: 90*s)
        let blackHoleGlyph: AsideGlyph = AsideGlyph(article: Article.blackHole, radius: 40*s+2*p, x: 350*s, y: 770*s)
        let twinParadoxGlyph: AsideGlyph = AsideGlyph(article: Article.twinParadox, radius: 54*s+2*p, x: 70*s, y: 630*s)
        let narwhalGlyph: AsideGlyph = AsideGlyph(article: Article.narwhal, radius: 60*s+2*p, x: 190*s, y: 930*s)
        let symetricGlyph: AsideGlyph = AsideGlyph(article: Article.symmetric, radius: 64*s+2*p, x: 330*s, y: 1600*s)
        let blackShieldGlyph: AsideGlyph = AsideGlyph(article: Article.blackShield, radius: 46*s+2*p, x: 380*s, y: 1700*s)
        let quantumBellGlyph: AsideGlyph = AsideGlyph(article: Article.quantumBell, radius: 60*s+2*p, x: 280*s, y: 1800*s)

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
        glyphsView.add(glyph: distanceExpGlyph)
        glyphsView.add(glyph: gravityExpGlyph)
        glyphsView.add(glyph: dilationExpGlyph)
        glyphsView.add(glyph: contractionExpGlyph)

        glyphsView.add(glyph: forwardGlyph)
        glyphsView.add(glyph: blackHoleGlyph)
        glyphsView.add(glyph: twinParadoxGlyph)
        glyphsView.add(glyph: narwhalGlyph)
        glyphsView.add(glyph: symetricGlyph)
        glyphsView.add(glyph: blackShieldGlyph)
        glyphsView.add(glyph: quantumBellGlyph)

        universeXGlyph.link(to: aetherGlyph)
        universeXGlyph.link(to: forwardGlyph)
        
        aetherGlyph.link(to: cellularGlyph)
        aetherGlyph.link(to: aetherExpGlyph)

        cellularGlyph.link(to: kinematicsGlyph)
        cellularGlyph.link(to: cellularExpGlyph)
        
        kinematicsGlyph.link(to: gravityGlyph)
        kinematicsGlyph.link(to: kinematicsExpGlyph)
        
        gravityGlyph.link(to: dilationGlyph)
        gravityGlyph.link(to: distanceExpGlyph)
        gravityGlyph.link(to: gravityExpGlyph)
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
        
        currentCapsule.transform = CGAffineTransform(rotationAngle: -.pi/2)
        view.addSubview(currentCapsule)
        
        view.addSubview(interchange)
    }
    
    override func layoutRatio056() {}
    override func layoutRatio133() {
        aexelsLabel.bottomRight(dx: -20*s, dy: -0*s, width: 300*s, height: 96*s)
        versionLabel.topLeft(dx: aexelsLabel.left-15*s, dy: aexelsLabel.top+62*s, width: 300*s, height: 30*s)
        glyphsView.frame = CGRect(x: 50*s, y: 20*s, width: 510*s, height: 2187*s)
        scrollView.frame = CGRect(x: 34*s, y: Screen.mac ? Screen.safeTop: 0, width: 570*s, height: view.height-(Screen.mac ? Screen.safeTop+Screen.safeBottom : 0))
        if glyphsView.superview != nil { scrollView.contentSize = glyphsView.frame.size }
        currentCapsule.render()
        currentCapsule.topLeft(dx: 10*s, dy: Screen.safeTop+19*s)
        interchange.topLeft(dx: 600*s, dy: Screen.safeTop+15*s, width: 360*s, height: 240*s)
    }
}
