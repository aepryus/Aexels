//
//  LimboView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class LimboPath {
	var strokePath: CGPath!
	var shadowPath: CGPath!
	var maskPath: CGPath!
}

class LimboView: UIView {
	var _limboPath = LimboPath()
	var limboPath: LimboPath {
		set {
			_limboPath = newValue
			setNeedsDisplay()
			self.layer.shadowPath = limboPath.shadowPath
			applyMask()
		}
		get {
			return _limboPath
		}
	}
	var _content: UIView?
	var content: UIView? {
		set {
			_content?.removeFromSuperview()
			_content = newValue
			
			if _content == nil {return}
			
			let p: CGFloat = 15
			_content?.frame = CGRect(x: p, y: p, width: bounds.size.width-2*p, height: bounds.size.height-2*p)
			addSubview(_content!)
		}
		get {
			return _content
		}
	}
	
	init () {
		super.init(frame: CGRect.zero)

		backgroundColor = UIColor.clear
		
		layer.shadowColor = UIColor.black.cgColor
		layer.shadowOffset = CGSize.zero
		layer.shadowRadius = 3
		layer.shadowOpacity = 0.6
	}
	required init? (coder aDecoder: NSCoder) {fatalError()}
	
	func applyMask () {}
	
// UIView ==========================================================================================
	override var frame: CGRect {
		set {
			super.frame = newValue
			guard frame != CGRect.zero else {return}
			limboPath.strokePath = CGPath(roundedRect: bounds.insetBy(dx: 6, dy: 6), cornerWidth: 10, cornerHeight: 10, transform: nil)
			limboPath.shadowPath = CGPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), cornerWidth: 10, cornerHeight: 10, transform: nil)
			limboPath.maskPath = limboPath.strokePath
			self.layer.shadowPath = limboPath.shadowPath
			applyMask()
		}
		get {
			return super.frame
		}
	}
	override func draw(_ rect: CGRect) {
		let c = UIGraphicsGetCurrentContext()!

		c.addPath(limboPath.strokePath)
		c.setStrokeColor(UIColor(white: 0.3, alpha: 1).cgColor)
		c.setLineWidth(1.5)
		c.strokePath()
	}
}
