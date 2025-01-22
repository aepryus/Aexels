//
//  AXButton.swift
//  Aexels
//
//  Created by Joe Charlier on 5/20/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

import UIKit

class AXButton: UIControl {
	
	init() {
		super.init(frame: CGRect.zero)
		backgroundColor = UIColor.clear
	}
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) { fatalError() }

// UIView ==========================================================================================
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let inside = super.point(inside: point, with: event)
		if inside && !isHighlighted && event?.type == .touches {
			isHighlighted = true
		}
		return inside
	}
	override var isHighlighted: Bool {
		didSet { setNeedsDisplay() }
	}
}
