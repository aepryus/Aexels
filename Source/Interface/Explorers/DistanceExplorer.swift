//
//  DistanceExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 2/17/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class DistanceExplorer: Explorer {
    let cyto: Cyto = Cyto(rows: 2, cols: 2)
    let articleScroll: UIScrollView = UIScrollView()
    let articleView: ArticleView = ArticleView()

    init() { super.init(key: "distance") }

// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()

        articleView.font = UIFont(name: "Verdana", size: 18*s)!
        articleView.color = .white
        articleView.scrollView = articleScroll
        articleView.key = "\(key)Lab"
        articleScroll.addSubview(articleView)

        cyto.cells = [
            LimboCell(c: 0, r: 0),
            LimboCell(c: 0, r: 1),
            MaskCell(content: articleScroll,c: 1, r: 0, h: 2, cutout: true)
        ]
        view.addSubview(cyto)
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
