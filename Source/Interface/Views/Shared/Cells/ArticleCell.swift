//
//  ArticleCell.swift
//  Aexels
//
//  Created by Joe Charlier on 2/6/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ArticleCell: NexusCell {
    let key: String
    let nameLabel: UILabel = UILabel()
    
    init(key: String, c: Int = 0, r: Int = 0, w: Int = 1, h: Int = 1) {
        self.key = key
        super.init(c: c, r: r, w: w, h: h)

        nameLabel.text = "\(key)_name".localized
        nameLabel.pen = Pen(font: .axBold(size: 16*s), color: .white, alignment: .center)
        nameLabel.numberOfLines = 2
        addSubview(nameLabel)
    }
    
// NexusCell =======================================================================================
    override func onTap() {
        let nexusExplorer: NexusExplorer = ((Aexels.window.rootViewController as! ExplorerViewController).explorer as! NexusExplorer)
        nexusExplorer.showArticle(key: "\(key)_article")
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        nameLabel.sizeToFit()
        nameLabel.center(height: nameLabel.height+4*s)
    }
}
