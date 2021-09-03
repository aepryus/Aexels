//
//  ExpButton.swift
//  Aexels
//
//  Created by Joe Charlier on 9/11/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class ExpButton: UIControl {
	
	var name: String
	var color: UIColor
	var backColor: UIColor? = nil
	var size: CGFloat = 13*Screen.s
	var radius: CGFloat = 5*Screen.s
	var activated: Bool = false {
		didSet{ setNeedsDisplay() }
	}
	
	init(name: String) {
		self.name = name
		color = UIColor.white
		super.init(frame: CGRect.zero)
		backgroundColor = .clear
	}
	init(name: String, color: UIColor) {
		self.name = name
		self.color = color
		super.init(frame: CGRect.zero)
		backgroundColor = .clear
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
// UIView ==========================================================================================
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let inside = super.point(inside: point, with: event)
		if inside && !isHighlighted && event?.type == .touches {
			isHighlighted = true
		}
		return inside
	}
	override var isHighlighted: Bool {
		didSet {setNeedsDisplay()}
	}
	override func draw(_ rect: CGRect) {
		let c = UIGraphicsGetCurrentContext()!
		
		let color = !isHighlighted ? self.color : OOColor.lavender.uiColor
		
		let path = CGPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerWidth: radius, cornerHeight: radius, transform: nil)
		c.addPath(path)
		color.setStroke()
		if !activated {
			if let backColor = backColor {
				backColor.setFill()
				c.drawPath(using: .fillStroke)
			} else {
				c.drawPath(using: .stroke)
			}
		} else {
			color.setFill()
			c.drawPath(using: .fillStroke)
		}
		
		let pen: Pen = Pen(font: UIFont.aexelBold(size: self.size), color: (activated ? UIColor.black : color), alignment: .center)
		let size = (name as NSString).size(withAttributes: pen.attributes)
		name.draw(in: CGRect(x: rect.origin.x, y: (rect.size.height-size.height)/2, width: rect.size.width, height: size.height), withAttributes: pen.attributes)
	}
}
