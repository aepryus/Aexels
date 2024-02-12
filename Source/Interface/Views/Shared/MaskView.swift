//
//  MaskView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class AXMaskView: UIView {
	var content: UIView? {
		didSet {
			oldValue?.removeFromSuperview()
			content?.frame = bounds
			if let content = content {addSubview(content)}
		}
	}	
	var path: CGPath? {
		didSet {
			let mask = CAShapeLayer()
			mask.path = path
			layer.mask = mask
		}
	}
}
