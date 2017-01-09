//
//  PlayButton.swift
//  Aexels
//
//  Created by Joe Charlier on 1/7/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class PlayButton: UIButton {
	private let onPlay: ()->()
	private let onStop: ()->()
	
	private let color: UIColor
	
	private var playing: Bool = false
	
	init (onPlay: @escaping ()->(), onStop: @escaping ()->()) {
		self.onPlay = onPlay
		self.onStop = onStop
		color = UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1)
		super.init(frame: CGRect.zero)
		addClosure({
			self.playing = !self.playing
			self.setNeedsDisplay()
			if self.playing {
				self.onPlay()
			} else {
				self.onStop()
			}
		}, controlEvents: .touchUpInside)
	}
	required init? (coder aDecoder: NSCoder) {fatalError()}
	
// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {
		let ir: CGFloat = 11
		
		if !playing {
			let p: CGFloat = 3
			let ph: CGFloat = 12
			let pl: CGFloat = 6
			let pr: CGFloat = 11
			
			let x4: CGFloat = frame.size.width/2
			let ix10: CGFloat = CGFloat(x4-pl)
			let ix11: CGFloat = x4+pr
			let iy1: CGFloat = p
			let iy2: CGFloat = iy1+ir
			let iy6: CGFloat = iy2-ph
			let iy9: CGFloat = iy2+ph
			let iy7: CGFloat = iy6+ph*pl/(pr+pl)
			let iy8: CGFloat = iy9-ph*pl/(pr+pl)
			
			let sym = CGMutablePath()
			sym.move(to: CGPoint(x: ix10, y: iy2))
			sym.addArc(tangent1End: CGPoint(x: ix10, y: iy6), tangent2End: CGPoint(x: x4, y: iy7), radius: 2, transform: .identity)
			sym.addArc(tangent1End: CGPoint(x: ix11, y: iy2), tangent2End: CGPoint(x: x4, y: iy8), radius: 2, transform: .identity)
			sym.addArc(tangent1End: CGPoint(x: ix10, y: iy9), tangent2End: CGPoint(x: ix10, y: iy2), radius: 2, transform: .identity)
			sym.closeSubpath()
			
			let c = UIGraphicsGetCurrentContext()!
			c.addPath(sym)
			c.setFillColor(color.cgColor)
			c.drawPath(using: .fill)
			c.setLineWidth(2)
			c.setFillColor(color.cgColor)
			c.drawPath(using: .stroke)

		} else {
			let p: CGFloat = 3
			let ph: CGFloat = 9
			let sp: CGFloat = 2
			let pw: CGFloat = 3
			
			let x4: CGFloat = frame.size.width/2
			let ix12: CGFloat = x4-sp
			let ix11: CGFloat = ix12-pw
			let ix10: CGFloat = ix11-pw
			let ix13: CGFloat = x4+sp
			let ix14: CGFloat = ix13+pw
			let ix15: CGFloat = ix14+pw
			let iy2: CGFloat = p+ir
			let iy6: CGFloat = iy2-ph
			let iy9: CGFloat = iy2+ph
			let r: CGFloat = 2
			
			let sym = CGMutablePath()
			sym.move(to: CGPoint(x: ix10, y: iy2))
			sym.addArc(tangent1End: CGPoint(x: ix10, y: iy6), tangent2End: CGPoint(x: ix11, y: iy6), radius: r, transform: .identity)
			sym.addArc(tangent1End: CGPoint(x: ix12, y: iy6), tangent2End: CGPoint(x: ix12, y: iy2), radius: r, transform: .identity)
			sym.addArc(tangent1End: CGPoint(x: ix12, y: iy9), tangent2End: CGPoint(x: ix11, y: iy9), radius: r, transform: .identity)
			sym.addArc(tangent1End: CGPoint(x: ix10, y: iy9), tangent2End: CGPoint(x: ix10, y: iy2), radius: r, transform: .identity)
			sym.closeSubpath()

			sym.move(to: CGPoint(x: ix13, y: iy2))
			sym.addArc(tangent1End: CGPoint(x: ix13, y: iy6), tangent2End: CGPoint(x: ix14, y: iy6), radius: r, transform: .identity)
			sym.addArc(tangent1End: CGPoint(x: ix15, y: iy6), tangent2End: CGPoint(x: ix15, y: iy2), radius: r, transform: .identity)
			sym.addArc(tangent1End: CGPoint(x: ix15, y: iy9), tangent2End: CGPoint(x: ix14, y: iy9), radius: r, transform: .identity)
			sym.addArc(tangent1End: CGPoint(x: ix13, y: iy9), tangent2End: CGPoint(x: ix13, y: iy2), radius: r, transform: .identity)
			sym.closeSubpath()

			let c = UIGraphicsGetCurrentContext()!
			c.addPath(sym)
			c.setFillColor(color.cgColor)
			c.drawPath(using: .fill)
			c.setLineWidth(2)
			c.setFillColor(color.cgColor)
			c.drawPath(using: .stroke)

		}
	}
}
