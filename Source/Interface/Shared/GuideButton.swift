//
//  GuideButton.swift
//  Aexels
//
//  Created by Joe Charlier on 2/10/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import OoviumEngine
import OoviumKit
import UIKit

class GuideButton: AXButton {
	var stateOn: Bool = false

// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {
		let p: CGFloat = 3*s
		let r: CGFloat = 2*s
		let q: CGFloat = self.frame.size.height/2 - p - 3*s

		let x2: CGFloat = self.frame.size.width/2
		let x1 = x2 - q
		let x3 = x2 + q
		let y2 = self.frame.size.height/2
		let y1 = y2 - q
		let y3 = y2 + q
		
		let path = CGMutablePath()
		
		path.move(to: CGPoint(x: x1, y: y2))
		path.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y1), radius: r)
		path.addArc(tangent1End: CGPoint(x: x3, y: y1), tangent2End: CGPoint(x: x3, y: y2), radius: r)
		path.addArc(tangent1End: CGPoint(x: x3, y: y3), tangent2End: CGPoint(x: x2, y: y3), radius: r)
		path.addArc(tangent1End: CGPoint(x: x1, y: y3), tangent2End: CGPoint(x: x1, y: y2), radius: r)
		path.closeSubpath()
		
		let stroke = isHighlighted ? Text.Color.lavender.uiColor : UIColor.white
		let fill = stroke.shade(0.5)
		if (stateOn) {
			let c = UIGraphicsGetCurrentContext()!
			c.addPath(path)
			c.setFillColor(fill.cgColor)
			c.setStrokeColor(stroke.cgColor)
			c.setLineWidth(2*s)
			c.drawPath(using: .fillStroke)
		} else {
			let c = UIGraphicsGetCurrentContext()!
			c.addPath(path)
			c.setLineWidth(2*s)
			c.setStrokeColor(fill.cgColor)
			c.drawPath(using: .stroke)
		}
	}
}
