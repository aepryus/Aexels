//
//  NexusCell.swift
//  Aexels
//
//  Created by Joe Charlier on 2/5/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class NexusCell: Cyto.Cell {

    override init(c: Int = 0, r: Int = 0, w: Int = 1, h: Int = 1) {
        super.init(c: c, r: r, w: w, h: h)
        layer.cornerRadius = 8*s
        layer.borderWidth = 3
        layer.borderColor = UIColor.white.shade(0.6).cgColor
        layer.backgroundColor = UIColor.white.shade(0.4).cgColor
                
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(gesture)
    }
    
// Events ==========================================================================================
    @objc func onTap() {}
}
