//
//  OoviumView.swift
//  Aexels
//
//  Created by Joe Charlier on 2/8/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class OoviumView: AEView {
    let ooviumLabel: UILabel = UILabel()
    let aetherView: AetherView
    
    init(aetherView: AetherView) {
        self.aetherView = aetherView
        super.init()

        ooviumLabel.text = "Oovium"
        ooviumLabel.textAlignment = .center
        ooviumLabel.textColor = UIColor.white.withAlphaComponent(0.3)
        ooviumLabel.font = UIFont(name: "Georgia", size: 36*s)
        addSubview(ooviumLabel)
        addSubview(aetherView)
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        aetherView.frame = bounds
        ooviumLabel.bottomRight(dx: -12*s, dy: -14*s, width: 144*s, height: 40*s)
        
        aetherView.renderToolBars()
        aetherView.placeToolBars()
        aetherView.showToolBars()
        aetherView.invokeAetherPicker()
        aetherView.stretch()
    }
}
