//
//  GuideButton.swift
//  Aexels
//
//  Created by Joe Charlier on 2/10/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class GuideButton: UIButton {
	var stateOn: Bool = true

// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {
		let p: CGFloat = 3
		let r: CGFloat = 2
		let s: CGFloat = self.frame.size.height/2 - p - 3

		let x2: CGFloat = self.frame.size.width/2
		let x1 = x2 - s
		let x3 = x2 + s
		let y2 = self.frame.size.height/2
		let y1 = y2 - s
		let y3 = y2 + s
		
		let path = CGMutablePath()
		
		path.move(to: CGPoint(x: x1, y: y2))
		path.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y1), radius: r)
		path.addArc(tangent1End: CGPoint(x: x3, y: y1), tangent2End: CGPoint(x: x3, y: y2), radius: r)
		path.addArc(tangent1End: CGPoint(x: x3, y: y3), tangent2End: CGPoint(x: x2, y: y3), radius: r)
		path.addArc(tangent1End: CGPoint(x: x1, y: y3), tangent2End: CGPoint(x: x1, y: y2), radius: r)
		path.closeSubpath()
		
		let stroke = UIColor.white
		let fill = UIColor(white: 0.5, alpha: 1)
		if (stateOn) {
			let c = UIGraphicsGetCurrentContext()!
			c.addPath(path)
			c.setFillColor(fill.cgColor)
			c.setStrokeColor(stroke.cgColor)
			c.setLineWidth(2)
			c.drawPath(using: .fillStroke)
		} else {
			let c = UIGraphicsGetCurrentContext()!
			c.addPath(path)
			c.setLineWidth(2)
			c.setStrokeColor(fill.cgColor)
			c.drawPath(using: .stroke)
		}
	}
}
