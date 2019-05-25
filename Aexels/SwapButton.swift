//
//  SwapButton.swift
//  Aexels
//
//  Created by Joe Charlier on 4/1/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumLib
import UIKit

fileprivate class SwapView: UIView {
	static let icon: UIImage = SwapView.renderIcon(color: UIColor.white)
	static let highlight: UIImage = SwapView.renderIcon(color: OOColor.lavender.uiColor)
	
	var isHighlighted: Bool = false {
		didSet {setNeedsDisplay()}
	}

	init() {
		super.init(frame: CGRect.zero)
		backgroundColor = UIColor.clear
		isUserInteractionEnabled = false
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}

// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {
		if !isHighlighted {
			SwapView.icon.draw(at: CGPoint.zero)
		} else {
			SwapView.highlight.draw(at: CGPoint.zero)
		}
	}
	
// Static ==========================================================================================
	private static func renderIcon(color: UIColor) -> UIImage {
		let s: CGFloat = 26*Screen.s
		let w: CGFloat = 2*Screen.s
		
		UIGraphicsBeginImageContextWithOptions(CGSize(width: s, height: s), false, 0)
		let c = UIGraphicsGetCurrentContext()!
		
		var path = CGMutablePath()
		
		path.addArc(center: CGPoint(x: s/2-0.5, y: s/2-0.5), radius: (s-w)/2, startAngle: -.pi/4, endAngle: -.pi*5/4, clockwise: true)
		path.closeSubpath()
		c.addPath(path)
		c.setFillColor(color.cgColor)
		c.setLineWidth(0)
		c.drawPath(using: .fill)
		
		path = CGMutablePath()
		
		path.addEllipse(in: CGRect(x: w/2, y: w/2, width: s-w, height: s-w))
		
		c.addPath(path)
		c.setLineWidth(w)
		c.setStrokeColor(color.cgColor)
		c.drawPath(using: .stroke)
		
		let image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		return image!
	}
}

class SwapButton: AXButton {
	fileprivate let swapView = SwapView()

	override init() {
		super.init()
		swapView.isUserInteractionEnabled = false
		addSubview(swapView)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
	func rotateView() {
		UIView.animate(withDuration: 0.2) {
			self.swapView.transform = self.swapView.transform.rotated(by: CGFloat(Double.pi))
		}
	}
	func resetView() {
		self.swapView.transform = CGAffineTransform.identity
	}
	
// UIButton ========================================================================================
	override var isHighlighted: Bool {
		didSet {
			swapView.isHighlighted = isHighlighted
			setNeedsDisplay()
		}
	}
	
// UIView ==========================================================================================
	override func layoutSubviews() {
		swapView.frame = bounds
	}
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let margin: CGFloat = 15*s
		let area = self.bounds.insetBy(dx: -margin, dy: -margin)
		let inside = area.contains(point)

		if inside && !isHighlighted && event?.type == .touches {
			isHighlighted = true
		}

		return inside
	}
}
