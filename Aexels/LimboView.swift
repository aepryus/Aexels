//
//  LimboView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class LimboView: UIView {
	var path: CGPath!
	
	init () {
		super.init(frame: CGRect.zero)

		backgroundColor = UIColor.clear
		
		layer.shadowColor = UIColor.black.cgColor
		layer.shadowOffset = CGSize.zero
		layer.shadowRadius = 3
		layer.shadowOpacity = 0.6
	}
	required init? (coder aDecoder: NSCoder) {super.init(coder: aDecoder)}
	
// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {
		let c = UIGraphicsGetCurrentContext()!

		var path = CGPath(roundedRect: rect.insetBy(dx: 6, dy: 6), cornerWidth: 10, cornerHeight: 10, transform: nil)
		c.addPath(path)
		c.setStrokeColor(UIColor(white: 0.3, alpha: 1).cgColor)
		c.setLineWidth(1.5)
		c.strokePath()
		
		path = CGPath(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerWidth: 10, cornerHeight: 10, transform: nil)
		self.layer.shadowPath = path;

		self.path = CGPath(roundedRect: rect.insetBy(dx: 6, dy: 6), cornerWidth: 10, cornerHeight: 10, transform: nil)
	}
}
