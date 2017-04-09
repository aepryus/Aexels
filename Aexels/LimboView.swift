//
//  LimboView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import OoviumLib
import UIKit

class LimboPath {
	var strokePath: CGPath!
	var shadowPath: CGPath!
	var maskPath: CGPath!
}

//enum AEPoint {
//	case center, top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight
//	
//	func isRight() -> Bool {
//		return self == .topRight || self == .right || self == .bottomRight
//	}
//	func isLeft() -> Bool {
//		return self == .topLeft || self == .left || self == .bottomLeft
//	}
//	func isTop() -> Bool {
//		return self == .topLeft || self == .top || self == .topRight
//	}
//	func isBottom() -> Bool {
//		return self == .bottomLeft || self == .bottom || self == .bottomRight
//	}
//}

class Cutout {
	let width: CGFloat
	let height: CGFloat
	
	init (width: CGFloat, height: CGFloat) {
		self.width = width
		self.height = height
	}
}

class LimboView: UIView {
	var p: CGFloat = 15
	var a: CGFloat = 6
	var b: CGFloat = 2
	var radius: CGFloat = 10

	var cutouts: [AEPoint:Cutout] = [:]
	
	var _content: UIView?
	var content: UIView? {
		set {
			_content?.removeFromSuperview()
			_content = newValue
			
			if _content == nil {return}
			
			_content?.frame = CGRect(x: p, y: p, width: bounds.size.width-2*p, height: bounds.size.height-2*p)
			addSubview(_content!)
		}
		get {return _content}
	}

	var limboPath = LimboPath()
//	var limboPath: LimboPath {
//		set {
//			_limboPath = newValue
//			setNeedsDisplay()
//			self.layer.shadowPath = limboPath.shadowPath
//			applyMask(_limboPath.maskPath)
//		}
//		get {return _limboPath}
//	}
	
	init () {
		super.init(frame: CGRect.zero)

		backgroundColor = UIColor.clear
		
		layer.shadowColor = UIColor.black.cgColor
		layer.shadowOffset = CGSize.zero
		layer.shadowRadius = 3
		layer.shadowOpacity = 0.6
	}
	convenience init (p: CGFloat) {
		self.init()
		self.p = p
	}
	convenience init (points: [(CGFloat, CGFloat)]) {
		self.init()
	}
	required init? (coder aDecoder: NSCoder) {fatalError()}
	
	private static func buildTopRightCutoutPath (x: [CGFloat], y: [CGFloat], radius: CGFloat) -> CGPath {
		let path = CGMutablePath()
		
		path.move(to: CGPoint(x: x[0], y: y[1]))
		path.addArc(tangent1End: CGPoint(x: x[0], y: y[0]), tangent2End: CGPoint(x: x[1], y: y[0]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[3], y: y[0]), tangent2End: CGPoint(x: x[3], y: y[4]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[3], y: y[3]), tangent2End: CGPoint(x: x[4], y: y[3]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[2], y: y[3]), tangent2End: CGPoint(x: x[2], y: y[1]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[2], y: y[2]), tangent2End: CGPoint(x: x[1], y: y[2]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[0], y: y[2]), tangent2End: CGPoint(x: x[0], y: y[1]), radius: radius)
		path.closeSubpath()
		
		return path
	}
	private static func buildBottomRightCutoutPath (x: [CGFloat], y: [CGFloat], radius: CGFloat) -> CGPath {
		let path = CGMutablePath()
		
		path.move(to: CGPoint(x: x[0], y: y[1]))
		path.addArc(tangent1End: CGPoint(x: x[0], y: y[0]), tangent2End: CGPoint(x: x[1], y: y[0]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[2], y: y[0]), tangent2End: CGPoint(x: x[2], y: y[1]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[2], y: y[3]), tangent2End: CGPoint(x: x[4], y: y[3]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[3], y: y[3]), tangent2End: CGPoint(x: x[3], y: y[4]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[3], y: y[2]), tangent2End: CGPoint(x: x[1], y: y[2]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[0], y: y[2]), tangent2End: CGPoint(x: x[0], y: y[1]), radius: radius)
		path.closeSubpath()
		
		return path
	}
	private func buildPath (p: CGFloat, q: CGFloat) -> CGPath {
		let path = CGMutablePath()
		
		let x1 = p
		let x3 = width - p
		let x2 = (x1 + x3) / 2
		let y1 = p
		let y3 = height - p
		let y2 = (y1 + y3) / 2
		
		path.move(to: CGPoint(x: x1, y: y2))
		
		if let cutout = cutouts[AEPoint.topLeft] {
			let xe = x1 + cutout.width + q
			let xc = (x1 + xe) / 2
			let ye = y1 + cutout.height + q
			let yc = (y1 + ye) / 2
			path.addArc(tangent1End: CGPoint(x: x1, y: ye), tangent2End: CGPoint(x: xc, y: ye), radius: radius)
			path.addArc(tangent1End: CGPoint(x: xe, y: ye), tangent2End: CGPoint(x: xe, y: yc), radius: radius)
			path.addArc(tangent1End: CGPoint(x: xe, y: y1), tangent2End: CGPoint(x: x2, y: y1), radius: radius)
		} else {
			path.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y1), radius: radius)
		}
		
		if let cutout = cutouts[AEPoint.topRight] {
			let xe = x3 - cutout.width - q
			let xc = (xe + x3) / 2
			let ye = y1 + cutout.height + q
			let yc = (y1 + ye) / 2
			path.addArc(tangent1End: CGPoint(x: xe, y: y1), tangent2End: CGPoint(x: xe, y: yc), radius: radius)
			path.addArc(tangent1End: CGPoint(x: xe, y: ye), tangent2End: CGPoint(x: xc, y: ye), radius: radius)
			path.addArc(tangent1End: CGPoint(x: x3, y: ye), tangent2End: CGPoint(x: x3, y: y2), radius: radius)
		} else {
			path.addArc(tangent1End: CGPoint(x: x3, y: y1), tangent2End: CGPoint(x: x3, y: y2), radius: radius)
		}
		
		if let cutout = cutouts[AEPoint.bottomRight] {
			let xe = x3 - cutout.width - q
			let xc = (xe + x3) / 2
			let ye = y3 - cutout.height - q
			let yc = (ye + y3) / 2
			path.addArc(tangent1End: CGPoint(x: x3, y: ye), tangent2End: CGPoint(x: xc, y: ye), radius: radius)
			path.addArc(tangent1End: CGPoint(x: xe, y: ye), tangent2End: CGPoint(x: xe, y: yc), radius: radius)
			path.addArc(tangent1End: CGPoint(x: xe, y: y3), tangent2End: CGPoint(x: x2, y: y3), radius: radius)
		} else {
			path.addArc(tangent1End: CGPoint(x: x3, y: y3), tangent2End: CGPoint(x: x2, y: y3), radius: radius)
		}
		
		if let cutout = cutouts[AEPoint.bottomLeft] {
			let xe = x1 + cutout.width + q
			let xc = (x1 + xe) / 2
			let ye = y3 - cutout.height - q
			let yc = (ye + y3) / 2
			path.addArc(tangent1End: CGPoint(x: xe, y: y3), tangent2End: CGPoint(x: xe, y: yc), radius: radius)
			path.addArc(tangent1End: CGPoint(x: xe, y: ye), tangent2End: CGPoint(x: xc, y: ye), radius: radius)
			path.addArc(tangent1End: CGPoint(x: x1, y: ye), tangent2End: CGPoint(x: x1, y: y2), radius: radius)
		} else {
			path.addArc(tangent1End: CGPoint(x: x1, y: y3), tangent2End: CGPoint(x: x1, y: y2), radius: radius)
		}
		
		path.closeSubpath()
		
		return path
	}
	
	func renderPaths () {
		
		limboPath.strokePath = buildPath(p: a, q: 0)
		limboPath.maskPath = buildPath(p: a, q: a-b)
		limboPath.shadowPath = buildPath(p: b, q: 0)
		
//		// Stroke
//		var x1 = a
//		var x3 = width - a
//		var x2 = (x1 + x3) / 2
//		var x4: CGFloat = 0
//		var x5: CGFloat = 0
//		
//		var y1 = a
//		var y3 = height - a
//		var y2 = (y1 + y3) / 2
//		var y4: CGFloat = 0
//		var y5: CGFloat = 0
//		
//		if let cutout = cutout {
//			if cutout.point.isRight() {
//				x4 = x3 - cutout.width
//				x5 = (x3 + x4) / 2
//			}
//			if cutout.point.isTop() {
//				y4 = y1 + cutout.height
//				y5 = (y1 + y4) / 2
//				limboPath.strokePath = LimboView.buildTopRightCutoutPath(x: [x1,x2,x3,x4,x5], y: [y1,y2,y3,y4,y5], radius: radius)
//			} else {
//				y4 = y3 - cutout.height
//				y5 = (y3 + y4) / 2
//				limboPath.strokePath = LimboView.buildBottomRightCutoutPath(x: [x1,x2,x3,x4,x5], y: [y1,y2,y3,y4,y5], radius: radius)
//			}
//		} else {
//			limboPath.strokePath = CGPath(roundedRect: CGRect(x: x1, y: y1, width: x3-x1, height: y3-y1), cornerWidth: radius, cornerHeight: radius, transform: nil)
//		}
		
//		// Mask
//		if let cutout = cutout {
//			if cutout.point.isRight() {
//				x4 = x3 - cutout.width - a + b
//				x5 = (x3 + x4) / 2
//			}
//			if cutout.point.isTop() {
//				y4 = y1 + cutout.height + a - b
//				y5 = (y1 + y3) / 2
//				limboPath.maskPath = LimboView.buildTopRightCutoutPath(x: [x1,x2,x3,x4,x5], y: [y1,y2,y3,y4,y5], radius: radius)
//			} else {
//				y4 = y3 - cutout.height - a + b
//				y5 = (y3 + y4) / 2
//				limboPath.maskPath = LimboView.buildBottomRightCutoutPath(x: [x1,x2,x3,x4,x5], y: [y1,y2,y3,y4,y5], radius: radius)
//			}
//		} else {
//			limboPath.maskPath = limboPath.strokePath
//		}
		
//		// Shadow
//		x1 = b
//		x3 = width - b
//		x2 = (x1 + x3) / 2
//		
//		y1 = b
//		y3 = height - b
//		y2 = (y1 + y3) / 2
//		
//		if let cutout = cutout {
//			if cutout.point.isRight() {
//				x4 = x3 - cutout.width
//				x5 = (x3 + x4) / 2
//			}
//			if cutout.point.isTop() {
//				y4 = y1 + cutout.height
//				y5 = (y1 + y4) / 2
//				limboPath.shadowPath = LimboView.buildTopRightCutoutPath(x: [x1,x2,x3,x4,x5], y: [y1,y2,y3,y4,y5], radius: radius)
//			} else {
//				y4 = y3 - cutout.height
//				y5 = (y3 + y4) / 2
//				limboPath.shadowPath = LimboView.buildBottomRightCutoutPath(x: [x1,x2,x3,x4,x5], y: [y1,y2,y3,y4,y5], radius: radius)
//			}
//		} else {
//			limboPath.shadowPath = CGPath(roundedRect: CGRect(x: x1, y: y1, width: x3-x1, height: y3-y1), cornerWidth: radius, cornerHeight: radius, transform: nil)
//		}

		applyMask(limboPath.maskPath)
		self.layer.shadowPath = limboPath.shadowPath
		setNeedsDisplay()
	}
	
	func applyMask (_ mask: CGPath) {}
	
// UIView ==========================================================================================
	override var frame: CGRect {
		set {
			super.frame = newValue
			guard frame != CGRect.zero else {return}
			limboPath.strokePath = CGPath(roundedRect: bounds.insetBy(dx: 6, dy: 6), cornerWidth: 10, cornerHeight: 10, transform: nil)
			limboPath.shadowPath = CGPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), cornerWidth: 10, cornerHeight: 10, transform: nil)
			limboPath.maskPath = limboPath.strokePath
			self.layer.shadowPath = limboPath.shadowPath
			
			renderPaths()
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
