//
//  ContentLimbo.swift
//  Aexels
//
//  Created by Joe Charlier on 5/20/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

import UIKit
import OoviumLib

class ContentLimbo: Limbo {
	let evMaskView: MaskView
	
	init(frame: CGRect, content: UIView) {
		let rect = CGRect(origin: CGPoint.zero, size: frame.size)
		evMaskView = MaskView(frame: rect, content: content, path: CGPath(roundedRect: rect.insetBy(dx: 7*D.s, dy: 7*D.s), cornerWidth: 10*D.s, cornerHeight: 10*D.s, transform: nil))
		super.init()
		addSubview(self.evMaskView)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
	// UIView ==========================================================================================
	override var frame: CGRect {
		didSet {
			evMaskView.frame = bounds
			if bounds != CGRect.zero {
				evMaskView.path = CGPath(roundedRect: bounds.insetBy(dx: 7*D.s, dy: 7*D.s), cornerWidth: 10*D.s, cornerHeight: 10*D.s, transform: nil)
			}
		}
	}
}
