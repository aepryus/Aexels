//
//  NetButton.swift
//  Aexels
//
//  Created by Joe Charlier on 6/5/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

import OoviumLib
import UIKit

class NetButton: UIButton {
	var on: Bool = true
	
	init() {
		super.init(frame: CGRect.zero)
		layer.cornerRadius = 8
		clipsToBounds = true
		backgroundColor = OOColor.lavender.uiColor.alpha(0.3)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {
		let color = on ? UIColor.white : UIColor(white: 0.5, alpha: 1)
		
		let s: CGFloat = 20
		let sn: CGFloat = s*sin(CGFloat.pi/6)
		let cs: CGFloat = s*cos(CGFloat.pi/6)
		let x: CGFloat = (width-2*s)/2
		let y: CGFloat = (height-2*cs)/2
		let r: CGFloat = 5
		
		let x1 = x
		let x3 = x1+sn
		let x5 = x3+s
		let x7 = x5+sn
		let x2 = (x1+x3)/2
		let x4 = (x3+x5)/2
		let x6 = (x5+x7)/2
		
		let y1 = y
		let y3 = y1+cs
		let y5 = y3+cs
		let y2 = (y1+y3)/2
		let y4 = (y3+y5)/2
		
		let path = CGMutablePath()
		path.move(to: CGPoint(x: x2, y: y2))
		path.addArc(tangent1End: CGPoint(x: x3, y: y1), tangent2End: CGPoint(x: x4, y: y1), radius: r)
		path.addArc(tangent1End: CGPoint(x: x5, y: y1), tangent2End: CGPoint(x: x6, y: y2), radius: r)
		path.addArc(tangent1End: CGPoint(x: x7, y: y3), tangent2End: CGPoint(x: x6, y: y4), radius: r)
		path.addArc(tangent1End: CGPoint(x: x5, y: y5), tangent2End: CGPoint(x: x4, y: y5), radius: r)
		path.addArc(tangent1End: CGPoint(x: x3, y: y5), tangent2End: CGPoint(x: x2, y: y4), radius: r)
		path.addArc(tangent1End: CGPoint(x: x1, y: y3), tangent2End: CGPoint(x: x2, y: y2), radius: r)
		path.closeSubpath()

		let c = UIGraphicsGetCurrentContext()!
		c.setStrokeColor(color.cgColor)
		c.setLineWidth(2)
		c.addPath(path)
		c.drawPath(using: .stroke)		
	}
}
