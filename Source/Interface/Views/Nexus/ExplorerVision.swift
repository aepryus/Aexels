//
//  ExplorerVision.swift
//  Aexels
//
//  Created by Joe Charlier on 2/9/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ExplorerVision: Vision {
    let explorer: AEViewController
    
    init(explorer: AEViewController, color: UIColor) {
        self.explorer = explorer
        super.init(color: color)
    }
    
// Vision ==========================================================================================
    override func onSelect() {
        Aexels.explorerViewController.explorer = explorer
    }
}
