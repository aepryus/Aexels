//
//  AetherExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class AetherExplorer: Explorer {
    
    let aexelsView: AexelsView = AexelsView()
    let expAButton: ExpButton = ExpButton(name: Screen.iPhone ? "12" : "12\nAexels")
    let expBButton: ExpButton = ExpButton(name: Screen.iPhone ? "60" : "60\nAexels")
    let expCButton: ExpButton = ExpButton(name: Screen.iPhone ? "360" : "360\nAexels")
    let expDButton: ExpButton = ExpButton(name: Screen.iPhone ? "G\no\nL" : "Game\nof\nLife")
    let expEButton: ExpButton = ExpButton(shape: .line)
    let expFButton: ExpButton = ExpButton(shape: .rectangle)
    let expGButton: ExpButton = ExpButton(shape: .box)
    let expHButton: ExpButton = ExpButton(shape: .ring)
    let expIButton: ExpButton = ExpButton(shape: .circle)
    let expJButton: ExpButton = ExpButton(shape: .nothing)
    let expView: UIView = UIView()

    lazy var experiments: [ExpButton] = { [
        expAButton,
        expBButton,
        expCButton,
        expDButton,
        expEButton,
        expFButton,
        expGButton,
        expHButton,
        expIButton,
        expJButton
    ] }()
    
    let swapper: Limbo = Limbo()
    var first: [Limbo] = [Limbo]()
    var second: [Limbo] = [Limbo]()
    var isFirst: Bool = false
    
    let articleScroll: UIScrollView = UIScrollView()
    let articleView: ArticleView = ArticleView()
    var cyto: Cyto!

    init() { super.init(key: "aether") }

    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Screen.iPhone {
            cyto = Cyto(rows: 3, cols: 1)
        } else {
           cyto = Cyto(rows: 2, cols: 2)
        }
        
        articleView.font = UIFont(name: "Verdana", size: 18*s)!
        articleView.color = .white
        articleView.scrollView = articleScroll
        articleView.key = "aetherLab"
        articleScroll.addSubview(articleView)

        expAButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.aexelsView.experimentA()
            self.expAButton.activated = true
        }
        self.expAButton.activated = true
        expView.addSubview(expAButton)

        expBButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.aexelsView.experimentB()
            self.expBButton.activated = true
        }
        expView.addSubview(expBButton)

        expCButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.aexelsView.experimentC()
            self.expCButton.activated = true
        }
        expView.addSubview(expCButton)

        expDButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.aexelsView.experimentD()
            self.expDButton.activated = true
        }
        expView.addSubview(expDButton)

        expEButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.aexelsView.experimentE()
            self.expEButton.activated = true
        }
        expView.addSubview(expEButton)

        expFButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.aexelsView.experimentF()
            self.expFButton.activated = true
        }
        expView.addSubview(expFButton)

        expGButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.aexelsView.experimentG()
            self.expGButton.activated = true
        }
        expView.addSubview(expGButton)

        expHButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.aexelsView.experimentH()
            self.expHButton.activated = true
        }
        expView.addSubview(expHButton)

        expIButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.aexelsView.experimentI()
            self.expIButton.activated = true
        }
        expView.addSubview(expIButton)
        
        expJButton.addAction {
            self.experiments.forEach { $0.activated = false }
            self.aexelsView.experimentJ()
            self.expJButton.activated = true
        }
        expView.addSubview(expJButton)
        
        if Screen.iPhone {
            cyto.cells = [
                LimboCell(content: aexelsView, c: 0, r: 0),
                LimboCell(content: expView, c: 0, r: 1),
                LimboCell(content: UIView(), c: 0, r: 2)
            ]
        } else {
            cyto.cells = [
                LimboCell(content: aexelsView, c: 0, r: 0),
                MaskCell(content: articleScroll, c: 1, r: 0, h: 2, cutouts: [.upperRight]),
                LimboCell(content: expView, c: 0, r: 1)
            ]
        }
        
        view.addSubview(cyto)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        aexelsView.play()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        aexelsView.stop()
    }
        
// AEViewController ================================================================================
    override func layout375x667() {
        cyto.Ys = [Screen.height-140*s - Screen.safeBottom - Screen.safeTop, 84*s]
        cyto.frame = CGRect(x: 5*s, y: Screen.safeTop, width: view.width-10*s, height: view.height-Screen.safeTop-Screen.safeBottom)
        cyto.layout()

        let om = 0*s
        let im = 2*s
        let bw = (expView.width-2*om-9*im)/10
        let bh = (expView.height-2*om)/1

        expAButton.topLeft(dx: om, dy: om, width: bw, height: bh)
        expBButton.topLeft(dx: om+bw+im, dy: om, width: bw, height: bh)
        expCButton.topLeft(dx: om+2*bw+2*im, dy: om, width: bw, height: bh)
        expDButton.topLeft(dx: om+3*bw+3*im, dy: om, width: bw, height: bh)
        expEButton.topLeft(dx: om+4*bw+4*im, dy: om, width: bw, height: bh)
        expFButton.topLeft(dx: om+5*bw+5*im, dy: om, width: bw, height: bh)
        expGButton.topLeft(dx: om+6*bw+6*im, dy: om, width: bw, height: bh)
        expHButton.topLeft(dx: om+7*bw+7*im, dy: om, width: bw, height: bh)
        expIButton.topLeft(dx: om+8*bw+8*im, dy: om, width: bw, height: bh)
        expJButton.topLeft(dx: om+9*bw+9*im, dy: om, width: bw, height: bh)
    }
    override func layout1024x768() {
        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let height = Screen.height - topY - botY
        let s = height / 748
        
        let uw: CGFloat = height - 110*s

        let om = 6*s
        let im = 6*s
        let bw = (expView.width-2*om-9*im)/10
        let bh = (expView.height-2*om)/1
        expAButton.topLeft(dx: om, dy: om, width: bw, height: bh)
        expBButton.topLeft(dx: om+bw+im, dy: om, width: bw, height: bh)
        expCButton.topLeft(dx: om+2*bw+2*im, dy: om, width: bw, height: bh)
        expDButton.topLeft(dx: om+3*bw+3*im, dy: om, width: bw, height: bh)
        expEButton.topLeft(dx: om+4*bw+4*im, dy: om, width: bw, height: bh)
        expFButton.topLeft(dx: om+5*bw+5*im, dy: om, width: bw, height: bh)
        expGButton.topLeft(dx: om+6*bw+6*im, dy: om, width: bw, height: bh)
        expHButton.topLeft(dx: om+7*bw+7*im, dy: om, width: bw, height: bh)
        expIButton.topLeft(dx: om+8*bw+8*im, dy: om, width: bw, height: bh)
        expJButton.topLeft(dx: om+9*bw+9*im, dy: om, width: bw, height: bh)

        cyto.Xs = [uw]
        cyto.Ys = [uw]
        cyto.frame = CGRect(x: 5*s, y: topY, width: view.width-10*s, height: view.height-topY-botY)
        cyto.layout()
        
        articleView.load()
        articleScroll.contentSize = articleView.scrollViewContentSize
        articleView.frame = CGRect(x: 10*s, y: 0, width: articleScroll.width-20*s, height: articleScroll.height)
    }
}
