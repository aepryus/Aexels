//
//  LimboButton.swift
//  Aexels
//
//  Created by Joe Charlier on 9/9/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class LimboButton: UIButton {
	var path: CGPath!

	let a: CGFloat = 6*Screen.s
	let b: CGFloat = 2*Screen.s
	let radius: CGFloat = 10*Screen.s

	init(title: String) {
		super.init(frame: CGRect.zero)

		backgroundColor = UIColor.clear
		
		layer.shadowColor = UIColor.black.cgColor
		layer.shadowOffset = CGSize.zero
		layer.shadowRadius = 3*s
		layer.shadowOpacity = 0.6
		
		setTitleColor(UIColor.black, for: .highlighted)
		titleLabel!.font = UIFont.ax(size: 24*s)
		titleEdgeInsets = UIEdgeInsets(top: 4*s, left: 0, bottom: 0, right: 0)
		
		self.setTitle(title, for: .normal)
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
	override var frame: CGRect {
		didSet {
			guard frame != CGRect.zero else {return}
			path = CGPath(roundedRect: bounds.insetBy(dx: 6*s, dy: 6*s), cornerWidth: 10*s, cornerHeight: 10*s, transform: nil)
			let shadowPath = CGPath(roundedRect: bounds.insetBy(dx: 2*s, dy: 2*s), cornerWidth: 10*s, cornerHeight: 10*s, transform: nil)
			self.layer.shadowPath = shadowPath
		}
	}
	override func draw(_ rect: CGRect) {
		let c = UIGraphicsGetCurrentContext()!
		
		c.addPath(path)
		c.setStrokeColor(UIColor(white: 0.3, alpha: 1).cgColor)
		c.setLineWidth(1.5*s)
		c.strokePath()
	}
}
