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

class Cutout {
	let width: CGFloat
	let height: CGFloat
	
	init (width: CGFloat, height: CGFloat) {
		self.width = width
		self.height = height
	}
}

class Limbo: UIView {
//	var path: CGPath? = nil
	
	var p: CGFloat = 15
	var a: CGFloat = 6
	var b: CGFloat = 2
	var radius: CGFloat = 10

	var cutouts: [Position:Cutout] = [:]
	
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
	
	init() {
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
	
	private func buildPath (p: CGFloat, q: CGFloat) -> CGPath {
		let path = CGMutablePath()
		
		let x1 = p
		let x3 = width - p
		let x2 = (x1 + x3) / 2
		let y1 = p
		let y3 = height - p
		let y2 = (y1 + y3) / 2
		
		path.move(to: CGPoint(x: x1, y: y2))
		
		if let cutout = cutouts[.topLeft] {
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
		
		if let cutout = cutouts[.topRight] {
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
		
		if let cutout = cutouts[.bottomRight] {
			let xe = x3 - cutout.width - q
			let xcL = (xe + x1) / 2
			let xcR = (xe + x3) / 2
			let ye = y3 - cutout.height - q
			let yc = (ye + y3) / 2
			path.addArc(tangent1End: CGPoint(x: x3, y: ye), tangent2End: CGPoint(x: xcR, y: ye), radius: radius)
			path.addArc(tangent1End: CGPoint(x: xe, y: ye), tangent2End: CGPoint(x: xe, y: yc), radius: radius)
			path.addArc(tangent1End: CGPoint(x: xe, y: y3), tangent2End: CGPoint(x: xcL, y: y3), radius: radius)
		} else {
			path.addArc(tangent1End: CGPoint(x: x3, y: y3), tangent2End: CGPoint(x: x2, y: y3), radius: radius)
		}
		
		if let cutout = cutouts[.bottomLeft] {
			let xe = x1 + cutout.width + q
			let xc = (x1 + xe) / 2
			let ye = y3 - cutout.height - q
			let ycT = (ye + y1) / 2
			let ycB = (ye + y3) / 2
			path.addArc(tangent1End: CGPoint(x: xe, y: y3), tangent2End: CGPoint(x: xe, y: ycB), radius: radius)
			path.addArc(tangent1End: CGPoint(x: xe, y: ye), tangent2End: CGPoint(x: xc, y: ye), radius: radius)
			path.addArc(tangent1End: CGPoint(x: x1, y: ye), tangent2End: CGPoint(x: x1, y: ycT), radius: radius)
		} else {
			path.addArc(tangent1End: CGPoint(x: x1, y: y3), tangent2End: CGPoint(x: x1, y: y2), radius: radius)
		}
		
		path.closeSubpath()
		
		return path
	}
	
	func renderPaths() {
		limboPath.strokePath = buildPath(p: a, q: 0)
		limboPath.maskPath = buildPath(p: a, q: a-b)
		limboPath.shadowPath = buildPath(p: b, q: 0)
		
		applyMask(limboPath.maskPath)
		self.layer.shadowPath = limboPath.shadowPath
		setNeedsDisplay()
	}
	
	func applyMask (_ mask: CGPath) {}
	
// UIView ==========================================================================================
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		if limboPath.strokePath.contains(point) {return super.hitTest(point, with: event)}
		else {return nil}
	}
	override var frame: CGRect {
		didSet {
			guard frame != CGRect.zero else {return}
			
			renderPaths()

			_content?.frame = CGRect(x: p, y: p, width: frame.size.width-2*p, height: frame.size.height-2*p)
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
