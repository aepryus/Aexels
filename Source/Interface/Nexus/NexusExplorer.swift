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
    let scrollView: UIScrollView = UIScrollView()
    let glyphsView: GlyphsView = GlyphsView()
    let articleView: ArticleView = ArticleView()
    var currentCapsule: ArticleCapsule = ArticleCapsule("◎", article: Article(key: ""))
    var contextGlyphsView: GlyphsView = GlyphsView()
    
    let articleCell: MaskCell
    let cyto: Cyto = Cyto(rows: 1, cols: 1)

    let musicButton: ImageButton = ImageButton(named: "music")
    let claudeButton: ClaudeButton = ClaudeButton()
    let claudeCircle: CircleButton
    let claudeHover: UIView = UIView()
    let glyphsCircle: CircleButton

    var glyphs: [GlyphView] = []
    var glyphsOffset: CGPoint = .zero
    
    lazy var vision: Vision = ExplorerVision(explorer: Aexels.nexusExplorer)
    
    override init() {
        claudeCircle = CircleButton(view: claudeButton)
        
        let imageView: UIImageView = UIImageView(image: UIImage(named: "glyphs_icon")!)
        imageView.bounds = CGRect(origin: .zero, size: CGSize(width: 30*Screen.s, height: 30*Screen.s))
        glyphsCircle = CircleButton(view: imageView)
        glyphsCircle.addAction {
            Aexels.explorerViewController.explorer = Aexels.nexusExplorer
        }
        
        articleCell = MaskCell(content: scrollView, c: 0, r: 0, cutouts: [.lowerLeft, .lowerRight, .upperRight])

        super.init()
    }

    func show(article: Article) {
        if !Screen.iPhone {
            guard article.key != articleView.key else { return }
            if contextGlyphsView.superview == nil {
                self.contextGlyphsView.alpha = 0
                view.addSubview(contextGlyphsView)
            }
            if currentCapsule.superview == nil { view.addSubview(currentCapsule) }
            UIView.animate(withDuration: 0.5) {
                self.musicButton.alpha = 0
                self.glyphsView.alpha = 0
                self.currentCapsule.alpha = 0
                self.articleView.alpha = 0
                self.contextGlyphsView.alpha = 0
            } completion: { (complete: Bool) in
                self.contextGlyphsView.setFocus(key: "\(article.parent == nil ? "art" : "asd")::\(article.key)")
                self.articleView.key = article.key
                self.claudeButton.article = article
                self.currentCapsule.article = article
                self.musicButton.removeFromSuperview()
                self.glyphsView.removeFromSuperview()
                self.scrollView.contentSize = self.articleView.scrollViewContentSize
                self.scrollView.addSubview(self.articleView)
                self.scrollView.contentOffset = CGPoint(x: 0, y: Screen.iPhone ? 0 : -1000)
                UIView.animate(withDuration: 0.5) {
                    self.articleView.alpha = 1
                    self.currentCapsule.alpha = 1
                    self.contextGlyphsView.alpha = 1
                }
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.glyphsView.alpha = 0
                self.articleView.alpha = 0
            } completion: { (complete: Bool) in
                self.articleView.key = article.key
                self.claudeButton.article = article
                self.glyphsView.removeFromSuperview()
                self.scrollView.contentSize = self.articleView.scrollViewContentSize
                self.scrollView.addSubview(self.articleView)
                self.scrollView.contentOffset = CGPoint(x: 0, y: Screen.iPhone ? 0 : -1000)
                UIView.animate(withDuration: 0.5) {
                    self.articleView.alpha = 1
                }
            }
        }
    }
    
    func showGlyphs() {
        claudeButton.article = nil

        musicButton.alpha = 0
        claudeButton.alpha = 0
        glyphsView.alpha = 0
        if !Screen.iPhone {
            view.addSubview(musicButton)
            view.addSubview(claudeButton)
        }
        scrollView.addSubview(glyphsView)
        
        UIView.animate(withDuration: 0.5) {
            self.currentCapsule.alpha = 0
            self.contextGlyphsView.alpha = 0
            self.articleView.alpha = 0
        } completion: { (complete: Bool) in
            self.articleView.removeFromSuperview()
            self.currentCapsule.removeFromSuperview()
            self.articleView.key = nil
            self.scrollView.contentSize = self.glyphsView.frame.size
            self.scrollView.contentOffset = self.glyphsOffset
            self.scrollView.addSubview(self.articleView)
            UIView.animate(withDuration: 0.5) {
                self.musicButton.alpha = 1
                self.claudeButton.alpha = 1
                self.glyphsView.alpha = 1
            }
        }
    }
    func snapGlyphs() {
        claudeButton.article = nil

        articleView.removeFromSuperview()
        currentCapsule.removeFromSuperview()
        contextGlyphsView.removeFromSuperview()
        
        if !Screen.iPhone {
            view.addSubview(musicButton)
            view.addSubview(claudeButton)
        }
        scrollView.addSubview(glyphsView)
        articleView.key = nil
        scrollView.contentSize = self.glyphsView.frame.size
        scrollView.contentOffset = self.glyphsOffset
        scrollView.addSubview(self.articleView)
        musicButton.alpha = 1
        claudeButton.alpha = 1
        glyphsView.alpha = 1
    }
    
    func defineGlyphs() -> [GlyphView] {
        let p: CGFloat = 3*s
        
        let universeXGlyph: ArticleGlyph = ArticleGlyph(article: Article.intro, radius: 112*s+2*p, x: 70*s, y: 30*s)
        let aetherGlyph: ArticleGlyph = ArticleGlyph(article: Article.aether, radius: 82*s+2*p, x: 50*s, y: 180*s)
        let cellularGlyph: ArticleGlyph = ArticleGlyph(article: Article.cellular, radius: 102*s+2*p, x: 230*s, y: 330*s)
        let kinematicsGlyph: ArticleGlyph = ArticleGlyph(article: Article.kinematics, radius: 112*s+2*p, x: 30*s, y: 480*s)
        let gravityGlyph: ArticleGlyph = ArticleGlyph(article: Article.gravity, radius: 90*s+2*p, x: 200*s, y: 630*s)
        let darknessGlyph: ArticleGlyph = ArticleGlyph(article: Article.darkness, radius: 110*s+2*p, x: 80*s, y: 760*s)
        let hyleGlyph: ArticleGlyph = ArticleGlyph(article: .hyle, radius: 72*s+2*p, x: 280*s, y: 860*s)
        let dilationGlyph: ArticleGlyph = ArticleGlyph(article: Article.dilation, radius: 100*s+2*p, x: 260*s, y: 1040*s)
        let contractionGlyph: ArticleGlyph = ArticleGlyph(article: Article.contraction, radius: 110*s+2*p, x: 100*s, y: 1000*s)
        let electromagnetismGlyph: ArticleGlyph = ArticleGlyph(article: Article.electromagnetism, radius: 116*s+2*p, x: 210*s, y: 1290*s)
        let bellTHooftGlyph: ArticleGlyph = ArticleGlyph(article: Article.bellTHooft, radius: 102*s+2*p, x: 50*s, y: 1430*s)
        let epilogueGlyph: ArticleGlyph = ArticleGlyph(article: Article.epilogue, radius: 96*s+2*p, x: 270*s, y: 1580*s)

        let aetherExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.aetherExplorer, radius: 50*s+2*p, x: 75*s, y: 315*s)
        let cellularExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.cellularExplorer, radius: 50*s+2*p, x: 400*s, y: 300*s)
        let kinematicsExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.kinematicsExplorer, radius: 50*s+2*p, x: 230*s, y: 530*s)
        let distanceExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.distanceExplorer, radius: 50*s+2*p, x: 320*s, y: 600*s)
        let gravityExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.gravityExplorer, radius: 50*s+2*p, x: 380*s, y: 670*s)
        let dilationExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.dilationExplorer, radius: 50*s+2*p, x: 380*s, y: 960*s)
        let contractionExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.contractionExplorer, radius: 50*s+2*p, x: 30*s, y: 920*s)
        let electromagnetismExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.electromagnetismExplorer, radius: 50*s+2*p, x: 380*s, y: 1420*s)

        let forwardGlyph: AsideGlyph = AsideGlyph(article: Article.forward, radius: 56*s+2*p, x: 270*s, y: 90*s)
        let claudeGlyph: AsideGlyph = AsideGlyph(article: Article.claude, radius: 56*s+2*p, x: 200*s, y: 150*s)
        let blackHoleGlyph: AsideGlyph = AsideGlyph(article: Article.blackHole, radius: 40*s+2*p, x: 350*s, y: 770*s)
        let chronosGlyph: AsideGlyph = AsideGlyph(article: Article.chronos, radius: 60*s+2*p, x: 400*s, y: 1110*s)
        let floatingLeafGlyph: AsideGlyph = AsideGlyph(article: .floatingLeaf, radius: 62*s, x: 350*s, y: 1180*s)
        let fourClocksGlyph: AsideGlyph = AsideGlyph(article: Article.fourClocks, radius: 46*s+2*p, x: 280*s, y: 1210*s)
        let narwhalGlyph: AsideGlyph = AsideGlyph(article: Article.narwhal, radius: 70*s+2*p, x: 30*s, y: 1140*s)
        let thooftGlyph: AsideGlyph = AsideGlyph(article: Article.thooft, radius: 60*s, x: 110*s, y: 1570*s)
        let glossaryGlyph: AsideGlyph = AsideGlyph(article: Article.glossary, radius: 60*s+2*p, x: 240*s, y: 1710*s)

        var glyphs: [GlyphView] = []
        
        glyphs.append(universeXGlyph)
        glyphs.append(aetherGlyph)
        glyphs.append(cellularGlyph)
        glyphs.append(kinematicsGlyph)
        glyphs.append(gravityGlyph)
        glyphs.append(darknessGlyph)
        glyphs.append(hyleGlyph)
        glyphs.append(dilationGlyph)
        glyphs.append(contractionGlyph)
        glyphs.append(electromagnetismGlyph)
        glyphs.append(bellTHooftGlyph)
        glyphs.append(epilogueGlyph)

        glyphs.append(aetherExpGlyph)
        glyphs.append(cellularExpGlyph)
        glyphs.append(kinematicsExpGlyph)
        glyphs.append(distanceExpGlyph)
        glyphs.append(gravityExpGlyph)
        glyphs.append(dilationExpGlyph)
        glyphs.append(contractionExpGlyph)
        glyphs.append(electromagnetismExpGlyph)

        glyphs.append(forwardGlyph)
        glyphs.append(claudeGlyph)
        glyphs.append(blackHoleGlyph)
        glyphs.append(chronosGlyph)
        glyphs.append(floatingLeafGlyph)
        glyphs.append(fourClocksGlyph)
        glyphs.append(narwhalGlyph)
        glyphs.append(thooftGlyph)
        glyphs.append(glossaryGlyph)

        universeXGlyph.link(to: aetherGlyph)
        universeXGlyph.link(to: forwardGlyph)
        universeXGlyph.link(to: claudeGlyph)
        
        aetherGlyph.link(to: cellularGlyph)
        aetherGlyph.link(to: aetherExpGlyph)

        cellularGlyph.link(to: kinematicsGlyph)
        cellularGlyph.link(to: cellularExpGlyph)
        
        kinematicsGlyph.link(to: gravityGlyph)
        kinematicsGlyph.link(to: kinematicsExpGlyph)
        
        gravityGlyph.link(to: darknessGlyph)
        gravityGlyph.link(to: distanceExpGlyph)
        gravityGlyph.link(to: gravityExpGlyph)
        gravityGlyph.link(to: blackHoleGlyph)
        
        darknessGlyph.link(to: hyleGlyph)
        
        hyleGlyph.link(to: dilationGlyph)
        
        dilationGlyph.link(to: contractionGlyph)
        dilationGlyph.link(to: dilationExpGlyph)
        dilationGlyph.link(to: chronosGlyph)
        dilationGlyph.link(to: floatingLeafGlyph)
        dilationGlyph.link(to: fourClocksGlyph)

        contractionGlyph.link(to: electromagnetismGlyph)
        contractionGlyph.link(to: contractionExpGlyph)
        contractionGlyph.link(to: narwhalGlyph)
        
        electromagnetismGlyph.link(to: electromagnetismExpGlyph)
        electromagnetismGlyph.link(to: bellTHooftGlyph)
        
        bellTHooftGlyph.link(to: epilogueGlyph)
        bellTHooftGlyph.link(to: thooftGlyph)
        
        epilogueGlyph.link(to: glossaryGlyph)
        
        contractionGlyph.contract = true
        
        return glyphs
    }

// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        if Screen.iPhone { glyphsView.scale = 0.78 }
        glyphsView.glyphs = defineGlyphs()
        glyphsView.focus = nil
        glyphsView.onTapGlyph = { (glyphView: GlyphView) in
            if self.glyphsView.alpha == 1 { self.glyphsOffset = self.scrollView.contentOffset }
            glyphView.execute()
        }
        
        contextGlyphsView.scale = 0.7
        contextGlyphsView.glyphs = defineGlyphs()
        contextGlyphsView.onTapGlyph = { (glyphView: GlyphView) in
            glyphView.execute()
        }

        scrollView.addSubview(glyphsView)
        scrollView.showsVerticalScrollIndicator = false
        if !Screen.iPhone { view.addSubview(scrollView) }
        if !Screen.iPhone { articleView.maxWidth = min(Screen.width - 500, 800) }
        else { articleView.maxWidth = Screen.width-30*s }
        articleView.scrollView = scrollView

        if !Screen.iPhone { view.addSubview(contextGlyphsView) }
        
        currentCapsule.transform = CGAffineTransform(rotationAngle: -.pi/2)
        view.addSubview(currentCapsule)
        
        if !Screen.iPhone {
            view.addSubview(musicButton)
            musicButton.addAction {
                Loom.transact { Aexels.settings.musicOn = !Aexels.settings.musicOn }
                if Aexels.settings.musicOn { Aexels.explorerViewController.startMusic() }
                else { Aexels.explorerViewController.stopMusic() }
            }
        }
        
        if Screen.iPhone {
            articleView.font = UIFont(name: "Verdana", size: 18*s)!
            articleView.color = .white

            cyto.cells = [articleCell]
            view.addSubview(cyto)

            claudeButton.flashView = claudeHover
            claudeHover.layer.backgroundColor = UIColor.black.tint(0.15).cgColor
            claudeHover.layer.cornerRadius = 25*s
            claudeHover.layer.borderWidth = 2*s
            claudeHover.layer.borderColor = UIColor.white.cgColor
            view.addSubview(claudeCircle)
            
            claudeHover.alpha = 0
            view.addSubview(claudeHover)
            
            let label: UILabel = UILabel()
            label.text = "copied to discuss with Claude"
            label.pen = Pen(font: .optima(size: Screen.iPhone ? 16*Screen.s : 12*Screen.s), color: .black.tint(0.9), alignment: .center)
            claudeHover.addSubview(label)
            claudeHover.bounds = CGRect(origin: .zero, size: CGSize(width: 250*s, height: 75*s))
            label.center(width: claudeHover.width * 0.9, height: 17*s)
            
            view.addSubview(glyphsCircle)
        } else {
            view.addSubview(claudeButton)
        }
    }
    
    override func layoutRatio046() {
        cyto.frame = CGRect(x: 5*s, y: safeTop, width: view.width-10*s, height: Screen.height - Screen.safeTop - Screen.safeBottom)
        cyto.layout()

        glyphsView.frame = CGRect(x: 0*s, y: 20*s, width: Screen.iPhone ? articleCell.width-10*s : 510*s, height: Screen.iPhone ? 1640*s : 2187*s)
        articleView.frame = CGRect(x: 10*s, y: 5*s, width: scrollView.width-20*s, height: scrollView.height-10*s)
        if glyphsView.superview != nil { scrollView.contentSize = glyphsView.frame.size }
        currentCapsule.render()
        currentCapsule.topLeft(dx: 10*s, dy: Screen.safeTop+19*s)        
        claudeCircle.bottomLeft(dx: -2*s, dy: -(Screen.safeBottom-7.44274809*s), width: 54*s, height: 54*s)
        glyphsCircle.bottomRight(dx: 2*s, dy: -(Screen.safeBottom-7.44274809*s), width: 54*s, height: 54*s)
        claudeButton.center(width: 30*s, height: 30*s)
        claudeHover.center(width: 250*s, height: 75*s)
    }
    override func layoutRatio143() {
        glyphsView.frame = CGRect(x: 50*s, y: 20*s, width: 990*s, height: 2187*s)
        scrollView.frame = CGRect(x: 44*s, y: Screen.mac ? Screen.safeTop: 0, width: 1050*s, height: view.height-(Screen.mac ? Screen.safeTop+Screen.safeBottom : 0))
        if glyphsView.superview != nil { scrollView.contentSize = glyphsView.frame.size }
        contextGlyphsView.topLeft(dx: 700*s, dy: 60*s, width: 320*s, height: 400*s)
        currentCapsule.render()
        currentCapsule.topLeft(dx: 15*s, dy: Screen.safeTop+19*s)
        
        musicButton.bottomRight(dx: -10*s, dy: -10*s, width: 20*s, height: 20*s)
        claudeButton.bottomLeft(dx: 10*s, dy: -10*s, width: 180*s, height: 24*s)
    }
}
