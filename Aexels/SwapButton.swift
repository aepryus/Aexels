//
//  SwapButton.swift
//  Aexels
//
//  Created by Joe Charlier on 4/1/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

fileprivate class SwapView: UIView {
	static let icon: UIImage = {
		let s: CGFloat = 26
		let w: CGFloat = 2
		
		UIGraphicsBeginImageContextWithOptions(CGSize(width: s, height: s), false, 0)
		let c = UIGraphicsGetCurrentContext()!
		
		var path = CGMutablePath()
		
		path.addArc(center: CGPoint(x: s/2-0.5, y: s/2-0.5), radius: (s-w)/2, startAngle: -.pi/4, endAngle: -.pi*5/4, clockwise: true)
		path.closeSubpath()
		c.addPath(path)
		c.setFillColor(UIColor.white.cgColor)
		c.setLineWidth(0)
		c.drawPath(using: .fill)
		
		path = CGMutablePath()
		
		path.addEllipse(in: CGRect(x: w/2, y: w/2, width: s-w, height: s-w))
		
		c.addPath(path)
		c.setLineWidth(w)
		c.setStrokeColor(UIColor.white.cgColor)
		c.drawPath(using: .stroke)
		
		let image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		return image!
	}()

	init() {
		super.init(frame: CGRect.zero)
		backgroundColor = UIColor.clear
	}
	required init? (coder aDecoder: NSCoder) {fatalError()}

// UIButton ========================================================================================
	override func draw(_ rect: CGRect) {
		SwapView.icon.draw(at: CGPoint.zero)
	}
}

class SwapButton: AXButton {
	fileprivate let swapView = SwapView()

	override init() {
		super.init()
		swapView.isUserInteractionEnabled = false
		addSubview(swapView)
	}
	required init? (coder aDecoder: NSCoder) {fatalError()}
	
	func rotateView() {
		UIView.animate(withDuration: 0.2) {
			self.swapView.transform = self.swapView.transform.rotated(by: CGFloat(Double.pi))
		}
	}
	
// UIView ==========================================================================================
	override func layoutSubviews() {
		swapView.frame = bounds
	}
	override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
		let margin: CGFloat = 15
		let area = self.bounds.insetBy(dx: -margin, dy: -margin)
		return area.contains(point)
	}
}
