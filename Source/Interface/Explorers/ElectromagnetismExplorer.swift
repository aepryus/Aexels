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
    
    let engine: ElectromagnetismEngine
    lazy var electromagneticView = ElectromagnetismView(engine: engine)

    init() {
        let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
        let s: CGFloat = height / 748
        let mainLen: CGFloat = height - 110*s
        let fixLen: CGFloat = Screen.width - mainLen - 10*s

        engine = ElectromagnetismEngine(size: CGSize(width: max(mainLen, fixLen*2+123), height: mainLen))

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
            LimboCell(c: 0, r: 1),
            MaskCell(content: articleScroll,c: 1, r: 0, h: 2, cutout: true)
        ]
        view.addSubview(cyto)
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
        
        articleView.load()
        articleScroll.contentSize = articleView.scrollViewContentSize
        articleView.frame = CGRect(x: 10*s, y: 0, width: articleScroll.width-20*s, height: articleScroll.height)
    }
}
