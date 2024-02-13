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
    let swapButton: SwapButton = SwapButton()
    var first: [Limbo] = [Limbo]()
    var second: [Limbo] = [Limbo]()
    var isFirst: Bool = false
    
    let cyto: Cyto = Cyto(rows: 2, cols: 2)

    init() {
        super.init(name: "Aether", key: "aether", canExplore: true)
    }

    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // AetherLimbo
//        aetherLimbo.content = aexelsView
        
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
        
        cyto.cells = [
            LimboCell(content: aexelsView, c: 0, r: 0),
            LimboCell(c: 1, r: 0, h: 2, cutout: true),
            LimboCell(content: expView, c: 0, r: 1)
        ]
        
        view.addSubview(cyto)
    }
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        super.viewWillAppear(animated)
        aexelsView.play()
    }
    override func viewWillDisappear(_ animated: Bool) {
        print("viewWillDisappear")
        super.viewWillDisappear(animated)
        aexelsView.stop()
    }
        
// AEViewController ================================================================================
    override func layout1024x768() {
        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let height = Screen.height - topY - botY
        let s = height / 748
        
//        let p: CGFloat = 5*s
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
    }
    
// =================================================================================================
// =================================================================================================
// =================================================================================================
// =================================================================================================
// =================================================================================================


	
// Explorer ========================================================================================
	override func layout375x667() {
        let size = UIScreen.main.bounds.size
        
        let w = size.width - 10*s

        expView.frame = CGRect(x: 5*s, y: Screen.height-140*s-Screen.safeBottom, width: w, height: 140*s)

        let om = 15*s
        let im = 6*s
        let bw = (expView.width-2*om-9*im)/10
        let bh = (expView.height-2*om)/1-60*s
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
}
