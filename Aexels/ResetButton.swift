//
//  ResetButton.swift
//  Aexels
//
//  Created by Joe Charlier on 2/10/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class ResetButton: AXButton {

// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {
		let ir: CGFloat = 11
		let p: CGFloat = 3
		let ph: CGFloat = 12
		let pl: CGFloat = 6
		let pr: CGFloat = 11
		let r: CGFloat = 2
		
		let x4: CGFloat = frame.size.width/2
		let ix10: CGFloat = x4+pl
		let ix11: CGFloat = x4-pr
		let iy1: CGFloat = p
		let iy2: CGFloat = iy1+ir
		let iy6: CGFloat = iy2-ph
		let iy9: CGFloat = iy2+ph
		let iy7: CGFloat = iy6+ph*pl/(pr+pl)
		let iy8: CGFloat = iy9-ph*pl/(pr+pl)

		let ix3: CGFloat = ix11
		let ix1: CGFloat = ix3
		let ix2: CGFloat = (ix1+ix3)/2
		
		let iy3 = iy6+1.5
		let iy5 = iy9-1.5
		let iy4 = (iy3+iy5)/2
		
		let path = CGMutablePath()
		
		path.move(to: CGPoint(x: ix1, y: iy4))
		path.addArc(tangent1End: CGPoint(x: ix1, y: iy3), tangent2End: CGPoint(x: ix2, y: iy3), radius: r)
		path.addArc(tangent1End: CGPoint(x: ix3, y: iy3), tangent2End: CGPoint(x: ix3, y: iy4), radius: r)
		path.addArc(tangent1End: CGPoint(x: ix3, y: iy5), tangent2End: CGPoint(x: ix2, y: iy5), radius: r)
		path.addArc(tangent1End: CGPoint(x: ix1, y: iy5), tangent2End: CGPoint(x: ix1, y: iy4), radius: r)
		path.closeSubpath()
		
		path.move(to: CGPoint(x: ix10, y: iy2))
		path.addArc(tangent1End: CGPoint(x: ix10, y: iy6), tangent2End: CGPoint(x: x4, y: iy7), radius: r)
		path.addArc(tangent1End: CGPoint(x: ix11, y: iy2), tangent2End: CGPoint(x: x4, y: iy8), radius: r)
		path.addArc(tangent1End: CGPoint(x: ix10, y: iy9), tangent2End: CGPoint(x: ix10, y: iy2), radius: r)
		path.closeSubpath()

		let stroke = UIColor.white
		let fill = UIColor(white: 0.5, alpha: 1)
		let c = UIGraphicsGetCurrentContext()!
		c.addPath(path)
		c.setFillColor(fill.cgColor)
		c.setStrokeColor(stroke.cgColor)
		c.setLineWidth(2)
		c.drawPath(using: .fillStroke)
	}
}
