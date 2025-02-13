//
//  DilationExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import MetalKit
import OoviumKit
import UIKit

class DilationExplorer: Explorer {
//    let engine: DilationEngine
//    lazy var dilationView: DilationView = DilationView(engine: engine)
//    lazy var fixedView: DilationView = DilationView(engine: engine, chaseCameraOn: true)
    
    // Metal ======
    var renderer: DilationRenderer!
    var dilationMetal: MTKView!
    var fixedMetal: MTKView!
    
    private let systemCell: LimboCell = !Screen.iPhone ? LimboCell(c: 0, r: 0, h: 4) : LimboCell(c: 0, r: 0, h: 2)
    private let aetherCell: LimboCell = !Screen.iPhone ? LimboCell(c: 0, r: 2, h: 2) : LimboCell(c: 0, r: 1)
    
    var cameraOn: Bool = false

    var isFirst: Bool = false
    
//    let articleScroll: UIScrollView = UIScrollView()
//    let articleView: ArticleView = ArticleView()
    
    let pingButton: PulseButton = PulseButton(name: "pulse")
    
    var dilationTab: DilationTab!
    let notesTab: NotesTab = NotesTab(key: "dilation")

	init() {
//        let s: CGFloat = Screen.s
//        let safeTop: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
//        let safeBottom: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
//        let universeWidth: CGFloat = Screen.height - safeTop - safeBottom

//        engine = DilationEngine(size: CGSize(width: universeWidth*2, height: universeWidth))
        
        super.init(key: "dilation")
        
//        engine.onVelocityChange = { (v: TCVelocity) in
//            let italicPen: Pen = Pen(font: UIFont(name: "Verdana-Italic", size: 10*s)!, color: .white, alignment: .right)
//            let sb = italicPen.format("γ = \(String(format: "%3.2f", TCGamma(self.engine.velocity)))")
//            self.dilationTab.lambdaLabel.attributedText = sb
//        }
    }
    
    func swapAetherFrame(_ onComplete: @escaping ()->() = {}) {
        cameraOn = !cameraOn
        
        if Screen.iPhone {
            if cameraOn {
                aetherCell.alpha = 1
                systemCell.h = 1
                cyto.cells.append(self.aetherCell)
                cyto.layout()
            } else {
                aetherCell.alpha = 0
                systemCell.h = 2
                aetherCell.removeFromSuperview()
                cyto.layout()
            }
            onComplete()
        } else {
            let duration: CGFloat = 0.5
            
            if cameraOn {
                UIView.animate(withDuration: duration) {
                    self.systemCell.alpha = 0
                } completion: { (complete: Bool) in
                    self.systemCell.h = 2
                    self.cyto.cells.append(self.aetherCell)
                    self.cyto.layout()
//                    self.engine.reset()
                    onComplete()
                    UIView.animate(withDuration: duration) {
                        self.systemCell.alpha = 1
                        self.aetherCell.alpha = 1
                    }
                }
            } else {
                UIView.animate(withDuration: duration) {
                    self.systemCell.alpha = 0
                    self.aetherCell.alpha = 0
                } completion: { (complete: Bool) in
                    self.systemCell.h = 4
                    self.aetherCell.removeFromSuperview()
                    self.cyto.cells.remove(object: self.aetherCell)
                    self.cyto.layout()
//                    self.engine.reset()
                    onComplete()
                    UIView.animate(withDuration: duration) {
                        self.systemCell.alpha = 1
                    }
                }
            }
        }
    }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        cyto = Screen.iPhone ? Cyto(rows: 3, cols: 1) : Cyto(rows: 4, cols: 2)
        view.addSubview(cyto)

        tabsCell = Screen.iPhone ? TabsCell(c: 0, r: 0) : TabsCell(c: 1, r: 1, h: 2)

        super.viewDidLoad()
        
        aetherCell.alpha = 0

        dilationMetal = MTKView(frame: view.bounds)
        dilationMetal.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        dilationMetal.isOpaque = false
        
        fixedMetal = MTKView(frame: view.bounds)
        fixedMetal.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        fixedMetal.isOpaque = false
        
        renderer = DilationRenderer(systemView: dilationMetal, aetherView: fixedMetal)
                
        systemCell.content = dilationMetal
        aetherCell.content = fixedMetal

        dilationTab = DilationTab(explorer: self)
        
        tabsCell.tabs = [dilationTab, notesTab]
        
        quickView.addSubview(pingButton)
        pingButton.addAction {
            self.renderer.onPing()
//            self.engine.pulse()
        }
        
        if Screen.iPhone {
            cyto.cells = [
                systemCell,
                MaskCell(content: quickView, c: 0, r: 1, cutouts: [.lowerLeft, .lowerRight])
            ]
            configCyto.cells = [
                tabsCell,
                titleCell
            ]
        } else {
            cyto.cells = [
                systemCell,
                titleCell,
                tabsCell,
                LimboCell(content: quickView, c: 1, r: 3)
            ]
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        engine.play()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        engine.stop()
    }

// AEViewController ================================================================================
//    override func layoutRatio056() {
//        super.layoutRatio056()
//    }
    override func layout1024x768() {
        let safeTop: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let safeBottom: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let cytoSize: CGSize = CGSize(width: view.width-10*s, height: Screen.height - safeTop - safeBottom)
        let universeWidth: CGFloat = cytoSize.height

        cyto.Xs = [universeWidth]
        cyto.Ys = [70*s, universeWidth/2-70*s, universeWidth/2-110*s, 110*s]
        cyto.frame = CGRect(x: 5*s, y: safeTop, width: view.width-10*s, height: cytoSize.height)
        cyto.layout()
        
        titleLabel.center(width: 300*s, height: 24*s)
        timeControl.left(dx: 10*s, width: 114*s, height: 54*s)
        pingButton.right(dx: -15*s, width: 60*s, height: 80*s)
    }

// TimeControlDelegate =============================================================================
    override func onPlay() {
        dilationMetal.isPaused = false
        fixedMetal.isPaused = false
    }
    override func onStep() {
        dilationMetal.draw()
        fixedMetal.draw()
    }
    override func onReset() {
        renderer.onReset()
//        controlsTab.applyControls()
        dilationMetal.draw()
        fixedMetal.draw()
        timeControl.playButton.stop()
    }
    override func onStop() {
        dilationMetal.isPaused = true
        fixedMetal.isPaused = true
    }
}
