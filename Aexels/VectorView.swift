//
//  VectorView.swift
//  Aexels
//
//  Created by Joe Charlier on 4/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import OoviumKit
import UIKit

class VectorView: UIView {
	var max: Double = 1
	var onTap: ((V2)->())?

	var _vector: V2 = V2(0, 1)
	var vector: V2 {
		set {
			_vector = newValue
			DispatchQueue.main.async {
				self.setNeedsDisplay()
			}
		}
		get {return _vector}
	}
	
	init() {
		super.init(frame: CGRect.zero)
		self.backgroundColor = UIColor.clear
		
		let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
		addGestureRecognizer(gesture)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
// Events ==========================================================================================
	@objc func onTap(_ gesture: UITapGestureRecognizer) {
		let lw: CGFloat = 3*s
		let radius = (Double(frame.size.width-lw))/2
		
		var x = Double(gesture.location(in: self).x - frame.size.width/2) / radius
		var y = -Double(gesture.location(in: self).y - frame.size.height/2) / radius
		
		if x*x + y*y > 1 {
			let q = sqrt(x*x + y*y)
			x /= q
			y /= q
		}
		x *= max
		y *= max
		
		vector = V2(x, y)
		if let onTap = onTap {
			onTap(vector)
		}
	}

// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {
		let lw: CGFloat = 3*s
		
		let c = UIGraphicsGetCurrentContext()!
		
		var path = CGMutablePath()
		path.addEllipse(in: CGRect(x: lw/2, y: lw/2, width: rect.size.width-lw, height: rect.size.height-lw))
		c.addPath(path)
		c.setLineWidth(lw)
		c.setStrokeColor(UIColor.white.cgColor)
		c.strokePath()
		
		path = CGMutablePath()
		let radius = (Double(rect.size.width-lw))/2
		let center = V2(Double(rect.size.width)/2, Double(rect.size.width)/2)
		
		let end = center + V2(vector.x, -vector.y) * radius/max
		
		path.addEllipse(in: CGRect(x: center.x-2, y: center.y-2, width: 4, height: 4))
		path.move(to: CGPoint(x: center.x, y: center.y))
		path.addLine(to: CGPoint(x: end.x, y: end.y))
		
		c.addPath(path)
		c.setLineWidth(2*s)
		c.setLineCap(.round)
		c.setStrokeColor(OOColor.lavender.uiColor.cgColor)
		c.drawPath(using: .fillStroke)
	}
}
