//
//  LimboButton.swift
//  Aexels
//
//  Created by Joe Charlier on 9/9/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

import OoviumLib
import UIKit

class LimboButton: UIButton {
	var path: CGPath!

	let a: CGFloat = 6
	let b: CGFloat = 2
	let radius: CGFloat = 10

	init(title: String) {
		super.init(frame: CGRect.zero)

		backgroundColor = UIColor.clear
		
		layer.shadowColor = UIColor.black.cgColor
		layer.shadowOffset = CGSize.zero
		layer.shadowRadius = 3
		layer.shadowOpacity = 0.6
		
		setTitleColor(UIColor.black, for: .highlighted)
		titleLabel!.font = UIFont.aexel(size: 24)
		titleEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
		
		self.setTitle(title, for: .normal)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
//	private func buildPath (p: CGFloat, q: CGFloat) -> CGPath {
//		let path = CGMutablePath()
//
//		let x1 = p
//		let x3 = width - p
//		let x2 = (x1 + x3) / 2
//		let y1 = p
//		let y3 = height - p
//		let y2 = (y1 + y3) / 2
//
//		path.move(to: CGPoint(x: x1, y: y2))
//
//		path.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y1), radius: radius)
//		path.addArc(tangent1End: CGPoint(x: x3, y: y1), tangent2End: CGPoint(x: x3, y: y2), radius: radius)
//		path.addArc(tangent1End: CGPoint(x: x3, y: y3), tangent2End: CGPoint(x: x2, y: y3), radius: radius)
//		path.addArc(tangent1End: CGPoint(x: x1, y: y3), tangent2End: CGPoint(x: x1, y: y2), radius: radius)
//		path.closeSubpath()
//
//		return path
//	}
//
//	func renderPaths() {
//		path = buildPath(p: a, q: 0)
//		let shadowPath = buildPath(p: b, q: 0)
//		self.layer.shadowPath = shadowPath
//		setNeedsDisplay()
//	}

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
	override var frame: CGRect {
		didSet {
			guard frame != CGRect.zero else {return}
			path = CGPath(roundedRect: bounds.insetBy(dx: 6, dy: 6), cornerWidth: 10, cornerHeight: 10, transform: nil)
			let shadowPath = CGPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), cornerWidth: 10, cornerHeight: 10, transform: nil)
			self.layer.shadowPath = shadowPath
		}
	}
	override func draw(_ rect: CGRect) {
		let c = UIGraphicsGetCurrentContext()!
		
		c.addPath(path)
		c.setStrokeColor(UIColor(white: 0.3, alpha: 1).cgColor)
		c.setLineWidth(1.5)
		c.strokePath()
	}
}
