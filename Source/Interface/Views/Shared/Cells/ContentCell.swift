//
//  ContentCell.swift
//  Aexels
//
//  Created by Joe Charlier on 2/4/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class ContentCell: LimboCell {
    let evMaskView: MaskView
    
    init(content: UIView, c: Int = 0, r: Int = 0, w: Int = 1, h: Int = 1) {
        evMaskView = MaskView(content: content)
        super.init(content: evMaskView, c: c, r: r, w: w, h: h)
        addSubview(self.evMaskView)
    }
    init(frame: CGRect, content: UIView) {
        let rect = CGRect(origin: CGPoint.zero, size: frame.size)
        evMaskView = MaskView(frame: rect, content: content, path: CGPath(roundedRect: rect.insetBy(dx: 7*Screen.s, dy: 7*Screen.s), cornerWidth: 10*Screen.s, cornerHeight: 10*Screen.s, transform: nil))
        super.init()
        addSubview(self.evMaskView)
    }
    required init?(coder aDecoder: NSCoder) {fatalError()}
    
    func bringContentToFront() {
        bringSubviewToFront(evMaskView)
    }
    
// UIView ==========================================================================================
    override var frame: CGRect {
        didSet {
            guard bounds != CGRect.zero else {return}
            evMaskView.frame = bounds
            evMaskView.path = CGPath(roundedRect: bounds.insetBy(dx: 7*s, dy: 7*s), cornerWidth: 10*s, cornerHeight: 10*s, transform: nil)
        }
    }
}
