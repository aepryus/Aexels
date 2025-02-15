//
//  OoviumTab.swift
//  Aexels
//
//  Created by Joe Charlier on 2/15/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import UIKit

class OoviumTab: TabsCellTab {
    var ooviumView: OoviumView? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let ooviumView else { return }
            addSubview(ooviumView)
        }
    }
    
    init() {
        super.init(name: "Oovium")
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        ooviumView?.frame = CGRect(x: 10*s, y: 10*s, width: width-20*s, height: height-43*s)
    }
}
