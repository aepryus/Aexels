//
//  ContentLimbo.swift
//  Aexels
//
//  Created by Joe Charlier on 5/20/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit
import OoviumKit

class ContentLimbo: Limbo {
	let evMaskView: MaskView
	
	init(content: UIView) {
		evMaskView = MaskView(content: content)
		super.init()
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
