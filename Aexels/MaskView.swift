//
//  MaskView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class AXMaskView: UIView {
	var _content: UIView?
	var content: UIView? {
		set {
			_content?.removeFromSuperview()
			_content = newValue
			_content!.frame = bounds
			addSubview(_content!)
		}
		get {return _content}
	}
	
	var _path: CGPath?
	var path: CGPath? {
		set {
			_path = newValue
			let mask = CAShapeLayer()
			mask.path = _path
			layer.mask = mask
		}
		get {return _path}
	}
}
