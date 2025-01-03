//
//  ElectromagnetismExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 12/12/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ElectromagnetismExplorer: Explorer {
    let cyto: Cyto = Cyto(rows: 2, cols: 2)
    let articleScroll: UIScrollView = UIScrollView()
    let articleView: ArticleView = ArticleView()
    let cSlider: CSlider = CSlider()
    let vSlider: VSlider = VSlider()
    let playButton: PlayButton = PlayButton()
    let resetButton: ResetButton = ResetButton()
    let autoSwap: BoolButton = BoolButton(text: "auto")
    let pingButton: PulseButton = PulseButton(name: "ping")
    let pongButton: PulseButton = PulseButton(name: "pong")
    let controlsView: UIView = UIView()

    let engine: ElectromagnetismEngine
    lazy var electromagneticView = ElectromagnetismView(engine: engine)

    init() {
//        let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
//        let s: CGFloat = height / 748
//        let mainLen: CGFloat = height - 110*s
//        let fixLen: CGFloat = Screen.width - mainLen - 10*s

        engine = ElectromagnetismEngine(size: CGSize(width: 500, height: 500))

        super.init(key: "electromagnetism")
    }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        articleView.font = UIFont(name: "Verdana", size: 18*s)!
        articleView.color = .white
        articleView.scrollView = articleScroll
        articleView.key = "\(key)Lab"
        articleScroll.addSubview(articleView)

        cyto.cells = [
            LimboCell(content: electromagneticView, c: 0, r: 0),
            LimboCell(content: controlsView, c: 0, r: 1),
            MaskCell(content: articleScroll,c: 1, r: 0, h: 2, cutout: true)
        ]
        view.addSubview(cyto)
        
        controlsView.addSubview(cSlider)
        cSlider.onChange = { (speedOfLight: Double) in
//            self.engine.speedOfLight = speedOfLight
        }
                
        vSlider.velocity = 0
        controlsView.addSubview(vSlider)
        vSlider.onChange = { (velocity: Double) in
            self.engine.velocity = velocity
        }
        
        playButton.playing = true
        controlsView.addSubview(playButton)
        playButton.onPlay = { [unowned self] in
            self.engine.play()
        }
        playButton.onStop = { [unowned self] in
            self.engine.stop()
        }

        controlsView.addSubview(resetButton)
        resetButton.addAction(for: .touchUpInside) { [unowned self] in
//            self.engine.reset()
            self.engine.tic()
        }
        
        controlsView.addSubview(autoSwap)
        autoSwap.addAction(for: .touchUpInside) { [unowned self] in
            self.autoSwap.rotateView()
//            self.engine.autoOn = !self.engine.autoOn
        }

        controlsView.addSubview(pingButton)
        pingButton.addAction {
            self.engine.onPing()
        }

        controlsView.addSubview(pongButton)
        pongButton.addAction {
            self.engine.onPong()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        engine.play()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        engine.stop()
    }

// AEViewController ================================================================================
    override func layout1024x768() {
        let safeTop: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let safeBottom: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let cytoSize: CGSize = CGSize(width: view.width-10*s, height: Screen.height - safeTop - safeBottom)
        let universeWidth: CGFloat = cytoSize.height - 110*s

        cyto.Xs = [universeWidth]
        cyto.Ys = [universeWidth]
        cyto.frame = CGRect(x: 5*s, y: safeTop, width: view.width-10*s, height: cytoSize.height)
        cyto.layout()
        
        engine.size = electromagneticView.frame.size
        
        articleView.load()
        articleScroll.contentSize = articleView.scrollViewContentSize
        articleView.frame = CGRect(x: 10*s, y: 0, width: articleScroll.width-20*s, height: articleScroll.height)
        
//        let w = UIScreen.main.bounds.size.width - 10*s

        let bw: CGFloat = 40*s
        playButton.left(size: CGSize(width: bw, height: 30*s))
        resetButton.left(dx: bw, size: CGSize(width: bw, height: 30*s))
        cSlider.topLeft(dx: resetButton.right+18*s, dy: 1*s, width: 140*s, height: 40*s)
        vSlider.topLeft(dx: cSlider.right+20*s, dy: cSlider.top, width: 140*s, height: 40*s)
        autoSwap.left(dx: vSlider.right+30*s, dy: -30*s)
        pingButton.right(dx: -15*s, width: 60*s, height: 80*s)
        pongButton.right(dx: -115*s, width: 60*s, height: 80*s)

        cSlider.setTo(60)
        vSlider.setTo(0.0)
    }
}
