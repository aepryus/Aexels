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
    enum Mode { case concepts, pathOfDiscovery }
    
    let glyphsScroll: UIScrollView = UIScrollView()
    let articleScroll: UIScrollView = UIScrollView()
    let glyphsView: GlyphsView = GlyphsView()
    let articleView: ArticleView = ArticleView()
    var currentCapsule: ArticleCapsule = ArticleCapsule("◎", article: Article(key: ""))
    var contextGlyphsView: GlyphsView = GlyphsView()
    
    let glyphsCell: MaskCell!
    let articleCell: MaskCell!
    let cyto: Cyto = Cyto(rows: 1, cols: 1)

    let pathButton: ImageButton = ImageButton(named: "aepryus")
    let pathCircle: CircleButton
    let musicButton: ImageButton = ImageButton(named: "music")
    let claudeButton: ClaudeButton = ClaudeButton()
    let claudeCircle: CircleButton
    let claudeHover: UIView = UIView()
    let glyphsCircle: CircleButton

    var mode: Mode = .concepts
    var glyphsOffset: CGPoint = .zero
    
    lazy var vision: Vision = ExplorerVision(explorer: Aexels.nexusExplorer)
    
    override init() {
        pathCircle = CircleButton(view: pathButton)
        claudeCircle = CircleButton(view: claudeButton)
        
        let imageView: UIImageView = UIImageView(image: UIImage(named: "glyphs_icon")!)
        imageView.bounds = CGRect(origin: .zero, size: CGSize(width: 30*Screen.s, height: 30*Screen.s))
        glyphsCircle = CircleButton(view: imageView)
        glyphsCircle.addAction {
            Aexels.explorerViewController.explorer = Aexels.nexusExplorer
        }
        
        if Screen.iPhone {
            glyphsCell = MaskCell(content: glyphsScroll, c: 0, r: 0, cutouts: [.lowerLeft, .lowerRight, .upperRight, .upperLeft])
            articleCell = MaskCell(content: articleScroll, c: 0, r: 0, cutouts: [.lowerLeft, .lowerRight, .upperRight])
            articleCell.alpha = 0
            cyto.addSubview(articleCell)
        } else {
            glyphsCell = nil
            articleCell = nil
        }
        
        super.init()
    }

    func show(article: Article) {
        if !Screen.iPhone {
            guard article.key != articleView.key else { return }
            if articleScroll.superview == nil {
                view.addSubview(articleScroll)
            }
            if self.contextGlyphsView.superview == nil { self.contextGlyphsView.alpha = 0 }
            self.view.addSubview(self.contextGlyphsView)
            if currentCapsule.superview == nil { view.addSubview(currentCapsule) }
            UIView.animate(withDuration: 0.5) {
                self.pathButton.alpha = 0
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
                self.pathButton.removeFromSuperview()
                self.musicButton.removeFromSuperview()
                self.glyphsView.removeFromSuperview()
                self.glyphsScroll.removeFromSuperview()
                self.glyphsScroll.removeFromSuperview()
                self.articleScroll.contentSize = self.articleView.scrollViewContentSize
                self.articleScroll.addSubview(self.articleView)
                self.articleScroll.contentOffset = CGPoint(x: 0, y: Screen.iPhone ? 0 : -1000)
                UIView.animate(withDuration: 0.5) {
                    self.articleView.alpha = 1
                    self.currentCapsule.alpha = 1
                    self.contextGlyphsView.alpha = 1
                }
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.glyphsCell.alpha = 0
                self.pathCircle.alpha = 0
                self.glyphsView.alpha = 0
                self.articleView.alpha = 0
            } completion: { (complete: Bool) in
                self.articleView.key = article.key
                self.claudeButton.article = article
                self.glyphsView.removeFromSuperview()
                self.articleScroll.contentSize = self.articleView.scrollViewContentSize
                self.articleScroll.addSubview(self.articleView)
                self.articleScroll.contentOffset = CGPoint(x: 0, y: Screen.iPhone ? 0 : -1000)
                UIView.animate(withDuration: 0.5) {
                    self.articleCell.alpha = 1
                    self.articleView.alpha = 1
                }
            }
        }
    }
    
    func showGlyphs() {
        claudeButton.article = nil

        pathButton.alpha = 0
        musicButton.alpha = 0
        claudeButton.alpha = 0
        glyphsView.alpha = 0
        if !Screen.iPhone {
            view.addSubview(pathButton)
            view.addSubview(musicButton)
            view.addSubview(claudeButton)
            view.addSubview(glyphsScroll)
            glyphsScroll.alpha = 1
        }
        glyphsScroll.addSubview(glyphsView)
        
        UIView.animate(withDuration: 0.5) {
            self.currentCapsule.alpha = 0
            self.contextGlyphsView.alpha = 0
            self.articleView.alpha = 0
        } completion: { (complete: Bool) in
            self.articleView.removeFromSuperview()
            self.currentCapsule.removeFromSuperview()
            self.articleView.key = nil
            self.glyphsScroll.contentSize = self.glyphsView.frame.size
            self.glyphsScroll.contentOffset = self.glyphsOffset
            self.articleView.addSubview(self.articleView)
            UIView.animate(withDuration: 0.5) {
                self.pathCircle.alpha = 1
                self.pathButton.alpha = 1
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
        
        if Screen.iPhone {
            glyphsCell.alpha = 1
            articleCell.alpha = 0
        } else {
            view.addSubview(pathButton)
            view.addSubview(musicButton)
            view.addSubview(claudeButton)
            view.addSubview(glyphsScroll)
        }
        glyphsScroll.addSubview(glyphsView)
        articleView.key = nil
        glyphsScroll.contentSize = self.glyphsView.frame.size
        glyphsScroll.contentOffset = self.glyphsOffset
        articleScroll.addSubview(self.articleView)
        pathCircle.alpha = 1
        pathButton.alpha = 1
        musicButton.alpha = 1
        claudeButton.alpha = 1
        glyphsView.alpha = 1
    }
    func snapSwapPaths() {
        if mode == .concepts {
            mode = .pathOfDiscovery
            glyphsView.glyphs = PathOfDiscovery.glyphs(s: s)
            glyphsView.focus = nil
            contextGlyphsView.glyphs = PathOfDiscovery.glyphs(s: s)
            contextGlyphsView.focus = nil
        } else {
            mode = .concepts
            glyphsView.glyphs = Concepts.glyphs(s: s)
            glyphsView.focus = nil
            contextGlyphsView.glyphs = Concepts.glyphs(s: s)
            contextGlyphsView.focus = nil
        }
        layout()
    }
    func swapPaths() {
        UIView.animate(withDuration: 0.4) {
            self.glyphsView.alpha = 0
        } completion: { (completed: Bool) in
            self.glyphsScroll.contentOffset = .zero
            self.snapSwapPaths()
            UIView.animate(withDuration: 0.4) {
                self.glyphsView.alpha = 1
            }
        }

    }

// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        if Screen.iPhone { glyphsView.scale = 0.78 }
        glyphsView.glyphs = Concepts.glyphs(s: s)
        glyphsView.focus = nil
        glyphsView.onTapGlyph = { (glyphView: GlyphView) in
            if self.glyphsView.alpha == 1 { self.glyphsOffset = self.glyphsScroll.contentOffset }
            glyphView.execute()
        }
        
        contextGlyphsView.scale = 0.7
        contextGlyphsView.glyphs = Concepts.glyphs(s: s)
        contextGlyphsView.onTapGlyph = { (glyphView: GlyphView) in
            glyphView.execute()
        }

        glyphsScroll.addSubview(glyphsView)
        glyphsScroll.showsVerticalScrollIndicator = false
        articleScroll.showsVerticalScrollIndicator = false
        if !Screen.iPhone { view.addSubview(glyphsScroll) }

        if !Screen.iPhone { articleView.maxWidth = min(Screen.width - 500, 800) }
        else { articleView.maxWidth = Screen.width-30*s }
        
        articleView.scrollView = articleScroll

        if !Screen.iPhone { view.addSubview(contextGlyphsView) }
        
        currentCapsule.transform = CGAffineTransform(rotationAngle: -.pi/2)
        view.addSubview(currentCapsule)
        
        pathButton.addAction { self.swapPaths() }
        if !Screen.iPhone {
            view.addSubview(pathButton)

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

            cyto.cells = [glyphsCell]
            view.addSubview(cyto)
            
            view.addSubview(pathCircle)

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
        articleCell.frame = glyphsCell.frame

        glyphsView.frame = CGRect(x: 0*s, y: 20*s, width: Screen.iPhone ? glyphsCell.width-10*s : 510*s, height: Screen.iPhone ? 1640*s : 2487*s)
        articleView.frame = CGRect(x: 10*s, y: 5*s, width: articleScroll.width-20*s, height: articleScroll.height-10*s)
        if glyphsView.superview != nil { glyphsScroll.contentSize = glyphsView.frame.size }
        currentCapsule.render()
        currentCapsule.topLeft(dx: 10*s, dy: Screen.safeTop+19*s)        
        pathCircle.topLeft(dx: -2*s, dy: Screen.safeTop-7.44274809*s, width: 54*s, height: 54*s)
        claudeCircle.bottomLeft(dx: -2*s, dy: -(Screen.safeBottom-7.44274809*s), width: 54*s, height: 54*s)
        glyphsCircle.bottomRight(dx: 2*s, dy: -(Screen.safeBottom-7.44274809*s), width: 54*s, height: 54*s)
        pathButton.center(width: 30*s, height: 30*s)
        claudeButton.center(width: 30*s, height: 30*s)
        claudeHover.center(width: 250*s, height: 75*s)
    }
    override func layoutRatio143() {
        glyphsView.frame = CGRect(x: 50*s, y: 20*s, width: 990*s, height: 2487*s)
        articleScroll.frame = CGRect(x: 44*s, y: Screen.mac ? Screen.safeTop: 0, width: 1050*s, height: view.height-(Screen.mac ? Screen.safeTop+Screen.safeBottom : 0))
        glyphsScroll.frame = articleScroll.frame
        if glyphsView.superview != nil { glyphsScroll.contentSize = glyphsView.frame.size }
        contextGlyphsView.topLeft(dx: 700*s, dy: 60*s, width: 320*s, height: 400*s)
        currentCapsule.render()
        currentCapsule.topLeft(dx: 15*s, dy: Screen.safeTop+19*s)
        
        pathButton.topLeft(dx: 10*s, dy: Screen.safeTop + 10*s, width: 20*s, height: 20*s)
        musicButton.bottomRight(dx: -10*s, dy: -10*s, width: 20*s, height: 20*s)
        claudeButton.bottomLeft(dx: 10*s, dy: -10*s, width: 180*s, height: 24*s)
    }
}
