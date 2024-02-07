//
//  ExplorerCell.swift
//  Aexels
//
//  Created by Joe Charlier on 2/6/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ExplorerCell: NexusCell {
    let explorer: Explorer
    let explorerButton: ExplorerButton
    
    init(explorer: Explorer, c: Int = 0, r: Int = 0, w: Int = 1, h: Int = 1) {
        self.explorer = explorer
        self.explorerButton = explorer.explorerButton
        super.init(c: c, r: r, w: w, h: h)
        addSubview(explorerButton)
    }
    
// NexusCell =======================================================================================
    override func onTap() {
        let explorerViewController: ExplorerViewController = (Aexels.window.rootViewController as! ExplorerViewController)
        explorerViewController.explorer = explorer
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
//        explorerButton.center(width: 189*s/2, height: 150*s/2)
        explorerButton.center(width: 70*s, height: 66*s)
    }
}
